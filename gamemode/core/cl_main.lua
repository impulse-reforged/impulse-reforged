--- A generic module that holds anything that doesnt fit elsewhere
-- @module impulse.Util

function GM:ForceDermaSkin()
	return "impulse"
end

local blur = Material("pp/blurscreen")

local superTesters = {
	["STEAM_0:1:53542485"] = true, -- mats
	["STEAM_0:1:75156459"] = true, -- jamsu
	["STEAM_0:1:83204982"] = true, -- oscar
	["STEAM_0:1:43061896"] = true, -- jim wakelin
	["STEAM_0:0:24607430"] = true, -- stranger
	["STEAM_0:0:26121174"] = true, -- greasy
	["STEAM_0:1:40283833"] = true, -- tim cook
	["STEAM_0:0:157214263"] = true, -- loka
	["STEAM_0:0:73384910"] = true, -- avx/soviet
	["STEAM_0:1:175014750"] = true -- personwhoplaysgames
}

local mappers = {
	["STEAM_0:0:24607430"] = true -- stranger
}

local eventTeam = {
	["STEAM_0:1:462578059"] = true -- opiper
}

local winners = {}


-- Please don't ever remove credit or users/badges from this section. People worked hard on this. Thanks!
impulse.Badges = {
	staff = {Material("icon16/shield.png"), "This player is a staff member.", function(ply) return not ply:IsIncognito() and ply:IsAdmin() end},
	donator = {Material("icon16/coins.png"), "This player is a donator.", function(ply) return ply:IsDonator() end},
	exdev = {Material("icon16/cog_go.png"), "This player is a ex impulse developer.", function(ply) return ply:SteamID() == "STEAM_0:1:102639297" end},
	dev = {Material("icon16/cog.png"), "This player is a impulse developer.", function(ply) return not ply:IsIncognito() and ply:IsDeveloper() end},
	vin = {Material("impulse-reforged/vin.png"), "Hi, it's me vin! The creator of impulse.", function(ply) return not ply:IsIncognito() and (ply:SteamID() == "STEAM_0:1:95921723") end},
	supertester = {Material("icon16/bug.png"), "This player made large contributions to the testing of impulse.", function(ply) return (superTesters[ply:SteamID()] or false) end},
	competition = {Material("icon16/rosette.png"), "This player has won a competition.", function(ply) return winners[ply:SteamID()] end},
	mapper = {Material("icon16/map.png"), "This player is a mapper that has collaborated with impulse.", function(ply) return mappers[ply:SteamID()] end},
	eventteam = {Material("icon16/controller.png"), "This player is the leader of the event team.", function(ply) return eventTeam[ply:SteamID()] end},
	communitymanager = {Material("icon16/transmit.png"), "This player is a community manager. Feel free to ask them questions.", function(ply) return ply:GetUserGroup() == "communitymanager" end}
}

impulse.blurRenderQueue = {}

local blur = Material("pp/blurscreen")
local surface = surface
local render = render

