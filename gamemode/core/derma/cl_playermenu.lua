local PANEL = {}

function PANEL:Init()
    self.padding = ScreenScale(32)

    self:SetSize(ScrW() / 2.5, ScrH() / 1.5)
    self:Center()
    self:SetTitle("Player menu")
    self:MakePopup()

    self.darkOverlay = Color(40, 40, 40, 160)

    self.tabSheet = vgui.Create("DColumnSheet", self)
    self.tabSheet:Dock(FILL)
    self.tabSheet.Navigation:SetWidth(self.padding)

    -- actions
    self.quickActions = vgui.Create("DPanel", self.tabSheet)
    self.quickActions:Dock(FILL)
    function self.quickActions:Paint(width, height)
        return true
    end

    -- teams
    self.teams = vgui.Create("DPanel", self.tabSheet)
    self.teams:Dock(FILL)
    function self.teams:Paint(width, height)
        return true
    end

    -- business
    self.business = vgui.Create("DPanel", self.tabSheet)
    self.business:Dock(FILL)
    function self.business:Paint()
        return true
    end

    -- info
    self.info = vgui.Create("DPanel", self.tabSheet)
    self.info:Dock(FILL)
    function self.info:Paint(width, height)
        return true
    end

    local defaultButton = self:AddSheet("Actions", Material("impulse-reforged/icons/banknotes-256.png"), self.quickActions, self.QuickActions)
    self:AddSheet("Teams", Material("impulse-reforged/icons/group-256.png"), self.teams, self.Teams)
    self:AddSheet("Business", Material("impulse-reforged/icons/cart-73-256.png"), self.business, self.Business)
    self:AddSheet("Information", Material("impulse-reforged/icons/info-256.png"), self.info, self.Info)

    self.tabSheet:SetActiveButton(defaultButton)
    defaultButton.loaded = true

    self:QuickActions()
    self.tabSheet.ActiveButton.Target:SetVisible(true)
    self.tabSheet.Content:InvalidateLayout()
end

