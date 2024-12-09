local PLAYER = FindMetaTable("Player")

function PLAYER:GetMoney()
    return self:GetNetVar("money", 0)
end

function PLAYER:GetBankMoney()
    return self:GetNetVar("bankMoney", 0)
end

function PLAYER:CanAfford(amount)
    return self:GetMoney() >= amount
end

function PLAYER:CanAffordBank(amount)
    return self:GetBankMoney() >= amount
end