net.Receive("impulseChatText", function()
    local data = net.ReadTable()
    if ( !data ) then return end

    chat.AddText(unpack(data))
end)

net.Receive("impulseSurfaceSound", function()
    surface.PlaySound(net.ReadString())
end)

net.Receive("impulseJoinData", function()
    impulse_isNewPlayer = net.ReadBool() -- this is saved as a normal global variable cuz impulse or localplayer have not loaded yet on the client
end)

net.Receive("impulseNotify", function(len)
    local message = net.ReadString()
    if ( !LocalPlayer() or !LocalPlayer().Notify ) then return end

    LocalPlayer():Notify(message)
end)

net.Receive("impulseATMOpen", function()
    vgui.Create("impulseATMMenu")
end)

net.Receive("impulseReadNote", function()
    local text = net.ReadString()

    local mainFrame = vgui.Create("DFrame")
    mainFrame:SetSize(300, 500)
    mainFrame:Center()
    mainFrame:MakePopup()
    mainFrame:SetTitle("Letter")

    local textFrame = vgui.Create( "DTextEntry", mainFrame )
    textFrame:SetPos(25, 50)
    textFrame:Dock(FILL)
    textFrame:SetText(text)
    textFrame:SetEditable(false)
    textFrame:SetMultiline(true)
end)

net.Receive("impulseChatNetMessage", function(len)
    local id = net.ReadUInt(8)
    local message = net.ReadString()
    local target = net.ReadUInt(8)
    local chatClass = impulse.chatClasses[id]
    local plyTarget = Entity(target)

    if target == 0 then
        chatClass(message)
    elseif IsValid(plyTarget) then
        chatClass(message, plyTarget)
    end

    hook.Run("impulseChatNetMessage", id, message, target)
end)

net.Receive("impulseSendJailInfo", function()
    local endTime = net.ReadUInt(16)
    local hasJailData = net.ReadBool()
    local jailData

    if hasJailData then
        jailData = net.ReadTable()
    end

    impulse_JailDuration = endTime
    impulse_JailTimeEnd = CurTime() + endTime
    impulse_JailData = jailData or nil

    hook.Run("PlayerGetJailData", endTime, jailData)
end)

net.Receive("impulseBudgetSound", function()
    local ent = Entity(net.ReadUInt(16))
    local snd = net.ReadString()

    if IsValid(ent) then
        ent:EmitSound(snd)
    end
end)

net.Receive("impulseBudgetSoundExtra", function()
    local ent = Entity(net.ReadUInt(16))
    local snd = net.ReadString()
    local level = net.ReadUInt(8)
    local pitch = net.ReadUInt(8)

    if level == 0 then
        level = 75
    end

    if pitch == 0 then
        pitch = 100
    end

    if IsValid(ent) then
        ent:EmitSound(snd, level, pitch)
    end
end)

net.Receive("impulseCinematicMessage", function()
    local title = net.ReadString()

    impulse.CinematicIntro = true
    impulse.CinematicTitle = title
end)

net.Receive("impulseZoneUpdate", function()
    local zone = net.ReadUInt(8)

    impulse.ShowZone = true
    LocalPlayer().impulseZone = zone
end)

net.Receive("impulseQuizForce", function()
    local team = net.ReadUInt(8)
    local quiz = vgui.Create("impulseQuiz")
    quiz:SetQuiz(team)
end)

net.Receive("impulseInvGive", function()
    local netid = net.ReadUInt(16)
    local itemID = net.ReadUInt(16)
    local strid = net.ReadUInt(4)
    local restricted = net.ReadBool()
    local class = net.ReadString() -- Receive class name for proper item lookups

    if !impulse.Inventory.Data[0][strid] then
        impulse.Inventory.Data[0][strid] = {}
    end

    impulse.Inventory.Data[0][strid][itemID] = {
        equipped = false,
        restricted = restricted,
        id = netid,
        class = class -- Store class so UI can resolve item definitions
    }

    if impulse_inventory and IsValid(impulse_inventory) then
        impulse_inventory:SetupItems()
    end
end)

