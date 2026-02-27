local PANEL = {}

local grey = Color(209, 209, 209)

function PANEL:Init()
    self:SetSize(700, 470)
    self:Center()
    self:SetTitle("Storage")
    self:MakePopup()

    self:SetupItems()
end

function PANEL:PaintOver(w, h)
    draw.SimpleText("You", "Impulse-Elements23-Shadow", 5, 30, grey)
    if self.invWeight then
        draw.SimpleText(self.invWeight .. "kg/" .. impulse.Config.InventoryMaxWeight .. "kg", "Impulse-Elements18-Shadow", 345, 35, grey, TEXT_ALIGN_RIGHT)
    end

    draw.SimpleText("Storage", "Impulse-Elements23-Shadow", w - 5, 30, grey, TEXT_ALIGN_RIGHT)
    if self.storageWeight then
        draw.SimpleText(self.storageWeight .. "kg/" .. LocalPlayer():GetMaxInventoryStorage() .. "kg", "Impulse-Elements18-Shadow", 355, 35, grey, TEXT_ALIGN_LEFT)
    end
end

function PANEL:SetupItems(invscroll, storescroll)
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
    local realInv = impulse.Inventory.Data[0][INVENTORY_PLAYER]
    local localInv = table.Copy(impulse.Inventory.Data[0][INVENTORY_PLAYER]) or {}
    local storageWeight = 0
    local realInvStorage = impulse.Inventory.Data[0][INVENTORY_STORAGE]
    local localInvStorage = table.Copy(impulse.Inventory.Data[0][INVENTORY_STORAGE]) or {}
    local reccurTemp = {}
    local sortMethod = impulse.Settings:Get("inv_sortweight", "Inventory only")
    local invertSort = true

    for v, k in pairs(localInv) do -- fix for fucking table.sort desyncing client/server itemids!!!!!!!
        if !istable(k) then
            localInv[v] = nil
            continue
        end

        local itemData, itemNetID = impulse.Inventory:ResolveItem(k)
        if !itemData or !itemNetID then
            localInv[v] = nil
            continue
        end

        k._itemNetID = itemNetID
        k.realKey = v

        if sortMethod == "Always" or sortMethod == "Containers only" then
            reccurTemp[itemNetID] = (reccurTemp[itemNetID] or 0) + (itemData.Weight or 0)
            k.sortWeight = reccurTemp[itemNetID]
        else
            k.sortWeight = itemData.Name or ""
            invertSort = false
        end
    end

    local reccurTemp = {}

    for v, k in pairs(localInvStorage) do
        if !istable(k) then
            localInvStorage[v] = nil
            continue
        end

        local itemData, itemNetID = impulse.Inventory:ResolveItem(k)
        if !itemData or !itemNetID then
            localInvStorage[v] = nil
            continue
        end

        k._itemNetID = itemNetID
        k.realKey = v

        if sortMethod == "Always" or sortMethod == "Containers only" then
            reccurTemp[itemNetID] = (reccurTemp[itemNetID] or 0) + (itemData.Weight or 0)
            k.sortWeight = reccurTemp[itemNetID]
        else
            k.sortWeight = itemData.Name or ""
            invertSort = false
        end
    end

    if localInv and table.Count(localInv) > 0 then
        for v, k in SortedPairsByMemberValue(localInv, "sortWeight", invertSort) do
            local itemNetID = k._itemNetID or impulse.Inventory:ResolveItemNetID(k)
            local otherItem = itemNetID and self.items[itemNetID]
            local itemX = itemNetID and impulse.Inventory.Items[itemNetID]
            if !itemX or !itemNetID then continue end

            if impulse.Inventory:ShouldStackItem(itemX) and otherItem then
                otherItem.Count = (otherItem.Count or 1) + 1
            else
                local item = self.invScroll:Add("impulseInventoryItem")
                item:Dock(TOP)
                item:DockMargin(0, 0, 0, 5)
                item.Basic = true
                item.Type = 1
                item:SetItem(k, w)
                item.InvID = k.realKey
                item.InvPanel = self
                self.items[itemNetID] = item
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

    if localInvStorage and table.Count(localInvStorage) > 0 then
        for v, k in SortedPairsByMemberValue(localInvStorage, "sortWeight", invertSort) do
            local itemNetID = k._itemNetID or impulse.Inventory:ResolveItemNetID(k)
            local otherItem = itemNetID and self.itemsStorage[itemNetID]
            local itemX = itemNetID and impulse.Inventory.Items[itemNetID]
            if !itemX or !itemNetID then continue end

            if impulse.Inventory:ShouldStackItem(itemX) and otherItem then
                otherItem.Count = (otherItem.Count or 1) + 1
            else
                local item = self.invStorageScroll:Add("impulseInventoryItem")
                item:Dock(TOP)
                item:DockMargin(0, 0, 0, 5)
                item.Basic = true
                item.Type = 2
                item:SetItem(k, w)
                item.InvID = k.realKey
                item.InvPanel = self
                self.itemsStorage[itemNetID] = item
            end

            storageWeight = storageWeight + (itemX.Weight or 0)
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

vgui.Register("impulseInventoryStorage", PANEL, "DFrame")
