--- Currency system for impulse
-- @module impulse.Currency

impulse.Currency = impulse.Currency or {}

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMoney()
    return tonumber(self:GetNetVar("money", 0))
end

function PLAYER:GetBankMoney()
    return tonumber(self:GetNetVar("bankmoney", 0))
end

function PLAYER:CanAfford(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    return self:GetMoney() >= amount
end

function PLAYER:CanAffordBank(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    return self:GetBankMoney() >= amount
end