--require("libs/globalStuff")

local smwMap = require("smwMap")


--Remote Coin Collection Code
local remoteCC = require("libs/remoteCC")

local fx = {}
local myShader = Shader()
myShader:compileFromFile(nil, "libs/flash.frag")

local duration = 34

function dist(dx, dy)
    return math.sqrt(dx*dx + dy*dy)
end

local seconds = 0
local minutes = 0

function onDraw()
    for _,v in ipairs(Block.get(159)) do
        local d = v.data
        
        if (v:mem(0x52, FIELD_WORD) ~= 0) then --Bonked by player this frame
            if not d.bonked then
                table.insert(fx, {timer = 0, w = v})
                d.bonked = true
            end

            for _,w in NPC.iterateIntersecting(v.x - 224, v.y - 224, v.x + v.width + 224, v.y + v.height + 224) do
                if dist(w.x+w.width/2 - v.x-v.width/2, w.y+w.height/2 - v.y-v.height/2) <= 224 + v.width/2 then
                    remoteCC.collect(w)
                end
            end
        else
            d.bonked = false --Cuz of timestop
        end
    end
    for _,v in ipairs(Colliders.getColliding{a=NPC.SHELL, atype = Colliders.NPC, btype = Colliders.NPC}) do
        if v[1]:mem(0x136,FIELD_BOOL) then --Is projectile
            remoteCC.collect(v[2], v[1])
        end
    end

    seconds = seconds + 0.0156
    -- Text.print("time: " .. math.floor(seconds*1000)/1000, 0, 0) --Upcoming competition!

    for i = #fx, 1, -1 do
        local f = fx[i]
        local v = f.w

        Graphics.drawBox {
            x = v.x - 224,
            y = v.y - 224,
            width = 224*2 + v.width,
            height = 224*2 + v.height,
            
            sceneCoords = true,
            shader = myShader, uniforms = {time = f.timer/duration, r = seed},
        }
        if Defines.levelFreeze then
            f.timer = f.timer + 0.15
        else
            f.timer = f.timer + 1
        end
        if f.timer >= duration then
            table.remove(fx, i)
        end
    end
end


--Mushroom go right code
local mushroom = {9, 90, 184, 185, 186, 187, 293, 425}

function onTick()
    for k,v in ipairs(NPC.get(mushroom)) do
        if v:mem(0x138, FIELD_WORD) == 1 then
            v.direction = DIR_RIGHT
        end
    end
end

function onExitLevel()
	player:transform(1)
end