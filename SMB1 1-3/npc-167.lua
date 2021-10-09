local goomba = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function goomba.onTickNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	v.ai3 = v.ai3 + 1
	if v.ai3 == 240 then
		if v.x > Player.getNearest(v.x, v.y).x then
			v.direction = -1
		else
			v.direction = 1
		end
		v.ai3 = 0
	end
end

function goomba.onInitAPI()
	npcManager.registerEvent(npcID, goomba, "onTickNPC")
end

return goomba