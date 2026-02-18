local PLAYER = FindMetaTable("Player")

function PLAYER:MakeAFK()
    if ( self:IsAFK() or self:GetRelay("afkImmune", false) or CAMI.PlayerHasAccess(self, "impulse: Bypass AFK") ) then return end

    self:SetRelay("afk", true)

    local playercount = player.GetCount()
    local maxcount = impulse.Config.UserSlots or game.MaxPlayers()
    local limit = impulse.Config.AFKKickRatio * maxcount

    if ( playercount >= limit and !self:IsDonator() ) then
        if ( self:IsAdmin() ) then return end
        self:Kick("You have been kicked for inactivity on a busy server. See you again soon!")
        return
    end

    local message = "You have been marked as AFK due to inactivity."
    if ( !self:IsAdmin() and self:Team() != impulse.Config.DefaultTeam ) then
        self:SetTeam(impulse.Config.DefaultTeam, true)
        message = message .. " And as a result, you have been transferred to the default team."
    end

    self:Notify(message)
end

function PLAYER:UnMakeAFK()
    if ( !self:IsAFK() ) then return end

    self:SetRelay("afk", nil)
    self:Notify("You are no longer marked as AFK.")
end

function PLAYER:IsAFK()
    return self:GetRelay("afk", false)
end
