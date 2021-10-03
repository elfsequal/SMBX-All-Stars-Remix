local testStuff = {}


local extendedPlayerStuff = require("libs/test/extendedPlayerStuff")
local extraNPCProperties  = require("libs/extraNPCProperties")
local playerphysicspatch  = require("libs/playerphysicspatch")
local modernReserveItems  = require("libs/modernReserveItems")
local betterSMWCamera     = require("libs/test/betterSMWCamera")
local littleDialogue      = require("libs/test/littleDialogue")
local warpTransition      = require("libs/warpTransition")
local paletteChange       = require("libs/test/paletteChange")
local progressStuff       = require("libs/test/progressStuff")
local bettereffects       = require("game/bettereffects")
local smallScreen         = require("libs/test/smallScreen")
local comboSounds         = require("libs/test/comboSounds")
local hudoverride         = require("hudoverride")
local serializer          = require("ext/serializer")
local idleBirbs           = require("libs/test/idleBirbs")
local pauseplus           = require("libs/test/pauseplus")
local goalTape            = require("goalTape_ai")
local textplus            = require("textplus")
local antizip             = require("libs/antizip")
local smwMap              = require("smwMap")
local levels              = require("libs/test/levels")
local rooms               = require("rooms")

--playerphysicspatch.accelerationMultiplier = 1.25
--playerphysicspatch.idleDeceleration = 0.99
playerphysicspatch.speedXDecelerationModifier = 0.09

warpTransition.levelStartTransition = warpTransition.TRANSITION_MOSAIC
warpTransition.crossSectionTransition = warpTransition.TRANSITION_MOSAIC
warpTransition.sameSectionTransition = warpTransition.TRANSITION_MOSAIC

smallScreen.editSectionBounds = false


SaveData.coins = SaveData.coins or 0
SaveData.totalDeaths = SaveData.totalDeaths or 0
SaveData.assistModeActive = SaveData.assistModeActive or false

SaveData.fileTime = SaveData.fileTime or 0

SaveData.sawIntro = SaveData.sawIntro or false

SaveData.unlockedCheckpoints = SaveData.unlockedCheckpoints or {}
local unlockedCheckpoints = SaveData.unlockedCheckpoints


Player.setCostume(CHARACTER_MARIO,"SMW-Mario-Episode",true)
Player.setCostume(CHARACTER_LUIGI,"SMW-Luigi-Episode",true)
Player.setCostume(CHARACTER_TOAD, "SMW-Toad-Episode" ,true)


testStuff.maxCoins  = 9999
testStuff.maxDeaths = 99999999999999


testStuff.isOnMap = (Level.filename() == smwMap.levelFilename)
testStuff.isInIntro = (Level.filename() == levels.names.intro)

testStuff.messWithMapHUD = true



testStuff.isInPlusThing = (player.character == CHARACTER_LUIGI)
testStuff.levelPalette = (testStuff.isInPlusThing and 1) or 0


testStuff.exitFadeActive = false
testStuff.exitFadeOut = 0


testStuff.speedrunModeEnabled = false

local SCREEN_MODE_WIDE = "Wide"
local SCREEN_MODE_SNES = "Small"
local SCREEN_MODE_FULL = "Full"
local SCREEN_MODE_FULL_WIDE = "Full, Wide"

testStuff.screenMode = SCREEN_MODE_WIDE


--testStuff.explosionID = Explosion.register(76, 953, 43, true, false)
testStuff.explosionID = Explosion.register(64, 953, Misc.resolveSoundFile("thwomp_loud"), true, false)


local globalDataLib = require("globalSaveData")
local GlobalSaveData = globalDataLib.data


GlobalSaveData.fastestTimes = GlobalSaveData.fastestTimes or {}
local fastestTimes = GlobalSaveData.fastestTimes



