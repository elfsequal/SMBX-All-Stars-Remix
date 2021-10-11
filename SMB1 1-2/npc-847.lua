--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local orbits = API.load("orbits")
local rng = require("rng")

--Create the library table
local ballNChain = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local ballNChainSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	ignorethrownnpcs = true,
	
	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(ballNChainSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function ballNChain.onInitAPI()
	npcManager.registerEvent(npcID, ballNChain, "onTickNPC")
	--npcManager.registerEvent(npcID, ballNChain, "onTickEndNPC")
	--npcManager.registerEvent(npcID, ballNChain, "onDrawNPC")
	--registerEvent(ballNChain, "onNPCKill")
end

function ballNChain.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze or player.forcedState > 0 then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 2 then
		--Reset our properties, if necessary
		v:mem(0x12A, FIELD_WORD, 180)
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		
		settings.speed = settings.speed or 25
		settings.length = settings.length or 3
		settings.angle = settings.angle or 0
		settings.number = settings.number or 1
		
		if v.direction == 0 then
			v.direction = rng.randomInt(1)
			if v.direction == 0 then
				v.direction = -1
			end
		end
		if v.dontMove then
			settings.speed = 0
		end
		--createChainball(v, settings.speed, settings.length, settings.angle)
		for k = settings.length - 1, 1, -1 do
			data.chainlink = orbits.new{
				attachToNPC = v,
				radius = k * 32,
				rotationSpeed = (settings.speed * 0.01) * v.direction,
				angleDegs = settings.angle,
				id = 846,
				number = settings.number,
				section = v:mem(0x146, FIELD_WORD),
				friendly = v.friendly
			}
		end
		data.chainball = orbits.new{
			attachToNPC = v,
			radius = settings.length * 32,
			rotationSpeed = (settings.speed * v.direction) * 0.01,
			angleDegs = settings.angle,
			id = 845,
			number = settings.number,
			section = v:mem(0x146, FIELD_WORD),
			friendly = v.friendly
		}
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--makes it move with its layer
	v.x = v.x + v.layerObj.speedX
	v.y = v.y + v.layerObj.speedY
end

-- function createChainball(npc, rotSpeed, chainLength, startAngle)
	-- for k = chainLength - 1, 1, -1 do
		-- orbits.new{x = npc.x + 16, y = npc.y + 16, radius = k * 32, rotationSpeed = rotSpeed * npc.direction, angleDegs = startAngle, id = 846, number = 1, section = npc:mem(0x146, FIELD_WORD), friendly = npc.friendly}
	-- end
	-- orbits.new{x = npc.x + 16, y = npc.y + 16, radius = chainLength * 32, rotationSpeed = rotSpeed * npc.direction, angleDegs = startAngle, id = 845, number = 1, section = npc:mem(0x146, FIELD_WORD), friendly = npc.friendly}
-- end

--Gotta return the library table!
return ballNChain