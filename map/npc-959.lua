--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")
local walking_npcs = require("walking_npcs")
local npcID = NPC_ID
local obj = {}


smwMap.setObjSettings(npcID,{
    framesY = 4,
	frameSpeed = 8,
	
    onTickObj = (function(v)
		walking_npcs.walking_smwMap(v)
		
	end),
})
	
walking_npcs.register(npcID)

return obj