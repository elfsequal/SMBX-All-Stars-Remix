local npc = {}
local birdos = require 'birdos'
local id = NPC_ID

local settings = {
	id = id,
	shoot = 3,
	
	eggId = 913,
	eggSfx = 16,
	effect = 912,
}

birdos.register(settings)

return npc