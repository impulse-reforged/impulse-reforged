local logs = impulse.Logs

--- Allows interactions with the players inventory
-- @module impulse.Inventory

INVENTORY_NIL = 0
INVENTORY_PLAYER = 1
INVENTORY_STORAGE = 2

impulse.Inventory = impulse.Inventory or {}
impulse.Inventory.Data = impulse.Inventory.Data or {}

--- Inserts an inventory item into the database. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @string class Class name of the item to add
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:AddItem(ownerid, class, storagetype)
    storagetype = storagetype or INVENTORY_PLAYER

    local query = mysql:Insert("impulse_inventory")
    query:Insert("uniqueid", class)
    query:Insert("ownerid", ownerid)
    query:Insert("storagetype", storagetype or INVENTORY_PLAYER)
    query:Execute()
end

--- Deletes an inventory item from the database. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @string class Class name of the item to remove
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @int[opt=1] limit The amount of items to remove
function impulse.Inventory:RemoveItem(ownerid, class, storagetype, limit)
    local query = mysql:Delete("impulse_inventory")
    query:Where("ownerid", ownerid)
    query:Where("uniqueid", class)
    query:Where("storagetype", storagetype or INVENTORY_PLAYER)
    query:Limit(limit or 1)

    query:Execute()
end

--- Clears a players inventory. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:ClearInventory(ownerid, storagetype)
    local query = mysql:Delete("impulse_inventory")
    query:Where("ownerid", ownerid)
    query:Where("storagetype", storagetype or INVENTORY_PLAYER)
    query:Execute()
end

--- Prints all possible data from the impulse_inventory table
-- @realm server
function impulse.Inventory:PrintAll()
    local query = mysql:Select("impulse_inventory")
    query:Callback(function(result)
        print("Printing impulse_inventory table:")
        PrintTable(result)
    end)
    query:Execute()
end

concommand.Add("impulse_inventory_printall", function(ply)
    if ( !IsValid(ply) or !ply:IsSuperAdmin() ) then return end

    impulse.Inventory:PrintAll()
end)

--- Updates the storage type for an existing item. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @string class Class name of the item to update
-- @int[opt=1] limit The amount of items to update
-- @int oldstoragetype Old storage type (1 is player inventory, 2 is storage)
-- @int newstoragetype New storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:UpdateStorageType(ownerid, class, limit, oldstoragetype, newstoragetype)
    oldstoragetype = oldstoragetype or INVENTORY_PLAYER
    newstoragetype = newstoragetype or INVENTORY_PLAYER

    if oldstoragetype == newstoragetype then return end

    local queryGet = mysql:Select("impulse_inventory")
    queryGet:Select("id")
    queryGet:Select("storagetype")
    queryGet:Where("ownerid", ownerid)
    queryGet:Where("uniqueid", class)
    queryGet:Where("storagetype", oldstoragetype)
    queryGet:Limit(limit or 1)
    queryGet:Callback(function(result) -- workaround because limit doesnt work for update queries
        if type(result) == "table" and #result > 0 then
            for v, k in pairs(result) do
                local query = mysql:Update("impulse_inventory")
                query:Update("storagetype", newstoragetype)
                query:Where("id", k.id)
                query:Where("storagetype", k.storagetype)
                query:Execute()
            end
        end
    end)

    queryGet:Execute()
end

--- Spawns an inventory item as an Entity
-- @realm server
-- @string class Class name of the item to spawn
-- @vector pos limit The spawn position
-- @player[opt] bannedPlayer Player to ban from picking up 
-- @int[opt] killTime Time until the item is removed automatically
-- @treturn entity Spawned item
function impulse.Inventory:SpawnItem(class, pos, bannedPlayer, killTime)
    local itemID = impulse.Inventory:ClassToNetID(class)
    if not itemID then return logs.Error("Attempting to spawn nil item!") end
    
    local item = ents.Create("impulse_item")
    item:SetItem(itemID)
    item:SetPos(pos)

    if bannedPlayer then
        item.BannedUser = bannedPlayer
    end

    if killTime then
        item.RemoveIn = CurTime() + killTime
    end
    
    item:Spawn()

    return item
end

