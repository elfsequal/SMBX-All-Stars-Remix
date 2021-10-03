-------------------------------
--  Simple Star Coin HUD v2  --
--     by EeveeEuphoria      --
-------------------------------

--[[ Usage:
	
	This is meant to be used if the HUD is disabled, such as by mods like ModernStyledHud.lua
	This can also be used if you manually disable the star coin counter.
	
	Place this somewhere near the top in your global episode/local level lunalua file:
	local scHUD = require("scHUD")
	
	After that line, use these to specify the HUD coordinates (based off the top-left pixel):
	scHUD.x = 40
	scHUD.y = 220
	If nothing is provided, they will default to 20 and 200 respectively.
	
	scHUD.levelstable = levelstarcoincounter
	If provided, this table will be used to represent how many star coins are in a specified level above a warp (door/pipe); before a player actually visits it to populate the save data with the actual value. 
	Do it like this:
	local levelstarcoincounter = {
	["cool level.lvl"] = 3,
	["funky town.lvlx"] = 2,
	["souper mayro.lvl"] = 3,
	}
	Be sure that it corresponds to the file name of your level in question, down to the file extension! .lvl is not the same as .lvlx!
	Also, whenever the player actually visits the level, it will check the values found in the save data rather than the provided table; this is really just a workaround.
	
			Other options include:
	scHUD.offset = 20
	This will determine how much should be added in-between each star-coin entry. Note that this isn't the space in-between, it's the total length before it starts drawing the next sprite.
	If not provided, it will default to 16.
	
	scHUD.center1 = 372
	scHUD.center2 = 427
	This will center the star coin hud according to two positions given; useful for centering on the item-drop box!
	If this is provided, scHUD.x will be ignored.
	It's recommended to use the left-most value first, with the right-most value second! (i.e. lowest value first, highest value second)
	
	scHUD.active = Graphics.loadImage(Misc.resolveFile("GFX/redcoina.png"))
	scHUD.inactive = Graphics.loadImage(Misc.resolveFile("GFX/redcoini.png"))
	scHUD.unclaimed = Graphics.loadImage(Misc.resolveFile("GFX/blue coin.png"))
	This will change the provided graphics used for the active/inactive (collected/unclaimed/unclaimed) star coins.
	Do note it will be assumed the length of both is the same as the inactive sprite; if they're not the same, it will not center properly!
	Another notre is that if "scHUD.unclaimed" is not declared, it will default to whatever scHUD.inactive is set to instead.
	
	scHUD.scHUD.playery = 60
	This sets the distance above the player the HUD should be if they're in front of a warp that leads to a level with star-coins.
	It will default to 48 if nothing is provided.
	
	scHUD.disablehud = true
	You can use this to disable the HUD portion if you just want to use the HUD used for warps.
	Enabling this will render scHUD.x, scHUD.y, scHUD.levelstable, and scHUD.center1/2 useless.
	
	scHUD.disablewarphud = true
	Use this to disable rendering the coins above the player when near a level warp w/ star coins.
	Use this combined with disablehud to have a useless mod that just wastes CPU cycles!
]]

--[[ Changelog for v2:
	- Now warp doors uses GFX to indicate if the player has collected a coin in a level, but hasn't saved their progress.
	- Code is a bit tidier now!
]]

local scHUD = {}

scHUD.active = Graphics.sprites.hardcoded["51-1"].img
scHUD.inactive = Graphics.sprites.hardcoded["51-0"].img
--scHUD.unclaimed = Graphics.loadImage(Misc.resolveFile("GFX/blue coin.png"))

function scHUD.onInitAPI()
	registerEvent(scHUD, "onDraw")
	registerEvent(scHUD, "onTick")
end

scHUD.x = 361
scHUD.y = 90
scHUD.offset = 16
scHUD.playery = 48

local function scDDT(value, playerhud)
	if not playerhud then
		if value == 0 then
			return scHUD.inactive
		elseif value == 1 then
			return scHUD.active
		elseif value == 2 and scHUD.unclaimed then
			return scHUD.unclaimed
		else
			return scHUD.inactive
		end
	else
		if value == 0 then
			return scHUD.inactive
		else
			return scHUD.active
		end
	end
end

function scHUD.onDraw()
	local starCoinsT = SaveData._basegame.starcoin[Level.filename()]
	if not scHUD.disablehud and (starCoinsT ~= nil and #starCoinsT ~= 0) then
		for index, value in ipairs(starCoinsT) do
			if scHUD.center1 and scHUD.center2 then
				local length = scHUD.offset*(#starCoinsT-1) + scHUD.inactive.width
				local xcen = math.ceil((math.abs(scHUD.center1 - scHUD.center2) - length)*0.5)
				Graphics.drawImage(scDDT(value, true), scHUD.center1 + xcen + (scHUD.offset*(index-1)), scHUD.y)
			else
				Graphics.drawImage(scDDT(value, true), scHUD.x + (scHUD.offset*index), scHUD.y)
			end
		end
	end
	if not scHUD.disablewarphud then
		for _,plyr in ipairs(Player.get()) do
			if plyr:mem(0x5A,FIELD_WORD) > 0 then
				local warp = Warp(plyr:mem(0x5A,FIELD_WORD)-1)
				if warp.levelFilename ~= "" then
					local starCoinsT2 = SaveData._basegame.starcoin[warp.levelFilename]
					if starCoinsT2 ~= nil and #starCoinsT2 ~= 0 then
						for index, value in ipairs(starCoinsT2) do
							local length = scHUD.offset*(#starCoinsT2-1) + scHUD.inactive.width
							local xcen = math.floor((plyr.width - length)*0.5)
							Graphics.drawImageToScene(scDDT(value), plyr.x + xcen + scHUD.offset*(index-1), plyr.y - scHUD.playery)
							--Text.print(value, 20, 220 + (20*index))
						end
					elseif type(scHUD.levelstable) == "table" and scHUD.levelstable[warp.levelFilename] then
						local length = scHUD.offset*(scHUD.levelstable[warp.levelFilename]-1) + scHUD.inactive.width
						local xcen = math.floor((plyr.width - length)*0.5)
						for i=scHUD.levelstable[warp.levelFilename],1,-1 do
							Graphics.drawImageToScene(scHUD.inactive, plyr.x + xcen + scHUD.offset*(i-1), plyr.y - scHUD.playery)
						end
					end
				end
			end
		end
	end
end

return scHUD