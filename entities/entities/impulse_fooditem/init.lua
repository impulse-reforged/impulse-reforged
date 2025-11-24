AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysWake()
end

function ENT:Use(client)
    if self.isDrink then
        client:EmitSound("impulse-reforged/drink.wav")
    else
        client:EmitSound("impulse-reforged/eat.wav")
    end

    client:FeedHunger(self.food)
    SafeRemoveEntity(self)
end
