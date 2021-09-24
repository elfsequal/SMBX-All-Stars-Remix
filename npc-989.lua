--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")

local npcTower = {}
local npcID = NPC_ID

local npcTowerSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
}

npcManager.setNpcSettings(npcTowerSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
)

local copyFromProperties = {
	"dontMove","legacyBoss","msg",
	"attachedLayerName","activateEventName","deathEventName","noMoreObjInLayer","talkEventName","layerName",
	"ai1","ai2","ai3","ai4","ai5","direction",
}

-- Most vanilla NPCs have nogravity set to false despite having the effects of nogravity, so here's a map of those IDs
local noGravityIDs = table.map{
	8,11,16,17,18,37,38,40,41,42,43,44,46,47,50,51,52,56,57,60,62,64,66,74,85,87,91,93,104,105,106,108,133,159,160,180,196,197,
	203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,245,246,255,256,257,
	259,260,266,269,270,271,272,274,276,282,283,289,290,292,
}

local validNPCForcedStates = table.map{0,1,3,4} -- 0x138 values that are valid and don't kick the NPC out of the stack


local function solidNPCFilter(v) -- Filter for Colliders.getColliding to only return NPCs that are solid to NPCs
    return (not v.isGenerator and not v.isHidden and not v.friendly and (NPC.config[v.id] and NPC.config[v.id].npcblock))
