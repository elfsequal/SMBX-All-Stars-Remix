--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local explosions = Particles.Emitter(0, 0, Misc.resolveFile("ap_goldflower_explosion.ini"))

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 16,
	gfxwidth = 16,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 16,
	height = 16,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	powerup = false,
	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,
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
npcManager.setNpcSettings(sampleNPCSettings)

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
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onPostNPCKill")
	registerEvent(sampleNPC, "onDraw")
end

local function explode(v)
	v:kill(9)
	explosions.x = v.x + 0.5 * v.width
	explosions.y = v.y + 0.5 * v.height
	explosions:Emit(1)
	SFX.play("explode.ogg")
	local circ = Colliders.Circle(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 64)
	for k,n in ipairs(Colliders.getColliding{
		atype = Colliders.NPC,
		b = circ,
		filter = function(o)
			if NPC.HITTABLE_MAP[o.id] and not o.friendly and not o.isHidden then
				return true
			end
		end
	}) do
		n:harm(3)
		NPC.spawn(10, n.x + 0.5 * n.width, n.y + 0.5 * n.height, player.section, false, true)
	end

	for k,n in ipairs(Colliders.getColliding{
		atype = Colliders.BLOCK,
		b = circ,
		filter = function(o)
			if Block.MEGA_SMASH_MAP[o.id] and not o.isHidden then
				return true
			end
		end
	}) do
		n:remove(3)
		NPC.spawn(10, n.x + 0.5 * n.width, n.y + 0.5 * n.height, player.section, false, true)
	end
end

function sampleNPC.onPostNPCKill(v, rsn)
	if v.id == npcID and rsn ~= 9 then
		explode(v)
	end
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end

	data.speedX = data.speedX or v.speedX
	
	--Execute main AI. This template just jumps when it touches the ground.
	if v.collidesBlockBottom then
		v.speedY = -6
	end

	if math.sign(v.speedX) ~= math.sign(data.speedX) or v.collidesBlockUp then
		explode(v)
	end
end
-- No need to register. Runs only when powerup is active.
function sampleNPC.onDraw()
    explosions:Draw(-5)
end

--Gotta return the library table!
return sampleNPC