net.Receive("impulseInvMove", function()
    local itemID = net.ReadUInt(16)
    local newitemID = net.ReadUInt(16)
    local from = net.ReadUInt(4)
    local to = net.ReadUInt(4)
    local netid

    local take = impulse.Inventory.Data[0][from][itemID]
    if !take then return end

    netid = take.id

    impulse.Inventory.Data[0][from][itemID] = nil
    impulse.Inventory.Data[0][to][newitemID] = {
        id = netid,
        class = take.class,
        restricted = take.restricted or false,
        equipped = false
    }

    if impulse_storage and IsValid(impulse_storage) then
        local invScroll = impulse_storage.invScroll:GetVBar():GetScroll()
        local invStorageScroll = impulse_storage.invStorageScroll:GetVBar():GetScroll()

        impulse_storage:SetupItems(invScroll, invStorageScroll)

        if (NEXT_MOVENOISE or 0) < CurTime() then -- to stop ear rape when mass moving items
            LocalPlayer():EmitSound("physics/wood/wood_crate_impact_hard2.wav", nil, nil, 0.5, CHAN_ITEM)
        end

        NEXT_MOVENOISE = CurTime() + 0.1
    end
end)

net.Receive("impulseInvRemove", function()
    local itemID = net.ReadUInt(16)
    local strid = net.ReadUInt(4)
    local item = impulse.Inventory.Data[0][strid][itemID]

    if item then
        impulse.Inventory.Data[0][strid][itemID] = nil

        if impulse_inventory and IsValid(impulse_inventory) then
            impulse_inventory:SetupItems()
        end
    end
end)

net.Receive("impulseInvClear", function()
    local storagetype = net.ReadUInt(4)

    if impulse.Inventory.Data[0][storagetype] then
        impulse.Inventory.Data[0][storagetype] = {}
    end
end)

net.Receive("impulseInvClearRestricted", function()
    local storagetype = net.ReadUInt(4)

    if impulse.Inventory.Data[0][storagetype] then
        for v, k in pairs(impulse.Inventory.Data[0][storagetype]) do
            if k.restricted then
                impulse.Inventory.Data[0][storagetype][v] = nil
            end
        end
    end
end)

net.Receive("impulseInvUpdateEquip", function()
    local itemID = net.ReadUInt(16)
    local state = net.ReadBool()
    local item = impulse.Inventory.Data[0][INVENTORY_PLAYER][itemID]

    item.equipped = state or false

    if impulse_inventory and IsValid(impulse_inventory) then
        impulse_inventory:FindItemPanelByID(itemID).IsEquipped = state or false
    end
end)

net.Receive("impulseInvDoSearch", function()
    local searchee = Entity(net.ReadUInt(8))
    local invSize = net.ReadUInt(16)
    local invCompiled = {}

    if !IsValid(searchee) then return end

    for i = 1,invSize do
        local itemnetid = net.ReadUInt(10)
        local item = impulse.Inventory.Items[itemnetid]

        table.insert(invCompiled, item)
    end


    impulse.Util:MakeWorkbar(5, "Searching...", function()
        if !IsValid(searchee) then return end

        local searchMenu = vgui.Create("impulseSearchMenu")
        searchMenu:SetInv(invCompiled)
        searchMenu:SetPlayer(searchee)
    end, true)
end)

net.Receive("impulseInvStorageOpen", function(len, client)
    impulse_storage = vgui.Create("impulseInventoryStorage")
end)

net.Receive("impulseRagdollLink", function()
    local ragdoll = net.ReadEntity()

    if IsValid(ragdoll) then
        LocalPlayer().Ragdoll = ragdoll
    end
end)

