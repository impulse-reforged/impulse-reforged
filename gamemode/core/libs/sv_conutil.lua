local function IsSteamID(str)
    return string.match(str, "STEAM_%d:%d:%d+")
end

local function IsSteamID64(str)
    return string.match(str, "7656119%d+")
end

concommand.Add("impulse_set_group", function(ply, cmd, args)
    if ( !IsValid(ply) or ply:IsSuperAdmin() or ply:IsListenServerHost() ) then
        local find = args[1]
        if !find then
            MsgC(Color(255, 0, 0), "[impulse-reforged] No player target specified.\n")
            return
        end

        local group = args[2]
        if !group then
            MsgC(Color(255, 0, 0), "[impulse-reforged] No group specified.\n")
            return
        end

        local targ = impulse.Util:FindPlayer(find)
        if IsValid(targ) then
            targ:SetUserGroup(group, true)
            MsgC(Color(83, 143, 239), "[impulse-reforged] Set '" .. targ:SteamID64() .. " (" .. targ:Name() .. ")' to group '" .. group .. "'.\n")

            local query = mysql:Update("impulse_players")
            query:Update("group", group)
            query:Where("steamid", targ:SteamID64())
            query:Execute()

            return
        else
            MsgC(Color(255, 200, 0), "[impulse-reforged] Target not found, checking for SteamID64...\n")
        end

        local steamid
        if IsSteamID(find) then
            steamid = util.SteamIDTo64(find)
        elseif IsSteamID64(find) then
            steamid = find
        end
        
        if !steamid then
            MsgC(Color(255, 0, 0), "[impulse-reforged] Target not found, and '" .. find .. "' is not a valid SteamID64.\n")
            return
        end

        local query = mysql:Update("impulse_players")
        query:Update("group", group)
        query:Where("steamid", steamid)
        query:Execute()

        MsgC(Color(83, 143, 239), "[impulse-reforged] Set '" .. steamid .. "' to group '" .. group .. "'.\n")
    end
end)