--- Spawns a workbench
-- @realm server
-- @string class Class name of the workbench
-- @vector pos limit The spawn position
-- @angle ang The spawn angle
-- @treturn entity Spawned workbench
function impulse.Inventory:SpawnBench(class, pos, ang)
    local benchClass = impulse.Inventory.Benches[class]
    if not benchClass then return logs.Error("Attempting to spawn nil bench!") end

    local bench = ents.Create("impulse_bench")
    bench:SetBench(benchClass)
    bench:SetPos(pos)
    bench:SetAngles(ang)
    bench:Spawn()

    return bench
end

local PLAYER = FindMetaTable("Player")

--- Gets a players inventory table
-- @realm server
-- @int[opt=1] type Storage type (1 is player inventory, 2 is storage)
-- @treturn table Inventory
function PLAYER:GetInventory(type)
    return impulse.Inventory.Data[self.impulseID][type or 1]
end

--- Returns if a player can hold an item in their local inventory
-- @realm server
-- @string class Item class name
-- @int[opt=1] amount Amount of the item
-- @treturn bool Can hold item
function PLAYER:CanHoldItem(class, amount)
    local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]
    local weight = ( item.Weight or 0 ) * (amount or 1)

    return self.InventoryWeight + weight <= impulse.Config.InventoryMaxWeight
end

--- Returns if a player can hold an item in their storage chest
-- @realm server
-- @string class Item class name
-- @int[opt=1] amount Amount of the item
-- @treturn bool Can hold item
function PLAYER:CanHoldItemStorage(class, amount)
    local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]
    local weight = ( item.Weight or 0 ) * (amount or 1)

    if ( self:IsDonator() ) then
        return self.InventoryWeightStorage + weight <= impulse.Config.InventoryStorageMaxWeightDonator
    else
        return self.InventoryWeightStorage + weight <= impulse.Config.InventoryStorageMaxWeight
    end
end

--- Returns if a player has an item in their local inventory
-- @realm server
-- @string class Item class name
-- @int[opt=1] amount Amount of the item
-- @treturn bool Has item
function PLAYER:HasInventoryItem(class, amount)
    local has = self.InventoryRegister[class]

    if ( amount ) then
        if has and has >= amount then
            return true, has
        else
            return false, has
        end
    end

    if ( has ) then
        return true, has
    end

    return false
end

--- Returns if a player has an item in their storage chest
-- @realm server
-- @string class Item class name
-- @int[opt=1] amount Amount of the item
-- @treturn bool Has item
function PLAYER:HasInventoryItemStorage(class, amount)
    local has = self.InventoryStorageRegister[class]

    if ( amount ) then
        if has and has >= amount then
            return true, has
        else
            return false, has
        end
    end

    if ( has ) then
        return true, has
    end

    return false
end

