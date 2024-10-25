--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Entity")

--- Sends a chat message to the player
-- @realm shared
-- @tab package Chat message package
-- @usage ply:AddChatText(Color(255, 0, 0), "Hello, ", Color(0, 255, 0), "world!")
function PLAYER:AddChatText(...)
    local package = {...}
    
    if ( SERVER ) then
        net.Start("impulseChatText")
            net.WriteTable(package)
        net.Send(self)
    else
        chat.AddText(unpack(package))
    end
end

--- Plays a sound on the player's client
-- @realm shared
-- @string sound Sound path
-- @usage ply:SurfacePlaySound("ambient/levels/labs/electric_explosion1.wav")
function PLAYER:SurfacePlaySound(sound)
    if ( SERVER ) then
        net.Start("impulseSurfaceSound")
            net.WriteString(sound)
        net.Send(self)
    else
        surface.PlaySound(sound)
    end
end

--- Returns if a player is an impulse framework developer
-- @realm shared
-- @treturn bool Is developer
function PLAYER:IsDeveloper()
    return hook.Run("PlayerIsDeveloper", self)
end

--- Returns if a player has donator status
-- @realm shared
-- @treturn bool Is donator
function PLAYER:IsDonator()
    return ( self:IsUserGroup("donator") or self:IsAdmin() ) or hook.Run("PlayerIsDonator", self)
end

local adminGroups = {
    ["admin"] = true,
    ["leadadmin"] = true,
    ["communitymanager"] = true
}

--- Returns if a player is an admin
-- @realm shared
-- @treturn bool Is admin
function PLAYER:IsAdmin()
    if ( self.IsSuperAdmin(self) ) then
        return true
    end

    if ( adminGroups[self.GetUserGroup(self)] ) then
        return true
    end

    if ( hook.Run("PlayerIsAdmin", self) ) then
        return true
    end

    return false
end

local leadAdminGroups = {
    ["leadadmin"] = true,
    ["communitymanager"] = true
}

--- Returns if a player is a lead admin
-- @realm shared
-- @treturn bool Is lead admin
function PLAYER:IsLeadAdmin()
    if ( self.IsSuperAdmin(self) ) then
        return true
    end

    if ( leadAdminGroups[self.GetUserGroup(self)] ) then
        return true
    end

    if ( hook.Run("PlayerIsLeadAdmin", self) ) then
        return true
    end

    return false
end

--- Returns if a player is a super admin
-- @realm shared
-- @treturn bool Is super admin
function PLAYER:IsSuperAdmin()
    if ( self.GetUserGroup(self) == "superadmin" ) then
        return true
    end

    if ( hook.Run("PlayerIsSuperAdmin", self) ) then
        return true
    end

    return false
end

--- Returns if a player is in the spawn zone
-- @realm shared
-- @treturn bool Is in spawn
function PLAYER:InSpawn()
    if ( hook.Run("PlayerIsInSpawn", self) ) then
        return true
    end

    if ( !impulse.Config.SpawnPos1 or !impulse.Config.SpawnPos2 ) then
        return false
    end

    return self:GetPos():WithinAABox(impulse.Config.SpawnPos1, impulse.Config.SpawnPos2)
end

--- Returns if the player has a female character
-- @realm shared
-- @treturn bool Is female
function PLAYER:IsCharacterFemale()
    if ( SERVER ) then
        return self:IsFemale(self.defaultModel)
    else
        return self:IsFemale(impulse_defaultModel)
    end
end

local notices = notices or {}

local function OrganizeNotices(i)
    local scrW = ScrW()
    local lastHeight = ScrH() - 100

    for k, v in ipairs(notices) do
        local height = lastHeight - v:GetTall() - 10
        v:MoveTo(scrW - (v:GetWide()), height, 0.15, (k / #notices) * 0.25, nil)
        lastHeight = height
    end
end

--- Sends a notification to a player
-- @realm shared
-- @string message The notification message
function PLAYER:Notify(message)
    if ( CLIENT ) then
        if ( !impulse.HUDEnabled ) then
            return MsgN(message)
        end

        local notice = vgui.Create("impulseNotify")
        local i = table.insert(notices, notice)

        notice:SetMessage(message)
        notice:SetPos(ScrW(), ScrH() - (i - 1) * (notice:GetTall() + 4) + 4) -- needs to be recoded to support variable heights
        notice:MoveToFront()
        OrganizeNotices(i)

        timer.Simple(7.5, function()
            if ( !IsValid(notice) ) then return end

            notice:AlphaTo(0, 1, 0, function()
                notice:Remove()

                for k, v in pairs(notices) do
                    if ( v == notice ) then
                        table.remove(notices, k)
                    end
                end

                OrganizeNotices(i)
            end)
        end)

        MsgN(message)
    else
        net.Start("impulseNotify")
            net.WriteString(message)
        net.Send(self)
    end
end

--- Returns a player's hunger level
-- @realm shared
-- @treturn number Hunger level
function PLAYER:GetHunger()
    return self:GetSyncVar(SYNC_HUNGER, 0)
end

--- Returns whether a player is running or not
-- @realm shared
-- @treturn bool Is running
function PLAYER:IsRunning()
    local velocity = self:GetVelocity():Length2D()
    return self:GetWalkSpeed() < velocity and self:KeyDown(IN_SPEED)
end

--- Returns whether a player is stuck or not
-- @realm shared
-- @treturn bool Is stuck
function PLAYER:IsStuck()
    return util.TraceEntity({
        start = self:GetPos(),
        endpos = self:GetPos(),
        filter = self
    }, self).StartSolid
end