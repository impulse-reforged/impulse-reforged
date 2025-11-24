--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Returns whether a player has broken legs
-- @realm shared
function PLAYER:HasBrokenLegs()
    return tobool(self:GetRelay("brokenLegs", false))
end
