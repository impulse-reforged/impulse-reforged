--[[
    Changelog Viewer - A unique sliding panel for displaying game updates
    Features: Smooth animations, categorized changes, version timeline
]]--

local PANEL = {}
local gradient = Material("vgui/gradient-u")

-- Category icons mapping
local categoryIcons = {
    ["Added"] = "impulse-reforged/icons/impulse2/plus-circle.png",
    ["Fixed"] = "impulse-reforged/icons/impulse2/wrench.png",
    ["Changed"] = "impulse-reforged/icons/impulse2/pencil.png",
    ["Removed"] = "impulse-reforged/icons/impulse2/trash.png",
    ["Balance"] = "impulse-reforged/icons/impulse2/bar-chart-alt-2.png",
    ["Content"] = "impulse-reforged/icons/impulse2/image.png",
}

-- Category colors
local categoryColors = {
    ["Added"] = Color(50, 200, 50),
    ["Fixed"] = Color(255, 165, 0),
    ["Changed"] = Color(100, 149, 237),
    ["Removed"] = Color(220, 50, 50),
    ["Balance"] = Color(255, 215, 0),
    ["Content"] = Color(147, 112, 219),
}

function PANEL:Init()
    if ( IsValid(impulse.ChangelogViewer) ) then
        impulse.ChangelogViewer:Remove()
    end

    impulse.ChangelogViewer = self

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    -- Start off-screen
    self.targetX = ScrW() * 0.25
    self.panelWidth = ScrW() * 0.75

    self:SetAlpha(0)
    self:AlphaTo(255, 0.2, 0)

    -- Background blur effect
    self.blurAlpha = 0

    -- Main content panel (slides in from right)
    self.content = self:Add("DPanel")
    self.content:SetSize(self.panelWidth, ScrH())
    self.content:SetPos(ScrW(), 0)

    self.content.Paint = function(this, width, height)
        surface.SetDrawColor(20, 20, 20, 190)
        surface.DrawRect(0, 0, width, height)
    end

    -- Header
    self.header = self.content:Add("DPanel")
    self.header:Dock(TOP)
    self.header:SetTall(120)
    self.header.Paint = function(this, width, height)
        surface.SetDrawColor(20, 20, 20, 190)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, width, height)
    end

    -- Close button
    local closeBtn = self.header:Add("DButton")
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(20, self.header:GetTall() / 2 - closeBtn:GetTall() / 2)
    closeBtn:SetText("")
    closeBtn.Paint = function(this, width, height)
        local col = this:IsHovered() and Color(220, 50, 50) or Color(100, 100, 100)
        draw.NoTexture()
        surface.SetDrawColor(col)

        local margin = 8
        surface.DrawLine(margin, margin, width - margin, height - margin)
        surface.DrawLine(width - margin, margin, margin, height - margin)
    end
    closeBtn.DoClick = function()
        self:Close()
    end
    closeBtn.OnCursorEntered = function()
        surface.PlaySound("ui/buttonrollover.wav")
    end

    -- Version title
    self.versionLabel = self.header:Add("DLabel")
    self.versionLabel:SetFont("Impulse-Elements48")
    self.versionLabel:SetText("Version 0.0")
    self.versionLabel:SizeToContents()
    self.versionLabel:SetPos(80, self.header:GetTall() / 2 - self.versionLabel:GetTall() / 2)
    self.versionLabel:SetTextColor(color_white)

    -- Update title
    self.titleLabel = self.header:Add("DLabel")
    self.titleLabel:SetFont("Impulse-Elements24")
    self.titleLabel:SetText("Loading...")
    self.titleLabel:SizeToContents()
    self.titleLabel:SetX(self.versionLabel:GetX() + self.versionLabel:GetWide() - self.titleLabel:GetWide() * 2)
    self.titleLabel:SetY(self.header:GetTall() / 2 + self.versionLabel:GetTall() / 2 - 5)
    self.titleLabel:SetTextColor(Color(200, 200, 200))

    -- Scrollable content area
    self.scroll = self.content:Add("DScrollPanel")
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(20, 0, 20, 0)

    local sbar = self.scroll:GetVBar()
    sbar:SetWide(8)
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
    end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, impulse.Config.MainColour)
    end

    -- Animate panel in
    timer.Simple(0.05, function()
        if ( !IsValid(self) ) then return end
        self.content:MoveTo(self.targetX, 0, 0.3, 0, -1)
        self.blurAlpha = 200
    end)
