util.AddNetworkString("impulseOpsObserverHide")
net.Receive("impulseOpsObserverHide", function(len, client)
    if !client:IsAdmin() then return end

    local val = net.ReadBool()

    client:SetRelay("observerHide", val)
end)
