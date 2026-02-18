--[[
    impulse-reforged - CAMI Privilege Registration
    Registers all CAMI privileges for the framework
]]

-- Register usergroups
CAMI.RegisterUsergroup({
    Name = "user",
    Inherits = "user"
}, "impulse-reforged")

CAMI.RegisterUsergroup({
    Name = "donator",
    Inherits = "user"
}, "impulse-reforged")

CAMI.RegisterUsergroup({
    Name = "admin",
    Inherits = "donator"
}, "impulse-reforged")

CAMI.RegisterUsergroup({
    Name = "superadmin",
    Inherits = "communitymanager"
}, "impulse-reforged")

-- Movement & Observation
CAMI.RegisterPrivilege({
    Name = "impulse: Noclip",
    MinAccess = "admin",
    Description = "Ability to enter noclip/observer mode"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Incognito",
    MinAccess = "admin",
    Description = "Ability to hide from players while in noclip"
})

-- Player Management
CAMI.RegisterPrivilege({
    Name = "impulse: Bring Player",
    MinAccess = "admin",
    Description = "Teleport players to you"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Goto Player",
    MinAccess = "admin",
    Description = "Teleport to other players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Return Player",
    MinAccess = "admin",
    Description = "Return players to their previous position"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Freeze Player",
    MinAccess = "admin",
    Description = "Freeze/unfreeze players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Slay Player",
    MinAccess = "admin",
    Description = "Kill other players instantly"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Respawn Player",
    MinAccess = "admin",
    Description = "Force respawn other players"
})

-- Moderation Actions
CAMI.RegisterPrivilege({
    Name = "impulse: Kick Players",
    MinAccess = "admin",
    Description = "Remove players from the server temporarily"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Ban Players",
    MinAccess = "admin",
    Description = "Permanently or temporarily ban players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Timeout Players",
    MinAccess = "admin",
    Description = "Temporarily restrict player actions"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Mute Players",
    MinAccess = "admin",
    Description = "Prevent players from using text chat"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Gag Players",
    MinAccess = "admin",
    Description = "Prevent players from using voice chat"
})

-- Reports & Support System
CAMI.RegisterPrivilege({
    Name = "impulse: Handle Support Tool",
    MinAccess = "superadmin",
    Description = "Access and use the support tool"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Handle Reports",
    MinAccess = "admin",
    Description = "View and respond to player reports"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Teleport to Reports",
    MinAccess = "admin",
    Description = "Teleport to players who created reports"
})

-- Inventory Management
CAMI.RegisterPrivilege({
    Name = "impulse: Give Items",
    MinAccess = "admin",
    Description = "Give items to players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Remove Items",
    MinAccess = "admin",
    Description = "Remove items from players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: View Inventory",
    MinAccess = "admin",
    Description = "View other players' inventories"
})

-- Character Management
CAMI.RegisterPrivilege({
    Name = "impulse: Set RP Name",
    MinAccess = "admin",
    Description = "Change other players' RP names"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Force Delete Character",
    MinAccess = "superadmin",
    Description = "Force delete player characters"
})

-- Whitelist Management
CAMI.RegisterPrivilege({
    Name = "impulse: Grant Whitelists",
    MinAccess = "admin",
    Description = "Grant whitelist access to players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Revoke Whitelists",
    MinAccess = "admin",
    Description = "Remove whitelist access from players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: View Whitelists",
    MinAccess = "admin",
    Description = "View whitelist information"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Bypass Whitelist",
    MinAccess = "admin",
    Description = "Join whitelisted teams without requirements"
})

