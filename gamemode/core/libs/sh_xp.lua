--- Player class methods
-- @classmod Player

local PLAYER = FindMetaTable("Player")

--- Returns the amount of XP a player has
-- @realm shared
-- @treturn int amount Amount of XP a player has
function PLAYER:GetXP()
    return tonumber(self:GetRelay("xp", 0))
end

if ( SERVER ) then
    --- Sets the amount of XP a player has
    -- @realm server
    -- @int amount The amount of XP to set for the player
    -- @opt[opt=false] bNoSave If true, the XP will not be saved to the database
    -- @treturn int amount The new amount of XP the player has received
    function PLAYER:SetXP(amount, bNoSave)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 ) then return end

        if ( !bNoSave ) then
            local query = mysql:Update("impulse_players")
            query:Update("xp", amount)
            query:Where("steamid", self:SteamID64())
            query:Execute()
        end

        return self:SetRelay("xp", amount)
    end

    --- Takes XP from a player
    -- @realm server
    -- @int amount The amount of XP to take from the player
    function PLAYER:TakeXP(amount)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 ) then return end

        self:SetXP(self:GetXP() - amount)

        hook.Run("PlayerTakeXP", self, amount)
    end

    --- Adds XP to a player
    -- @realm server
    -- @int amount The amount of XP to add to the player
    function PLAYER:AddXP(amount)
        if ( !self.impulseBeenSetup or self.impulseBeenSetup == false ) then return end
        if ( !isnumber(amount) or amount < 0 ) then return end

        self:SetXP(self:GetXP() + amount)

        hook.Run("PlayerGetXP", self, amount)
    end

    --- Gives XP with a message to the player
    -- @realm server
    function PLAYER:GiveTimedXP()
        local amount = impulse.Config.XPGet or 5
        if ( self:IsDonator() ) then
            amount = impulse.Config.XPGetDonator or 10
        end

        self:AddXP(amount)
        self:Notify("You have received " .. amount .. " XP for playing.")
    end
end
