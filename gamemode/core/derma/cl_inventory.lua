local PANEL = {}

function PANEL:Init()
    impulse.InventoryMenu = self

    local width, height = ScrW() / 1.25, ScrH() / 1.25

    self:SetSize(width, height)
    self:Center()
    self:CenterHorizontal()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MoveToFront()
    self:SetKeyboardInputEnabled(false)

    local model = LocalPlayer():GetModel()
    local skin = LocalPlayer():GetSkin()

    self.modelPreview = vgui.Create("impulseModelPanel", self)
    self.modelPreview:Dock(LEFT)
    self.modelPreview:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), 0)
    self.modelPreview:SetWide(self:GetWide() / 4)
    self.modelPreview:SetModel(model, skin)
    self.modelPreview:MoveToBack()
    self.modelPreview:SetCursor("arrow")

    self.modelPreview:SetFOV(self:GetWide() / self:GetTall() * 20)
    self.modelPreview.copyLocalSequence = true

    self.infoName = vgui.Create("DLabel", self.modelPreview)
    self.infoName:Dock(TOP)
    self.infoName:SetText(LocalPlayer():Nick())
    self.infoName:SetFont("Impulse-Elements24-Shadow")
    self.infoName:SizeToContents()

    if self.infoName:GetWide() > 245 then
        self.infoName:SetFont("Impulse-Elements19-Shadow")
    end

    local clientTeam = LocalPlayer():Team()
    self.infoTeam = vgui.Create("DLabel", self.modelPreview)
    self.infoTeam:Dock(TOP)
    self.infoTeam:SetText(team.GetName(clientTeam))
    self.infoTeam:SetFont("Impulse-Elements19-Shadow")
    self.infoTeam:SetColor(team.GetColor(clientTeam))
    self.infoTeam:SizeToContents()

    local className = LocalPlayer():GetTeamClassName()
    local rankName = LocalPlayer():GetTeamRankName()

    if ( className != "" ) then
        self.infoClassRank = vgui.Create("DLabel", self.modelPreview)
        self.infoClassRank:Dock(TOP)
        self.infoClassRank:SetFont("Impulse-Elements19-Shadow")
        self.infoClassRank:SetText(className)
        self.infoClassRank:SetColor(team.GetColor(clientTeam))
        self.infoClassRank:SizeToContents()

        if ( rankName and rankName != "" ) then
            self.infoClassRank:SetText(className  ..  " - "  ..  rankName)
        end
    else
        if ( rankName and rankName != "" ) then
            self.infoClassRank = vgui.Create("DLabel", self.modelPreview)
            self.infoClassRank:Dock(TOP)
            self.infoClassRank:SetFont("Impulse-Elements19-Shadow")
            self.infoClassRank:SetText(rankName)
            self.infoClassRank:SetColor(team.GetColor(clientTeam))
            self.infoClassRank:SizeToContents()
        end
    end

    self.tabs = vgui.Create("DPropertySheet", self)
    self.tabs:Dock(FILL)
    self.tabs:DockMargin(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))
    self.tabs.tabScroller:DockMargin(-1, 0, -1, 0)
    self.tabs.tabScroller:SetOverlap(0)
    self.tabs.Paint = nil

    self.tabs:InvalidateParent(true)

    self.invScroll = vgui.Create("DScrollPanel", self.tabs)
    self.invScroll:Dock(FILL)
    self.invScroll:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))

    self.skillScroll = vgui.Create("DScrollPanel", self.tabs)
    self.skillScroll:Dock(FILL)
    self.skillScroll:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))

    self:SetupItems(width, height)
    self:SetupSkills(width, height)

    self.tabs:AddSheet("Inventory", self.invScroll)
    self.tabs:AddSheet("Skills", self.skillScroll)

    hook.Run("ImpulseInventoryOpened", self)
end

