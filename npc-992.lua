--[[

	Written by MrDoubleA
    Please give credit!
    
    Credit to Novarender for doing most of the work on the key's following behaviour

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("keys_ai")


local keys = {}
local npcID = NPC_ID

local collectionEffectID = (npcID)
local keyID = nil -- Defaults to the key that was registered first if nil

local keysSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 4,
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
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	ignorethrownnpcs = true,
	isinteractable = true,

	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,

	
	type = "blue",

	collectSFX    = SFX.open(Misc.resolveSoundFile("keys_coins_collect"   )),
	collectAllSFX = SFX.open(Misc.resolveSoundFile("keys_coins_collectAll")),

	keyID = keyID,
	collectionEffectID = collectionEffectID,
}

npcManager.setNpcSettings(keysSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})

ai.registerCoin(npcID)


return keys