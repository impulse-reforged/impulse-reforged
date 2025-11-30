--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Breaks a player's legs
-- @realm server
function PLAYER:BreakLegs()
    if ( self:HasBrokenLegs() ) then return end

    self:SetRelay("brokenLegs", true)
    self:SetRelay("brokenLegsStartTime", CurTime())

    self:EmitSound("impulse-reforged/bone" .. math.random(1, 3) .. ".wav")
    self:Notify("You have broken your legs and can barely move!", NOTIFY_ERROR)

    hook.Run("PlayerLegsBroken", self)
end

--- Fixes a player's legs
-- @realm server
function PLAYER:FixLegs()
    self:SetRelay("brokenLegs", nil)
    self:SetRelay("brokenLegsStartTime", nil)
end
