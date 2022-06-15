--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")
local jumping_npcs = require("jumping_npcs")
local npcID = NPC_ID
local obj = {}


smwMap.setObjSettings(npcID,{
    framesY = 4,
	frameSpeed = 12,
	
    onTickObj = (function(v)
		jumping_npcs.jumping_smwMap(v)
		
	end),
})
	
jumping_npcs.register(npcID)

return obj