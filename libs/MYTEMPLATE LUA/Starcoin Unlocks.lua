require("libs/globalStuff")
require("npcs/ai/starcoin")

function onStart()
local fivecoinLayer = Layer.get("5coin")
local tencoinLayer = Layer.get("10coin")
	if SaveData._basegame.starcoinCounter >= 5 then 
		fivecoinLayer:show(true)
	end
	if SaveData._basegame.starcoinCounter >= 10 then
		
		tencoinLayer:show(true)
	end
end