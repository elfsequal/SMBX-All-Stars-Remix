local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	frames = 4,
	framestyle = 0,
	framespeed = 6,
	
	width = 28,
	gfxwidth=32,
	gfxheight=32,
	height = 32,
	
	jumphurt = true,
	nohurt = true,
	
	isinteractable = true,
	noiceball = true,
	
	nogravity = true,
	noblockcollision = true,
}

local function effect(v, n)
	local str = tostring(n)
	
	for i = 1, #str do
		local n = tonumber(str:sub(i,i)) + 1
		
		local e = Effect.spawn(783, v.x + (v.width / 2) - 8, v.y + (v.height / 2) - 8)
		e.x = e.x + (16 * (i - 1))
		e.variant = n
		e.speedY = -2
	end
end

function npc.onNPCKill(e, v, r)
	if v.id ~= id then return end

	local data = v.data._basegame
	local parent = data.parent

	if r == 9 and parent then
		local pdata = parent.data._basegame
	
		for k,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if p.forcedState == 0 and p.deathTimer <= 0 and p.BlinkTimer <= 0 and not p.isMega and not p.hasStarman then
				pdata.amount = pdata.amount - 1
				pdata.collected = pdata.collected + 1
				pdata.player = p
				effect(v, pdata.collected)
				Effect.spawn(131, v.x, v.y)
				
				local sfx = 'audio/sfx/red_coin' .. pdata.collected .. '.ogg'
				if Misc.resolveFile(sfx) then
					SFX.play(sfx)
				end
				
				return
			end
		end
	end
end

local function ai(v)
	local data = v.data._basegame
	local parent = data.parent
	local pdata = parent.data._basegame
	
	if not parent.isValid then
		data.parent = nil
		Effect.spawn(131, v.x, v.y)
		
		v:kill(9)
		return
	end
	
	if pdata.timer < 100 then
		if math.random() > 0.5 then
			v.animationFrame = -1
		end	
	end
end

function npc.onTickEndNPC(v)
	-- animation
	
	v.despawnTimer = 180
	
	local cfg = NPC.config[id]
	local frame = lunatime.tick() / cfg.framespeed
	
	if cfg.framestyle > 0 and v.direction == 1 then
		frame = frame + cfg.frames
	end
	
	v.animationFrame = math.floor(frame) % cfg.frames
	
	-- behavior
	local data = v.data._basegame

	if data.parent then
		ai(v)
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onNPCKill')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc