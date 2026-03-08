local PANEL = {}

local quickTools = {
    {
        name = "Goto",
        icon = "icon16/arrow_right.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /goto " .. sid)
        end
    },
    {
        name = "Bring",
        icon = "icon16/arrow_inout.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /bring " .. sid)
        end
    },
    {
        name = "Respawn",
        icon = "icon16/arrow_refresh.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /respawn " .. sid)
        end
    },
    {
        name = "Unarrest",
        icon = "icon16/lock_open.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /unarrest " .. sid)
        end
    },
    {
        name = "Name change",
        icon = "icon16/textfield_rename.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /forcenamechange " .. sid)
        end
    },
    {
        name = "Set team",
        icon = "icon16/group_edit.png",
        onRun = function(client, sid)
            local teams = DermaMenu()
            for v, k in pairs(impulse.Teams.Stored) do
                teams:AddOption(k.name, function()
                    LocalPlayer():ConCommand("say /setteam " .. sid .. " " .. v)
                end)
            end

            teams:Open()
        end
    },
    {
        name = "View inventory",
        icon = "icon16/magnifier.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /viewinv " .. sid)
        end
    },
    {
        name = "Combine Ban",
        icon = "icon16/group_delete.png",
        onRun = function(client, sid)
            Derma_StringRequest("impulse", "Enter the length (in minutes) (1 WEEK MAX):", "", function(length)
                LocalPlayer():ConCommand("say /combineban " .. sid .. " " .. length)
            end)
        end
    },
    {
        name = "OOC timeout",
        icon = "icon16/sound_add.png",
        onRun = function(client, sid)
            Derma_StringRequest("impulse", "Enter the timeout length (in minutes):", "10", function(length)
                LocalPlayer():ConCommand("say /ooctimeout " .. sid .. " " .. length)
            end)
        end
    },
    {
        name = "Un-OOC timeout",
        icon = "icon16/sound_delete.png",
        onRun = function(client, sid)
            LocalPlayer():ConCommand("say /unooctimeout " .. sid)
        end
    },
    {
        name = "Cleanup Props",
        icon = "icon16/building_delete.png",
        onRun = function(client, sid)
            Derma_Query("Are you sure you want to cleanup the props of:\n" .. client:Nick() .. "(" .. client:SteamName() .. ")?", "ops", "Yes", function()
                LocalPlayer():ConCommand("say /cleanup " .. sid)
            end, "No, take me back!")
        end
    },
    {
        name = "Warn",
        icon = "icon16/error_add.png",
        onRun = function(client, sid)
            Derma_StringRequest("impulse", "Enter the reason:", "", function(reason)
                LocalPlayer():ConCommand("say /warn " .. sid .. " " .. reason)
            end)
        end
    },
    {
        name = "Kick",
        icon = "icon16/user_go.png",
        onRun = function(client, sid)
            Derma_StringRequest("impulse", "Enter the reason:", "Violation of community guidelines", function(reason)
                LocalPlayer():ConCommand("say /kick " .. sid .. " " .. reason)
            end)
        end
    },
    {
        name = "Ban",
        icon = "icon16/user_delete.png",
        onRun = function(client, sid)
            local i = Derma_StringRequest("impulse", "Enter the length (in minutes):", "", function(length)
                Derma_StringRequest("impulse", "Enter the reason:", "", function(reason)
                    local userInfo = sid
                    local targ = player.GetBySteamID(sid)

                    if IsValid(targ) then
                        userInfo = targ:Nick() .. " (" .. targ:SteamName() .. ")"
                    end

                    Derma_Query("Please confirm the ban:\nUser: " .. userInfo .. "\nLength: " .. string.NiceTime(tonumber(length) * 60) .. " (" .. length .. " minutes)\nReason: " .. reason .. "\n\nAll issued bans are logged forever, even if deleted.", "impulse", "Confirm", function()
                        LocalPlayer():ConCommand("say /ban " .. sid .. " " .. length .. " " .. reason)
                    end, "Abort")
                end)
            end)

            local textEntry = i:GetChild(4):GetChildren()[2]

            local function addTime(time)
                local v = textEntry:GetValue()

                local new = (tonumber(v) or 0) + time

                textEntry:SetValue(new)
                LocalPlayer():Notify("Added " .. time .. " minutes.")
            end

            local addDay = vgui.Create("DButton", i)
            addDay:SetPos(10, 90)
            addDay:SetSize(25, 20)
            addDay:SetText("+1D")
            addDay.DoClick = function() addTime(1440) end

            local addWeek = vgui.Create("DButton", i)
            addWeek:SetPos(40, 90)
            addWeek:SetSize(25, 20)
            addWeek:SetText("+1W")
            addWeek.DoClick = function() addTime(10080) end

            local addMonth = vgui.Create("DButton", i)
            addMonth:SetPos(70, 90)
            addMonth:SetSize(25, 20)
            addMonth:SetText("+1M")
            addMonth.DoClick = function() addTime(43200) end

            local addSixMonths = vgui.Create("DButton", i)
            addSixMonths:SetPos(100, 90)
            addSixMonths:SetSize(25, 20)
            addSixMonths:SetText("+6M")
            addSixMonths.DoClick = function() addTime(259200) end
        end
    },
    {
        name = "IAC Flag",
        icon = "icon16/flag_red.png",
        onRun = function(client, sid)
            Derma_Query("BEFORE FLAGGING READ THE GUIDE AT: https://impulse-community.com/threads/how-to-iac-flag-a-user.3044/\nAre you sure you want to flag:\n" .. client:Nick() .. "(" .. client:SteamName() .. ")?", "ops", "Yes", function()
                LocalPlayer():ConCommand("say /iacflag " .. sid)
            end, "No, take me back!")
        end
    }
}

