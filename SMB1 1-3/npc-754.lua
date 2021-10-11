--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local lineguide = require("lineguide")


local reznorWheel = {}
local npcID = NPC_ID

local defaultPlatformID = (npcID + 1)
local defaultEnemyID = 413

local reznorWheelSettings = {
	id = npcID,
	
	gfxwidth = 256,
	gfxheight = 256,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 256,
	height = 256,
	
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
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = true,

	
	defaultPlatformID = defaultPlatformID,
	defaultEnemyID = defaultEnemyID,

	-- Controls the quality of the image being displayed. 1 is normal, 0.5 will remove 1x1 pixels.
	renderScale = 0.5,
}

npcManager.setNpcSettings(reznorWheelSettings)
npcManager.registerHarmTypes(npcID,{},{})


lineguide.registerNpcs(npcID)


function reznorWheel.onInitAPI()
	npcManager.registerEvent(npcID, reznorWheel, "onTickNPC")
	npcManager.registerEvent(npcID, reznorWheel, "onDrawNPC")
	npcManager.registerEvent(npcID, reznorWheel, "onCameraDrawNPC")
end


local function getNPCID(id,defaultID)
	if id > 0 then
		return id
	else
		return defaultID
	end
end

local function getPlatformPosition(v,data,config,settings,i)
	local rotation = math.rad(data.rotation + (i - 1)/data.platformCount*360 + settings.startingRotation)

	local x = v.x + v.width *0.5 + math.sin(rotation)*settings.platformDistance
	local y = v.y + v.height*0.5 - math.cos(rotation)*settings.platformDistance

	return x,y
end

local function npcIsValid(v)
	return (v.isValid and v.despawnTimer > 0 and v:mem(0x12C,FIELD_WORD) == 0)
end

local function stopAttachingToLineguides(v)
	local lineguideData = v.data._basegame.lineguide

	if lineguideData ~= nil then
		lineguideData.state = lineguide.states.NORMAL
		lineguideData.attachCooldown = 2
	end
end


reznorWheel.dontUseDontMoveIDMap = table.map{294,600,601,602,603}

local function moveNPCTo(v,x,y)
	local config = NPC.config[v.id]

	if config.playerblocktop or config.playerblock then
        v.speedX = (x - v.x)
        v.speedY = (y - v.y)

        if v.id == 263 then
            v.ai3 = 0
        end
        
        v.dontMove = false
    else
        v.x = x
        v.y = y

        v.speedX = 0
        v.speedY = 0

        v.spawnX = v.x
        v.spawnY = v.y
        v.spawnWidth = v.width
        v.spawnHeight = v.height
		v.spawnSpeedX = v.speedX
		v.spawnSpeedY = v.speedY

        v.dontMove = (not reznorWheel.dontUseDontMoveIDMap[v.id])
    end
end


local function initialisePreSpawnStuff(v)
    local config = NPC.config[v.id]
	local data = v.data

    local settings = v.data._settings


    local platformID = getNPCID(settings.platformID,config.defaultPlatformID)
    local platformConfig = NPC.config[platformID]

	local enemyID = getNPCID(settings.enemyID,config.defaultEnemyID)
	local enemyConfig = NPC.config[enemyID]
    

    local unitsWidth = math.max(platformConfig.width,enemyConfig.width)

    data.spawnMinX = v.spawnX + v.spawnWidth *0.5 - settings.platformDistance - unitsWidth*0.5
	data.spawnMaxX = v.spawnX + v.spawnWidth *0.5 + settings.platformDistance + unitsWidth*0.5
    data.spawnMinY = v.spawnY + v.spawnHeight*0.5 - settings.platformDistance - platformConfig.height*0.5 - enemyConfig.height
    data.spawnMaxY = v.spawnY + v.spawnHeight*0.5 + settings.platformDistance + platformConfig.height*0.5

    -- Set section to allow the wheel itself to be out of bounds
    v.section = Section.getIdxFromCoords(data.spawnMinX,data.spawnMinY,data.spawnMaxX - data.spawnMinX,data.spawnMaxY - data.spawnMinY)
