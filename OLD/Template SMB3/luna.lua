--------------------------------------------------
-- Level code
-- Created 8:36 2021-9-17
--------------------------------------------------

-- Run code on level start
function onStart()
	Player.setCostume(CHARACTER_MARIO, "SMB3 Mario", true)
	player.powerup = PLAYER_SMALL;
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
	player.reservePowerup = 0
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

function onInputUpdate()
if player.altJumpKeyPressing then
player.altJumpKeyPressing = false
player.jumpKeyPressing = true
end
end

