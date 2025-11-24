--- Currency system for impulse
-- @module impulse.Currency

impulse.Currency = impulse.Currency or {}

local PLAYER = FindMetaTable("Player")

--- Returns the player's money
-- @realm shared
-- @treturn number The player's money
function PLAYER:GetMoney()
    return tonumber(self:GetRelay("money", 0))
end

--- Returns the player's bank money
-- @realm shared
-- @treturn number The player's bank money
function PLAYER:GetBankMoney()
    return tonumber(self:GetRelay("bankMoney", 0))
end

--- Returns wether the player has enough money to afford the amount
-- @realm shared
-- @int amount The amount to check
-- @treturn boolean Wether the player can afford the amount
function PLAYER:CanAfford(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    return self:GetMoney() >= amount
end

--- Adds money to the player
-- @realm shared
-- @int amount The amount to add
function PLAYER:CanAffordBank(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    return self:GetBankMoney() >= amount
end
