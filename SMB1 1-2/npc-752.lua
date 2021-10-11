--[[

	Written by MrDoubleA
    Please give credit!
    
    Credit to Novarender for vastly improving the font used for character names

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local ai = require("goalTape_ai")


local goalTape = {}
local npcID = NPC_ID



local goalTapeSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
    harmlessthrown = true,

	ignorethrownnpcs = true,
    
    notcointransformable = true,

    
    movementSpeed = 2, -- How fast the goal tape moves up and down.

    doDarken = true,    -- Whether or not everything is darkened during the exit animation.
    doIrisOut = false,  -- Whether or not there's an iris out effect to exit the level.
	pausesGame = true,  -- Where or not the entire game is paused during the exit.
	isOrb = true,       -- Whether or not the NPC is a ? Orb.

	poseTime = 464,      -- The frame on which the pose is done.
	startExitTime = 600, -- The frame on which the iris out starts.

    victoryPose = nil,        -- The "victory pose" used. Can be nil for none, or a number for a specific frame (see http://i.imgur.com/1dnW3g3.png for a list).
    victoryPoseOnYoshi = nil, -- The "victory pose" used when on a yoshi.

    mainSFX = SFX.open(Misc.resolveFile("audio/sfx/goalTape_orb.ogg")),        -- The sound played when hitting the goal tape. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.
    irisOutSFX = SFX.open(Misc.resolveFile("audio/sfx/goalTape_irisOut.ogg")), -- The sound used for the iris out. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.

    heldNPCsTransform = false, -- Whether or not an NPC being held will transform when hitting the goal.
    
    -- Results
    displayCharacterName = true, -- Whether or not the character's name is displayed with the results.
    displayCourseClear = true,   -- Whether or not the "course clear" text is displayed with the results.
    doTimerCountdown = true,     -- Whether or not to do the countdown of the timer, if the timer is enabled.

    timerScoreMultiplier = 50, -- How many points each timer second is worth.
    timerCountdownSpeed = 128, -- How many frames it takes to count down the timer.

    -- The sound effects using for the timer countdown. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.
    countdownStartSFX = SFX.open(Misc.resolveFile("audio/sfx/goalTape_countdown_start.wav")),
    countdownLoopSFX  = SFX.open(Misc.resolveFile("audio/sfx/goalTape_countdown_loop.wav")),
    countdownEndSFX   = SFX.open(Misc.resolveFile("audio/sfx/goalTape_countdown_end.wav")),
}

npcManager.setNpcSettings(goalTapeSettings)
npcManager.registerDefines(npcID,{NPC.UNHITTABLE})
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})


ai.register(npcID)


return goalTape