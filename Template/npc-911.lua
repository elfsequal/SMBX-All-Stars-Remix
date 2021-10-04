local npc = {}
local birdos = require 'birdos'
local id = NPC_ID

local settings = {
	id = id,
	shoot = 3,
	canShootFire = true,
	
	effect = 911,
}

birdos.register(settings)

return npc