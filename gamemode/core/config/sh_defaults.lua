-- Core configuration defaults for impulse-reforged.
-- Schemas can override these values in their own config files.

local mainColourDefault = Color(52, 152, 219, 255)
local interactColourDefault = Color(120, 220, 120, 255)
local rankColourDefault = Color(211, 211, 211, 255)

local function ClampColourValue(value, fallback)
    local n = tonumber(value)
    if ( !n ) then
        return fallback
    end

    return math.Clamp(math.floor(n), 0, 255)
end

local function NormalizeColor(key, fallback)
    local value = impulse.Config[key]
    if ( IsColor(value) ) then
        impulse.Config[key] = Color(
            ClampColourValue(value.r, fallback.r),
            ClampColourValue(value.g, fallback.g),
            ClampColourValue(value.b, fallback.b),
            ClampColourValue(value.a, fallback.a or 255)
        )
        return
    end

    if ( istable(value) ) then
        local r = value.r or value[1]
        local g = value.g or value[2]
        local b = value.b or value[3]
        local a = value.a or value[4] or 255

        if ( r != nil and g != nil and b != nil ) then
            impulse.Config[key] = Color(
                ClampColourValue(r, fallback.r),
                ClampColourValue(g, fallback.g),
                ClampColourValue(b, fallback.b),
                ClampColourValue(a, fallback.a or 255)
            )
            return
        end
    end

    impulse.Config[key] = Color(fallback.r, fallback.g, fallback.b, fallback.a or 255)
end

local function NormalizeNumber(key, fallback, minValue)
    local value = tonumber(impulse.Config[key])

    if ( !value ) then
        impulse.Config[key] = fallback
        return
    end

    if ( minValue != nil and value < minValue ) then
        impulse.Config[key] = fallback
        return
    end

    impulse.Config[key] = value
end

local function NormalizeString(key, fallback)
    local value = impulse.Config[key]
    if ( !isstring(value) or value == "" ) then
        impulse.Config[key] = fallback
    end
end

local function ApplyCoreConfigDefaults()
    NormalizeColor("MainColour", mainColourDefault)
    NormalizeColor("InteractColour", interactColourDefault)

    NormalizeString("CurrencyPrefix", "$")

    NormalizeNumber("XPTime", 300, 1)
    NormalizeNumber("AFKTime", 120, 1)

    NormalizeNumber("TalkDistance", 280, 1)
    NormalizeNumber("YellDistance", 560, 1)
    NormalizeNumber("WhisperDistance", 100, 1)
    NormalizeNumber("VoiceDistance", 900, 1)

    NormalizeNumber("TeamChangeTime", 15, 0)
    NormalizeNumber("TeamChangeTimeDonator", 5, 0)
    NormalizeNumber("ClassChangeTime", 15, 0)

    NormalizeNumber("HungerTime", 120, 1)
    NormalizeNumber("HungerHealTime", 10, 1)
    NormalizeNumber("BrokenLegsHealTime", 90, 1)

    NormalizeNumber("OOCLimit", 15, 0)
    NormalizeNumber("OOCLimitVIP", 30, 0)
    NormalizeNumber("DroppedMoneyLimit", 5, 1)
    NormalizeNumber("MaxLetters", 10, 1)

    NormalizeNumber("DefaultTeam", 1, 1)
    NormalizeNumber("WalkSpeed", 120, 1)
    NormalizeNumber("JogSpeed", 220, 1)
    NormalizeNumber("JumpPower", 160, 1)

    if ( !istable(impulse.Config.RankColours) ) then
        impulse.Config.RankColours = {
            ["user"] = rankColourDefault
        }
    elseif ( !IsColor(impulse.Config.RankColours.user) ) then
        impulse.Config.RankColours.user = rankColourDefault
    end
end

ApplyCoreConfigDefaults()
hook.Add("PostConfigLoad", "impulseCoreConfigDefaults", ApplyCoreConfigDefaults)
