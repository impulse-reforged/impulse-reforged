--[[
    impulse Badge System

    Badges are decorative icons displayed on player profiles, scoreboards, and context menus
    to highlight special roles, achievements, or contributions within the community.

    Please don't ever remove credit or users/badges from this section.
    People worked hard on this. Thanks!
]]

impulse.Badges = impulse.Badges or {}

-- Badge user lists
local BADGE_USERS = {
    superTesters = {
        ["STEAM_0:1:53542485"] = "mats",
        ["STEAM_0:1:75156459"] = "jamsu",
        ["STEAM_0:1:83204982"] = "oscar",
        ["STEAM_0:1:43061896"] = "jim wakelin",
        ["STEAM_0:0:24607430"] = "stranger",
        ["STEAM_0:0:26121174"] = "greasy",
        ["STEAM_0:1:40283833"] = "tim cook",
        ["STEAM_0:0:157214263"] = "loka",
        ["STEAM_0:0:73384910"] = "avx/soviet",
        ["STEAM_0:1:175014750"] = "personwhoplaysgames"
    },

    mappers = {
        ["STEAM_0:0:24607430"] = "stranger"
    },

    eventTeam = {
        ["STEAM_0:1:462578059"] = "opiper"
    },

    exDevelopers = {
        ["STEAM_0:1:102639297"] = "ex developer"
    },

    creator = {
        ["STEAM_0:1:95921723"] = "vin"
    },

    competitionWinners = {
        -- Add competition winners here
    }
}

--[[
    Badge Structure:
    {
        icon = Material object,
        description = string,
        check = function(client) - returns true if player should have badge
        priority = number (optional, lower = higher priority in display order)
    }
]]

-- Register badge function for easy badge creation
function impulse.RegisterBadge(id, icon, description, checkFunc, priority)
    if !id or !icon or !description or !checkFunc then
        ErrorNoHalt("[impulse] Failed to register badge - missing required parameters\n")
        return false
    end

    impulse.Badges[id] = {
        icon,
        description,
        checkFunc,
        priority or 999
    }

    return true
end

-- Helper function to check if SteamID is in a badge list
local function HasBadge(steamID, badgeList)
    steamID = util.SteamIDFrom64(steamID) or steamID
    return badgeList[steamID] != nil
end

-- Initialize badges
local function InitializeBadges()
    -- Creator Badge (Highest Priority)
    impulse.RegisterBadge("creator",
        Material("impulse-reforged/vin.png"),
        "Hi, it's me vin! The creator of impulse.",
        function(client)
            return !client:IsIncognito() and HasBadge(client:SteamID(), BADGE_USERS.creator)
        end,
        1
    )

    -- Maintainer Badge
    impulse.RegisterBadge("maintainer",
        Material("icon16/wrench.png"),
        "Hey there, my name is Riggs! I am the creator of impulse: reforged.",
        function(client)
            return !client:IsIncognito() and client:SteamID64() == "76561197963057641"
        end,
        1.5
    )

    -- Developer Badge
    impulse.RegisterBadge("dev",
        Material("icon16/cog.png"),
        "This player is an impulse developer.",
        function(client)
            return !client:IsIncognito() and client:IsDeveloper()
        end,
        2
    )

    -- Ex-Developer Badge
    impulse.RegisterBadge("exdev",
        Material("icon16/cog_go.png"),
        "This player is an ex-impulse developer.",
        function(client)
            return HasBadge(client:SteamID(), BADGE_USERS.exDevelopers)
        end,
        3
    )

    -- Staff Badge
    impulse.RegisterBadge("staff",
        Material("icon16/shield.png"),
        "This player is a staff member.",
        function(client)
            return !client:IsIncognito() and client:IsAdmin()
        end,
        10
    )

    -- Community Manager Badge
    impulse.RegisterBadge("communitymanager",
        Material("icon16/transmit.png"),
        "This player is a community manager. Feel free to ask them questions.",
        function(client)
            return client:GetUserGroup() == "communitymanager"
        end,
        11
    )

    -- Event Team Badge
    impulse.RegisterBadge("eventteam",
        Material("icon16/controller.png"),
        "This player is part of the event team.",
        function(client)
            return HasBadge(client:SteamID(), BADGE_USERS.eventTeam)
        end,
        20
    )

    -- Donator Badge
    impulse.RegisterBadge("donator",
        Material("icon16/coins.png"),
        "This player is a donator.",
        function(client)
            return client:IsDonator()
        end,
        30
    )

    -- Super Tester Badge
    impulse.RegisterBadge("supertester",
        Material("icon16/bug.png"),
        "This player made large contributions to the testing of impulse.",
        function(client)
            return HasBadge(client:SteamID(), BADGE_USERS.superTesters)
        end,
        40
    )

    -- Mapper Badge
    impulse.RegisterBadge("mapper",
        Material("icon16/map.png"),
        "This player is a mapper that has collaborated with impulse.",
        function(client)
            return HasBadge(client:SteamID(), BADGE_USERS.mappers)
        end,
        50
    )

    -- Competition Winner Badge
    impulse.RegisterBadge("competition",
        Material("icon16/rosette.png"),
        "This player has won a competition.",
        function(client)
            return HasBadge(client:SteamID(), BADGE_USERS.competitionWinners)
        end,
        60
    )
