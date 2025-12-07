local PANEL = {}

function PANEL:Init()
    self.Colour = Color(60, 255, 105, 150)
    self.Name = "Connecting..."
    self.Ping = 0

    -- Dynamic height based on two text rows + margins; avoids magic numbers.
    local rowH = ScreenScaleH(8) -- scalable row height
    local verticalMargin = ScreenScaleH(4)
    self:SetTall(rowH * 2 + verticalMargin * 2)

    self:SetCursor("hand")
    self:SetTooltip("Left click to open info card. Right click to copy SteamID64.")

    -- Wrapper for text/content (filled later when player is set)
    self.infoWrap = vgui.Create("DPanel", self)
    self.infoWrap:Dock(FILL)
    self.infoWrap:DockMargin(ScreenScale(2), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))
    self.infoWrap:SetPaintBackground(false)
    self.infoWrap:SetMouseInputEnabled(false)

    -- Top row (name + ping)
    self.topRow = vgui.Create("DPanel", self.infoWrap)
    self.topRow:Dock(TOP)
    self.topRow:SetTall(rowH)
    self.topRow:SetPaintBackground(false)

    self.nameLabel = vgui.Create("DLabel", self.topRow)
    self.nameLabel:Dock(FILL)
    self.nameLabel:SetFont("Impulse-Elements18-Shadow")
    self.nameLabel:SetTextColor(color_white)
    self.nameLabel:SetContentAlignment(4) -- left middle
    self.nameLabel:SetText(self.Name)

    self.pingLabel = vgui.Create("DLabel", self.topRow)
    self.pingLabel:Dock(RIGHT)
    self.pingLabel:SetWide(ScreenScaleH(30))
    self.pingLabel:SetFont("Impulse-Elements18-Shadow")
    self.pingLabel:SetTextColor(color_white)
    self.pingLabel:SetContentAlignment(6) -- right middle
    self.pingLabel:SetText(self.Ping)

    -- Bottom row (team name + badges on right)
    self.bottomRow = vgui.Create("DPanel", self.infoWrap)
    self.bottomRow:Dock(TOP)
    self.bottomRow:SetTall(rowH)
    self.bottomRow:SetPaintBackground(false)

    self.teamLabel = vgui.Create("DLabel", self.bottomRow)
    self.teamLabel:Dock(FILL)
    self.teamLabel:SetFont("Impulse-Elements18-Shadow")
    self.teamLabel:SetTextColor(color_white)
    self.teamLabel:SetContentAlignment(4)
    self.teamLabel:SetText("")

    self.badgeWrap = vgui.Create("DPanel", self.bottomRow)
    self.badgeWrap:Dock(RIGHT)
    self.badgeWrap:SetWide(ScreenScaleH(80)) -- scalable area for badges
    self.badgeWrap:SetPaintBackground(false)
    self.badgeWrap.PerformLayout = function(s)
        -- Reflow badge icons horizontally with small padding
        local x = s:GetWide()
        for _, child in ipairs(s:GetChildren()) do
            child:SetPos(x - child:GetWide(), (s:GetTall() - child:GetTall()) * 0.25)
            x = x - child:GetWide() - ScreenScaleH(2)
        end
    end

    -- Timing helpers for dynamic updates
    self.nextPingUpdate = 0
    self.nextNameUpdate = 0
    self.nextTeamUpdate = 0
end

function PANEL:SetPlayer(player)
    self.Colour = team.GetColor(player:Team())
    self.Name = player:Nick()
    self.Player = player
    self.Badges = {}

    for v, k in pairs(impulse.Badges) do
        if ( k[3](player) ) then
            self.Badges[v] = k
        end
    end

    -- Avatar / model icon
    if ( IsValid(self.modelIcon) ) then self.modelIcon:Remove() end

    self.modelIcon = vgui.Create("impulseSpawnIcon", self)
    self.modelIcon:Dock(LEFT)
    self.modelIcon:SetWide(self:GetTall())
    self.modelIcon:SetModel(player:GetModel(), player:GetSkin())
    self.modelIcon:SetMouseInputEnabled(false)

    timer.Simple(0, function()
        if ( !IsValid(self) ) then return end

        local ent = self.modelIcon and self.modelIcon.Entity
        if ( IsValid(ent) and IsValid(self.Player) ) then
            for _, k in pairs(self.Player:GetBodyGroups()) do
                ent:SetBodygroup(k.id, self.Player:GetBodygroup(k.id))
            end
        end
    end)

    function self.modelIcon:PaintOver()
        return false
    end

    self:RefreshText()
    self:RefreshBadges()
end

