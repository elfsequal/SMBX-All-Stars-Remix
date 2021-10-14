-- Made by DitchenCat
local SuperJump = {};

local charge = 0;
local pwrUp = false;
local display = " ";
local ableToSJ = true;
local sfxPlay = false;
local maxC = false;
local inASJ = false;
local BAR = Graphics.loadImage(Misc.resolveFile("libs/SuperJump/Bar.png"))
local FIL = Graphics.loadImage(Misc.resolveFile("libs/SuperJump/Bar-fill.png"))
local FLA = Graphics.loadImage(Misc.resolveFile("libs/SuperJump/Bar-flash.png"))

function SuperJump.onInitAPI()
	registerEvent(SuperJump, "onLoop", "onLoop")
	registerEvent(SuperJump, "onKeyDown", "onKeyDown")
	registerEvent(SuperJump, "onKeyUp", "onKeyUp")
	registerEvent(SuperJump, "onEvent", "onEvent")
	registerEvent(SuperJump, "jumpChecker", "jumpChecker")
	registerEvent(SuperJump, "superJump", "superJump")
	registerEvent(SuperJump, "drawCharge", "drawCharge")
end



function SuperJump.jumpChecker()

	if maxC == true then
		Defines.jumpheight = 30;
	else
		Defines.jumpheight = 20;	
	end 
	
	
	maxC = false;
	
	if pwrUp == true then
	
		charge = charge + 1;
		if charge > 60 then
		
			if sfxPlay == false then
			Audio.playSFX(Misc.resolveFile("libs/SuperJump/Charge.ogg"))
			sfxPlay = true
			end
			
			charge = 60;
			maxC = true;
			
		end
	end
	
	if inASJ == true then
	
		ableToSJ = true;
		
	else
	
	if player:mem(0x146,FIELD_WORD) == 2 or player:mem(0x48,FIELD_WORD) > 0 or player:mem(0x176,FIELD_WORD) > 0 then
		if player:mem(0x34,FIELD_WORD) == 0 then
			if player.character == CHARACTER_TOAD then
				if player:mem(0x112,FIELD_WORD) == 4 or player:mem(0x112,FIELD_WORD) == 5 then
					ableToSJ = false;
				else
					ableToSJ = true;
				end
			else
				ableToSJ = true;
			end
		else
			ableToSJ = false;
		end
	else
		ableToSJ = false;
	end
	
	end
	
end

function SuperJump.drawCharge()
	if pwrUp == true then
		Graphics.drawImageWP(FIL, 102, 4, 0, 0, charge * 2, 0, 0)
		if maxC == true then
			Graphics.drawImageWP(FLA, 102, 4, 0)
		end
	end
end

function SuperJump.onKeyDown(Code)

	if Code == 1 and ableToSJ == true then
		pwrUp = true;
	elseif Code == KEY_JUMP and maxC == true then 
		SuperJump.superJump()
	elseif Code > 1 and inASJ == false or Code == 0 and inASJ == false then
		pwrUp = false;
		charge = 0;
	end

end

function SuperJump.onKeyUp(Code)
	if Code == 1 and maxC == true then
	-- Youre fine
	else
		sfxPlay = false;
		pwrUp = false;
		charge = 0;
	end
end

function SuperJump.superJump()
	-- I need a particle system here.
	-- Ive tried to use a particle api for this
	-- but the particles disappear abruptly when the jump ends.
	end

function SuperJump.onLoop()
	Graphics.drawImageWP(BAR,80,2,0)
	SuperJump.jumpChecker()
	SuperJump.drawCharge()
end

return SuperJump;