local PANEL = {}

function PANEL:Init()
    self:SetSize(900, 810)
    self:Center()
    self:SetTitle("ops support tools")
    self:MakePopup()

    local sheet = vgui.Create("DColumnSheet", self)
    sheet:Dock(FILL)

    local b = vgui.Create("DPanel", sheet)
    b:Dock(FILL)
    b.Paint = nil

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("Target (Steam64 ID):")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local steamid64 = vgui.Create("DTextEntry", b)
    steamid64:SetFont("ChatFont")
    steamid64:SetPos(0, 20)
    steamid64:SetSize(900, 30)
    steamid64:SetPlaceholderText("Steam64 ID")

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("Refund:")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local scroll = vgui.Create("DScrollPanel", b)
    scroll:SetTall(500)
    scroll:Dock(TOP)

    local refund = {}
    local refund2 = {}
    local cats = {}

    for v, k in pairs(impulse.Inventory.Items) do
        if !cats[k.Category or "Unknown"] then
            local cat = scroll:Add("DCollapsibleCategory")
            cat:Dock(TOP)
            cat:SetLabel(k.Category or "Unknown")
            cat:SetExpanded(false)

            cats[k.Category or "Unknown"] = vgui.Create("DPanelList", panel)
            local list = cats[k.Category or "Unknown"]
            list:Dock(FILL)
            list:SetSpacing(5)
            cat:SetContents(list)
        end

        local btn = vgui.Create("DButton")
        btn:SetText("  " .. k.Name .. " (" .. k.UniqueID .. ")")
        btn:SetContentAlignment(4)
        btn:Dock(TOP)
        btn:SetFont("Impulse-Elements18")
        btn:DockMargin(0, 0, 0, 5)
        btn.ItemClass = k.UniqueID

        function btn:DoClick()
            Derma_StringRequest("impulse", "Amount of " .. k.Name .. " to refund", "1", function(val)
                if !tonumber(val) then
                    return LocalPlayer():Notify("The value entered is not a number.")
                end

                local val = math.Clamp(math.floor(val), 0, 30)

                if val == 0 then
                    refund[self.ItemClass] = nil

                    for v, k in pairs(refund2) do
                        if k[1] == self.ItemClass then
                            refund2[v] = nil
                        end
                    end

                    return LocalPlayer():Notify("Successfully removed " .. self.ItemClass .. " .. ")
                end

                for v, k in pairs(refund2) do
                    if k[1] == self.ItemClass then
                        refund2[v] = nil
                    end
                end

                refund[self.ItemClass] = val
                table.insert(refund2, {self.ItemClass, val})

                LocalPlayer():Notify("Selected " .. k.Name .. " x" .. val .. ".")
            end)
        end

        cats[k.Category or "Unknown"]:AddItem(btn)
    end

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("Total:")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)

    local lbl = vgui.Create("DLabel", b)
    lbl:SetText("Nothing")
    lbl:SetFont("Impulse-Elements18")
    lbl:Dock(TOP)
    lbl:SetContentAlignment(7)
    lbl:SetWrap(true)
    lbl:SetTall(70)

    function lbl:Think()
        local t = ""
        for v, k in pairs(refund2) do
            t = t..k[1] .. " x" .. k[2] .. ", "
        end

        self:SetText(t)
    end

    local confirm = vgui.Create("DButton", b)
    confirm:SetPos(0, 700)
    confirm:SetSize(600, 60)
    confirm:SetText("Issue Refund")

    function confirm:DoClick()
        local id = string.Trim(steamid64:GetValue(), " ")

        if id == "" or !tonumber(id) then
            return LocalPlayer():Notify("The SteamID64 entered is invalid.")
        end

        if !refund2 or table.Count(refund2) < 1 then
            return LocalPlayer():Notify("No refund items have been selected.")
        end

        local data = pon.encode(refund)

        net.Start("impulseOpsSTDoRefund")
        net.WriteString(id)
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
        net.SendToServer()
    end

    sheet:AddSheet("Refunder", b, "icon16/bricks.png")

    local b = vgui.Create("DPanel", sheet)
    b:Dock(FILL)
    b.Paint = nil

    local btn = vgui.Create("DButton", b)
    btn:Dock(TOP)
    btn:SetText("Enable OOC")

    function btn:DoClick()
        net.Start("impulseOpsSTDoOOCEnabled")
        net.WriteBool(true)
        net.SendToServer()
    end

    local btn = vgui.Create("DButton", b)
    btn:Dock(TOP)
    btn:SetText("Disable OOC")

    function btn:DoClick()
        net.Start("impulseOpsSTDoOOCEnabled")
        net.WriteBool(false)
        net.SendToServer()
    end

    sheet:AddSheet("Chat", b, "icon16/bricks.png")

    local b = vgui.Create("DPanel", sheet)
    b:Dock(FILL)
    b.Paint = nil

    local scroll = vgui.Create("DScrollPanel", b)
    scroll:Dock(FILL)

    for v, k in pairs(impulse.Teams.Stored) do
        local t = scroll:Add("DPanel")
        t:SetTall(60)
        t:Dock(TOP)

        function t:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60, 200))
        end

        local lbl = vgui.Create("DLabel", t)
        lbl:SetText(k.name .. " (ID: " .. v .. ") (Current players: " .. #team.GetPlayers(v) .. ")")
        lbl:SetFont("Impulse-Elements18")
        lbl:SizeToContents()
        lbl:SetPos(5, 5)

        local btn = vgui.Create("DButton", t)
        btn:SetPos(5, 25)
        btn:SetSize(80, 25)
        btn:SetText("Lock Team")

        function btn:DoClick()
            net.Start("impulseOpsSTDoTeamLocked")
            net.WriteUInt(v, 8)
            net.WriteBool(true)
            net.SendToServer()
        end

        local btn = vgui.Create("DButton", t)
        btn:SetPos(90, 25)
        btn:SetSize(80, 25)
        btn:SetText("Unlock Team")

        function btn:DoClick()
            net.Start("impulseOpsSTDoTeamLocked")
            net.WriteUInt(v, 8)
            net.WriteBool(false)
            net.SendToServer()
        end
    end

    sheet:AddSheet("Teams", b, "icon16/bricks.png")

    local b = vgui.Create("DPanel", sheet)
    b:Dock(FILL)
    b.Paint = nil

    local text = vgui.Create("DTextEntry", b)
    text:Dock(TOP)
    text:SetPlaceholderText("Enter group name (exactly)")

    local btn = vgui.Create("DButton", b)
    btn:Dock(TOP)
    btn:SetText("Remove Group")

    function btn:DoClick()
        Derma_Query("Are you sure you want to remove the " .. text:GetValue() .. " group?", "impulse",
        "Remove", function()
            net.Start("impulseOpsSTDoGroupRemove")
            net.WriteString(text:GetValue())
            net.SendToServer()
        end, "Cancel")
    end

    sheet:AddSheet("Groups", b, "icon16/bricks.png")
end

vgui.Register("impulseSupportTool", PANEL, "DFrame")
