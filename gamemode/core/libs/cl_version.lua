net.Receive("impulse.Version", function()
    local data = net.ReadTable()
    if ( !istable(data) ) then
        impulse.Version = {}
        return
    end

    impulse.Version = data
end)
