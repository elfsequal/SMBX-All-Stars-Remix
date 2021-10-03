--[[
   _____          _                      _            _   _                                 _       _   
  / ____|        | |                    | |          | | | |                               (_)     | |  
 | |    _   _ ___| |_ ___  _ __ ___     | |_ _____  _| |_| |__   _____  __    ___  ___ _ __ _ _ __ | |_ 
 | |   | | | / __| __/ _ \| '_ ` _ \    | __/ _ \ \/ / __| '_ \ / _ \ \/ /   / __|/ __| '__| | '_ \| __|
 | |___| |_| \__ \ || (_) | | | | | |   | ||  __/>  <| |_| |_) | (_) >  <    \__ \ (__| |  | | |_) | |_ 
  \_____\__,_|___/\__\___/|_| |_| |_|    \__\___/_/\_\\__|_.__/ \___/_/\_\   |___/\___|_|  | | .__/ \__|
                                                 _              ___  _   _      _____      | |        
                                                | |            / _ \| | | |    / ____|     |_|        
                                                | |__  _   _  | (_) | |_| |__ | |     ___  _ __ ___ 
                                                | '_ \| | | |  \__, | __| '_ \| |    / _ \| '__/ _ \
                                                | |_) | |_| |    / /| |_| | | | |___| (_) | | |  __/
                                                |_.__/ \__, |   /_/  \__|_| |_|\_____\___/|_|  \___|
                                                        __/ |                                       
                                                       |___/                                        

		You can use this in your own stuff, but please give credit.
		Not only to me, but also to these people!

		CREDITS--CREDITS--CREDITS--CREDITS--CREDITS--CREDITS--CREDITS-
		
			- Rednaxela on the Codehaus server for the custom tag system, a much neater rendering system and the idea of using metatables for the textboxes!
				- Please do give credit to this person they helped me so much with this project i cant even put it into words
			- The Codehaus server and the SMBX servers as a whole, actually, for helping me when I ask questions

		END-OF-CREDITS--END-OF-CREDITS--END-OF-CREDITS--END-OF-CREDITS

		When you want to create a textbox, you can have these named arguments:
			- text: the text to display. A string. NECESSARY

			- x: the x position. A number. NECESSARY

			- y: the y position. A number. NECESSARY

			- font: the path to the font's ini file. A string.
				- If not given, it simply uses the default font.

			- pause: if true, the game will be paused while the message is being displayed. A boolean.
				- Defaults to false.

			- completeDestroyUponFinish: if true, the textbox will get :CompleteDestroy()'d when it finishes, which means that you can't call any more functions using it. It's basically useless. A boolean.
				- Defaults to false, though it is set to true for message boxes (1.3 kind).

			- progressWhileNotDrawn: if true, the textbox will progress while not drawn. This also means it can be closed if it finishes even if it's not drawn. A boolean.
				- Defaults to false.

			- progressWhilePaused: if true, the textbox will progress while the game is paused. If not provided and pause is set to true, this is also set to true. Otherwise, false. A boolean.

			- sceneCoords: if true, will use scene coordinates instead of camera coordinates. A boolean.
				- What this means is that if you want the message to appear above an NPC or a player, set it to true and you can use [thing].y or [thing].x in x and y.
				- If this is false, it will use camera coords instead, which means that 0,0 will be at the top-left of your screen and 800x600.
				- Defaults to false.

			- clampInCamera: if true, the textbox will clamp itself so it doesn't go outside of the camera. Automatically set to true for Message Boxes. (the 1.3 ones) A boolean.
				- Defaults to false for code-created textboxes.

			- playerControlled: if true, the game will wait for the player's input to progress the textbox. A boolean.
				- Defaults to false.

			- lifetime: if playerControlled is false, this affects how much the game waits until removing the textbox. A number.

			- textColor: The color of the text.
				- Defaults to Color.white.

			- nameColor: The color of the name.
				- Defaults to Color.white.

			- boxColor: The color of the box.
				- If not given, it uses self.boxColor.

			- xscale: The horizontal scale of the text. A number.
				- Defaults to 2.

			- yscale: Same as xscale, but for vertical scale.

			- maxWidth: The width of the box.
				- Defaults to self.boxWidth.

			- padding: A table containing padding information!
				- Each argument usable is:
					- up: How many pixels should there be between the top of the textbox and the text? Defaults to 0.
					- down: How many pixels should there be between the bottom of the textbox and the text? Defaults to 0.
					- left : Same as up or down, but for the left of the textbox. Defaults to 0.
					- right : For the right. Defaults to 0.

				- Note: None of them can go lower than 0 but, other than that, they aren't clamped.
						This means that you can totally set them to be higher than the total width/height and they'll screw	over the whole rendering.
						But I'm simply providing the tools to do it so I will not be preventing this.
						Make of this what you will.


		In a textbox's message you can use these custom tags:

			- new: useful if you want to split a textbox into multiple messages.
				Usage: text 1<new>text 2<new>text 3
				Note: the name resets between <new>s so you have to set it again!
					name: my name<new>name: is<new>name: name!!

			- wait: when this tag is reached, it waits for the amount of ticks specified before continuing to the next letter.
				Usage: <wait 4>

			- speed: when this tag is reached, sets the amount of ticks to wait between letters.
				Usage: <speed 1>

			- sound: when this tag is reached, a sound is played.
				Usage: <sound 13>
				    or <sound bumper>

			- instant: when this tag is reached, the full text is instantly shown.
			- has an argument; if it's false, it doesn't run tags after it. if true it does.
				Usage: <instant false>
				    or <instant true>

			- stopinstant: stops any <instant> tags that were before used.
				Usage: <stopinstant>

			- skip: allows or disallows the player to skip the text.
			- false disallows it, true allows it.
				Usage: <skip false>
				    or <skip true>

			- next: continues to the next message in the queue if there is one (see: <new> tag) or closes the textbox.
				Usage: <next>

			- voice: sets the voice for the message.
				Usage: <voice sound>
				    or <voice sound1 sound2 sound3 ...> ! You can use multiple sounds and the library will randomize them automatically!

			- func: possibly the most powerful of all the tags. when it's reached, a function is called.
				Usage: <func myFunc>
				Note: You have to register it using registerFunction for it to be usable! Check the example level provided with the library.


		Additionally, if you want to check if a textbox is done, you can use [variable].done .
		If it's true, the textbox is done and you can stop drawing it. If it's false, the textbox is not done yet.
		If a textbox is done, it also gets removed from the allTextboxes table so input won't work on it anymore.
		If you wish to re-start a textbox you can call [variable]:Restart() which will take care of it.			

]]

