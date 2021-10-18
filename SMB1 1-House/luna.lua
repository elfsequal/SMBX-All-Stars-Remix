require("libs/globalStuff")

local tbox = textbox.New{
	text = "<voice climbing>Pick a box. <new>Its contents will help you on your way.",
	x = 280,
	y = 280,
	pause = false,
	playerControlled = false
}

-- I could set the textbox's draw mode to "auto" which would make the library draw it automatically:
tbox:SetDrawMode("auto")