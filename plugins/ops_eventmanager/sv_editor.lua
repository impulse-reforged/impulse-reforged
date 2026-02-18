concommand.Add("impulse_ops_eventmanager", function(client)
    if !CAMI.PlayerHasAccess(client, "impulse: Manage Events") then return end

    local c = table.Count(impulse.Ops.EventManager.Sequences)

    net.Start("impulseOpsEMMenu")
    net.WriteUInt(c, 8)

    for v, k in pairs(impulse.Ops.EventManager.Sequences) do
        net.WriteString(v)
    end

    net.Send(client)
end)
