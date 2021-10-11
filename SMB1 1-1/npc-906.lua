--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local friendlyNPC = require("npcs/ai/friendlies")

--Create the library table
local friendlies = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local friendliesSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 32,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	

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
local configFile = npcManager.setNpcSettings(friendliesSettings)

function friendlies.onInitAPI()
	npcManager.registerEvent(npcID, friendlies, "onTickNPC")
	npcManager.registerEvent(npcID, friendlies, "onDrawNPC")
end

function friendlies.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data
	
	if not Misc.isPaused() then
		if not Defines.levelFreeze then
			data.sprite:rotate(data.rotation)
		end
	end
	
	if data.type == 32 then
		v.animationFrame = 32
	elseif data.type == 31 then
		v.animationFrame = 31
	elseif data.type == 30 then
		v.animationFrame = 30
    elseif data.type == 29 then
	    v.animationFrame = 29
	elseif data.type == 28 then
		v.animationFrame = 28
	elseif data.type == 27 then
		v.animationFrame = 27
	elseif data.type == 26 then
		v.animationFrame = 26
	elseif data.type == 25 then
		v.animationFrame = 25
	elseif data.type == 24 then
		v.animationFrame = 24	
	elseif data.type == 23 then
		v.animationFrame = 23
    elseif data.type == 22 then
	    v.animationFrame = 22
    elseif data.type == 21 then
		v.animationFrame = 21
	elseif data.type == 20 then
		v.animationFrame = 20
	elseif data.type == 19 then
		v.animationFrame = 19
	elseif data.type == 18 then
		v.animationFrame = 18
	elseif data.type == 17 then
		v.animationFrame = 17		
	elseif data.type == 16 then
		v.animationFrame = 16
    elseif data.type == 15 then
	    v.animationFrame = 15
    elseif data.type == 14 then
		v.animationFrame = 14
	elseif data.type == 13 then
		v.animationFrame = 13
	elseif data.type == 12 then
		v.animationFrame = 12
	elseif data.type == 11 then
		v.animationFrame = 11
	elseif data.type == 10 then
		v.animationFrame = 10		
	elseif data.type == 9 then
		v.animationFrame = 9
    elseif data.type == 8 then
	    v.animationFrame = 8
    elseif data.type == 7 then
		v.animationFrame = 7
	elseif data.type == 6 then
		v.animationFrame = 6
	elseif data.type == 5 then
		v.animationFrame = 5
	elseif data.type == 4 then
		v.animationFrame = 4
	elseif data.type == 3 then
		v.animationFrame = 3	
	elseif data.type == 2 then
		v.animationFrame = 2
	elseif data.type == 1 then
		v.animationFrame = 1
	elseif data.type == 0 then
	    v.animationFrame = 0
	end
end	

function friendlies.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	data.state = data.state or 0
	data.timer = data.timer or 0
	data.rotation = data.rotation or 0
	
	if data._settings.respawnable == nil then
		data._settings.respawnable = true
	end
	
	data.type = data._settings.type or 0
	
	data.scale = data.scale or 1
	data.lifetime = data.lifetime or 0
	
	if data.lifetime == 0 then
		data.origin = data.origin or vector(v.x, v.y)
	end
	
	data.sprite = Sprite{
		image = Graphics.sprites.npc[npcID].img,
		x = (v.x + v.width / 2 + 4) - (data.scale * 2 + 2) + configFile.gfxoffsetx,
		y = v.y - (data.scale * 2 + 4) + configFile.gfxoffsety,
		width = configFile.gfxwidth * data.scale,
		height = configFile.gfxheight * data.scale,
		frames = configFile.frames,
		align = Sprite.align.TOP
	}
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		data.timer = 0
		data.rotation = 0
		data.lifetime = 0
		v.speedY = -Defines.npc_grav
		
		if data.origin ~= nil then
			v.x = data.origin.x
			v.y = data.origin.y
		end
		return
	end
end	


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


friendlyNPC.register(npcID)
--Gotta return the library table!
return friendlies