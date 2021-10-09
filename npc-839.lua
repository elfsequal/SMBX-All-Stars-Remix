local npc = {}
local id = NPC_ID
local npcManager = require 'npcManager'

npcManager.setNpcSettings{
	id = id,
	
	coinID = id - 1,
	nogravity = true,
	noblockcollision = true,
	jumphurt = true,
	nohurt = true,
}

local orbits = require 'orbits'
	
function npc.onTickEndNPC(v)
	local data = v.data._basegame
	
	local data = v.data._basegame
	local config = NPC.config[id]
	local settings = v.data._settings
	
	data.orb = data.orb or orbits.new{
		x = v.x + v.width / 2,
		y = v.y + v.height / 2,
		
		section = v.section,
		id = config.coinID,
		
		speed = settings.speed * v.direction,
		radius = settings.radius,
		number = settings.count,
		angleDegs = settings.startAngle
	}
	
	if data.orb and data.orb.orbitingNPCs then
		local count = settings.gaps
		
		for k,n in ipairs(data.orb.orbitingNPCs) do
			if n and n.isValid then
				n.data._basegame.pos = {x = v.x --[[+ v.width / 2]], y = v.y --[[+ v.height / 2]]}
			end
		end
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc