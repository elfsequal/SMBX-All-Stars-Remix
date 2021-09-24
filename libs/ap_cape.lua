--[[

    Cape for anotherpowerup.lua
    by MrDoubleA

    Credit to JDaster64 for making a SMW physics guide and ripping SMA4 Mario/Luigi sprites
    Custom Toad and Link sprites by Legend-Tony980 (https://www.deviantart.com/legend-tony980/art/SMBX-Toad-s-sprites-Fourth-Update-724628909, https://www.deviantart.com/legend-tony980/art/SMBX-Link-s-sprites-Sixth-Update-672269804)
    Custom Peach sprites by Lx Xzit and Pakesho
    SMW Mario and Luigi graphics from AwesomeZack

    Credit to FyreNova for generally being cool (oh and maybe working on a SMBX38A version of this, too)

]]

local ai = require("libs/ap_cape_ai")

local apt = {}

apt.spritesheets = {
    Graphics.loadImageResolved("mario-2.png"),
    Graphics.loadImageResolved("luigi-2.png"),
    Graphics.loadImageResolved("peach-2.png"),
    Graphics.loadImageResolved("toad-2.png"),
    Graphics.loadImageResolved("link-2.png"),
}

apt.capeSpritesheets = {
    Graphics.loadImageResolved("mario-ap_cape_cape.png"),
    Graphics.loadImageResolved("luigi-ap_cape_cape.png"),
    Graphics.loadImageResolved("peach-ap_cape_cape.png"),
    Graphics.loadImageResolved("toad-ap_cape_cape.png"),
    Graphics.loadImageResolved("link-ap_cape_cape.png"),
}

apt.apSounds = {
    upgrade = SFX.open(Misc.resolveSoundFile("ap_cape_get")),
    reserve = 12
}

apt.items = {984}


apt.cheats = {"needacape","needafeather"}

ai.register(apt)


function apt.onEnable()
    ai.onEnable(apt)
end
function apt.onDisable()
    ai.onDisable(apt)
end

function apt.onTick()
    ai.onTick(apt)
end
function apt.onTickEnd()
    ai.onTickEnd(apt)
end
function apt.onDraw()
    ai.onDraw(apt)
end


return apt