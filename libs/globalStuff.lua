local globalStuff = {}
require("libs/nsmbwalls")
require("libs/Twirl")

local dropShadows = require("libs/dropShadows")

local antizip = require("libs/antizip")
local modernReserveItems = require("libs/modernReserveItems")
local coyotetime = require("libs/coyotetime")
local anotherPowerDownLibrary = require("libs/anotherPowerDownLibrary")
local extraNPCProperties = require("libs/extraNPCProperties")
local warpTransition = require("libs/warpTransition")
local playerphysicspatch = require("libs/playerphysicspatch")
local aw = require("libs/anotherwalljump")
local ModernStyledHud = require("libs/ModernStyledHud")
local scHUD = require("libs/scHUD")
local textbox = require ("libs/customTextbox")
local flutterjump = require ("libs/flutterjump")
local spawnzones = require ("libs/spawnzones")
local deathTracker = require("libs/deathTracker")
local altfiredeathsystem = require("libs/altfiredeathsystem")

aw.registerAllPlayersDefault()
--aw.blacklist(87)

--local handycam = require("handycam")
--handycam[1].zoom = 1

local on ground = true