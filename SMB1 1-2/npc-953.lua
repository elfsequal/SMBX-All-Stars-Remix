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



local COINS_ADDR = 0x00B2C5A8
local LIVES_ADDR = 0x00B2C5AC
local function addCoins(amount)
	mem(COINS_ADDR,FIELD_WORD,(mem(COINS_ADDR,FIELD_WORD)+amount))

	if mem(COINS_ADDR,FIELD_WORD) >= 100 then
		if mem(LIVES_ADDR,FIELD_FLOAT) < 99 then
			mem(LIVES_ADDR,FIELD_FLOAT,(mem(LIVES_ADDR,FIELD_FLOAT)+math.floor(mem(COINS_ADDR,FIELD_WORD)/100)))
			SFX.play(15)

			mem(COINS_ADDR,FIELD_WORD,(mem(COINS_ADDR,FIELD_WORD)%100))
		else
			mem(COINS_ADDR,FIELD_WORD,99)
		end
	end
end

function helmetNPC.onTickHelmet(p,properties)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields
	
	helmets.utils.simpleAnimation(p,properties)


	if helmets.utils.playerIsInactive(p) then return end


	fields.timer = (fields.timer or 0) + (math.abs(p.speedX)+math.abs(p.speedY))
	fields.totalCoins = (fields.totalCoins or 0)


	if fields.timer > 48 then
		fields.timer = 0
		addCoins(1)

		Effect.spawn(11,p.x+(p.width/2),p.y)
		SFX.play(14)


		fields.totalCoins = fields.totalCoins + 1

		if fields.totalCoins >= properties.customConfig.maxCoins then
			helmets.setCurrentType(p,nil)
		end
	end
end



helmets.registerType(npcID,helmetNPC,{
	name = "coinBlock",

	protectFromHarm = false,

	frames = 4,
	frameStyle = helmets.FRAMESTYLE.STATIC,

	lostEffectID = lostEffectID,

	onTick = helmetNPC.onTickHelmet,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		maxCoins = 80,
	},
})

return helmetNPC