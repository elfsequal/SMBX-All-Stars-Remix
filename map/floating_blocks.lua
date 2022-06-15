--[[

    smwMap.lua
    by MrDoubleA

    See main file for more
	
	Floating Blocks by SpoonyBardOL

]]

local smwMap = require("smwMap")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local floating_blocks = {}

local npcIDs = {}
local shadowID = 949

function floating_blocks.register(id)
	npcIDs[id] = true
end

function floating_blocks.floating_smwMap(v)
	if v.data.startY == nil then
		v.data.startY = v.y
	end
	if v.data.height == nil then
		v.data.height = v.settings.height or 40
	end
		
	if v.data.myShadow == nil and v.data.height > 0 then
		v.data.myShadow = smwMap.createObject(shadowID, v.x, v.data.startY)
	end
		
    v.frameY = smwMap.doBasicAnimation(v,smwMap.getObjectConfig(v.id).framesY,6)

	if v.doneRise == nil then
		v.doneRise = true
		v.y = v.y - v.data.height
		v.width = 24
		v.height = 24
	end

	v.priority = -12		

	-- Shadow

	if v.data.myShadow then
		v.data.myShadow.x = v.x
	end
end

return floating_blocks