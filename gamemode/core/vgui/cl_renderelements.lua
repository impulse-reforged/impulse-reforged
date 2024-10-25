local impulseLogo = Material("impulse-reforged/impulse-white.png")
local reforgedLogo = Material("impulse-reforged/reforged-white.png")
local fromCol = Color(255, 45, 85, 255)
local toCol = Color(90, 200, 250, 255)
local fromColHalloween = Color(252, 70, 5)
local toColHalloween = Color(148, 1, 148)
local fromColXmas = Color(223, 17, 3)
local toColXmas = Color(240, 240, 236)

local dateCustom = {
	["12-25"] = {fromColXmas, toColXmas}, -- dec 25th
	["10-31"] = {fromColHalloween, toColHalloween} -- oct 31st
}

local function Glow(c, t, m)
    return Color(c.r + ((t.r - c.r) * (m)), c.g + ((t.g - c.g) * (m)), c.b + ((t.b - c.b) * (m)))
end

local date = os.date("%m-%d")
function impulse:DrawLogo(x, y, w, h)
	local framework, reforged = hook.Run("GetFrameworkLogo")
	framework = framework or impulseLogo
	reforged = reforged or reforgedLogo


	local from, to = hook.Run("GetFrameworkLogoColour")
	from = from or fromCol
	to = to or toCol

	local col = from:Lerp(to, math.abs(math.sin((RealTime() - 0.08) * .2)))

	surface.SetMaterial(framework)
	surface.SetDrawColor(col)
	surface.DrawTexturedRect(x, y, w, h * 0.65)

	surface.SetMaterial(reforged)
	surface.SetDrawColor(col)
	surface.DrawTexturedRect(x, y + h * 0.65, w * 0.6, h * 0.35)
end