--[[

	Written by MrDoubleA
	Please give credit!

    Part of helmets.lua

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local helmets = require("helmets")


local helmetNPC = {}
local npcID = NPC_ID

local lostEffectID = (npcID)

local helmetNPCSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 44,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 6,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	powerup = true,

	ignorethrownnpcs = true,


	-- Helmet settings
	equipableFromBottom  = true,
	equipableFromDucking = false,
	equipableFromTouch   = true,
}

npcManager.setNpcSettings(helmetNPCSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})


local propellerSounds = {"fallSoundObj"}
local canSpinJumpCharacters = table.map{CHARACTER_MARIO,CHARACTER_LUIGI,CHARACTER_TOAD,CHARACTER_ZELDA,CHARACTER_UNCLEBROADSWORD}

local function canRestoreBoosts(p)
	return (
		(helmets.utils.playerIsInactive(p) and p.forcedState ~= 500) -- Inactive, but not transforming into a statue
		or (p.mount == 1 and p:mem(0x10C,FIELD_BOOL)) -- Hopping in a boot   
		or p:isGroundTouching()       -- Touching ground
		or p:mem(0x40,FIELD_WORD) > 0 -- Climbing
		or p:mem(0x0C,FIELD_BOOL)     -- Fairy
		or p:mem(0x36,FIELD_BOOL)     -- Underwater/in quicksand
		or p.mount == 2               -- Flying in a clown car
	)
end
local function canBoost(p)
	return (
		not helmets.utils.isWallSliding(p) -- Sliding with anotherwalljump
		and not p:mem(0x16E,FIELD_BOOL)    -- Flying
		and not p:mem(0x4A,FIELD_BOOL)     -- Statue
	)
end

function helmetNPC.onTickHelment(p,properties)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields


	local frameSpeed = 8

	fields.boostTimer = (fields.boostTimer or 0)
	fields.boostsUsed = (fields.boostsUsed or 0)

	if canRestoreBoosts(p) then
		fields.boostsUsed = 0
		fields.boostTimer = 0

		helmets.utils.stopSounds(data,propellerSounds)
	elseif fields.boostTimer > 0 then
		fields.boostTimer = fields.boostTimer + 1

		p.speedX = math.clamp(p.speedX,-Defines.player_walkspeed,Defines.player_walkspeed)
		p.speedY = -6

		frameSpeed = frameSpeed*0.25

		if fields.boostTimer > properties.customConfig.boostTime or p:mem(0x14A,FIELD_WORD) > 0 then
			fields.boostTimer = 0

			p:mem(0x18,FIELD_BOOL,(fields.boostsUsed >= properties.customConfig.boosts))
		end
	elseif canBoost(p) then
		if fields.boostsUsed < properties.customConfig.boosts and (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) then
			fields.boostsUsed = fields.boostsUsed + 1
			fields.boostTimer = 1

			helmets.utils.stopSounds(data,propellerSounds)


			p:mem(0x18,FIELD_BOOL,false)

			if p.keys.altJump == KEYS_PRESSED and canSpinJumpCharacters[p.character] then
				p:mem(0x50,FIELD_BOOL,true)
				SFX.play(33)
			end
			if properties.customConfig.boostSFX then
				helmets.utils.playSFX(properties.customConfig.boostSFX[math.min(fields.boostsUsed,#properties.customConfig.boostSFX)])
			end
		elseif fields.boostsUsed > 0 then
			p.speedX = math.clamp(p.speedX,-Defines.player_walkspeed*1.5,Defines.player_walkspeed*1.5)
			p.speedY = math.min(Defines.gravity/6,p.speedY-(helmets.utils.getPlayerGravity(p)*0.5))
			frameSpeed = frameSpeed*0.5

			if p.speedY > 0 then
				if properties.customConfig.fallSFX and not helmets.utils.soundObjIsPlaying(fields.fallSoundObj) then
					fields.fallSoundObj = helmets.utils.playSFX(properties.customConfig.fallSFX)
				end
			else
				helmets.utils.stopSounds(data,propellerSounds)
			end
		end
	end


	helmets.utils.simpleAnimation(p,properties,frameSpeed)
	fields.variantFrame = math.max(0,(properties.variantFrames-properties.customConfig.boosts-1)+fields.boostsUsed)
end


helmets.registerType(npcID,helmetNPC,{
	name = "propellerBox",

	frames = 6,
	frameStyle = helmets.FRAMESTYLE.STATIC,

	variantFrames = 4,


	lostEffectID = lostEffectID,

	onTick = helmetNPC.onTickHelment,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		boosts = 3,
		boostTime = 12,

		boostSFX = {
			SFX.open(Misc.resolveSoundFile("helmets_propellerBox_boost1")),
			SFX.open(Misc.resolveSoundFile("helmets_propellerBox_boost2")),
			SFX.open(Misc.resolveSoundFile("helmets_propellerBox_boost3")),
		},

		fallSFX = SFX.open(Misc.resolveSoundFile("helmets_propellerBox_fall")),
	},
})

return helmetNPC