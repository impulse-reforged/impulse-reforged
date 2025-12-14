AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.Bench and self.Bench.Model or "models/props_wasteland/controlroom_desk001b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(false)

    if self.Bench then
        self:SetBenchType(self.Bench.Class)
    end

    local phys = self:GetPhysicsObject()
    phys:Wake()
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

function ENT:SetBench(bench)
    self.Bench = bench

    local health = bench.Health
    if ( health and health > 0 ) then
        self:SetMaxHealth(health)
        self:SetHealth(health)

        self.OnTakeDamage = function(ent, dmg)
            ent:SetHealth(ent:Health() - dmg:GetDamage())

            if ent:Health() <= 0 then
                SafeRemoveEntity(ent)

                if ( bench.OnBreak ) then
                    bench.OnBreak(bench, self)
                end

                hook.Run("OnBenchDestroyed", self, bench)
            end
        end
    end
end

function ENT:OnTakeDamage(dmg)
    return false
end

function ENT:Use(activator, caller)
    if activator:IsPlayer() and activator:Alive() then
        if activator:GetRelay("arrested", false) then
            return activator:Notify("You cannot access this when detained.")
        end

        if self.Bench.Illegal and activator:IsPolice() then
            return activator:Notify("You cannot access this due to your team.")
        end

        if self.Bench.CanUse and !self.Bench.CanUse(self.Bench, activator) then
            return activator:Notify("You can not use this workbench.")
        end

        if self.Bench.OnUse then
            self.Bench.OnUse(self.Bench, activator)
        end

        net.Start("impulseBenchUse")
        net.Send(activator)

        activator.currentBench = self
    end
end
