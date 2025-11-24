--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Breaks a player's legs
-- @realm server
function PLAYER:BreakLegs()
    self.BrokenLegsTime = CurTime() + impulse.Config.BrokenLegsHealTime -- reset heal time

    if ( self:HasBrokenLegs() ) then return end

    self:SetRelay("brokenLegs", true)
    self.impulseBrokenLegs = true

    self:EmitSound("impulse-reforged/bone" .. math.random(1, 3) .. ".wav")
    self:Notify("You have broken your legs!", NOTIFY_ERROR)

    hook.Run("PlayerLegsBroken", self)
end

--- Fixes a player's legs
-- @realm server
function PLAYER:FixLegs()
    self:SetRelay("brokenLegs", false)
    self.impulseBrokenLegs = false
    self.BrokenLegsTime = nil
end
