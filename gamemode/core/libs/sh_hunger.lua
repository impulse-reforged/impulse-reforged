--- Helper functions for the players hunger
-- @module impulse.Hunger

local PLAYER = FindMetaTable("Player")

if SERVER then
    --- Set the hunger amount of a player
    -- @realm server
    -- @int amount Amount of hunger (0-100)
    function PLAYER:SetHunger(amount)
        self:SetLocalSyncVar(SYNC_HUNGER, math.Clamp(amount, 0, 100))
    end

    --- Gives the player the amount of hunger
    -- @realm server
    -- @int amount Amount of hunger (0-100)
    function PLAYER:FeedHunger(amount)
        self:SetHunger(amount + self:GetSyncVar(SYNC_HUNGER, 100))
    end
end