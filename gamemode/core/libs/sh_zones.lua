local PLAYER = FindMetaTable("Player")

function PLAYER:GetZone()
    return self.impulseZone
end

function PLAYER:GetZoneName()
    local data = impulse.Config.Zones[self.impulseZone]
    if self.impulseZone and data and data.name then
        return data.name
    else
        return ""
    end
end

function PLAYER:GetZoneDescription()
    local data = impulse.Config.Zones[self.impulseZone]
    if self.impulseZone and data and data.description then
        return data.description
    else
        return ""
    end
end

function PLAYER:SetZone(id)
    if (self.impulseZone or -1) == id then return end
    self.impulseZone = id

    net.Start("impulseZoneUpdate")
    net.WriteUInt(id, 8)
    net.Send(self)

    hook.Run("PlayerZoneChanged", self, id)
end
