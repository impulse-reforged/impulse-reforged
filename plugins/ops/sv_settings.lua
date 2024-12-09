util.AddNetworkString("impulseOpsObserverHide")
net.Receive("impulseOpsObserverHide", function(len, ply)
    if not ply:IsAdmin() then return end

    local val = net.ReadBool()

    ply:SetSyncVar(SYNC_OBSERVER_HIDE, val, true)
    ply:Sync()
end)