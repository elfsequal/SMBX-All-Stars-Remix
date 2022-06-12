-- Declare our library table
local pwing = {}

pwing.active = false

function pwing.onInitAPI()
	registerEvent(pwing, "onTickEnd")
	registerEvent(pwing, "onStart")
	registerEvent(pwing, "onExit")
end

function pwing.onStart()
	Defines.cheat_wingman = false
	pwing.active = false
end

function pwing.onExit()
	Defines.cheat_wingman = false
	pwing.active = false
end

function pwing.onTickEnd()
	if pwing.active then
		if player.powerup == 4 or player.powerup == 5 and Level.endState() == 0 then
			player:mem(0x02, FIELD_WORD, 80)
			if player.mount == 0 then
				Defines.cheat_wingman = true
			else
				Defines.cheat_wingman = false
				
				--Disable sparkles while on the ground
				if player:isGroundTouching() == false then
					player:mem(0x16E, FIELD_BOOL, true)
					player:mem(0x170, FIELD_FLOAT, 999)
				end
			end
		else
			Defines.cheat_wingman = false
			pwing.active = false
		end
	end
end

return pwing