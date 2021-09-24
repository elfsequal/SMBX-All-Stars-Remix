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
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
	frames = 0, -- classic redigit
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	powerup = true,
	isshell = true,


	-- Helmet settings
	equipableFromBottom  = true,
	equipableFromDucking = true,
	equipableFromTouch   = false,
}

npcManager.setNpcSettings(helmetNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	}, 
	{
		[HARM_TYPE_JUMP]            = lostEffectID,
		[HARM_TYPE_FROMBELOW]       = lostEffectID,
		[HARM_TYPE_NPC]             = lostEffectID,
		[HARM_TYPE_PROJECTILE_USED] = lostEffectID,
		[HARM_TYPE_HELD]            = lostEffectID,
		[HARM_TYPE_TAIL]            = lostEffectID,
		[HARM_TYPE_SPINJUMP]        = lostEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)


helmets.registerType(npcID,helmetNPC,{
	name = "beetle",

	frames = 4,
	frameStyle = helmets.FRAMESTYLE.AUTO_FLIP,

	lostEffectID = lostEffectID,

	onTick = helmets.utils.onTickShell,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		hitSFX = {
			SFX.open(Misc.resolveSoundFile("helmets_beetle_hit1")),
			SFX.open(Misc.resolveSoundFile("helmets_beetle_hit2")),
		},
		isSpiny = false,
	},
})


helmets.registerShell(npcID)

return helmetNPC