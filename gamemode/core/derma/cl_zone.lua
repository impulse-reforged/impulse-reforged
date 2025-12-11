local PANEL = {}

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW() / 2, 50)
    self:AlphaTo(255, 3, 0, function() self:AlphaTo(0, 3, 4, function() self:Remove() end) end)
end

function PANEL:Think()
    if self.Zone != LocalPlayer():GetZoneName() then
        self.Zone = LocalPlayer():GetZoneName()
    end

    if self.ZoneDescription != (hook.Run("GetZoneDescription", self.Zone) or LocalPlayer():GetZoneDescription()) then
        self.ZoneDescription = hook.Run("GetZoneDescription", self.Zone) or LocalPlayer():GetZoneDescription()
    end

    if !LocalPlayer():Alive() then
        return self:Remove()
    end

    if !impulse.HUDEnabled then
        return self:Remove()
    end

    local x = hook.Run("ShouldDrawHUDBox")
    if x != nil and x == false then
        return self:Remove()
    end

    if impulse.chatBox and IsValid(impulse.chatBox.chatLog) and impulse.chatBox.chatLog.active then
        return self:Remove()
    end
end

function PANEL:Paint(w,h)
    if self.Zone and self.Zone != "" then
        draw.DrawText(self.Zone, "Impulse-Elements23-Italic", 0, 0, color_white, TEXT_ALIGN_LEFT)
    end

    local zoneDescription = hook.Run("GetZoneDescription", self.Zone) or self.ZoneDescription
    if zoneDescription and zoneDescription != "" then
        draw.DrawText(zoneDescription, "Impulse-Elements18", 0, 23, ColorAlpha(color_white, 100), TEXT_ALIGN_LEFT)
    end
end

vgui.Register("impulseZoneLabel", PANEL, "DPanel")
