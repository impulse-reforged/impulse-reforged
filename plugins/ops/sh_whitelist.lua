-- Team Whitelist Management Commands
-- Provides comprehensive whitelist commands for team management

-- Helper function to find team by name or ID
local function findTeam(identifier)
    if !identifier then return nil end

    -- Try as number first
    local teamID = tonumber(identifier)
    if teamID and impulse.Teams.Stored[teamID] then
        return teamID, impulse.Teams.Stored[teamID]
    end

    -- Try finding by name
    local team = impulse.Teams:FindTeam(identifier)
    if team then
        return team.index, team
    end

    return nil
end

-- /addwhitelist <player> <team> <level> - Add or update whitelist
local addWhitelistCommand = {
    description = "Adds or updates a player's whitelist for a team.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        if !args[1] or !args[2] or !args[3] then
            return client:Notify("Usage: /addwhitelist <player> <team> <level>")
        end

        local target = impulse.Util:FindPlayer(args[1])
        if !IsValid(target) then
            return client:Notify("Could not find player: " .. tostring(args[1]))
        end

        local teamID, teamData = findTeam(args[2])
        if !teamID then
            return client:Notify("Invalid team. Use team name or ID.")
        end

        local level = tonumber(args[3])
        if !level or level < 1 then
            return client:Notify("Invalid whitelist level specified. The level must be a number greater than or equal to 1.")
        end

        local steamID = target:SteamID64()
        local teamCodeName = teamData.codeName
        impulse.Teams.SetWhitelist(steamID, teamCodeName, level)

        -- Update the player's cached whitelists
        target.Whitelists = target.Whitelists or {}
        target.Whitelists[teamID] = level

        print("[ops] " .. client:Name() .. " (" .. client:SteamID64() .. ") added whitelist level " .. level .. " for " .. target:Name() .. " (" .. steamID .. ") on team " .. teamData.name)
        client:Notify("Successfully added whitelist level " .. level .. " for " .. target:Nick() .. " on team " .. teamData.name .. ".")
        target:Notify("You have been whitelisted for " .. teamData.name .. " at level " .. level .. ".")

        -- Log to admins
        for k, v in player.Iterator() do
            if CAMI.PlayerHasAccess(v, "impulse: View Whitelists") then
                v:AddChatText(Color(135, 206, 235), "[ops] " .. client:SteamName() .. " (" .. client:SteamID64() .. ") added whitelist level " .. level .. " for " .. target:Nick() .. " (" .. target:SteamID64() .. ") on team " .. teamData.name .. " (ID: " .. teamID .. ") | Current Team: " .. team.GetName(target:Team()) .. " | Pos: " .. tostring(target:GetPos()))
            end
        end
    end
}

impulse.RegisterChatCommand("/addwhitelist", addWhitelistCommand)
impulse.RegisterChatCommand("/whitelist", addWhitelistCommand)

-- /removewhitelist <player> <team> - Remove whitelist
local removeWhitelistCommand = {
    description = "Removes a player's whitelist for a team.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        if !args[1] or !args[2] then
            return client:Notify("Usage: /removewhitelist <player> <team>")
        end

        local target = impulse.Util:FindPlayer(args[1])
        if !IsValid(target) then
            return client:Notify("Could not find player: " .. tostring(args[1]))
        end

        local teamID, teamData = findTeam(args[2])
        if !teamID then
            return client:Notify("Invalid team. Use team name or ID.")
        end

        local steamID = target:SteamID64()
        local teamCodeName = teamData.codeName

        -- Remove from database
        local query = mysql:Delete("impulse_whitelists")
        query:Where("steamid", steamID)
        query:Where("team", teamCodeName)
        query:Execute()

        -- Update the player's cached whitelists
        if target.Whitelists then
            target.Whitelists[teamID] = nil
        end

        print("[ops] " .. client:Name() .. " (" .. client:SteamID64() .. ") removed whitelist for " .. target:Name() .. " (" .. steamID .. ") on team " .. teamData.name)
        client:Notify("Successfully removed the whitelist for " .. target:Nick() .. " on team " .. teamData.name .. ".")
        target:Notify("Your whitelist for " .. teamData.name .. " has been removed.")

        -- Log to admins
        local oldLevel = target.Whitelists and target.Whitelists[teamID] or "None"
        for k, v in player.Iterator() do
            if CAMI.PlayerHasAccess(v, "impulse: View Whitelists") then
                v:AddChatText(Color(135, 206, 235), "[ops] " .. client:SteamName() .. " (" .. client:SteamID64() .. ") removed whitelist for " .. target:Nick() .. " (" .. target:SteamID64() .. ") on team " .. teamData.name .. " (ID: " .. teamID .. ") | Old Level: " .. tostring(oldLevel) .. " | Current Team: " .. team.GetName(target:Team()) .. " | Pos: " .. tostring(target:GetPos()))
            end
        end
    end
}

