local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

npcManager.setNpcSettings({
	id = id,
	
	gfxwidth = 32,
	gfxheight = 32,
	
	frames = 1,
	nogravity = true,
	
	jumphurt = true,
	spinjumpsafe = true,
})

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	npcManager.registerEvent(id, npc, 'onCameraDrawNPC')
end

local spawnedbygenerator = {
    [1] = true,
    [3] = true,
    [4] = true,
}

local function drawNPC(npcobject, args)
    args = args or {}
    if npcobject.__type ~= "NPC" then
        error("Must pass a NPC object to draw. Example: drawNPC(myNPC)")
    end
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

    if spawnedbygenerator[npcobject:mem(0x138, FIELD_WORD)] then
        p = -75
    end

    local sourceX = args.sourceX or 0
    local sourceY = args.sourceY or 0

    --framestyle is a weird thing...

    local frames = args.frames or cfg.frames
    local f = frame or 0
    --but only if we actually pass a custom frame...
    if args.frame and afs and cfg.framestyle > 0 then
        if cfg.framestyle == 2 then
            if npcobject:mem(0x12C, FIELD_WORD) > 0 or npcobject:mem(0x132, FIELD_WORD) > 0 then
                f = f + 2 * frames
            end
        end
        if npcobject.direction == 1 then
            f = f + frames
        end
    end

    Graphics.drawBox{
		texture = args.texture or Graphics.sprites.npc[npcobject.id].img, 
		x = x, 
		y = y, 
		
		sourceX = sourceX, 
		sourceY = sourceY + trueHeight * f, 
		sourceWidth = w, 
		sourceHeight = h, 
		color = Color.white .. o,

		priority = p,
		sceneCoords = true,
		
		rotation = args.rotation,
		centered = args.centered,
	}
end

function npc.onCameraDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	
	local data = v.data._basegame
	
	if not data.init or not data.npc then return end

	local time = math.cos(lunatime.tick() / 10) * 8
	local config = NPC.config[id]
	
	drawNPC(v, {
		frame = 0,
		
		yOffset = -v.height + 2,
		
		rotation = time / 2,
	})
	
	drawNPC(data.npc, {
		frame = 0,
		rotation = time,
		
		xOffset = v.width / 2,
		yOffset = v.height / 2,
		
		centered = true,
	})
end

local function init(v)
	local data = v.data._basegame
	
	if not data.init then
		if v.ai1 > 0 then
			local nc = NPC.config[v.ai1]
			local npc = {}

			npc.x = v.x
			npc.y = v.y
			npc.id = v.ai1
			npc.width = nc.width
			npc.height = nc.height
			npc.mem = function(npc, a, f)
				return v:mem(a, FIELD_WORD)
			end

			npc.__type = 'NPC'
	
			data.npc = npc
			
			v.width = nc.width
			v.height = nc.height
			
			v.friendly = nc.nohurt
		end
		
		data.init = true
	end
end

function npc.onTickEndNPC(v)
	local data = v.data._basegame
	local config = NPC.config[id]
	init(v)
	
	data.npc.x = v.x
	data.npc.y = v.y
	
	v.speedY = 2
	
	if v.collidesBlockBottom then
		Effect.spawn(131, v.x + v.width / 2 - 16, v.y - config.gfxheight)
		
		NPC.spawn(v.ai1, v.x, v.y)
		v:kill(9)
	end
	
	v.animationFrame = -1
end

return npc