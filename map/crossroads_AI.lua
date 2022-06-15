--[[

    smwMap.lua
    by MrDoubleA

    See main file for more
	
	Auto-clearing and Lockable Crossroad by SpoonyBardOL

]]

local smwMap = require("smwMap")

local bor = bit.bor
local npcID = NPC_ID
local crossroadAI = {}

local boxImg = Graphics.loadImage(Misc.resolveFile("unlockWindow.png"))

local boxExpandX = 1
local boxExpandY = 1
local starShift = 0

SaveData.smwMap = SaveData.smwMap or {}
local saveData = SaveData.smwMap

saveData.crossUnlock = saveData.crossUnlock or {}
saveData.crossPathDone = saveData.crossPathDone or {}
saveData.crossRoadFrame = saveData.crossRoadFrame or {}

local directionToWeight = {
	["up"]    = 8,
	["right"] = 4,
	["down"]  = 2,
	["left"]  = 1,
}

local npcIDs = {}

function crossroadAI.register(id)
	npcIDs[id] = true
end

function crossroadAI.crossroad_smwMap(v)
	if frameSet == nil then
		frameSet = 0
	end
	if not saveData.crossRoadFrame[v.settings.roadTitle] then
		saveData.crossRoadFrame[v.settings.roadTitle] = 0
	end
	if saveData.crossUnlock[v.settings.roadTitle] then
		v.settings.locked = false
	end
	v.settings.levelFilename = ""
	if v.settings.locked then
		frameSet = 16
	else
		frameSet = saveData.crossRoadFrame[v.settings.roadTitle]
	end

	for _,dirName in ipairs{"up","right","down","left"} do
		if smwMap.pathIsUnlocked(v.settings["path_".. dirName]) then
			saveData.crossRoadFrame[v.settings.roadTitle] = bor(saveData.crossRoadFrame[v.settings.roadTitle], directionToWeight[dirName])
		end
	end
       
	if v.lockedFade == 0 and not v.settings.locked and not saveData.crossPathDone[v.settings.roadTitle] then
		for _,directionName in ipairs{"up","right","down","left"} do
			local unlockType = (v.settings["unlock_".. directionName])
			if unlockType == true then
				smwMap.unlockPath(v.settings["path_".. directionName],v)
			end
		end
		saveData.crossPathDone[v.settings.roadTitle] = true
	end
	if v == smwMap.mainPlayer.levelObj and smwMap.mainPlayer.state == smwMap.PLAYER_STATE.NORMAL and (v.settings.locked and not saveData.crossUnlock[v.settings.roadTitle]) then
		local starIcon = Graphics.loadImageResolved("hardcoded-33-5.png")
		local sCoinIcon = Graphics.loadImageResolved("hardcoded-51-1.png")
		if v.settings.starCoins > 0 then
			Graphics.drawImageWP(sCoinIcon,v.x + 38 - smwMap.camera.x,v.y + 60 - smwMap.camera.y,-1)
			Text.print("x"..v.settings.starCoins, v.x + 54 - smwMap.camera.x,v.y + 60 - smwMap.camera.y)
			starShift = 20
		end
		if v.settings.stars > 0 then
			Graphics.drawImageWP(starIcon,v.x + 38 - smwMap.camera.x,v.y + 60 + starShift - smwMap.camera.y,-1)
			Text.print("x"..v.settings.stars, v.x + 54 - smwMap.camera.x,v.y + 60 + starShift - smwMap.camera.y)
		end
		if v.settings.stars > v.settings.starCoins then
			boxExpandX = math.floor(math.log10(v.settings.stars)) + 1
		else
			boxExpandX = math.floor(math.log10(v.settings.starCoins)) + 1
		end
		if v.settings.stars > 0 and v.settings.starCoins > 0 then
			boxExpandY = 2
		else
			boxExpandY = 1
		end
		
		Sprite.draw{x = v.x + 28 - smwMap.camera.x, y = v.y + 58 - smwMap.camera.y, width=54 + (boxExpandX * 16), height = (boxExpandY * 4) + (boxExpandY * 16), priority = -1.1, pivot = Sprite.align.TOPLEFT, bordertexture = boxImg, borderwidth = 4}
		
		if (SaveData._basegame.starcoinCounter ~= nil and SaveData._basegame.starcoinCounter >= v.settings.starCoins) and mem(0x00B251E0, FIELD_WORD) >= v.settings.stars then
			local smokeDirections = {
				vector(-1,-1),vector(1,-1),vector(-1,1),vector(1,1),
			}
			SFX.play(smwMap.playerSettings.levelDestroyedSound)
			if smwMap.levelDestroyedSmokeEffectID ~= nil then
				for index,direction in ipairs(smokeDirections) do
					local smoke = smwMap.createObject(smwMap.levelDestroyedSmokeEffectID, v.x,v.y)
					smoke.data.direction = direction
					smoke.frameX = index-1
				end
			end
			saveData.crossUnlock[v.settings.roadTitle] = true
        end
		
	end
	v.frameY = frameSet
end


return crossroadAI