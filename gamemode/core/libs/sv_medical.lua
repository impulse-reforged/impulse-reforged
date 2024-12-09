local PLAYER = FindMetaTable("Player")

function PLAYER:BreakLegs()
    self.BrokenLegsTime = CurTime() + impulse.Config.BrokenLegsHealTime -- reset heal time

    if self:HasBrokenLegs() then return end

    self:SetNetVar("brokenLegs", true)
    self.BrokenLegs = true

    self:EmitSound("impulse-reforged/bone"..math.random(1, 3)..".wav")
    self:Notify("You have broken your legs.")

    hook.Run("PlayerLegsBroken", self)
end

function PLAYER:FixLegs()
    self:SetNetVar("brokenLegs", false)
    self.BrokenLegs = false
    self.BrokenLegsTime = nil
end