util.AddNetworkString("impulse.Addons")

local function FetchAddons()
    local addons = engine.GetAddons()
    local validAddons = {}
    for _, addon in ipairs(addons) do
        if ( addon.mounted and addon.downloaded and addon.wsid and addon.wsid != 0 and addon.title ) then
            table.insert(validAddons, {
                title = addon.title,
                id = addon.wsid
            })
        end
    end

    return validAddons
end

local function BroadcastAddons(data, recipients)
    if ( !data ) then return end

    net.Start("impulse.Addons")
        net.WriteTable(data)
    if ( recipients ) then
        net.Send(recipients)
    else
        net.Broadcast()
    end
end

local function SetupAddons()
    local data = FetchAddons()

    -- Set server-side global for other server code
    impulse.Addons = data or {}

    -- Broadcast to all connected clients
    BroadcastAddons(impulse.Addons)
end

-- Initialize on server start
hook.Add("Initialize", "impulse.Addons", function()
    SetupAddons()
end)

-- Re-setup on gamemode reload so clients get updated info
hook.Add("OnReloaded", "impulse.Addons", function()
    SetupAddons()
end)

-- When a player joins, send them the current version
hook.Add("PlayerInitialSpawn", "impulse.Addons", function(client)
    if ( !IsValid(client) ) then return end

    BroadcastAddons(impulse.Addons, client)
end)
