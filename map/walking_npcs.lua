--[[

    smwMap.lua
    by MrDoubleA

    See main file for more
	
	Walking NPCs by SpoonyBardOL

]]

local smwMap = require("smwMap")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local walking_npcs = {}

local npcIDs = {}

function walking_npcs.register(id)
	npcIDs[id] = true
end

function walking_npcs.walking_smwMap(v)
	if v.data.horiSpeed == nil then
		v.data.horiSpeed = v.settings.horiSpeed
	end
	if v.data.vertiSpeed == nil then
		v.data.vertiSpeed = v.settings.vertiSpeed
	end
	v.data.startX = v.data.startX or v.x
	v.data.startY = v.data.startY or v.y
	if v.data.walkTimer == nil then
		v.data.walkTimer = 0
	end
				
	v.data.walkTimer = v.data.walkTimer + 1

	v.x = v.x + v.data.horiSpeed
	v.y = v.y + v.data.vertiSpeed
				
	if 	v.data.walkTimer > v.settings.turnTimer then
		v.data.horiSpeed = -v.data.horiSpeed
		v.data.vertiSpeed = -v.data.vertiSpeed
		v.data.walkTimer = 0
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
end

return walking_npcs