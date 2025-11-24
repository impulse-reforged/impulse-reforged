--- Helper functions for the players hunger
-- @module impulse.Hunger

impulse.Hunger = impulse.Hunger or {}

--- Set the hunger amount of a player
-- @realm server
-- @player client Player to set hunger
-- @int amount Amount of hunger (0-100)
function impulse.Hunger:SetHunger(client, amount)
    client:SetHunger(amount)
end

--- Feed's the player the amount of hunger
-- @realm server
-- @player client Player to feed hunger
-- @int amount Amount of hunger (0-100)
function impulse.Hunger:FeedHunger(client, amount)
    client:FeedHunger(amount)
end

--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Set the hunger amount of a player
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:SetHunger(amount)
    return self:SetRelay("hunger", math.Clamp(amount, 0, 100))
end

--- Gives the player the amount of hunger
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:FeedHunger(amount)
    return self:SetHunger(amount + self:GetRelay("hunger", 100))
end

--- Takes the amount of hunger from the player
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:TakeHunger(amount)
    return self:SetHunger(self:GetRelay("hunger", 100) - amount)
end