impulse.RegisterChatCommand("/removewhitelist", removeWhitelistCommand)
impulse.RegisterChatCommand("/delwhitelist", removeWhitelistCommand)
impulse.RegisterChatCommand("/unwhitelist", removeWhitelistCommand)

-- /checkwhitelist <player> [team] - Check whitelist status
local checkWhitelistCommand = {
    description = "Checks a player's whitelist status for a specific team or all teams.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        if !args[1] then
            return client:Notify("Usage: /checkwhitelist <player> [team]")
        end

        local target = impulse.Util:FindPlayer(args[1])
        if !IsValid(target) then
            return client:Notify("Could not find player: " .. tostring(args[1]))
        end

        if args[2] then
            -- Check specific team
            local teamID, teamData = findTeam(args[2])
            if !teamID then
                return client:Notify("Invalid team specified. Please use a valid team name or ID.")
            end

            if target:HasTeamWhitelist(teamID) then
                local level = target.Whitelists[teamID]
                client:Notify(target:Nick() .. " has whitelist level " .. level .. " for " .. teamData.name .. ".")
            else
                client:Notify(target:Nick() .. " does not have a whitelist for " .. teamData.name .. ".")
            end
        else
            -- Check all teams
            if !target.Whitelists or table.Count(target.Whitelists) == 0 then
                return client:Notify(target:Nick() .. " does not have any whitelists.")
            end

            client:Notify("Whitelists for " .. target:Nick() .. ":")
            for teamID, level in pairs(target.Whitelists) do
                local teamData = impulse.Teams.Stored[teamID]
                if teamData then
                    client:Notify(" - " .. teamData.name .. ": Level " .. level)
                end
            end
        end
    end
}

impulse.RegisterChatCommand("/checkwhitelist", checkWhitelistCommand)
impulse.RegisterChatCommand("/whitelistcheck", checkWhitelistCommand)
impulse.RegisterChatCommand("/wlcheck", checkWhitelistCommand)

