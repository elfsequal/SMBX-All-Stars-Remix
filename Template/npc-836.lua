local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	frames = 5,
	framestyle = 0,
	framespeed = 4,
	
	width = 32,
	height=70,
	gfxwidth=42,
	gfxheight=70,
	
	jumphurt = true,
	nohurt = true,
	
	isinteractable = true,
	noiceball = true,
	
	nogravity = true,
	noblockcollision = true,
	
	coinID = id + 1,
	timer = 430,
	sfx = 'audio/sfx/ring_timer.ogg',
	sfxAll = 'audio/sfx/red_coin_all.ogg'
}

function npc.onStartNPC(v)
	local cfg = NPC.config[id]
	
	local data = v.data._settings
	local basedata = v.data._basegame
	
	basedata.coins = basedata.coins or {}
	
	for k,n in NPC.iterate(cfg.coinID) do
		local ndata = n.data._settings
		
		if data.activate == ndata.name then
			basedata.coins[#basedata.coins + 1] = {x = n.x, y = n.y}
		end
		
		n:kill()
	end
end

local function activate(v)
	local data = v.data._basegame
	local cfg = NPC.config[id]	
	
	data.sfx = SFX.play(cfg.sfx)
	
	for k,n in ipairs(data.coins) do
		local coin = NPC.spawn(cfg.coinID, n.x, n.y)
		local cdata = coin.data._basegame
		cdata.parent = v
		
		Effect.spawn(131, coin.x - 4, coin.y)	
	end
	
	data.timer = cfg.timer
	data.collected = 0
	data.amount = #data.coins
	data.activated = true
end

function npc.onNPCKill(e, v, r)
	if v.id ~= id then return end

	local data = v.data._basegame
	
	if r == 9 and not data.activated then
		for k,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if p.forcedState == 0 and p.deathTimer <= 0 and p.BlinkTimer <= 0 and not p.isMega and not p.hasStarman then
				activate(v)
				v.friendly = true
				v.speedX = 0
				e.cancelled = true
				Effect.spawn(131, p)
			end
		end
	end
end

function npc.onTickEndNPC(v)
	v.despawnTimer = 180
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	if data.activated then
		v:mem(0x138, FIELD_WORD, 8)
		v:mem(0x13C, FIELD_DFLOAT, 8)
		
		data.timer = data.timer - 1
		if data.timer < 0 then
			v:kill(9)
		end
	end
	
	if data.amount == 0 then
		data.sfx:stop()
		
		local p = data.player
		if p then
			local cfg = NPC.config[id]	
			SFX.play(cfg.sfxAll)
			
			local bonus = NPC.spawn(settings.prize or 90, p.x, p.y)
			bonus.x = p.x
			bonus.y = p.y - bonus.height * 2
			bonus.speedY = -6
			bonus.direction = p.direction
			
			Effect.spawn(131, bonus.x, bonus.y)	
		end
		
		v:kill(9)
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onNPCKill')
	npcManager.registerEvent(id, npc, 'onStartNPC')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc