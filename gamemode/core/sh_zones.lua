function meta:GetZone()
    return self.impulseZone
end

function meta:GetZoneName()
    local data = impulse.Config.Zones[self.impulseZone]
    if self.impulseZone and data.name then
        return data.name
    else
        return ""
    end
end

function meta:GetZoneDescription()
    local data = impulse.Config.Zones[self.impulseZone]
    if self.impulseZone and data.description then
        return data.description
    else
        return ""
    end
end

function meta:SetZone(id)
    if (self.impulseZone or -1) == id then return end
    self.impulseZone = id

    net.Start("impulseZoneUpdate")
    net.WriteUInt(id, 8)
    net.Send(self)

    hook.Run("PlayerZoneChanged", self, id)
end