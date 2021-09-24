local readme = {}

-- readmesign.lua v1.1
-- Created by SetaYoshi

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")
local textplus = require("textplus")
local font = textplus.loadFont("block-1000-font.ini")

local blockID = BLOCK_ID

local settings = blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true,
	sizable = true,

	xscale = 2,
	yscale = 2,
	offX = 14,
	offY = 16,
	priority = -89.9,
	plaintext = false
})


function readme.onDrawBlock(b)
	textplus.print{text = b.data._settings.text, font = font, x = b.x + settings.offX, y = b.y + settings.offY, xscale = settings.xscale, yscale = settings.yscale, priority = settings.priority, maxWidth = b.width - settings.offX*2, plaintext = settings.plaintext, sceneCoords = true}
end

function readme.onInitAPI()
  blockmanager.registerEvent(blockID, readme, "onDrawBlock")
end

return readme
