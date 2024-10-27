-- luacheck: ignore 111

--- Hooks that can be used in a Plugin or a Schema for the client
-- @hooks Shared

--- Controls wether a player can use their inventory, returning false stops all inventory interaction and stops the inventory from displaying
-- @realm shared
-- @entity ply The player that is trying to use their inventory
-- @treturn bool Can use inventory
function CanUseInventory(ply)
end

--- Called to decide what the known name of a player should be
-- @realm shared
-- @entity ply The player to get the name of
-- @treturn string The known name
function PlayerGetKnownName()
end

--- Called after the config has loaded
-- @realm shared
function PostConfigLoad()
end

--- Called when the schema has loaded fully
-- @realm shared
function OnSchemaLoaded()
end

--- Called when a Sync variable is updated
-- @realm shared
-- @int varID The sync variable ID
-- @int targetID The entity ID of the target
-- @param any The new value
function OnSyncUpdate()
end

--- Called to decide if a player can change team
-- @realm shared
-- @entity ply The player
-- @int team The team to switch to
-- @treturn bool Can we switch team?
function CanPlayerChangeTeam()
end