local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"
local fludd = require 'fludd'

npcManager.setNpcSettings{
	id = id,
	
	frames = 3,
	framestyle = 1,
	
	gfxwidth = 38,
	gfxheight = 42,
	width = 38,
	height = 42,
	
	nohurt = true,
	jumphurt = true,
	noiceball = true,
	isinteractable = true,
	
	fluddId = id + 1,
}

function npc.onTickEndNPC(v)
	local config = NPC.config[id]
	
	v.animationFrame = ((config.framestyle > 0 and v.direction == 1) and (v.ai2 + config.frames)) or v.ai2
end

function npc.onNPCKill(e, v, r)
	if v.id ~= id then return end
	
	for k,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.mount == 0 and not p.isMega then
			fludd.activate(p.idx, v.ai2)
		else
			e.cancelled = true
		end
	end
end

function npc.onInitAPI()
	npcManager.registerHarmTypes(id,
	{HARM_TYPE_LAVA}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	});
	
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	registerEvent(npc, 'onNPCKill')
end

return npc