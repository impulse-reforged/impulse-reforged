--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Entity and global variable relay system for synchronized data storage.
-- Provides networked variable storage for entities and global values with automatic cleanup.
-- Similar to SetNWVar/GetNWVar but with more control over networking and recipients.
-- @module impulse.Relay

impulse.Relay = impulse.Relay or {}
impulse.Relay.Data = impulse.Relay.Data or {}

if ( SERVER ) then
    function impulse.Relay:Sync(recipients)
        net.Start("impulse.Relay.Sync")
            net.WriteTable(impulse.Relay.Data)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

local ENTITY = FindMetaTable("Entity")

--- Set a relay variable on an entity with optional networking.
-- Stores a value associated with this entity and optionally syncs it to clients.
-- @realm shared
-- @param name string The variable name to set
-- @param value any The value to store (will be networked if on server)
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage entity:SetRelay("health_percentage", 0.75)
-- @usage player:SetRelay("status", "injured", false, {otherPlayer})
function ENTITY:SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ErrorNoHalt("Invalid 'name' argument provided to method Entity:SetRelay()\n")
        return
    end

    local index = tostring(self:EntIndex())
    if ( type(self) == "Player" ) then
        index = self:SteamID64()
    end

    impulse.Relay.Data[index] = impulse.Relay.Data[index] or {}
    impulse.Relay.Data[index][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("impulse.Relay.Update")
            net.WriteString(index)
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

--- Get a relay variable from an entity.
-- Retrieves a stored value associated with this entity.
-- @realm shared
-- @param name string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The stored value or fallback if !found
-- @usage local health = entity:GetRelay("health_percentage", 1.0)
-- @usage local status = player:GetRelay("status", "healthy")
function ENTITY:GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    local index = tostring(self:EntIndex())
    if ( type(self) == "Player" ) then
        index = self:SteamID64()
    end

    impulse.Relay.Data[index] = impulse.Relay.Data[index] or {}

    local value = impulse.Relay.Data[index][name]
    if ( value != nil ) then
        return value
    end

    return fallback
end

--- Returns a table of all relay data for this entity.
-- @realm shared
-- @return table A table containing all relay variables for this entity
-- @usage local data = entity:GetAllRelayData()
function ENTITY:GetAllRelayData()
    local index = tostring(self:EntIndex())
    if ( type(self) == "Player" ) then
        index = self:SteamID64()
    end

    impulse.Relay.Data[index] = impulse.Relay.Data[index] or {}

    return impulse.Relay.Data[index]
end

--- Set a global relay variable with optional networking.
-- Stores a global value that can be accessed from anywhere and optionally syncs to clients.
-- @realm shared
-- @param name string The variable name to set
-- @param value any The value to store (will be networked if on server)
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage SetRelay("round_state", "preparation")
-- @usage SetRelay("server_message", "Welcome!", false, specificPlayers)
function SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ErrorNoHalt("Invalid 'name' argument provided to function SetRelay()\n")
        return
    end

    impulse.Relay.Data["global"] = impulse.Relay.Data["global"] or {}
    impulse.Relay.Data["global"][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("impulse.Relay.Update")
            net.WriteString("global")
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

--- Get a global relay variable.
-- Retrieves a stored global value that can be accessed from anywhere.
-- @realm shared
-- @param name string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The stored value or fallback if !found
-- @usage local roundState = GetRelay("round_state", "waiting")
-- @usage local message = GetRelay("server_message", "")
function GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    impulse.Relay.Data["global"] = impulse.Relay.Data["global"] or {}

    local value = impulse.Relay.Data["global"][name]
    if ( value != nil ) then
        return value
    end

    return fallback
end

hook.Add("EntityRemoved", "impulse.Relay.CleanUp", function(ent, fullUpdate)
    if ( fullUpdate ) then return end

    local index = tostring(ent:EntIndex())
    if ( type(ent) == "Player" ) then
        index = ent:SteamID64()
    end

    impulse.Relay.Data[index] = nil
end)

hook.Add("PlayerDisconnected", "impulse.Relay.CleanUp", function(client)
    local index = client:SteamID64()
    impulse.Relay.Data[index] = nil
end)

hook.Add("PlayerInitialSpawn", "impulse.Relay.SyncData", function(client)
    timer.Simple(5, function()
        if ( type(client) != "Player" ) then return end
        impulse.Relay:Sync(client)
    end)
end)

if ( SERVER ) then
    util.AddNetworkString("impulse.Relay.Update")
    util.AddNetworkString("impulse.Relay.Sync")
else
    net.Receive("impulse.Relay.Update", function()
        local index = net.ReadString()
        local name = net.ReadString()
        local value = net.ReadType()

        impulse.Relay.Data[index] = impulse.Relay.Data[index] or {}
        impulse.Relay.Data[index][name] = value
    end)

    net.Receive("impulse.Relay.Sync", function()
        local data = net.ReadTable()
        if ( !istable(data) ) then return end

        impulse.Relay.Data = data
    end)
end