function PANEL:Init()
    if ( IsValid(impulse.playerInfoCard) ) then
        impulse.playerInfoCard:Remove()
    end

    impulse.playerInfoCard = self

    self:SetSize(ScrW() / 3.5, ScrH() / 3)
    self:Center()
    self:SetTitle("Player Information")
    self:MakePopup()
end

function PANEL:SetPlayer(client, badges)
    self.client = client or NULL
    self.badges = badges or {}

    if ( !IsValid(client) ) then
        self:Close()
        return
    end

    -- 3d model
    self.characterPreview = self:Add("impulseModelPanel")
    self.characterPreview:Dock(RIGHT)
    self.characterPreview:SetWide(ScreenScale(48))
    self.characterPreview:SetFOV(ScreenScale(8))
    self.characterPreview:SetModel(client:GetModel(), client:GetSkin())
    self.characterPreview:MoveToBack()
    self.characterPreview:SetCursor("arrow")

    self.characterPreview.LayoutEntity = function(this, entity)
        entity:SetAngles(Angle(0, 45, 0))
        this:RunAnimation()

        for k, v in pairs(client:GetBodyGroups()) do
            entity:SetBodygroup(v.id, client:GetBodygroup(v.id))
        end
    end

    self.nameContainer = self:Add("DPanel")
    self.nameContainer:Dock(TOP)
    self.nameContainer:DockMargin(0, 0, 0, 5)
    self.nameContainer:SetTall(ScreenScaleH(32))
    self.nameContainer.Paint = nil

    self.profileImage = self.nameContainer:Add("AvatarImage")
    self.profileImage:Dock(LEFT)
    self.profileImage:DockMargin(0, 0, 5, 0)
    self.profileImage:SetSize(self.nameContainer:GetTall(), self.nameContainer:GetTall())
    self.profileImage:SetPlayer(client, 128)

    local nameContainer = self.nameContainer:Add("DPanel")
    nameContainer:Dock(TOP)
    nameContainer.Paint = nil

    self.oocName = nameContainer:Add("DLabel")
    self.oocName:Dock(LEFT)
    self.oocName:SetFont("Impulse-CharacterInfo-NO")
    self.oocName:SetText(client:SteamName())
    self.oocName:SizeToContents()

    self.rpName = nameContainer:Add("DLabel")
    self.rpName:Dock(LEFT)
    self.rpName:SetFont("Impulse-Elements18")
    self.rpName:SetText(client:Name())
    self.rpName:SetTextInset(0, -4)
    self.rpName:SetContentAlignment(2)
    self.rpName:SizeToContents()

    nameContainer:SetTall(math.max(self.oocName:GetTall(), self.rpName:GetTall()))

    self.teamName = self.nameContainer:Add("DLabel")
    self.teamName:Dock(TOP)
    self.teamName:SetFont("Impulse-Elements23")
    self.teamName:SetText(team.GetName(client:Team()))
    self.teamName:SetTextColor(team.GetColor(client:Team()))
    self.teamName:SizeToContents()

    self.badgesContainer = self.nameContainer:Add("DPanel")
    self.badgesContainer:Dock(TOP)
    self.badgesContainer:SetTall(16)
    self.badgesContainer.Paint = nil

    -- badges
    local xShift = 0
    for badgeName, badgeData in pairs(impulse.Badges) do
        if badgeData[3](client) then
            local badge = self.badgesContainer:Add("DImageButton")
            badge:Dock(LEFT)
            badge:SetSize(16, 16)
            badge:SetMaterial(badgeData[1])
            badge.info = badgeData[2]

            function badge:DoClick()
                Derma_Message(badge.info, "impulse", "Close")
            end

            xShift = xShift + 20
        end
    end

    self.buttonsContainer = self:Add("DPanel")
    self.buttonsContainer:Dock(TOP)
    self.buttonsContainer:DockMargin(0, 0, 0, 5)
    self.buttonsContainer:SetTall(ScreenScaleH(8))
    self.buttonsContainer.Paint = nil

    -- buttons
    self.profileButton = self.buttonsContainer:Add("DButton")
    self.profileButton:Dock(LEFT)
    self.profileButton:DockMargin(0, 0, 5, 0)
    self.profileButton:SetText("Steam Profile")
    self.profileButton:SizeToContents()
    self.profileButton.DoClick = function()
        gui.OpenURL("http://steamcommunity.com/profiles/" .. client:SteamID64())
    end

    self.sidButton = self.buttonsContainer:Add("DButton")
    self.sidButton:Dock(LEFT)
    self.sidButton:DockMargin(0, 0, 5, 0)
    self.sidButton:SetText("Copy Steam ID")
    self.sidButton:SizeToContents()
    self.sidButton.DoClick = function()
        SetClipboardText(client:SteamID64())
        LocalPlayer():Notify("Copied SteamID64.")
    end

    self.forumButton = self.buttonsContainer:Add("DButton")
    self.forumButton:Dock(LEFT)
    self.forumButton:DockMargin(0, 0, 5, 0)
    self.forumButton:SetText("Panel Profile")
    self.forumButton:SizeToContents()
    self.forumButton.DoClick = function()
        gui.OpenURL(impulse.Config.PanelURL .. "/index.php?t=user&id=" .. client:SteamID64())
    end

    self.whitelistButton = self.buttonsContainer:Add("DButton")
    self.whitelistButton:Dock(LEFT)
    self.whitelistButton:DockMargin(0, 0, 5, 0)
    self.whitelistButton:SetText("Forum Profile")
    self.whitelistButton:SizeToContents()
    self.whitelistButton.DoClick = function()
        if !IsValid(client) then return end

        gui.OpenURL("https://impulse-community.com/api/getforumprofile.php?id=" .. client:SteamID64())
    end

    -- xp/playtime
    self.playtime = self:Add("DLabel")
    self.playtime:Dock(TOP)
    self.playtime:SetFont("Impulse-Elements18-Shadow")
    self.playtime:SetText("XP: " .. client:GetXP())
    self.playtime:SizeToContents()

    -- tp
    self.tp = vgui.Create("DLabel", self)
    self.tp:Dock(TOP)
    self.tp:DockMargin(0, 0, 0, 5)
    self.tp:SetFont("Impulse-Elements18-Shadow")
    self.tp:SetText("Achievement Points: " .. client:GetRelay("achievementPoints", 0))
    self.tp:SizeToContents()

    -- admin stuff
    if ( LocalPlayer():IsAdmin() ) then
        self.adminTools = self:Add("DCollapsibleCategory")
        self.adminTools:Dock(FILL)
        self.adminTools:SetExpanded(0)
        self.adminTools:SetLabel("Admin tools (click to expand)")

        local colInv = Color(0, 0, 0, 0)
        function self.adminTools:Paint()
            self:SetBGColor(colInv)
        end

        self.adminList = vgui.Create("DIconLayout", self.adminTools)
        self.adminList:Dock(FILL)
        self.adminList:SetSpaceY(5)
        self.adminList:SetSpaceX(5)

        for v, k in pairs(quickTools) do
            local action = self.adminList:Add("DButton")
            action:SetSize(125,30)
            action:SetText(k.name)
            action:SetIcon(k.icon)

            action.runFunc = k.onRun
            local target = client
            function action:DoClick()
                if !IsValid(target) then return LocalPlayer():Notify("This player has disconnected.") end
                self.runFunc(target, target:SteamID64())
            end
        end
    end
end

vgui.Register("impulsePlayerInfoCard", PANEL, "DFrame")

if ( IsValid(impulse.playerInfoCard) ) then
    local client = impulse.playerInfoCard.client
    local badges = impulse.playerInfoCard.badges

    vgui.Create("impulsePlayerInfoCard"):SetPlayer(client, badges)
end
