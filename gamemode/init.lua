DeriveGamemode("sandbox")

MsgC(Color(83, 143, 239), "[impulse-reforged] Starting server load...\n")

impulse = impulse or {}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/cl_util.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("core/sv_util.lua")
AddCSLuaFile("shared.lua")

include("core/cl_util.lua")
include("core/sh_util.lua")
include("core/sv_util.lua")
include("shared.lua")

-- security overrides, people should have these set anyway, but this is just in case
RunConsoleCommand("sv_allowupload", "0")
RunConsoleCommand("sv_allowdownload", "0")
RunConsoleCommand("sv_allowcslua", "0")

if ( engine.ActiveGamemode() == "impulse-reforged" ) then
    local gs = ""
    for k, v in pairs(engine.GetGamemodes()) do
        if v.name:find("impulse") and v.name != "impulse-reforged" then
            gs = gs .. v.name .. "\n"
        end
    end

    SetGlobalString("impulse_fatalerror", "No schema loaded. Please place the schema in your gamemodes folder, then set it as your gamemode.\n\nInstalled available schemas:\n"..gs)
end

-- Include all files in the gamemode such as models, materials, sounds, etc. This is done to ensure that the files are sent to the client. Subfolders are included as well.
local function IncludeFolder(dir)
    local total = 0

    local files, folders = file.Find(dir .. "*", "GAME")
    for k, v in pairs(files) do
        total = total + 1

        resource.AddFile(dir .. v)
    end

    for k, v in pairs(folders) do
        total = total + IncludeFolder(dir .. v .. "/")
    end

    return total
end

local function IncludeContent()
    MsgC(Color(83, 143, 239), "[impulse-reforged] Loading content...\n")

    local total = 0

    total = total + IncludeFolder("gamemodes/impulse-reforged/content/")

    MsgC(Color(0, 255, 0), "[impulse-reforged] Completed content load (" .. total .. " files)...\n")
end

-- Include all workshop addons
local function IncludeWorkshopAddons()
    MsgC(Color(83, 143, 239), "[impulse-reforged] Loading workshop addons...\n")

    local total = 0
    local addons = engine.GetAddons()

    for k, v in pairs(addons) do
        if v.mounted and v.wsid != "0" then
            total = total + 1

            resource.AddWorkshop(v.wsid)
            MsgC(Color(83, 143, 239), "[impulse-reforged] Added workshop addon: " .. v.title .. "\n")
        end
    end

    MsgC(Color(0, 255, 0), "[impulse-reforged] Completed workshop addon load (" .. total .. " addons)...\n")
end

IncludeContent()
IncludeWorkshopAddons()

MsgC(Color(0, 255, 0), "[impulse-reforged] Completed server load...\n")