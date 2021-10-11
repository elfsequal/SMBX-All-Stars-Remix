local npc = {}
local id = NPC_ID
local npcManager = require 'npcManager'

npcManager.setNpcSettings{
	id = id,

	frames=4,
	
	nogravity = true,
	noblockcollision = true,

	nohurt = true,
	jumphurt = true,
	isinteractable = true,
	iscoin = true,
}

function npc.onTickEndNPC(v)
	v.animationFrame = -1
end

local function isColliding(a,b)
	   if ((b.x >= a.x + a.width) or
		   (b.x + b.width <= a.x) or
		   (b.y >= a.y + a.height) or
		   (b.y + b.height <= a.y)) then
			  return false 
	   else return true
           end
	end
	
function npc.onCameraDrawNPC(v, idx)
	if v.despawnTimer <= 0 or not isColliding(v, Camera(idx)) then return end
	
	local data = v.data._basegame
	local cfg = NPC.config[id]
	
	local frame = (lunatime.tick() / cfg.framespeed)
	local angle = -math.rad(180 / 2)

	if data.pos then
		angle = math.atan2(v.y - data.pos.y, v.x - data.pos.x)
	end
	
	Sprite.draw{
		texture = Graphics.sprites.npc[v.id].img,
		
		x = v.x + v.width / 2,
		y = v.y + v.height / 2,
		
		frames = cfg.frames,
		frame = (math.floor(frame) % cfg.frames) + 1,
		
		align = Sprite.align.CENTER,
		sceneCoords = true,
		priority = -45,
		
		rotation = math.deg(angle),
	}
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	npcManager.registerEvent(id, npc, 'onCameraDrawNPC')
end

return npc