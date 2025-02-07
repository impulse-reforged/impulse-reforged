local logs = impulse.Logs

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
            logs:Error("No player target specified.")
            return
        end

        local group = args[2]
        if !group then
            logs:Error("No group specified.")
            return
        end

        local targ = impulse.Util:FindPlayer(find)
        if IsValid(targ) then
            targ:SetUserGroup(group, true)
            logs:Info("Set '" .. targ:SteamID64() .. " (" .. targ:Name() .. ")' to group '" .. group .. "'.\n")

            local query = mysql:Update("impulse_players")
            query:Update("group", group)
            query:Where("steamid", targ:SteamID64())
            query:Execute()

            return
        else
            logs:Warning("Target not found, checking for SteamID64...\n")
        end

        local steamid
        if IsSteamID(find) then
            steamid = util.SteamIDTo64(find)
        elseif IsSteamID64(find) then
            steamid = find
        end
        
        if !steamid then
            logs:Error("Target not found, and '" .. find .. "' is not a valid SteamID64.")
            return
        end

        local query = mysql:Update("impulse_players")
        query:Update("group", group)
        query:Where("steamid", steamid)
        query:Execute()

        logs:Success("Set '" .. steamid .. "' to group '" .. group .. "'.\n")
    end
end)