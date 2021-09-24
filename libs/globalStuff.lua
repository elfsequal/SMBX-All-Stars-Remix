require("libs/nsmbwalls")
require("libs/Twirl")

--local dropShadows = require("libs/dropShadows")
local antizip = require("libs/antizip")
local modernReserveItems = require("libs/modernReserveItems")
local coyotetime = require("libs/coyotetime")
local anotherPowerDownLibrary = require("libs/anotherPowerDownLibrary")
local extraNPCProperties = require("libs/extraNPCProperties")
local warpTransition = require("libs/warpTransition")
local playerphysicspatch = require("libs/playerphysicspatch")
local metalCap = require("libs/metalCap")
local ap = require("libs/anotherpowerup")

ap.registerItemTier(981, true)
ap.registerPowerup("libs/ap_goldflower")

ap.registerItemTier(980, true)
ap.registerPowerup("libs/ap_propellermushroom")
local on ground = true