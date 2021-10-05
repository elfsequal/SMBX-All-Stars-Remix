--[[

	Written by MrDoubleA
	Please give credit!

	Collection sound effects provided by Chipss

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bigCoin = {}

bigCoin.idMap = {}


-- Fun fact: this function is based off of the source code!
local coinsPointer = 0x00B2C5A8
local livesPointer = 0x00B2C5AC
local function addCoins(amount)
    mem(coinsPointer,FIELD_WORD,(mem(coinsPointer,FIELD_WORD)+amount))

    if mem(coinsPointer,FIELD_WORD) >= 100 then
        if mem(livesPointer,FIELD_FLOAT) < 99 then
            mem(livesPointer,FIELD_FLOAT,(mem(livesPointer,FIELD_FLOAT)+math.floor(mem(coinsPointer,FIELD_WORD)/100)))
            SFX.play(15)

            mem(coinsPointer,FIELD_WORD,(mem(coinsPointer,FIELD_WORD)%100))
        else
            mem(coinsPointer,FIELD_WORD,99)
        end
    end
end

function bigCoin.register(id)
	npcManager.registerEvent(id,bigCoin,"onTickNPC")

    bigCoin.idMap[id] = true
end


function bigCoin.onInitAPI()
	registerEvent(bigCoin,"onPostNPCKill")
end


function bigCoin.onTickNPC(v)
	if Defines.levelFreeze
	or v.despawnTimer <= 0
	or v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then return end
	
	npcutils.applyLayerMovement(v)
end

function bigCoin.onPostNPCKill(v,reason)
	if not bigCoin.idMap[v.id] then return end

	local collected = (npcManager.collected(v,reason) or v:mem(0x138,FIELD_WORD) == 5)

	if not collected then return end


	local config = NPC.config[v.id]

	if config.value then
		addCoins(config.value)
	end
	if config.collectSoundEffect then
		SFX.play(config.collectSoundEffect)
	end
	if config.collectEffectID then
		local w = Effect.spawn(config.collectEffectID,0,0)
		w.x = (v.x+(v.width /2)-(w.width /2))
		w.y = (v.y+(v.height/2)-(w.height/2))
	end
end

return bigCoin