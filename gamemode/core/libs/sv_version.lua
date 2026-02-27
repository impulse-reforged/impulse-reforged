util.AddNetworkString("impulse.Version")

local function ReadVersionFile()
    local content = file.Read("gamemodes/impulse-reforged/version.json", "GAME")
    if ( !content ) then
        return nil
    end

    if ( !content ) then
        return nil
    end

    local ok, data = pcall(util.JSONToTable, content)
    if ( ok and istable(data) ) then
        return data
    end

    return nil
end

local function BroadcastVersion(data, recipients)
    if ( !data ) then return end

    net.Start("impulse.Version")
        net.WriteTable(data)
    if ( recipients ) then
        net.Send(recipients)
    else
        net.Broadcast()
    end
end

local function SetupVersion()
    local data = ReadVersionFile()

    -- Set server-side global for other server code
    impulse.Version = data or {}

    -- Broadcast to all connected clients
    BroadcastVersion(impulse.Version)
end

-- Initialize on server start
hook.Add("Initialize", "impulse.Version", function()
    SetupVersion()
end)

-- Re-setup on gamemode reload so clients get updated info
hook.Add("OnReloaded", "impulse.Version", function()
    SetupVersion()
end)

-- When a player joins, send them the current version
hook.Add("PlayerInitialSpawn", "impulse.Version", function(client)
    if ( type(client) != "Player" ) then return end

    BroadcastVersion(impulse.Version, client)
end)
