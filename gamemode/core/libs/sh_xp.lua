--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Returns the amount of XP a player has
-- @realm shared
-- @treturn int amount Amount of XP a player has
function PLAYER:GetXP()
    return tonumber(self:GetNetVar("xp", 0))
end

if ( SERVER ) then
    --- Sets the amount of XP a player has
    -- @realm server
    -- @int amount The amount of XP to set for the player
    -- @treturn int amount The new amount of XP the player has received
    function PLAYER:SetXP(amount, bNoSave)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

        if ( !bNoSave ) then
            local query = mysql:Update("impulse_players")
            query:Update("xp", amount)
            query:Where("steamid", self:SteamID64())
            query:Execute()
        end

        return self:SetNetVar("xp", amount)
    end
    
    --- Takes XP from a player
    -- @realm server
    -- @int amount The amount of XP to take from the player
    function PLAYER:TakeXP(amount)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

        self:SetXP(self:GetXP() - amount)

        hook.Run("PlayerTakeXP", self, amount)
    end

    --- Adds XP to a player
    -- @realm server
    -- @int amount The amount of XP to add to the player
    function PLAYER:AddXP(amount)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return end

        self:SetXP(self:GetXP() + amount)

        hook.Run("PlayerGetXP", self, amount)
    end

    --- Gives XP with a message to the player
    -- @realm server
    function PLAYER:GiveTimedXP()
        if ( self:IsDonator() ) then
            self:AddXP(impulse.Config.XPGetDonator)
            self:Notify("You have received " .. impulse.Config.XPGetDonator .. " XP for playing.")
        else
            self:AddXP(impulse.Config.XPGet)
            self:Notify("You have received " .. impulse.Config.XPGet .. " XP for playing.")
        end
    end
end
