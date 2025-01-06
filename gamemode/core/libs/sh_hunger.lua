--- Helper functions for the players hunger
-- @module impulse.Hunger

impulse.Hunger = impulse.Hunger or {}

--- Returns the amount of hunger a player has
-- @realm shared
-- @treturn int amount Amount of hunger a player has
function impulse.Hunger:GetHunger(ply)
    return ply:GetHunger()
end

--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Returns the amount of hunger a player has
-- @realm shared
-- @treturn int amount Amount of hunger a player has
function PLAYER:GetHunger()
    return tonumber(self:GetNetVar("hunger", 100))
end