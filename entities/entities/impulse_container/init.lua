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
    local count = 0

    if self.Inventory[class] then
        count = self.Inventory[class]
    end

    self.Inventory[class] = count + (amount or 1)

    if !noUpdate then
        self:UpdateUsers()
    end
end

function ENT:TakeItem(class, amount, noUpdate)
    local itemCount = self.Inventory[class]
    if itemCount then
        local newCount = itemCount - (amount or 1)

        if newCount < 1 then
            self.Inventory[class] = nil
        else
            self.Inventory[class] = newCount
        end
    end

    if !noUpdate then
        self:UpdateUsers()
    end
end

function ENT:GetStorageWeight()
    local weight = 0

    for k, v in pairs(self.Inventory) do
        local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(k)]
        weight = weight + ((item.Weight or 0) * v)
    end

    return weight
end

function ENT:CanHoldItem(class)
    local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]
    local weight = (item.Weight or 0) * (amount or 1)

    return self:GetStorageWeight() + weight <= self:GetCapacity()
end

function ENT:AddAuthorised(client)
    self.Authorised[client] = true
end

function ENT:AddUser(client)
    self.Users[client] = true

    net.Start("impulseInvContainerOpen")
    net.WriteUInt(table.Count(self.Inventory), 8)

    for k, v in pairs(self.Inventory) do
        local netid = impulse.Inventory:ClassToNetID(k)
        local amount = v

        net.WriteUInt(netid, 10)
        net.WriteUInt(amount, 8)
    end

    net.Send(client)

    client.currentContainer = self
end

function ENT:RemoveUser(client)
    self.Users[client] = nil
    client.currentContainer = nil
end

function ENT:UpdateUsers()
    local pos = self:GetPos()

    for k, v in pairs(self.Users) do
        if IsValid(k) and pos:DistToSqr(k:GetPos()) < (230 ^ 2) then
            net.Start("impulseInvContainerUpdate")
            net.WriteUInt(table.Count(self.Inventory), 8)

            for k2,v2 in pairs(self.Inventory) do
                local netid = impulse.Inventory:ClassToNetID(k2)
                local amount = v2

                net.WriteUInt(netid, 10)
                net.WriteUInt(amount, 8)
            end
            net.Send(k)
        else
            self.Users[k] = nil
        end
    end
end

function ENT:Use(activator, caller)
    if activator:IsPlayer() and activator:Alive() then
        if activator:GetRelay("arrested", false) then 
            return activator:Notify("You cannot access a container when detained.") 
        end

        if activator:IsCP() and self:GetLoot() then
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