local function isOnGroundRedigit()
    return (
        player.speedY == 0
        or player:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
        or player:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end


local function blockIsSolidFilter(v)
    if not Colliders.FILTER_COL_BLOCK_DEF(v) then
        return false
    end

    local blockConfig = Block.config[v.id]

    if blockConfig.passthrough and (blockConfig.playerfilter == -1 or blockConfig.playerfilter == player.character) then
        return false
    end

    if blockConfig.semisolid or blockConfig.sizeable then
        return false
    end

    return true
end

local function npcIsSolidFilter(v)
    if not Colliders.FILTER_COL_NPC_DEF(v) or v.despawnTimer <= 0 then
        return false
    end

    local npcConfig = NPC.config[v.id]

    if not npcConfig.playerblock then
        return false
    end

    return true
end


local function addZeroes(value,count)
    return string.format("%.".. count.. "d",value)
end

local function convertTime(rawSeconds,onlySecondsIfPossible,showMilliseconds)
    local milliseconds = math.floor(rawSeconds * 1000) % 1000
    local seconds = math.floor(rawSeconds) % 60
    local minutes = math.floor(rawSeconds / 60) % 60
    local hours = math.floor(rawSeconds / 3600)

    local ret = addZeroes(seconds,2)


    if minutes > 0 or not onlySecondsIfPossible then
        ret = addZeroes(minutes,2).. ".".. ret
    end

    if hours > 0 then
        ret = hours.. ".".. ret
    end

    if showMilliseconds then
        ret = ret.. ".".. addZeroes(milliseconds,3)
    end

    return ret
end


function testStuff.getShopItems()
    if SaveData.smwMap == nil then
        return {}
    end

    local beatenLevels = SaveData.smwMap.beatenLevels

    local shopItems = {}

    table.insert(shopItems,{cost = 20,name = "Mushroom",icon = "mushroom", powerupState = PLAYER_BIG,powerupID = 185})
    table.insert(shopItems,{cost = 35,name = "Fire Flower",icon = "flower", powerupState = PLAYER_FIREFLOWER,powerupID = 183})

    if beatenLevels[levels.names.sky] then
        table.insert(shopItems,{cost = 40,name = "Ice Flower",icon = "flower", powerupState = PLAYER_ICE,powerupID = 277})
    end

    if beatenLevels[levels.names.train] then
        table.insert(shopItems,{cost = 50,name = "Leaf",icon = "leaf", powerupState = PLAYER_LEAF,powerupID = 34})
    end

    if beatenLevels[levels.names.lotus] and not SaveData.hasBoughtOrb then
        table.insert(shopItems,{cost = 2000,name = "?-Orb",icon = "question", reserveID = 952})
    end


    if beatenLevels[levels.names.castle] then
        table.insert(shopItems,{cost = 10,name = "Hammer Suit",icon = "mushroom", powerupState = PLAYER_HAMMER,powerupID = 170})
    end


    return shopItems
end


function testStuff.startFadeOut()
    testStuff.exitFadeActive = true
    Misc.pause(true)
end


-- Coins + deaths
local displayCoins = SaveData.coins
local levelDeaths = 0

do
    local REAL_COINS_ADDR = 0x00B2C5A8
    local REAL_LIVES_ADDR = 0x00B2C5AC

    local neutralLivesValue = 50

    local coinsPerLives = {
        [1] = 10,
        [2] = 25,
        [3] = 50,
        [4] = 75,
        [5] = 100,
        [6] = 200,
        [7] = 300,
        [8] = 400,
        [9] = 500,
        [10] = 1000,
    }

    -- Mute lives sound
    --Audio.sounds[15].muted = true


    mem(REAL_LIVES_ADDR,FIELD_FLOAT,neutralLivesValue)


    testStuff.muteCoinGainingSound = false

    function testStuff.updateCoins()
        local forceSound = false


        -- Coin stuff
        SaveData.coins = math.min(testStuff.maxCoins,SaveData.coins + mem(REAL_COINS_ADDR,FIELD_WORD))
        mem(REAL_COINS_ADDR,FIELD_WORD,0)

        -- Lives stuff
        local lifeAddition = (mem(REAL_LIVES_ADDR,FIELD_FLOAT) - neutralLivesValue)

        if lifeAddition > 0 then
            SaveData.coins = math.min(testStuff.maxCoins,SaveData.coins + (coinsPerLives[lifeAddition] or coinsPerLives[#coinsPerLives]))
            forceSound = true
        end

        mem(REAL_LIVES_ADDR,FIELD_FLOAT,neutralLivesValue)



        -- Make the coin counter match up with the actual amount of coins
        local change = (SaveData.coins-displayCoins)/16
        if change < 0 then
            change = math.floor(change)
        elseif change > 0 then
            change = math.ceil(change)
        end

        displayCoins = displayCoins + change

        if SaveData.coins ~= displayCoins or forceSound then
            if not testStuff.muteCoinGainingSound then
                SFX.play(14)
            end
        else
            testStuff.muteCoinGainingSound = false
        end
    end

    function testStuff.updateDeaths(fromRespawn)
        if fromRespawn then
            SaveData.totalDeaths = math.min(testStuff.maxDeaths,SaveData.totalDeaths + 1)
            levelDeaths = math.min(testStuff.maxDeaths,levelDeaths + 1)
        end
    end
end


local oldStandingNPC

local powerupProjectiles = {
    [PLAYER_FIREFLOWER] = 13,
    [PLAYER_ICE]        = 265,
    [PLAYER_HAMMER]     = {171,291,292,266},
}

local maxProjectileCount = 2


function testStuff.onTick()
    -- Tweak: while climbing, update player's direction
    if player.climbing then
        if player.forcedState == FORCEDSTATE_NONE then
            if player.keys.left then
                player.direction = DIR_LEFT
            elseif player.keys.right then
                player.direction = DIR_RIGHT
            end
        end
    end

    -- Tweak: if the player just jumped off of an NPC, conserve that speed
    if not player:isOnGround() and player.standingNPC == nil and oldStandingNPC ~= nil and oldStandingNPC.isValid and oldStandingNPC:mem(0x122,FIELD_WORD) == 0 and not Defines.levelFreeze then
        player.speedX = player.speedX + oldStandingNPC.speedX
    end

    oldStandingNPC = player.standingNPC

    -- Tweak: don't shoot fireballs while spin jumping
    --[[if player:mem(0x50,FIELD_BOOL) and (player.powerup == PLAYER_FIREFLOWER or player.powerup == PLAYER_ICE) then
        player:mem(0x160,FIELD_WORD,2)
    end]]


    -- Tweak: only shoot 2 fireballs
    local projectileID = powerupProjectiles[player.powerup]

    if projectileID ~= nil then
        local projectileCount = 0

        for _,v in NPC.iterate(projectileID,player.section) do
            if v.spawnId <= 0 then
                if v.x+v.width > camera.x and v.x < camera.x+camera.width and v.y+v.height > camera.y and v.y < camera.y+camera.height then
                    projectileCount = projectileCount + 1
                else
                    v:kill(HARM_TYPE_VANISH)
                end
            end
        end

        if (projectileCount >= maxProjectileCount or player:mem(0x50,FIELD_BOOL)) and not Defines.cheat_flamethrower then
            player:mem(0x160,FIELD_WORD,2)
            player:mem(0x162,FIELD_WORD,2)
        else
            player:mem(0x160,FIELD_WORD,0)
            player:mem(0x162,FIELD_WORD,0)
        end
    end


    if Misc.inEditor() then
        Defines.cheat_speeddemon = Misc.GetKeyState(VK_0)
    end


    Defines.player_hasCheated = false


    testStuff.updateMusicName()
end


local bigPowerupFrames = {1,2,1,2,1,2,3,2,3,2,3,2,3}

local flowerPowerupPalettes = {
    [FORCEDSTATE_POWERUP_FIRE] = {1,2,3,4},
    [FORCEDSTATE_POWERUP_ICE]  = {1,2,9,10},
}

local powerdownPowerupPalettes = {
    [PLAYER_FIREFLOWER] = {3,4,1,2},
    [PLAYER_LEAF]       = {1,2},
    [PLAYER_TANOOKIE]   = {5,6,1,2},
    [PLAYER_HAMMER]     = {7,8,1,2},
    [PLAYER_ICE]        = {10,9,1,2},
}

local powerupStates = table.map{
    FORCEDSTATE_POWERUP_BIG,FORCEDSTATE_POWERDOWN_SMALL,FORCEDSTATE_POWERUP_FIRE,FORCEDSTATE_POWERUP_LEAF,FORCEDSTATE_POWERUP_TANOOKI,
    FORCEDSTATE_POWERUP_HAMMER,FORCEDSTATE_POWERUP_ICE,FORCEDSTATE_POWERDOWN_FIRE,FORCEDSTATE_POWERDOWN_ICE,FORCEDSTATE_MEGASHROOM,
}


local lastFramePowerup = PLAYER_SMALL
local poweringDownFromPowerup

local function setPowerup(powerup,logicalHitboxHandling)
    local newSettings = PlayerSettings.get(player.character,powerup)
    local oldSettings = PlayerSettings.get(player.character,player.powerup)

    -- Ducking handling
    if player:mem(0x12E,FIELD_BOOL) then
        player:mem(0x12E,FIELD_BOOL,false)
        player.y = player.y + player.height - oldSettings.hitboxHeight
        player.height = oldSettings.hitboxHeight
        player.frame = 1
    end

    local newWidth = newSettings.hitboxWidth
    local newHeight = newSettings.hitboxHeight
    local oldWidth,oldHeight

    if player.mount == MOUNT_YOSHI then
        -- Who doesn't love hardcoded values?
        if powerup == PLAYER_SMALL then
            newHeight = 54
        else
            newHeight = 60
        end
    end

    if logicalHitboxHandling or player.mount == MOUNT_YOSHI then
        oldWidth = player.width
        oldHeight = player.height
    else
        oldWidth = oldSettings.hitboxWidth
        oldHeight = oldSettings.hitboxHeight
    end

    player.x = player.x + oldWidth*0.5 - newWidth*0.5
    player.width = newWidth
    
    player.y = player.y + oldHeight - newHeight
    player.height = newHeight

    player:mem(0x12E,FIELD_BOOL,false)


    player.powerup = powerup
end

function testStuff.onTickEnd()
    --if true then return end

    -- Tweak: different powering up
    if flowerPowerupPalettes[player.forcedState] ~= nil then
        setPowerup(PLAYER_BIG,false)

        local palettes = flowerPowerupPalettes[player.forcedState]

        extendedPlayerStuff.playerPalette = palettes[(math.floor(player.forcedTimer / 4) % #palettes) + 1]
    elseif player.forcedState == FORCEDSTATE_POWERDOWN_SMALL then
        if lastFramePowerup > PLAYER_BIG then
            player.forcedState = FORCEDSTATE_POWERUP_BIG
            player.forcedTimer = 0

            poweringDownFromPowerup = lastFramePowerup
        end
    elseif player.forcedState == FORCEDSTATE_POWERUP_BIG and poweringDownFromPowerup ~= nil and powerdownPowerupPalettes[poweringDownFromPowerup] ~= nil then
        setPowerup(PLAYER_BIG,false)

        local palettes = powerdownPowerupPalettes[poweringDownFromPowerup]

        extendedPlayerStuff.playerPalette = palettes[(math.floor(player.forcedTimer / 4) % #palettes) + 1]

        -- Have correct invincibility time
        if player.forcedTimer == 1 then
            player:mem(0x140,FIELD_WORD,player:mem(0x140,FIELD_WORD) + 100)
        end
    end


    if player.forcedState ~= FORCEDSTATE_POWERUP_BIG then
        poweringDownFromPowerup = nil
    end
    

    if (player.forcedState == FORCEDSTATE_POWERUP_BIG and poweringDownFromPowerup == nil) or player.forcedState == FORCEDSTATE_POWERDOWN_SMALL then
        if player.forcedState == FORCEDSTATE_POWERDOWN_SMALL then
            setPowerup(PLAYER_BIG,false)
        else
            setPowerup(PLAYER_SMALL,false)
        end

        local frame = bigPowerupFrames[math.floor(player.forcedTimer / 4) + 1]

        extendedPlayerStuff.customFrameY = 1
        extendedPlayerStuff.customFrameX = frame or 3
    end



    Defines.levelFreeze = (powerupStates[player.forcedState] or mem(0x00B2C62E,FIELD_WORD) > 0)


    lastFramePowerup = player.powerup
end



local DEBRIS_DEFAULT = 954
local DEBRIS_BROWN   = 955
local DEBRIS_CEMENT  = 956


local effectReplacements = {
    [3] = 0,
    [5] = 0,
    [11] = 958,
    [13] = 951,
}

local blockDebrisEffects = {
    -- Hit bllocks
    [2]   = DEBRIS_BROWN,
    [89]  = DEBRIS_BROWN,

    -- Cement blocks
    [1]   = DEBRIS_CEMENT,
    [115] = DEBRIS_CEMENT,
    [132] = DEBRIS_CEMENT,
    [573] = DEBRIS_CEMENT,
    [574] = DEBRIS_CEMENT,
}
local defaultDebrisEffect = DEBRIS_DEFAULT

function testStuff.replaceEffects()
    for _,e in ipairs(Effect.get()) do
        local replace = effectReplacements[e.id]

        if e.id == 1 and e.timer > 0 then
            -- Destroy the other debris effects
            local width = 16
            local height = width
            local x = e.x + e.width  - e.speedX - width *0.5
            local y = e.y + e.height - e.speedY - height*0.5


            for _,other in ipairs(Effect.getIntersecting(x,y,x + width,y + height)) do
                if other.id == e.id and other ~= e then
                    e.x = 0
                    e.y = 0
                    e.timer = 0
                end
            end


            -- Search for destroyed blocks and assume its debris effect
            local closestBlock
            local closestBlockDistance = math.huge

            for _,b in Block.iterateIntersecting(e.x,e.y,e.x + e.width,e.y + e.height) do
                if b.layerName == "Destroyed Blocks" then
                    local xDistance = ((b.x + b.width *0.5) - (e.x + e.width *0.5))
                    local yDistance = ((b.y + b.height*0.5) - (e.x + e.height*0.5))
                    local totalDistance = math.sqrt(xDistance*xDistance + yDistance*yDistance)

                    if totalDistance < closestBlockDistance then
                        closestBlock = b
                        closestBlockDistance = totalDistance
                    end
                end
            end

            if closestBlock ~= nil then
                replace = blockDebrisEffects[closestBlock.id] or defaultDebrisEffect

                e.x = closestBlock.x + closestBlock.width *0.5 - e.width *0.5
                e.y = closestBlock.y + closestBlock.height*0.5 - e.height*0.5
            else
                replace = defaultDebrisEffect
            end
        end


        if replace ~= nil and e.timer > 0 then
            if replace > 0 then
                local r = Effect.spawn(replace,e.x + e.width*0.5,e.y + e.height*0.5)

                local config = Effect.config[replace][1]

                if config.xAlign ~= 0.5 and config.yAlign ~= 0.5 then
                    r.x = r.x - r.width*0.5
                    r.y = r.y - r.height*0.5
                end
            end

            e.x = 0
            e.y = 0
            e.timer = 0
        end
    end
end


function testStuff.onPostNPCHarm(v,reason,culprit)
    if reason == HARM_TYPE_NPC and type(culprit) == "NPC" and culprit.id == 13 and culprit ~= v then
        v.data.hitByFireTime = lunatime.tick()
    end
end

function testStuff.onPostNPCKill(v,reason)
    -- Drop a coin if killed by fire
    if reason == HARM_TYPE_NPC and v.data.hitByFireTime == lunatime.tick() then
        local coin = NPC.spawn(88,v.x+(v.width*0.5),v.y+v.height,v.section,false,true)

        coin.y = coin.y - coin.height

        coin.speedX = RNG.random(1,1.5)*math.sign((player.x + player.width*0.5) - (v.x + v.width*0.5))
        coin.speedY = RNG.random(-6,-4)
        coin.ai1 = 1


        if v.data.depthSwitching ~= nil then
            coin.data.depthSwitching = {depth = v.data.depthSwitching.depth}
        end
    end

    -- Spin jump thing
    if reason == HARM_TYPE_SPINJUMP and (player.x+player.width >= v.x and player.x <= v.x+v.width and player.y+player.height-math.max(0,player.speedY) <= v.y-v.speedY) and player.keys.down then
        player:mem(0x11C,FIELD_BOOL,0)
        player.speedY = 0.01
    end
end


-- HUD
do
    local starcoin = require("npcs/ai/starcoin")


    local totalHeight = 64

    local itemBoxImage = Graphics.loadImageResolved("hud_itembox.png")
    local itemBoxDefaultColor = Color.fromHexRGB(0x58A8F0)

    
    local items = {}

    items[0] = Graphics.loadImageResolved("hud_item_unknown.png")

    items[9] = Graphics.loadImageResolved("hud_item_mushroom.png")
    items[184] = items[9]
    items[185] = items[9]
    items[249] = items[9]

    items[14] = Graphics.loadImageResolved("hud_item_fireFlower.png")
    items[182] = items[14]
    items[183] = items[14]

    items[264] = Graphics.loadImageResolved("hud_item_iceFlower.png")
    items[277] = items[264]

    items[34] = Graphics.loadImageResolved("hud_item_leaf.png")
    items[169] = Graphics.loadImageResolved("hud_item_tanooki.png")
    items[170] = Graphics.loadImageResolved("hud_item_hammer.png")

    items[293] = Graphics.loadImageResolved("hud_item_star.png")

    items[951] = Graphics.loadImageResolved("hud_item_tape.png")
    items[952] = Graphics.loadImageResolved("hud_item_orb.png")

    items[95]  = Graphics.loadImageResolved("hud_item_egg.png") -- green yoshi
    items[98]  = items[95] -- blue yoshi
    items[99]  = items[95] -- yellow yoshi
    items[100] = items[95] -- red yoshi
    items[148] = items[95] -- black yoshi
    items[149] = items[95] -- purple yoshi
    items[150] = items[95] -- pink yoshi
    items[228] = items[95] -- ice yoshi
    items[96]  = items[95] -- egg


    local coinsImage = Graphics.loadImageResolved("hud_coins.png")
    local deathsImage = Graphics.loadImageResolved("hud_deaths.png")

    local crossImage = Graphics.loadImageResolved("hud_cross.png")


    local textFont = textplus.loadFont("numbersFont.ini")
    local textScale = 2

    local textFontZeroWidth = textFont.glyphs[string.byte("0")].width


    local bigFont = textplus.loadFont("bigFont.ini")


    local textLayouts = {}
    local function getTextLayout(name,text,font,scale,maxWidth)
        local existingData = textLayouts[name]

        if existingData == nil or existingData[2] ~= text or existingData[3] ~= text or existingData[4] ~= maxWidth then
            local totalScale = textScale * (scale or 1)

            textLayouts[name] = {textplus.layout(text,maxWidth,{font = font or textFont,xscale = totalScale,yscale = totalScale}),text,scale,maxWidth}
        end

        return textLayouts[name][1]
    end


    local displayButtons = {
        {"pause","+"},
        {"dropItem","-"},
        {"up","△"},
        {"down","▽"},
        {"left","◁"},
        {"right","▷"},
        {"jump","B"},
        {"run","Y"},
        {"altJump","A"},
        {"altRun","X"},
    }


    local function drawHUD(camIdx,priority,isSplit)
        local topY = camera.height*0.5 + smallScreen.height*0.5 + smallScreen.offsetY
        if testStuff.isUsingFullMode() then
            topY = camera.height*0.5 - smallScreen.height*0.5
        end

        local centreY = topY + totalHeight*0.5
        local centreX = camera.width*0.5
        local leftX = centreX - smallScreen.width*0.5

        local starCoinData = starcoin.getLevelList()
        local starCoinCount = #starCoinData

        local xOffset = 0
        local yOffset = 0

        local putEverythingOnLeft = testStuff.isUsingFullMode() or (testStuff.speedrunModeEnabled and testStuff.screenMode == SCREEN_MODE_SNES)

        if starCoinCount > 0 then
            yOffset = -6
        end

        local levelData = levels.data[Level.filename()]


        --Graphics.drawBox{color = Color.purple,priority = priority,x = centreX-(smallScreen.width*0.5),y = topY,width = smallScreen.width,height = totalHeight}

        -- Item box
        local itemBoxX = (putEverythingOnLeft and (leftX + itemBoxImage.width*0.5 + 24)) or centreX
        local itemBoxColor

        if levelData ~= nil and levelData.itemBoxColor ~= nil then
            itemBoxColor = levelData.itemBoxColor
        else
            itemBoxColor = itemBoxDefaultColor
        end

        --Graphics.drawImageWP(itemBoxImage,itemBoxX - itemBoxImage.width*0.5,centreY-(itemBoxImage.height*0.5)+yOffset,priority)
        Graphics.drawBox{texture = itemBoxImage,priority = priority,color = itemBoxColor,x = itemBoxX - itemBoxImage.width*0.5,y = centreY - itemBoxImage.height*0.5 + yOffset}

        local itemImage = items[player.reservePowerup] or items[0]

        if player.reservePowerup > 0 and itemImage ~= nil then
            Graphics.drawImageWP(itemImage,itemBoxX - itemImage.width*0.5,centreY-(itemImage.height*0.5)+yOffset,priority)
        end


        -- Coins
        local layout = getTextLayout("coinCount",tostring(displayCoins))
        --local textWidth = math.max(layout.width,textFontZeroWidth*textScale*2)
        local textWidth = layout.width

        local coinsX = (putEverythingOnLeft and (itemBoxX + itemBoxImage.width*0.5 + 24)) or (centreX - itemBoxImage.width*0.5 - textWidth - crossImage.width - coinsImage.width - 48)
        local coinsY = (putEverythingOnLeft and (topY + 8)) or (centreY - coinsImage.height*0.5 + yOffset)

        Graphics.drawImageWP(coinsImage,coinsX,coinsY,priority)
        Graphics.drawImageWP(crossImage,coinsX + crossImage.width,coinsY,priority)

        textplus.render{layout = layout,x = coinsX + coinsImage.width + crossImage.width + 16,y = coinsY - 2,priority = priority}


        -- Deaths
        local layout = getTextLayout("deathCount",tostring(levelDeaths))

        local deathsX = (putEverythingOnLeft and coinsX) or (centreX + (itemBoxImage.width*0.5) + 32)
        local deathsY = (putEverythingOnLeft and coinsY + coinsImage.height + 4) or (centreY - deathsImage.height*0.5 + yOffset)

        Graphics.drawImageWP(deathsImage,deathsX,deathsY,priority)
        Graphics.drawImageWP(crossImage,deathsX + crossImage.width,deathsY,priority)

        textplus.render{layout = layout,x = deathsX + deathsImage.width + crossImage.width + 16,y = deathsY - 2,priority = priority}


        -- Star coins / dragon coins
        local uncollectedImage = Graphics.sprites.hardcoded["51-0"].img
        local collectedImage = Graphics.sprites.hardcoded["51-1"].img

        local iconWidth = math.max(uncollectedImage.width,collectedImage.width)
        local iconHeight = math.max(uncollectedImage.height,collectedImage.height)

        local starCoinsTotalWidth = (iconWidth * starCoinCount)

        local starCoinsX = (putEverythingOnLeft and leftX + math.max(starCoinsTotalWidth,itemBoxImage.width)*0.5 + 24) or centreX

        for index,value in ipairs(starCoinData) do
            local icon
            if value == 0 then
                icon = uncollectedImage
            else
                icon = collectedImage
            end

            local x = starCoinsX - starCoinsTotalWidth*0.5 + iconWidth*(index-1)
            local y = topY + totalHeight - icon.height

            Graphics.drawImageWP(icon,x,y,priority)
        end
    end


    function testStuff.drawSpeedrunStuff(priority)
        if not testStuff.speedrunModeEnabled then
            return
        end


        local textX,textY
        local textScale = 1

        if testStuff.isOnMap then
            textX = 800 - smwMap.hudSettings.borderRightWidth - 24
            textY = 600 - smwMap.hudSettings.borderBottomHeight + 0
        elseif testStuff.isUsingFullMode() then
            textX = camera.width*0.5 + smallScreen.width*0.5 - 8
            textY = camera.height*0.5 - smallScreen.height*0.5 + 8
            textScale = 0.5
        else
            textX = camera.width*0.5 + smallScreen.width*0.5 - 24
            textY = camera.height*0.5 + smallScreen.height*0.5 + smallScreen.offsetY + 0
        end


        local flashInterval = (testStuff.levelBeatTimer / 24)
        local flashingActive = (flashInterval > 0 and flashInterval <= 8)
        local drawTimes = (not flashingActive or flashInterval%1 < 0.5)

        local displayLevelTime = (flashingActive and testStuff.beatLevelTime) or lunatime.drawtime()

        local displayTotalTime = SaveData.fileTime + displayLevelTime


        local totalLayout = getTextLayout("totalTime",convertTime(displayTotalTime,false,false),bigFont,textScale)

        if drawTimes then
            textplus.render{layout = totalLayout,priority = priority,x = textX - totalLayout.width,y = textY}
        end

        textY = textY + totalLayout.height


        local levelLayout = getTextLayout("levelTime",convertTime(displayLevelTime,false,true),nil,textScale)

        if drawTimes then
            textplus.render{layout = levelLayout,priority = priority,x = textX - levelLayout.width,y = textY}
        end

        textY = textY + levelLayout.height


        local inputText = ""

        for _,buttonData in ipairs(displayButtons) do
            if player.rawKeys[buttonData[1]] then
                inputText = inputText.. buttonData[2]
            else
                inputText = inputText.. "."
            end
        end

        local inputLayout = getTextLayout("inputDisplay",inputText,nil,textScale)

        textplus.render{layout = inputLayout,priority = priority,x = textX - inputLayout.width,y = textY}

        textY = textY + inputLayout.height


        -- Time compared to best time
        local previousTime = fastestTimes[Level.filename()]
        local newTime = testStuff.beatLevelTime
        
        if Level.winState() > 0 and previousTime ~= nil then
            local difference = (newTime - previousTime)


            local comparisonText
            local comparisonColor

            if difference > 0 then -- worse time
                comparisonText = "+".. convertTime(math.abs(difference),true,true)
                comparisonColor = Color.red
            elseif difference < 0 then -- better time!
                comparisonText = "-".. convertTime(math.abs(difference),true,true).. "  NEW PB!"
                comparisonColor = Color.green
            else -- same time
                comparisonText = "+0.000"
                comparisonColor = Color.white
            end

            local comparisonLayout = getTextLayout("timeComparison",comparisonText,nil,textScale)

            textplus.render{layout = comparisonLayout,color = comparisonColor,priority = priority,x = textX - comparisonLayout.width,y = textY}
        end
    end


    local function getMusicName()
        if pauseplus.getSelectionValue("settings","Mute Music") then
            return nil
        end

        local musicName

        if testStuff.isOnMap then
            if smwMap.currentlyPlayingMusic ~= 0 then
                musicName = smwMap.currentlyPlayingMusic
            end
        else
            musicName = rooms.currentMusicPath
        end

        if musicName ~= nil then
            -- Remove episode path
            local episodePath = Misc.episodePath()

            if musicName:sub(1,#episodePath) == episodePath then
                musicName = musicName:sub(#episodePath+1,#musicName)
            end

            -- Remove extra .spc data
            musicName = musicName:match("^(.*)|.*$") or musicName

            -- Finally, see if it matches a music name
            musicName = levels.musicNames[musicName] or "If you're seeing this, something's gone wrong. Please tell me. Thanks!"
        end

        return musicName
    end


    local musicNameFont = textplus.loadFont("textplus/font/6.ini")
    local musicIcon = Graphics.loadImageResolved("icon_music_outline.png")

    local musicNameAppearTime = 112
    local musicNameOffset = 16
    local musicNameOffsetFromIcon = 16
    local musicNameFadedDistance = 48

    local musicNameActive = false
    local musicName = nil
    local musicNameTimer = 0
    local musicNameY = 0

    local function getMusicNameLayout()
        local maxWidth
        if testStuff.isOnMap then
            maxWidth = 800 - smwMap.hudSettings.borderRightWidth - smwMap.hudSettings.borderLeftWidth
        else
            maxWidth = smallScreen.width
        end

        maxWidth = maxWidth - musicNameOffset*2 - musicIcon.width - musicNameOffsetFromIcon

        return getTextLayout("musicName",musicName,musicNameFont,nil,maxWidth)
    end


    function testStuff.drawMusicName(priority)
        if not musicNameActive then
            return
        end

        local layout = getMusicNameLayout()

        local textX,textY

        if testStuff.isOnMap then
            textX = smwMap.hudSettings.borderLeftWidth
            textY = 600 - smwMap.hudSettings.borderBottomHeight
        else
            textX = camera.width*0.5 - smallScreen.width*0.5 + smallScreen.offsetX
            textY = camera.height*0.5 + smallScreen.height*0.5 + smallScreen.offsetY
        end

        textX = textX + musicNameOffset
        textY = textY - musicNameOffset - layout.height + math.floor(musicNameY)

        local opacity = (1 - math.max(musicNameY / musicNameFadedDistance))

        Graphics.drawBox{texture = musicIcon,priority = priority,color = Color.white.. opacity,x = textX,y = textY + layout.height*0.5 - musicIcon.height*0.5}

        textplus.render{
            layout = layout,priority = priority,color = Color.white * opacity,
            x = textX + musicIcon.width + musicNameOffsetFromIcon,y = textY,
        }
    end

    function testStuff.updateMusicName()
        local newMusicName = getMusicName()

        if newMusicName ~= musicName and newMusicName ~= nil then
            musicName = newMusicName
            musicNameActive = true
            musicNameTimer = 0
            musicNameY = musicNameFadedDistance
        else
            musicName = newMusicName
            musicNameActive = (musicNameActive and musicName ~= nil)
        end

        if musicNameActive then
            musicNameTimer = musicNameTimer + 1

            if musicNameTimer > musicNameAppearTime then
                musicNameY = musicNameY + 0.08*(musicNameTimer - musicNameAppearTime)

                if musicNameY >= musicNameFadedDistance then
                    musicNameActive = false
                end
            else
                musicNameY = musicNameY * 0.91
            end
        end
    end


    Graphics.overrideHUD(drawHUD)


    smallScreen.offsetY = -totalHeight*0.5
end

-- pause menu
do
    local mainFont = textplus.loadFont("littleDialogue/font.ini")
    local bigFont = textplus.loadFont("bigFont.ini")

    pauseplus.font = mainFont

    pauseplus.musicVolumeDecrease = 0.5
    pauseplus.backgroundDarkness = 0.4

    pauseplus.horizontalSpace = 48
    pauseplus.verticalSpace   = 24

    pauseplus.doResizing = true


    local items = {
        {185,"Mushroom","mushroom"},
        {183,"Fire Flower","fireFlower"},
        {277,"Ice Flower","iceFlower"},
        {34,"Leaf","leaf"},
        {293,"Star","star"},
    }

    local levelBeatData = {
        [LEVEL_WIN_TYPE_SMB3ORB] = {"Goal Orb" , "hud_item_orb.png" , {id = 952,pausesGame = true}},
        [LEVEL_WIN_TYPE_TAPE]    = {"Goal Tape", "hud_item_tape.png", {id = 951,pausesGame = true}},
    }


    local function addStat(statsText,stats,iconName)
        if statsText ~= "" then
            statsText = statsText.. "\n\n"
        end

        statsText = statsText.. "<image icon_".. iconName.. ".png> "

        if type(stats) == "table" then
            for idx,name in ipairs(stats) do
                if idx ~= 1 then
                    statsText = statsText.. "\n  "
                end

                statsText = statsText.. name
            end
        else
            statsText = statsText.. stats
        end

        return statsText
    end


    local function getFastestTimesList()
        local times = {}

        for _,filename in ipairs(levels.beatableList) do
            if fastestTimes[filename] ~= nil then
                table.insert(times,levels.data[filename].name.. " - ".. convertTime(fastestTimes[filename],false,true))
            end
        end

        return times
    end


    testStuff.saveSound = SFX.open(Misc.resolveSoundFile("saved"))

    local function saveAndQuitRoutine()
        pauseplus.canControlMenu = false

        pauseplus.save()

        if testStuff.isOnMap then
            smwMap.forceMutedMusic = true
        else
            rooms.forcedMusicPause = true
        end

        SFX.play(testStuff.saveSound)


        Routine.wait(0.5,true)

        testStuff.startFadeOut()
    end

    
    local function popFromHistory()
        table.remove(pauseplus.history)
    end
    local function popFromHistoryTwice()
        popFromHistory()
        popFromHistory()
    end


    local function setAssistModeActive()
        SaveData.assistModeActive = true
    end

    local function beatLevelRoutine(beatData)
        while Misc.isPaused() do
            Routine.skip()
        end

        goalTape.startExit(beatData[3])
    end


    function testStuff.initPauseMenuOptions()
        -- Main
        pauseplus.createSubmenu("main",{headerText = "PAUSE",headerTextFont = bigFont})

        pauseplus.createOption("main",{text = "Continue",closeMenu = true})
        pauseplus.createOption("main",{text = "Settings",goToSubmenu = "settings"})

        if not testStuff.isOnMap then
            --pauseplus.createOption("main",{text = "Restart",closeMenu = true,action = (function(optionObj) player:kill() end)})
            pauseplus.createOption("main",{text = "Exit Level",action = (function()
                --rooms.forcedMusicPause = true
                testStuff.startFadeOut()
            end)})
        else
            pauseplus.createOption("main",{text = "Save and Quit",action = (function()
                Routine.run(saveAndQuitRoutine)
            end)})
        end

        -- Settings
        pauseplus.createSubmenu("settings",{headerText = "SETTINGS",headerTextFont = bigFont})

        --pauseplus.createOption("settings",{text = "Border Style",selectionType = pauseplus.SELECTION_NAMES,selectionNames = {"Dark Symbols","Symbols","Black"},action = testStuff.initOptionChoices,description = "Choose the the border surrounding the window."})
        pauseplus.createOption("settings",{text = "Screen Mode",selectionType = pauseplus.SELECTION_NAMES,selectionNames = {SCREEN_MODE_WIDE,SCREEN_MODE_SNES,SCREEN_MODE_FULL,SCREEN_MODE_FULL_WIDE},action = testStuff.initOptionChoices,description = "Select how the screen fills the window."})
        pauseplus.createOption("settings",{text = "Mute Music",selectionType = pauseplus.SELECTION_CHECKBOX,action = testStuff.initOptionChoices,description = "Mute all music from the game."})
        pauseplus.createOption("settings",{text = "Quick Death",selectionType = pauseplus.SELECTION_CHECKBOX,action = testStuff.initOptionChoices,description = "Speeds up the death effect."})
        pauseplus.createOption("settings",{text = "Screenshake",selectionType = pauseplus.SELECTION_NAMES,selectionNames = {"Full","Half","Disabled"},description = "How much screenshake there is."})
        pauseplus.createOption("settings",{text = "Physics Patch Disabled",selectionType = pauseplus.SELECTION_CHECKBOX,action = testStuff.initOptionChoices,description = "Return acceleration to the default."})
        --pauseplus.createOption("settings",{text = "Speedrun Mode",selectionType = pauseplus.SELECTION_CHECKBOX,action = testStuff.initOptionChoices,description = "Show a timer and input display."})
        pauseplus.createOption("settings",{text = "<color yellow>Speedrun Options</color>",goToSubmenu = "speedrun",description = "Includes options for speedrunning."})

        
        -- Assist mode stff
        pauseplus.createOption("settings",{text = "<color lightblue>Assist Options</color>",goToSubmenu = "assist",description = "Includes options for accesibility."})

        -- Assist options
        pauseplus.createSubmenu("assist",{headerText = "<color lightblue>ASSIST OPTIONS</color>",headerTextFont = bigFont})

        pauseplus.createOption("assist",{text = "Mid-air Jumps",action = setAssistModeActive,selectionType = pauseplus.SELECTION_NAMES,selectionNames = {"0","1","2","3","∞"},description = "How many times you're able to jump in the air."})
        pauseplus.createOption("assist",{text = "Invincibility",action = setAssistModeActive,selectionType = pauseplus.SELECTION_CHECKBOX,description = "Control if you can survive almost any hit."})

        -- Item select
        pauseplus.createOption("assist",{text = "Item Select",goToSubmenu = "itemSelect",description = "Pick a powerup to put into your reserve box."})
        
        pauseplus.createSubmenu("itemSelect",{headerText = "<color lightblue>ITEM SELECT</color>",headerTextFont = bigFont})

        for _,data in ipairs(items) do
            pauseplus.createOption("itemSelect",{text = "<image hud_item_".. data[3].. ".png> ".. data[2],sfx = 12,closeMenu = true,action = (function(optionObj)
                player.reservePowerup = data[1]
                setAssistModeActive()
            end)})
        end

        -- Level skip
        local levelData = levels.data[Level.filename()]

        if levelData ~= nil and levelData.exits ~= nil and #levelData.exits > 0 then
            pauseplus.createOption("assist",{text = "Beat Level",goToSubmenu = "beatLevel",description = "Beat this level instantly."})

            pauseplus.createSubmenu("beatLevel",{headerText = "<color lightblue>EXIT SELECT</color>",headerTextFont = bigFont})

            for _,beatCode in ipairs(levelData.exits) do
                local beatData = levelBeatData[beatCode]

                pauseplus.createOption("beatLevel",{text = "<image ".. beatData[2].. "> ".. beatData[1],closeMenu = true,action = (function(optionObj)
                    Routine.run(beatLevelRoutine,beatData)
                    setAssistModeActive()
                end)})
            end
        end


        -- Speedrun options
        local times = getFastestTimesList()

        pauseplus.createSubmenu("speedrun",{headerText = "<color yellow>SPEEDRUN OPTIONS</color>",headerTextFont = bigFont})

        pauseplus.createOption("speedrun",{text = "Speedrun HUD",selectionType = pauseplus.SELECTION_CHECKBOX,action = testStuff.initOptionChoices,description = "Enable a timer and input display."})

        if #times > 0 then
            pauseplus.createOption("speedrun",{text = "View Personal Bests...",goToSubmenu = "fastestTimes",description = "View your personal best for each level."})

            local headerText = ""

            for index,text in ipairs(times) do
                headerText = headerText.. text

                if index < #times then
                    headerText = headerText.. "\n"
                end
            end

            pauseplus.createSubmenu("fastestTimes",{headerText = headerText})
        end

        if not testStuff.isOnMap and fastestTimes[Level.filename()] ~= nil then
            pauseplus.createOption("speedrun",{text = "<color lightred>Erase this level's PB</color>",goToSubmenu = "eraseLevelTime",description = "Erase the personal best of the level you're playing."})
            
            pauseplus.createSubmenu("eraseLevelTime",{headerText = "Are you sure you want to delete your personal best for this level? <color lightred>This action cannot be undone.</color>"})
            pauseplus.createOption("eraseLevelTime",{text = "Yes, erase this level's PB",goToSubmenu = "speedrun",action = (function(optionObj)
                fastestTimes[Level.filename()] = nil
                testStuff.initPauseMenuOptions()
            end),lateAction = popFromHistoryTwice})
            pauseplus.createOption("eraseLevelTime",{text = "No, go back",goToSubmenu = "speedrun",goToOption = #pauseplus.submenus.speedrun.options,lateAction = popFromHistoryTwice})
        end

        if #times > 0 then
            pauseplus.createOption("speedrun",{text = "<color lightred>Erase all PB's</color>",goToSubmenu = "eraseAllTimes",description = "Erase the personal bests of every level."})
            
            pauseplus.createSubmenu("eraseAllTimes",{headerText = "Are you sure you want to delete all your personal bests? <color lightred>This action cannot be undone.</color>"})
            pauseplus.createOption("eraseAllTimes",{text = "Yes, erase all PB's",goToSubmenu = "speedrun",action = (function(optionObj)
                for _,filename in ipairs(levels.beatableList) do
                    fastestTimes[filename] = nil
                end
                testStuff.initPauseMenuOptions()
            end),lateAction = popFromHistoryTwice})
            pauseplus.createOption("eraseAllTimes",{text = "No, go back",goToSubmenu = "speedrun",goToOption = #pauseplus.submenus.speedrun.options,lateAction = popFromHistoryTwice})
        end


        -- Stats
        --[[local data = levels.data[Level.filename()]
        local stats

        if data ~= nil then
            stats = data.stats
        end

        if stats ~= nil then
            local statsText = ""

            if stats.music ~= nil then
                statsText = addStat(statsText,stats.music,"music")
            end

            if stats.tileset ~= nil then
                statsText = addStat(statsText,stats.tileset,"tileset")
            end

            if stats.other ~= nil then
                statsText = addStat(statsText,stats.other,"other")
            end


            local menuName = (testStuff.isOnMap and "Map Stats") or "Level Stats"


            pauseplus.createOption("main",{text = menuName,goToSubmenu = "stats"},#pauseplus.submenus.main.options)

            pauseplus.createSubmenu("stats",{headerText = statsText,headerTextFont = mainFont})
        end]]
    end


    testStuff.dontSetSectionBounds = {}

    function testStuff.initSectionBounds()
        -- Handle section bounds
        for _,sectionObj in ipairs(Section.get()) do
            if not testStuff.dontSetSectionBounds[sectionObj.idx] then
                local ob = sectionObj.origBoundary
                local b = sectionObj.boundary

                if ob.right-ob.left == 800 then
                    b.left = b.left + (b.right-b.left)*0.5 - smallScreen.width*0.5
                    b.right = b.left + smallScreen.width
                end
                if ob.bottom-ob.top == 600 then
                    b.top = b.bottom - smallScreen.height
                end

                sectionObj.boundary = b
            end
        end
    end


    local screenModes = {
        [SCREEN_MODE_WIDE]      = {width = 800,height = 450,full = false,name = "wide"},
        [SCREEN_MODE_SNES]      = {width = 512,height = 448,full = false,name = "small"},
        [SCREEN_MODE_FULL]      = {width = 600,height = 450,full = true ,name = "full"},
        [SCREEN_MODE_FULL_WIDE] = {width = 800,height = 450,full = true ,name = "fullWide"},
    }


    function testStuff.isUsingFullMode()
        return screenModes[testStuff.screenMode].full
    end


    function testStuff.initOptionChoices()
        testStuff.screenMode = pauseplus.getSelectionValue("settings","Screen Mode")
        testStuff.speedrunModeEnabled = pauseplus.getSelectionValue("speedrun","Speedrun HUD")

        if testStuff.isOnMap then
            if testStuff.messWithMapHUD then
                local screenModeProperties = screenModes[testStuff.screenMode]

                smwMap.hudSettings.borderLeftWidth = (800 - screenModeProperties.width)*0.5 + 34
                smwMap.hudSettings.borderRightWidth = smwMap.hudSettings.borderLeftWidth

                smwMap.hudSettings.starcoinsXOffset = 16
                smwMap.hudSettings.starcoinsAtBottom = false

                if testStuff.screenMode == SCREEN_MODE_WIDE then
                    smwMap.hudSettings.starcoinsXOffset = 16
                    smwMap.hudSettings.starcoinsAtBottom = false
                else
                    smwMap.hudSettings.starcoinsXOffset = 0
                    smwMap.hudSettings.starcoinsAtBottom = true
                end

                smwMap.hudSettings.borderTopHeight = 124
                smwMap.hudSettings.borderBottomHeight = 144

                if screenModeProperties.full then
                    smallScreen.width = screenModeProperties.width
                    smallScreen.height = screenModeProperties.height
                    smallScreen.offsetX = 0
                    smallScreen.offsetY = 0
                    smallScreen.croppingEnabled = true
                    smallScreen.priority = 5.01

                    smallScreen.scaleX = (800 / smallScreen.width)
                    smallScreen.scaleY = (600 / smallScreen.height)

                    smwMap.hudSettings.borderTopHeight = smwMap.hudSettings.borderTopHeight + 32
                    smwMap.hudSettings.borderBottomHeight = smwMap.hudSettings.borderBottomHeight - 32
                else
                    smallScreen.croppingEnabled = false
                end

                smwMap.camera.width  = 800 - smwMap.hudSettings.borderLeftWidth - smwMap.hudSettings.borderRightWidth
                smwMap.camera.height = 600 - smwMap.hudSettings.borderTopHeight - smwMap.hudSettings.borderBottomHeight
                smwMap.camera.renderX = smwMap.hudSettings.borderLeftWidth
                smwMap.camera.renderY = smwMap.hudSettings.borderTopHeight

                smwMap.hudSettings.borderImage = testStuff.getBorderImage()


                smwMap.hudSettings.playerOffsetX = 30
                smwMap.hudSettings.playerOffsetY = -6

                smwMap.hudSettings.counterOffsetX = 48
                smwMap.hudSettings.counterOffsetY = -4

                smwMap.hudSettings.levelTitleOffsetX = 32
                smwMap.hudSettings.levelTitleOffsetY = -2

                smwMap.hudSettings.starcoinsYOffset = -4

                smwMap.hudSettings.counterText = "x%s"


                smwMap.selectStartPointSettings.enabled = true


                smwMap.hudSettings.levelTitleColor = Color.white


                smwMap.levelTitleLayout = nil


                -- Set up counters
                smwMap.hudCounters = {
                    -- Deaths
                    {
                        icon = Graphics.loadImageResolved("hud_deaths.png"),
                        getValue = (function()
                            return SaveData.totalDeaths
                        end),
                    },
                    -- Coin counter
                    {
                        icon = Graphics.sprites.hardcoded["33-2"],
                        getValue = (function()
                            return displayCoins
                        end),
                    },
                    -- Stars
                    {
                        icon = Graphics.sprites.hardcoded["33-5"],
                        isEnabled = (function()
                            return mem(0x00B251E0,FIELD_WORD) > 0
                        end),
                        getValue = (function()
                            return mem(0x00B251E0,FIELD_WORD)
                        end),
                    }
                }
            end

            smwMap.walkCycles["SMW-MARIO-EPISODE"] = smwMap.walkCycles["SMW-MARIO"]
            smwMap.walkCycles["SMW-LUIGI-EPISODE"] = smwMap.walkCycles["SMW-LUIGI"]

            smwMap.forceMutedMusic = pauseplus.getSelectionValue("settings","Mute Music")

            betterSMWCamera.settings.enabled = false

            return
        end

        -- Wide mode
        local modeProperties = screenModes[testStuff.screenMode]

        local newScreenWidth = modeProperties.width
        local newScreenHeight = modeProperties.height
        local newScreenScaleX = 1
        local newScreenScaleY = 1
        local newScreenOffsetX = 0
        local newScreenOffsetY = -32
        local newScreenPriority = 1.5

        if modeProperties.full then
            newScreenScaleX = (800 / newScreenWidth)
            newScreenScaleY = (600 / newScreenHeight)
            newScreenOffsetX = 0
            newScreenOffsetY = 0

            if newScreenScaleX ~= newScreenScaleY then
                newScreenPriority = 10
            end
        end


        smallScreen.width = newScreenWidth
        smallScreen.height = newScreenHeight

        smallScreen.scaleX = newScreenScaleX
        smallScreen.scaleY = newScreenScaleY

        smallScreen.offsetX = newScreenOffsetX
        smallScreen.offsetY = newScreenOffsetY

        smallScreen.priority = newScreenPriority


        pauseplus.offset = vector(smallScreen.offsetX,smallScreen.offsetY)


        testStuff.initSectionBounds()


        -- Bound the camera pos to avoid seeing out of bounds
        if betterSMWCamera.settings.enabled and betterSMWCamera.cameraData.currentPos ~= nil then
            betterSMWCamera.cameraData.currentPos = betterSMWCamera.boundCameraPos(betterSMWCamera.cameraData.currentPos)
        end


        -- Mute muisc
        rooms.forcedMusicPause = pauseplus.getSelectionValue("settings","Mute Music")


        -- Quick death stuff
        if pauseplus.getSelectionValue("settings","Quick Death") then
            Audio.sounds[8].sfx = SFX.open(Misc.resolveSoundFile("death-short"))
        else
            Audio.sounds[8].sfx = SFX.open(Misc.resolveSoundFile("death-long"))
        end

        Audio.sounds[54].sfx = Audio.sounds[8].sfx

        -- PPP disable
        playerphysicspatch.enabled = (not pauseplus.getSelectionValue("settings","Physics Patch Disabled"))
    end


    testStuff.midAirJumpsUsed = 0
    testStuff.crushingBlocks = {}


    local crushIn = Misc.resolveSoundFile("assistCrush_in")
    local crushOut = Misc.resolveSoundFile("assistCrush_out")


    local function getPlayerCrushingCollider()
        local col = Colliders.getHitbox(player)

        col.x = col.x - 2
        col.y = col.y - 2
        col.width = col.width + 4
        col.height = col.height + 4

        return col
    end

    local function doBlockPoof(block)
        local effectID = 10
        local effectConfig = Effect.config[effectID][1]

        local effectsX = math.ceil(block.width / effectConfig.width)
        local effectsY = math.ceil(block.height / effectConfig.height)

        for x = 1,effectsX do
            for y = 1,effectsY do
                local e = Effect.spawn(effectID,0,0)

                e.x = block.x + block.width *0.5 - effectsX*effectConfig.width *0.5 + (x-1)*effectConfig.width 
                e.y = block.y + block.height*0.5 - effectsY*effectConfig.height*0.5 + (y-1)*effectConfig.height
                e.speedX = block.speedX * 0.5
                e.speedY = block.speedY
            end
        end
    end


    function testStuff.handleAssist()
        -- Restore crushing blocks
        for i = #testStuff.crushingBlocks, 1, -1 do
            local block = testStuff.crushingBlocks[i]
            local remove = false

            if block.isValid and block.isHidden then
                if not Colliders.collide(block,getPlayerCrushingCollider()) then
                    block.isHidden = block.layerObj.isHidden
                    remove = true

                    SFX.play(crushOut)

                    doBlockPoof(block)
                end
            else
                remove = true
            end

            if remove then
                table.remove(testStuff.crushingBlocks,i)
            end
        end


        if not SaveData.assistModeActive then
            return
        end


        -- Invincibility
        local donthurtmeActive = Cheats.get("donthurtme").active
        local invincibility = pauseplus.getSelectionValue("assist","Invincibility")

        Defines.cheat_donthurtme = donthurtmeActive or invincibility


        -- Mid-air jumps
        local allowedJumps = pauseplus.getSelectionValue("assist","Mid-air jumps")
        if allowedJumps == "∞" then
            allowedJumps = math.huge
        else
            allowedJumps = tonumber(allowedJumps) or 0
        end

        if isOnGroundRedigit() or player:mem(0x26,FIELD_WORD) > 0 or player:mem(0x34,FIELD_WORD) > 0 then
            testStuff.midAirJumpsUsed = 0
        elseif (player.forcedState == FORCEDSTATE_NONE and player.deathTimer == 0 and not player.climbing) and testStuff.midAirJumpsUsed < allowedJumps and player.keys.jump == KEYS_PRESSED then
            testStuff.midAirJumpsUsed = testStuff.midAirJumpsUsed + 1

            player:mem(0x11C,FIELD_WORD,Defines.jumpheight)
            SFX.play(1)
        end
    end


    local crushShader = Shader()
    crushShader:compileFromFile(nil,"assistCrush_transparent.frag")

    local crushColor1 = Color.white
    local crushColor2 = Color(0,0,0,0.625)

    function testStuff.handleAssistOnDraw()
        for _,block in ipairs(testStuff.crushingBlocks) do
            if block.isValid then
                local image = Graphics.sprites.block[block.id].img

                if image ~= nil then
                    Graphics.drawBox{
                        texture = image,sceneCoords = true,priority = -66,
                        x = math.floor(block.x + 0.5),y = math.floor(block.y + 0.5),
                        sourceWidth = block.width,sourceHeight = block.height,
                        shader = crushShader,uniforms = {
                            crushColor1 = crushColor1,
                            crushColor2 = crushColor2,
                        },
                    }
                end
            end
        end
    end


    local function crusherFilter(v)
        return (
            Colliders.FILTER_COL_BLOCK_DEF(v)
            and (v.speedX ~= 0 or v.speedY ~= 0)
        )
    end

    function testStuff.onPlayerKill(eventObj,p)
        if pauseplus.getSelectionValue("assist","Invincibility") then
            if player.y >= player.sectionObj.boundary.bottom + 64 then
                player.speedY = -20
                eventObj.cancelled = true
                SFX.play(24)
                return
            end

            -- Check for crushing
            local blocks = Colliders.getColliding{a = getPlayerCrushingCollider(),b = Block.SOLID.. Block.PLAYERSOLID,btype = Colliders.BLOCK,filter = crusherFilter}

            if #blocks > 0 then
                for _,block in ipairs(blocks) do
                    block.isHidden = true
                    table.insert(testStuff.crushingBlocks,block)

                    doBlockPoof(block)
                end

                SFX.play(crushIn)

                eventObj.cancelled = true
            end
        end
    end


    -- Borders
    local borderImages = {}

    function testStuff.getBorderImage()
        if borderImages[isWide] == nil then
            local imageName = "border_".. screenModes[testStuff.screenMode].name

            if testStuff.isOnMap then
                imageName = imageName.. "_map"
            end

            imageName = imageName.. ".png"

            borderImages[testStuff.screenMode] = Graphics.loadImage(Misc.resolveGraphicsFile(imageName) or Misc.resolveGraphicsFile("stock-0.png"))
        end

        return borderImages[testStuff.screenMode]
    end

    function testStuff.drawBorder()
        if testStuff.isOnMap or testStuff.isUsingFullMode() then
            return
        end

        local image = testStuff.getBorderImage()

        Graphics.drawImageWP(image,0,0,hudoverride.priority - 0.001)
    end


    testStuff.initPauseMenuOptions()
end



-- Death effect
do
    local deathEffects = {}
    local deathCoins = {}

    
    local deathEffectImage = Graphics.loadImageResolved("deathEffect.png")

    local deathEffectCharacters = 2
    local deathEffectPowerups = 7
    local deathEffectFrames = 2


    local coinImage = Graphics.loadImageResolved("npc-88.png")

    local coinFrames = 4


    local deathCoinsCost = 15


    function testStuff.handleDeathEffects()
        if #deathEffects > 0 and not pauseplus.getSelectionValue("settings","Quick Death") then
            Graphics.drawScreen{priority = -4,color = Color.black.. 0.5}
        end


        for _,coin in ipairs(deathCoins) do
            local width = coinImage.width
            local height = coinImage.height / coinFrames

            local sourceY = (math.floor(coin.timer / 8) % coinFrames) * height


            coin.timer = coin.timer + 1

            if coin.timer >= 24 or pauseplus.getSelectionValue("settings","Quick Death") then
                coin.speedY = coin.speedY + coin.gravity

                coin.x = coin.x + coin.speedX
                coin.y = coin.y + coin.speedY
            end


            Graphics.drawImageToSceneWP(coinImage, coin.x - width*0.5, coin.y - height*0.5, 0,sourceY, width,height,-4)
        end

        for _,obj in ipairs(deathEffects) do
            obj.timer = obj.timer + 1

            if not obj.isQuick then
                if obj.timer == 224 then
                    Misc.unpause()

                    rooms.forcedMusicPause = pauseplus.getSelectionValue("settings","Mute Music")
                elseif obj.timer == 24 then
                    obj.speedX = obj.direction * 1.15
                    obj.speedY = -10
                elseif obj.timer >= 24 then
                    obj.speedY = obj.speedY + 0.25

                    obj.animationFrame = math.floor(obj.timer / 8) % deathEffectFrames

                    obj.rotation = obj.rotation + obj.direction*8
                end

                obj.x = obj.x + obj.speedX
                obj.y = obj.y + obj.speedY
            end


            extendedPlayerStuff.render{
                ignorestate = true,priority = -4,character = obj.character,powerup = obj.powerup,
                x = obj.x - player.width*0.5,y = obj.y - player.height*0.5,
                rotation = obj.rotation,frameX = obj.animationFrame+1,frameY = 2,
            }
        end
    end

    function testStuff.createDeathEffect(p)
        local obj = {}

        obj.character = p.character
        obj.powerup = p.powerup

        obj.x = p.x + p.width*0.5
        obj.y = p.y + p.height - 4

        obj.rotation = 0

        obj.direction = -p.direction

        obj.speedX = 0
        obj.speedY = 0

        obj.timer = 0

        obj.animationFrame = 0

        obj.isQuick = pauseplus.getSelectionValue("settings","Quick Death")


        table.insert(deathEffects,obj)


        if not obj.isQuick then
            rooms.forcedMusicPause = true

            Defines.earthquake = 8

            Misc.pause(true)


            for i = 1, math.min(SaveData.coins,deathCoinsCost) do
                local coin = {}
    
                coin.x = p.x + p.width*0.5
                coin.y = p.y + p.height*0.5
    
                coin.speedX = RNG.random(0.5,2) * RNG.irandomEntry{-1,1}
                coin.speedY = RNG.random(-10,-5)
    
                coin.gravity = RNG.random(0.12,0.2)
    
                coin.timer = 0
    
                table.insert(deathCoins,coin)
            end
        end


        SaveData.coins = math.max(0,SaveData.coins - deathCoinsCost)
        testStuff.muteCoinGainingSound = true
    end

    function testStuff.onResetDeathEffects(fromRespawn)
        if fromRespawn then
            deathEffects = {}
            deathCoins = {}
        end
    end
end


do
    local paletteBuffer = Graphics.CaptureBuffer(800,600)

    local offscreenPadding = 32

    function testStuff.applyLevelPalette()
        if testStuff.levelPalette > 0 then
            local shaderObj,uniforms = paletteChange.getShaderAndUniforms(testStuff.levelPalette,"palette.png")


            local applyX = math.max(0,camera.width *0.5 - smallScreen.width *0.5 - offscreenPadding)
            local applyY = math.max(0,camera.height*0.5 - smallScreen.height*0.5 - offscreenPadding)

            local applyWidth  = math.min(camera.width ,smallScreen.width  + offscreenPadding*2)
            local applyHeight = math.min(camera.height,smallScreen.height + offscreenPadding*2)

            local applyPriority = -0.01

            if Level.winState() > 0 then
                applyPriority = -7.01
            elseif player.deathTimer > 0 then
                applyPriority = -5.01
            end

            paletteBuffer:captureAt(applyPriority)

            Graphics.drawBox{
                texture = paletteBuffer,priority = applyPriority,
                x = applyX,y = applyY,width = applyWidth,height = applyHeight,
                sourceX = applyX,sourceY = applyY,sourceWidth = applyWidth,sourceHeight = applyHeight,
                shader = shaderObj,uniforms = uniforms,
            }
        end
    end
end


-- Save game icon
--[[do
    SaveData.saveCount = SaveData.saveCount or 0


    GameData.saveIconQueued = GameData.saveIconQueued or false
    GameData.queuedSaveIconSuccessful = GameData.queuedSaveIconSuccessful or false


    local LEAVING_LEVEL_ADDR = 0x00B2C5B4


    local saveIcon = {}


    local iconImage = Graphics.loadImageResolved("saveIcon.png")
    local iconCharacters = 4
    local iconFrames = 3
    
    local fadeInTime = 12
    local fadeOutTime = 32
    
    local savedSFX = Misc.resolveSoundFile("saved")
    local failedSFX = Misc.resolveSoundFile("wrong")

    local textFont = textplus.loadFont("numbersFont.ini")
    local textScale = 2


    local function saveWasSuccessful()
        local filename = "save".. Misc.saveSlot().. "-ext.dat"
        local f = io.open(Misc.episodePath().. filename,"r")

        if f == nil then
            return false
        end

        local content = f:read("*all")

        f:close()


        -- Parse the save file...
        local s,e = pcall(serializer.deserialize, content, filename)


        if not s then
            return false
        end


        if e.saveCount ~= SaveData.saveCount then -- the data is not the same... so therefore, the same musn't have worked
            return false
        end


        return true
    end


    local function startSaveIcon(successful)
        if Misc.inEditor() or Misc.inMarioChallenge() or testStuff.isOnMap then
            return
        end

        saveIcon.active = true

        saveIcon.character = player.character
        saveIcon.timer = 0
        saveIcon.opacity = 0
        saveIcon.frame = 0

        saveIcon.offsetY = 0
        saveIcon.speedY = 0

        local text

        if successful then
            saveIcon.successful = true
            saveIcon.lifetime = 80

            text = "SAVED"
        else
            saveIcon.successful = false
            saveIcon.lifetime = 96

            text = "SAVE FAILED"
        end

        saveIcon.textLayout = textplus.layout(text,nil,{font = textFont,xscale = textScale,yscale = textScale})
    end

    function testStuff.queueSaveIcon(successful)
        if successful == nil then
            successful = saveWasSuccessful()
        end

        GameData.saveIconQueued = true
        GameData.queuedSaveIconSuccessful = true
    end


    function testStuff.onSaveGameEarly()
        SaveData.saveCount = SaveData.saveCount + 1
    end

    function testStuff.onSaveGameLate()
        testStuff.queueSaveIcon(saveWasSuccessful())
    end


    function testStuff.onDrawSaveIcon()
        if GameData.saveIconQueued then
            startSaveIcon(GameData.queuedSaveIconSuccessful)
            GameData.saveIconQueued = false
        end


        if not saveIcon.active then
            return
        end


        if saveIcon.successful then
            saveIcon.frame = math.floor(saveIcon.timer / 8) % (iconFrames - 1)

            if saveIcon.timer == 28 then
                SFX.play(savedSFX,0.45)
            end
        else
            saveIcon.frame = iconFrames - 1

            if saveIcon.timer == 24 then
                saveIcon.speedY = -4
            elseif saveIcon.timer >= 24 then
                saveIcon.speedY = saveIcon.speedY + 0.2
            end

            saveIcon.offsetY = saveIcon.offsetY + saveIcon.speedY

            if saveIcon.timer == 16 then
                SFX.play(failedSFX,0.35)
            end
        end


        if saveIcon.timer <= saveIcon.lifetime then
            saveIcon.opacity = math.min(1, saveIcon.opacity + (1 / fadeInTime))
        else
            saveIcon.opacity = math.max(0, saveIcon.opacity - (1 / fadeOutTime))

            if saveIcon.opacity <= 0 then
                saveIcon.active = false
                return
            end
        end


        saveIcon.timer = saveIcon.timer + 1


        local width  = iconImage.width  / iconCharacters
        local height = iconImage.height / iconFrames

        local textX = camera.width *0.5 + smallScreen.width *0.5 + smallScreen.offsetX - 16
        local textY = camera.height*0.5 + smallScreen.height*0.5 + smallScreen.offsetY - 16 - saveIcon.textLayout.height

        local x = textX - saveIcon.textLayout.width*0.5 - width*0.5
        local y = textY - height + saveIcon.offsetY

        local priority = (hudoverride.priority - 0.001)

        Graphics.drawImageWP(iconImage,x,y,width * (saveIcon.character-1),height * saveIcon.frame,width,height,saveIcon.opacity,priority)

        textplus.render{layout = saveIcon.textLayout,priority = priority,color = Color.white*saveIcon.opacity,x = textX - saveIcon.textLayout.width,y = textY}
    end

    function testStuff.onStartSaveIcon()
        if GameData.saveIconQueued then
            startSaveIcon(GameData.queuedSaveIconSuccessful)
            GameData.saveIconQueued = true
        end
    end
end]]


local function introRoutine()
    player.direction = DIR_RIGHT

    local music = SFX.open(Misc.resolveSoundFile("music/Super Mario World - World Clear"))


    pauseplus.canPause = false

    Routine.wait(0.25)


    -- Skip the intro and enable speedrun mode if holding dropItem + altJump
    if player.rawKeys.dropItem and player.rawKeys.altJump then
        SFX.play(14)

        SaveData.pauseplus.selectionData.speedrun["speedrun hud"] = true
        testStuff.speedrunModeEnabled = true

        Routine.wait(0.2)

        testStuff.startFadeOut()

        return
    end


    SFX.play(music)

    Routine.wait(0.25)


    -- Create the box
    local b = player.sectionObj.boundary
    local boxPos = vector((b.right + b.left) * 0.5,b.bottom - 160)

    littleDialogue.create{text = "Welcome! In this strange land, we find that Yoshi's egg is missing. Looks like somebody's back at it again!",speakerObj = boxPos,uncontrollable = true}


    -- Wait, and then wait for jump input
    Routine.wait(14,true)

    while (player.rawKeys.jump ~= KEYS_PRESSED) do
        Routine.skip(true)
    end

    -- Exit
    testStuff.startFadeOut()
end



testStuff.beatLevelTime = 0
testStuff.levelBeatTimer = 0


function testStuff.onDraw()
    if testStuff.exitFadeActive then
        testStuff.exitFadeOut = math.min(1, testStuff.exitFadeOut + 0.02)

        if testStuff.exitFadeOut >= 1 then
            if testStuff.isOnMap then
                pauseplus.quit()
            else
                Misc.unpause()
                Level.exit()
            end
        end

        Graphics.drawScreen{color = Color.black.. testStuff.exitFadeOut,priority = 9}
    end


    if Level.winState() == 0 then
        testStuff.beatLevelTime = lunatime.drawtime()
        testStuff.levelBeatTimer = 0
    else
        testStuff.levelBeatTimer = testStuff.levelBeatTimer + 1
    end


    if testStuff.isOnMap then
        hudoverride.priority = smwMap.hudSettings.priority
    elseif testStuff.isUsingFullMode() then
        hudoverride.priority = smallScreen.priority - 0.002
    elseif warpTransition.transitionIsFromLevelStart or Level.winState() > 0 then
        hudoverride.priority = 4.999999
    else
        hudoverride.priority = 7
    end

    if testStuff.isUsingFullMode() then
        pauseplus.priority = hudoverride.priority + 0.001
    else
        pauseplus.priority = 7.1
    end

    testStuff.drawSpeedrunStuff(hudoverride.priority + 0.001)
    testStuff.drawMusicName(hudoverride.priority - 0.001)
end


function testStuff.onReset(fromRespawn)
    testStuff.initSectionBounds()
end


function testStuff.onExitLevel(winType)
    if Misc.inEditor() and winType == 0 then
        Defines.player_hasCheated = false
        Misc.saveGame()
    end

    -- Handle speedrun stuff
    SaveData.fileTime = SaveData.fileTime + lunatime.drawtime()

    if winType ~= LEVEL_WIN_TYPE_NONE then
        local previousTime = fastestTimes[Level.filename()]
        local newTime = testStuff.beatLevelTime

        if previousTime == nil or newTime < previousTime then
            fastestTimes[Level.filename()] = newTime
        end
    end
end


local screenshakeOptions = {["Full"] = 1,["Half"] = 0.5,["Disabled"] = 0}

testStuff.horizontalShake = 0
testStuff.verticalShake = 0

function testStuff.onCameraUpdate()
    -- Screen shake
    testStuff.horizontalShake = math.max(testStuff.horizontalShake - 1,0)
    testStuff.verticalShake = math.max(testStuff.verticalShake - 1,(Defines.earthquake - 1)*1.5,0)

    local multiplier = ((lunatime.drawtick() % 2)*2 - 1) * screenshakeOptions[pauseplus.getSelectionValue("settings","Screenshake")]

    camera.x = camera.x + testStuff.horizontalShake*multiplier
    camera.y = camera.y + testStuff.verticalShake*multiplier

    Defines.earthquake = 0
end


function testStuff.onStart()
    if testStuff.isOnMap and not SaveData.sawIntro and not Misc.inEditor() and not Misc.inMarioChallenge() then
        Level.load(levels.names.intro)

        smwMap.transitionSettings.enterMapSettings.pauses = false
        smwMap.forceMutedMusic = true

        Graphics.drawScreen{color = Color.black,priority = 10}
    elseif testStuff.isInIntro then
        Routine.run(introRoutine)
        SaveData.sawIntro = true
    end
end


function testStuff.onCheckpoint(c,_)
    unlockedCheckpoints[Level.filename()] = unlockedCheckpoints[Level.filename()] or {}
    unlockedCheckpoints[Level.filename()][c.idx] = true

    Misc.saveGame()
end


function testStuff.onPostExplosion(explosion,p)
    if explosion.id == testStuff.explosionID then
        local blocks = Colliders.getColliding{a = explosion.collider,b = Block.MEGA_STURDY,btype = Colliders.BLOCK}

        for _,block in ipairs(blocks) do
            block:remove(true)
        end
    end
end



function testStuff.onInitAPI()
    registerEvent(testStuff,"onStart","initOptionChoices",false)
    registerEvent(testStuff,"onDraw","drawBorder",false)

    registerEvent(testStuff,"onTick","handleAssist")
    registerEvent(testStuff,"onDraw","handleAssistOnDraw")

    registerEvent(testStuff,"onDraw","updateCoins")
    registerEvent(testStuff,"onReset","updateDeaths")

    registerEvent(testStuff,"onPostNPCHarm")
    registerEvent(testStuff,"onPostNPCKill")

    registerEvent(testStuff,"onTick","replaceEffects")
    registerEvent(testStuff,"onTickEnd","replaceEffects")
    registerEvent(testStuff,"onDraw","replaceEffects")

    registerEvent(testStuff,"onDraw","applyLevelPalette",false)

    registerEvent(testStuff,"onDraw","handleDeathEffects")
    registerEvent(testStuff,"onPostPlayerKill","createDeathEffect")
    registerEvent(testStuff,"onReset","onResetDeathEffects")


    --registerEvent(testStuff,"onSaveGame","onSaveGameEarly",true)
    --registerEvent(testStuff,"onSaveGame","onSaveGameLate",false)
    --registerEvent(testStuff,"onDraw","onDrawSaveIcon")
    --registerEvent(testStuff,"onStart","onStartSaveIcon")


    registerEvent(testStuff,"onStart","onStart",false)

    registerEvent(testStuff,"onTick")
    registerEvent(testStuff,"onTickEnd")
    registerEvent(testStuff,"onDraw")

    registerEvent(testStuff,"onCameraUpdate")

    registerEvent(testStuff,"onPlayerKill")

    registerEvent(testStuff,"onReset")

    registerEvent(testStuff,"onExitLevel")

    registerEvent(testStuff,"onCheckpoint")

    registerEvent(testStuff,"onPostExplosion")
end


return testStuff