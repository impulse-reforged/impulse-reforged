--- A fast entity based synchronous networking system
-- @module impulse.Sync

impulse.Sync = impulse.Sync or {}
impulse.Sync.Vars = impulse.Sync.Vars or {}
impulse.Sync.VarsConditional = impulse.Sync.VarsConditional or {}
impulse.Sync.Data = impulse.Sync.Data or {}
local syncVarsID = 0

SYNC_ID_BITS = 8
SYNC_MAX_VARS = 255

--- Types of Sync variable
-- @realm shared
-- @field SYNC_BOOL A boolean
-- @field SYNC_STRING An ASCII string of any length
-- @field SYNC_INT An unsigned 8 bit integer
-- @field SYNC_BIGINT An unsigned 16 bit integer
-- @field SYNC_HUGEINT An unsigned 32 bit integer
-- @field SYNC_MINITABLE (Avoid using) A 32 bit compressed table
-- @field SYNC_INTSTACK A collection of up to 255 8 bit unsigned integers
-- @table SyncTypes

SYNC_BOOL = 1
SYNC_STRING =  2
SYNC_INT = 3
SYNC_BIGINT = 4
SYNC_HUGEINT = 5
SYNC_MINITABLE = 6
SYNC_INTSTACK = 7

SYNC_TYPE_PUBLIC = 1
SYNC_TYPE_PRIVATE = 2

--[[--
Physical object in the game world.

Entities are physical representations of objects in the game world. Helix extends the functionality of entities to interface
between Helix's own classes, and to reduce boilerplate code.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Entity) for all other methods that the `Player` class has.
]]
-- @classmod Entity

local meta = FindMetaTable("Entity")

--- Registers a new Sync variable for usage. **Must be called in the shared realm**
-- @realm shared
-- @int type SyncType
-- @bool[opt=false] conditional Is conditional
-- @see SyncTypes
-- @usage SYNC_XP = impulse.Sync:RegisterVar(SYNC_INT)
function impulse.Sync:RegisterVar(type, conditional)
    syncVarsID = syncVarsID + 1

    if syncVarsID > SYNC_MAX_VARS then
        print("[impulse-reforged] WARNING: Sync var limit hit! (255)")
    end

    impulse.Sync.Vars[syncVarsID] = type

    if conditional then
        impulse.Sync.VarsConditional[syncVarsID] = conditional
    end

    return syncVarsID
end

local ioRegister = {}
ioRegister[SERVER] = {}
ioRegister[CLIENT] = {}

--- Reads or writes a value based on the SyncType provided
-- @realm shared
-- @internal
-- @int type SyncType
-- @param value
function impulse.Sync:DoType(type, value)
    return ioRegister[SERVER or CLIENT][type](value)
end

if ( CLIENT ) then
    --- Gets the Sync variable on an entity
    -- @realm shared
    -- @int varID Sync variable (EG: SYNC_MONEY)
    -- @param fallback If we don't know the value we will fallback to this value
    -- @return value
    -- @usage local xp = ply:GetSyncVar(SYNC_XP, 0)
    function meta:GetSyncVar(varID, fallback)
        local targetData = impulse.Sync.Data[self.EntIndex(self)]

        if targetData != nil then
            if targetData[varID] != nil then
                return targetData[varID]
            end
        end
        return fallback
    end

    net.Receive("impulseSyncUpdate", function(len)
        local targetID = net.ReadUInt(16)
        local varID = net.ReadUInt(SYNC_ID_BITS)
        local syncType = impulse.Sync.Vars[varID]
        local newValue = impulse.Sync:DoType(syncType)
        local targetData = impulse.Sync.Data[targetID]

        if not targetData then
            impulse.Sync.Data[targetID] = {}
            targetData = impulse.Sync.Data[targetID]
        end

        targetData[varID] = newValue

        hook.Run("OnSyncUpdate", varID, targetID, newValue)
    end)

    net.Receive("impulseSyncUpdatepdateClient", function(len)
        local targetID = net.ReadUInt(8)
        local varID = net.ReadUInt(SYNC_ID_BITS)
        local syncType = impulse.Sync.Vars[varID]
        local newValue = impulse.Sync:DoType(syncType)
        local targetData = impulse.Sync.Data[targetID]

        if not targetData then
            impulse.Sync.Data[targetID] = {}
            targetData = impulse.Sync.Data[targetID]
        end

        targetData[varID] = newValue

        hook.Run("OnSyncUpdate", varID, targetID, newValue)
    end)

    net.Receive("impulseSyncRemove", function()
        local targetID = net.ReadUInt(16)

        impulse.Sync.Data[targetID] = nil
    end)

    net.Receive("impulseSyncRemoveVar", function()
        local targetID = net.ReadUInt(16)
        local varID = net.ReadUInt(SYNC_ID_BITS)
        local syncEnt = impulse.Sync.Data[targetID]

        if syncEnt then
            if impulse.Sync.Data[targetID][varID] != nil then
                impulse.Sync.Data[targetID][varID] = nil
            end
        end

        hook.Run("OnSyncUpdate", varID, targetID)
    end)
