local PLAYER = FindMetaTable("Player")

function PLAYER:GetXP()
    return self:GetNetVar("xp", 0)
end

if SERVER then
    function PLAYER:SetXP(amount)
        if not self.impulseBeenSetup or self.impulseBeenSetup == false then return end
        if not isnumber(amount) or amount < 0 or amount >= 1 / 0 then return end

        local query = mysql:Update("impulse_players")
        query:Update("xp", amount)
        query:Where("steamid", self:SteamID64())
        query:Execute()

        return self:SetNetVar("xp", amount)
    end
    
    function PLAYER:TakeXP(amount)
        if ( !amount > 0 ) then
            print("Input must be more than 0!")
            return
        end
        
        local setAmount = self:GetXP() - amount

        self:SetXP(setAmount)

        hook.Run("PlayerTakeXP", self, amount)
    end

    function PLAYER:AddXP(amount)
        local setAmount = self:GetXP() + amount

        self:SetXP(setAmount)

        hook.Run("PlayerGetXP", self, amount)
    end

    function PLAYER:GiveTimedXP()
        if self:IsDonator() then
            self:AddXP(impulse.Config.XPGetVIP)
            self:Notify("You have received "..impulse.Config.XPGetVIP.." XP for playing.")
        else
            self:AddXP(impulse.Config.XPGet)
            self:Notify("You have received "..impulse.Config.XPGet.." XP for playing.")
        end
    end
end