end

-- Get badges for a specific player (returns sorted by priority)
function impulse.GetPlayerBadges(client)
    if type(client) != "Player" then return {} end

    local badges = {}

    for id, badgeData in pairs(impulse.Badges) do
        if badgeData[3](client) then
            table.insert(badges, {
                id = id,
                icon = badgeData[1],
                description = badgeData[2],
                priority = badgeData[4] or 999
            })
        end
    end

    -- Sort by priority (lower number = higher priority)
    table.sort(badges, function(a, b)
        return a.priority < b.priority
    end)

    return badges
end

-- Check if a player has a specific badge
function impulse.PlayerHasBadge(client, badgeID)
    if type(client) != "Player" or !impulse.Badges[badgeID] then
        return false
    end

    return impulse.Badges[badgeID][3](client)
end

-- Get badge data by ID
function impulse.GetBadge(badgeID)
    return impulse.Badges[badgeID]
end

-- Get all registered badge IDs
function impulse.GetAllBadgeIDs()
    local ids = {}
    for id, _ in pairs(impulse.Badges) do
        table.insert(ids, id)
    end
    return ids
end

-- Add a competition winner
function impulse.AddCompetitionWinner(steamID, name)
    BADGE_USERS.competitionWinners[steamID] = name or "Competition Winner"
    print("[impulse] Added competition winner badge for " .. steamID)
end

-- Remove a competition winner
function impulse.RemoveCompetitionWinner(steamID)
    if BADGE_USERS.competitionWinners[steamID] then
        BADGE_USERS.competitionWinners[steamID] = nil
        print("[impulse] Removed competition winner badge for " .. steamID)
    end
end

-- Console command to list all badge users (admin only)
concommand.Add("impulse_badges_list", function(ply, cmd, args)
    if IsValid(ply) and !ply:IsAdmin() then
        return ply:ChatPrint("You must be an admin to use this command.")
    end

    print(" = == impulse Badge Users == = ")
    for category, users in pairs(BADGE_USERS) do
        print("\n[" .. category .. "]")
        for steamID, name in pairs(users) do
            print("  " .. steamID .. " - " .. name)
        end
    end
    print("\n = == = == = == = == = == = == = == = == = ")
end)

-- Console command to add competition winner
concommand.Add("impulse_badges_addwinner", function(ply, cmd, args)
    if IsValid(ply) and !ply:IsSuperAdmin() then
        return ply:ChatPrint("You must be a superadmin to use this command.")
    end

    if !args[1] then
        local msg = "Usage: impulse_badges_addwinner <steamid> [name]"
        if IsValid(ply) then
            ply:ChatPrint(msg)
        else
            print(msg)
        end
        return
    end

    local steamID = args[1]
    local name = table.concat(args, " ", 2) or "Competition Winner"

    impulse.AddCompetitionWinner(steamID, name)

    local msg = "Added competition winner badge for " .. steamID .. " (" .. name .. ")"
    if IsValid(ply) then
        ply:ChatPrint(msg)
    else
        print(msg)
    end
end)

-- Console command to remove competition winner
concommand.Add("impulse_badges_removewinner", function(ply, cmd, args)
    if IsValid(ply) and !ply:IsSuperAdmin() then
        return ply:ChatPrint("You must be a superadmin to use this command.")
    end

    if !args[1] then
        local msg = "Usage: impulse_badges_removewinner <steamid>"
        if IsValid(ply) then
            ply:ChatPrint(msg)
        else
            print(msg)
        end
        return
    end

    local steamID = args[1]
    impulse.RemoveCompetitionWinner(steamID)

    local msg = "Removed competition winner badge for " .. steamID
    if IsValid(ply) then
        ply:ChatPrint(msg)
    else
        print(msg)
    end
end)

-- Backward compatibility: Allow direct access to badge check functions
-- This ensures existing code like impulse.Badges["staff"][3](client) still works
setmetatable(impulse.Badges, {
    __index = function(t, key)
        -- Return nil if accessing a non-existent badge
        return rawget(t, key)
    end
})

-- Initialize badges when this file loads
InitializeBadges()

MsgC(Color(83, 143, 239), "[impulse] Badge system initialized with ", Color(0, 255, 0), tostring(table.Count(impulse.Badges)), Color(83, 143, 239), " badges\n")
