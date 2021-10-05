local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"
local fludd = require 'fludd'

npcManager.setNpcSettings{
	id = id,
	
	frames = 1,
	framestyle = 0,
	
	nohurt = true,
	jumphurt = true,
	noiceball = true,
	isinteractable = true,
	
	nogravity = true,
	noblockcollision = true,
}

function npc.onPostNPCKill(v, r)
	if v.id ~= id then return end
	
	for k,p in ipairs(Player.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
		for i = 1, 4 do
			local e = Effect.spawn(74, v.x + v.width / 2, v.y + v.height / 2)
			e.speedX = math.random(-4,4)
			e.speedY = math.random(-4,4)
		end
		
		local fld = fludd.isActivated(p.idx)
		
		if fld then
			fld.energy = 100
		end
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onPostNPCKill')
end

return npc