end

local function initialise(v,data,config,settings)
	if data.spawnX == nil then
		initialisePreSpawnStuff(v)
	end

	data.rotation = 0

	data.triggeredEvent = false

	-- Spawn platforms and enemies
	local platformID = getNPCID(settings.platformID,config.defaultPlatformID)
    local platformConfig = NPC.config[platformID]

	local enemyID = getNPCID(settings.enemyID,config.defaultEnemyID)
	local enemyConfig = NPC.config[enemyID]

	data.platformNPCs = {}
	data.enemyNPCs = {}

	data.platformCount = settings.platformCount

	for i = 1,data.platformCount do
		local x,y = getPlatformPosition(v,data,config,settings,i)

		local platform = NPC.spawn(platformID,x,y,v.section,false,true)
		local enemy = NPC.spawn(enemyID,x,y - platform.height*0.5 - enemyConfig.height*0.5,v.section,false,true)

		platform.direction = v.direction
		enemy.direction = v.direction

		data.platformNPCs[i] = platform
		data.enemyNPCs[i] = enemy

		stopAttachingToLineguides(platform)
		stopAttachingToLineguides(enemy)
	end


	data.initialized = true
end

local function deinitialise(v,data)
	for _,npc in ipairs(data.platformNPCs) do
		if npc.isValid then
			npc:kill(HARM_TYPE_VANISH)
		end
	end

	for _,npc in ipairs(data.enemyNPCs) do
		if npc.isValid then
			npc:kill(HARM_TYPE_VANISH)
		end
	end

	data.initialized = false
end


function reznorWheel.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if data.spawnX == nil then
		initialisePreSpawnStuff(v)
	end
	
	if v.despawnTimer <= 0 then
		if data.initialized then
			deinitialise(v,data)
		end

		return
	end

	local config = NPC.config[v.id]
	local settings = v.data._settings

	local lineguideData = v.data._basegame.lineguide

	if not data.initialized then
		initialise(v,data,config,settings)
	end

	if not Layer.isPaused() then
		data.rotation = data.rotation + settings.rotationSpeed
	end


	-- Layer movement
	npcutils.applyLayerMovement(v)

	
	if lineguideData ~= nil then
		-- Apply gravity if using lineguides but not currently attached to one
        if lineguideData.state == lineguide.states.FALLING then
            if v.underwater then
                v.speedY = math.min(1.6, v.speedY + Defines.npc_grav*0.2)
            else
                v.speedY = math.min(8, v.speedY + Defines.npc_grav)
            end
        end

		-- Allow setting line speed via extra settings
        lineguideData.lineSpeed = settings.lineSpeed
    end


	v.despawnTimer = math.max(100,v.despawnTimer)


	-- Update each platform
	for i = 1, data.platformCount do
		local npc = data.platformNPCs[i]

		if npc ~= nil then
			if npcIsValid(npc) then
				local x,y = getPlatformPosition(v,data,config,settings,i)

				moveNPCTo(npc,x - npc.width*0.5,y - npc.height*0.5)

				npc.despawnTimer = math.max(100,npc.despawnTimer)

				stopAttachingToLineguides(npc)
				npc.noblockcollision = true
			else
				data.platformNPCs[i] = nil
			end
		end
	end

	-- Update each enemy
	local hasActiveEnemy = false

	for i = 1, data.platformCount do
		local npc = data.enemyNPCs[i]

		if npc ~= nil then
			if npcIsValid(npc) then
				local platform = data.platformNPCs[i]

				if platform ~= nil then
					npc.x = platform.x + platform.width*0.5 - npc.width*0.5
					npc.y = platform.y - npc.height

					npc.speedX = 0
					npc.speedY = 0.001

					moveNPCTo(npc,platform.x + platform.width*0.5 - npc.width*0.5,platform.y - npc.height)
				end

				npc.despawnTimer = math.max(100,npc.despawnTimer)

				hasActiveEnemy = true

				stopAttachingToLineguides(npc)
				npc.noblockcollision = true
			else
				data.enemyNPCs[i] = nil
			end
		end
	end

	if not hasActiveEnemy and not data.triggeredEvent and settings.allDefeatedEvent ~= "" then
		triggerEvent(settings.allDefeatedEvent)
		data.triggeredEvent = true
	end
