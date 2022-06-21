require("libs/globalStuff")
local inventory = require("libs/customInventory")

--Add inventory items
function onEvent(eventName)
	if eventName == "PowerupInv" then
		inventory.addPowerUp(7, 5)
	end
end