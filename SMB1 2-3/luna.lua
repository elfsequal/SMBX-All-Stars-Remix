require("libs/globalStuff")
local fakeblocks = require("libs/blocks/ai/fakeblocks")

-- If true, blocks on the "nsmbwalls" layer will be converted into fake blocks
fakeblocks.useNSMBWallsLayer = true

-- List of additional NSMBWalls layer names. All blocks on these layers will be converted into fake blocks
-- Include any layers that you previously added to the nsmbwalls.layers table here, if any
-- Has no effect if fakeblocks.useNSMBWallsLayer is not set
fakeblocks.additionalNSMBWallsLayers = {}