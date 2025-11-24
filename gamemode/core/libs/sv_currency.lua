--- Currency system for impulse
-- @module impulse.Currency

impulse.Currency = impulse.Currency or {}

--- Spawns money at a position
-- @realm server
-- @vector pos Position to spawn the money at
-- @int amount Amount of money to spawn
-- @player[opt=nil] dropper Player who dropped the money
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

--- Set's the amount of money a player has
-- @realm server
-- @int amount The amount of money to set for the player
-- @opt[opt=false] bNoSave If true, the money will not be saved to the database
-- @treturn int amount The new amount of money the player has received
function PLAYER:SetMoney(amount, bNoSave)
    if ( !self.impulseBeenSetup ) then return end

    if ( !bNoSave ) then
        local query = mysql:Update("impulse_players")
        query:Update("money", amount)
        query:Where("steamid", self:SteamID64())
        query:Execute()
    end

    self:SetRelay("money", amount)

    return amount
end

--- Set's the amount of bank money a player has
-- @realm server
-- @int amount The amount of bank money to set for the player
-- @opt[opt=false] bNoSave If true, the bank money will not be saved to the database
-- @treturn int amount The new amount of bank money the player has received
function PLAYER:SetBankMoney(amount, bNoSave)
    if ( !self.impulseBeenSetup ) then return end

    if ( !bNoSave ) then
        local query = mysql:Update("impulse_players")
        query:Update("bankmoney", amount)
        query:Where("steamid", self:SteamID64())
        query:Execute()
    end

    self:SetRelay("bankMoney", amount)

    return amount
end

--- Gives the player the amount of money
-- @realm server
-- @int amount Amount of money to give to the player
function PLAYER:AddMoney(amount)
    return self:SetMoney(self:GetMoney() + amount)
end

--- Takes the amount of money from the player
-- @realm server
-- @int amount Amount of money to take from the player
function PLAYER:TakeMoney(amount)
    return self:SetMoney(self:GetMoney() - amount)
end

--- Gives the player the amount of bank money
-- @realm server
-- @int amount Amount of bank money to give to the player
function PLAYER:AddBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() + amount)
end

--- Takes the amount of bank money from the player
-- @realm server
-- @int amount Amount of bank money to take from the player
function PLAYER:TakeBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() - amount)
end
