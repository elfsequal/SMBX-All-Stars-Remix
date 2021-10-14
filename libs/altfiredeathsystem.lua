--Alternate Death by Fireball System--
--by Nat The Porcupine--

local altfiredeathsystem = {}
local colliders = require("colliders")
local coinStyleTable = {["SMB1"] = 88, ["SMB2"] = 138, ["SMB3"] = 10, ["SMW"] = 33, ["Zelda"] = 251, ["Sonic"] = 152}
local coinStyle = "SMB3"

function altfiredeathsystem.onInitAPI()
	registerEvent(altfiredeathsystem, "onTick", "onTick")
	registerEvent(altfiredeathsystem, "onNPCKill", "onNPCKill")
	registerEvent(altfiredeathsystem, "onTickEnd", "onTickEnd")
end

function altfiredeathsystem.onTick()

	for _,coin in pairs(NPC.get(coinStyleTable[coinStyle],-1)) do
		if coin.ai2 < 1 then
			coin.ai2 = 1;	--ai2 is usually unused on coin NPCs, but here we use it as a "just spawned" flag
		end
	end
	
end

function altfiredeathsystem.onNPCKill(event,npc,reason)
	
	if npc.id == 13 and npc.ai3 == 0 then	--This prevents a player's fireball from dying immediately so we can test for its collision later
		npc.ai3 = 1;
		event.cancelled = true;
	end
	
	if npc.id ~= 13 and reason == 3 then	--This checks for an NPC that isn't a fireball that has died as the result of a thrown projectile
		
		for _,fireball in pairs(NPC.get(13,-1)) do
			if colliders.collide(fireball,npc) then
				
				NPC.spawn(coinStyleTable[coinStyle],npc.x,npc.y,player.section,false);	--Spawns the coin
				
				for _,coin in pairs(NPC.get(coinStyleTable[coinStyle],player.section)) do
					if colliders.collide(coin,npc) and coin.ai2 == 0 then
						coin.speedX = fireball.direction * 0.75;	--Sets the X speed of the coin
						coin.speedY = -4;	--Sets the Y speed of the coin
						coin.ai1 = 1;	--Enables gravity
						npc:kill(9);
						playSFX(9);
						return
					end
				end
			end
		end
		npc:kill(4);
		playSFX(9);
		
	end
	
end

function altfiredeathsystem.onTickEnd()
	for _,npc in pairs(NPC.get(13,-1)) do
		if npc.ai3 == 1 then
			npc:kill(4);	--Kills the fireball for good
		end
	end
end

return altfiredeathsystem;