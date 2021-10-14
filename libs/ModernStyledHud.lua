------------------------------------------------------------------------
--                                                                    --
--  Modern Styled Hud For SMBX                                        --
--  Made by Elf of Happy and Love (快乐爱的小精灵)                    --
--                                                                    --
--  This replaces Original SMW Styled Hud with a Modern Styled Hud.   --
--  Like New Super Mario Bros. Wii, Super Mario Maker, etc.           --
--                                                                    --
--  Documentation: https://pastebin.com/s7hFRG4U                      --
--                                                                    --
--  (Note: Star Coin counters and other new characters aren't         --
--  implemented yet)                                                  --
--                                                                    --
------------------------------------------------------------------------

local modernhud = {}

local ticks = 0
local timeup = false

local hurryupsfx = Misc.multiResolveFile("hurry-up.ogg", "sound/extended/hurry-up.ogg")

local modernhudchar = {}
modernhudchar[1] = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-1-1.png", "graphics/modernhud/modernhud-1-1.png"))
modernhudchar[2] = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-1-2.png", "graphics/modernhud/modernhud-1-2.png"))
modernhudchar[3] = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-1-3.png", "graphics/modernhud/modernhud-1-3.png"))
modernhudchar[4] = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-1-4.png", "graphics/modernhud/modernhud-1-4.png"))
modernhudchar[5] = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-1-5.png", "graphics/modernhud/modernhud-1-5.png"))

local coincounter = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-2.png", "graphics/modernhud/modernhud-2.png"))
local starcounter = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-3.png", "graphics/modernhud/modernhud-3.png"))

local multiplier = Graphics.sprites.hardcoded["33-1"].img
local reservebox = Graphics.sprites.hardcoded["48-0"].img

local heartbg =  Graphics.sprites.hardcoded["36-2"].img
local heartfill = Graphics.sprites.hardcoded["36-1"].img
local timergfx = Graphics.loadImage(Misc.multiResolveFile("libs/ModernHud/modernhud-4.png", "graphics/modernhud/modernhud-4.png"))

modernhud.usereserve = modernhud.usereserve or true

function modernhud.onInitAPI()
	registerEvent(modernhud,"onStart","onStart",true)
	registerEvent(modernhud,"onTick","onTick",true)
end

local function ModernHUD(camIndex,priority,isSplit)
	Graphics.drawImageWP(timergfx,502,65,5)
	if Level.settings.timer and Level.settings.timer.enable then
		Text.printWP(string.format("%03d",Timer.getValue()),1,520,65,5)
	else
		Text.printWP("000",1,520,65,5)
	end
	Graphics.drawImageWP(modernhudchar[player.character],32,38,5)
	Text.printWP(string.format("%08d",SaveData._basegame.hud.score),1,466,48,5)
	Text.printWP(mem(0x00B2C5AC,FIELD_FLOAT),1,84,48,5)
	Text.printWP(mem(0x00B2C5A8,FIELD_WORD),1,176,48,5)
	Text.printWP(mem(0x00B251E0,FIELD_WORD),1,274,48,5)
	Graphics.drawImageWP(coincounter,124,38,5)
	Graphics.drawImageWP(starcounter,216,38,5)
	Graphics.drawImageWP(multiplier,66,48,5)
	Graphics.drawImageWP(multiplier,158,48,5)
	Graphics.drawImageWP(multiplier,256,48,5)
	if modernhud.usereserve and player.character < 3 then
		Graphics.drawImageWP(reservebox,372,30,3)
		if player.reservePowerup > 0 then
			local reservepower = Graphics.sprites.npc[player.reservePowerup].img
			Graphics.draw{type = RTYPE_IMAGE,image = reservepower, x = 384, y = 42, sourceWidth = NPC.config[player.reservePowerup].width, sourceHeight = NPC.config[player.reservePowerup].height}
		end
	end
	if player.character >= 3 then
		Graphics.drawImageWP(heartbg,357,38,4.9)
		Graphics.drawImageWP(heartbg,389,38,4.9)
		Graphics.drawImageWP(heartbg,421,38,4.9)
		if (player:mem(0x16,FIELD_WORD)) == 1 then
			Graphics.drawImageWP(heartfill,357,38,5)
		elseif (player:mem(0x16,FIELD_WORD)) == 2 then
			Graphics.drawImageWP(heartfill,357,38,5)
			Graphics.drawImageWP(heartfill,389,38,5)
		elseif (player:mem(0x16,FIELD_WORD)) == 3 then
			Graphics.drawImageWP(heartfill,357,38,5)
			Graphics.drawImageWP(heartfill,389,38,5)
			Graphics.drawImageWP(heartfill,421,38,5)
		end
	end
end

function modernhud.onStart()
	Graphics.overrideHUD(ModernHUD)
end

function modernhud.onTick()
	if not modernhud.usereserve and player.character < 3 then
		player.reservePowerup = 0
	end
end

return modernhud