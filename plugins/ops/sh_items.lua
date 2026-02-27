if ( CLIENT ) then
    local CATEGORY_ALL = "__all__"
    local STYLE_TOP = Color(30, 30, 30, 200)
    local STYLE_BODY = Color(80, 80, 80, 100)
    local STYLE_CARD = Color(45, 45, 45, 220)
    local STYLE_CARD_HOVER = Color(70, 70, 70, 235)
    local STYLE_BORDER = Color(110, 110, 110, 140)
    local STYLE_CAT_ACTIVE = Color(80, 80, 80, 170)
    local STYLE_CAT_INACTIVE = Color(60, 60, 60, 130)
    local STYLE_TEXT_SECONDARY = Color(200, 200, 200, 220)
    local STYLE_TEXT_MUTED = Color(170, 170, 170, 200)

    local function BuildSpawnerCatalog()
        local unique = {}

        for _, item in pairs(impulse.Inventory.Items or {}) do
            if ( !istable(item) ) then continue end
            if ( !item.UniqueID or item.UniqueID == "" ) then continue end

            -- Lua refresh can register items multiple times; keep only one per UniqueID.
            unique[item.UniqueID] = unique[item.UniqueID] or item
        end

        local categories = {}
        local categoryNames = {}

        for _, item in pairs(unique) do
            local category = item.Category or "Unknown"
            categories[category] = categories[category] or {}
            table.insert(categories[category], item)
        end

        for categoryName, _ in pairs(categories) do
            table.insert(categoryNames, categoryName)
            table.sort(categories[categoryName], function(a, b)
                local aName = a.Name or a.UniqueID or ""
                local bName = b.Name or b.UniqueID or ""
                return aName < bName
            end)
        end

        table.sort(categoryNames)

        return categories, categoryNames
    end

    local function BuildItemCard(parent, panel, item)
        local card = parent:Add("DButton")
        card:SetSize(170, 210)
        card:SetText("")
        card:SetTooltip(item.UniqueID or "unknown")
        card.ItemClass = item.UniqueID

        function card:Paint(w, h)
            local bg = self:IsHovered() and STYLE_CARD_HOVER or STYLE_CARD
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(STYLE_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local mdl = vgui.Create("DModelPanel", card)
        mdl:Dock(TOP)
        mdl:SetTall(130)
        mdl:SetModel(item.Model or "models/props_junk/watermelon01.mdl")
        mdl:SetMouseInputEnabled(false)
        mdl:SetFOV(28)
        mdl:SetCamPos(Vector(45, 45, 35))
        mdl:SetLookAt(vector_origin)

        local name = vgui.Create("DLabel", card)
        name:Dock(TOP)
        name:DockMargin(6, 6, 6, 0)
        name:SetFont("Impulse-Elements16")
        name:SetTextColor(color_white)
        name:SetText(item.Name or item.UniqueID or "Unknown Item")
        name:SetWrap(true)
        name:SetAutoStretchVertical(true)

        local uid = vgui.Create("DLabel", card)
        uid:Dock(TOP)
        uid:DockMargin(6, 4, 6, 0)
        uid:SetFont("Impulse-Elements10")
        uid:SetTextColor(STYLE_TEXT_SECONDARY)
        uid:SetText(item.UniqueID or "unknown")
        uid:SetWrap(true)
        uid:SetAutoStretchVertical(true)

        local spawn = vgui.Create("DButton", card)
        spawn:Dock(BOTTOM)
        spawn:DockMargin(6, 8, 6, 6)
        spawn:SetTall(24)
        spawn:SetText("Give Item")
        spawn:SetFont("Impulse-Elements14")
        spawn:SetTextColor(color_white)

        function spawn:Paint(w, h)
            local alpha = 120
            if ( self:IsDown() ) then
                alpha = 170
            elseif ( self:IsHovered() ) then
                alpha = 150
            end

            surface.SetDrawColor(ColorAlpha(STYLE_BODY, alpha))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(STYLE_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local function DoGive()
            if ( !panel.Selected or panel.Selected == "" ) then
                return LocalPlayer():Notify("No target selected.")
            end

            LocalPlayer():ConCommand("say /giveitem " .. panel.Selected .. " " .. item.UniqueID)
        end

        function card:DoClick()
            DoGive()
        end

        function spawn:DoClick()
            DoGive()
        end
    end

    net.Receive("impulseOpsItemSpawner", function()
        if ( IsValid(impulse_itemSpawnerMenu) ) then
            impulse_itemSpawnerMenu:Remove()
        end

        local categories, categoryNames = BuildSpawnerCatalog()

        local panel = vgui.Create("DFrame")
        impulse_itemSpawnerMenu = panel
        panel:SetSize(math.max(980, ScrW() * 0.72), math.max(600, ScrH() * 0.78))
        panel:Center()
        panel:SetSkin("impulse")
        panel:SetTitle("Item Spawner")
        panel:MakePopup()
        panel.Selected = LocalPlayer():SteamID64()
        panel.SelectedCategory = CATEGORY_ALL
        panel.SearchValue = ""

        local top = vgui.Create("DPanel", panel)
        top:Dock(TOP)
        top:SetTall(48)
        top:DockMargin(6, 6, 6, 6)
        top.Paint = nil

        local targetBox = vgui.Create("DComboBox", top)
        targetBox:Dock(LEFT)
        targetBox:SetWide(390)
        targetBox:SetSortItems(false)
        targetBox:SetFont("Impulse-Elements18")
        targetBox:AddChoice("Me", LocalPlayer():SteamID64())
        targetBox:AddChoice("Custom SteamID64 (Offline User)", "__custom__")

        for _, ply in player.Iterator() do
            targetBox:AddChoice("PLAYER: " .. ply:Nick() .. " (" .. ply:SteamName() .. ")", ply:SteamID64())
        end

        targetBox:SetValue("Me")

        local search = vgui.Create("DTextEntry", top)
        search:Dock(FILL)
        search:DockMargin(6, 0, 0, 0)
        search:SetUpdateOnType(true)
        search:SetPlaceholderText("Search items by name, unique ID, or category...")

        local status = vgui.Create("DLabel", top)
        status:Dock(BOTTOM)
        status:DockMargin(6, 6, 0, 0)
        status:SetFont("Impulse-Elements14")
        status:SetTextColor(STYLE_TEXT_SECONDARY)

        local body = vgui.Create("DPanel", panel)
        body:Dock(FILL)
        body:DockMargin(6, 0, 6, 6)
        body.Paint = function(_, w, h)
            surface.SetDrawColor(STYLE_BODY)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(STYLE_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local categoryScroll = vgui.Create("DScrollPanel", body)
        categoryScroll:Dock(LEFT)
        categoryScroll:SetWide(235)

        local itemScroll = vgui.Create("DScrollPanel", body)
        itemScroll:Dock(FILL)
        itemScroll:DockMargin(8, 0, 0, 0)

        local itemLayout = vgui.Create("DTileLayout", itemScroll)
        itemLayout:Dock(TOP)
        itemLayout:SetBaseSize(170)
        itemLayout:SetSpaceX(8)
        itemLayout:SetSpaceY(8)
        itemLayout:SetBorder(4)

        local function RefreshStatus(shownCount)
            local target = panel.Selected or "none"
            if ( target == LocalPlayer():SteamID64() ) then
                target = "Me (" .. target .. ")"
            end

            status:SetText("Target: " .. target .. " | Showing: " .. tostring(shownCount or 0) .. " item(s)")
            status:SizeToContents()
        end

        local function RefreshItems()
            itemLayout:Clear()

            local shown = 0
            local searchValue = string.lower(panel.SearchValue or "")
            local isAll = panel.SelectedCategory == CATEGORY_ALL

            local function AddCategoryItems(categoryName)
                local items = categories[categoryName]
                if ( !items ) then return end

                for _, item in ipairs(items) do
                    local itemName = string.lower(item.Name or "")
                    local itemUID = string.lower(item.UniqueID or "")
                    local itemCategory = string.lower(item.Category or "unknown")
                    local hasSearch = searchValue == ""
                        or string.find(itemName, searchValue, 1, true)
                        or string.find(itemUID, searchValue, 1, true)
                        or string.find(itemCategory, searchValue, 1, true)

                    if ( !hasSearch ) then continue end

                    BuildItemCard(itemLayout, panel, item)
                    shown = shown + 1
                end
            end

            if ( isAll ) then
                for _, categoryName in ipairs(categoryNames) do
                    AddCategoryItems(categoryName)
                end
            else
                AddCategoryItems(panel.SelectedCategory)
            end

            if ( shown < 1 ) then
                local empty = itemLayout:Add("DLabel")
                empty:SetText("No items matched your current filter.")
                empty:SetFont("Impulse-Elements19-Shadow")
                empty:SetTextColor(STYLE_TEXT_MUTED)
                empty:SetSize(520, 50)
            end

            RefreshStatus(shown)
        end

        local function AddCategoryButton(label, categoryName, count)
            local button = categoryScroll:Add("DButton")
            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 6)
            button:SetTall(30)
            button:SetText("")

            function button:Paint(w, h)
                local isActive = panel.SelectedCategory == categoryName
                local bg = isActive and STYLE_CAT_ACTIVE or STYLE_CAT_INACTIVE

                surface.SetDrawColor(bg)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(STYLE_BORDER)
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                draw.SimpleText(label, "Impulse-Elements14", 8, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(count), "Impulse-Elements14", w - 8, h / 2, STYLE_TEXT_SECONDARY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            function button:DoClick()
                panel.SelectedCategory = categoryName
                RefreshItems()
            end
        end

        local totalCount = 0
        for _, categoryName in ipairs(categoryNames) do
            totalCount = totalCount + #categories[categoryName]
        end

        AddCategoryButton("All Items", CATEGORY_ALL, totalCount)

        for _, categoryName in ipairs(categoryNames) do
            AddCategoryButton(categoryName, categoryName, #categories[categoryName])
        end

        function targetBox:OnSelect(index, text, value)
            if ( value == "__custom__" ) then
                Derma_StringRequest("impulse", "Enter the target SteamID64 below:", "", function(sid)
                    if ( !IsValid(panel) ) then return end

                    sid = string.Trim(sid or "", " ")
                    if ( sid == "" ) then return end

                    panel.Selected = sid
                    self:SetText("Custom SteamID64 (" .. sid .. ")")
                    RefreshStatus()
                end)
            else
                panel.Selected = value
                RefreshStatus()
            end
        end

        function search:OnValueChange(value)
            panel.SearchValue = string.lower(string.Trim(value or ""))
            RefreshItems()
        end

        RefreshItems()
    end)
else
    util.AddNetworkString("impulseOpsItemSpawner")
end


local giveItemCommand = {
    description = "Gives a player the specified item. Use /itemspawner instead.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, arg, rawText)
        if !client:IsSuperAdmin() then return end

        local steamid = arg[1]
        local item = arg[2]

        if !item then
            return client:Notify("No item uniqueID supplied.")
        end

        if steamid:len() > 25 then
            return client:Notify("SteamID64 too long.")
        end

        local query = mysql:Select("impulse_players")
        query:Select("id")
        query:Where("steamid", steamid)
        query:Callback(function(result)
            if type(client) != "Player" then return end

            if !result or #result < 1 then
                return client:Notify("This Steam account has not joined the server yet or the SteamID64 is invalid.")
            end

            if !impulse.Inventory.ItemsStored[item] then
                return client:Notify("Item: " .. item .. " does not exist.")
            end

            local target = player.GetBySteamID64(steamid)

            if target and IsValid(target) then
                target:GiveItem(item)
                return client:Notify("You have given " .. target:Nick() .. " a " .. item .. ".")
            end

            local impulseID = result[1].id

            impulse.Inventory:AddItem(impulseID, item)
            client:Notify("Offline player (" .. steamid .. ") has been given a " .. item .. ".")
        end)

        query:Execute()
    end
}

impulse.RegisterChatCommand("/giveitem", giveItemCommand)

local itemSpawnerCommand = {
    description = "Opens the item spawner.",
    superAdminOnly = true,
    onRun = function(client, arg, rawText)
        if !client:IsSuperAdmin() then return end

        net.Start("impulseOpsItemSpawner")
        net.Send(client)
    end
}

impulse.RegisterChatCommand("/itemspawner", itemSpawnerCommand)
