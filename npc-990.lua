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

local failedCollectionEffectID = (npcID)

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

	
	collectSFX       = SFX.open(Misc.resolveSoundFile("keys_collect"      )), -- The sound effect played when collecting the NPC normally.
	collectFailedSFX = SFX.open(Misc.resolveSoundFile("keys_collectFailed")), -- The sound effect played when collecting the NPC, but not having enough room for it.

	revealSFX = SFX.open(Misc.resolveSoundFile("keys_reveal")), -- The sound effect played when the NPC is revealed from another NPC.
	moveSFX   = SFX.open(Misc.resolveSoundFile("keys_move"  )), -- The sound effect played when the NPC begins to move towards the player.

	bubbleImage = Graphics.loadImageResolved("keys_bubble.png"), -- The image used when inside of a bubble.

	failedCollectionEffectID = failedCollectionEffectID, -- The effect spawned when the NPC is collected, but the player does not have enough room for it.
}

npcManager.setNpcSettings(keysSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})

ai.registerKey(npcID)


-- Floating up and down behaviour

function keys.onInitAPI()
	npcManager.registerEvent(npcID,keys,"onTickNPC")
end

function keys.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.timer = nil
		return
	end

	if not data.timer then
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		return
	end
	
	npcutils.applyLayerMovement(v)


	data.timer = data.timer + 1
	
	v.speedY = (math.cos(data.timer/20)*0.1)
end


return keys