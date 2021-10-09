local fludd = {}

fludd.has = {}
fludd.id = 820

local HOVER = 0
local TURBO = 1
local ROCKET = 2

function fludd.activate(idx, typ)
	fludd.has[idx] = {energy = 100, water = 100, type = typ, hold = false}
end

function fludd.isActivated(idx)
	return fludd.has[idx]
end

local function ai(p, v)
	local k = p.keys
	
	if k.jump == KEYS_PRESSED then
		v.hold = true
	elseif k.jump == KEYS_DOWN and v.hold and v.energy > 0 and v.water > 0 then
		v.energy = v.energy - ((v.type ~= ROCKET and 0.5) or 2)
		v.water = v.water - ((v.type ~= ROCKET and 0.025) or 0.15)
		
		if v.type == TURBO then
			p.speedX = (9 * (v.energy / 100)) * p.direction
			p.speedY = 0
		else
			local div = (v.type ~= ROCKET and v.energy / 100) or v.energy / 75
			
			local speedY = (v.type == ROCKET and 12) or 6
			p.speedY = -(speedY * div)
		end
	else
		v.hold = false
	end
	
	if v.energy == 0 or v.water == 0 then
		v.hold = false
	end
	
	if v.hold then
		local x = (p.direction == 1 and -(p.width * 1.45) + 8) or (p.width / 1.20) + 24
		local y = 0
		
		if v.type == TURBO then
			x = (x - 8 * p.direction)
			y = -16
		end
		
		local e = Effect.spawn(74, p.x + x, p.y + y)
		e.speedX = (v.type == TURBO and -p.speedX) or p.speedX
		e.speedY = math.abs(p.speedY)
	end
	
	if p:isOnGround() then
		v.hold = false
		
		v.energy = v.energy + ((v.type ~= ROCKET and 1) or 2)
	end
	
	if p:mem(0x36, FIELD_BOOL) then
		v.water = v.water + 1
	end
	
	v.energy = math.clamp(v.energy, 0, 100)
	v.water = math.clamp(v.water, 0, 100)
	
	p:mem(0xBC, FIELD_WORD, 32)
end

function fludd.onTickEnd()
	for k = 1, #fludd.has do
		local v = fludd.has[k]
		
		if v then
			local p = Player(k)
			ai(p, v)
			
			if p.deathTimer > 0 or p.isMega then
				table.remove(fludd.has, k)
			end
		end
	end
end

local function drawNPC(npcobject, args)
    args = args or {}
    local frame = args.frame or npcobject.animationFrame

    local afs = args.applyFrameStyle
    if afs == nil then afs = true end

    local cfg = NPC.config[npcobject.id]
    
    --gfxwidth/gfxheight can be unreliable
    local trueWidth = cfg.gfxwidth
    if trueWidth == 0 then trueWidth = npcobject.width end

    local trueHeight = cfg.gfxheight
    if trueHeight == 0 then trueHeight = npcobject.height end

    --drawing position isn't always exactly hitbox position
    local x = npcobject.x + 0.5 * npcobject.width - 0.5 * trueWidth + cfg.gfxoffsetx + (args.xOffset or 0)
    local y = npcobject.y + npcobject.height - trueHeight + cfg.gfxoffsety + (args.yOffset or 0)

    --cutting off our sprite might be nice for piranha plants and the likes
    local w = args.width or trueWidth
    local h = args.height or trueHeight

    local o = args.opacity or 1

    --the bane of the checklist's existence
    local p = args.priority or -45
    if cfg.foreground then
        p = -15
    end
	
    local sourceX = args.sourceX or 0
    local sourceY = args.sourceY or 0

    --framestyle is a weird thing...

    local frames = args.frames or cfg.frames
    local f = frame or 0
    --but only if we actually pass a custom frame...
    if args.frame and afs and cfg.framestyle > 0 then
        if npcobject.direction == 1 then
            f = f + frames
        end
    end

    Graphics.drawImageToSceneWP(args.texture or Graphics.sprites.npc[npcobject.id].img, x, y, sourceX, sourceY + trueHeight * f, w, h, o, p)
end

local textplus = require 'textplus'
local font = textplus.loadFont("textplus/font/2.ini")

local function bar(x, max, val, col, y)
	local y = y or 0
	
	Graphics.drawBox{
		x = x + 2,
		y = y + 2,
		width = max,
		height = 4,
		
		color = Color.black .. 0.75,
	}
	
	Graphics.drawBox{
		x = x,
		y = y,
		width = val,
		height = 4,
		
		color = col,
	}
	
	textplus.print{
		text = tostring(math.floor(val)),
		
		x = x + max - 32,
		y = y - 8,
		
		xscale = 2,
		yscale = 2,
		
		font = font,
	}
end

local function render(p, v)
    local cfg = NPC.config[fludd.id]
    
	local x = (p.direction == 1 and -p.width * 1.45) or p.width / 1.20
	
	drawNPC({
		id = fludd.id, 
		width = cfg.width, 
		height = cfg.height, 
		x = p.x + x, 
		y = p.y - cfg.height / 2,
		direction = p.direction,
	}, 
	{
		frame = v.type,
		priority = -35,
	})
	
	local w = 100
	local x = 32
	
	if p.idx == 2 then
		x = 800 - 32 - w
	end
	
	if p.idx <= 2 then
		bar(x, w, v.water, Color.fromHexRGB(0x00CBFF), 600 - 48)
		bar(x, w, v.energy, Color.fromHexRGB(0xFF4300), 600 - 24)
	end
end

function fludd.onCameraDraw()
	for k = 1, #fludd.has do
		local v = fludd.has[k]
		
		if v then
			render(Player(k), v)
		end
	end
end

function fludd.onExit()
	fludd.has = {}
end

function fludd.onInitAPI()
	registerEvent(fludd, 'onCameraDraw')
	registerEvent(fludd, 'onTickEnd')
	registerEvent(fludd, 'onExit')
end

return fludd