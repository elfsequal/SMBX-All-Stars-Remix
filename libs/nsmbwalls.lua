--**********************************************************************--
--**********************************************************************--
--**.-. .-. .----..-.   .-..----. .-. . .-.  .--.  .-.   .-.    .----.**--
--**|  `| |{ {__  |  `.'  || {}  }| |/ \| | / {} \ | |   | |   { {__  **--
--**| |\  |.-._} }| |\ /| || {}  }|  .'.  |/  /\  \| `--.| `--..-._} }**--
--**`-' `-'`----' `-' ` `-'`----' `-'   `-'`-'  `-'`----'`----'`----' **--
--**********************************************************************--
--**********************************************************************--
--------------------------------NSMBWalls---------------------------------
----------------------Created by Sambo - Feb. 2017------------------------
-----------------Adds the "fake wall" effect from NSMBW-------------------
--------------------------------For SMBX----------------------------------
-----------------REQUIRES IMAGIC and COLLIDERS libraries------------------

local imagic = API.load("imagic") -- made by Hoeloe
local colliders = API.load("colliders") -- also made by Hoeloe. Hmmm...

local nsmbwalls = {}

local LAYER = "nsmbwalls"
local DUMMY_IMG = "nsmbwalls/dummyBlock.png"

local X_RAY_RADIUS = 128 -- What was I supposed to call it???
local X_RAY_RESIZE_RATE = 6

local blockImages = {} -- Table of images for the effect layer
local blockData = {} 

nsmbwalls.layers = {LAYER} -- names of layers used for the draw effect.
nsmbwalls.fillerBlocks = {}

local xRays = {} -- The effect that reveals hidden areas
local sensors = {} -- Sensor for xRay activation
local overlays = {} -- Semitransparent overlay for xRay

local count = {0,0} -- pipe warp timers. They count twice as fast in 2P mode for some reason...

local xRayBuffer = Graphics.CaptureBuffer(800, 600)
local overlayBuffer = Graphics.CaptureBuffer(800, 600)

local VE_PRIORITY = {-9.6,-9.4}

local testTexture = Graphics.loadImage("block-444.png")

--[[******************************************************
***                    Initialization                  ***
********************************************************]]

function nsmbwalls.onInitAPI()
	registerEvent(nsmbwalls, "onStart", "initialize", true)
	registerEvent(nsmbwalls, "onCameraUpdate", "update", true)
end

--[[******************************************************
  * Get the path to a png file
  ******************************************************]]
local function getPath(filename)
	return Misc.resolveFile(filename .. ".png") or Misc.resolveFile(DUMMY_IMG);
end

--[[******************************************************
  * Load the images for all blocks on the effect layer
  ******************************************************]]
