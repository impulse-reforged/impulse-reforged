local PLAYER = FindMetaTable("Player")

function PLAYER:SetMoney(amount)
    if not self.impulseBeenSetup or self.impulseBeenSetup == false then return end
    if not isnumber(amount) or amount < 0 or amount >= 1 / 0 then return end

    local query = mysql:Update("impulse_players")
    query:Update("money", amount)
    query:Where("steamid", self:SteamID64())
    query:Execute()

    return self:SetNetVar("money", amount)
end

function PLAYER:SetBankMoney(amount)
    if not self.impulseBeenSetup or self.impulseBeenSetup == false then return end
    if not isnumber(amount) or amount < 0 or amount >= 1 / 0 then return end

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

function impulse.SpawnMoney(pos, amount, dropper)
    local note = ents.Create("impulse_money")
    note:SetMoney(amount)
    note:SetPos(pos)
    note.Dropper = dropper or nil
    note:Spawn()

    return note
end