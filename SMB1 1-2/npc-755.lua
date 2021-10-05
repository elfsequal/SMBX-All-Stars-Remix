--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local lineguide = require("lineguide")


local reznorPlatform = {}
local npcID = NPC_ID

local reznorPlatformSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 64,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
}

npcManager.setNpcSettings(reznorPlatformSettings)
npcManager.registerHarmTypes(npcID,{},{})


lineguide.registerNpcs(npcID)


function reznorPlatform.onInitAPI()
	npcManager.registerEvent(npcID, reznorPlatform, "onTickNPC")
	npcManager.registerEvent(npcID, reznorPlatform, "onDrawNPC")
end


local function initialise(v,data,config)
	data.bumpUp = 0
	data.bumpDown = 0
	data.initialized = true
end

local function hitNPCs(v,data,config)
	local col = Colliders.getHitbox(v)

	col.height = 4
	col.y = col.y - col.height

	local npcs = Colliders.getColliding{a = col,b = NPC.HITTABLE,btype = Colliders.NPC}

	for _,npc in ipairs(npcs) do
		Block(0).y = npc.y + npc.height
		npc:harm(HARM_TYPE_FROMBELOW)
	end
end


function reznorPlatform.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local config = NPC.config[v.id]
	local lineguideData = v.data._basegame.lineguide

	if not data.initialized then
		initialise(v,data,config)
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.bumpUp = 0
		data.bumpDown = 0
	else
		if data.bumpUp ~= 0 then
			data.bumpUp = data.bumpUp - (math.sign(data.bumpUp)*2)
		elseif data.bumpDown ~= 0 then
			data.bumpDown = data.bumpDown - (math.sign(data.bumpDown)*2)
		end

		-- Check for hits
		for _,p in ipairs(Player.get()) do
			if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
			and p.x+p.width > v.x
			and p.x < v.x+v.width
			and p.y+p.speedY <= v.y+v.height+v.speedY
			and p.y-p.speedY >= v.y+v.height-v.speedY
			then
				data.bumpUp = -12
				data.bumpDown = 12

				hitNPCs(v,data,config)

				break
			end
		end

		-- Apply gravity if using lineguides but not currently attached to one
		if lineguideData ~= nil and lineguideData.state == lineguide.states.FALLING then
			if v.underwater then
				v.speedY = math.min(1.6, v.speedY + Defines.npc_grav*0.2)
			else
				v.speedY = math.min(8, v.speedY + Defines.npc_grav)
			end
		end
	end
end

function reznorPlatform.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	if not data.initialized then
		initialise(v,data,config)
	end

	if data.bumpUp ~= 0 or data.bumpDown ~= 0 then
		npcutils.drawNPC(v,{yOffset = -(data.bumpDown + data.bumpUp)})
		npcutils.hideNPC(v)
	end
end


return reznorPlatform