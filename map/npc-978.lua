--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")

local npcID = NPC_ID
local crossroad = {}
local crossroadAI = require("crossroads_AI")

smwMap.setObjSettings(npcID,{
    framesY = 17,

    onTickObj = (function(v)
		crossroadAI.crossroad_smwMap(v)
    end),

    isLevel = true,
	hasDestroyedAnimation = true,
})

crossroadAI.register(npcID)

return crossroad