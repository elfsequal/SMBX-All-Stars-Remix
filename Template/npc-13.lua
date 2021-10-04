-- needed to prevent game from crashing when ice cube collides with fireball, and there is no npc inside

local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

function npc.onTickNPC(v)
	for k,n in NPC.iterateIntersecting(v.x + v.speedX, v.y + v.speedY, v.x + v.width + v.speedX, v.y + v.height + v.speedY) do
		if n.id == 263 and n.ai1 <= 0 then
			v:kill(3)
			n:kill(3)
			return
		end
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickNPC')
end

return npc