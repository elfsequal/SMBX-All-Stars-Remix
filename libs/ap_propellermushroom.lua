

local apt = {}

-- Variable "name" is reserved
-- variable "registerItems" is reserved

apt.spritesheets = {
    Graphics.loadImage(Misc.resolveFile("mario-ap-propeller.png")), --Mario
    Graphics.sprites.luigi[7].img, --Luigi
    Graphics.sprites.peach[7].img, --Peach
    Graphics.sprites.toad[7].img, --Toad
}

apt.apSounds = {
    upgrade = 6,
    reserve = 12
}

apt.items = {980} -- Items that can be collected

--------------------
apt.projectileTimer = 0
apt.projectileTimerMax = {
    30,
    35,
    40,
    25,
    25
}
--------------------

local animFrames = {
    11,11,11,11,12,12,12,12,
}

-- Runs when player switches to this powerup. Use for setting stuff like global Defines.
function apt.onEnable()

end

-- Runs when player switches to this powerup. Use for resetting stuff from onEnable.
function apt.onDisable()

end


-- No need to register. Runs only when powerup is active.
function apt.onTickEnd()
    --Your code here
    if player.keys.altJump == KEYS_PRESSED then
        Defines.jumpheight = 55
        Defines.gravity = 3
        return
    end
        if player.keys.altJump ==  KEYS_UNPRESSED then
Defines.jumpheight = 20
Defines.gravity = 12
end
end

function apt.onTick()
    --Your code here
    if player.keys.altJump == KEYS_PRESSED then
        Defines.jumpheight = 55
        Defines.gravity = 3
        return
    end
        if player.keys.altJump ==  KEYS_UNPRESSED then
Defines.jumpheight = 20
Defines.gravity = 12
end
end

-- No need to register. Runs only when powerup is active.
function apt.onDraw()
end

return apt