net.Receive("impulseUpdateOOCLimit", function()
    local time = net.ReadUInt(16)
    local reset = net.ReadBool()

    if LocalPlayer():IsAdmin() then
        LocalPlayer().OOCLimit = 100
        return
    end

    if reset then
        LocalPlayer().OOCLimit = ((LocalPlayer():IsDonator() and impulse.Config.OOCLimitVIP) or impulse.Config.OOCLimit)
        return
    end

    LocalPlayer().OOCLimit = (LocalPlayer().OOCLimit and LocalPlayer().OOCLimit - 1) or ((LocalPlayer():IsDonator() and impulse.Config.OOCLimitVIP) or impulse.Config.OOCLimit)
    LocalPlayer():Notify("You have " .. LocalPlayer().OOCLimit .. " OOC messages left for " .. string.NiceTime(time) .. ".")
end)

net.Receive("impulseCharacterEditorOpen", function()
    local vo = impulse.Util:GetRandomAmbientVO("female")
    surface.PlaySound(vo)

    vgui.Create("impulseCharacterEditor")
end)

net.Receive("impulseUpdateDefaultModelSkin", function()
    impulse_defaultModel = net.ReadString()
    impulse_defaultSkin = net.ReadUInt(8)
end)

net.Receive("impulseConfiscateCheck", function()
    local item = net.ReadEntity()

    if IsValid(item) then
        local name = item and item.HUDName or "unknown item"
        local request = Derma_Query("Would you like to confiscate this " .. name .. "?",
            "impulse",
            "Confiscate",
            function()
                net.Start("impulseDoConfiscate")
                net.SendToServer()
            end,
            "Cancel")

        function request:Think()
            if !item or !IsValid(item) then
                self:Remove()
            end
        end
    end
end)

net.Receive("impulseSkillUpdate", function()
    local skillid = net.ReadUInt(4)
    local xp = net.ReadUInt(16)
    local name = table.KeyFromValue(impulse.Skills.Skills, skillid)

    if !impulse_IsReady then -- in setup
        impulse.Skills.Data[name] = xp
        return
    end

    local oldLevel = LocalPlayer():GetSkillLevel(name)
    impulse.Skills.Data[name] = xp
    local newLevel = LocalPlayer():GetSkillLevel(name)

    if oldLevel != newLevel then
        LocalPlayer():Notify("You have reached skill level " .. newLevel .. " for the " .. impulse.Skills.GetNiceName(name) .. " skill.")
    end
end)

net.Receive("impulseBenchUse", function()
    vgui.Create("impulseCraftingMenu")
end)

net.Receive("impulseMixDo", function()
    if ( IsValid(impulse.CraftingMenu) and impulse.CraftingMenu.UseItem and impulse.CraftingMenu.UseMix ) then
        impulse.CraftingMenu:DoCraft(impulse.CraftingMenu.UseItem, impulse.CraftingMenu.UseMix)
    end
end)

net.Receive("impulseVendorUse", function()
    if impulse.VendorMenu and IsValid(impulse.VendorMenu) then return end

    impulse.VendorMenu = vgui.Create("impulseVendorMenu")
    impulse.VendorMenu:SetupVendor()
end)

net.Receive("impulseVendorUseDownload", function()
    local vendor = net.ReadString()
    local buyLen = net.ReadUInt(32)
    local buy = pon.decode(net.ReadData(buyLen))
    local sellLen = net.ReadUInt(32)
    local sell = pon.decode(net.ReadData(sellLen))

    impulse.Vendor.Data[vendor].Buy = buy
    impulse.Vendor.Data[vendor].Sell = sell

    if impulse.VendorMenu and IsValid(impulse.VendorMenu) then return end

    impulse.VendorMenu = vgui.Create("impulseVendorMenu")
    impulse.VendorMenu:SetupVendor()
end)

