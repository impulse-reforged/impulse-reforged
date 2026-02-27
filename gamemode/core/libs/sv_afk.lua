local PLAYER = FindMetaTable("Player")

function PLAYER:MakeAFK()
    if self.impulseAFKImmune then return end

    self.impulseAFKState = true

    local playercount = player.GetCount()
    local maxcount = impulse.Config.UserSlots or game.MaxPlayers()
    local limit = (impulse.Config.AFKKickRatio or 0.8) * maxcount

    if playercount >= limit and (impulse.Ops.EventManager.GetEventMode() or !self:IsDonator()) then
        if self:IsAdmin() then return end

        self:Kick("You have been kicked for inactivity on a busy server. See you again soon!")
        return
    end

    self:Notify("Due to inactivity, you have been marked as AFK. You may be demoted from your current team.")

    if !self:IsAdmin() and self:Team() != impulse.Config.DefaultTeam then
        self:SetTeam(impulse.Config.DefaultTeam, true)
    end
end

function PLAYER:UnMakeAFK()
    self.impulseAFKState = false
    self:Notify("You are no longer marked as AFK.")
end

function PLAYER:IsAFK()
    return self.impulseAFKState or false
end
