--[[

	Written by MrDoubleA
    Please give credit!
    
    Credit to Novarender for doing most of the work on the key's following behaviour

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local hudoverride = require("hudoverride")
local textplus = require("textplus")


local keys = {}


-- Constants
local RAW_BGO_COUNT_ADDR = 0x00B25958 -- bgo count, without the BGOs made by locked warps


-- Some other stuft


keys.keyIDList = {}
keys.keyIDMap = {}

keys.coinIDList = {}
keys.coinIDMap = {}


keys.coinTypesList = {}
keys.coinTypesMap = {}


keys.phantoIDList = {370,625,626}
keys.keyGateIDList = {255}


local npcsToKill

local justReset = false
local storedNPCCount


local colBox = Colliders.Box(0,0,0,0)
local function unlockWarp(warp)
    warp.locked = false

    -- Remove BGO
    colBox.x      = warp.entranceX
    colBox.y      = warp.entranceY
    colBox.width  = warp.entranceWidth
    colBox.height = warp.entranceHeight

    for _,bgo in BGO.iterate() do
        if bgo.idx >= mem(RAW_BGO_COUNT_ADDR,FIELD_WORD) and bgo.id == 98 and colBox:collide(bgo) then -- Belongs to this warp
            bgo.layerName = ""
            bgo.isHidden = true
        end
    end
end


-- Key objects stuff
do
    keys.keyObjects = {}

    setmetatable(keys.keyObjects,{__call = (function(tbl,index)
        if not tbl[index] or type(index) ~= "number" then
            error("Invalid key index")
        end

        return tbl[index]
    end)})


    -- Setup key states
    local KEY_STATE = {
        FOLLOW_CATCH_UP = 0,
        FOLLOW          = 1,

        REWARD_START    = 2,
        REWARD_FLOAT    = 3,
        REWARD_CATCH_UP = 4,

        UNLOCK_GATE     = 5,
        BUBBLE          = 6,
    }

    keys.KEY_STATE = KEY_STATE


    function keys.keyObjects.count()
        return #keys.keyObjects
    end

    function keys.keyObjects.iterate()
        return ipairs(keys.keyObjects)
    end
    function keys.keyObjects.get()
        return keys.keyObjects
    end


    -- Get all the keys that a player has. If includeNotFollowing is true, it may be out of order.
    function keys.keyObjects.getFromPlayer(playerObj,includeNotFollowing) 
        if type(playerObj) == "number" then
            playerObj = Player(playerObj)
        elseif playerObj == nil then
            includeNotFollowing = true
        end


        local ret = {}

        for _,self in keys.keyObjects.iterate() do
            if not includeNotFollowing then
                if self.player == playerObj and self.followingIndex ~= nil then
                    ret[self.followingIndex] = self
                end
            else
                if self.player == playerObj then
                    table.insert(ret,self)
                end
            end
        end

        return ret
    end
    function keys.keyObjects.iterateFromPlayer(playerObj,includeNotFollowing)
        return ipairs(keys.keyObjects.getFromPlayer(playerObj,includeNotFollowing))
    end



    -- Some convenience functions
    function keys.keyObjects:getConfig()
        return (NPC.config[self.npcID] or {})
    end
    function keys.keyObjects:playSound(name)
        local config = self:getConfig()
        local sound = config[name.. "SFX"]

        if sound then
            SFX.play(sound)
        end
    end

    function keys.keyObjects:startFollowing(teleport)
        if teleport then
            self.position = vector(self.player.x+(self.player.width/2)-(self.size.x/2),self.player.y+self.player.height-self.size.y)
        end


        self.state = KEY_STATE.FOLLOW
        self.timer = 0

        self.followingIndex = #keys.keyObjects.getFromPlayer(self.player)+1
        self.delayFromPlayer = 1

        self.speed = vector.zero2
    end
    function keys.keyObjects:stopFollowing()
        if self.followingIndex == nil then return end

        for _,key in keys.keyObjects.iterateFromPlayer(self.player) do
            if key ~= self and (key.followingIndex ~= nil and key.followingIndex > self.followingIndex) then
                key.followingIndex = key.followingIndex - 1
            end
        end

        self.followingIndex = nil
        self.delayFromPlayer = nil

        self.isStill = nil
        self.isGrounded = nil

        self.bounceSpeed = nil
        self.bounceOffset = nil
    end
    function keys.keyObjects:remove()
        self._toBeRemoved = true

        -- Cleanup
        self:stopFollowing()
        if self.light ~= nil and self.light.isValid then
            self.light:destroy()
        end
    end

    function keys.keyObjects:setPlayer(playerObj,isReward)
        if type(playerObj) == "number" then
            playerObj = Player(playerObj)
        end


        local config = self:getConfig()

        self.player = playerObj

        if playerObj ~= nil then -- Assigning to a player
            local playerKeys = keys.keyObjects.getFromPlayer(playerObj,true)

            if #playerKeys <= keys.maxKeysPerPlayer then -- The player has enough room for this key
                if isReward then
                    self.state = KEY_STATE.REWARD_START
                    self:playSound("reveal")
                else
                    self.state = KEY_STATE.FOLLOW_CATCH_UP
                end

                self.timer = 0
            else -- The player already has the max amount of keys
                if config.failedCollectionEffectID then
                    Effect.spawn(config.failedCollectionEffectID,self.position.x+(self.size.x/2),self.position.y+(self.size.y/2))
                end
                self:playSound("collectFailed")
        
                self:remove()
            end
        else
            self.state = KEY_STATE.BUBBLE
            self.timer = 0

            self:stopFollowing()
        end
    end

    function keys.keyObjects:updateLight()
        local config = self:getConfig()


        if self.light == nil or not self.light.isValid then
            -- Create light
            local radius = (config.lightradius or 0)
            local color = Color.parse(config.lightcolor or Color.white)
            local brightness = (config.lightbrightness or 0)

            if radius > 0 and (color.r ~= 0 or color.g ~= 0 or color.b ~= 0) and brightness > 0 then	
                self.light = Darkness.addLight(Darkness.light(0,0, radius, brightness, color, config.lightflicker))
            end
        end

        -- Update the light
        if self.light ~= nil and self.light.isValid then
            self.light.x = self.position.x+(self.size.x/2)
            self.light.y = self.position.y+(self.size.y/2)
        end
    end

    -- Following behaviour
    do
        keys.playerTrails = {}

        local function createPlayerPosition(playerObj)
            return {
                position = vector(playerObj.x+(playerObj.width/2),playerObj.y+playerObj.height),
                isGrounded = playerObj:isGroundTouching(),
            }
        end
        local function positionsAreEqual(position1,position2)
            return (position1.position == position2.position and position1.isGrounded == position2.isGrounded)
        end

        local function getPreviousInChain(self,otherKeys) -- Get the object one closer to the player
            if self.followingIndex == 1 then
                return self.player
            else
                return otherKeys[self.followingIndex-1]
            end
        end

        local function getObjectDelay(object)
            if type(object) == "Player" then
                return #keys.playerTrails[object]
            else
                return (object.delayFromPlayer or 1)
            end
        end
        local function getObjectBottomCentre(object)
            if type(object) == "Player" then
                return vector(object.x+(object.width/2),object.y+object.height)
            else
                return vector(object.position.x+(object.size.x/2),object.position.y+object.size.y)
            end
        end
        local function getObjectIsGrounded(object)
            if type(object) == "Player" then
                return object:isGroundTouching()
            else
                return object.isGrounded
            end
        end



        function keys.keyObjects:followPlayer()
            local trail = keys.playerTrails[self.player]
            local goalPosition

            if trail ~= nil then
                goalPosition = trail[self.delayFromPlayer]
            end
            
            
            if goalPosition ~= nil then
                -- Main following behaviour
                local previous = getPreviousInChain(self,trail.keys)
                local previousDelay = getObjectDelay(previous)

                self.speed = (goalPosition.position-getObjectBottomCentre(self))

                self.delayFromPlayer = (self.delayFromPlayer or 1)
                self.isGrounded = goalPosition.isGrounded

                if self.isGrounded then
                    if self.followingIndex == 1 then
                        self.isStill = trail.isStill
                    else
                        self.isStill = previous.isStill
                    end

                    if self.isStill then
                        local distanceFromPrevious = (getObjectBottomCentre(previous)-getObjectBottomCentre(self))

                        if math.abs(distanceFromPrevious.x) > keys.followerKeyMinDistance and self.delayFromPlayer < previousDelay then
                            self.delayFromPlayer = self.delayFromPlayer + 1
                        end
                    else
                        if self.delayFromPlayer < (previousDelay-10) then
                            self.delayFromPlayer = self.delayFromPlayer + 1
                        end
                    end
                else
                    if (getObjectIsGrounded(previous) and self.delayFromPlayer < previousDelay) or (self.delayFromPlayer < (previousDelay-10)) then
                        self.delayFromPlayer = self.delayFromPlayer + 1
                    end
                end

                -- Bouncing
                if self.isGrounded then
                    self.bounceSpeed = (self.bounceSpeed or 0) + Defines.npc_grav
                    self.bounceOffset = math.min(0,(self.bounceOffset or 0) + self.bounceSpeed)

                    if self.bounceOffset >= 0 and not self.isStill then
                        self.bounceSpeed = -1.75
                    end
                else
                    self.bounceOffset = 0
                    self.bounceSpeed = 0
                end

                self.speed.y = self.speed.y + self.bounceOffset
            else
                self.speed = vector.zero2
            end
        end


        function keys.updateTrails()
            for _,playerObj in ipairs(Player.get()) do
                keys.playerTrails[playerObj] = keys.playerTrails[playerObj] or {}
                local trail = keys.playerTrails[playerObj]

                local playerKeys = keys.keyObjects.getFromPlayer(playerObj)


                if (playerObj.forcedState == 0 and playerObj.deathTimer == 0 and not playerObj:mem(0x13C,FIELD_BOOL)) and #playerKeys > 0 then
                    -- Add another position
                    local currentPosition = createPlayerPosition(playerObj)
                    local lastPosition = trail[#trail]


                    trail.keys = playerKeys -- for performance, I guess
                    trail.isStill = (lastPosition and positionsAreEqual(currentPosition,lastPosition))
                    

                    if not trail.isStill then
                        table.insert(trail,currentPosition)
                    end


                    -- Remove some old positions
                    local lastKey = playerKeys[#playerKeys]

                    if lastKey and (lastKey.delayFromPlayer ~= nil and lastKey.delayFromPlayer > 1) then
                        table.remove(trail,1)

                        for _,key in ipairs(playerKeys) do
                            key.delayFromPlayer = (key.delayFromPlayer or 1)-1
                        end
                    end
                elseif #playerKeys == 0 then
                    keys.playerTrails[playerObj] = {}
                end
            end
        end
    end
    

    local stateBehaviour = {}


    stateBehaviour[KEY_STATE.FOLLOW] = (function(self)
        self:followPlayer()
    end)

    stateBehaviour[KEY_STATE.REWARD_START] = (function(self)
        if self.speed.y == 0 then
            self.speed.y = -6
        elseif self.speed.y > -1 then
            self.state = KEY_STATE.REWARD_FLOAT
            self.timer = 0
        else
            self.speed.y = self.speed.y*0.96
        end

        self.speed.x = 0
    end)

    stateBehaviour[KEY_STATE.REWARD_FLOAT] = (function(self)
        if self.timer > 48 then
            self.state = KEY_STATE.REWARD_CATCH_UP
            self.timer = 0

            self:playSound("move")
        else
            if RNG.randomInt(1,16) == 1 then
                Effect.spawn(78,self.position.x+(self.size.x/2),self.position.y+(self.size.y/2))
            end

            self.speed.y = math.cos(self.timer/12)*0.5
        end

        self.speed.x = 0
    end)

    stateBehaviour[KEY_STATE.UNLOCK_GATE] = (function(self)
        if self.keyGateNPC == nil or not self.keyGateNPC.isValid or self.keyGateNPC.isHidden or self.keyGateNPC.despawnTimer <= 0 then
            -- The key gate is invalid, so just go back to the player
            self.state = KEY_STATE.FOLLOW_CATCH_UP
            self.timer = 0

            self:playSound("move")
        else
            local distance = vector(self.keyGateNPC.x+(self.keyGateNPC.width/2),self.keyGateNPC.y+(self.keyGateNPC.height/2))-(self.position+(self.size/2))

            if distance.length < 0.035 then
                self.keyGateNPC:kill(HARM_TYPE_NPC)
                self:remove()
            else
                self.speed = distance*0.125
            end
        end
    end)

    stateBehaviour[KEY_STATE.BUBBLE] = (function(self)
        -- Bubble animation
        self.bubbleSize = (self.bubbleSize or 1)
        self.bubbleSizeIncrease = (self.bubbleSizeIncrease or -0.17)

        if (self.bubbleSize < 0.2 and self.bubbleSizeIncrease < 0) or (self.bubbleSize > 0.8 and self.bubbleSizeIncrease > 0) then
            self.bubbleSizeIncrease = -self.bubbleSizeIncrease
        elseif math.abs(self.bubbleSizeIncrease) < 0.005 then
            self.bubbleSize = (math.cos(self.timer/24)+8)/16
            self.bubbleSizeIncrease = 0
        end

        self.bubbleSize = self.bubbleSize + self.bubbleSizeIncrease
        self.bubbleSizeIncrease = self.bubbleSizeIncrease*0.935

        -- Main behaviour
        local nearestPlayer = Player.getNearest(self.position.x+(self.size.x/2),self.position.y+(self.size.y/2))

        if nearestPlayer ~= nil then
            if nearestPlayer.sectionObj ~= self.sectionObj then -- The player is in a different section
                self.position = vector(
                    math.clamp(self.position.x,nearestPlayer.sectionObj.boundary.left-(self.size.x/2),nearestPlayer.sectionObj.boundary.right -(self.size.x/2)),
                    math.clamp(self.position.y,nearestPlayer.sectionObj.boundary.top -(self.size.y/2),nearestPlayer.sectionObj.boundary.bottom-(self.size.y/2))
                )
            else
                local distance = vector(nearestPlayer.x+(nearestPlayer.width/2),nearestPlayer.y+(nearestPlayer.height/2))-(self.position+(self.size/2))

                local acceleration = distance:normalise()*0.0025
                local maxSpeed     = distance:normalise()*0.75

                for i=1,2 do
                    self.speed[i] = math.clamp(self.speed[i] + acceleration[i],-math.abs(maxSpeed[i]),math.abs(maxSpeed[i]))
                end
            end

            -- Interact with the player
            for _,playerObj in ipairs(Player.getIntersecting(self.position.x,self.position.y,self.position.x+self.size.x,self.position.y+self.size.y)) do
                if playerObj.forcedState == 0 and playerObj.deathTimer == 0 and not playerObj:mem(0x13C,FIELD_BOOL) then
                    self.bubbleSize = nil
                    self.bubbleSizeIncrease = nil

                    self:setPlayer(playerObj)

                    SFX.play(91)
                end
            end
        else
            self.speed = self.speed*0.98

            if self.speed.length < 0.1 then
                self.speed = vector.zero2
            end
        end
    end)


    keys.keyObjects.stateBehaviour = stateBehaviour


    local catchUpSpeeds = {[KEY_STATE.FOLLOW_CATCH_UP] = 8,[KEY_STATE.REWARD_CATCH_UP] = 12}
    local catchUpDistanceThreshold = 1024 -- If the player is any further than this, it will just teleport directly to them
    local catchUpTimeThreshold = 256 -- If the key is trying to catchup for longer than this, it will just teleport directly to the player

    function keys.keyObjects:onTick()
        local config = self:getConfig()

        -- Make sure the player is still valid
        if self.player ~= nil and (not self.player.isValid or self.player:mem(0x13C,FIELD_BOOL)) then
            self:setPlayer(nil)
        end


        self.timer = self.timer + 1

        if stateBehaviour[self.state] ~= nil then
            stateBehaviour[self.state](self)
        elseif catchUpSpeeds[self.state] ~= nil then
            local distanceFromPlayer = vector(self.player.x+(self.player.width/2),self.player.y+self.player.height)-vector(self.position.x+(self.size.x/2),self.position.y+self.size.y)
            local speed = catchUpSpeeds[self.state]

            local tooFar = (distanceFromPlayer.length > catchUpDistanceThreshold or self.timer > catchUpTimeThreshold)

            self.timer = self.timer + 1

            if distanceFromPlayer.length < speed or tooFar then
                self:startFollowing(tooFar)
                self:playSound("collect")
            else
                self.speed = distanceFromPlayer:normalise()*speed
            end
        end

        self.position = self.position + self.speed

        self.animationTimer = self.animationTimer + 1
        self:updateLight()


        -- Act as... y'know, a key
        if self.player ~= nil and self.player.forcedState == 0 and self.followingIndex == 1 then
            -- Handle locked doors
            if self.player:mem(0x5A,FIELD_WORD) > 0 then
                local currentWarp = Warp(self.player:mem(0x5A,FIELD_WORD)-1)

                if self.player.keys.up and currentWarp.locked then
                    unlockWarp(currentWarp)
                    self:remove()
                end
            end


            -- Handle keyhole exits
            for _,bgo in BGO.iterateIntersecting(self.player.x,self.player.y,self.player.x+self.player.width,self.player.y+self.player.height) do
                if bgo.id == 35 and not bgo.isHidden then
                    Level.winState(3)
                    SFX.play(31)

                    Audio.SeizeStream(-1)
                    Audio.MusicStop()
                end
            end


            -- Unlock key gates
            for _,npc in NPC.iterate(keys.keyGateIDList) do
                if not npc.isGenerator and not npc.isHidden and npc.despawnTimer > 0 then
                    -- Make sure no other key is already unlocking this
                    local distance = vector(npc.x+(npc.width/2),npc.y+(npc.height/2))-(self.position+(self.size/2))

                    local alreadyBeingUnlocked = false
                    for _,key in keys.keyObjects.iterate() do
                        if key.keyGateNPC == npc then
                            alreadyBeingUnlocked = true
                            break
                        end
                    end


                    if not alreadyBeingUnlocked and distance.length < 160 then
                        self.state = KEY_STATE.UNLOCK_GATE
                        self.timer = 0

                        self.keyGateNPC = npc

                        self:stopFollowing()
                        self:playSound("move")
                    end
                end
            end


            -- Wake up phantos
            local foundPhanto = false

            for _,npc in NPC.iterate(keys.phantoIDList) do
                local settings = npc.data._settings

                if settings.targetId == self.npcID then
                    foundPhanto = true
                    break
                end
            end


            if foundPhanto then
                -- Create an NPC, make it think that it's being held, and then kill it. This obviously isn't great, but I couldn't find much better...
                local npc = NPC.spawn(self.npcID,0,0,self.player.section)

                npc:mem(0x12C,FIELD_WORD,self.player.idx)
                npc:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN)
            end
        end
    end

    function keys.keyObjects:onDraw()
        if self._toBeRemoved then return end


        local config = self:getConfig()

        local priority = -36
        if self.followingIndex ~= nil then
            priority = priority-(self.followingIndex/keys.maxKeysPerPlayer)
        end


        -- Main drawing
        local gfxwidth  = ((config.gfxwidth  ~= 0 and config.gfxwidth ) or config.width )
        local gfxheight = ((config.gfxheight ~= 0 and config.gfxheight) or config.height)
        
        if self.sprite == nil then
            local texture = Graphics.sprites.npc[self.npcID].img

            self.sprite = Sprite{texture = texture,pivot = Sprite.align.CENTRE,frames = (texture.height/gfxheight)}
        end


        local frame = (math.floor(self.animationTimer/config.framespeed)%self.sprite.frames)

        self.sprite.position = vector(self.position.x+(self.size.x/2),self.position.y+self.size.y-(gfxheight/2))


        self.sprite:draw{frame = frame+1,priority = priority,sceneCoords = true}


        -- Bubble drawing
        if self.bubbleSize ~= nil then
            if self.bubbleSprite == nil then
                self.bubbleSprite = Sprite{texture = config.bubbleImage,pivot = Sprite.align.CENTRE}
            end

            self.bubbleSprite.position = (self.position+(self.size/2))
            self.bubbleSprite.scale = vector(math.abs(self.bubbleSize)*2,math.abs(1-self.bubbleSize)*2)
            
            self.bubbleSprite:draw{priority = priority,sceneCoords = true}
        end
    end



    local keyObjFields = table.map{
        "_idx",
        "npcID","position","size","speed",
        "state","timer","animationTimer","keyGateNPC","_toBeRemoved",
        "sprite","light","bubbleSize","bubbleSizeIncrease","bubbleSprite", -- aesthetic stuff
        "player","followingIndex","delayFromPlayer","isStill","isGrounded","bounceSpeed","bounceOffset", -- following stuff
    }
    local extraKeyObjFields = {
        --idx        = {get = (function(self) return (table.ifind(keys.keyObjects,self) or -1) end)},
        idx        = {get = (function(self) return self._idx end)},
        isValid    = {get = (function(self) return (self._idx > 0) end)},

        x          = {get = (function(self) return self.position.x end),set = (function(self,value) self.position.x = value end)},
        y          = {get = (function(self) return self.position.y end),set = (function(self,value) self.position.y = value end)},
        width      = {get = (function(self) return self.size.x end),set = (function(self,value) self.size.x = value end)},
        height     = {get = (function(self) return self.size.y end),set = (function(self,value) self.size.y = value end)},

        section    = {get = (function(self) return Section.getIdxFromCoords(self.x,self.y,self.width,self.height) end)},
        sectionObj = {get = (function(self) return Section.getFromCoords(self.x,self.y,self.width,self.height) end)},
    }

    local keyObjMetatable = {
        __index = (function(self,key)
            local field = extraKeyObjFields[key]

            if field ~= nil and field.get ~= nil then
                return field.get(self)
            else
                return keys.keyObjects[key]
            end
        end),
        __newindex = (function(self,key,value)
            local field = extraKeyObjFields[key]

            if keyObjFields[key] then
                rawset(self,key,value)
            elseif field ~= nil and field.set ~= nil then
                field.set(self,value)
            elseif field ~= nil then
                error("Field '".. tostring(key).. "' is read only.")
            else
                error("Field '".. tostring(key).. "' does not exist.")
            end
        end),
    }


    function keys.keyObjects.spawn(npcID,x,y,playerObj,isReward)
        local self = setmetatable({},keyObjMetatable)

        self._idx = #keys.keyObjects+1

        -- Define a bunch of fields
        self.npcID = (npcID or keys.keyIDList[1])


        local config = self:getConfig()

        self.size = vector(config.width,config.height)
        self.position = vector(x,y)-(self.size/2)

        self.speed = vector.zero2


        self.state = KEY_STATE.BUBBLE
        self.timer = 0
        
        self.animationTimer = 0
        self._toBeRemoved = false


        -- Release it into the wild
        table.insert(keys.keyObjects,self)
        

        self:updateLight()
        self:setPlayer(playerObj,isReward)


        return self
    end
end


-- Stuff for saving the keys/key coins into GameData
local killedNPCIndices = {}

do
    GameData.keys = GameData.keys or {}
    GameData.keys[Level.filename()] = GameData.keys[Level.filename()] or {}

    local savedData = GameData.keys[Level.filename()]


    function keys.resetSavedData()
        savedData.keys = {}
        savedData.coins = {}
        savedData.killedNPCIndices = {}
    end


    function keys.deleteAlreadyKilledNPCs()
        for _,index in ipairs(killedNPCIndices) do
            local idx = index
            if justReset then
                idx = idx+(storedNPCCount or 0)
            end

            local npc = NPC(idx)

            if npc ~= nil and npc.isValid then
                npcsToKill = npcsToKill or {}
                table.insert(npcsToKill,npc)

                npc.animationFrame = -1000
            end
        end
    end

    function keys.loadSavedData()
        if savedData.keys == nil then return end

        for _,keyData in ipairs(savedData.keys) do
            local playerObj = player
            if keyData.playerIndex <= Player.count() then
                playerObj = Player(keyData.playerIndex)
            end

            local key = keys.keyObjects.spawn(keyData.npcID,playerObj.x+(playerObj.width/2),playerObj.y+(playerObj.height/2),playerObj)
            key:startFollowing(true)
        end
        for _,coinData in ipairs(savedData.coins) do
            local type = keys.coinTypesMap[coinData.name]

            type.collected = coinData.collected
        end

        killedNPCIndices = table.iclone(savedData.killedNPCIndices)
        keys.deleteAlreadyKilledNPCs()
    end

    function keys.saveData()
        keys.resetSavedData() -- Make sure no old data persists

        for _,key in keys.keyObjects.iterate() do
            if key.player ~= nil and key.player.isValid then
                table.insert(savedData.keys,{npcID = key.npcID,playerIndex = key.player.idx})
            end
        end
        for _,type in ipairs(keys.coinTypesList) do
            if type.collected > 0 then
                table.insert(savedData.coins,{name = type.name,collected = type.collected})
            end
        end

        savedData.killedNPCIndices = table.iclone(killedNPCIndices)
    end


    function keys.onStart()
        if Misc.inEditor() and Checkpoint.getActive() == nil then
            keys.resetSavedData()
        else
            keys.loadSavedData()
        end
    end
    function keys.onCheckpoint(checkpointObj,playerObj)
        keys.saveData()
    end
    function keys.onExitLevel(exitType)
        if exitType > 0 then
            keys.resetSavedData()
        end
    end
end



-- Some global things

function keys.registerKey(id)
    npcManager.registerEvent(id,keys,"onStartNPC","onStartKey")
    npcManager.registerEvent(id,keys,"onTickEndNPC")

    table.insert(keys.keyIDList,id)
    keys.keyIDMap[id] = true
end
function keys.registerCoin(id)
    npcManager.registerEvent(id,keys,"onStartNPC","onStartCoin")
    npcManager.registerEvent(id,keys,"onTickEndNPC")

    -- Create a coin type
    local config = NPC.config[id]

    local type = {
        id = id,name = config.type,collected = 0,total = 0,timeSinceLastCollected = math.huge,
        hudImage = Graphics.loadImageResolved(keys.coinImageFilename:format(config.type)),
    }

    table.insert(keys.coinTypesList,type)
    keys.coinTypesMap[config.type] = type
    

    table.insert(keys.coinIDList,id)
    keys.coinIDMap[id] = true
end


-- Custom coin counter
do
    local layoutCache = {}
    local layoutCacheList = {}

    function keys.drawCoins(camIdx,priority,isSplit)
        local camera = Camera(camIdx)


        -- Remove any unused layouts to save memory
        for i=#layoutCacheList,1,-1 do
            local cached = layoutCacheList[i]

            if cached[2] then
                cached[2] = false
            else
                table.remove(layoutCacheList,i)
            end
        end


        local offsetY = 34
        if hudoverride.visible.timer and Timer.isActive() then
            offsetY = offsetY + hudoverride.offsets.timer.y
        end


        for _,type in ipairs(keys.coinTypesList) do
            local opacity = 1
            if type.collected >= type.total then
                opacity = 1-(math.max(0,type.timeSinceLastCollected-96)/12)
            end

            if type.total > 0 and opacity > -2 then
                local heightMultiplier = math.clamp(opacity+2,0,1)


                local iconWidth = (type.hudImage.width)
                local iconHeight = (type.hudImage.height/4)

                local totalWidth = (math.min(type.total,keys.maxCoinsPerLine)+2)*iconWidth
                local totalHeight = math.ceil(type.total/keys.maxCoinsPerLine)*iconHeight

                local middleX = (camera.width-32-(totalWidth/2))
                

                if keys.coinCounterVisible then
                    -- Draw text
                    local text = keys.coinCounterText:format(type.collected,type.total)

                    local layout = layoutCache[text]
                    if layout == nil then
                        layout = textplus.layout(text,nil,{font = keys.coinCounterFont})

                        local cached = {layout,true}

                        table.insert(layoutCacheList,cached)
                        layoutCache[text] = cached
                    else
                        layout[2] = true
                        layout = layout[1]
                    end


                    textplus.render{layout = layout,x = middleX-(layout.width/2),y = offsetY-(layout.height/2),color = Color.white*opacity}

                    -- Draw icon
                    Graphics.drawImageWP(type.hudImage,middleX-(layout.width/2)-iconWidth,offsetY-(iconHeight/2),0,iconHeight,iconWidth,iconHeight,opacity,priority)


                    offsetY = offsetY + (layout.height*heightMultiplier)
                end
                
                if keys.coinIconsVisible then
                    -- Draw the coins
                    for i=0,(type.total-1) do
                        local frame = 0
                        if type.collected > i then -- Collected
                            frame = 1
                        end


                        local scale = 1
                        if type.collected == (i+1) then
                            scale = math.min(1,type.timeSinceLastCollected/5)
                        end

                        local lineWidth = math.min(keys.maxCoinsPerLine,type.total-(math.floor(i/keys.maxCoinsPerLine)*keys.maxCoinsPerLine))*iconWidth

                        local x = (middleX-(lineWidth/2)+((i%keys.maxCoinsPerLine)*iconWidth)+(iconWidth/2))-((iconWidth*scale)/2)
                        local y = (offsetY+(math.floor(i/keys.maxCoinsPerLine)*iconHeight))-((iconHeight*scale)/2)


                        if scale == 1 then
                            Graphics.drawImageWP(type.hudImage,x,y,0,frame*iconHeight,iconWidth,iconHeight,opacity,priority)
                        elseif scale ~= 0 then
                            local y1 = ((frame  )/4)
                            local y2 = ((frame+1)/4)

                            Graphics.drawBox{
                                texture = type.hudImage,priority = priority,color = Color.white.. opacity,
                                x = x,y = y,width = (iconWidth*scale),height = (iconHeight*scale),
                                textureCoords = {0,y1,1,y1,1,y2,0,y2},
                            }
                        end
                    end

                    -- Draw the brackets
                    for i=0,1 do
                        local frame = (2+i)

                        local x = (middleX-(totalWidth/2)+(totalWidth*i)-(iconWidth/2))
                        local y = (offsetY+(totalHeight/2)-iconHeight)

                        Graphics.drawImageWP(type.hudImage,x,y,0,frame*iconHeight,iconWidth,iconHeight,opacity,priority)
                    end

                    offsetY = offsetY + (totalHeight*heightMultiplier)
                end
            end

            type.timeSinceLastCollected = type.timeSinceLastCollected + 1
        end
    end

    Graphics.addHUDElement(keys.drawCoins)
end


function keys.onInitAPI()
    registerEvent(keys,"onTick")
    registerEvent(keys,"onDraw")

    registerEvent(keys,"onTickEnd")


    registerEvent(keys,"onTick","updateTrails")

    registerEvent(keys,"onCheckpoint")
    registerEvent(keys,"onExitLevel")
    registerEvent(keys,"onStart")

    registerEvent(keys,"onBeforeReset") -- rooms.lua support
    registerEvent(keys,"onReset")


    registerEvent(keys,"onPostNPCKill","onPostNPCKillCollectable")

    registerEvent(keys,"onPostNPCHarm","onPostNPCHarmKeyOwner")
    registerEvent(keys,"onPostNPCKill","onPostNPCKillKeyOwner")
end


function keys.onTick()
    -- Remove any invalid keys
    for i=keys.keyObjects.count(),1,-1 do
        local self = keys.keyObjects(i)

        if self._toBeRemoved then
            -- Remove this key from the array and update the 'idx' field for other keys
            local count = keys.keyObjects.count()

            for idx=(i+1),count do
                local obj = keys.keyObjects[idx]

                keys.keyObjects[idx-1] = obj
                obj._idx = (idx-1)
            end
            keys.keyObjects[count] = nil

            self._idx = -1
        end
    end

    -- Run the logic for each key
    for idx,self in keys.keyObjects.iterate() do
        self:onTick()
    end


    justReset = false
end

function keys.onDraw()
    -- Draw each key
    for _,self in keys.keyObjects.iterate() do
        self:onDraw()
    end
end


-- NPC stuff
do
    function keys.onPostNPCKillCollectable(v,reason)
        if not keys.keyIDMap[v.id] and not keys.coinIDMap[v.id] then return end
    
        local collectedBy = npcManager.collected(v,reason)
        local config = NPC.config[v.id]
        local data = v.data
    
        if not collectedBy then return end
    
    
        if keys.keyIDMap[v.id] then
            keys.keyObjects.spawn(v.id,v.x+(v.width/2),v.y+(v.height/2),collectedBy)
        elseif keys.coinIDMap[v.id] and v.spawnId > 0 then
            keys.coinTypesMap[config.type].collected = keys.coinTypesMap[config.type].collected + 1
            keys.coinTypesMap[config.type].timeSinceLastCollected = 0
    
            if keys.coinTypesMap[config.type].collected < keys.coinTypesMap[config.type].total then
                if config.collectSFX then
                    SFX.play(config.collectSFX)
                end
            else
                if config.collectAllSFX then
                    SFX.play(config.collectAllSFX)
                end
    
    
                keys.keyObjects.spawn(config.keyID,v.x+(v.width/2),v.y+(v.height/2),collectedBy,true)
            end
    
            if config.collectionEffectID then
                local effect = Effect.spawn(config.collectionEffectID,0,0)
    
                effect.x = (v.x+(v.width /2))-(effect.width /2)
                effect.y = (v.y+(v.height/2))-(effect.height/2)
            end
        end
    
        -- Make sure this NPC cannot respawn
        table.insert(killedNPCIndices,data.originalIndex)
    end
    
    
    function keys.onPostNPCHarmKeyOwner(v,reason,culprit)
        local keyData = v.data._keys
    
        if culprit == nil or keyData == nil or keyData.keyID == nil then return end
    
    
        if type(culprit) == "Player" then
            keyData.latestHarmCulprit = culprit
        elseif type(culprit) == "NPC" then
            if culprit:mem(0x12C,FIELD_WORD) > 0 then -- Held by player
                keyData.latestHarmCulprit = Player(culprit:mem(0x12C,FIELD_WORD))
            elseif culprit:mem(0x132,FIELD_WORD) > 0 then -- Thrown by player
                keyData.latestHarmCulprit = Player(culprit:mem(0x132,FIELD_WORD))
            end
        end
    end
    
    function keys.onPostNPCKillKeyOwner(v,reason)
        local keyData = v.data._keys
    
        if keyData == nil or keyData.keyID == nil then return end
        if table.ifind(killedNPCIndices,keyData.originalIndex) or justReset then return end -- Prevent this NPC from spawning a key if it's been permantly killed
        
        local culprit = keyData.latestHarmCulprit
        if culprit == nil and Player.count() == 1 then
            culprit = player
        elseif culprit ~= nil and not culprit.isValid then
            culprit = nil
        end
    
    
        keys.keyObjects.spawn(keyData.keyID,v.x+(v.width/2),v.y+(v.height/2),culprit,true)
    
    
        -- Make sure this NPC cannot respawn
        table.insert(killedNPCIndices,keyData.originalIndex)
    end
    
    
    function keys.onBeforeReset(fromRespawn)
        justReset = true
        storedNPCCount = NPC.count()
    end
    
    function keys.onReset(fromRespawn)
        justReset = true
    
        
        for _,type in ipairs(keys.coinTypesList) do
            type.total = 0
    
            if fromRespawn then
                type.collected = 0
            end
        end
    
        for _,v in NPC.iterate(keys.keyIDList) do
            if not v.isGenerator and v:mem(0x122,FIELD_WORD) == 0 then
                keys.onStartKey(v)
            end
        end
        for _,v in NPC.iterate(keys.coinIDList) do
            if not v.isGenerator and v:mem(0x122,FIELD_WORD) == 0 then
                keys.onStartCoin(v)
            end
        end
        
        if fromRespawn then
            killedNPCIndices = {}
            keys.playerTrails = {}

            for _,key in keys.keyObjects.iterate() do
                key:remove()
            end
            
            keys.loadSavedData()
        else
            keys.deleteAlreadyKilledNPCs()
        end
    end


    local function getNPCIdx(v)
        if not justReset then
            return v.idx
        else
            return v.idx-(storedNPCCount or 0)
        end
    end
    function keys.onStartKey(v)
        local data = v.data

        data.originalIndex = getNPCIdx(v)

        -- If this NPC on top of another NPC, give that NPC a key
        for _,npc in NPC.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
            if npc ~= v and not npc.isGenerator and npc.layerName == v.layerName and npc:mem(0x122,FIELD_WORD) == 0 then
                npc.data._keys = npc.data._keys or {}
                local keyData = npc.data._keys

                keyData.keyID = v.id
                keyData.latestHarmCulprit = nil

                keyData.originalIndex = getNPCIdx(npc)


                npcsToKill = npcsToKill or {}
                table.insert(npcsToKill,v)

                v.animationFrame = -1000

                break
            end
        end
    end
    function keys.onStartCoin(v)
        local config = NPC.config[v.id]
        local data = v.data

        data.originalIndex = getNPCIdx(v)

        keys.coinTypesMap[config.type].total = keys.coinTypesMap[config.type].total + 1
    end

    function keys.onTickEndNPC(v)
        local data = v.data


        if Defines.levelFreeze then return end

        if v.despawnTimer <= 0 then
            data.timer = nil
            return
        end


        if not data.timer then
            data.timer = 0
        end

        data.timer = data.timer + 1

        if data.timer >= 64 and RNG.randomInt(1,160) == 1 or data.timer >= 512 then
            Effect.spawn(78,v.x+(v.width/2),v.y+(v.height/2))
            data.timer = 0
        end
    end


    function keys.onTickEnd()
        -- NPC's are not killed instantly for rooms.lua compatibility
        if npcsToKill ~= nil then
            for _,npc in ipairs(npcsToKill) do
                if npc.isValid then
                    npc.animationFrame = -1000
                    npc:kill(HARM_TYPE_OFFSCREEN)
                end
            end

            npcsToKill = nil
        end
    end
end


--- Settings ---

-- The maximum number of keys that a player can have at a time.
keys.maxKeysPerPlayer = 8
-- The minimum distance between any two keys following the player.
keys.followerKeyMinDistance = 24

--- Key Coin HUD Settings ---

-- The filename of the images used for key coins in the HUD. The %s is replaced with the name.
keys.coinImageFilename = "keys_coins_hud_%s.png"
-- The maximum amount of key coin icons per line.
keys.maxCoinsPerLine = 5

-- The font used for the key coin counter.
keys.coinCounterFont = textplus.loadFont("textplus/font/1.ini")
-- The text used for the key coin counter. The %d's are replaced with the current and total counts.
keys.coinCounterText = "%d/%d"

-- Whether or not a counter is displayed for the key coins.
keys.coinCounterVisible = true
-- Whether or not icons of the coins are displayed.
keys.coinIconsVisible = true


return keys