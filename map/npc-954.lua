--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")
local floating_blocks = require("floating_blocks")

local npcID = NPC_ID
local obj = {}


smwMap.setObjSettings(npcID,{
    framesY = 4,

    onTickObj = (function(v)
		floating_blocks.floating_smwMap(v)
    end),
})

floating_blocks.register(npcID)

return obj