--- Blurs the content underneath the given panel. This will fall back to a simple darkened rectangle if the player has
-- blurring disabled.
-- @realm client
-- @tparam panel panel Panel to draw the blur for
-- @number[opt=5] amount Intensity of the blur. This should be kept between 0 and 10 for performance reasons
-- @number[opt=0.2] passes Quality of the blur. This should be kept as default
-- @number[opt=255] alpha Opacity of the blur
-- @usage function PANEL:Paint(width, height)
--     impulse:DrawBlur(self)
-- end
function impulse:DrawBlur(panel, amount, passes, alpha)
	amount = amount or 5

	if (!impulse.Settings:Get("perf_blur")) then
		surface.SetDrawColor(50, 50, 50, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(255, 255, 255, alpha or 255)

		local x, y = panel:LocalToScreen(0, 0)

		for i = -(passes or 0.2), 1, 0.2 do
			-- Do things to the blur material to make it blurry.
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			-- Draw the blur material over the screen.
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end
end

--- Draws a blurred rectangle with the given position and bounds. This shouldn't be used for panels, see `impulse:DrawBlur`
-- instead.
-- @realm client
-- @number x X-position of the rectangle
-- @number y Y-position of the rectangle
-- @number width Width of the rectangle
-- @number height Height of the rectangle
-- @number[opt=5] amount Intensity of the blur. This should be kept between 0 and 10 for performance reasons
-- @number[opt=0.2] passes Quality of the blur. This should be kept as default
-- @number[opt=255] alpha Opacity of the blur
-- @usage hook.Add("HUDPaint", "MyHUDPaint", function()
--     impulse:DrawBlurAt(0, 0, ScrW(), ScrH())
-- end)
function impulse:DrawBlurAt(x, y, width, height, amount, passes, alpha)
	amount = amount or 5

	if (!impulse.Settings:Get("perf_blur")) then
		surface.SetDrawColor(30, 30, 30, amount * 20)
		surface.DrawRect(x, y, width, height)
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(255, 255, 255, alpha or 255)

		local scrW, scrH = ScrW(), ScrH()
		local x2, y2 = x / scrW, y / scrH
		local w2, h2 = (x + width) / scrW, (y + height) / scrH

		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRectUV(x, y, width, height, x2, y2, w2, h2)
		end
	end
end

--- Pushes a 3D2D blur to be rendered in the world. The draw function will be called next frame in the
-- `PostDrawOpaqueRenderables` hook.
-- @realm client
-- @func drawFunc Function to call when it needs to be drawn
function impulse:PushBlur(drawFunc)
	self.blurRenderQueue[#self.blurRenderQueue + 1] = drawFunc
end

--- Wraps text so it does not pass a certain width. This function will try and break lines between words if it can,
-- otherwise it will break a word if it's too long.
-- @realm client
-- @string text Text to wrap
-- @number maxWidth Maximum allowed width in pixels
-- @string[opt="Impulse-Elements19-Shadow"] font Font to use for the text
function impulse:WrapText(text, maxWidth, font)
	font = font or "Impulse-Elements19-Shadow"
	surface.SetFont(font)

	local words = string.Explode("%s", text, true)
	local lines = {}
	local line = ""
	local lineWidth = 0 -- luacheck: ignore 231

	-- we don't need to calculate wrapping if we're under the max width
	if (surface.GetTextSize(text) <= maxWidth) then
		return {text}
	end

	for i = 1, #words do
		local word = words[i]
		local wordWidth = surface.GetTextSize(word)

		-- this word is very long so we have to split it by character
		if (wordWidth > maxWidth) then
			local newWidth

			for i2 = 1, word:utf8len() do
				local character = word[i2]
				newWidth = surface.GetTextSize(line .. character)

				-- if current line + next character is too wide, we'll shove the next character onto the next line
				if (newWidth > maxWidth) then
					lines[#lines + 1] = line
					line = ""
				end

				line = line .. character
			end

			lineWidth = newWidth
			continue
		end

		local space = (i == 1) and "" or " "
		local newLine = line .. space .. word
		local newWidth = surface.GetTextSize(newLine)

		if (newWidth > maxWidth) then
			-- adding this word will bring us over the max width
			lines[#lines + 1] = line

			line = word
			lineWidth = wordWidth
		else
			-- otherwise we tack on the new word and continue
			line = newLine
			lineWidth = newWidth
		end
	end

	if (line != "") then
		lines[#lines + 1] = line
	end

	return lines
end

--- Creates a work bar on the players screen
-- @realm client
-- @int time The time it will take to complete the bar
-- @string[opt] text Text to display on the bar
-- @func[opt] onDone Called when bar is complete
-- @bool[opt=false] popup If the bar should stop player input
function impulse:MakeWorkbar(time, text, onDone, popup)
	if ( IsValid(impulse.WorkbarPanel) ) then
		impulse.WorkbarPanel:Remove()
	end

	if not ( time ) then
		return
	end

	local bar = vgui.Create("impulseWorkbar")
	bar:SetEndTime(CurTime() + time)

	if text then
		bar:SetText(text)
	end

	if onDone then
		bar.OnEnd = onDone
	end

	if popup then
		bar:MakePopup()
	end
end

function impulse.Util:PlayGesture(ply, gesture, slot)
    if ( !ply ) then ply = LocalPlayer() end
	if ( !IsValid(ply) ) then return end

    if ( !slot ) then slot = GESTURE_SLOT_CUSTOM end

    ply:AddVCDSequenceToGestureSlot(slot, ply:LookupSequence(gesture), 0, 1)
end

local baseWidth, baseHeight = 1280, 720
local targetWidth, targetHeight = 3840, 2160

--- @realm client
function impulse:DynamicScaleFontSize(baseSize)
    local screenWidth, screenHeight = ScrW(), ScrH()
    local baseScale = baseHeight / screenHeight
    local targetScale = targetHeight / baseHeight

    local scaleFactor = Lerp(math.Clamp((screenHeight - baseHeight) / (targetHeight - baseHeight), 0, 1), baseScale, targetScale)

    return math.Round(baseSize * scaleFactor * impulse.Settings:Get("font_scale"))
end

local myscrw, myscrh = 1920, 1080

function SizeW(width)
	local screenwidth = myscrw
	return width*ScrW()/screenwidth
end

function SizeH(height)
	local screenheight = myscrh
	return height*ScrH()/screenheight
end

function SizeWH(width, height)
	local screenwidth = myscrw
	local screenheight = myscrh
	return width*ScrW()/screenwidth, height*ScrH()/screenheight
end

function HexColor(hex, alpha)
	hex = hex:gsub("#","")
	return Color (tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), alpha or 255)
end

local uColoursBase = {
	HexColor("#ff0000"),
	HexColor("#ff8c00"),
	HexColor("#00ff7f"),
	HexColor("#ff1493"),
	HexColor("#1e90ff"),
	HexColor("#adff2f"),
	HexColor("#eee8aa"),
	HexColor("#87cefa"),
	HexColor("#dda0dd"),
	HexColor("#ffd700"),
	HexColor("#808000"),
	HexColor("#2e8b57"),
	HexColor("#ba55d3"),
	HexColor("#000080"),
	HexColor("#b22222"),
	HexColor("#2e8b57"),
	HexColor("#696969"),
	HexColor("#e9967a")
}

local uColoursUsed = {}
local uColoursLive = {}
function impulse:GetUniqueColour(hash)
	if uColoursLive[hash] then
		return uColoursLive[hash]
	end

	for v, k in RandomPairs(uColoursBase) do
		if uColoursUsed[v] then
			continue
		end

		uColoursLive[hash] = k
		uColoursUsed[v] = true
	end

	if not uColoursLive[hash] then
		uColoursUsed = {}
	end

	return uColoursLive[hash]
end

function impulse:GetTextSize(text, font)
	surface.SetFont(font or "Impulse-Elements20")
	return surface.GetTextSize(text)
end

function impulse:GetTextWidth(text, font)
	surface.SetFont(font or "Impulse-Elements20")
	return surface.GetTextSize(text)
end

function impulse:GetTextHeight(text, font)
	surface.SetFont(font or "Impulse-Elements20")
	return select(2, surface.GetTextSize(text))
end

function impulse:DrawTexture(material, color, x, y, w, h, ...)
	surface.SetDrawColor(color or color_white)
	surface.SetMaterial(Material(material, ...))
	surface.DrawTexturedRect(x, y, w, h)
end

concommand.Add("impulse_play_intro", function(ply, cmd, args)
	local music = impulse.Config.IntroMusic
	local introScenes = impulse.Config.IntroScenes
	if introScenes then
		local arg1 = tonumber(args[1])
		if arg1 and introScenes[arg1] then
			impulse.Scenes.Play(1, introScenes[arg1])
			return
		end

		impulse.Scenes.PlaySet(introScenes, music)
	end
end)