net.Receive("impulseViewWhitelists", function()
    local targ = impulse_WhitelistReqTarg

    if !targ or !IsValid(targ) then return end

    local count = net.ReadUInt(4)
    local top = targ:SteamName() .. "'s whitelist(s):\n\n"
    local mid = ""

    for i = 1, count do
        local teamid = net.ReadUInt(8)
        local level = net.ReadUInt(8)
        local teamname = team.GetName(teamid)
        mid = mid .. teamname .. "   Level: " .. level .. "\n"
    end

    if mid == "" then
        mid = "None"
    end

    Derma_Message(top .. mid, targ:SteamName() .. "'s whitelist(s)", "Close")
end)

net.Receive("impulseInvContainerCodeTry", function()
    Derma_StringRequest("impulse", "Enter container passcode (numerics only):", nil, function(text)
        local code = tonumber(text)

        if code then
            code = math.floor(code)

            if code < 0 then
                return LocalPlayer():Notify("Passcode can not be negative.")
            end

            net.Start("impulseInvContainerCodeReply")
            net.WriteUInt(code, 16)
            net.SendToServer()
        else
            LocalPlayer():Notify("Passcode must only contain numeric characters.")
        end
    end, nil, "Enter")
end)

net.Receive("impulseInvContainerOpen", function()
    local count = net.ReadUInt(8)
    local containerInv = {}

    for i = 1,count do
        local itemClass = net.ReadString()
        local amount = net.ReadUInt(8)

        if ( itemClass and itemClass != "" ) then
            containerInv[itemClass] = {amount = amount}
        end
    end

    if impulse_container and IsValid(impulse_container) then
        impulse_container:Remove()
    end

    impulse_container = vgui.Create("impulseInventoryContainer")
    impulse_container:SetupContainer()
    impulse_container:SetupItems(containerInv)
end)

net.Receive("impulseInvContainerUpdate", function()
    local count = net.ReadUInt(8)
    local containerInv = {}

    for i = 1,count do
        local itemClass = net.ReadString()
        local amount = net.ReadUInt(8)

        if ( itemClass and itemClass != "" ) then
            containerInv[itemClass] = {amount = amount}
        end
    end

    if impulse_container and IsValid(impulse_container) then
        local invScroll = impulse_container.invScroll:GetVBar():GetScroll()
        local invStorageScroll = impulse_container.invStorageScroll:GetVBar():GetScroll()

        impulse_container:SetupItems(containerInv, invScroll, invStorageScroll)
        surface.PlaySound("physics/wood/wood_crate_impact_hard2.wav")
    end
end)

net.Receive("impulseInvContainerSetCode", function()
    Derma_StringRequest("impulse",
        "Enter new container passcode:",
        nil, function(text)
            if !tonumber(text) then
                return LocalPlayer():Notify("Passcode must be a number.")
            end

            local passcode = tonumber(text)
            passcode = math.floor(passcode)

            if passcode < 1000 or passcode > 9999 then
                return LocalPlayer():Notify("Passcode must have 4 digits.")
            end

            net.Start("impulseInvContainerDoSetCode")
            net.WriteUInt(passcode, 16)
            net.SendToServer()
        end, nil, "Set Passcode")
end)

net.Receive("impulseAchievementGet", function()
    local achievementCode = net.ReadString()

    if !impulse.Achievements then return end

    local get = vgui.Create("impulseAchievementNotify")
    get:SetAchivement(achievementCode)

    impulse.Achievements[achievementCode] = math.floor(os.time())
end)

net.Receive("impulseAchievementSync", function()
    impulse.Achievements = {}
    local count = net.ReadUInt(8)

    for i = 1, count do
        local id = net.ReadString()
        local time = net.ReadUInt(32)

        impulse.Achievements[id] = time
    end
end)

