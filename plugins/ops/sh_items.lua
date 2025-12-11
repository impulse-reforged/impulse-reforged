if ( CLIENT ) then
    net.Receive("impulseOpsItemSpawner", function()
        local panel = vgui.Create("DFrame")
        panel:SetSize(ScrW() / 1.5, ScrH() / 1.25)
        panel:Center()
        panel:SetTitle("Item Spawner")
        panel:MakePopup()

        local targetBox = vgui.Create("DComboBox", panel)
        targetBox:Dock(TOP)
        targetBox:SetWide(400)

        targetBox:AddChoice("Me")
        targetBox:AddChoice("Custom SteamID64 (Offline User)")

        for v, k in player.Iterator() do
            targetBox:AddChoice("PLAYER: " .. k:Nick() .. " (" .. k:SteamName() .. ")", k:SteamID64())
        end

        targetBox:SetSortItems(false)

        function targetBox:OnSelect(index, text, sid)
            if text == "Me" then
                panel.Selected = LocalPlayer():SteamID64()
            elseif text == "Custom SteamID64 (Offline User)" then
                Derma_StringRequest("impulse", "Enter the SteamID64 (not 64 format) below:", "", function(sid)
                    if IsValid(panel) then
                        sid = string.Trim(sid, " ")
                        panel.Selected = sid
                        self:SetText("Custom SteamID64 (" .. sid .. ")")
                    end
                end)
            else
                panel.Selected = sid
            end
        end

        local scroll = vgui.Create("DScrollPanel", panel)
        scroll:Dock(FILL)

        local items = table.Copy(impulse.Inventory.Items)
        table.sort(items, function(a, b) return a.Name < b.Name end)

        local cats = {}
        for v, k in pairs(items) do
            if !cats[k.Category or "Unknown"] then
                local cat = scroll:Add("DCollapsibleCategory")
                cat:Dock(TOP)
                cat:SetLabel(k.Category or "Unknown")

                cats[k.Category or "Unknown"] = vgui.Create("DTileLayout", panel)
                local layout = cats[k.Category or "Unknown"]
                layout:Dock(FILL)
                layout:SetBaseSize(128)
                layout:SetSpaceX(5)
                layout:SetSpaceY(5)
                layout:SetBorder(5)

                cat:SetContents(layout)
            end

            local btn = vgui.Create("DButton", cats[k.Category or "Unknown"])
            btn:SetText("")
            btn:SetSize(128, 128)
            btn:SetTooltip(k.UniqueID)
            btn.ItemClass = k.UniqueID

            function btn:DoClick()
                if !panel.Selected then
                    return LocalPlayer():Notify("No target selected.")
                end

                LocalPlayer():ConCommand("say /giveitem " .. panel.Selected .. " " .. self.ItemClass)
            end

            local label = vgui.Create("DLabel", btn)
            label:SetText(k.Name)
            label:SetFont("Impulse-Elements10")
            label:SizeToContents()
            label:SetPos(btn:GetWide() / 2 - label:GetWide() / 2, 4)

            local mdl = vgui.Create("DModelPanel", btn)
            mdl:SetModel(k.Model or "models/props_junk/watermelon01.mdl")
            mdl:SetSize(128 - 16, 128 - 16)
            mdl:SetPos(btn:GetWide() / 2 - mdl:GetWide() / 2, 16)
            mdl:SetFOV(15)
            mdl:SetCamPos(Vector(50, 50, 50))
            mdl:SetLookAt(vector_origin)
            mdl:SetMouseInputEnabled(false)
        end
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
            if !IsValid(client) then return end

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
