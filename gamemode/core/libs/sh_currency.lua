local PLAYER = FindMetaTable("Player")

function PLAYER:GetMoney()
    return self:GetSyncVar(SYNC_MONEY, 0)
end

function PLAYER:GetBankMoney()
    return self:GetSyncVar(SYNC_BANKMONEY, 0)
end

function PLAYER:CanAfford(amount)
    return self:GetMoney() >= amount
end

function PLAYER:CanAffordBank(amount)
    return self:GetBankMoney() >= amount
end