--[[

	Written by MrDoubleA
	Please give credit!

	Collection sound effects provided by Chipss

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")

local ai = require("bigCoin_ai")

local bigCoin = {}
local npcID = NPC_ID

local collectEffectID = (npcID)

local bigCoinSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	width = 64,
	height = 64,

	frames = 4,
	framestyle = 0,
	framespeed = 8,

	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	harmlessgrab = true,
	isinteractable = true,
	notcointransformable = true,

	value = 10,
	collectEffectID = collectEffectID,
	
	--collectSoundEffect = Misc.multiResolveFile("starcoin-collect.ogg", "sound/extended/starcoin-collect.ogg"),
	collectSoundEffect = Misc.resolveFile("bigcoin-10.ogg"),
}

npcManager.setNpcSettings(bigCoinSettings)
npcManager.registerDefines(npcID,{NPC.COLLECTIBLE})
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})

ai.register(npcID)

return bigCoin