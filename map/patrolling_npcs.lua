--[[

    smwMap.lua
    by MrDoubleA

    See main file for more
	
	Patrolling NPCs by SpoonyBardOL

]]

local smwMap = require("smwMap")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local patrolling_npcs = {}
local frameStyle
local npcIDs = {}

function patrolling_npcs.register(id)
	npcIDs[id] = true
end

function patrolling_npcs.patrolling_smwMap(v)
	if v.data.horiSpeed == nil then
		v.data.horiSpeed = v.settings.horiSpeed
	end
	if v.data.vertiSpeed == nil then
		v.data.vertiSpeed = v.settings.vertiSpeed
	end
	if smwMap.getObjectConfig(v.id).frameType then
		frameStyle = 1
	else
		frameStyle = 0.5
	end
	v.data.startX = v.data.startX or v.x
	v.data.startY = v.data.startY or v.y
	if v.data.walkTimer == nil then
		v.data.walkTimer = 0
	end

	v.data.walkTimer = v.data.walkTimer + 1

	if 	v.data.walkTimer < v.settings.turnTimer then
		v.x = v.x + v.data.horiSpeed
		v.y = v.y + v.data.vertiSpeed
	elseif v.data.walkTimer > v.settings.turnTimer and v.data.walkTimer < (v.settings.turnTimer + v.settings.waitTimer) then
		v.data.isPaused = true
	elseif v.data.walkTimer > (v.settings.turnTimer + v.settings.waitTimer) then
		v.data.horiSpeed = -v.data.horiSpeed
		v.data.vertiSpeed = -v.data.vertiSpeed
		v.data.isPaused = false
		v.data.walkTimer = 0
	end	

			   
	-- Frames
	local totalFrames = smwMap.getObjectConfig(v.id).framesY
	local walkingFrames = smwMap.getObjectConfig(v.id).walkFrames
	local aniSpeed = smwMap.getObjectConfig(v.id).frameSpeed
	v.frameY = smwMap.doBasicAnimation(v,(totalFrames - walkingFrames)*frameStyle,aniSpeed)
	if v.data.isPaused then
		v.frameY = totalFrames*frameStyle - 1
	end
	if v.data.horiSpeed > 0 then
		v.frameY = v.frameY + totalFrames*frameStyle
	end
	
	
	v.priority = -12
end

return patrolling_npcs