function PANEL:QuickActions()
    self.quickActionsInner = vgui.Create("DPanel", self.quickActions)
    self.quickActionsInner:Dock(FILL)

    self.quickActionsInner.Paint = function(_, width, height)
        surface.SetDrawColor(self.darkOverlay)
        surface.DrawRect(0, 0, width, height)
        return true
    end

    self.collapsableOptions = vgui.Create("DCollapsibleCategory", self.quickActionsInner)
    self.collapsableOptions:SetLabel("Actions")
    self.collapsableOptions:Dock(TOP)

    local colInv = Color(0, 0, 0, 0)
    self.collapsableOptions.Paint = function(this, width, height)
        this:SetBGColor(colInv)
    end

    -- allowing them to accordion causes bugs
    self.collapsableOptions.Toggle = function(this) return end

    self.collapsableOptionsScroll = vgui.Create("DScrollPanel", self.collapsableOptions)
    self.collapsableOptionsScroll:Dock(FILL)
    self.collapsableOptions:SetContents(self.collapsableOptionsScroll)

    self.list = vgui.Create("DIconLayout", self.collapsableOptionsScroll)
    self.list:Dock(FILL)
    self.list:SetSpaceY(5)
    self.list:SetSpaceX(5)

    local btn = self.list:Add("DButton")
    btn:Dock(TOP)
    btn:SetText("Drop money")
    function btn:DoClick()
        Derma_StringRequest("impulse", "Enter amount of money to drop:", nil, function(amount)
            LocalPlayer():ConCommand("say /dropmoney " .. amount)
        end)
    end

    btn = self.list:Add("DButton")
    btn:Dock(TOP)
    btn:SetText("Write a letter")
    function btn:DoClick()
        Derma_StringRequest("impulse", "Write letter content:", nil, function(text)
            LocalPlayer():ConCommand("say /write " .. text)
        end)
    end

    btn = self.list:Add("DButton")
    btn:Dock(TOP)
    btn:SetText("Change RP name (requires " .. impulse.Config.CurrencyPrefix .. impulse.Config.RPNameChangePrice .. ")")
    function btn:DoClick()
        Derma_StringRequest("impulse", "Enter your new RP name:", nil, function(text)
            net.Start("impulseChangeRPName")
            net.WriteString(text)
            net.SendToServer()
        end)
    end

    btn = self.list:Add("DButton")
    btn:Dock(TOP)
    btn:SetText("Sell all doors")
    function btn:DoClick()
        net.Start("impulseSellAllDoors")
        net.SendToServer()
    end

    self.collapsableOptions = vgui.Create("DCollapsibleCategory", self.quickActionsInner)
    self.collapsableOptions:SetLabel(team.GetName(LocalPlayer():Team()) .. " options")
    self.collapsableOptions:Dock(TOP)
    local colTeam = team.GetColor(LocalPlayer():Team())
    function self.collapsableOptions:Paint(width, height)
        surface.SetDrawColor(colTeam)
        surface.DrawRect(0, 0, width, 20)
        self:SetBGColor(colInv)
    end

    function self.collapsableOptions:Toggle() -- allowing them to accordion causes bugs
        return
    end

    self.collapsableOptionsScroll = vgui.Create("DScrollPanel", self.collapsableOptions)
    self.collapsableOptionsScroll:Dock(FILL)
    self.collapsableOptions:SetContents(self.collapsableOptionsScroll)

    self.list = vgui.Create("DIconLayout", self.collapsableOptionsScroll)
    self.list:Dock(FILL)
    self.list:SetSpaceY(5)
    self.list:SetSpaceX(5)

    local classes = impulse.Teams.Stored[LocalPlayer():Team()].classes
    if classes and LocalPlayer():InSpawn() then
        for v,classData in pairs(classes) do
            if !classData.noMenu and LocalPlayer():GetTeamClass() != v then
                local btn = self.list:Add("DButton")
                btn:Dock(TOP)
                btn.classID = v

                local btnText = "Become " .. classData.name
                if classData.xp then
                    btnText = btnText .. " (" .. classData.xp .. "XP)"
                end
                btn:SetText("Become " .. classData.name .. " (" .. classData.xp .. "XP)")

                btn.DoClick = function(this)
                    net.Start("impulseClassChange")
                        net.WriteUInt(this.classID, 8)
                    net.SendToServer()
                end
            end
        end
    end
end

