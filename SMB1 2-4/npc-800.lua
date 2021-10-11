local npcManager = require("npcManager");
local lunajson = require("ext/lunajson")

local stackNPC = {};

local npcStackBaseList = {}
local npcStackInverseReferenceLookup = {}
local stackNPCLookup = {}
local npcTableRemovalList = {}
local removingNPCs = false

local npcID = NPC_ID

npcManager.setNpcSettings ({
    id = npcID,
    gfxheight = 32,
    gfxwidth = 32,
    width = 32,
    height = 32,
    frames = 1,
    framestyle = 0,
    jumphurt = 1,
    nohurt=1,
    nofireball = 1,
	noyoshi = 1,
	npcblocktop = 0,
    score = 2,
    noblockcollision=true,
    nogravity=true,
});
npcManager.registerDefines(npcID, {NPC.UNHITTABLE});

function stackNPC.onInitAPI()
	npcManager.registerEvent(npcID, stackNPC, "onStartNPC");
    registerEvent(stackNPC, "onPostNPCKill");
	registerEvent(stackNPC, "onTick");
end

local function positionStackNPC(v, upper)
    v.x = upper.x + 0.5 * upper.width - 0.5 * v.width
    v.y = upper.y - v.height
end

local function spawnStackNPC(data, x, y, section, npcData, upper)
    local n = NPC.spawn(data.id, x, y, section, true)
    if upper then
        positionStackNPC(n, upper)
        npcStackInverseReferenceLookup[n] = upper
        n.data.swayTimer = RNG.random(0, 100)
        n.data.noblockcollision = n.noblockcollision
        n.noblockcollision = true
    else
        n.x = x - n.width * 0.5
        n.y = y - n.height
        table.insert(npcStackBaseList, n)
    end
    n:mem(0xA8, FIELD_DFLOAT, n.x)
    n:mem(0xB0, FIELD_DFLOAT, n.y)
    for k,v in pairs(npcData) do
        n[k] = v
    end
    if data.ai1 then
        n:mem(0xDE, FIELD_WORD, data.ai1)
        n.ai1 = data.ai1
    end
    if data.ai2 then
        n:mem(0xE0, FIELD_WORD, data.ai2)
        n.ai2 = data.ai2
    end
    n:mem(0xD8, FIELD_FLOAT, n.direction)
    n:mem(0xDC, FIELD_WORD, n.id)
    stackNPCLookup[n] = true
    if data.settings then
        n.data._settings = table.join(data.settings, n.data._settings)
    end
    if (data.child) then
        n.data.child = spawnStackNPC(data.child, x, y, section, npcData, n)
    end
    return n
end

function stackNPC.onPostNPCKill(v, killReason) 
    if not stackNPCLookup[v] then return end

    stackNPCLookup[v] = nil

    if v.data.child then
        npcStackInverseReferenceLookup[v.data.child] = nil
        if v.data.child.data.noblockcollision ~= nil then
            v.data.child.noblockcollision = v.data.child.data.noblockcollision
        end
        table.insert(npcStackBaseList, v.data.child)
    end

    if npcStackInverseReferenceLookup[v] then
        npcStackInverseReferenceLookup[v].data.child = nil
    else
        npcTableRemovalList[v] = true
        removingNPCs = true
    end
end

function stackNPC.onStartNPC(v)
	-- Reference to current instance
    local data = v.data._basegame
    
    if v.data._settings and v.data._settings.stack ~= "" then
        local s = lunajson.decode(v.data._settings.stack)
        spawnStackNPC(s, v.x + 0.5 * v.width, v.y + v.height, v:mem(0x146, FIELD_WORD), {
            direction = v.direction,
            friendly = v.friendly,
            layerName = v.layerName,
            layerObj = v.layerObj
        })
    end

    v:kill(9)
end

local function positionChild(v, x)
    if v.isValid and v.data.child and v.data.child.isValid then
        v.data.child.x = x - 0.5 * v.data.child.width
        v.data.child.y = v.y - v.data.child.height
        positionChild(v.data.child, x)
        v.data.child.data.swayTimer = v.data.child.data.swayTimer + 1
        v.data.child.x = v.data.child.x + 4 * math.sin(v.data.child.data.swayTimer * 0.125)
        v.data.child.speedX = 0
        v.data.child.speedY = 0
    end
end

function stackNPC.onTick()
    if removingNPCs then
        for i=#npcStackBaseList, 1, -1 do
            if npcTableRemovalList[npcStackBaseList[i]] then
                table.remove(npcStackBaseList, i)
            end
        end
        npcTableRemovalList = {}
        removingNPCs = false
    end

    if Defines.levelFreeze then return end
    
    for k,v in ipairs(npcStackBaseList) do
        positionChild(v, v.x + 0.5 * v.width)
    end
end

return stackNPC;