local PANEL = {}

local grey = Color(209, 209, 209)

function PANEL:Init()
    self:SetSize(700, 470)
    self:Center()
    self:MakePopup()

    --self:SetupItems()
end

function PANEL:SetupContainer()
    local client = LocalPlayer()

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 120
    trace.filter = client

    local tr = util.TraceLine(trace)

    if hook.Run("IsContainer", tr.Entity) == false then
        print("not impulse container")
        return self:Remove()
    end

    self.container = tr.Entity
    self.isLoot = self.container.GetLoot and self.container:GetLoot() or false

    local containerName = hook.Run("GetContainerName", self.container)
    if ( !containerName or containerName == "" ) then
        local ragdollName = self.container:GetRelay("ragdoll.name", nil)
        if ( ragdollName and ragdollName != "" ) then
            containerName = ragdollName
        end
    end

    self:SetTitle(containerName or ( self.isLoot and "Storage Container" or "Loot Container" ))
end

function PANEL:OnRemove()
    net.Start("impulseInvContainerClose")
    net.SendToServer()
end

function PANEL:PaintOver(w, h)
    local capacity = impulse.Config.InventoryMaxWeight
    if self.container and self.container.GetCapacity then
        capacity = self.container:GetCapacity()
    end

    draw.SimpleText("You", "Impulse-Elements23-Shadow", 5, 30, grey)
    if self.invWeight then
        draw.SimpleText(self.invWeight .. "kg/" .. impulse.Config.InventoryMaxWeight .. "kg", "Impulse-Elements18-Shadow", 345, 35, grey, TEXT_ALIGN_RIGHT)
    end

    draw.SimpleText(self:GetTitle(), "Impulse-Elements23-Shadow", w - 5, 30, grey, TEXT_ALIGN_RIGHT)
    if self.storageWeight and self.container then
        draw.SimpleText(self.storageWeight .. "kg/" .. capacity .. "kg", "Impulse-Elements18-Shadow", 355, 35, grey, TEXT_ALIGN_LEFT)
    end
end

function PANEL:Think()
    if self.container then
        if !IsValid(self.container) or self.container:GetPos():DistToSqr(LocalPlayer():GetPos()) > (120 ^ 2) then
            return self:Remove()
        end

        if !LocalPlayer():Alive()  then
            return self:Remove()
        end

        if LocalPlayer():GetRelay("arrested", false) then
            return self:Remove()
        end
    end
end

function PANEL:SetupItems(containerInv, invscroll, storescroll)
    containerInv = istable(containerInv) and containerInv or {}

    local w,h = self:GetSize()

    if self.invScroll and IsValid(self.invScroll) then
        self.invScroll:Remove()
    end

    if self.invStorageScroll and IsValid(self.invStorageScroll) then
        self.invStorageScroll:Remove()
    end

    self.invScroll = vgui.Create("DScrollPanel", self)
    self.invScroll:SetPos(0, 55)
    self.invScroll:SetSize(346, h - 55)

    self.invStorageScroll = vgui.Create("DScrollPanel", self)
    self.invStorageScroll:SetPos(354, 55)
    self.invStorageScroll:SetSize(346, h - 55)

    self.items = {}
    self.itemPanels = {}
    self.itemsStorage = {}
    self.itemPanelsStorage = {}
    local invWeight = 0
    local invData = impulse.Inventory.Data and impulse.Inventory.Data[0]
    local localInv = table.Copy((invData and invData[INVENTORY_PLAYER]) or {}) or {}
    local storageWeight = 0
    local reccurTemp = {}
    local sortMethod = impulse.Settings:Get("inv_sortweight", "Inventory only")
    local invertSort = true

    for v, k in pairs(localInv) do -- fix for fucking table.sort desyncing client/server itemids!!!!!!!
        if !istable(k) or !k.id then
            localInv[v] = nil
            continue
        end

        k.realKey = v
        local itemData = impulse.Inventory.Items[k.id]

        if !itemData then
            localInv[v] = nil
            continue
        end

        if sortMethod == "Always" or sortMethod == "Containers only" then
            reccurTemp[k.id] = (reccurTemp[k.id] or 0) + (itemData.Weight or 0)
            k.sortWeight = reccurTemp[k.id]
        else
            k.sortWeight = itemData.Name or ""
            invertSort = false
        end
    end

    local reccurTemp = {}

    for v, k in pairs(containerInv) do
        if !istable(k) then
            containerInv[v] = nil
            continue
        end

        k.realKey = v
        local itemData = impulse.Inventory.Items[v]

        if !itemData then
            containerInv[v] = nil
            continue
        end

        local amount = k.amount or 1
        k.amount = amount

        if sortMethod == "Always" or sortMethod == "Containers only" then
            k.sortWeight = (itemData.Weight or 0) * amount
        else
            k.sortWeight = itemData.Name or ""
            invertSort = false
        end
    end

    if localInv and table.Count(localInv) > 0 then
        for v, k in SortedPairsByMemberValue(localInv, "sortWeight", invertSort) do
            local otherItem = self.items[k.id]
            local itemX = impulse.Inventory.Items[k.id]
            if !itemX then continue end

            if itemX.CanStack and otherItem then
                otherItem.Count = (otherItem.Count or 1) + 1
            else
                local item = self.invScroll:Add("impulseInventoryItem")
                item:Dock(TOP)
                item:DockMargin(0, 0, 0, 5)
                item.Basic = true
                item.ContainerInv = true
                item.Type = 1
                item:SetItem(k, w)
                item.InvID = k.realKey
                item.InvPanel = self
                item.Disabled = self.isLoot

                self.items[k.id] = item
            end

            invWeight = invWeight + (itemX.Weight or 0)
        end
    else
        self.empty = self.invScroll:Add("DLabel", self)
        self.empty:SetContentAlignment(5)
        self.empty:Dock(TOP)
        self.empty:SetText("Empty")
        self.empty:SetFont("Impulse-Elements19-Shadow")
    end

    if table.Count(containerInv) > 0 then
        for v, k in SortedPairsByMemberValue(containerInv, "sortWeight", invertSort) do
            local itemX = impulse.Inventory.Items[k.realKey]
            if !itemX then continue end

            local item = self.invStorageScroll:Add("impulseInventoryItem")
            item:Dock(TOP)
            item:DockMargin(0, 0, 0, 5)
            item.Basic = true
            item.ContainerType = true
            item.Type = 2
            item:SetItem(k.realKey, w)
            item.InvClass = k.realKey
            item.InvPanel = self
            item.Count = k.amount
            self.itemsStorage[k.realKey] = item

            storageWeight = storageWeight + ((itemX.Weight or 0) * k.amount)
        end
    else
        self.empty = self.invStorageScroll:Add("DLabel", self)
        self.empty:SetContentAlignment(5)
        self.empty:Dock(TOP)
        self.empty:SetText("Empty")
        self.empty:SetFont("Impulse-Elements19-Shadow")
    end

    self.invWeight = invWeight
    self.storageWeight = storageWeight

    if invscroll then
        self.invScroll:GetVBar():AnimateTo(invscroll, 0)
        self.invStorageScroll:GetVBar():AnimateTo(storescroll, 0)
    end
end

vgui.Register("impulseInventoryContainer", PANEL, "DFrame")
