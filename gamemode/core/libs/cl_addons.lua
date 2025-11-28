net.Receive("impulse.Addons", function()
    local data = net.ReadTable()
    if ( !istable(data) ) then
        impulse.Addons = {}
        return
    end

    impulse.Addons = data
end)