net.Receive("impulseGetRefund", function()
    local messageTop = "You have been refunded for a server crash/restart.\nThe funds will be deposited into your bank.\n\nDetails:"
    local details = ""

    local count = net.ReadUInt(8)
    local amount = net.ReadUInt(16)

    for i = 1, count do
        local name = net.ReadString()
        local itemAmount = net.ReadUInt(8)

        details = details .. "\n" .. itemAmount .. "x" .. " " .. name
    end

    details = details .. "\nTOTAL REFUND: " .. impulse.Config.CurrencyPrefix .. amount

    REFUND_MSG = messageTop .. details
end)

net.Receive("impulseGroupMember", function()
    local sid = net.ReadString()
    local name = net.ReadString()
    local rank = net.ReadString()

    impulse.Group.Groups[1] = impulse.Group.Groups[1] or {}
    impulse.Group.Groups[1].Members = impulse.Group.Groups[1].Members or {}

    impulse.Group.Groups[1].Members[sid] = {Name = name, Rank = rank}

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end
end)

net.Receive("impulseGroupRanks", function()
    local len = net.ReadUInt(32)
    local ranks = pon.decode(net.ReadData(len))

    impulse.Group.Groups[1] = impulse.Group.Groups[1] or {}
    impulse.Group.Groups[1].Ranks = ranks

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end
end)

net.Receive("impulseGroupRank", function()
    local name = net.ReadString()
    local len = net.ReadUInt(32)
    local rank = pon.decode(net.ReadData(len))

    if name then return end

    if !impulse.Group.Groups[1] then
        impulse.Group.Groups[1] = {}
    end

    if !impulse.Group.Groups[1].Ranks then
        impulse.Group.Groups[1].Ranks = {}
    end

    impulse.Group.Groups[1].Ranks[name] = rank

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end
end)

net.Receive("impulseGroupMemberRemove", function()
    local sid = net.ReadString()

    impulse.Group.Groups[1] = impulse.Group.Groups[1] or {}
    impulse.Group.Groups[1].Members = impulse.Group.Groups[1].Members or {}

    impulse.Group.Groups[1].Members[sid] = nil

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end
end)

net.Receive("impulseGroupInvite", function()
    local groupName = net.ReadString()
    local inviterName = net.ReadString()

    impulse.Group.Groups[1] = {}
    impulse.Group.Invites[groupName] = inviterName

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end

    LocalPlayer():Notify("You have been invited to a group. Press F6 to accept it.")
end)

net.Receive("impulseGroupMetadata", function()
    local info = net.ReadString()
    local col = net.ReadColor()

    impulse.Group.Groups[1] = impulse.Group.Groups[1] or {}

    if col.r == 0 and col.g == 0 and col.b == 0 then
        impulse.Group.Groups[1].Color = nil
    else
        impulse.Group.Groups[1].Color = col
    end

    impulse.Group.Groups[1].Info = info

    if IsValid(impulse.groupEditor) then
        impulse.groupEditor:Refresh()
    end
end)

net.Receive("impulseGetButtons", function()
    local count = net.ReadUInt(16)

    impulse_ActiveButtons = {}

    for i = 1,count do
        local entIndex = net.ReadUInt(16)
        local buttonId = net.ReadUInt(16)

        impulse_ActiveButtons[entIndex] = buttonId
    end
end)

net.Receive("impulsePlayGesture", function()
    local client = net.ReadPlayer()
    if ( type(client) != "Player" ) then return end

    local gesture = net.ReadString()
    local slot = net.ReadInt(16)

    impulse.Util:PlayGesture(client, gesture, slot)
end)

net.Receive("impulseClearWorkbar", function()
    if ( IsValid(impulse.WorkbarPanel) ) then
        impulse.WorkbarPanel:Remove()
    end
end)

net.Receive("impulseMakeWorkbar", function()
    if ( IsValid(impulse.WorkbarPanel) ) then
        impulse.WorkbarPanel:Remove()
    end

    local time = net.ReadUInt(6) or nil
    local text = net.ReadString() or nil
    local popup = net.ReadBool() or nil

    impulse.Util:MakeWorkbar(time, text, nil, popup)
end)
