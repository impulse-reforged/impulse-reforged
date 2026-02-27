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
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:AddItem(ownerid, class, storageType)
    storageType = storageType or INVENTORY_PLAYER

    local query = mysql:Insert("impulse_inventory")
    query:Insert("uniqueid", class)
    query:Insert("ownerid", ownerid)
    query:Insert("storageType", storageType or INVENTORY_PLAYER)
    query:Execute()
end

--- Deletes an inventory item from the database. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @string class Class name of the item to remove
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @int[opt = 1] limit The amount of items to remove
function impulse.Inventory:RemoveItem(ownerid, class, storageType, limit)
    local query = mysql:Delete("impulse_inventory")
    query:Where("ownerid", ownerid)
    query:Where("uniqueid", class)
    query:Where("storageType", storageType or INVENTORY_PLAYER)
    query:Limit(limit or 1)
    query:Execute()
end

--- Clears a players inventory. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:ClearInventory(ownerid, storageType)
    local query = mysql:Delete("impulse_inventory")
    query:Where("ownerid", ownerid)
    query:Where("storageType", storageType or INVENTORY_PLAYER)
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

concommand.Add("impulse_inventory_printall", function(client)
    if ( !IsValid(client) or !client:IsSuperAdmin() ) then return end

    impulse.Inventory:PrintAll()
end)

