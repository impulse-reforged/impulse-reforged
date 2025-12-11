-- Define gamemode information.
GM.Name = "impulse"
GM.Author = "vin, Riggs"
GM.Website = "https://impulse.minerva-servers.com"

if ( SERVER ) then
    concommand.Remove("gm_save")
    RunConsoleCommand("sv_defaultdeployspeed", 1)
end

-- disable widgets cause it uses like 30% server cpu lol
function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")

-- Create impulse data folder
file.CreateDir("impulse-reforged")

-- Load config
impulse.Config = impulse.Config or {}

-- Include thirdparty libraries
impulse.Util:IncludeDir("core/thirdparty")

-- Attempt to connect to a database if we have the details
impulse.Config.YML = impulse.Yaml.Read("data/impulse-reforged/config.yml") or {}

-- Load core config defaults
impulse.Util:IncludeDir("core/config")

-- Load the rest of the gamemode
impulse.Util:IncludeDir("core/libs")
impulse.Util:IncludeDir("core/meta")
impulse.Util:IncludeDir("core/derma")
impulse.Util:IncludeDir("core/hooks")

function GM:Initialize()
    impulse.Plugins:Load()
    impulse.Schema:Load()
end

impulse_reloaded = false
impulse_reloads = impulse_reloads or 0
impulse_reload_time = SysTime()

function GM:OnReloaded()
    if ( impulse_reloaded ) then return end

    GM = GM or GAMEMODE

    impulse.Plugins:Load()
    impulse.Schema:Load()

    impulse_reloads = impulse_reloads + 1
    impulse_reload_time = math.Round(SysTime() - impulse_reload_time, 2)

    MsgC(Color(0, 255, 0), "[impulse-reforged] Reloaded in " .. impulse_reload_time .. "s. (" .. impulse_reloads .. " total reloads)\n")

    GM = nil
end

impulse_ispreview = CreateConVar("impulse_preview", 0, FCVAR_REPLICATED, "If the current build is in preview mode.")