textbox = {}

local textplus = require("textplus")

local defaultFont = textplus.loadFont("textplus/font/3.ini") -- Replace this with the path to your default font that will be used if there's no font specified.

local allTexts = {}

local pauseQueued = false
local oteh = false --onTickEndHappened

-- SETTINGS HERE!

-- The amount of ticks between each letter. Resets to this when a new textbox is created.
textbox.defaultCharacterTicks = 3

-- If set to true, skipping a textbox causes it to run the tags it skipped over.
textbox.skipRunsTags = false

-- How wide is the message box? Also affects the text's wrapping.
-- It's best not to set it higher than the camera's width.
textbox.boxWidth = 250

-- Replace this with another color if you want a differently-colored box.
-- Only applies for newly-created textboxes if you don't assign boxColor inside of the arguments.
-- Color.black is the color, and .. 0.5 is the opacity; higher the value, the more opaque, and thus less see-through it is.
-- At opacity 1, its completely opaque, and at opacity 0, it's completely invisible.
textbox.boxColor = Color.black .. 0.5

-- The properties the talk message should use.
-- These are the same properties you can assign a textbox you create yourself. (They're documented above)
-- You don't need to specify the text, x, y, sceneCoords or clampInCamera properties as those are set by default.
textbox.talkMessageProperties = {
	pause = true,
	playerControlled = true,
	padding = {
		up = 0,
		down = 0,
		left = 0,
		right = 0
	}
}

-- SETTINGS END.

-- Custom tags
local customTags = {}

-- Imma be honest I have no idea how this tag does what it does but /shrug
-- Thanks Rednaxela!
function customTags.wait(fmt, out, args)

    out[#out+1] = {
    	wait=tonumber(args[1]),
    	fmt=fmt
    }

    return fmt

end

function customTags.sound(fmt, out, args)

	local s

	if not tonumber(args[1]) then s = Misc.resolveSoundFile(args[1])
	else s = tonumber(args[1])
	end

    out[#out+1] = {
    	sound=s,
    	fmt=fmt
    }

    return fmt

end

function customTags.func(fmt, out, args)

    out[#out+1] = {
    	func=args[1],
    	fmt=fmt
    }

    return fmt

end

function customTags.skip(fmt, out, args)

	local bool = args[1] or "true"
	bool = bool == "true"

    out[#out+1] = {
    	skippable=bool,
    	fmt=fmt
    }

    return fmt

end

function customTags.speed(fmt, out, args)

    out[#out+1] = {
    	speed=tonumber(args[1]),
    	fmt=fmt
    }

    return fmt

end

function customTags.instant(fmt, out, args)

	local bool = false

	if tostring(args[1]) == "true" then bool = true
	end

    out[#out+1] = {
    	instant=bool,
    	fmt=fmt
    }

    return fmt

end

function customTags.stopinstant(fmt, out, args)

    out[#out+1] = {
    	stopinstant=true,
    	fmt=fmt
    }

    return fmt

end

function customTags.next(fmt, out, args)

    out[#out+1] = {
    	next=true,
    	fmt=fmt
    }

    return fmt

end

function customTags.voice(fmt, out, args)

	for _,s in pairs(args) do

		if not tonumber(s) then s = Misc.resolveSoundFile(s)
		else s = tonumber(s)
		end

		args[_] = s

	end

    out[#out+1] = {
    	voice=args,
    	fmt=fmt
    }

    return fmt

end

local selfEndingTags = {"wait", "sound", "func", "speed", "instant", "stopinstant", "next", "voice", "skip"}

function textbox.onInitAPI()
	
	registerEvent(textbox, "onTickEnd")
	registerEvent(textbox, "onInputUpdate")
	registerEvent(textbox, "onDraw")
	registerEvent(textbox, "onMessageBox")

end

-- Stores all the textboxes that have their draw method set to "auto" so they can be drawn by the library.
local textboxList = {}

-- Stores all the textboxes created. Used for input.
local allTextboxes = {}

-- Textbox class (thanks Rednaxela again!)
local Textbox = {}
local TextboxMT = {
	__index = Textbox,
	__type = "CustomTextbox"
}
textbox.Textbox = Textbox

local function CheckForNil(var, default)
	if var == nil then return default end
	return var
end

-- This gets the name, if there is any.
local function GetName(text)

	-- Returns the name and the text
	local nameLastIndex

	for i=1,text:len()-1 do

		local char = text:sub(i,i)

		if char == ":" and text:sub(i+1,i+1) == " " then

			text = text:sub(1,i)..text:sub(i+2,text:len())

			nameLastIndex = i-1

			break

		end

	end

	if nameLastIndex then return text:sub(1,nameLastIndex), text:sub(nameLastIndex+2,text:len()) end

	return nil, text -- We just return nil if nothing was found

end

local function SearchForFirstNewTag(text)

	local i, j = text:find("<new>")

	if i then return text:sub(1, i-1), text:sub(j+1, text:len())
	else return text
	end

end

local allFuncs = {}

function textbox.registerFunction(func, name)

	-- Puts it into the table so the game knows which functions have been registered and which not
	allFuncs[name] = func

end

local function newtextbox(args)

	local obj = {}

	if not args.text then error("You need to set the text!") end
	if not args.x then error("You need to set the x position!") end
	if not args.y then error("You need to set the y position!") end

	args.x, args.y = math.floor(args.x), math.floor(args.y)

	args.text,args.nextText = SearchForFirstNewTag(args.text)

	local name, text = GetName(args.text)

	args.name = name
	args.text = text

	args.maxWidth = CheckForNil(args.maxWidth,textbox.boxWidth)
	args.font = CheckForNil(args.font,defaultFont)

	args.completeDestroyUponFinish = CheckForNil(completeDestroyUponFinish, false)

	args.pause = CheckForNil(args.pause,false)

	args.playerControlled = CheckForNil(args.playerControlled,false)
	args.lifetime = CheckForNil(args.lifetime, 65)

	args.progressWhilePaused = CheckForNil(args.progressWhilePaused,args.pause)
	args.progressWhileNotDrawn = CheckForNil(args.progressWhileNotDrawn,false)

	args.sceneCoords = CheckForNil(args.sceneCoords,false)

	args.clampInCamera = CheckForNil(args.clampInCamera, false)

	args.boxColor = CheckForNil(args.boxColor,textbox.boxColor)
	args.textColor = CheckForNil(args.textColor,Color.white)
	args.nameColor = CheckForNil(args.nameColor,Color.white)

	args.xscale = CheckForNil(args.xscale,2)
	args.yscale = CheckForNil(args.yscale,2)

	args.padding = CheckForNil(args.padding,{})
	args.padding.left = CheckForNil(args.padding.left,0)
	args.padding.right = CheckForNil(args.padding.right,0)
	args.padding.down = CheckForNil(args.padding.down,0)
	args.padding.up = CheckForNil(args.padding.up,0)

	args.padding.left = math.max(math.floor(args.padding.left),0)
	args.padding.right = math.max(math.floor(args.padding.right),0)
	args.padding.up = math.max(math.floor(args.padding.up),0)
	args.padding.down = math.max(math.floor(args.padding.down),0)

	obj.args = args

	obj.text = textplus.parse(
		args.text,
		args,
		customTags,
		selfEndingTags
	)
	obj.layout = textplus.layout(obj.text, args.maxWidth - args.padding.right - args.padding.left)

	if args.name then

		obj.name = textplus.parse(
			args.name,
			args
		)

		obj.nameLayout = textplus.layout(obj.name, args.maxWidth - 50)

	end

	if args.clampInCamera then

		local xLeft,xRight,yUp,yDown = 0,camera.width,0,camera.height

		if args.sceneCoords then xLeft,xRight,yUp,yDown = camera.x,camera.x+camera.width,camera.y,camera.y+camera.height end

		yUp = yUp + obj.layout.height/2

		if args.name then yUp = yUp + obj.nameLayout.height - args.font.cellHeight*args.yscale/2 end

		args.x = math.min(math.max(args.x, xLeft), xRight-obj.layout.width-args.padding.left-args.padding.right)
		args.y = math.min(math.max(args.y, yUp), yDown-obj.layout.height-args.padding.up-args.padding.down)

	end

	obj.delay = textbox.defaultCharacterTicks
	obj.timer = textbox.defaultCharacterTicks
	obj.skipInvulTime = 2 -- for 2 ticks you can't skip.
	obj.lastTick = nil
	obj.limit = 0
	obj.done = false
	obj.deathTimer = 0
	obj.voice = nil -- If nil we don't play a voice
	obj.skippingUsingInstant = false
	obj.instantRunTags = false
	obj.skippable = true

	obj.iter = obj.layout:iter()

	if args.pause then if not oteh then pauseQueued = true else Misc.pause() end end

	return setmetatable(obj, TextboxMT)

end

function textbox.New(args)
	
	local txt = newtextbox(args)

	table.insert(allTextboxes,txt)

	txt.tblIdx = #allTextboxes -- We set it to the length of the table since we just insert it at the end

	return txt

end

-- This function reparses the text.
function Textbox:ParseText()

	self.text = textplus.parse(self.args.text, self.args, customTags, selfEndingTags)
	self.layout = textplus.layout(self.text, self.args.maxWidth - self.args.padding.right - self.args.padding.left)

	if self.args.clampInCamera then

		local xLeft,xRight,yUp,yDown = 0,camera.width,0,camera.height

		if self.args.sceneCoords then xLeft,xRight,yUp,yDown = camera.x,camera.x+camera.width,camera.y,camera.y+camera.height end

		yUp = yUp + self.layout.height/2

		if self.args.name then yUp = yUp + self.nameLayout.height - self.args.font.cellHeight*self.args.yscale/2 end

		self.args.x = math.min(math.max(self.args.x, xLeft), xRight-self.layout.width-self.args.padding.left-self.args.padding.right)
		self.args.y = math.min(math.max(self.args.y, yUp), yDown-self.layout.height-self.args.padding.up-self.args.padding.down)

	end

	self.iter = self.layout:iter()

end

-- Restarts the textbox
function Textbox:Restart()

	self.done = false
	table.insert(allTextboxes, self)
	self.tblIdx = #allTextboxes

	-- We reset the variables as well as reparse name and text

	self:ParseText()
	self:ParseName()

	self:ResetVariables()

end

-- Resets variables
function Textbox:ResetVariables()

	self.delay = textbox.defaultCharacterTicks
	self.timer = textbox.defaultCharacterTicks
	self.skipInvulTime = 2
	self.deathTimer = 0
	self.lastTick = nil
	self.limit = 1
	self.voice = nil
	self.skippingUsingInstant = false
	self.skippable = true
	self.instantRunTags = false

end

-- This function reparses the name.
function Textbox:ParseName()

	local name, text = GetName(self.args.text)

	self.args.name = name
	self.args.text = text

	if self.args.name then

		self.name = textplus.parse(self.args.name, self.args)
		self.nameLayout = textplus.layout(self.name, self.args.maxWidth - 50)

	end

end

-- Slight misnomer, affects whether the textbox is drawn by the library or by the user
-- if set to "manual" the drawing is made by the user
-- if set to anything else it's made by the library
function Textbox:SetDrawMode(mode)

	mode = mode or "manual"

	if mode == "manual" then textboxList[self] = nil
	else textboxList[self] = true
	end

end

local function InstantAllowsIt(instantActive,instantRunsTags)
	if instantActive then if instantRunsTags then return true end
	else return true end
	return false
end

function Textbox:Draw()

	self.skipInvulTime = self.skipInvulTime - 1

	if not self.lastTick then
		self.lastTick = LunaTime.tick()
	end

	if self.args.progressWhilePaused == Misc.isPaused() then self.timer = self.timer - 1 end

	-- If the textbox was not drawn for some time
	if LunaTime.tick() - self.lastTick > 1 and self.args.progressWhileNotDrawn then self.timer = self.timer - (LunaTime.tick() - self.lastTick) end

	while self.limit and self.timer <= 0 do

		local idx, code = self.iter()
		self.limit = idx
		
		if code == nil then
			-- End of iteration!
			-- No need to do anything, we'll be setting self.limit to nil
			self.timer = 0

		elseif type(code) == "number" then
			-- It's a character code
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end

		elseif (code.img ~= nil) then
			-- It's an image tag
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end

		elseif (code.wait ~= nil) then
			-- It's a wait tag so we add the delay to our timer
			if not self.skippingUsingInstant then self.timer = self.timer + code.wait end

		elseif (code.speed ~= nil) then
			-- It's a speed tag
			if not self.skippingUsingInstant then self.timer = self.timer + code.speed end

			if InstantAllowsIt(self.skippingUsingInstant,self.instantRunTags) then self.delay = code.speed end

		elseif (code.sound ~= nil) then
			-- It's a sound tag so we play a sound
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end

			if InstantAllowsIt(self.skippingUsingInstant,self.instantRunTags) then SFX.play(code.sound) end

		elseif (code.func ~= nil) then
			-- It's a func tag
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end

			if InstantAllowsIt(self.skippingUsingInstant,self.instantRunTags) then
				if allFuncs[code.func] then allFuncs[code.func]()
				else error("\nYou tried to use a function but didn't register it first!\nUse registerFunction to do that.\n\nExample of how to use it provided in the example level.\n\n")
				end
			end

		elseif (code.instant ~= nil) then
			-- It's an instant tag

			self.instantRunTags = code.instant
			self.skippingUsingInstant = true

		elseif (code.skippable ~= nil) then
			-- It's a skip tag
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end

			self.skippable = code.skippable

		elseif (code.stopinstant ~= nil) then
			-- It's a stopinstant tag

			if self.skippingUsingInstant then 
				self.skippingUsingInstant = false
			end

		elseif (code.next ~= nil) then
			-- It's a next tag
			self:Next()
			return -- We exit out of this function to avoid any errors!

		elseif (code.voice ~= nil) then
			-- It's a voice tag so we set the voice
			if not self.skippingUsingInstant then self.timer = self.timer + self.delay end
			if InstantAllowsIt(self.skippingUsingInstant,self.instantRunTags) then self.voice = code.voice end

		end

		if code and self.voice then
			local voice = self.voice[math.random(1,#self.voice)]

			SFX.play{
				sound = voice,
				volume = 1/3
			}

		end

	end

	-- If the player doesn't control the textbox
	if not self.args.playerControlled then

		-- and we reached the end of the textbox
		if not self.limit then

			-- Increment the deathTimer by 1
			if not Defines.levelFreeze then self.deathTimer = self.deathTimer + 1 end

			-- If it reaches lifetime, we go either to the next message or destroy the textbox
			if self.deathTimer >= self.args.lifetime then

				self.deathTimer = 0

				if self.args.nextText then

					self.args.text = self.args.nextText

					self.args.text,self.args.nextText = SearchForFirstNewTag(self.args.text)

					self:ParseName()

					self:ParseText()

					self:ResetVariables()

				else
					self:Destroy()
					return

				end

			end

		end

	end

	self.lastTick = LunaTime.tick()

	local x = self.args.x + self.args.padding.left
	local y = self.args.y + self.args.padding.up

	textplus.render{
		x = x,
		y = y,
		layout = self.layout,
		limit = self.limit,
		sceneCoords = self.args.sceneCoords,
		color = self.args.textColor
	}

	if self.args.name then

		textplus.render{
			x = self.args.x + self.args.maxWidth/2 - self.nameLayout.width/2,
			y = self.args.y - self.nameLayout.height,
			layout = self.nameLayout,
			sceneCoords = self.args.sceneCoords,
			color = self.args.nameColor
		}

		local xText, yText = self.args.x, self.args.y - self.args.font.cellHeight*self.args.yscale/2
		local nameX,nameY = self.args.x + self.args.maxWidth/2 - self.nameLayout.width/2, self.args.y - self.nameLayout.height - self.args.font.cellHeight*self.args.yscale/2

		Graphics.glDraw{
			primitive = Graphics.GL_TRIANGLE_STRIP,
			vertexCoords = {
				nameX, nameY,
				nameX + self.nameLayout.width, nameY,
				nameX, nameY + self.nameLayout.height,
				nameX + self.nameLayout.width, nameY + self.nameLayout.height,
				xText, yText,
				xText + self.args.maxWidth, yText,
				xText, yText + self.args.padding.up + self.args.padding.down + self.layout.height,
				xText + self.args.maxWidth, yText + self.args.padding.up + self.args.padding.down + self.layout.height
			},
			color = self.args.boxColor,
			sceneCoords = self.args.sceneCoords,
			priority = -1
		}

	else

		local magicFormula = self.args.font.cellHeight*self.args.yscale/2

		Graphics.glDraw{
			primitive = Graphics.GL_TRIANGLE_STRIP,
			vertexCoords = {
				self.args.x, self.args.y - magicFormula,
				self.args.x + self.args.maxWidth, self.args.y - magicFormula,
				self.args.x, self.args.y + self.args.padding.down + self.args.padding.up + self.layout.height - magicFormula,
				self.args.x + self.args.maxWidth, self.args.y + self.args.padding.down + self.args.padding.up + self.layout.height - magicFormula
			},
			color = self.args.boxColor,
			sceneCoords = self.args.sceneCoords,
			priority = -1
		}

	end

end

-- If this is called, the textbox is skipped.
function Textbox:Finish()

	self.delay = 0

	if not textbox.skipRunsTags then self.limit = nil end

end

-- Progresses to the next text in queue if there is one.
-- If there isn't it closes the textbox.
function Textbox:Next()

	-- If we have a <new> tag, we need to continue to the next message.
	if self.args.nextText then

		self.args.text = self.args.nextText

		self.args.text,self.args.nextText = SearchForFirstNewTag(self.args.text)

		self:ParseName()

		self:ParseText()

		self:ResetVariables()

	else -- If we don't we destroy the textbox

		if self.args.completeDestroyUponFinish then self:CompleteDestroy() else self:Destroy() end

	end

end

-- Destroy the textbox.
-- You can call :Restart to make it work again.
function Textbox:Destroy()

	allTextboxes[self.tblIdx] = nil -- Remove the textbox from allTextboxes

	if self.args.pause then Misc.unpause() end

	self.done = true

	self.tblIdx = nil

end

-- Destroys the textbox completely.
-- After you do this, it's recommended to set your textbox variable to nil as well and let the lua garbage collector take care of the rest.
function Textbox:CompleteDestroy()

	self:Destroy()

	setmetatable(self, nil)

end

function textbox.onTickEnd()

	oteh = true

	if pauseQueued then
		Misc.pause()
		pauseQueued = false

	end

end

function textbox.onDraw()

	for t,_ in pairs(textboxList) do

		if not t.done then t:Draw() end

	end

end

local function InputCheck()

	for _,v in pairs(player.keys) do
		if v == KEYS_PRESSED then return true end
	end

	return false

end

function textbox.onInputUpdate()

	if InputCheck() then

		for _,t in pairs(allTextboxes) do

			if t.args.playerControlled and t.skipInvulTime <= 0 then

				-- The textbox hasn't finished yet
				if t.limit and t.skippable then

					t:Finish()

				elseif not t.limit then -- The textbox has finished

					t:Next()

				end

			end

		end

	end

end

function textbox.onMessageBox(eventToken, content, plr, NPC)

	eventToken.cancelled = true

	local x, y = 320 - textbox.boxWidth/4, 80
	local tbl = {}

	if NPC then
		x = NPC.x + NPC.width/2 - textbox.boxWidth/2
		y = NPC.y - 50
		tbl.sceneCoords = true

	end

	
	tbl.text = content
	tbl.x = x
	tbl.y = y
	tbl.clampInCamera = true

	for k,v in pairs(textbox.talkMessageProperties) do if not tbl[k] then tbl[k] = v end end

	local obj = textbox.New(tbl)

	obj:SetDrawMode("auto")

end

return textbox