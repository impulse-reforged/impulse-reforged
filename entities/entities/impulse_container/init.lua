AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    local model = self.impulseSaveKeyValue and self.impulseSaveKeyValue["model"]

    if model then
        self:SetModel(model)
    elseif self:GetModel() == "models/error.mdl" then
        self:SetModel("models/props_junk/wood_crate001a.mdl")
    end
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(false)

    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()

        if self.impulseSaveKeyValue then
            phys:EnableMotion(false)
        else
            phys:EnableMotion(true)
        end
    end

    self.Users = {}
    self.Authorised = {}
    self.Inventory = {}

    local lootpool = self.impulseSaveKeyValue and self.impulseSaveKeyValue["lootpool"]

    if lootpool then
        self:SetLoot(true)
        self:SetCapacity(30)
        self.LootPool = lootpool
        self:MakeLoot()
    end
end

function ENT:OnTakeDamage(dmg) 
    return false
end

function ENT:MakeLoot()
    local pool = self.LootPool

    if impulse.Config.LootPools and impulse.Config.LootPools[pool] then
        local loot = impulse.Loot.GenerateFromPool(pool)

        self.Inventory = {}

        for k, v in pairs(loot) do
            self:AddItem(k, v, true)    
        end

        self:UpdateUsers()

        local fullRatio = player.GetCount() / game.MaxPlayers()
        fullRatio = math.Clamp(fullRatio, 0 , 1)

        local base = impulse.Config.LootPools[self.LootPool].MaxWait
        local take = base - impulse.Config.LootPools[self.LootPool].MinWait
        take = take * fullRatio

        self.LootNext = CurTime() + (base - take)
    end
end

function ENT:SetCode(code)
    self.Authorised = {}
    self.Code = code
end

function ENT:AddItem(class, amount, noUpdate)
    return impulse.Inventory:ContainerAddItem(self, class, amount, noUpdate)
end

function ENT:TakeItem(class, amount, noUpdate)
    return impulse.Inventory:ContainerTakeItem(self, class, amount, noUpdate)
end

function ENT:GetStorageWeight()
    return impulse.Inventory:ContainerGetWeight(self)
end

function ENT:CanHoldItem(class, amount)
    return impulse.Inventory:ContainerCanHoldItem(self, class, amount)
end

function ENT:AddAuthorised(client)
    self.Authorised[client] = true
end

function ENT:AddUser(client)
    return impulse.Inventory:ContainerAddUser(self, client)
end

function ENT:RemoveUser(client)
    return impulse.Inventory:ContainerRemoveUser(self, client)
end

function ENT:UpdateUsers()
    return impulse.Inventory:ContainerUpdateUsers(self)
end

function ENT:Use(activator, caller)
    if activator:IsPlayer() and activator:Alive() then
        if activator:GetRelay("arrested", false) then 
            return activator:Notify("You cannot access a container when detained.") 
        end

        if activator:IsPolice() and self:GetLoot() then
            return activator:Notify("You cannot access this container as this team.")
        end

        if !self:GetLoot() and self.Code and !self.Authorised[activator] then
            net.Start("impulseInvContainerCodeTry")
            net.Send(activator)

            activator.currentContainerPass = self
            return
        end

        self:AddUser(activator)
    end
end

function ENT:Think()
    if self:GetLoot() then
        if self.LootNext and CurTime() > self.LootNext then
            if table.Count(self.Inventory) == 0 then
                self:MakeLoot()
            else
                local fullRatio = player.GetCount() / game.MaxPlayers()
                fullRatio = math.Clamp(fullRatio, 0 , 1)

                local base = impulse.Config.LootPools[self.LootPool].MaxWait
                local take = base - impulse.Config.LootPools[self.LootPool].MinWait
                take = take * fullRatio

                self.LootNext = CurTime() + (base - take)
            end
        end

        self:NextThink(CurTime() + 10)
        return true
    end
end
