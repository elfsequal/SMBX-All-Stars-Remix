--[[

    smwMap.lua
    by MrDoubleA

    See main file for more
	
	Jumping NPCs by SpoonyBardOL

]]

local smwMap = require("smwMap")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local jumping_npcs = {}

local npcIDs = {}
local shadowID = 949

function jumping_npcs.register(id)
	npcIDs[id] = true
end

function jumping_npcs.jumping_smwMap(v)
	if v.data.bounces == nil then
		v.data.bounces = 0
	end
	if v.data.horiSpeed == nil then
		v.data.horiSpeed = v.settings.horiSpeed * 0.1
	end
	if v.data.vertiSpeed == nil then
		v.data.vertiSpeed = 1
	end
	if v.data.startY == nil then
		v.data.startY = v.y
	end
	
	if v.data.myShadow == nil then
		v.data.myShadow = smwMap.createObject(shadowID, v.x, v.data.startY)
	end
	
	v.x = v.x + v.data.horiSpeed
	v.y = v.y + v.data.vertiSpeed
	v.data.vertiSpeed = v.data.vertiSpeed + 0.175
		
	if v.y > v.data.startY then
		v.data.vertiSpeed = -v.settings.jHeight * 0.5
		v.y = v.y - 2
		
		v.data.bounces = v.data.bounces + 1
		if v.data.bounces > v.settings.bounceTimes then
			v.data.horiSpeed = -v.data.horiSpeed
			v.data.bounces = 0
		end
	end			
			   
	-- Frames
	local totalFrames = smwMap.getObjectConfig(v.id).framesY
	local aniSpeed = smwMap.getObjectConfig(v.id).frameSpeed
	if smwMap.getObjectConfig(v.id).frameType then
		v.frameY = smwMap.doBasicAnimation(v,totalFrames,aniSpeed)
	else
		v.frameY = smwMap.doBasicAnimation(v,totalFrames*0.5,aniSpeed)
		if v.data.horiSpeed > 0 then
			v.frameY = v.frameY + totalFrames*0.5
		end
	end
	
	v.priority = -12
		
	-- Shadow
	
	if v.data.myShadow then
		v.data.myShadow.x = v.x
	end

end

return jumping_npcs