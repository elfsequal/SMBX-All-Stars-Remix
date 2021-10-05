
-- flutterjump.lua 
-- by AndrewPixel

local flutterjump = {}

local jumptimer = 0
local fluttertimer = 0
local canflutter = true
local springed = false
local soundfx 

function flutterjump.onInitAPI()
	registerEvent(flutterjump, "onTick")
	registerEvent(flutterjump, "onDraw")
end

function flutterjump.onTick()

	if player:mem(0x66, FIELD_BOOL) or player:mem(0x108, FIELD_WORD) ~= 3 then return end

	if player:mem(0x60, FIELD_BOOL) or player.speedY > 0 then
		if player.speedY <= 2 and fluttertimer == 0 then
			jumptimer = jumptimer + 1
		else
			jumptimer = 37
		end
	else
		if player.speedY == 0 then
			jumptimer = 0
		end
	end

	if canflutter and player.keys.jump and (jumptimer >= 37 or player.speedY > 2) and player.speedY > -7 then
		if math.abs(player.speedX) > math.abs(player.direction * 3.5) then
			player.speedX = player.speedX * 0.8
		end
		if player.speedY > 10 then
			player.speedY = player.speedY - 4
		else
			player.speedY = player.speedY - 0.7
		end
		fluttertimer = fluttertimer + 1
		if fluttertimer == 1 then
			soundfx = SFX.play{
				sound = Misc.resolveFile("costumes/klonoa/SMW2-Yoshi/klonoa_flutter.ogg")
			}
		end
	else
		if not springed and player.speedY < -7 or fluttertimer >= 50 then
			canflutter = false
		else
			if (not player:mem(0x60, FIELD_BOOL) and player.speedY == 0) or player:mem(0x176, FIELD_WORD) ~= 0 then
				springed = false
				canflutter = true
				fluttertimer = 0
			end
		end
	end

	if not canflutter and player:mem(0x11C, FIELD_WORD) > 0 then
		canflutter = true
		fluttertimer = 0
		jumptimer = 0
	end

	if (fluttertimer > 0 and not player.keys.jump) then
		canflutter = false
	end

	if fluttertimer > 20 and player:mem(0x14A, FIELD_WORD) > 0 then
		canflutter = false
	end

	if player.speedY < -10 then
		jumptimer = 0
		fluttertimer = 0
		canflutter = true
		springed = true
	end

	if not canflutter and soundfx then
		soundfx:fadeout(500)
	end

end

function flutterjump.onDraw()
	if canflutter and fluttertimer > 0 then
		player:mem(0x7A, FIELD_WORD, 3.5 + 3.5*player.direction + math.floor(lunatime.tick() * 0.4) % 3)
	end
end

return flutterjump