--- Returns if a player has an specific item. This is used to check if they have the exact item, not just an item of the class specified
-- @realm server
-- @int itemID Item ID
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Has item
function PLAYER:HasInventoryItemSpecific(itemID, storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local has = impulse.Inventory.Data[self.impulseID][storagetype][itemID]
    if ( has ) then
        return true, has
    end

    return false
end

--- Returns if a player has an illegal inventory item
-- @realm server
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Has illegal item
-- @treturn int Item ID of illegal item
function PLAYER:HasIllegalInventoryItem(storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local inv = self:GetInventory(storagetype)

    for k, v in pairs(inv) do
        local class = impulse.Inventory:ClassToNetID(v.class)
        local item = impulse.Inventory.Items[class]

        if ( !v.restricted and item.Illegal ) then
            return true, k
        end
    end

    return false
end

--- Returns if a specific inventory item is restricted
-- @realm server
-- @int itemID Item ID
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Is restricted
function PLAYER:IsInventoryItemRestricted(itemID, storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local has = impulse.Inventory.Data[self.impulseID][storagetype][itemID]
    if ( has ) then
        return has.restricted
    end

    return false
end

--- Gives an inventory item to a player
-- @realm server
-- @string class Item class name
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @bool[opt=false] restricted Is item restricted
-- @bool[opt=false] isLoaded (INTERNAL) Used for first time setup when player connects
-- @bool[opt=false] moving (INTERNAL) Is item just being moved? (stops database requests)
-- @int[opt] clip (INTERNAL) (Only used for weapons) Item clip
-- @treturn int ItemID
function PLAYER:GiveItem(class, storagetype, restricted, isLoaded, moving, clip) -- isLoaded is a internal arg used for first time item setup, when they are already half loaded
    if ( !self.impulseBeenInventorySetup and !isLoaded ) then
        return
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local restricted = restricted or false
    local itemNet = impulse.Inventory:ClassToNetID(class)
    local weight = impulse.Inventory.Items[itemNet].Weight or 0
    local impulseID = self.impulseID

    local inv = impulse.Inventory.Data[impulseID][storagetype]
    local itemID 

    for i = 1, ( table.Count(inv) + 1 ) do -- intellegent table insert looks for left over ids to reuse to stop massive id's that cant be networked
        if ( inv[i] == nil ) then
            itemID = i

            impulse.Inventory.Data[impulseID][storagetype][i] = {
                id = itemNet,
                class = class,
                restricted = restricted,
                equipped = false,
                clip = clip or nil
            }

            break
        end
    end

    if ( !restricted and !isLoaded and !moving ) then
        impulse.Inventory:AddItem(impulseID, class, storagetype)
    end
    
    if ( storagetype == INVENTORY_PLAYER ) then
        self.InventoryWeight = self.InventoryWeight + weight
        self.InventoryRegister[class] = (self.InventoryRegister[class] or 0) + 1 -- use a register that copies the actions of the real inv for search efficiency
    elseif ( storagetype == INVENTORY_STORAGE ) then
        self.InventoryWeightStorage = self.InventoryWeightStorage + weight
        self.InventoryStorageRegister[class] = (self.InventoryStorageRegister[class] or 0) + 1 -- use a register that copies the actions of the real inv for search efficiency
    end

    if ( !moving ) then
        net.Start("impulseInvGive")
            net.WriteUInt(itemNet, 16) 
            net.WriteUInt(itemID, 16)
            net.WriteUInt(storagetype, 4)
            net.WriteBool(restricted or false)
        net.Send(self)
    end

    return itemID
end

--- Takes an inventory item from a player
-- @realm server
-- @int itemID Item ID
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @bool[opt=false] moving (INTERNAL) Is item just being moved? (stops database requests)
-- @treturn int Clip
function PLAYER:TakeInventoryItem(itemID, storagetype, moving)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local amount = amount or 1
    local impulseID = self.impulseID
    local itemData = impulse.Inventory.Data[impulseID][storagetype][itemID]
    local itemNet = impulse.Inventory:ClassToNetID(itemData.class)
    local weight = (impulse.Inventory.Items[itemNet].Weight or 0) * amount

    if ( !moving ) then
        impulse.Inventory:RemoveItem(self.impulseID, itemData.class, storagetype, 1)
    end

    if ( storagetype == INVENTORY_PLAYER ) then
        self.InventoryWeight = math.Clamp(self.InventoryWeight - weight, 0, 1000)
    elseif ( storagetype == INVENTORY_STORAGE ) then
        self.InventoryWeightStorage = math.Clamp(self.InventoryWeightStorage - weight, 0, 1000)
    end

    if ( storagetype == INVENTORY_PLAYER ) then
        local regvalue = self.InventoryRegister[itemData.class]
        self.InventoryRegister[itemData.class] = regvalue - 1

        if self.InventoryRegister[itemData.class] < 1 then -- any negative values to be removed
            self.InventoryRegister[itemData.class] = nil
        end
    elseif ( storagetype == INVENTORY_STORAGE ) then
        local regvalue = self.InventoryStorageRegister[itemData.class]
        self.InventoryStorageRegister[itemData.class] = regvalue - 1

        if self.InventoryStorageRegister[itemData.class] < 1 then -- any negative values to be removed
            self.InventoryStorageRegister[itemData.class] = nil
        end
    end

    if ( itemData.equipped ) then
        self:SetInventoryItemEquipped(itemID, false)
    end

    local clip = itemData.clip

    hook.Run("OnInventoryItemRemoved", self, storagetype, itemData.class, itemData.id, itemData.equipped, itemData.restricted, itemID)

    impulse.Inventory.Data[impulseID][storagetype][itemID] = nil
    
    if ( !moving ) then
        net.Start("impulseInvRemove")
            net.WriteUInt(itemID, 16)
            net.WriteUInt(storagetype, 4)
        net.Send(self)
    end

    return clip
end

--- Clears a players inventory
-- @realm server
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearInventory(storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER

    local inv = self:GetInventory(storagetype)

    for v, k in pairs(inv) do
        self:TakeInventoryItem(v, storagetype, true)
    end

    impulse.Inventory:ClearInventory(self.impulseID, storagetype)

    net.Start("impulseInvClear")
    net.WriteUInt(storagetype, 4)
    net.Send(self)
end

--- Clears restricted items from a players inventory
-- @realm server
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearRestrictedInventory(storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end
    local storagetype = storagetype or INVENTORY_PLAYER

    local inv = self:GetInventory(storagetype)

    for v, k in pairs(inv) do
        if k.restricted then
            self:TakeInventoryItem(v, storagetype, true)
        end
    end

    net.Start("impulseInvClearRestricted")
    net.WriteUInt(storagetype, 4)
    net.Send(self)
end

--- Clears illegal items from a players inventory
-- @realm server
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearIllegalInventory(storagetype)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end
    local storagetype = storagetype or INVENTORY_PLAYER

    local inv = self:GetInventory(storagetype)

    for v, k in pairs(inv) do
        local itemData = impulse.Inventory.Items[k.id]

        if itemData and itemData.Illegal then
            self:TakeInventoryItem(v)
        end
    end
end

--- Takes an item from a players inventory by class name
-- @realm server
-- @string class Item class name
-- @int[opt=1] storagetype Storage type (1 is player inventory, 2 is storage)
-- @int[opt=1] amount Amount to take
function PLAYER:TakeInventoryItemClass(class, storagetype, amount)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local storagetype = storagetype or INVENTORY_PLAYER
    local amount = amount or 1
    local impulseID = self.impulseID

    local count = 0
    for v, k in pairs(impulse.Inventory.Data[impulseID][storagetype]) do
        if k.class == class then
            count = count + 1
            self:TakeInventoryItem(v, storagetype)

            if count == amount then return end
        end
    end
end

--- Sets a specific inventory item as equipped or not
-- @realm server
-- @int itemID Item ID
-- @bool state Is equipped
function PLAYER:SetInventoryItemEquipped(itemID, state)
    local item = impulse.Inventory.Data[self.impulseID][1][itemID]

    if not item then return end
    
    local id = impulse.Inventory:ClassToNetID(item.class)
    local onEquip = impulse.Inventory.Items[id].OnEquip
    local unEquip = impulse.Inventory.Items[id].UnEquip
    if not onEquip then return end
    local class = impulse.Inventory.Items[id]
    local isAlive = self:Alive()

    if class.CanEquip and !class.CanEquip(item, self) then return end

    local canEquip = hook.Run("PlayerCanEquipItem", self, class, item)

    if canEquip != nil and !canEquip then return end

    if class.EquipGroup then
        local equippedItem = self.InventoryEquipGroups[class.EquipGroup]
        if equippedItem and equippedItem != itemID then
            self:SetInventoryItemEquipped(equippedItem, false)
        end 
    end

    if state then
        if class.EquipGroup then
            self.InventoryEquipGroups[class.EquipGroup] = itemID
        end
        onEquip(item, self, class, itemID)
        if isAlive then self:EmitSound("impulse-reforged/equip.wav") end
    elseif unEquip then
        if class.EquipGroup then
            self.InventoryEquipGroups[class.EquipGroup] = nil
        end
        unEquip(item, self, class, itemID)
        if isAlive then self:EmitSound("impulse-reforged/unequip.wav") end
    end

    item.equipped = state

    net.Start("impulseInvUpdateEquip")
    net.WriteUInt(itemID, 16)
    net.WriteBool(state or false)
    net.Send(self)
end

--- Un equips all iventory items for a player
-- @realm server
function PLAYER:UnEquipInventory()
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    local inv = self:GetInventory(1)

    for k, v in pairs(inv) do
        if ( v.equipped ) then
            self:SetInventoryItemEquipped(k, false)
        end
    end
end

--- Drops a specific inventory item
-- @realm server
-- @int itemID Item ID
function PLAYER:DropInventoryItem(itemID)
    local trace = {}
    trace.start = self:EyePos()
    trace.endpos = trace.start + self:GetAimVector() * 48
    trace.filter = self

    local item = impulse.Inventory.Data[self.impulseID][1][itemID]
    local tr = util.TraceLine(trace)

    local itemNet = impulse.Inventory:ClassToNetID(item.class)
    local class = impulse.Inventory.Items[itemNet]

    if ( item.restricted and !class.DropIfRestricted ) then
        return
    end

    self:TakeInventoryItem(itemID)

    self.DroppedItemsC = (self.DroppedItemsC or 0)
    self.DroppedItems = self.DroppedItems or {}
    self.DroppedItemsCA = (self.DroppedItemsCA and self.DroppedItemsCA + 1) or 1

    if ( self.DroppedItemsC >= impulse.Config.DroppedItemsLimit ) then
        for k, v in pairs(self.DroppedItems) do
            if ( IsValid(v) and v.ItemOwner and v.ItemOwner == self ) then
                v:Remove()
                break
            end
        end
    end

    local ent = impulse.Inventory:SpawnItem(item.class, tr.HitPos)
    ent.ItemOwner = self

    if ( class.WeaponClass and item.clip ) then
        ent.ItemClip = item.clip
    end

    self.DroppedItemsC = self.DroppedItemsC + 1
    self.DroppedItems[self.DroppedItemsCA] = ent
    self.NextItemDrop = CurTime() + 2

    ent.DropIndex = self.DroppedItemsCA

    -- Measurements to stop crashes
    if ( self.DroppedItemsC > 5 and ( ( self.NextItemDrop or 0 ) > CurTime() or self.DroppedItemsC > 14 ) ) then
        ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end
end

--- Uses a specific inventory item
-- @realm server
-- @int itemID Item ID
function PLAYER:UseInventoryItem(itemID)
    local class = impulse.Inventory.Data[self.impulseID][1][itemID].class
    local itemNet = impulse.Inventory:ClassToNetID(class)
    local item = impulse.Inventory.Items[itemNet]
    local trEnt

    if ( item.OnUse ) then
        if ( item.ShouldTraceUse ) then
            local trace = {}
            trace.start = self:EyePos()
            trace.endpos = trace.start + self:GetAimVector() * 85
            trace.filter = self

            trEnt = util.TraceLine(trace).Entity

            if ( !trEnt or !IsValid(trEnt) or !item.ShouldTraceUse(item, self, trEnt) ) then
                return
            end
        end

        local shouldRemove = item.OnUse(item, self, trEnt or nil)
        if ( shouldRemove and self:HasInventoryItemSpecific(itemID) ) then
            self:TakeInventoryItem(itemID)
        end
    end
end

--- Moves a specific inventory item across storages (to move several of the same items use MoveInventoryItemMass as it is faster)
-- @realm server
-- @int itemID Item ID
-- @int from Old storage type
-- @int to New storage type
function PLAYER:MoveInventoryItem(itemID, from, to)
    if ( self:IsInventoryItemRestricted(itemID, from) ) then
        return
    end

    local item = impulse.Inventory.Data[self.impulseID][from][itemID]
    local class = item.class

    local itemclip = self:TakeInventoryItem(itemID, from, true)

    impulse.Inventory:UpdateStorageType(self.impulseID, class, 1, from, to)
    local newitemID = self:GiveItem(class, to, false, nil, true, (itemclip or nil))

    net.Start("impulseInvMove")
        net.WriteUInt(itemID, 16)
        net.WriteUInt(newitemID, 16)
        net.WriteUInt(from, 4)
        net.WriteUInt(to, 4)
    net.Send(self)
end

--- Moves a collection of the same items across storages
-- @realm server
-- @string class Item class name
-- @int from Old storage type
-- @int to New storage type
-- @int amount Amount to move
function PLAYER:MoveInventoryItemMass(class, from, to, amount)
    impulse.Inventory:UpdateStorageType(self.impulseID, class, amount, from, to)

    local takes = 0
    for k, v in pairs(self:GetInventory(from)) do
        if ( !v.restricted and v.class == class ) then
            takes = takes + 1

            local itemclip = self:TakeInventoryItem(k, from, true)
            local newitemID = self:GiveItem(class, to, false, nil, true, ( itemclip or nil ))

            net.Start("impulseInvMove")
            net.WriteUInt(k, 16)
            net.WriteUInt(newitemID, 16)
            net.WriteUInt(from, 4)
            net.WriteUInt(to, 4)
            net.Send(self)

            if ( takes >= amount ) then
                return
            end
        end
    end
end

--- Returns if a player can make a mix
-- @realm server
-- @string class Mixture class name
-- @treturn bool Can make mixture
function PLAYER:CanMakeMix(class)
    local skill = self:GetSkillLevel("craft")
    if ( class.Level > skill ) then
        return false
    end

    for k, v in pairs(class.Input) do
        local item = self:HasInventoryItem(k, v.take)
        if ( !item or self:IsInventoryItemRestricted(item) ) then
            return false
        end
    end

    return true
end