--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Returns whether a player has broken legs
-- @realm shared
function PLAYER:HasBrokenLegs()
    return self:GetRelay("brokenLegs", false)
end

--- Gets the time when the player's legs were broken
-- @realm shared
function PLAYER:GetBrokenLegsStartTime()
    return self:GetRelay("brokenLegsStartTime", 0)
end