function PANEL:SetupItems(width, height)
    -- Use panel dimensions if width/height not provided
    width = width or self:GetWide()
    height = height or self:GetTall()

    if ( IsValid(self.invScroll) ) then
        self.invScroll:Clear()
    end

    self.items = {}
    self.itemsPanels = {}

    local weight = 0
    local localInv = table.Copy(impulse.Inventory.Data[0][INVENTORY_PLAYER]) or {}
    if localInv and table.Count(localInv) > 0 then
        for v, k in pairs(localInv) do
            local itemData = impulse.Inventory.Items[k.id]
            if not itemData then continue end

            local otherItem = self.items[k.id]
            local itemX = itemData

            if itemX.CanStack and otherItem then
                otherItem.Count = (otherItem.Count or 1) + 1
            else
                local item = self.invScroll:Add("impulseInventoryItem")
                item:Dock(TOP)
                item:DockMargin(0, 0, 15, 5)
                item:SetItem(k, width)
                item.InvID = v
                item.InvPanel = self
                self.items[k.id] = item
                self.itemsPanels[v] = item
            end

            weight = weight + (itemX.Weight or 0)
        end
    else
        self.empty = self.invScroll:Add("DLabel", self)
        self.empty:SetContentAlignment(5)
        self.empty:Dock(FILL)
        self.empty:SetText("Empty")
        self.empty:SetFont("Impulse-Elements19-Shadow")
        self.empty:SizeToContents()
    end

    self.invWeight = weight
end

local bodyCol = Color(50, 50, 50, 210)
function PANEL:SetupSkills(width, height)
    -- Use panel dimensions if width/height not provided
    width = width or self:GetWide()
    height = height or self:GetTall()

    if ( IsValid(self.skillScroll) ) then
        self.skillScroll:Clear()
    end

    for v, k in pairs(impulse.Skills.Skills) do
        local skillBg = self.skillScroll:Add("DPanel")
        skillBg:Dock(TOP)
        skillBg:DockMargin(0, 0, 0, ScreenScaleH(4))
        skillBg:SetTall(ScreenScaleH(24))
        skillBg.Skill = v

        local level = LocalPlayer():GetSkillLevel(v)
        local xp = LocalPlayer():GetSkillXP(v)

        function skillBg:Paint(width, height)
            surface.SetDrawColor(bodyCol)
            surface.DrawRect(0, 0, width, height)

            local skill = self.Skill
            local skillName = impulse.Skills.GetNiceName(skill)

            draw.DrawText(skillName .. " - Level " .. level, "Impulse-Elements16-Shadow", ScreenScale(2), ScreenScaleH(2), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.DrawText("Total skill: " .. xp .. "XP", "Impulse-Elements16-Shadow", width - ScreenScale(2), ScreenScaleH(2), color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            return true
        end

        local lastXp = impulse.Skills.GetLevelXPRequirement(level - 1)
        local nextXp = impulse.Skills.GetLevelXPRequirement(level)
        local perc = (xp - lastXp) / (nextXp - lastXp)

        local bar = vgui.Create("DProgress", skillBg)
        bar:Dock(FILL)
        bar:DockMargin(ScreenScale(2), ScreenScaleH(10), ScreenScale(2), ScreenScaleH(2))

        if level == 10 then
            bar:SetFraction(1)
            bar.BarCol = Color(218, 165, 32)
        else
            bar:SetFraction(perc)
        end

        function bar:PaintOver(width, height)
            if level != 10 then
                draw.DrawText(math.Round(perc * 100, 1) .. "% to next level", "Impulse-Elements18-Shadow", width / 2, 10, color_white, TEXT_ALIGN_CENTER)
            else
                draw.DrawText("Mastered", "Impulse-Elements18-Shadow", width / 2, 10, color_white, TEXT_ALIGN_CENTER)
            end

            draw.DrawText(lastXp .. "XP", "Impulse-Elements16-Shadow", 10, 10, color_white)
            draw.DrawText(nextXp .. "XP", "Impulse-Elements16-Shadow", width - 10, 10, color_white, TEXT_ALIGN_RIGHT)
        end
    end
end

function PANEL:FindItemPanelByID(id)
    return self.itemsPanels[id]
end

local grey = Color(209, 209, 209)
function PANEL:PaintOver(width, height)
    draw.SimpleText(self.invWeight .. "kg/" .. impulse.Config.InventoryMaxWeight .. "kg", "Impulse-Elements18-Shadow", width - ScreenScale(6), ScreenScaleH(14), grey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

vgui.Register("impulseInventory", PANEL, "DFrame")

if ( IsValid(impulse.InventoryMenu) ) then
    impulse.InventoryMenu:Remove()
    impulse.InventoryMenu = nil
end