function PANEL:GetDisplayName()
    if ( !IsValid(self.Player) ) then return self.Name end

    local icName = ""
    if ( LocalPlayer():IsAdmin() ) then
        icName = " (" .. self.Player:Name() .. ")"
        local rpGroup = self.Player:GetRelay("groupName", nil)
        if ( impulse.Settings:Get("admin_showgroup") and rpGroup ) then
            icName = icName .. " (" .. rpGroup .. ")"
        end
    end

    return self.Player:SteamName() .. icName
end

function PANEL:RefreshText()
    if ( !IsValid(self.Player) ) then return end

    self.nameLabel:SetText(self:GetDisplayName())
    self.pingLabel:SetText(self.Player:Ping())

    -- Build team text with class and rank
    local teamText = team.GetName(self.Player:Team())
    local className = self.Player:GetTeamClassName()
    local rankName = self.Player:GetTeamRankName()

    if ( className and className != "" ) then
        teamText = teamText .. ", " .. className
    end

    if ( rankName and rankName != "" ) then
        teamText = teamText .. ", " .. rankName
    end

    self.teamLabel:SetText(teamText)
    self.Colour = team.GetColor(self.Player:Team())
end

function PANEL:RefreshBadges()
    if ( !IsValid(self.badgeWrap) ) then return end

    -- Clear previous
    for _, child in ipairs(self.badgeWrap:GetChildren()) do child:Remove() end

    for badgeName, badgeData in pairs(self.Badges) do
        local icon = vgui.Create("DImageButton", self.badgeWrap)
        icon:SetMaterial(badgeData[1])
        icon:SetSize(16, 16)
        icon:SetTooltip(badgeName)
        icon:SetMouseInputEnabled(true)
        icon.DoClick = function()
            local info = badgeData[2] or "No additional information available."
            Derma_Message(info, "impulse", "Close")
        end
    end

    self.badgeWrap:InvalidateLayout(true)
end

function PANEL:Think()
    if ( !IsValid(self.Player) ) then return end

    local ct = CurTime()
    if ( ct > self.nextPingUpdate ) then
        self.pingLabel:SetText(self.Player:Ping())
        self.nextPingUpdate = ct + 1 -- update ping every second
    end

    if ( ct > self.nextTeamUpdate ) then
        -- Build team text with class and rank
        local teamText = team.GetName(self.Player:Team())
        local className = self.Player:GetTeamClassName()
        local rankName = self.Player:GetTeamRankName()

        if className and className != "" then
            teamText = teamText .. ", " .. className
        end

        if rankName and rankName != "" then
            teamText = teamText .. ", " .. rankName
        end

        self.teamLabel:SetText(teamText)
        self.Colour = team.GetColor(self.Player:Team())
        self.nextTeamUpdate = ct + 2
    end

    if ( ct > self.nextNameUpdate ) then
        self.nameLabel:SetText(self:GetDisplayName())
        self.nextNameUpdate = ct + 5
    end
end

local gradient = Material("vgui/gradient-l")
local gradientr = Material("vgui/gradient-r")
local outlineCol = Color(190,190,190,240)
local darkCol = Color(30,30,30,200)

function PANEL:Paint(width,height)
    if ( !IsValid(self.Player) ) then return end

    -- Background gradient layers (retain original visual style)
    surface.SetDrawColor(self.Colour)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(1,1,width-1,height-2)

    if ( self.Player == LocalPlayer() or self.Player:GetFriendStatus() == "friend" ) then
        surface.SetDrawColor(ColorAlpha(color_white, (50 + math.sin(RealTime() * 2) * 50) * .4))
        surface.SetMaterial(gradientr)
        surface.DrawTexturedRect(width * 0.6, 1, width * 0.4 - 1, height - 1) -- proportional instead of magic number
    end

    surface.SetMaterial(gradient)
    surface.SetDrawColor(darkCol)
    surface.DrawTexturedRect(1,1,width-1,height-2)
end

function PANEL:PaintOver(width, height)
    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(0, 0, width, height)
end

function PANEL:OnMousePressed(key)
    if ( !IsValid(self.Player) ) then return false end

    if ( key == MOUSE_RIGHT ) then
        LocalPlayer():Notify("You have copied " .. self.Player:SteamName() .. "'s Steam ID.")
        SetClipboardText(self.Player:SteamID64())
    else
        if ( impulse_infoCard and IsValid(impulse_infoCard) ) then
            impulse_infoCard:Remove()
        end

        impulse_infoCard = vgui.Create("impulsePlayerInfoCard")
        impulse_infoCard:SetPlayer(self.Player, self.Badges)
    end
end

vgui.Register("impulseScoreboardCard", PANEL, "DPanel")