end
local function isCollidingWithSolidBlock(v) -- Get vhether or not this NPC is touching a block/NPC
	return (not NPC.config[v.id].noblockcollision and not v.noblockcollision and (#Colliders.getColliding{a = v,b = Block.SOLID.. Block.PLAYER,btype = Colliders.BLOCK} > 0 or #Colliders.getColliding{a = v,btype = Colliders.NPC,filter = solidNPCFilter} > 0))
end


local colBox = Colliders.Box(0,0,0,0)
local function goThroughSemisolidBlocks(v,towerData) -- Somewhat janky way to go through semisolid blocks/NPCs
	if v.speedY < 0 or (v.noblockcollision or NPC.config[v.id].noblockcollision) then return end

	colBox.x,colBox.y = v.x,v.y+v.speedY+v.height
	colBox.width,colBox.height = v.width,1

	local semisolidObj

	-- Check for semisolid blocks
	for _,w in ipairs(Colliders.getColliding{a = colBox,b = Block.SOLID.. Block.PLAYER.. Block.SEMISOLID,btype = Colliders.BLOCK}) do
		if Block.SEMISOLID_MAP[w.id] and v.y+v.height <= w.y+v.speedY+0.5 then
			semisolidObj = w
		else
			return
		end
	end
	-- Check for semisolid NPCs
	for _,w in ipairs(Colliders.getColliding{a = colBox,btype = Colliders.NPC}) do
		local config = NPC.config[w.id]

		if config and (config.playerblocktop and not config.npcblock) and v.y+v.height <= w.y+v.speedY+0.5 then
			semisolidObj = w
		else
			return
		end
	end

	if semisolidObj then
		if semisolidObj.__type == "NPC" then
			v.y = v.y + 4.5
		else
			v.y = v.y + 0.5
		end
		v.speedY = towerData.speedY
	end
end

local function updateXPosition(v,normalX,towerData) -- Get how much the NPC should rock back and forth
	towerData.waveTimer = towerData.waveTimer + 1
	local waveOffset = (math.sin((towerData.waveTimer+(towerData.originalIndex*6))/24)*2)

	v.x = normalX+waveOffset+(v.speedX*2) -- Apply wave offset

	if isCollidingWithSolidBlock(v) then -- If this position would cause colliding with something solid
		towerData.waveTimer = 0
		v.x = normalX
	else
		v.x = normalX+waveOffset
	end
end


function npcTower.onInitAPI()
	npcManager.registerEvent(npcID,npcTower,"onTickNPC")
end

function npcTower.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local settings = v.data._settings
	local data = v.data
	
	if v.despawnTimer <= 0 then
		if data.npcs then
			for _,w in ipairs(data.npcs) do
				if w.isValid then
					w:kill(HARM_TYPE_OFFSCREEN)
				end
			end

			data.npcs = nil
		end

		data.despawnTimer = nil

		return
	end

	-- Initialisation of data, parsing of the ID list, and spawning of NPCs
	if data.despawnTimer == nil then
		data.despawnTimer = 180
	end

	-- Force to be friendly, but store the original value of friendly
	if data.originalFriendly == nil then
		data.originalFriendly = v.friendly
		v.friendly = true
	end

	if not data.npcList and settings.npcList ~= "" then
		local list,errorStr = loadstring("return {".. tostring(settings.npcList).. "}")

		if list == nil then
			error("Error in parsing NPC Tower settings: ".. tostring(errorStr))
		else
			data.npcList = list()

			-- Convert IDs to data
			for k,p in ipairs(data.npcList) do
				if type(p) == "number" then
					data.npcList[k] = {id = p}
				end
			end
		end
	end
	if not data.npcs and data.npcList then
		data.npcs = {}

		local index = 0
		local y = v.y+v.height

		for k,p in ipairs(data.npcList) do
			-- Spawn NPCs
			for i=1,(p.count or 1) do
				index = index + 1

				local config = NPC.config[p.id]
				local w = NPC.spawn(p.id,v.x+(v.width/2),y-(config.height/2),v.section,false,true)

				for _,f in ipairs(copyFromProperties) do
					if p[f] == nil then
						w[f] = v[f]
					else
						w[f] = p[f]
					end
				end
				-- Special case for being friendly or not
				if p.friendly == nil then
					w.friendly = data.originalFriendly
				else
					w.friendly = p.friendly
				end

				w:mem(0x138,FIELD_WORD  ,v:mem(0x138,FIELD_WORD)  )
				w:mem(0x13A,FIELD_WORD  ,v:mem(0x13A,FIELD_WORD)  )
				w:mem(0x13C,FIELD_DFLOAT,v:mem(0x13C,FIELD_DFLOAT))
				w:mem(0x144,FIELD_WORD  ,v:mem(0x144,FIELD_WORD)  )

				w.data._tower = w.data._tower or {}
				local towerData = w.data._tower

				towerData.originalProperties = p

				towerData.originalIndex = index
				towerData.index = index

				towerData.smallestYDistance = (w.y+w.height)-(v.y+v.height) -- The largest offset from the bottom NPC that this NPC has had
				towerData.isBottomNPC = (index == 1)
				towerData.waveTimer = 0
				towerData.speedY = 0

				y = y - w.height
				
				table.insert(data.npcs,w)
			end
		end
	end

	if data.npcs and #data.npcs > 0 then
		local turnAround = false

		local k = 1
		while k <= #data.npcs do
			local w = data.npcs[k]
			if not w.isValid or w.isGenerator or w.isHidden or w.despawnTimer <= 0 -- Boring defeated stuff
			or not validNPCForcedStates[w:mem(0x138,FIELD_WORD)] -- 'Contained within'/forced states
			or w:mem(0x12C, FIELD_WORD) > 0 and k > 1            -- Grabbed (but not the bottom NPC)
			or w.id == 263 and w.ai1 > 0                         -- Turned to ice (but not originally an ice block)
			then
				table.remove(data.npcs,k) -- Remove from stack
			else
				-- Other stuff which runs before main logic
				turnAround = (turnAround or (k > 1 and w:mem(0x120,FIELD_BOOL)))
				
				k = k + 1
			end
		end

		for k,w in ipairs(data.npcs) do
			if v:mem(0x138, FIELD_WORD) == 0 then
				local towerData = w.data._tower
				local config = NPC.config[w.id]

				local bottom = data.npcs[1]
				local below = data.npcs[k-1]
				local above = data.npcs[k+1]

				towerData.index = k

				w:mem(0x120,FIELD_BOOL,w:mem(0x120,FIELD_BOOL) or turnAround)
				
				if not below then
					if not towerData.isBottomNPC then
						-- If this NPC has just become the bottom one
						if w.noblockcollision then -- Crushing
							w.noblockcollision = false

							if isCollidingWithSolidBlock(w) then -- Crush if this NPC just gained collision and is touching a block
								w:kill(HARM_TYPE_NPC)
							end
						end

						towerData.isBottomNPC = true
						w.noblockcollision = false
						w.speedX = 0
					end

					towerData.waveTimer = 0

					-- Special logic
					if config.iscoin and w.ai1 == 0 then
						w.speedX = -0.5*w.direction
						w.ai1 = 1
					end
				else
					towerData.isBottomNPC = false

					w.direction = towerData.originalProperties.direction or bottom.direction
					w.speedX = bottom.speedX

					local noblockcollisionNew = (bottom.noblockcollision or NPC.config[bottom.id].noblockcollision or bottom:mem(0x12C, FIELD_WORD) > 0)
					local noblockcollisionBefore = w.noblockcollision

					w.noblockcollision = noblockcollisionNew

					-- Crush this NPC if it's in a block
					if noblockcollisionBefore and not noblockcollisionNew and isCollidingWithSolidBlock(w) then
						w:kill(HARM_TYPE_NPC)
					end


					-- Apply gravity to NPCs that usually don't have gravity
					if (config.nogravity or noGravityIDs[w.id]) or (config.iscoin and w.ai1 == 0) then
						local gravity = Defines.npc_grav
						if w.underwater then
							gravity = gravity*0.2
						end

						towerData.speedY = math.min(8,towerData.speedY + gravity)
						w.y = w.y + towerData.speedY
					elseif w.speedY > 1 then
						towerData.speedY = w.speedY
					end

					goThroughSemisolidBlocks(w,towerData)


					towerData.smallestYDistance = math.max(towerData.smallestYDistance,(bottom.y+bottom.height)-(v.y+v.height))

					local maxBelow = below.y-w.height+below.speedY
					local maxAbove = math.min((bottom.y+bottom.height)-towerData.smallestYDistance,below.y-(w.height*2))

					if config.npcblock then
						maxBelow = maxBelow - 4
					end

					if w.y > maxBelow then
						w.y = maxBelow
						w.speedY,towerData.speedY = 0,0
					elseif w.y < maxAbove then
						w.y = maxAbove
						w.speedY,towerData.speedY = 0,0
					end

					updateXPosition(w,bottom.x+(bottom.width/2)-(w.width/2),towerData)

					w.spawnX,w.spawnY,w.spawnWidth,w.spawnHeight = w.x,w.y,w.width,w.height -- Mother Brain relies on spawn position, so update it
				end
			end

			if w.despawnTimer >= 180 then
				data.despawnTimer = 180
			end
		end

		if data.despawnTimer > 0 then
			data.despawnTimer = data.despawnTimer - 1

			if lunatime.tick() ~= 1 and v.despawnTimer ~= 1 then -- fixes weird bug where otherwise all towers spawn their NPCs when the level starts
				v.despawnTimer = 180
			end

			if data.despawnTimer >= 180 then
				-- If at least one NPC is on screen, then keep the rest of them spawned
				for _,w in ipairs(data.npcs) do
					if w.isValid and w.despawnTimer > 0 then
						w.despawnTimer = 180
					end
				end
			end
		else
			v.despawnTimer = -1
		end
	elseif data.npcs then -- If all NPCs in the stack have been defeated
		v:kill(HARM_TYPE_OFFSCREEN)
	end
end

return npcTower