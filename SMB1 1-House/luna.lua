require("libs/globalStuff")
local inventory = require("libs/customTextbox")
local inventory = require("libs/customInventory")

function onEvent(eventName)
	if eventName == "Chest1" then
		inventory.addPowerUp(2, 1)
	end
	if eventName == "Chest2" then
		inventory.addPowerUp(0, 1)
	end
	if eventName == "Chest3" then
		inventory.addPowerUp(1, 1)
	end
end

--local tbox = textbox.New{
--	text = "<voice climbing>Pick a box. <new><voice climbing>Its contents will help you on your way.",
--	x = 280,
--	y = 280,
--	pause = false,
--	playerControlled = false
--}

-- I could set the textbox's draw mode to "auto" which would make the library draw it automatically:
--tbox:SetDrawMode("auto")

