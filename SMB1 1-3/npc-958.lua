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


function helmetNPC.onTickHelmet(p,properties)
	local data = helmets.getPlayerData(p)
	local fields = data.customFields


	fields.cooldown = math.max(0,(fields.cooldown or 0)-1)
	fields.hitsUsed = fields.hitsUsed or 0


	if not helmets.utils.playerIsInactive(p) and fields.cooldown == 0 and p:mem(0x14A,FIELD_WORD) > 0 then
		local position = helmets.utils.getHelmetPosition(p,properties)
		helmetNPC.createHit(properties.npcID,position.x,position.y)
		
		fields.cooldown = properties.customConfig.hitTime
		fields.hitsUsed = fields.hitsUsed + 1

		if fields.hitsUsed >= properties.customConfig.hits then
			helmets.setCurrentType(p,nil)
		end
	end


	helmets.utils.simpleAnimation(p,properties)
	fields.variantFrame = math.max(0,(properties.variantFrames-properties.customConfig.hits)+fields.hitsUsed)
end


local ringShader = Shader()
ringShader:compileFromFile(nil,Misc.resolveFile("helmets_powBox_ring.frag"))


helmets.registerType(npcID,helmetNPC,{
	name = "powBox",

	frames = 1,
	frameStyle = helmets.FRAMESTYLE.STATIC,

	variantFrames = 3,


	lostEffectID = lostEffectID,

	onTick = helmetNPC.onTickHelmet,
	onDraw = helmets.utils.onDrawDefault,
	customConfig = {
		hits = 3,

		hitRadius = 160,
		hitTime = 24,

		hitSFX = SFX.open(Misc.resolveSoundFile("audio/sfx/helmets_powBox_hit")),

		ringColor = Color.fromHexRGB(0xFF0000),
		ringShader = ringShader,
		ringSize = 16,
	},
})


-- Stuff for the hit effects
helmetNPC.hits = {}
function helmetNPC.createHit(id,x,y)
	local properties = helmets.idMap[id]
	
	local hit = {}

	hit.collider = Colliders.Circle(x,y,0)
	hit.properties = properties
	hit.npcID = id

	hit.isValid = true

	table.insert(helmetNPC.hits,hit)


	Defines.earthquake = 4
	helmets.utils.playSFX(properties.customConfig.hitSFX)


	return hit
end

function helmetNPC.onInitAPI()
	registerEvent(helmetNPC,"onTick")
	registerEvent(helmetNPC,"onCameraDraw")
end


function helmetNPC.onTick()
	local index = 1
	while index <= #helmetNPC.hits do
		local hit = helmetNPC.hits[index]
		local config = hit.properties.customConfig

		hit.collider.radius = hit.collider.radius + (config.hitRadius/config.hitTime)

		-- Destroy stuff
		for _,block in ipairs(Colliders.getColliding{a = hit.collider,btype = Colliders.BLOCK}) do
			block:hit(false)

			if Block.MEGA_SMASH_MAP[block.id] then
				block:remove(true)
			end
		end

		for _,npc in ipairs(Colliders.getColliding{a = hit.collider,b = NPC.HITTABLE,btype = Colliders.NPC}) do
			npc:harm(HARM_TYPE_NPC)
		end


		if hit.collider.radius > config.hitRadius then
			table.remove(helmetNPC.hits,index)
			hit.isValid = false
		else
			index = index + 1
		end
	end
end

function helmetNPC.onCameraDraw(camIdx)
	local c = Camera(camIdx)

	for _,hit in ipairs(helmetNPC.hits) do
		local config = hit.properties.customConfig

		if config.ringShader ~= nil then
			local color = config.ringColor or Color.white
			color = Color(color.r,color.g,color.b,color.a)

			color.a = color.a * math.clamp(2-((hit.collider.radius/config.hitRadius)*2),0,1)
		

			Graphics.drawBox{
				x = 0,y = 0,width = c.width,height = c.height,priority = 0,
				shader = config.ringShader,uniforms = {
					screenSize = vector(c.width,c.height),

					color = color,
					ringSize = config.ringSize,

					position = vector(hit.collider.x,hit.collider.y)-vector(c.x,c.y),
					radius = hit.collider.radius,
				},
			}
		end
	end
end


return helmetNPC