end


local npcBuffer = Graphics.CaptureBuffer(320,320)

local lowPriorityStates = table.map{1,3,4}

local function getNPCPriority(v,data,config)
	if v:mem(0x12C,FIELD_WORD) > 0 then
		return -30
	elseif lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		return -75
	end

	if config.foreground then
		return -15
	end

	return -75
end

function reznorWheel.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	local settings = v.data._settings

	if not data.initialized then
		initialise(v,data,config,settings)
	end

	local texture = Graphics.sprites.npc[v.id].img
	if texture == nil then
		return
	end

	local priority = getNPCPriority(v,data,config)

	if data.sprite == nil then
		data.sprite = Sprite{texture = texture,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
	end

	local x = v.x + v.width*0.5 + config.gfxoffsetx
	local y = v.y + v.height - config.gfxheight*0.5 + config.gfxoffsety

	data.sprite.rotation = data.rotation

	if config.renderScale >= 1 then -- renderScale is normal quality, just render like a normal sprite
		data.sprite.x = x
		data.sprite.y = y

		data.sprite.scale.x = 1
		data.sprite.scale.y = 1

		data.sprite:draw{priority = priority,sceneCoords = true}
	else -- renderScale < 1, so render it downscaled to the buffer, and then draw that buffer to the screen
		npcBuffer:clear(priority)
		--Graphics.drawBox{target = npcBuffer,color = Color.red.. 0.2,x = 0,y = 0,width = npcBuffer.width,height = npcBuffer.height,priority = priority}

		data.sprite.x = npcBuffer.width*0.5
		data.sprite.y = npcBuffer.height*0.5

		data.sprite.scale.x = config.renderScale
		data.sprite.scale.y = config.renderScale

		data.sprite:draw{priority = priority,target = npcBuffer}

		Graphics.drawBox{
			texture = npcBuffer,priority = priority,
			sceneCoords = true,centred = true,

			x = x,y = y,
			width = npcBuffer.width/config.renderScale,
			height = npcBuffer.height/config.renderScale,
		}
	end

	--[[Graphics.drawBox{
		color = Color.purple.. 0.25,sceneCoords = true,
		x = data.spawnMinX,y = data.spawnMinY,
		width = data.spawnMaxX - data.spawnMinX,height = data.spawnMaxY - data.spawnMinY,
	}]]

	npcutils.hideNPC(v)
end


function reznorWheel.onCameraDrawNPC(v,camIdx)
    -- The spawning ranging is a bit bigger, so handle all that
    if v.isHidden then
        return
    end


    local data = v.data

	if data.spawnMinX == nil then
        initialisePreSpawnStuff(v,data)
	end


	local c = Camera(camIdx)

	if c.x+c.width > data.spawnMinX and c.y+c.height > data.spawnMinY and data.spawnMaxX > c.x and data.spawnMaxY > c.y then
		-- On camera, so activate (based on this  https://github.com/smbx/smbx-legacy-source/blob/master/modGraphics.bas#L517)
		local resetOffset = (0x126 + (camIdx - 1)*2)

		if v:mem(resetOffset, FIELD_BOOL) or v:mem(0x124,FIELD_BOOL) then
			if not v:mem(0x124,FIELD_BOOL) then
				v:mem(0x14C,FIELD_WORD,camIdx)
			end

			v.despawnTimer = 180
			v:mem(0x124,FIELD_BOOL,true)

            if not data.initialized then
				local config = NPC.config[v.id]
				local settings = v.data._settings

                initialise(v,data,config,settings)
            end
		end

		v:mem(0x126,FIELD_BOOL,false)
		v:mem(0x128,FIELD_BOOL,false)
	end
end


return reznorWheel