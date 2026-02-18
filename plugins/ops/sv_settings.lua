util.AddNetworkString("impulseOpsObserverHide")
net.Receive("impulseOpsObserverHide", function(len, client)
    if !CAMI.PlayerHasAccess(client, "impulse: Admin Settings") then return end

    local val = net.ReadBool()

    client:SetRelay("observerHide", val)
end)
