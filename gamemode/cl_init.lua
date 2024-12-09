local ply
local _LocalPlayer = LocalPlayer
function LocalPlayer()
    ply = _LocalPlayer()

    if IsValid(pl) then
        LocalPlayer = function()
            return ply
        end
    end

    return ply
end

DeriveGamemode("sandbox")

MsgC(Color(83, 143, 239), "[impulse-reforged] Starting client load...\n")

impulse = impulse or {}

include("core/cl_util.lua")
include("core/sh_util.lua")
include("core/sv_util.lua")
include("shared.lua")

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")

hook.Add("PreDrawHalos", "PropertiesHover", function() -- overwrite exploitable context menu shit

    if ( !IsValid( vgui.GetHoveredPanel() ) or !vgui.GetHoveredPanel():IsWorldClicker() ) then return end

    local ent = properties.GetHovered( EyePos(), LocalPlayer():GetAimVector() )
    if ( !IsValid( ent ) ) then return end

    if ent:GetNoDraw() then return end

    local c = Color( 255, 255, 255, 255 )
    c.r = 200 + math.sin( RealTime() * 50 ) * 55
    c.g = 200 + math.sin( RealTime() * 20 ) * 55
    c.b = 200 + math.cos( RealTime() * 60 ) * 55

    local t = { ent }
    if ( ent.GetActiveWeapon and IsValid( ent:GetActiveWeapon() ) ) then table.insert( t, ent:GetActiveWeapon() ) end
    halo.Add( t, c, 2, 2, 2, true, false )
end)

RunConsoleCommand("cl_showhints",  "0") -- disable annoying gmod hints by default

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

MsgC(Color(0, 255, 0), "[impulse-reforged] Completed client load...\n")