function PANEL:Teams()
    self.teamsInner = vgui.Create("DScrollPanel", self.teams)
    self.teamsInner:Dock(LEFT)
    self.teamsInner:SetWide(self:GetWide() / 2)
    self.teamsInner.Paint = function(this, width, height)
        surface.SetDrawColor(self.darkOverlay)
        surface.DrawRect(0, 0, width, height)
    end

    self.modelPreview = vgui.Create("DModelPanel", self.teams)
    self.modelPreview:Dock(TOP)
    self.modelPreview:SetTall(self:GetTall() / 2)
    self.modelPreview:SetCursor("arrow")
    self.modelPreview:SetFOV(self.modelPreview:GetFOV() - 19)
    self.modelPreview.LayoutEntity = function(this, ent)
        ent:SetAngles(Angle(0, 45 + math.sin(CurTime()) * 45 / 2, 0))
        --ent:SetSequence(ACT_IDLE)
        --self:RunAnimation()
    end

    self.descLbl = vgui.Create("DLabel", self.teams)
    self.descLbl:Dock(TOP)
    self.descLbl:DockMargin(ScreenScale(2), ScreenScaleH(2), ScreenScale(2), 0)
    self.descLbl:SetText("Description:")
    self.descLbl:SetFont("Impulse-Elements18")
    self.descLbl:SizeToContents()

    self.descLblT = vgui.Create("DLabel", self.teams)
    self.descLblT:Dock(TOP)
    self.descLblT:DockMargin(ScreenScale(2), 0, ScreenScale(2), ScreenScaleH(2))
    self.descLblT:SetText("")
    self.descLblT:SetFont("Impulse-Elements14")

    self.availibleTeams = vgui.Create("DCollapsibleCategory", self.teamsInner)
    self.availibleTeams:SetLabel("Available teams")
    self.availibleTeams:Dock(TOP)
    local colInv = Color(0, 0, 0, 0)
    function self.availibleTeams:Paint()
        self:SetBGColor(colInv)
    end

    self.unavailibleTeams = vgui.Create("DCollapsibleCategory", self.teamsInner)
    self.unavailibleTeams:SetLabel("Unavailable teams")
    self.unavailibleTeams:Dock(TOP)
    function self.unavailibleTeams:Paint()
        self:SetBGColor(colInv)
    end

    for k, v in SortedPairsByMemberValue(impulse.Teams.Stored, "name") do
        local selectedList

        if (v.xp > LocalPlayer():GetXP()) or (v.donatorOnly and v.donatorOnly == true and LocalPlayer():IsDonator() == false) then
            selectedList = self.unavailibleTeams
        else
            selectedList = self.availibleTeams
        end

        local teamCard = vgui.Create("impulseTeamCard", selectedList)
        teamCard:Dock(TOP)
        teamCard:SetTeam(k)
        teamCard:SetMouseInputEnabled(true)

        local realSelf = self

        function teamCard:OnCursorEntered()
            local teamData = impulse.Teams.Stored[self.teamID]
            local model = teamCard.model
            local skin = teamCard.skin

            realSelf.modelPreview:SetModel(model)
            realSelf.modelPreview.Entity:SetSkin(skin or 0)

            -- Reset all bodygroups first
            for i = 0, realSelf.modelPreview.Entity:GetNumBodyGroups() - 1 do
                realSelf.modelPreview.Entity:SetBodygroup(i, 0)
            end

            -- Apply model-specific bodygroups if any
            local bodygroups = teamCard.bodygroups
            if ( bodygroups ) then
                for name, value in pairs(bodygroups) do
                    realSelf.modelPreview.Entity:SetBodygroup(realSelf.modelPreview.Entity:FindBodygroupByName(name), value)
                end
            end

            realSelf.descLblT:SetText(teamData.description)
            realSelf.descLblT:SetWrap(true)
            realSelf.descLblT:SizeToContents()
            realSelf.descLblT:SetContentAlignment(7)
        end

        function teamCard:OnMousePressed()
            net.Start("impulseTeamChange")
                net.WriteUInt(self.teamID, 8)
            net.SendToServer()

            realSelf:Remove()
        end
    end
end

function PANEL:Business()
    self.businessInner = vgui.Create("DPanel", self.business)
    self.businessInner:Dock(FILL)

    self.businessInner.Paint = function(_, width, height)
        surface.SetDrawColor(self.darkOverlay)
        surface.DrawRect(0, 0, width, height)
        return true
    end

    self.itemsScroll = vgui.Create("DScrollPanel", self.businessInner)
    self.itemsScroll:Dock(FILL)

    self.utilItems = self.itemsScroll:Add("DCollapsibleCategory")
    self.utilItems:SetLabel("Utilities")
    self.utilItems:Dock(TOP)
    local colInv = Color(0, 0, 0, 0)
    self.utilItems.Paint = function(this, width, height)
        this:SetBGColor(colInv)
    end

    local utilList = vgui.Create("DIconLayout", self.utilItems)
    utilList:Dock(FILL)
    utilList:SetSpaceY(5)
    utilList:SetSpaceX(5)
    self.utilItems:SetContents(utilList)

    self.cat = {}

    for name,k in pairs(impulse.Business.Data) do
        if !LocalPlayer():CanBuy(name) then continue end

        local parent = nil

        if k.category then
            if self.cat[k.category] then
                parent = self.cat[k.category]
            else
                local cat = self.itemsScroll:Add("DCollapsibleCategory")
                cat:SetLabel(k.category)
                cat:Dock(TOP)
                cat.Paint = nil

                self.cat[k.category] = vgui.Create("DIconLayout", cat)
                self.cat[k.category]:Dock(FILL)
                cat:SetContents(self.cat[k.category])

                parent = self.cat[k.category]
            end
        end

        local item = (parent or utilList):Add("impulseSpawnIcon")

        if k.item then
            local x = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(k.item)]
            item:SetModel(x.Model)
        else
            item:SetModel(k.model)
        end

        item:SetSize(ScreenScale(24), ScreenScale(24))
        item:SetTooltip(name .. " \n" .. impulse.Config.CurrencyPrefix .. k.price)
        item.id = table.KeyFromValue(impulse.Business.Stored, name)

        function item:DoClick()
            net.Start("impulseBuyItem")
            net.WriteUInt(item.id, 8)
            net.SendToServer()
        end

        local costLbl = vgui.Create("DLabel", item)
        costLbl:Dock(BOTTOM)
        costLbl:SetContentAlignment(5)
        costLbl:SetFont("Impulse-Elements18-Shadow")
        costLbl:SetText(impulse.Config.CurrencyPrefix .. k.price)
        costLbl:SizeToContents()
    end
