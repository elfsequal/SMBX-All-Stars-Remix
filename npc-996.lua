--[[

	Written by MrDoubleA
	Please give credit!
	
	Graphics created by YoshoCraft64

    Part of helmets.lua

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local helmets = require("helmets")


local helmetNPC = {}
local npcID = NPC_ID

local lostEffectID = (npcID)
local projectileID = (npcID+1)

local helmetNPCSettings = {
	id = npcID,
	
	gfxwidth = 48,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 1,
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


local cannonSounds = {"chargeStartSoundObj","chargeLoopSoundObj"}

local function shoot(p,properties,isCharged)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields


	local position = helmets.utils.getHelmetPosition(p,properties)
	local x = (position.x+((properties.texture.width*0.8)*p.direction))
	local y = (position.y)


	if properties.customConfig.projectileID then
		local npc = NPC.spawn(properties.customConfig.projectileID,x,y,p.section,false,true)
		local npcData = npc.data

		fields.projectile = npc
		npcData.player = p

		if isCharged then
			npc.speedX = properties.customConfig.chargedProjectileSpeed*p.direction
		else
			npc.speedX = properties.customConfig.projectileSpeed*p.direction
		end
	end


	local effect = Effect.spawn(10,0,0)
	
	effect.x = x-(effect.width/2)
	effect.y = y-(effect.height/2)

	local effect = Effect.spawn(71,x-8,y-8)


	if isCharged then
		helmets.utils.playSFX(properties.customConfig.chargedShotSFX)
	else
		helmets.utils.playSFX(properties.customConfig.shotSFX)
	end
end

local function cantShoot(p)
	return (
		helmets.utils.playerIsInactive(p) -- Inactive
		or helmets.utils.isWallSliding(p) -- Sliding with anotherwalljump
		or p:mem(0x26,FIELD_WORD) > 0     -- Pulling grass
		or p:mem(0x40,FIELD_WORD) > 0     -- Climbing
		or p:mem(0x4A,FIELD_BOOL)         -- Statue
		or p.holdingNPC ~= nil            -- Holding something
	)
end


function helmetNPC.onTickHelmet(p,properties)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields

	helmets.utils.useFacingFrames(p,properties,false)


	if cantShoot(p) then
		fields.chargeTime = 0
		helmets.utils.stopSounds(data,cannonSounds)

		return
	end


	fields.chargeTime = (fields.chargeTime or 0)


	local isCharged = (fields.chargeTime >= properties.customConfig.chargeTime)

	if (fields.projectile == nil or not fields.projectile.isValid) and (p:mem(0x160,FIELD_WORD) == 0 and p:mem(0x14,FIELD_WORD) <= 0) then
		if p.keys.run == KEYS_PRESSED then
			shoot(p,properties,false)
		elseif p.keys.run then
			if isCharged then
				local position = helmets.utils.getHelmetPosition(p,properties)
				local effect = Effect.spawn(12,0,0)

				effect.x = position.x+((properties.texture.width/2)*p.direction)-(effect.width/2)
				effect.y = position.y-(effect.height/2)

				effect.speedX = p.speedX+(RNG.random(1,6)*p.direction)
				effect.speedY = p.speedY+(RNG.random(-3,3))
			end


			if not helmets.utils.soundObjIsPlaying(fields.chargeStartSoundObj) and not helmets.utils.soundObjIsPlaying(fields.chargeLoopSoundObj) then
				if properties.customConfig.chargeLoopSFX and (fields.chargeStartSoundObj ~= nil) then
					fields.chargeLoopSoundObj = helmets.utils.playSFX(properties.customConfig.chargeLoopSFX)
				elseif properties.customConfig.chargeStartSFX then
					fields.chargeStartSoundObj = helmets.utils.playSFX(properties.customConfig.chargeStartSFX)
				end
			end

			fields.chargeTime = fields.chargeTime + 1
		else
			if isCharged then
				shoot(p,properties,true)
			end

			helmets.utils.stopSounds(data,cannonSounds)

			fields.chargeTime = 0
		end
	else
		helmets.utils.stopSounds(data,cannonSounds)
	end
end

function helmetNPC.onLostHelmet(p,properties)
	local data = helmets.getPlayerData(p)

	helmets.utils.stopSounds(data,cannonSounds)
end


helmets.registerType(npcID,helmetNPC,{
	name = "cannonBox",

	frames = 3,
	frameStyle = helmets.FRAMESTYLE.MANUAL_FLIP,

	lostEffectID = lostEffectID,

	onTick = helmetNPC.onTickHelmet,
	onLost = helmetNPC.onLostHelmet,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		chargeTime = 64,

		shotSFX        = SFX.open(Misc.resolveSoundFile("helmets_cannonBox_shot"       )),
		chargedShotSFX = SFX.open(Misc.resolveSoundFile("helmets_cannonBox_chargedShot")),

		chargeStartSFX = SFX.open(Misc.resolveSoundFile("helmets_cannonBox_chargeStart")),
		chargeLoopSFX  = SFX.open(Misc.resolveSoundFile("helmets_cannonBox_chargeLoop" )),

		projectileID = projectileID,
		projectileSpeed = 6, -- should be 7 blocks
		chargedProjectileSpeed = 8.5, -- should be 11 blocks
	},
})

return helmetNPC