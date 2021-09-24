cap = {}

local metalCapMObj = SFX.play{
	sound = "Super Mario 64 - Metallic Mario Main.ogg",
	loops = 0,
	delay = 0
}
metalCapMObj:Pause()

local metalCapIObj = SFX.play{
	sound = "Super Mario 64 - Metallic Mario Intro.ogg",
	loops = 1,
	delay = 0
}
metalCapIObj:Pause()

local sections = {} --Used for determining in which section the music should play
--local origSectionMusic = {}

local moosicCache = 0 --literally stole the idea and basic code from the starman npc

local alreadyPlaying = false
local playedLoop = false

--Settings here!
cap.duration = 1200 --Lasts for ~20 seconds by default (1200), as that's how long it is in SM64. (i think atl east)

--This setting allows for customizability regarding which blocks to be able to be destroyed!
--The way a block is "registered" is:
-- [block id goes here] = {arguments go here}
--Arguments are as follows:
	--top: If set to true, the block can be destroyed from the top. Defaults to true.
	--bottom: Same thing as top, but on the bottom. Defaults to true.
	--left: If set to true, the block can be destroyed from the left. More on this later. Defaults to false.
	--right: Same thing as left, but on the right. Defaults to false.
	--speedThresholdH: If set to a value above 0, the player needs to be the same speed or faster before they can destroy it from the side. Defaults to 0.
	--speedThresholdV: If set to a value above 0, the player needs to be the same speed or faster before they can destroy it from the top/bottom. Defaults to 0.
	--bounceH: The amount that the player will be "bounced" horizontally when breaking the block when from the side. Defaults to 0.
	--bounceV: The amount that the player will be "bounced" vertically when breaking the block from the top. Defaults to 6.

cap.destroyableBlocks = {
	[457] = {top = true, bottom = true, left = true, right = true, speedThresholdH = 0, speedThresholdV = 0, bounceH = 0, bounceV = 6},
	[4] = {top = true, bottom = true, left = true, right = true, speedThresholdH = 0, speedThresholdV = 0, bounceH = 0, bounceV = 6},
}
--End of settings.

local metalShader = Shader()
local colliders = require("colliders")

function cap.onInitAPI()
	registerEvent(cap, "onTick", "onTick")
	registerEvent(cap, "onTickEnd", "onTickEnd")
	registerEvent(cap, "onDraw", "onDraw")
	registerEvent(cap, "onStart", "onStart")
	registerEvent(cap, "onExitLevel", "onExitLevel")
end

function cap.onStart()
	metalShader:compileFromFile(nil, "libs/metalShader.frag")

	--[[for i=1,21 do
		local sectionNr = i - 1
		origSectionMusic[i] = Section(sectionNr).musicID
	end]]
end

function cap.onExitLevel()
	if moosicCache then
		Audio.MusicVolume(moosicCache)
		moosicCache = nil
	end
end

function cap.onTickEnd()
	for _,plr in ipairs(Player.get()) do
		if plr.isMetal then
			cap.destroyableBlocksCheck(plr)

			if not alreadyPlaying then
				moosicCache = Audio.MusicVolume()

				metalCapIObj:Resume()

				Audio.MusicVolume(0)
				alreadyPlaying = true
			end

			if not playedLoop and not metalCapIObj:isPlaying() then --if the metal cap music stopped playing

				metalCapMObj:Resume()
				
				playedLoop = true
			end
		end
	end
end

function cap.onTick()
	for _,plr in ipairs(Player.get()) do

		if plr.isMetal then

			plr.metalTransformationTimer = plr.metalTransformationTimer or 0

			if plr.metalTransformationTimer ~= 0 then

				plr.metalTransformationTimer = plr.metalTransformationTimer - 1
				plr.speedX = 0
				cap.disableControls(plr)

			else

				plr.capTimer = plr.capTimer or 0

				plr.capTimer = plr.capTimer + 1

				if plr.capTimer == cap.duration then

					plr.isMetal = false

					local dontStopMusic = false

					for _,p in ipairs(Player.get()) do
						if p.section == plr.section and p.idx ~= plr.idx and p.isMetal then --checks if there is another player in the same section
							dontStopMusic = true
							break
						end
					end

					if not dontStopMusic then
						metalCapMObj:Pause()

						Audio.MusicVolume(moosicCache)
						moosicCache = nil --reset it

						alreadyPlaying = false
						playedLoop = false


					end

					--What this does is "reset" the amount of loops this SFX has.
					metalCapIObj = SFX.play{
						sound = "Super Mario 64 - Metallic Mario Intro.ogg",
						loops = 0,
						delay = 0
					}

					metalCapIObj:Pause()

					plr.capTimer = 0
					plr.metalTransformationTimer = 0

				else
					plr:mem(0x140, FIELD_WORD, 1)
				end
			end

			for _,v in ipairs(NPC.getIntersecting(plr.x, plr.y, plr.x + plr.width, plr.y + plr.height)) do
				if v.friendly then return end --layer 1 of security of "not killing non-enemies", if an NPC is friendly, this won't pass
				if not NPC.HITTABLE_MAP[v.id] then return end --layer 2 of security of "not killing non-enemies", if an NPC cannot be killed, this won't pass

				local config = NPC.config[v.id]

				if config.notKilledByMetal ~= nil and config.notKilledByMetal then return end --layer 3 of security, if a NPC has this config, they won't be killed. It's a custom property, so if you want a killabe NPC to be unkillable by metal, add this.

				SFX.Play(9)
				v:harm()
			end
		end

		plr.lastSpeedY = plr.speedY
		plr.lastSpeedX = plr.speedX
	end
