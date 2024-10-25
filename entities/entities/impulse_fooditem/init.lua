AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:PhysWake()
end

function ENT:Use(ply)
	if self.isDrink then
		ply:EmitSound("impulse-reforged/drink.wav")
	else
		ply:EmitSound("impulse-reforged/eat.wav")
	end

	ply:FeedHunger(self.food)
	SafeRemoveEntity(self)
end