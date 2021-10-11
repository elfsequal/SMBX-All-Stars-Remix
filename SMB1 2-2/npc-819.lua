local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	frames = 4,
	framestyle = 0,
	
	gfxwidth = 66,
	gfxheight = 64,
	width = 64,
	height = 64,
	
	nohurt = true,
	noiceball = true,
	
	fluddId = id + 1,
}

function npc.onTickEndNPC(v)
	local config = NPC.config[id]
	
	if v.ai1 ~= config.fluddId then
		v.ai2 = 3
	end
	
	v.animationFrame = ((config.framestyle > 0 and v.direction == 1) and (v.ai2 + config.frames)) or v.ai2
end

function npc.onPostNPCHarm(v, r, c)
	if v.ai1 <= 0 or v.id ~= id then return end
	
	local config = NPC.config[id]
	
	local n = NPC.spawn(v.ai1, v.x, v.y)
	n.x = v.x + (v.width - n.width) / 2
	n.y = v.y + (v.height - n.height) / 2
	
	n.direction = v.direction
	n.dontMove = v.dontMove
	n.despawnTimer = 100
	n.layerName = "Spawned NPCs"
	n.legacyBoss = v.legacyBoss
	n.friendly = v.friendly
	
	if n.id == config.fluddId then
		n.ai2 = v.ai2
	end
end

function npc.onInitAPI()
	npcManager.registerHarmTypes(id,
	{HARM_TYPE_JUMP, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
	{
		[HARM_TYPE_JUMP] = 131,
		[HARM_TYPE_TAIL] = 131,
		[HARM_TYPE_SWORD] = 131,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	});
	
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	registerEvent(npc, 'onPostNPCHarm')
end

return npc