end

-- Declare some sync var types and how they are read/written
ioRegister[SERVER][SYNC_BOOL] = function(val) return net.WriteBool(val) end
ioRegister[CLIENT][SYNC_BOOL] = function(val) return net.ReadBool() end
ioRegister[SERVER][SYNC_INT] = function(val) return net.WriteUInt(val, 8) end
ioRegister[CLIENT][SYNC_INT] = function(val) return net.ReadUInt(8) end
ioRegister[SERVER][SYNC_BIGINT] = function(val) return net.WriteUInt(val, 16) end
ioRegister[CLIENT][SYNC_BIGINT] = function(val) return net.ReadUInt(16) end
ioRegister[SERVER][SYNC_HUGEINT] = function(val) return net.WriteUInt(val, 32) end
ioRegister[CLIENT][SYNC_HUGEINT] = function(val) return net.ReadUInt(32) end
ioRegister[SERVER][SYNC_STRING] = function(val) return net.WriteString(val) end
ioRegister[CLIENT][SYNC_STRING] = function(val) return net.ReadString() end
ioRegister[SERVER][SYNC_MINITABLE] = function(val) return net.WriteData(pon.encode(val), 32) end
ioRegister[CLIENT][SYNC_MINITABLE] = function(val) return pon.decode(net.ReadData(32)) end
ioRegister[SERVER][SYNC_INTSTACK] = function(val) 
    local count = net.WriteUInt(#val, 8)

    for v, k in pairs(val) do
        net.WriteUInt(k, 8)
    end

    return
end
ioRegister[CLIENT][SYNC_INTSTACK] = function(val) 
    local count = net.ReadUInt(8)
    local compiled =  {}

    for k = 1, count do
        table.insert(compiled, (net.ReadUInt(8)))
    end

    return compiled
end

--- Default Sync variables
-- @realm shared
-- @field SYNC_ARRESTED Whether the player is arrested
-- @field SYNC_BANKMONEY The player's stored money
-- @field SYNC_BROKENLEGS Whether the player has broken legs
-- @field SYNC_CLASS The player's class
-- @field SYNC_COS_CHEST Cosmetic sync values for clothing
-- @field SYNC_COS_FACE Cosmetic sync values for clothing
-- @field SYNC_COS_HEAD Cosmetic sync values for clothing
-- @field SYNC_CRAFTLEVEL The player's crafting level
-- @field SYNC_DOOR_BUYABLE Whether the door is buyable
-- @field SYNC_DOOR_GROUP The door's group
-- @field SYNC_DOOR_NAME The door's name
-- @field SYNC_DOOR_OWNERS The door's owners
-- @field SYNC_GROUP_NAME If the player is in a group, the group name
-- @field SYNC_GROUP_RANK If the player is in a group, their rank in the group
-- @field SYNC_HUNGER The player's hunger level
-- @field SYNC_INCOGNITO Whether the player is in incognito
-- @field SYNC_PROPCOUNT The player's prop count
-- @field SYNC_RANK The player's rank
-- @field SYNC_RPNAME The player's roleplay name
-- @field SYNC_THROPHYPOINTS The player's trophy points
-- @field SYNC_TYPING Whether the player is typing
-- @field SYNC_WEPRAISED Whether the player has raised their weapon
-- @field SYNC_XP The player's xp points
-- @field SYNX_MONEY The player's physical money
-- @table SyncDefaults

SYNC_ARRESTED = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_BANKMONEY = impulse.Sync:RegisterVar(SYNC_HUGEINT)
SYNC_BROKENLEGS = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_CLASS = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_COS_CHEST = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_COS_FACE = impulse.Sync:RegisterVar(SYNC_INT) -- cosmetic sync values for clothing
SYNC_COS_HEAD = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_CRAFTLEVEL = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_DOOR_BUYABLE = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_DOOR_GROUP = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_DOOR_NAME = impulse.Sync:RegisterVar(SYNC_STRING)
SYNC_DOOR_OWNERS = impulse.Sync:RegisterVar(SYNC_INTSTACK)
SYNC_GROUP_NAME = impulse.Sync:RegisterVar(SYNC_STRING)
SYNC_GROUP_RANK = impulse.Sync:RegisterVar(SYNC_STRING)
SYNC_HUNGER = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_INCOGNITO = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_MONEY = impulse.Sync:RegisterVar(SYNC_HUGEINT)
SYNC_PROPCOUNT = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_RANK = impulse.Sync:RegisterVar(SYNC_INT)
SYNC_RPNAME = impulse.Sync:RegisterVar(SYNC_STRING)
SYNC_TROPHYPOINTS = impulse.Sync:RegisterVar(SYNC_BIGINT)
SYNC_TYPING = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_WEPRAISED = impulse.Sync:RegisterVar(SYNC_BOOL)
SYNC_XP = impulse.Sync:RegisterVar(SYNC_HUGEINT)

hook.Run("CreateSyncVars")