-- Building & Props
CAMI.RegisterPrivilege({
    Name = "impulse: Physgun",
    MinAccess = "admin",
    Description = "Use physgun on any entity including players"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Toolgun",
    MinAccess = "admin",
    Description = "Use toolgun and its tools"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Spawn Props",
    MinAccess = "admin",
    Description = "Spawn props, NPCs, effects, and entities"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Spawn Admin Props",
    MinAccess = "admin",
    Description = "Spawn admin-restricted props"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Remove Entities",
    MinAccess = "admin",
    Description = "Use remover tool on player-spawned entities"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Remove Map Entities",
    MinAccess = "superadmin",
    Description = "Use remover tool on map entities and admin tools"
})

-- World Editor Tools
CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Zones",
    MinAccess = "superadmin",
    Description = "Edit and create zones"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Vendors",
    MinAccess = "superadmin",
    Description = "Place and configure vendors"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Storage",
    MinAccess = "superadmin",
    Description = "Create and edit storage containers"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Scenes",
    MinAccess = "superadmin",
    Description = "Edit scene configurations"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - NPCs",
    MinAccess = "superadmin",
    Description = "Configure NPC spawn points"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Loot",
    MinAccess = "superadmin",
    Description = "Configure loot spawn points"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Buttons",
    MinAccess = "superadmin",
    Description = "Configure button behaviors"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Editor - Snow",
    MinAccess = "superadmin",
    Description = "Configure Christmas snow effects and textures"
})

-- Event Management
CAMI.RegisterPrivilege({
    Name = "impulse: Manage Events",
    MinAccess = "superadmin",
    Description = "Available to game event managers"
})

-- Admin Interface
CAMI.RegisterPrivilege({
    Name = "impulse: Admin Settings",
    MinAccess = "admin",
    Description = "Access admin settings menu"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Admin ESP",
    MinAccess = "admin",
    Description = "See admin ESP overlays"
})

CAMI.RegisterPrivilege({
    Name = "impulse: See Admins",
    MinAccess = "admin",
    Description = "See other admins in noclip"
})

-- Communication
CAMI.RegisterPrivilege({
    Name = "impulse: Bypass OOC Cooldown",
    MinAccess = "admin",
    Description = "Bypass OOC chat cooldown timer"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Admin Chat Commands",
    MinAccess = "admin",
    Description = "Use admin-only chat commands"
})

CAMI.RegisterPrivilege({
    Name = "impulse: View Steam IDs",
    MinAccess = "admin",
    Description = "View Steam IDs in chat context menus"
})

-- Context Menu Actions
CAMI.RegisterPrivilege({
    Name = "impulse: Context - Entity Owner",
    MinAccess = "admin",
    Description = "See entity ownership in context menu"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Context - Copy Position",
    MinAccess = "admin",
    Description = "Copy entity positions"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Context - Copy Angles",
    MinAccess = "admin",
    Description = "Copy entity angles"
})

-- Protection Bypasses
CAMI.RegisterPrivilege({
    Name = "impulse: Bypass AntiCheat",
    MinAccess = "admin",
    Description = "Bypass anticheat detections"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Bypass AutoMod",
    MinAccess = "admin",
    Description = "Bypass automod punishments"
})

CAMI.RegisterPrivilege({
    Name = "impulse: Bypass AFK",
    MinAccess = "admin",
    Description = "Bypass AFK kick timer"
})

-- Advanced Tools
CAMI.RegisterPrivilege({
    Name = "impulse: Manage E2 Bans",
    MinAccess = "admin",
    Description = "Modify Expression 2 banned functions list"
})

CAMI.RegisterPrivilege({
    Name = "impulse: View Player Info",
    MinAccess = "admin",
    Description = "View extended player information cards"
})

-- Utility function to check CAMI privileges
if SERVER then
    --- Check if a player has a specific privilege
    -- @realm server
    -- @tparam Player player The player to check
    -- @tparam string privilege The privilege name
    -- @tparam Player target Optional target player for the privilege check
    -- @treturn bool Has privilege
    function impulse.HasPermission(player, privilege, target)
        return CAMI.PlayerHasAccess(player, privilege, function(hasAccess)
            return hasAccess
        end, target)
    end
end
