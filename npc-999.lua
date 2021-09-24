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


local disableKeys = {"up","right","down","left"}
local bulletSounds = {"flySoundObj"}

local colBox = Colliders.Box(0,0,0,0)

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


local function hitWall(p)
	helmets.setCurrentType(p,nil)
	p.speedX = 0

	SFX.play(3)
end

local function hittableNPCFilter(npc)
	return (
		(not npc.isGenerator and not npc.isHidden and npc.despawnTimer > 0)    -- Boring stuff
		and (npc:mem(0x130,FIELD_WORD) == 0 or npc:mem(0x12E,FIELD_WORD) == 0) -- Not just thrown
		and npc:mem(0x12C,FIELD_WORD) == 0 -- Not held
		and not npc.friendly
	)
end

function helmetNPC.onTickHelment(p,properties)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields
	

	fields.flightTime = (fields.flightTime or 0)

	
	if canRestoreBoosts(p) then
		fields.flightTime = 0
		fields.rotation = 0

		helmets.utils.stopSounds(data,bulletSounds)
	elseif canBoost(p) and (p.speedY > 0 and fields.flightTime < properties.customConfig.flightTime and (p.keys.jump or p.keys.altJump)) then
		local isStuttering = (fields.flightTime > properties.customConfig.flightTime-properties.customConfig.stutterTime)
		

		p.speedX = math.clamp(p.speedX+(properties.customConfig.acceleration*p.direction),-properties.customConfig.maxSpeed,properties.customConfig.maxSpeed)
		p.speedY = -helmets.utils.getPlayerGravity(p)+0.0001

		p:mem(0x18,FIELD_BOOL,false)

		if p:mem(0x50,FIELD_BOOL) then
			p:mem(0x50,FIELD_BOOL,false)
			p.direction = p:mem(0x54,FIELD_WORD)
		end


		-- Sound effect
		if fields.flySoundObj == nil then
			fields.flySoundObj = helmets.utils.playSFX(properties.customConfig.flySFX)
		else
			helmets.utils.changeSoundsVolume(data,bulletSounds,0.2)
		end


		-- Hit blocks/NPCs
		colBox.x,colBox.y = p.x+p.speedX,p.y
		colBox.width,colBox.height = p.width,p.height

		for _,block in ipairs(Colliders.getColliding{a = colBox,b = Block.SOLID,btype = Colliders.BLOCK}) do
			block:hit(false,p)
			hitWall(p)
		end
		for _,npc in ipairs(Colliders.getColliding{a = colBox,b = NPC.HITTABLE,btype = Colliders.NPC,filter = hittableNPCFilter}) do
			npc:harm(HARM_TYPE_NPC)
			hitWall(p)
		end

		if p:mem(0x148,FIELD_WORD) > 0 or p:mem(0x14C,FIELD_WORD) > 0 then -- Something else happened
			hitWall(p)
		end
		


		-- Extra effects
		local smokeFrequency = 8
		if isStuttering then
			fields.rotation = RNG.random(-10,10)
			smokeFrequency = 18
		end


		fields.smokeTimer = (fields.smokeTimer or 0) + 1

		if fields.smokeTimer%smokeFrequency == 0 then
			local position = helmets.utils.getHelmetPosition(p,properties)
			local effect = Effect.spawn(10,0,0)

			effect.x = (position.x-((properties.texture.width/2)*p.direction))-(effect.width /2)
			effect.y = (position.y                                           )-(effect.height/2)
		end

		fields.flightTime = fields.flightTime + 1


		-- Bit janky but ehh
		for _,name in ipairs(disableKeys) do
			p.keys[name] = false
		end

		p.keys.run = (p.holdingNPC ~= nil and p.keys.run)
	else
		fields.rotation = 0

		if fields.flightTime < properties.customConfig.flightTime then
			helmets.utils.changeSoundsVolume(data,bulletSounds,-0.1)
		end
	end

	helmets.utils.simpleAnimation(p,properties)
end

function helmetNPC.onLostHelmet(p,properties)
	local data = helmets.getPlayerData(p)

	helmets.utils.stopSounds(data,bulletSounds)
end


helmets.registerType(npcID,helmetNPC,{
	name = "bulletMask",

	frames = 1,
	frameStyle = helmets.FRAMESTYLE.AUTO_FLIP,

	offset = vector(0,4),


	lostEffectID = lostEffectID,

	onTick = helmetNPC.onTickHelment,
	onLost = helmetNPC.onLostHelmet,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		flightTime = 270, -- How long the player can fly for without needing to recharge
		stutterTime = 96, -- How long it'll "stutter" before falling

		acceleration = 0.25,
		maxSpeed = 6.5,

		flySFX = SFX.open(Misc.resolveSoundFile("helmets_bulletMask_fly")),
	},
})

return helmetNPC