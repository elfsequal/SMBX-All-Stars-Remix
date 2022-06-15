--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")
local patrolling_npcs = require("patrolling_npcs")
local npcID = NPC_ID
local obj = {}


smwMap.setObjSettings(npcID,{
    framesY = 6,
	walkFrames = 2,
	frameSpeed = 8,
	
    onTickObj = (function(v)
		patrolling_npcs.patrolling_smwMap(v)
		
	end),
})
	
patrolling_npcs.register(npcID)

return obj