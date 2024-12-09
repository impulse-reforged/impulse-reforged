util.AddNetworkString("impulseOpsObserverHide")
net.Receive("impulseOpsObserverHide", function(len, ply)
    if not ply:IsAdmin() then return end

    local val = net.ReadBool()

    ply:SetNetVar("observerHide", val)
end)