--- Updates the storage type for an existing item. This can be used to control the inventory of offline users
-- @realm server
-- @int ownerid OwnerID number
-- @string class Class name of the item to update
-- @int[opt = 1] limit The amount of items to update
-- @int oldstoragetype Old storage type (1 is player inventory, 2 is storage)
-- @int newstoragetype New storage type (1 is player inventory, 2 is storage)
function impulse.Inventory:UpdateStorageType(ownerid, class, limit, oldstoragetype, newstoragetype)
    oldstoragetype = oldstoragetype or INVENTORY_PLAYER
    newstoragetype = newstoragetype or INVENTORY_PLAYER

    if ( oldstoragetype == newstoragetype ) then return end

    local queryGet = mysql:Select("impulse_inventory")
    queryGet:Select("id")
    queryGet:Select("storageType")
    queryGet:Where("ownerid", ownerid)
    queryGet:Where("uniqueid", class)
    queryGet:Where("storageType", oldstoragetype)
    queryGet:Limit(limit or 1)
    queryGet:Callback(function(result) -- workaround because limit doesnt work for update queries
        if ( type(result) == "table" and #result > 0 ) then
            for v, k in pairs(result) do
                local query = mysql:Update("impulse_inventory")
                query:Update("storageType", newstoragetype)
                query:Where("id", k.id)
                query:Where("storageType", k.storageType)
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
    if ( !itemID ) then return logs:Error("Attempting to spawn nil item!") end

    local item = ents.Create("impulse_item")
    item:SetItem(itemID)
    item:SetPos(pos)

    if ( bannedPlayer ) then
        item.BannedUser = bannedPlayer
    end

    if ( killTime ) then
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
    if ( !benchClass ) then return logs:Error("Attempting to spawn nil bench!") end

    local bench = ents.Create("impulse_bench")
    bench:SetBench(benchClass)
    bench:SetPos(pos)
    bench:SetAngles(ang)
    bench:Spawn()

    return bench
end

local CONTAINER_UPDATE_DISTANCE_SQR = (230 ^ 2)

local function ResolveContainerItem(class)
    local itemID = class

    if ( !isnumber(itemID) ) then
        itemID = impulse.Inventory:ClassToNetID(class)
    end

    if ( !itemID ) then
        return nil, nil
    end

    return impulse.Inventory.Items[itemID], itemID
end

--- Builds a validated network payload for a container inventory.
-- @realm server
-- @entity container Container entity with `Inventory` table
-- @treturn table Payload entries
function impulse.Inventory:BuildContainerPayload(container)
    local payload = {}
    local inv = container and container.Inventory

    if ( !istable(inv) ) then
        return payload
    end

    for class, amount in pairs(inv) do
        local itemData = ResolveContainerItem(class)
        if ( !itemData ) then continue end

        local itemAmount = math.floor(tonumber(amount) or 1)
        if ( itemAmount < 1 ) then continue end

        payload[#payload + 1] = {
            class = itemData.UniqueID or class,
            amount = itemAmount
        }
    end

    return payload
end

--- Sends a single container inventory snapshot over net.
-- @realm server
-- @entity container Container entity
-- @player target Recipient
-- @string[opt=impulseInvContainerUpdate] netMsg Message name
function impulse.Inventory:SendContainerSnapshot(container, target, netMsg)
    if ( !IsValid(target) ) then return end

    local payload = self:BuildContainerPayload(container)

    net.Start(netMsg or "impulseInvContainerUpdate")
    net.WriteUInt(#payload, 8)

    for _, entry in ipairs(payload) do
        net.WriteString(entry.class)
        net.WriteUInt(math.min(entry.amount, 255), 8)
    end

    net.Send(target)
end

--- Adds an item to a container table and updates listeners.
-- @realm server
-- @entity container Container entity
-- @string class Item class
-- @int[opt=1] amount Amount
-- @bool[opt=false] noUpdate Skip update
function impulse.Inventory:ContainerAddItem(container, class, amount, noUpdate)
    container.Inventory = container.Inventory or {}
    local addAmount = tonumber(amount) or 1

    local count = container.Inventory[class] or 0
    container.Inventory[class] = count + addAmount

    if ( !noUpdate ) then
        self:ContainerUpdateUsers(container)
    end
end

--- Removes an item from a container table and updates listeners.
-- @realm server
-- @entity container Container entity
-- @string class Item class
-- @int[opt=1] amount Amount
-- @bool[opt=false] noUpdate Skip update
function impulse.Inventory:ContainerTakeItem(container, class, amount, noUpdate)
    container.Inventory = container.Inventory or {}
    local takeAmount = tonumber(amount) or 1

    local itemCount = container.Inventory[class]
    if ( itemCount ) then
        local newCount = itemCount - takeAmount

        if ( newCount < 1 ) then
            container.Inventory[class] = nil
        else
            container.Inventory[class] = newCount
        end
    end

    if ( !noUpdate ) then
        self:ContainerUpdateUsers(container)
    end
end

--- Returns total container weight.
-- @realm server
-- @entity container Container entity
-- @treturn number Weight in kg
function impulse.Inventory:ContainerGetWeight(container)
    local weight = 0

    for class, amount in pairs(container.Inventory or {}) do
        local itemData = ResolveContainerItem(class)
        if ( !itemData ) then continue end

        weight = weight + ((itemData.Weight or 0) * amount)
    end

    return weight
end

--- Checks if a container can hold the specified item amount.
-- @realm server
-- @entity container Container entity
-- @string class Item class
-- @int[opt=1] amount Amount
-- @treturn bool Can hold
function impulse.Inventory:ContainerCanHoldItem(container, class, amount)
    local itemData = ResolveContainerItem(class)
    if ( !itemData ) then
        return false
    end

    local capacity = impulse.Config.InventoryMaxWeight
    if ( container.GetCapacity ) then
        capacity = container:GetCapacity()
    end

    local weight = (itemData.Weight or 0) * (tonumber(amount) or 1)
    return self:ContainerGetWeight(container) + weight <= capacity
end

--- Adds a user to a container and sends full snapshot.
-- @realm server
-- @entity container Container entity
-- @player client User
function impulse.Inventory:ContainerAddUser(container, client)
    if ( !IsValid(client) ) then return end

    container.Users = container.Users or {}
    container.Users[client] = true

    self:SendContainerSnapshot(container, client, "impulseInvContainerOpen")

    client.currentContainer = container
end

--- Removes a user from a container.
-- @realm server
-- @entity container Container entity
-- @player client User
function impulse.Inventory:ContainerRemoveUser(container, client)
    if ( istable(container.Users) ) then
        container.Users[client] = nil
    end

    if ( IsValid(client) ) then
        client.currentContainer = nil
    end
end

--- Updates all container listeners in range.
-- @realm server
-- @entity container Container entity
function impulse.Inventory:ContainerUpdateUsers(container)
    if ( !IsValid(container) ) then return end

    container.Users = container.Users or {}

    local pos = container:GetPos()

    for user, _ in pairs(container.Users) do
        if ( IsValid(user) and pos:DistToSqr(user:GetPos()) < CONTAINER_UPDATE_DISTANCE_SQR ) then
            self:SendContainerSnapshot(container, user, "impulseInvContainerUpdate")
        else
            self:ContainerRemoveUser(container, user)
        end
    end
end

--- Attaches shared container behavior methods to an entity.
-- @realm server
-- @entity container Container entity
function impulse.Inventory:AttachContainerMethods(container)
    if ( !IsValid(container) ) then return end

    container.Users = container.Users or {}
    container.Inventory = container.Inventory or {}

    container.AddItem = function(this, class, amount, noUpdate)
        return impulse.Inventory:ContainerAddItem(this, class, amount, noUpdate)
    end

    container.TakeItem = function(this, class, amount, noUpdate)
        return impulse.Inventory:ContainerTakeItem(this, class, amount, noUpdate)
    end

    container.GetStorageWeight = function(this)
        return impulse.Inventory:ContainerGetWeight(this)
    end

    container.CanHoldItem = function(this, class, amount)
        return impulse.Inventory:ContainerCanHoldItem(this, class, amount)
    end

    container.AddUser = function(this, user)
        return impulse.Inventory:ContainerAddUser(this, user)
    end

    container.RemoveUser = function(this, user)
        return impulse.Inventory:ContainerRemoveUser(this, user)
    end

    container.UpdateUsers = function(this)
        return impulse.Inventory:ContainerUpdateUsers(this)
    end
end

--- Stores player inventory as a container on their ragdoll.
-- @realm server
-- @player client Dead player
-- @entity ragdoll Player ragdoll
function impulse.Inventory:CreateRagdollContainer(client, ragdoll)
    if ( !IsValid(client) or !IsValid(ragdoll) ) then return end

    self:AttachContainerMethods(ragdoll)

    ragdoll.GetCapacity = function(this)
        return this:GetRelay("ragdoll.capacity", impulse.Config.InventoryMaxWeight)
    end

    local inventory = client:GetInventory()
    local items = {}

    for _, item in pairs(inventory) do
        local itemID = self:ClassToNetID(item.class)
        if ( !itemID ) then continue end

        local itemData = self.Items[itemID]
        if ( !itemData ) then continue end

        table.insert(items, item.class)

        ragdoll:AddItem(item.class, item.amount, true)
    end

    ragdoll:SetRelay("ragdoll.items", items)
    ragdoll:SetRelay("ragdoll.capacity", impulse.Config.InventoryMaxWeight)
    ragdoll:SetRelay("ragdoll.name", client:Name())
end

--- Drops death items onto the ground and saves restore metadata.
-- @realm server
-- @player client Dead player
-- @entity killer Killer entity
function impulse.Inventory:DropDeathItems(client, killer)
    if ( !IsValid(client) ) then return end

    local inv = client:GetInventory()
    local restorePoint = {}
    local pos = client:LocalToWorld(client:OBBCenter())
    local dropped = 0

    for _, itemData in pairs(inv) do
        local itemID = self:ClassToNetID(itemData.class)
        local item = itemID and self.Items[itemID]

        if ( !itemData.restricted ) then
            table.insert(restorePoint, itemData.class)
        end

        if ( item and item.DropOnDeath and !itemData.restricted ) then
            local ent = self:SpawnItem(itemData.class, pos)
            if ( IsValid(ent) ) then
                ent.ItemClip = itemData.clip
            end

            dropped = dropped + 1

            if ( dropped > 4 ) then
                break
            end
        end
    end

    hook.Run("PlayerDropDeathItems", client, killer, pos, dropped, inv)

    client:GetTable().InventoryRestorePoint = restorePoint
end

--- Handles death item routing based on configured hooks.
-- @realm server
-- @player client Dead player
-- @entity ragdoll Player ragdoll
function impulse.Inventory:HandlePlayerDeathItems(client, ragdoll)
    if ( !IsValid(client) or !IsValid(ragdoll) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable.impulseBeenInventorySetup ) then return end

    local killer = ragdoll.Killer

    if ( hook.Run("PlayerShouldDropDeathItems", client, killer) == true ) then
        return self:DropDeathItems(client, killer)
    end

    if ( hook.Run("PlayerShouldRagdollDeathItems", client, killer) == true ) then
        return self:CreateRagdollContainer(client, ragdoll)
    end
end

--- Returns true if an entity is a ragdoll inventory container.
-- @realm server
-- @entity entity Candidate entity
-- @treturn bool Is ragdoll container
function impulse.Inventory:IsRagdollContainer(entity)
    return IsValid(entity)
        and entity:IsRagdoll()
        and entity:GetRelay("ragdoll.items")
        and istable(entity.Inventory)
        and isfunction(entity.AddUser)
end

--- Attempts to open a ragdoll container for a player.
-- @realm server
-- @player client User
-- @entity entity Candidate ragdoll
-- @treturn bool|nil True when opened, false when blocked, nil when not a ragdoll container
function impulse.Inventory:TryOpenRagdollContainer(client, entity)
    if ( !IsValid(client) or !self:IsRagdollContainer(entity) ) then
        return nil
    end

    entity.impulseNextUse = CurTime() + 1

    if ( client:GetRelay("arrested", false) ) then
        client:Notify("You cannot access a container when detained.")
        return false
    end

    entity:AddUser(client)

    return true
end

local PLAYER = FindMetaTable("Player")

--- Handles death item behavior for this player.
-- @realm server
-- @entity ragdoll Player ragdoll
function PLAYER:HandleDeathItems(ragdoll)
    return impulse.Inventory:HandlePlayerDeathItems(self, ragdoll)
end

local function ShouldPersistInventory(client)
    return IsValid(client) and !client:IsBot()
end

--- Gets a players inventory table
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @treturn table Inventory
function PLAYER:GetInventory(storageType)
    storageType = storageType or INVENTORY_PLAYER

    local id = self.impulseID
    if ( !id ) then return {} end

    local data = impulse.Inventory.Data[id]
    if ( !data ) then return {} end

    data[storageType] = data[storageType] or {}
    return data[storageType]
end

--- Returns a copy of a players inventory table
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @treturn table Inventory table
function PLAYER:GetInventoryCopy(storageType)
    return table.Copy(self:GetInventory(storageType))
end

--- Returns if a player can hold an item in their local inventory
-- @realm server
-- @string class Item class name
-- @int[opt = 1] amount Amount of the item
-- @treturn bool Can hold item
function PLAYER:CanHoldItem(class, amount)
    local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]
    local weight = ( item.Weight or 0 ) * (amount or 1)

    return self.InventoryWeight + weight <= impulse.Config.InventoryMaxWeight
end

--- Returns if a player can hold an item in their storage chest
-- @realm server
-- @string class Item class name
-- @int[opt = 1] amount Amount of the item
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
-- @int[opt = 1] amount Amount of the item
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
-- @int[opt = 1] amount Amount of the item
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
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Has item
function PLAYER:HasInventoryItemSpecific(itemID, storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local has = impulse.Inventory.Data[self.impulseID][storageType][itemID]
    if ( has ) then
        return true, has
    end

    return false
end

--- Returns if a player has an illegal inventory item
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Has illegal item
-- @treturn int Item ID of illegal item
function PLAYER:HasIllegalInventoryItem(storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local inv = self:GetInventory(storageType)
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
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @treturn bool Is restricted
function PLAYER:IsInventoryItemRestricted(itemID, storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local has = impulse.Inventory.Data[self.impulseID][storageType][itemID]
    if ( has ) then
        return has.restricted
    end

    return false
end

--- Gives an inventory item to a player
-- @realm server
-- @string class Item class name
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @bool[opt = false] restricted Is item restricted
-- @bool[opt = false] isLoaded (INTERNAL) Used for first time setup when player connects
-- @bool[opt = false] moving (INTERNAL) Is item just being moved? (stops database requests)
-- @int[opt] clip (INTERNAL) (Only used for weapons) Item clip
-- @treturn int ItemID
function PLAYER:GiveItem(class, storageType, restricted, isLoaded, moving, clip) -- isLoaded is a internal arg used for first time item setup, when they are already half loaded
    if ( !self.impulseBeenInventorySetup and !isLoaded ) then
        return
    end

    storageType = storageType or INVENTORY_PLAYER
    restricted = restricted or false

    -- Validate that the item class exists and is registered
    local itemNet = impulse.Inventory:ClassToNetID(class)
    if ( !itemNet or !impulse.Inventory.Items[itemNet] ) then
        logs:Error("Attempted to give unknown item class '" .. tostring(class) .. "' to player " .. tostring(self) .. " (" .. tostring(self.impulseID) .. ")")
        -- Return nil so callers can gracefully handle failure (e.g., refund purchases)
        return
    end

    local weight = impulse.Inventory.Items[itemNet].Weight or 0
    local impulseID = self.impulseID

    if ( !impulse.Inventory.Data[impulseID] or !impulse.Inventory.Data[impulseID][storageType] ) then
        -- Attempt to auto-initialize missing inventory for this player
        impulse.Inventory.Data[impulseID] = impulse.Inventory.Data[impulseID] or {}
        impulse.Inventory.Data[impulseID][INVENTORY_PLAYER] = impulse.Inventory.Data[impulseID][INVENTORY_PLAYER] or {}
        impulse.Inventory.Data[impulseID][INVENTORY_STORAGE] = impulse.Inventory.Data[impulseID][INVENTORY_STORAGE] or {}

        -- Ensure local caches exist
        self.InventoryRegister = self.InventoryRegister or {}
        self.InventoryStorageRegister = self.InventoryStorageRegister or {}
        self.InventoryEquipGroups = self.InventoryEquipGroups or {}

        -- Ensure weights exist
        self.InventoryWeight = self.InventoryWeight or 0
        self.InventoryWeightStorage = self.InventoryWeightStorage or 0

        -- Mark that inventory has been set up to avoid re-entrancy issues
        self.impulseBeenInventorySetup = self.impulseBeenInventorySetup or true

        -- Inform logs that we recovered from an uninitialized state (no user-facing error)
        logs:Warning("Recovered missing inventory for player " .. tostring(self) .. " (" .. tostring(impulseID) .. ") while giving item '" .. tostring(class) .. "'.")

        -- Continue with give flow after initializing structures
    end

    -- If it still doesn't exist, abort
    if ( !impulse.Inventory.Data[impulseID] or !impulse.Inventory.Data[impulseID][storageType] ) then
        self:Notify("An error occurred while giving you an item. Please contact a developer, if this persists please relog.")
        return logs:Error("Failed to initialize missing inventory for player " .. tostring(self) .. " (" .. tostring(impulseID) .. ") while giving item '" .. tostring(class) .. "'.")
    end

    local inv = impulse.Inventory.Data[impulseID][storageType]
    local itemID

    for i = 1, ( table.Count(inv) + 1 ) do -- intellegent table insert looks for left over ids to reuse to stop massive id's that cant be networked
        if ( inv[i] == nil ) then
            itemID = i

            impulse.Inventory.Data[impulseID][storageType][i] = {
                id = itemNet,
                class = class,
                restricted = restricted,
                equipped = false,
                clip = clip or nil
            }

            break
        end
    end

    if ( !restricted and !isLoaded and !moving and ShouldPersistInventory(self) ) then
        impulse.Inventory:AddItem(impulseID, class, storageType)
    end

    if ( storageType == INVENTORY_PLAYER ) then
        self.InventoryWeight = self.InventoryWeight + weight
        self.InventoryRegister[class] = (self.InventoryRegister[class] or 0) + 1 -- use a register that copies the actions of the real inv for search efficiency
    elseif ( storageType == INVENTORY_STORAGE ) then
        self.InventoryWeightStorage = self.InventoryWeightStorage + weight
        self.InventoryStorageRegister[class] = (self.InventoryStorageRegister[class] or 0) + 1 -- use a register that copies the actions of the real inv for search efficiency
    end

    if ( !moving ) then
        net.Start("impulseInvGive")
            net.WriteUInt(itemNet, 16)
            net.WriteUInt(itemID, 16)
            net.WriteUInt(storageType, 4)
            net.WriteBool(restricted or false)
            net.WriteString(class) -- Send class so client can store and resolve items
        net.Send(self)
    end

    return itemID
end

--- Takes an inventory item from a player
-- @realm server
-- @int itemID Item ID
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @bool[opt = false] moving (INTERNAL) Is item just being moved? (stops database requests)
-- @number[opt = 1] amount Amount to take
-- @treturn int Clip
function PLAYER:TakeInventoryItem(itemID, storageType, moving, amount)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER
    amount = amount or 1

    local impulseID = self.impulseID
    local itemData = impulse.Inventory.Data[impulseID][storageType][itemID]
    local itemNet = impulse.Inventory:ClassToNetID(itemData.class)
    local weight = (impulse.Inventory.Items[itemNet].Weight or 0) * amount

    if ( !moving and ShouldPersistInventory(self) ) then
        impulse.Inventory:RemoveItem(self.impulseID, itemData.class, storageType, 1)
    end

    if ( storageType == INVENTORY_PLAYER ) then
        self.InventoryWeight = math.Clamp(self.InventoryWeight - weight, 0, 1000)
    elseif ( storageType == INVENTORY_STORAGE ) then
        self.InventoryWeightStorage = math.Clamp(self.InventoryWeightStorage - weight, 0, 1000)
    end

    if ( storageType == INVENTORY_PLAYER ) then
        local regvalue = self.InventoryRegister[itemData.class]
        self.InventoryRegister[itemData.class] = regvalue - 1

        if self.InventoryRegister[itemData.class] < 1 then -- any negative values to be removed
            self.InventoryRegister[itemData.class] = nil
        end
    elseif ( storageType == INVENTORY_STORAGE ) then
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

    hook.Run("OnInventoryItemRemoved", self, storageType, itemData.class, itemData.id, itemData.equipped, itemData.restricted, itemID)

    impulse.Inventory.Data[impulseID][storageType][itemID] = nil

    if ( !moving ) then
        net.Start("impulseInvRemove")
            net.WriteUInt(itemID, 16)
            net.WriteUInt(storageType, 4)
        net.Send(self)
    end

    return clip
end

--- Clears a players inventory
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearInventory(storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local inv = self:GetInventory(storageType)
    for v, k in pairs(inv) do
        self:TakeInventoryItem(v, storageType, true)
    end

    if ( ShouldPersistInventory(self) ) then
        impulse.Inventory:ClearInventory(self.impulseID, storageType)
    end

    net.Start("impulseInvClear")
        net.WriteUInt(storageType, 4)
    net.Send(self)
end

--- Clears restricted items from a players inventory
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearRestrictedInventory(storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local inv = self:GetInventory(storageType)
    for v, k in pairs(inv) do
        if k.restricted then
            self:TakeInventoryItem(v, storageType, true)
        end
    end

    net.Start("impulseInvClearRestricted")
        net.WriteUInt(storageType, 4)
    net.Send(self)
end

--- Clears illegal items from a players inventory
-- @realm server
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
function PLAYER:ClearIllegalInventory(storageType)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER

    local inv = self:GetInventory(storageType)
    for v, k in pairs(inv) do
        local itemData = impulse.Inventory.Items[k.id]

        if ( itemData and itemData.Illegal ) then
            self:TakeInventoryItem(v)
        end
    end
end

--- Takes an item from a players inventory by class name
-- @realm server
-- @string class Item class name
-- @int[opt = 1] storageType Storage type (1 is player inventory, 2 is storage)
-- @int[opt = 1] amount Amount to take
function PLAYER:TakeInventoryItemClass(class, storageType, amount)
    if ( !self.impulseBeenInventorySetup ) then
        return false
    end

    storageType = storageType or INVENTORY_PLAYER
    amount = amount or 1

    local impulseID = self.impulseID

    local count = 0
    for v, k in pairs(impulse.Inventory.Data[impulseID][storageType]) do
        if ( k.class == class ) then
            count = count + 1
            self:TakeInventoryItem(v, storageType)

            if ( count == amount ) then
                return
            end
        end
    end
end

--- Sets a specific inventory item as equipped or not
-- @realm server
-- @int itemID Item ID
-- @bool state Is equipped
function PLAYER:SetInventoryItemEquipped(itemID, state)
    local item = impulse.Inventory.Data[self.impulseID][1][itemID]
    if ( !item ) then return end

    local id = impulse.Inventory:ClassToNetID(item.class)
    local onEquip = impulse.Inventory.Items[id].OnEquip
    local unEquip = impulse.Inventory.Items[id].UnEquip
    if ( !onEquip ) then return end

    local class = impulse.Inventory.Items[id]
    local isAlive = self:Alive()
    if ( class.CanEquip and !class.CanEquip(item, self) ) then return end

    local canEquip = hook.Run("PlayerCanEquipItem", self, class, item)
    if ( canEquip != nil and !canEquip ) then return end

    if ( class.EquipGroup ) then
        local equippedItem = self.InventoryEquipGroups[class.EquipGroup]
        if ( equippedItem and equippedItem != itemID ) then
            self:SetInventoryItemEquipped(equippedItem, false)
        end
    end

    if ( state ) then
        if ( class.EquipGroup ) then
            self.InventoryEquipGroups[class.EquipGroup] = itemID
        end

        onEquip(item, self, class, itemID)

        if ( isAlive ) then
            self:EmitSound("impulse-reforged/equip.wav")
        end
    elseif ( unEquip ) then
        if ( class.EquipGroup ) then
            self.InventoryEquipGroups[class.EquipGroup] = nil
        end

        unEquip(item, self, class, itemID)

        if ( isAlive ) then
            self:EmitSound("impulse-reforged/unequip.wav")
        end
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

    if ( item.restricted and !class.DropIfRestricted ) then return end

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

    if ( ShouldPersistInventory(self) ) then
        impulse.Inventory:UpdateStorageType(self.impulseID, class, 1, from, to)
    end
    local newitemID = self:GiveItem(class, to, false, nil, true, itemclip or nil)

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
    if ( ShouldPersistInventory(self) ) then
        impulse.Inventory:UpdateStorageType(self.impulseID, class, amount, from, to)
    end

    local takes = 0
    for k, v in pairs(self:GetInventory(from)) do
        if ( !v.restricted and v.class == class ) then
            takes = takes + 1

            local itemclip = self:TakeInventoryItem(k, from, true)
            local newitemID = self:GiveItem(class, to, false, nil, true, itemclip or nil)

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
        return false, "Your crafting skill is too low to make this item!"
    end

    local missing = false
    local missingItems = {}
    local inv = self:GetInventory()

    for k, v in pairs(class.Input) do
        local available = 0

        for _, itemData in pairs(inv) do
            if ( itemData.class == k and !itemData.restricted ) then
                available = available + 1
            end
        end

        if ( available < v.take ) then
            missing = true

            local netid = impulse.Inventory:ClassToNetID(k)
            local name = k

            if ( netid and impulse.Inventory.Items[netid] and impulse.Inventory.Items[netid].Name ) then
                name = impulse.Inventory.Items[netid].Name
            end

            table.insert(missingItems, name .. " x" .. v.take)
        end
    end

    if ( missing ) then
        return false, "You are missing the following items: " .. table.concat(missingItems, ", ")
    end

    return true
end