end

--this function is used to determine if there are blocks that the player can destroy (and also destroy them!)
function cap.destroyableBlocksCheck(plr)

	plr.lastSpeedY = plr.lastSpeedY or 0
	plr.lastSpeedX = plr.lastSpeedX or 0

	--Collision checkin'!
	--There's like, a 99% chance that I could've handled this better, but I don't know enough lua and programming in SMBX2 to do it that way.

	--Bottom
	if plr:mem(0x146, FIELD_WORD) ~= 0 then
		for _,blck in Block.iterateIntersecting(plr.x, plr.y, plr.x + plr.width, plr.y + plr.height + 8) do
			if not blck.isHidden and cap.destroyableBlocks[blck.id] ~= nil then

				--setting up the, well, settings

				local block = cap.destroyableBlocks[blck.id]

				local top = block.top or true
				local speedThresholdV = block.speedThresholdV or 0
				local bounceV = block.bounceV or 6

				if plr.lastSpeedY > 0 and math.abs(plr.lastSpeedY) > math.abs(speedThresholdV) and top then
					plr.speedY = -math.abs(bounceV)
					blck:remove(true)
				end

			end
		end
	end

	--Top
	if plr:mem(0x14A, FIELD_WORD) ~= 0 then
		for _,blck in Block.iterateIntersecting(plr.x, plr.y - 8, plr.x + plr.width, plr.y) do
			if not blck.isHidden and cap.destroyableBlocks[blck.id] ~= nil then

				--setting up the, well, settings

				local block = cap.destroyableBlocks[blck.id]

				local bottom = block.bottom or true
				local speedThresholdV = block.speedThresholdV or 0

				if plr.lastSpeedY < 0 and math.abs(plr.lastSpeedY) > math.abs(speedThresholdV) and bottom then
					plr.speedY = 0
					blck:remove(true)
				end

			end
		end
	end

	--Left
	if plr:mem(0x148, FIELD_WORD) ~= 0 then
		for _,blck in Block.iterateIntersecting(plr.x - 8, plr.y, plr.x + plr.width, plr.y + plr.height) do

			if not blck.isHidden and cap.destroyableBlocks[blck.id] ~= nil then

				--setting up the, well, settings

				local block = cap.destroyableBlocks[blck.id]

				local right = block.right or true
				local speedThresholdH = block.speedThresholdH or 0
				local bounceH = block.bounceH or 0

				if plr.lastSpeedX < 0 and math.abs(plr.lastSpeedX) > math.abs(speedThresholdH) and right then
					plr.speedX = bounceH
					blck:remove(true)
				end

			end
		end
	end

	--Right
	if plr:mem(0x14C, FIELD_WORD) ~= 0 then
		for _,blck in Block.iterateIntersecting(plr.x, plr.y, plr.x + plr.width + 8, plr.y + plr.height) do
			if not blck.isHidden and cap.destroyableBlocks[blck.id] ~= nil then

				--setting up the, well, settings

				local block = cap.destroyableBlocks[blck.id]

				local left = block.left or true
				local speedThresholdH = block.speedThresholdH or 0
				local bounceH = block.bounceH or 0

				if plr.lastSpeedX > 0 and math.abs(plr.lastSpeedX) > math.abs(speedThresholdH) and left then
					plr.speedX = -bounceH
					blck:remove(true)
				end

			end
		end
	end
end

--just a way to disable the controls and not flood the main onTick event
function cap.disableControls(plr)
	plr.keys.up = false
	plr.keys.down = false
	plr.keys.left = false
	plr.keys.right = false

	plr.keys.jump = false
	plr.keys.altJump = false
	plr.keys.altRun = false
	plr.keys.run = false
	plr.keys.dropItem = false
	plr.keys.pause = false
end

function cap.onDraw()
	for _,plr in ipairs(Player.get()) do
		if plr.isMetal then

			plr:mem(0x142, FIELD_BOOL, false)

			local enabled = 0
			local speed = 0

			plr.metalTransformationTimer = plr.metalTransformationTimer or 0

			if plr.metalTransformationTimer >= 30 then
				speed = 1
			else
				speed = 2
			end

			plr.capTimer = plr.capTimer or 0

			if plr.capTimer >= cap.duration - 180 then
				speed = 1
			end
			if plr.capTimer >= cap.duration - 60 then
				speed = 2
			end

			if plr.metalTransformationTimer ~= 0 and plr.metalTransformationTimer < 60 then
				enabled = math.sin(lunatime.tick()*speed/2)*3
			elseif plr.metalTransformationTimer == 0 then
				enabled = 1
			end

			if plr.capTimer >= cap.duration - 60 then
				enabled = math.sin(lunatime.tick()*speed/2)*3
			end

			plr:render{
				x = plr.x,
				shader = metalShader,
				uniforms = {
					enabled = enabled,
				},
			}
		end
	end
end

return cap