local function loadBlockData()
	local loadedImages = {}
	for _,b in pairs(Block.get()) do
		for k,v in pairs(nsmbwalls.layers) do
			if tostring(b.layerName) == v then -- Check if the block needs drawn
				if not loadedImages[b.id] then
					loadedImages[b.id] = true
					
					-- load the image
					blockImages[b.id] = Graphics.sprites.block[b.id].img -- no more loadImage!
				end
				--load data for the block into data table
				blockData[#blockData + 1] =
				{
					id = b.id,
					x = b.x,
					y = b.y,
					width = b.width,
					height = b.height
				}
			end
		end
	end
end

function nsmbwalls.initialize()
	for k,_ in pairs(Player.get()) do
	
		-- load a table containing only the block data needed for drawing
		loadBlockData()
	
		-- Create the needed objects for player(s)
		xRays[k] = imagic.Circle{x = 0, y = 0, radius = 1, scene = true}
		sensors[k] = colliders.Circle(0, 0, 8)
	end
end

--[[******************************************************
***                      Running                       ***
********************************************************]]

--[[******************************************************
  * Update the capture buffers
  ******************************************************]]
local function updateBuffers()
	xRayBuffer:captureAt(-9.9)
	overlayBuffer:captureAt(-9.7)
end

--[[******************************************************
  * Check if the sensor is behind a nsmbwalls layer
  ******************************************************]]
local function checkSensor(plr, sensor)
	for _,block in pairs(Block.getIntersecting(plr.x, plr.y, plr.x + plr.width, plr.y + plr.height)) do
		for _,v in pairs(nsmbwalls.layers) do
			if tostring(block.layerName) == v then
				if colliders.collide(sensor, block) then
					return true;
				end
			end
		end
	end
	return false;
end

--[[******************************************************
  * Update the textures and sizes of the objects
  ******************************************************]]
local function getNewRadius(isBehindLayer, xRay, forcedShrink)
	local r = xRay.radius or 0
	if isBehindLayer and not forcedShrink then
		if r + X_RAY_RESIZE_RATE <= X_RAY_RADIUS then
			r = r + X_RAY_RESIZE_RATE
		else
			r = X_RAY_RADIUS
		end
	else
		if r - X_RAY_RESIZE_RATE >= 0 then
			r = r - X_RAY_RESIZE_RATE
		else
			r = 0
		end
	end
	return r
end

--[[******************************************************
  * Draw the effect layer
  ******************************************************]]
local function drawBlocks(cam)
	for _,b in pairs(blockData) do
		if (b.x + b.width >= cam.x and b.x < cam.x + cam.width) and -- on-screen check
		(b.y + b.height >= cam.y and b.y < cam.y + cam.height) then
			Graphics.drawImageToSceneWP(blockImages[b.id], b.x, b.y, -9.8)
			-- Graphics.draw
			-- {
				-- type = RTYPE_IMAGE,
				-- image = blockImages[b.id],
				-- x = b.x,
				-- y = b.y,
				-- isSceneCoordinates = true,
				-- priority = -9.8
			-- }
			-- Switched draw functions due to performance issues
		end
	end
end

--[[******************************************************
  * Update the status of objects
  * Runs in onCameraUpdate because an up-to-date camera position is needed
  ******************************************************]]
function nsmbwalls.update()

	-- Get the camera(s)
	local cams = (Camera.get())

	--Text.print(cams[1].width .. ", " .. cams[1].height, 10, 560)
	--Text.print(cams[2].width .. ", " .. cams[2].height, 10, 580)
	
	updateBuffers()
	
	for k,plr in ipairs(Player.get()) do
		
		-- get the center of the player
		local playerCenterX = math.floor(plr.x + plr.width/2) + .5
		local playerCenterY = math.floor(plr.y + plr.height/2) + .5
		
		-- get the center of the player relative to the camera
		-- needed for the offset of the buffer.
		-- I'm drawing at scene coords for 2P support
		local cam
		local noRedraw = false;
		if (cams[1].width ~= 800 or cams[1].height ~= 600) then
			cam = cams[k]
		else
			cam = cams[1]
			if k == 2 then
				noRedraw = true
			end
		end
		if not noRedraw then
			drawBlocks(cam)
		end
		
		-- local centerOnScreenX = math.floor(playerCenterX - cam.x)
		-- local centerOnScreenY = math.floor(playerCenterY - cam.y)
		local centerOnScreenX = playerCenterX - cam.x
		local centerOnScreenY = playerCenterY - cam.y

		sensors[k].x = playerCenterX
		sensors[k].y = playerCenterY
		
		-- check if the effect should be forced to shrink
		local forcedShrink = false;
		if plr:mem(0x122, FIELD_WORD) == 3 then
			count[k] = count[k] + 1;
			if count[k] > 40 and count[k] <= 70 then
				forcedShrink = true
			end
		else
			count[k] = 0
		end
		
		-- check the sensor
		local isBehindLayer = checkSensor(plr, sensors[k])
		
		-- update the textures and sizes of objects.
		local r = getNewRadius(isBehindLayer, xRays[k], forcedShrink)
		
		if r > 0 then
			xRays[k] = imagic.Circle
			{
				radius = r,
				x = playerCenterX,
				y = playerCenterY,
				scene = true,
				texture = xRayBuffer,
				-- filltype = imagic.TEX_FILL,
				filltype = imagic.TEX_PLACE,
				texoffsetX = (centerOnScreenX - 400)/800,
				texoffsetY = (centerOnScreenY - 300)/600
			}
		
			-- xRays[k]:ScaleTexture((800) / (2 * r), (600) / (2 * r))
		
			overlays[k] = imagic.Circle
			{
				radius = r,
				x = playerCenterX,
				y = playerCenterY,
				scene = true,
				texture = overlayBuffer,
				-- filltype = imagic.TEX_FILL,
				filltype = imagic.TEX_PLACE,
				texoffsetX = (centerOnScreenX - 400)/800,
				texoffsetY = (centerOnScreenY - 300)/600
			}
			-- overlays[k]:ScaleTexture((800) / (2 * r), (600) / (2 * r))
		
			--draw the xRay object
			xRays[k]:Draw(VE_PRIORITY[k], 0xffffffff)
			
			--draw the overlay effect
			overlays[k]:Draw(VE_PRIORITY[k] + .1, 0xffffff66)
		end
	end
end

return nsmbwalls;