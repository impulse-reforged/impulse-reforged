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
                local classBtn = self.list:Add("DPanel")
                classBtn:Dock(TOP)
                classBtn:DockMargin(5, 2, 5, 2)
                classBtn:SetTall(60)
                classBtn:SetCursor("hand")
                classBtn.classID = v
                classBtn.hovered = false

                local btnText = "Become " .. classData.name
                local reqText = ""
                if classData.xp and classData.xp > 0 then
                    reqText = "Requires " .. classData.xp .. " XP"
                end
                if classData.whitelistLevel then
                    if reqText != "" then reqText = reqText .. " | " end
                    reqText = reqText .. "Whitelist Level " .. classData.whitelistLevel
                end

                classBtn.Paint = function(this, width, height)
                    local bgColor = Color(50, 50, 50, 200)
                    local borderColor = impulse.Config.MainColour

                    if this.hovered then
                        bgColor = Color(70, 70, 70, 220)
                        borderColor = ColorAlpha(impulse.Config.MainColour, 255)
                    end

                    surface.SetDrawColor(bgColor)
                    surface.DrawRect(0, 0, width, height)

                    surface.SetDrawColor(borderColor)
                    surface.DrawOutlinedRect(0, 0, width, height, 2)

                    draw.SimpleText(btnText, "Impulse-Elements20-Shadow", 10, 10, color_white)

                    if classData.description then
                        draw.SimpleText(classData.description, "Impulse-Elements14-Shadow", 10, 30, Color(200, 200, 200))
                    end

                    if reqText != "" then
                        draw.SimpleText(reqText, "Impulse-Elements14-Shadow", width - 10, height - 10, Color(100, 200, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                    end
                end

                classBtn.OnCursorEntered = function(this)
                    this.hovered = true
                end

                classBtn.OnCursorExited = function(this)
                    this.hovered = false
                end

                classBtn.OnMousePressed = function(this)
                    net.Start("impulseClassChange")
                        net.WriteUInt(this.classID, 8)
                    net.SendToServer()

                    self:Remove()
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
            local netid = impulse.Inventory:ClassToNetID(k.item)
            local x = impulse.Inventory.Items[netid]

            if ( x ) then
                item:SetModel(x.Model)
            else
                item:SetModel("models/error.mdl")
            end
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

    local classesRanks = vgui.Create("DScrollPanel", self.infoSheet)
    classesRanks:Dock(FILL)
    self:PopulateClassesRanks(classesRanks)

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

    self.infoSheet:AddSheet("Classes & Ranks", classesRanks)
    self.infoSheet:AddSheet("Commands", commands)
end

function PANEL:PopulateClassesRanks(parent)
    -- Iterate through all teams
    for teamID, teamData in SortedPairsByMemberValue(impulse.Teams.Stored, "name") do
        local teamCategory = vgui.Create("DCollapsibleCategory", parent)
        teamCategory:SetLabel(teamData.name)
        teamCategory:Dock(TOP)
        teamCategory:DockMargin(5, 5, 5, 0)

        local teamColor = teamData.color or Color(255, 255, 255)
        teamCategory.Paint = function(this, width, height)
            surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, 100)
            surface.DrawRect(0, 0, width, 20)
        end

        local teamContent = vgui.Create("DPanel", teamCategory)
        teamContent:Dock(FILL)
        teamContent.Paint = function(_, width, height)
            surface.SetDrawColor(40, 40, 40, 200)
            surface.DrawRect(0, 0, width, height)
        end

        teamCategory:SetContents(teamContent)

        -- Team Requirements
        local reqLabel = vgui.Create("DLabel", teamContent)
        reqLabel:Dock(TOP)
        reqLabel:DockMargin(5, 5, 5, 5)
        reqLabel:SetFont("Impulse-Elements18")
        reqLabel:SetText("Team Requirements:")
        reqLabel:SizeToContents()

        local reqText = "XP: " .. (teamData.xp or 0)
        if teamData.donatorOnly then
            reqText = reqText .. " | Donator Only"
        end

        local reqValue = vgui.Create("DLabel", teamContent)
        reqValue:Dock(TOP)
        reqValue:DockMargin(10, 0, 5, 5)
        reqValue:SetFont("Impulse-Elements14")
        reqValue:SetText(reqText)
        reqValue:SizeToContents()

        -- Classes Section
        if teamData.classes and table.Count(teamData.classes) > 0 then
            local classHeader = vgui.Create("DLabel", teamContent)
            classHeader:Dock(TOP)
            classHeader:DockMargin(5, 10, 5, 5)
            classHeader:SetFont("Impulse-Elements18")
            classHeader:SetText("Classes:")
            classHeader:SetColor(Color(100, 200, 255))
            classHeader:SizeToContents()

            for classID, classData in ipairs(teamData.classes) do
                if classData.noMenu then continue end

                local classPanel = vgui.Create("DPanel", teamContent)
                classPanel:Dock(TOP)
                classPanel:DockMargin(10, 2, 5, 2)
                classPanel:SetTall(50)
                classPanel.Paint = function(_, width, height)
                    surface.SetDrawColor(50, 50, 50, 180)
                    surface.DrawRect(0, 0, width, height)

                    draw.SimpleText(classData.name, "Impulse-Elements18-Shadow", 5, 5, color_white)

                    if classData.description then
                        draw.SimpleText(classData.description, "Impulse-Elements14-Shadow", 5, 25, Color(200, 200, 200))
                    end
                end

                local classReq = vgui.Create("DLabel", classPanel)
                classReq:Dock(RIGHT)
                classReq:SetFont("Impulse-Elements14")
                classReq:SetContentAlignment(6)

                local reqStr = ""
                if classData.xp and classData.xp > 0 then
                    reqStr = reqStr .. classData.xp .. " XP"
                end
                if classData.whitelistLevel then
                    if reqStr != "" then reqStr = reqStr .. " | " end
                    reqStr = reqStr .. "WL Lvl " .. classData.whitelistLevel
                end
                if reqStr == "" then
                    reqStr = "No Requirements"
                end

                classReq:SetText(reqStr)
                classReq:SizeToContents()
                classReq:SetWide(classReq:GetWide() + 10)
            end
        end

        -- Ranks Section
        if teamData.ranks and table.Count(teamData.ranks) > 0 then
            local rankHeader = vgui.Create("DLabel", teamContent)
            rankHeader:Dock(TOP)
            rankHeader:DockMargin(5, 10, 5, 5)
            rankHeader:SetFont("Impulse-Elements18")
            rankHeader:SetText("Ranks:")
            rankHeader:SetColor(Color(255, 200, 100))
            rankHeader:SizeToContents()

            for rankID, rankData in ipairs(teamData.ranks) do
                local rankPanel = vgui.Create("DPanel", teamContent)
                rankPanel:Dock(TOP)
                rankPanel:DockMargin(10, 2, 5, 2)
                rankPanel:SetTall(50)
                rankPanel.Paint = function(_, width, height)
                    surface.SetDrawColor(50, 50, 50, 180)
                    surface.DrawRect(0, 0, width, height)

                    draw.SimpleText(rankData.name, "Impulse-Elements18-Shadow", 5, 5, color_white)

                    if rankData.description then
                        draw.SimpleText(rankData.description, "Impulse-Elements14-Shadow", 5, 25, Color(200, 200, 200))
                    end
                end

                local rankReq = vgui.Create("DLabel", rankPanel)
                rankReq:Dock(RIGHT)
                rankReq:DockMargin(0, 0, 5, 0)
                rankReq:SetFont("Impulse-Elements14")
                rankReq:SetContentAlignment(6)

                local reqStr = ""
                if rankData.xp and rankData.xp > 0 then
                    reqStr = reqStr .. rankData.xp .. " XP"
                end
                if rankData.whitelistLevel then
                    if reqStr != "" then reqStr = reqStr .. " | " end
                    reqStr = reqStr .. "WL Lvl " .. rankData.whitelistLevel
                end
                if rankData.salary and rankData.salary > 0 then
                    if reqStr != "" then reqStr = reqStr .. " | " end
                    reqStr = reqStr .. "Salary: " .. impulse.Config.CurrencyPrefix .. rankData.salary
                end
                if reqStr == "" then
                    reqStr = "No Requirements"
                end

                rankReq:SetText(reqStr)
                rankReq:SizeToContents()
                rankReq:SetWide(rankReq:GetWide() + 10)
            end
        end

        -- If no classes or ranks
        if (!teamData.classes or table.Count(teamData.classes) == 0) and (!teamData.ranks or table.Count(teamData.ranks) == 0) then
            local noData = vgui.Create("DLabel", teamContent)
            noData:Dock(TOP)
            noData:DockMargin(10, 10, 5, 10)
            noData:SetFont("Impulse-Elements14")
            noData:SetText("This team has no classes or ranks.")
            noData:SetColor(Color(150, 150, 150))
            noData:SizeToContents()
        end
    end
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