-- /listwhitelists <team> - List all whitelisted players for a team
local listWhitelistsCommand = {
    description = "Lists all players whitelisted for a specific team.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        if !args[1] then
            return client:Notify("Usage: /listwhitelists <team>")
        end

        local teamID, teamData = findTeam(args[1])
        if !teamID then
            return client:Notify("Invalid team specified. Please use a valid team name or ID.")
        end

        local teamCodeName = teamData.codeName
        impulse.Teams.GetAllWhitelists(teamCodeName, function(result)
            if !IsValid(client) then return end

            if !result or #result == 0 then
                return client:Notify("No whitelists were found for " .. teamData.name .. ".")
            end

            client:Notify("Whitelists for " .. teamData.name .. " (" .. #result .. " total):")

            for _, data in ipairs(result) do
                local ply = player.GetBySteamID64(data.steamid)
                local name = IsValid(ply) and ply:Nick() or "Offline"
                client:Notify(" - " .. name .. " (SteamID64: " .. data.steamid .. ") - Level " .. data.level)
            end
        end)
    end
}

impulse.RegisterChatCommand("/listwhitelists", listWhitelistsCommand)
impulse.RegisterChatCommand("/whitelistlist", listWhitelistsCommand)
impulse.RegisterChatCommand("/wllist", listWhitelistsCommand)

-- /teaminfo <team> - Show detailed team information including whitelist requirements
local teamInfoCommand = {
    description = "Shows detailed information about a team including ranks and classes.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        if !args[1] then
            return client:Notify("Usage: /teaminfo <team>")
        end

        local teamID, teamData = findTeam(args[1])
        if !teamID then
            return client:Notify("Invalid team specified. Please use a valid team name or ID.")
        end

        client:Notify(" = == = == = == = == = == = == = == = == = == = == = == = == = == = ")
        client:Notify("Team: " .. teamData.name .. " (ID: " .. teamID .. ")")
        client:Notify("XP Required: " .. (teamData.xp or 0))
        if teamData.donatorOnly then
            client:Notify("Donator Only: Yes")
        end

        -- List ranks
        if teamData.ranks and table.Count(teamData.ranks) > 0 then
            client:Notify("--- Ranks ---")
            for rankID, rankData in ipairs(teamData.ranks) do
                local reqText = "XP: " .. (rankData.xp or 0)
                if rankData.whitelistLevel then
                    reqText = reqText .. " | WL Level: " .. rankData.whitelistLevel
                end
                client:Notify(rankID .. ". " .. rankData.name .. " (" .. reqText .. ")")
            end
        end

        -- List classes
        if teamData.classes and table.Count(teamData.classes) > 0 then
            client:Notify("--- Classes ---")
            for classID, classData in ipairs(teamData.classes) do
                if !classData.noMenu then
                    local reqText = "XP: " .. (classData.xp or 0)
                    if classData.whitelistLevel then
                        reqText = reqText .. " | WL Level: " .. classData.whitelistLevel
                    end
                    client:Notify(classID .. ". " .. classData.name .. " (" .. reqText .. ")")
                end
            end
        end

        client:Notify(" = == = == = == = == = == = == = == = == = == = == = == = == = == = ")
    end
}

impulse.RegisterChatCommand("/teaminfo", teamInfoCommand)
impulse.RegisterChatCommand("/teamsinfo", teamInfoCommand)

-- Console Commands
if SERVER then
    -- impulse_whitelists_add <steamid64> <team> <level>
    concommand.Add("impulse_whitelists_add", function(client, cmd, args)
        if IsValid(client) and not CAMI.PlayerHasAccess(client, "impulse: Grant Whitelists") then
            return client:Notify("You must be an admin to use this command.")
        end

        if !args[1] or !args[2] or !args[3] then
            local msg = "Usage: impulse_whitelists_add <steamid64> <team> <level>"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local steamID = args[1]
        if !string.match(steamID, "^%d+$") or #steamID != 17 then
            local msg = "Invalid SteamID64 format"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local teamID, teamData = findTeam(args[2])
        if !teamID then
            local msg = "Invalid team specified. Please use a valid team name or ID."
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local level = tonumber(args[3])
        if !level or level < 1 then
            local msg = "Invalid whitelist level specified. The level must be a number greater than or equal to 1."
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local teamCodeName = teamData.codeName
        impulse.Teams.SetWhitelist(steamID, teamCodeName, level)

        -- Update cached whitelists if player is online
        local target = player.GetBySteamID64(steamID)
        if IsValid(target) then
            target.Whitelists = target.Whitelists or {}
            target.Whitelists[teamID] = level
            target:Notify("You have been whitelisted for " .. teamData.name .. " at level " .. level .. ".")
        end

        local adminName = IsValid(client) and client:Name() .. " (" .. client:SteamID64() .. ")" or "Console"
        print("[ops] " .. adminName .. " added whitelist level " .. level .. " for SteamID64 " .. steamID .. " on team " .. teamData.name)
        local msg = "Successfully added whitelist level " .. level .. " for SteamID64: " .. steamID .. " on team " .. teamData.name .. "."
        if IsValid(client) then
            client:Notify(msg)
        else
            print(msg)
        end
    end)

    -- impulse_whitelists_remove <steamid64> <team>
    concommand.Add("impulse_whitelists_remove", function(client, cmd, args)
        if IsValid(client) and not CAMI.PlayerHasAccess(client, "impulse: Revoke Whitelists") then
            return client:Notify("You must be an admin to use this command.")
        end

        if !args[1] or !args[2] then
            local msg = "Usage: impulse_whitelists_remove <steamid64> <team>"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local steamID = args[1]
        if !string.match(steamID, "^%d+$") or #steamID != 17 then
            local msg = "Invalid SteamID64 format"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local teamID, teamData = findTeam(args[2])
        if !teamID then
            local msg = "Invalid team. Use team name or ID."
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        -- Remove from database
        local teamCodeName = teamData.codeName
        local query = mysql:Delete("impulse_whitelists")
        query:Where("steamid", steamID)
        query:Where("team", teamCodeName)
        query:Execute()

        -- Update cached whitelists if player is online
        local target = player.GetBySteamID64(steamID)
        if IsValid(target) then
            if target.Whitelists then
                target.Whitelists[teamID] = nil
            end
            target:Notify("Your whitelist for " .. teamData.name .. " has been removed.")
        end

        local adminName = IsValid(client) and client:Name() .. " (" .. client:SteamID64() .. ")" or "Console"
        print("[ops] " .. adminName .. " removed whitelist for SteamID64 " .. steamID .. " on team " .. teamData.name)
        local msg = "Successfully removed the whitelist for SteamID64: " .. steamID .. " on team " .. teamData.name .. "."
        if IsValid(client) then
            client:Notify(msg)
        else
            print(msg)
        end
    end)

    -- impulse_whitelists_list <team>
    concommand.Add("impulse_whitelists_list", function(client, cmd, args)
        if IsValid(client) and not CAMI.PlayerHasAccess(client, "impulse: View Whitelists") then
            return client:Notify("You must be an admin to use this command.")
        end

        if !args[1] then
            local msg = "Usage: impulse_whitelists_list <team>"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local teamID, teamData = findTeam(args[1])
        if !teamID then
            local msg = "Invalid team specified. Please use a valid team name or ID."
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
            return
        end

        local teamCodeName = teamData.codeName
        impulse.Teams.GetAllWhitelists(teamCodeName, function(result)
            if IsValid(client) and not IsValid(client) then return end

            if !result or #result == 0 then
                local msg = "No whitelists were found for " .. teamData.name .. "."
                if IsValid(client) then
                    client:Notify(msg)
                else
                    print(msg)
                end
                return
            end

            local header = "Whitelists for " .. teamData.name .. " (" .. #result .. " total):"
            if IsValid(client) then
                client:Notify(header)
            else
                print(header)
            end

            for _, data in ipairs(result) do
                local ply = player.GetBySteamID64(data.steamid)
                local name = IsValid(ply) and ply:Nick() or "Offline"
                local msg = " - " .. name .. " (SteamID64: " .. data.steamid .. ") - Level " .. data.level

                if IsValid(client) then
                    client:Notify(msg)
                else
                    print(msg)
                end
            end
        end)
    end)

    -- impulse_listteams - List all teams with IDs
    concommand.Add("impulse_listteams", function(client, cmd, args)
        if IsValid(client) and not CAMI.PlayerHasAccess(client, "impulse: View Whitelists") then
            return client:Notify("You must be an admin to use this command.")
        end

        local header = "Available Teams:"
        if IsValid(client) then
            client:Notify(header)
        else
            print(header)
        end

        for teamID, teamData in SortedPairsByMemberValue(impulse.Teams.Stored, "name") do
            local msg = teamID .. ". " .. teamData.name .. " (XP: " .. (teamData.xp or 0) .. ")"
            if IsValid(client) then
                client:Notify(msg)
            else
                print(msg)
            end
        end
    end)
end
