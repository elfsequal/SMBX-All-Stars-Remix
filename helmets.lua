--[[

	Written by MrDoubleA
    Please give credit!

    Part of helmets.lua



    Documentation for this library:
    https://docs.google.com/document/d/1-FON-Mwr-KCKGbDoKNzPi_uBcx4WiuBfRJX4brCBaQU/edit?usp=sharing

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local playerManager = require("playerManager")


local helmets = {}


local THROWN_NPC_COOLDOWN    = 0x00B2C85C
local SHELL_HORIZONTAL_SPEED = 0x00B2C860
local SHELL_VERTICAL_SPEED   = 0x00B2C864

local colBox  = Colliders.Box(0,0,0,0)
local colBox2 = Colliders.Box(0,0,0,0)


helmets.FRAMESTYLE = {
    STATIC      = 0, -- Graphics are not affected by which way the player faces
    MANUAL_FLIP = 1, -- A second set of frames are used when facing right
    AUTO_FLIP   = 2, -- Graphics are automatically flipped when facing right
}


helmets.idList = {}
helmets.idMap  = {}

helmets.typeProperties = {}
helmets.typeList       = {}


local function convertToPlayer(p) -- Converts an index to the player object, and nil to player 1
    if type(p) == "number" then
        return Player(p)
    else
        return (p or player)
    end
end


local function playerIsInactive(p)
    return (p.forcedState > 0 or p.deathTimer > 0 or p:mem(0x13C,FIELD_BOOL) or p.isMega)
end
local function npcIsInactive(npc)
    return (npc.isGenerator or npc.isHidden or npc.despawnTimer <= 0 or npc:mem(0x12C,FIELD_WORD) > 0 or npc:mem(0x138,FIELD_WORD) > 0 or npc.friendly)
end

local function getSFX(currentSFX,name,sfxName,default)
    if type(currentSFX) == "string" then
        return SFX.open(currentSFX)
    elseif currentSFX == nil then
        local resolved = (Misc.resolveSoundFile("helmets_".. name.. "_".. sfxName) or Misc.resolveSoundFile("helmets_".. sfxName))

        if resolved ~= nil then
            return SFX.open(resolved)
        else
            return default
        end
    else
        return currentSFX
    end
end
local function playSFX(sfx,loops)
    if type(sfx) == "table" then
        return playSFX(RNG.irandomEntry(sfx),loops)
    elseif sfx then
        return SFX.play{sound = sfx,loops = loops or 1}
    end
end


function helmets.registerType(id,library,properties)
    if properties.texture == nil then
        properties.texture = Graphics.loadImageResolved("helmets_".. properties.name.. ".png")
    elseif type(properties.texture) == "string" then
        properties.texture = Graphics.loadImageResolved(properties.texture)
    end
    if properties.frameStyle == nil then
        properties.frameStyle = helmets.FRAMESTYLE.STATIC
    end
    if properties.protectFromHarm == nil then
        properties.protectFromHarm = true
    end
    
    properties.getSFX = getSFX(properties.getSFX,properties.name,"get",41)
    properties.lostSFX = getSFX(properties.lostSFX,properties.name,"lost",35)

    properties.library = library
    properties.npcID = id


    table.insert(helmets.typeList,properties.name)
    helmets.typeProperties[properties.name] = properties


    npcManager.registerEvent(id,helmets,"onTickNPC")

    table.insert(helmets.idList,id)
    helmets.idMap[id] = properties
end


local playerData = {}
function helmets.getPlayerData(p)
    playerData[p] = playerData[p] or {}
    return playerData[p]
end


function helmets.getCurrentType(p)
    p = convertToPlayer(p)

    local data = helmets.getPlayerData(p)

    return data.currentHelmet
end

function helmets.setCurrentType(p,newType,isInstant)
    -- Shuffle around the arguments a bit
    if type(p) == "string" or p == nil then
        isInstant = newType
        newType = p
        p = player
    else
        p = convertToPlayer(p)
    end

    local data = helmets.getPlayerData(p)


    if data.currentHelmet == newType then return end


    if not isInstant then
        if newType ~= nil then
            local properties = helmets.typeProperties[newType]


            if properties.protectFromHarm then
                p:mem(0x140,FIELD_WORD,50)
            end
            if properties.getSFX then
                playSFX(properties.getSFX)
            end
        else
            local properties = helmets.typeProperties[data.currentHelmet]


            if properties.protectFromHarm then
                p:mem(0x140,FIELD_WORD,150)
            end
            if properties.lostEffectID then
                local effect = Effect.spawn(properties.lostEffectID,p.x+(p.width),p.y)

                effect.direction = p.direction
            end
            if properties.lostSFX then
                playSFX(properties.lostSFX)
            end
        end
    end

    -- Trigger onLost
    local properties = helmets.typeProperties[data.currentHelmet]

    if properties ~= nil and properties.onLost ~= nil then
        properties.onLost(p,properties)
    end


    data.currentHelmet = newType
    data.customFields = {}
end


function helmets.onInitAPI()
    registerEvent(helmets,"onTick")
    registerEvent(helmets,"onDraw")

    registerEvent(helmets,"onPlayerHarm")
    registerEvent(helmets,"onPostPlayerKill")

    registerEvent(helmets,"onNPCHarm","onNPCHarmShell")
end



-- Events for the helmets on players
do
    local function callEvent(name,...)
        for _,p in ipairs(Player.get()) do
            local data = helmets.getPlayerData(p)
            
            if data.currentHelmet ~= nil then
                local properties = helmets.typeProperties[data.currentHelmet]
                local func = properties[name]

                if func ~= nil then
                    func(p,properties,...)
                end
            end
        end
    end

    function helmets.onTick()
        for _,p in ipairs(Player.get()) do
            if p.isMega and not p.keepPowerOnMega then
                helmets.setCurrentType(p,nil)
            end
        end

        callEvent("onTick")
    end
    function helmets.onDraw()
        callEvent("onDraw")
    end
end


function helmets.onPlayerHarm(eventObj,p)
    local type = helmets.getCurrentType(p)
    
    if type ~= nil then
        local properties = helmets.typeProperties[type]

        if properties.protectFromHarm then
            helmets.setCurrentType(p,nil)
            eventObj.cancelled = true
        end
    end
end
function helmets.onPostPlayerKill(p)
    helmets.setCurrentType(p,nil)
end



-- The actual helmet NPC's logic
function helmets.onTickNPC(v)
	if Defines.levelFreeze or v.despawnTimer <= 0 or v:mem(0x138,FIELD_WORD) > 0 then return end
    
    local properties = helmets.idMap[v.id]
    local config = NPC.config[v.id]


    if config.equipableFromDucking then
        local holdingPlayer = Player(v:mem(0x12C,FIELD_WORD))
        
        if helmets.getCurrentType(holdingPlayer) == nil and holdingPlayer.keys.down == KEYS_PRESSED then
            helmets.setCurrentType(holdingPlayer,properties.name)
            v:kill(HARM_TYPE_OFFSCREEN)

            return
        end
    end

    if config.equipableFromBottom or config.equipableFromTouch then
        colBox.x,colBox.y = v.x+v.speedX,v.y+v.speedY
        colBox.width,colBox.height = v.width,v.height
        
        for _,p in ipairs(Player.get()) do
            if helmets.getCurrentType(p) == nil and not playerIsInactive(p) and (config.equipableFromTouch or p.y >= v.y+v.height) then
                colBox2.x,colBox2.y = p.x+p.speedX,p.y+p.speedY
                colBox2.width,colBox2.height = p.width,p.height

                if colBox:collide(colBox2) then
                    helmets.setCurrentType(p,properties.name)
                    v:kill(HARM_TYPE_OFFSCREEN)

                    return
                end
            end
        end
    end
end


do
    helmets.ai = {onTick = {},onDraw = {},onCameraDraw = {},onLost = {}}


    local getHelmetPosition -- Reserve for later

    
    





    function helmets.ai.onTick.PROPELLER_BOX(p,properties)

    end




    function helmets.ai.onTick.BULLET_MASK(p,properties)

    end

    function helmets.ai.onLost.BULLET_MASK(p,properties)

    end



    function helmets.ai.onTick.POW_BOX(p,properties)

    end

    function helmets.ai.onCameraDraw.POW_BOX(p,properties,camIdx)
        if properties.customConfig.ringShader == nil then return end


        local c = Camera(camIdx)

        local data = helmets.getPlayerData(p)
        local fields = data.customFields

        if not fields.hitActive then return end


        local color = properties.customConfig.ringColor or Color.white
        color = Color(color.r,color.g,color.b,color.a)

        color.a = color.a * math.clamp(2-((fields.hitCollider.radius/properties.customConfig.hitRadius)*2),0,1)
        
    

        Graphics.drawBox{
            x = 0,y = 0,width = c.width,height = c.height,priority = 0,
            shader = properties.customConfig.ringShader,uniforms = {
                screenSize = vector(c.width,c.height),

                color = color,
                ringSize = properties.customConfig.ringSize,

                position = vector(fields.hitCollider.x,fields.hitCollider.y)-vector(c.x,c.y),
                radius = fields.hitCollider.radius,
            },
        }
    end



    --- onDraw functions ---

    
end

-- Utils stuff
do
    helmets.utils = {}


    -- General convenience functions

    helmets.utils.playerIsInactive = playerIsInactive
    helmets.utils.playSFX = playSFX


    function helmets.utils.getPlayerGravity(p)
        local gravity = Defines.player_grav
        if p:mem(0x34,FIELD_WORD) > 0 and p:mem(0x06,FIELD_WORD) == 0 then
            gravity = gravity*0.1
        elseif p:mem(0x3A,FIELD_WORD) > 0 then
            gravity = 0
        elseif playerManager.getBaseID(p.character) == CHARACTER_LUIGI then
            gravity = gravity*0.9
        end
    
        return gravity
    end


    -- Returns if a player is wall sliding with anotherwalljump.lua
    local anotherwalljumpEnabled = nil
    local anotherwalljump
    function helmets.utils.isWallSliding(p)
        if anotherwalljumpEnabled == nil then
            -- Try to find anotherwalljump if we haven't already
            pcall(function() anotherwalljump = anotherwalljump or require("anotherwalljump") end)
            pcall(function() anotherwalljump = anotherwalljump or require("aw")              end)

            anotherwalljumpEnabled = (anotherwalljump ~= nil and anotherwalljump.isWallSliding ~= nil)
        end

        return (anotherwalljumpEnabled and anotherwalljump.isWallSliding(p) ~= 0)
    end


    -- Stops and deletes any sound objects that are included in 'soundNames' and are in 'data.customFields'.
    -- For example, if you made 'soundNames' '{"mySoundObj"}', then it'd stop the sound effect in 'data.customFields.mySoundObj'.
    function helmets.utils.stopSounds(data,soundNames)
        local fields = data.customFields

        for _,name in ipairs(soundNames) do
            if fields[name] ~= nil then
                fields[name]:stop()
            end

            fields[name] = nil
        end
    end
    -- Similar to stopSounds, except it changes the volume of the sound effects by 'amount', pausing it if it reaches 0.
    function helmets.utils.changeSoundsVolume(data,soundNames,amount)
        local fields = data.customFields

        for _,name in ipairs(soundNames) do
            if fields[name] ~= nil then
                local sfx = fields[name]
                
                sfx.volume = math.clamp(sfx.volume + amount,0,1)

                if sfx.volume == 0 then
                    sfx:pause()
                else
                    sfx:resume()
                end
            end
        end
    end

    -- Returns true if 'soundObj' is not nil and is currently playing.
    function helmets.utils.soundObjIsPlaying(soundObj)
        return (soundObj ~= nil and soundObj:isPlaying())
    end


    -- Frame-related functions

    --[[
        Sets the frame of the helmet, depending on if the player is facing backwards or forwards. Order is:

        0 - Facing sideways
        1 - Facing forwards
        2 - Facing backwards
        3 - (If 'hasYoshiFrame' is true) Riding yoshi
    ]]
    local frontFrames = table.map{0,15,27}
    local backFrames = table.map{13,25,26}
    local duckingFrames = table.map{7}

    local smb2Characters = table.map{CHARACTER_PEACH,CHARACTER_TOAD}

    function helmets.utils.useFacingFrames(p,properties,hasYoshiFrame)
        local data = helmets.getPlayerData(p)
        local fields = data.customFields

        local playerFrame = math.abs(p.frame)

        if p.mount == 3 and hasYoshiFrame then
            fields.frame = 3
        elseif backFrames[playerFrame] then
            fields.frame = 2
        elseif frontFrames[playerFrame] or (duckingFrames[playerFrame] and smb2Characters[p.character]) then
            fields.frame = 1
        else
            fields.frame = 0
        end
    end

    -- Causes a simple animation, going from one frame to the next. 'frameSpeed' defaults to 8 and 'frames' defaults to properties.frames.
    function helmets.utils.simpleAnimation(p,properties,frameSpeed,frames)
        local data = helmets.getPlayerData(p)
        local fields = data.customFields

        frameSpeed = frameSpeed or 8
        frames     = frames     or properties.frames

        fields.animationTimer = (fields.animationTimer or 0) + 1
        fields.frame = (math.floor(fields.animationTimer/frameSpeed)%frames)
    end


    -- AI functions below

    function helmets.utils.shake(p,properties)
        local data = helmets.getPlayerData(p)
        local fields = data.customFields

        if playerIsInactive(p) then
            fields.rotation = nil
            return
        end

        fields.shakeDirection = fields.shakeDirection or 1
        fields.rotation = fields.rotation or 0

        if p.speedX == 0 then
            if fields.rotation > 0 then
                fields.rotation = math.max(0,fields.rotation-3)
            elseif fields.rotation < 0 then
                fields.rotation = math.min(0,fields.rotation+3)
            end
        elseif math.abs(fields.rotation) > 8 and math.sign(fields.rotation) == fields.shakeDirection then
            fields.shakeDirection = -fields.shakeDirection
        else
            fields.rotation = fields.rotation+(fields.shakeDirection*math.abs(p.speedX))
        end
    end



    -- A lot 1.3 NPCs have nogravity set to false despite having the effects of nogravity, so here's a map of those IDs
    local noGravityIDs = table.map{
        8,11,16,17,18,37,38,40,41,42,43,44,46,47,50,51,52,56,57,60,62,64,66,74,85,87,91,93,104,105,106,108,133,159,160,180,196,197,
        203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,245,246,255,256,257,
        259,260,266,269,270,271,272,274,276,282,283,289,290,292,
    }
    function helmets.utils.onTickShell(p,properties)
        local data = helmets.getPlayerData(p)
        local fields = data.customFields

        helmets.utils.useFacingFrames(p,properties,true)
        helmets.utils.shake(p,properties)


        if helmets.utils.playerIsInactive(p) then
            return
        end


        colBox.x,colBox.y = p.x-p.speedX,p.y+(p.speedY*2)-1
        colBox.width,colBox.height = p.width,1

        for _,npc in NPC.iterate() do
            local config = NPC.config[npc.id]

            if not npcIsInactive(npc) and (npc:mem(0x130,FIELD_WORD) ~= p.idx or npc:mem(0x12E,FIELD_WORD) == 0) and (not config.nohurt and not NPC.COLLECTIBLE_MAP[npc.id]) then
                colBox2.x,colBox2.y = npc.x+npc.speedX,npc.y+(npc.speedY*2)
                colBox2.width,colBox2.height = npc.width,npc.height

                if colBox:collide(colBox2) then
                    if (npc.width*npc.height < (24^2)) then
                        npc:kill(HARM_TYPE_NPC)
                    else
                        if properties.customConfig.isSpiny then
                            npc:harm(HARM_TYPE_NPC)
                        end

                        if (config.nogravity or noGravityIDs[npc.id]) or config.isheavy then
                            p:mem(0x11C,FIELD_WORD,0)
                            p.speedY = 5
                        else
                            npc.speedY = -5
                        end
                    end

                    playSFX(properties.customConfig.hitSFX)
                end
            end
        end

        if properties.customConfig.isSpiny then
            for _,block in Block.iterateIntersecting(p.x,p.y-1,p.x+p.width,p.y) do
                if not block.isHidden and not block:mem(0x5A,FIELD_BOOL) and Block.MEGA_STURDY_MAP[block.id] then
                    block:remove(true)
                end
            end
        end
    end




    -- Default onDraw function
    do
        local invisibleStates = table.map{5,8,10}
        local frameStyleMultipliers = {
            [helmets.FRAMESTYLE.STATIC     ] = 1,
            [helmets.FRAMESTYLE.MANUAL_FLIP] = 2,
            [helmets.FRAMESTYLE.AUTO_FLIP  ] = 1,
        }

        local clownCarOffsets = {
            [CHARACTER_MARIO] = {[PLAYER_SMALL] = 24,[PLAYER_BIG] = 36},
            [CHARACTER_LUIGI] = {[PLAYER_SMALL] = 24,[PLAYER_BIG] = 38},
            [CHARACTER_PEACH] = {[PLAYER_SMALL] = 24,[PLAYER_BIG] = 30},
            [CHARACTER_TOAD]  = {[PLAYER_SMALL] = 24,[PLAYER_BIG] = 30},
            [CHARACTER_LINK]  = {[PLAYER_SMALL] = 30,[PLAYER_BIG] = 30},
        }

        local function getPriority(p)
            if p.forcedState == 3 then
                return -70
            else
                return -25
            end
        end
        local function round(a)
            if a%1 < 0.5 then
                return math.floor(a)
            else
                return math.ceil(a)
            end
        end

        function helmets.utils.getHelmetPosition(p,properties)
            local playerSettings = PlayerSettings.get(playerManager.getBaseID(p.character),p.powerup)
            local position = vector(p.x+(p.width/2),p.y)


            -- Find the offset
            local offset = helmets.offsets
            if p.mount == 3 then
                offset = offset.onYoshi
            end

            offset = offset[p:getCostume()] or offset[p.character] or offset.default
            offset = offset[p.powerup] or offset[PLAYER_BIG]

            if type(offset) == "table" then
                offset = offset[p.frame] or offset.default
            end
            if type(offset) == "number" then
                offset = vector(0,offset)
            end


            local width,height = p.width,p.height
            if p.mount == 2 then
                width,height = playerSettings.hitboxWidth,playerSettings.hitboxHeight

                local clownCarOffset = clownCarOffsets[playerManager.getBaseID(p.character)]
                position.y = position.y - (clownCarOffset[p.powerup] or clownCarOffset[PLAYER_BIG])
            elseif p.mount == 3 then
                position.y = position.y + p:mem(0x10E,FIELD_WORD)

                if p:mem(0x12E,FIELD_BOOL) then
                    position.y = position.y + 14
                end
            end

            position = position + vector((offset.x*width)*p.direction,offset.y*height)
            position = position + (properties.offset or vector(0,0))


            return position
        end


        -- These values are multiplied by the width/height of the player to get the helmet's position. If it's a number, it'll act as just a Y offset
        helmets.offsets = {}
        helmets.offsets.default = {
            [PLAYER_SMALL] = 0.1,
            [PLAYER_BIG]   = 0.2,
        }

        -- Character-specific offsets
        helmets.offsets[CHARACTER_LINK] = {
            [PLAYER_BIG] = {
                default = -0.05,
                [6] = vector(-0.25,-0.05), -- Prepare for stab
                [7] = vector(0.65,-0.05),  -- Stab
                [8] = vector(0.75,-0.05),  -- Crouching stab
            },
        }
        helmets.offsets[CHARACTER_NINJABOMBERMAN] = {
            [PLAYER_BIG] = {
                default = -0.1,
                [7] = 0.2, -- Ducking
            },
        }
        helmets.offsets[CHARACTER_MEGAMAN] = {
            [PLAYER_BIG] = {
                default = vector(0.15,-0.05),
                [3]  = vector(0.15,0.1),   -- Walking 1
                [4]  = vector(0.15,0.1),   -- Walking 2
                [6]  = vector(0.45,-0.05), -- Shooting
                [16] = -0.35,              -- Hurt
            },
        }
        helmets.offsets[CHARACTER_WARIO] = {
            [PLAYER_SMALL] = 0.1,
            [PLAYER_BIG]   = {
                default = vector(0.1,-0.1),
                [7]  = vector(0.25,-0.2), -- Ducking
                [22] = vector(0.25,-0.2), -- Crawling 1
                [23] = vector(0.25,-0.2), -- Crawling 2
                [32] = vector(0.3,-0.1),  -- Shoulder bash 1
                [33] = vector(0.3,-0.1),  -- Shoulder bash 2
            },
        }
        helmets.offsets[CHARACTER_KLONOA] = {
            [PLAYER_BIG] = {
                default = vector(0.15,0.25),
                [35] = vector(-0.35,0.25), -- Ring?? attack? thing???
            }
        }

        helmets.offsets[CHARACTER_PEACH]           = {[PLAYER_BIG] = 0.1}
        helmets.offsets[CHARACTER_TOAD]            = {[PLAYER_BIG] = 0.15}
        helmets.offsets[CHARACTER_BOWSER]          = {[PLAYER_BIG] = vector(0.35,0.05)}
        helmets.offsets[CHARACTER_ROSALINA]        = {[PLAYER_BIG] = 0.1}
        helmets.offsets[CHARACTER_SNAKE]           = {[PLAYER_BIG] = vector(0.1,-0.05)}
        helmets.offsets[CHARACTER_ULTIMATERINKA]   = {[PLAYER_BIG] = 0}
        helmets.offsets[CHARACTER_UNCLEBROADSWORD] = {[PLAYER_BIG] = 0.1}

        -- Costume-specific offsets
        helmets.offsets["SMW-MARIO"] = {
            [PLAYER_SMALL] = {
                default = 0,
                [35] = 0.35, -- Ducking
                [36] = 0.35, -- Ducking with an item
            },
            [PLAYER_BIG] = {
                default = 0.15,
                [27] = vector(0.1,0.15), -- Victory
            },
        }
        helmets.offsets["SMW-LUIGI"] = {
            [PLAYER_SMALL] = {
                default = -0.1,
                [35] = 0.35, -- Ducking
                [36] = 0.35, -- Ducking with an item
            },
            [PLAYER_BIG] = {
                default = 0.2,
                [27] = vector(0.1,0.2), -- Victory
            },
        }
        helmets.offsets["SMW2-YOSHI"] = {
            [PLAYER_BIG] = {
                default = vector(0.35,-0.1),
                [14] = vector(0.55,0.1), -- Spit out
                [35] = vector(0.55,0.1), -- Tongue
            }
        }

        -- Yoshi offsets
        helmets.offsets.onYoshi = {}
        helmets.offsets.onYoshi.default = {
            [PLAYER_SMALL] = vector(-0.5,-0.5),
            [PLAYER_BIG]   = vector(-0.3,0.1),
        }

        function helmets.utils.onDrawDefault(p,properties)
            if p.deathTimer > 0 or p:mem(0x13C,FIELD_BOOL) or invisibleStates[p.forcedState] or p:mem(0x142,FIELD_BOOL) then return end

            local data = helmets.getPlayerData(p)
            local fields = data.customFields

            
            if fields.sprite == nil then
                fields.sprite = Sprite{texture = properties.texture,frames = vector(properties.variantFrames or 1,properties.frames*frameStyleMultipliers[properties.frameStyle]),pivot = vector(0.5,0.5)}
            end


            local frame = vector(fields.variantFrame or 0,fields.frame or 0)
            
            local direction = p.direction
            if p.frame < 0 then
                direction = -direction
            end

            if properties.frameStyle == helmets.FRAMESTYLE.MANUAL_FLIP and direction == DIR_RIGHT then
                frame.y = frame.y+properties.frames
            elseif properties.frameStyle == helmets.FRAMESTYLE.AUTO_FLIP then
                fields.sprite.texpivot = vector((direction+1)*0.5,0)
                fields.sprite.width = fields.sprite.texture.width*-direction
            end


            local position = helmets.utils.getHelmetPosition(p,properties)
            position = vector(round(position.x),round(position.y))

            fields.sprite.position = position
            fields.sprite.rotation = (fields.rotation or 0)

            fields.sprite:draw{frame = frame+1,priority = getPriority(p),sceneCoords = true}
        end
    end
end


-- Shell stuff I guess
do
    helmets.shellIDList = {}
    helmets.shellIDMap  = {}

    function helmets.registerShell(id)
        table.insert(helmets.shellIDList,id)
        helmets.shellIDMap[id] = true
    end

    function helmets.onNPCHarmShell(eventObj,v,reason,culprit)
        if not helmets.shellIDMap[v.id] then return end
        
        local culpritIsPlayer = (culprit and culprit.__type == "Player")
        local culpritIsNPC    = (culprit and culprit.__type == "NPC"   )

        if reason == HARM_TYPE_JUMP then
            if v:mem(0x138,FIELD_WORD) == 2 then
                v:mem(0x138,FIELD_WORD,0)
            end

            if culpritIsPlayer and culprit:mem(0xBC,FIELD_WORD) <= 0 and culprit.mount ~= 2 then
                if v.speedX == 0 and (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx) then
                    SFX.play(9)
                    v.speedX = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT)*culprit.direction
                    v.speedY = 0
                    
                    v:mem(0x12E,FIELD_WORD,mem(THROWN_NPC_COOLDOWN,FIELD_WORD))
                    v:mem(0x130,FIELD_WORD,culprit.idx)
                    v:mem(0x132,FIELD_BOOL,true)
                elseif (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx) or (v:mem(0x22,FIELD_WORD) == 0 and (culpritIsPlayer and culprit:mem(0x40,FIELD_WORD) == 0)) then
                    SFX.play(2)
                    v.speedX = 0
                    v.speedY = 0

                    if v:mem(0x1C,FIELD_WORD) > 0 then
                        v:mem(0x18,FIELD_FLOAT,0)
                        v:mem(0x132,FIELD_BOOL,true)
                    end
                end
            end
        elseif reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
            SFX.play(9)

            v:mem(0x132,FIELD_BOOL,true)
            v.speedY = -5
            v.speedX = 0
        elseif reason == HARM_TYPE_LAVA then
            v:mem(0x122,FIELD_WORD,reason)
        elseif reason ~= HARM_TYPE_PROJECTILE_USED then
            if reason == HARM_TYPE_NPC then
                if not (v.id == 24 and culpritIsNPC and (culprit.id == 13 or culprit.id == 108)) then
                    v:mem(0x122,FIELD_WORD,reason)
                end
            else
                v:mem(0x122,FIELD_WORD,reason)
            end
        elseif reason == HARM_TYPE_PROJECTILE_USED then
            if culpritIsNPC and culprit:mem(0x132,FIELD_BOOL) and (culprit.id < 117 or culprit.id > 120) then
                v:mem(0x122,FIELD_WORD,reason)
            end
        end

        eventObj.cancelled = true
    end
end


return helmets