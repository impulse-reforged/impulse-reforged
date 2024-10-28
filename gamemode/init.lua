resource.AddWorkshop("1651398810") -- framework content

DeriveGamemode("sandbox")

MsgC(Color(83, 143, 239), "[impulse-reforged] Starting boot sequence...\n")
MsgC(Color(83, 143, 239), "[impulse-reforged] Starting server load...\n")

impulse = impulse or {} -- defining global function table

-- load the framework bootstrapper

AddCSLuaFile("shared.lua")
include("shared.lua")

MsgC(Color(0, 255, 0), "[impulse-reforged] Completed server load...\n")

-- security overrides, people should have these set anyway, but this is just in case
RunConsoleCommand("sv_allowupload", "0")
RunConsoleCommand("sv_allowdownload", "0")
RunConsoleCommand("sv_allowcslua", "0")

if engine.ActiveGamemode() == "impulse-reforged" then
    local gs = ""
    for k, v in pairs(engine.GetGamemodes()) do
        if v.name:find("impulse") and v.name != "impulse-reforged" then
            gs = gs .. v.name .. "\n"
        end
    end

    SetGlobalString("impulse_fatalerror", "No schema loaded. Please place the schema in your gamemodes folder, then set it as your gamemode.\n\nInstalled available schemas:\n"..gs)
end