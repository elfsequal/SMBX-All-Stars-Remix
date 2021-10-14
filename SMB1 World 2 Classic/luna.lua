--------------------------------------------------
-- Level code
-- Created 8:36 2021-9-17
--------------------------------------------------
require("libs/retroStuff")
-- Run code on level start
function onStart()
	Player.setCostume(CHARACTER_MARIO, "SMB1 Mario", true)
	player.powerup = PLAYER_SMALL;
	player.mount = MOUNT_NONE;
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
	--player.reservePowerup = 0
end

function onTickEnd()
	player.reservePowerup = 0
end
-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
	if(eventName == "BowserDeath") then
		--Audio.MusicChange(player.section, "silence")
		Audio.playSFX("audio/music/SMB1 Classic Boss Fanfare.ogg")
	end
end

function onInputUpdate()
if player.altJumpKeyPressing then
player.altJumpKeyPressing = false
player.jumpKeyPressing = true
end
end