end

function PANEL:CategorizeChanges(changes)
    local categorized = {
        ["Added"] = {},
        ["Fixed"] = {},
        ["Changed"] = {},
        ["Removed"] = {},
        ["Balance"] = {},
        ["Content"] = {}
    }

    for _, change in ipairs(changes) do
        local lower = string.lower(change)

        if ( string.find(lower, "^added") or string.find(lower, "^new") ) then
            table.insert(categorized["Added"], change)
        elseif ( string.find(lower, "^fixed") or string.find(lower, "^resolved") ) then
            table.insert(categorized["Fixed"], change)
        elseif ( string.find(lower, "^removed") or string.find(lower, "^deleted") ) then
            table.insert(categorized["Removed"], change)
        elseif ( string.find(lower, "^balanced") or string.find(lower, "^adjusted") ) then
            table.insert(categorized["Balance"], change)
        elseif ( string.find(lower, "^improved") or string.find(lower, "^refactored") or string.find(lower, "^updated") ) then
            table.insert(categorized["Changed"], change)
        else
            -- Default to Changed for unlabeled items
            table.insert(categorized["Changed"], change)
        end
    end

    return categorized
end

function PANEL:SetChangelogData(data)
    self.data = data

    -- Set version and title
    self.versionLabel:SetText("Version " .. (data.Version or "Unknown"))
    self.versionLabel:SizeToContents()

    self.titleLabel:SetText(data.Title or "Update")
    self.titleLabel:SizeToContents()

    -- Add description section if exists
    if ( data.Description and data.Description != "" ) then
        local descPanel = self.scroll:Add("DPanel")
        descPanel:Dock(TOP)
        descPanel:DockMargin(0, 10, 15, 20)
        descPanel:SetSize(self.content:GetWide() - 60, 100)
        descPanel.Paint = function(this, width, height)
            draw.RoundedBox(8, 0, 0, width, height, Color(25, 25, 25, 200))

            -- Subtle left border
            surface.SetDrawColor(impulse.Config.MainColour.r, impulse.Config.MainColour.g, impulse.Config.MainColour.b, 100)
            surface.DrawRect(0, 0, 4, height)
        end

        local descLabel = descPanel:Add("DLabel")
        descLabel:SetPos(20, 15)
        descLabel:SetFont("Impulse-Elements18")
        descLabel:SetText(data.Description)
        descLabel:SetWrap(true)
        descLabel:SetAutoStretchVertical(true)
        descLabel:SetWide(descPanel:GetWide() - 40)
        descLabel:SetTextColor(Color(220, 220, 220))

        timer.Simple(0, function()
            if ( !IsValid(descPanel) ) then return end
            descPanel:SetTall(descLabel:GetTall() + 30)
        end)
    end

    -- Add changelog categories
    if ( data.Changes ) then
        -- Check if Changes is a categorized table or a flat array
        if ( #data.Changes > 0 ) then
            -- Flat array - auto-categorize by keywords
            local categorized = self:CategorizeChanges(data.Changes)
            for category, changes in SortedPairs(categorized) do
                if ( #changes > 0 ) then
                    self:AddCategory(category, changes)
                end
            end
        else
            -- Already categorized
            for category, changes in SortedPairs(data.Changes) do
                if ( #changes > 0 ) then
                    self:AddCategory(category, changes)
                end
            end
        end
    end
end

function PANEL:AddCategory(categoryName, changes)
    local categoryPanel = self.scroll:Add("DPanel")
    categoryPanel:Dock(TOP)
    categoryPanel:DockMargin(0, 0, 15, 15)
    categoryPanel.Paint = nil

    -- Category header
    local header = categoryPanel:Add("DPanel")
    header:Dock(TOP)
    header:SetSize(self.content:GetWide() - 60, 40)
    header.Paint = function(this, width, height)
        draw.RoundedBox(8, 0, 0, width, height, Color(30, 30, 30, 230))

        -- Colored left accent
        local col = categoryColors[categoryName] or impulse.Config.MainColour
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, 5, height)
    end

    -- Category icon
    local icon = header:Add("DImage")
    icon:SetPos(15, 10)
    icon:SetSize(20, 20)
    icon:SetImage(categoryIcons[categoryName] or "icon16/information.png")
    icon:SetImageColor(categoryColors[categoryName] or impulse.Config.MainColour)

    -- Category title
    local title = header:Add("DLabel")
    title:SetPos(45, 10)
    title:SetFont("Impulse-Elements24")
    title:SetText(categoryName)
    title:SizeToContents()
    title:SetTextColor(categoryColors[categoryName] or impulse.Config.MainColour)

    -- Count badge
    local countBadge = header:Add("DPanel")
    countBadge:SetPos(header:GetWide() - 50, 10)
    countBadge:SetSize(35, 20)
    countBadge.Paint = function(this, width, height)
        local col = categoryColors[categoryName] or impulse.Config.MainColour
        draw.RoundedBox(10, 0, 0, width, height, Color(col.r, col.g, col.b, 50))

        draw.SimpleText(#changes, "Impulse-Elements14", width / 2, height / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Changes list
    local listPanel = categoryPanel:Add("DPanel")
    listPanel:Dock(TOP)
    listPanel:DockMargin(10, 5, 10, 0)
    listPanel:SetWide(self.content:GetWide() - 80)
    listPanel.Paint = nil

    local totalHeight = 0
    for i, change in ipairs(changes) do
        local changeEntry = listPanel:Add("DPanel")
        changeEntry:Dock(TOP)
        changeEntry:DockMargin(0, 2, 0, 2)
        changeEntry.Paint = function(this, width, height)
            if ( this:IsHovered() ) then
                draw.RoundedBox(6, 0, 0, width, height, Color(40, 40, 40, 200))
            else
                draw.RoundedBox(6, 0, 0, width, height, Color(20, 20, 20, 190))
            end
        end

        -- Bullet point
        local bullet = changeEntry:Add("DPanel")
        bullet:SetPos(15, 13)
        bullet:SetSize(6, 6)
        bullet.Paint = function(this, width, height)
            local col = categoryColors[categoryName] or impulse.Config.MainColour
            draw.RoundedBox(3, 0, 0, width, height, col)
        end

        -- Change text
        local changeLabel = changeEntry:Add("DLabel")
        changeLabel:SetPos(35, 8)
        changeLabel:SetFont("Impulse-Elements18")
        changeLabel:SetText(change)
        changeLabel:SetWrap(true)
        changeLabel:SetAutoStretchVertical(true)
        changeLabel:SetWide(listPanel:GetWide() - 50)
        changeLabel:SetTextColor(Color(230, 230, 230))

        timer.Simple(0, function()
            if ( !IsValid(changeEntry) ) then return end
            changeEntry:SetTall(changeLabel:GetTall() + 16)
            totalHeight = totalHeight + changeEntry:GetTall() + 4
        end)
    end

    timer.Simple(0.01, function()
        if ( !IsValid(listPanel) ) then return end
        listPanel:SetTall(totalHeight)
        categoryPanel:SetTall(header:GetTall() + listPanel:GetTall() + 10)
    end)
end

function PANEL:Close()
    surface.PlaySound("ui/buttonclickrelease.wav")

    self.content:MoveTo(ScrW(), 0, 0.25, 0, -1, function()
        if ( IsValid(self) ) then
            self:Remove()
        end
    end)

    self:AlphaTo(0, 0.25, 0)
    self.blurAlpha = 0
end

function PANEL:Paint(width, height)
    -- Blur background
    if ( self.blurAlpha > 0 ) then
        impulse.Util:DrawBlurAt(0, 0, width, height, (self.blurAlpha / 200) * 5)

        -- Dark overlay
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, width, height)
    end
end

function PANEL:OnMousePressed()
    -- Click outside to close
    local x, _ = self:CursorPos()
    if ( x < self.targetX ) then
        self:Close()
    end
end

vgui.Register("impulseChangelogViewer", PANEL, "EditablePanel")
