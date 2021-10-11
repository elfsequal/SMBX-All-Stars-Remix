--[[

	Written by MrDoubleA
	Please give credit!

    Part of helmets.lua

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local helmetNPC = {}
local npcID = NPC_ID


local explosionType = Explosion.register(32,71,43,true,true)

local helmetNPCSettings = {
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
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = true,


	lifetime = 35,
}

npcManager.setNpcSettings(helmetNPCSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN})



local function explode(v)
	local data = v.data

	local effect = Effect.spawn(10,0,0)

	effect.x = v.x+(v.width /2)-(effect.width /2)
	effect.y = v.y+(v.height/2)-(effect.height/2)


	Explosion.spawn(v.x+(v.width/2),v.y+(v.height/2),explosionType,data.player)
	v:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN)
end


function helmetNPC.onInitAPI()
	npcManager.registerEvent(npcID,helmetNPC,"onTickNPC")
end

function helmetNPC.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.lifetime = nil
		return
	end

	if not data.lifetime then
		data.lifetime = config.lifetime
		data.spawnDirection = v.direction
	end
	

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then return end



	data.lifetime = data.lifetime - 1

	if data.lifetime <= 0 or v:mem(0x120,FIELD_BOOL) or v.direction ~= data.spawnDirection or (v.collidesBlockUp or v.collidesBlockRight or v.collidesBlockBottom or v.collidesBlockLeft) then
		explode(v)
	end
end

return helmetNPC