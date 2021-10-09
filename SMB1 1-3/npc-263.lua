local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

function npc.onTickEndNPC(v)
	if v.ai1 >= 0 then return end
	
	local p = Player(-v.ai1)
	p.x = v.x + v.width / 2
	p.y = v.y + v.height / 2
	v.width = p.width
	v.height = p.height
	p.forcedState = 8
	p.speedX = 0
	p.speedY = 0
	
	if v.width < 32 then
		v.width = 32
	end
	
	if p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED then
		v:kill(3)
	end
	
	if v.despawnTimer < 170 then
		v:kill(3)	
	end
	
	local bound = Section(v.section).boundary
	
	if (v.x < bound.left) or (v.x + v.width > bound.right) then
		v:kill(3)
	end
end

local render = Graphics.drawImageToSceneWP

function npc.onCameraDrawNPC(v)
	if v.despawnTimer <= 0 or v.ai1 >= 0 then return end
	
	local texture = Graphics.sprites.npc[id].img
	local cfg = NPC.config[id]
	
	render(
		texture, 
		v.x + cfg.gfxoffsetx, 
		v.y + cfg.gfxoffsety, 
		0,
		0,
		v.width - 6,
		v.height - 6,
		-45
	)
	
	render(
		texture, 
		v.x + cfg.gfxoffsetx + v.width - 6, 
		v.y + cfg.gfxoffsety, 
		128 - 6,
		0,
		6,
		v.height - 6,
		-45
	)
	
	render(
		texture, 
		v.x + cfg.gfxoffsetx, 
		v.y + cfg.gfxoffsety + v.height - 6, 
		0,
		128 - 6,
		v.width - 6,
		6,
		-45
	)
	
	render(
		texture, 
		v.x + cfg.gfxoffsetx + v.width - 6, 
		v.y + cfg.gfxoffsety + v.height - 6, 
		128 - 6,
		128 - 6,
		6,
		6,
		-45
	)
	
	local p = Player(-v.ai1)
	p:render{
		ignorestate = true,
		priority = -75,
		
		x = v.x + (v.width - p.width) / 2,
		y = v.y,
	}
end

function npc.onPostNPCKill(v,r)
	if v.id ~= id then return end
	
	if v.ai1 >= 0 then return end
	
	local p = Player(-v.ai1)
	p.forcedState = 0
	p.x = v.x
	p.y = v.y
	
	if not v.friendly then
		p:harm()
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onPostNPCKill')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	npcManager.registerEvent(id, npc, 'onCameraDrawNPC')
end

return npc