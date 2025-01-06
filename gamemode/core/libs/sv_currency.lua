--- Currency system for impulse
-- @module impulse.Currency

impulse.Currency = impulse.Currency or {}

--- Spawns money at a position
-- @realm server
-- @vector pos Position to spawn the money at
-- @int amount Amount of money to spawn
-- @opt[opt=nil] dropper Player who dropped the money
function impulse.Currency:SpawnMoney(pos, amount, dropper)
    local note = ents.Create("impulse_money")
    note:SetMoney(amount)
    note:SetPos(pos)
    note.Dropper = dropper or nil
    note:Spawn()

    return note
end

--- Wipes everyone's money
-- @realm server
function impulse.Currency:WipeMoney()
    local query = mysql:Update("impulse_players")
    query:Update("money", 0)
    query:Execute()

    for k, v in player.Iterator() do
        v:SetMoney(0)
    end
end

--- Wipes everyone's bank money
-- @realm server
function impulse.Currency:WipeBankMoney()
    local query = mysql:Update("impulse_players")
    query:Update("bankmoney", 0)
    query:Execute()

    for k, v in player.Iterator() do
        v:SetBankMoney(0)
    end
end

--- Wipes everyone's money and bank money
-- @realm server
function impulse.Currency:WipeAll()
    self:WipeMoney()
    self:WipeBankMoney()
end

local PLAYER = FindMetaTable("Player")

function PLAYER:SetMoney(amount)
    if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    local query = mysql:Update("impulse_players")
    query:Update("money", amount)
    query:Where("steamid", self:SteamID64())
    query:Execute()

    return self:SetNetVar("money", amount)
end

function PLAYER:SetBankMoney(amount)
    if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

    local query = mysql:Update("impulse_players")
    query:Update("bankmoney", amount)
    query:Where("steamid", self:SteamID64())
    query:Execute()

    return self:SetNetVar("bankMoney", amount)
end

function PLAYER:GiveBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() + amount)
end

function PLAYER:TakeBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() - amount)
end

function PLAYER:GiveMoney(amount)
    return self:SetMoney(self:GetMoney() + amount)
end

function PLAYER:TakeMoney(amount)
    return self:SetMoney(self:GetMoney() - amount)
end