end

function PANEL:Info()
    self.infoSheet = vgui.Create("DPropertySheet", self.info)
    self.infoSheet:Dock(FILL)

    if ( impulse.Config.RulesURL and impulse.Config.RulesURL != "" ) then
        local webRules = vgui.Create("DHTML", self.infoSheet)
        webRules:OpenURL(impulse.Config.RulesURL)

        self.infoSheet:AddSheet("Rules", webRules)
    end

    if ( impulse.Config.TutorialURL and impulse.Config.TutorialURL != "" ) then
        local webTutorial = vgui.Create("DHTML", self.infoSheet)
        webTutorial:OpenURL(impulse.Config.TutorialURL)

        self.infoSheet:AddSheet("Help & Tutorials", webTutorial)
    end

    local commands = vgui.Create("DScrollPanel", self.infoSheet)
    commands:Dock(FILL)

    for v, k in pairs(impulse.chatCommands) do
        local color = impulse.Config.MainColour

        if k.adminOnly == true and LocalPlayer():IsAdmin() == false then
            continue
        elseif k.adminOnly == true then
            color = impulse.Config.InteractColour
        end

        if k.superAdminOnly == true and LocalPlayer():IsSuperAdmin() == false then
            continue
        elseif k.superAdminOnly == true then
            color = Color(255, 0, 0, 255)
        end

        local command = commands:Add("DPanel", commands)
        command:SetTall(40)
        command:Dock(TOP)
        command.name = v
        command.desc = k.description
        command.color = color

        command.Paint = function(this, width, height)
            draw.SimpleText(this.name, "Impulse-Elements22-Shadow", 5, 0, this.color)
            draw.SimpleText(this.desc, "Impulse-Elements18-Shadow", 5, 20, color_white)
            return true
        end
    end

    self.infoSheet:AddSheet("Commands", commands)
end

function PANEL:AddSheet(name, icon, pnl, loadFunc)
    local tab = self.tabSheet:AddSheet(name, pnl)
    local panel = self
    tab.Button:SetSize(self.padding, self.padding)

    tab.Button.Paint = function(this, width, height)
        if ( panel.tabSheet.ActiveButton == this ) then
            surface.SetDrawColor(impulse.Config.MainColour)
        else
            surface.SetDrawColor(color_white)
        end

        surface.SetMaterial(icon)
        surface.DrawTexturedRect(15, 0, width - 30, height - 30)

        draw.SimpleText(name, "Impulse-Elements18", width / 2, height - 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        return true
    end

    local oldClick = tab.Button.DoClick
    tab.Button.DoClick = function(this)
        oldClick()

        if ( loadFunc and !this.loaded ) then
            loadFunc(panel)
            this.loaded = true
        end
    end

    return tab.Button
end

vgui.Register("impulsePlayerMenu", PANEL, "DFrame")
