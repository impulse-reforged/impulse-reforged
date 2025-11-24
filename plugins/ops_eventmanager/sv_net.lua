util.AddNetworkString("impulseOpsEMMenu")
util.AddNetworkString("impulseOpsEMPushSequence")
util.AddNetworkString("impulseOpsEMUpdateEvent")
util.AddNetworkString("impulseOpsEMPlaySequence")
util.AddNetworkString("impulseOpsEMStopSequence")
util.AddNetworkString("impulseOpsEMClientsideEvent")
util.AddNetworkString("impulseOpsEMIntroCookie")
util.AddNetworkString("impulseOpsEMPlayScene")
util.AddNetworkString("impulseOpsEMEntAnim")

net.Receive("impulseOpsEMPushSequence", function(len, client)
    if (client.nextOpsEMPush or 0) > CurTime() then return end
    client.nextOpsEMPush = CurTime() + 1

    if not client:IsEventAdmin() then return end

    local seqName = net.ReadString()
    local seqEventCount = net.ReadUInt(16)
    local events = {}

    print("[ops-em] Starting pull of "..seqName.." (by "..client:SteamName().."). Total events: "..seqEventCount.."")

    for i=1, seqEventCount do
        local dataSize = net.ReadUInt(16)
        local eventData = pon.decode(net.ReadData(dataSize))

        table.insert(events, eventData)
        print("[ops-em] Got event "..i.."/"..seqEventCount.." ("..eventData.Type..")")
    end

    impulse.Ops.EventManager.Sequences[seqName] = events

    print("[ops-em] Finished pull of "..seqName..". Ready to play sequence!")

    if IsValid(client) then
        client:Notify("Push completed.")
    end
end)

net.Receive("impulseOpsEMPlaySequence", function(len, client)
    if (client.nextOpsEMPlay or 0) > CurTime() then return end
    client.nextOpsEMPlay = CurTime() + 1

    if not client:IsEventAdmin() then return end

    local seqName = net.ReadString()

    if not impulse.Ops.EventManager.Sequences[seqName] then
        return client:Notify("Sequence does not exist on server (push first).")
    end

    if impulse.Ops.EventManager.GetSequence() == seqName then
        return client:Notify("Sequence already playing.")
    end

    impulse.Ops.EventManager.PlaySequence(seqName)

    print("[ops-em] Playing sequence "..seqName.." (by "..client:SteamName()..").")
    client:Notify("Playing sequence "..seqName..".")
end)

net.Receive("impulseOpsEMStopSequence", function(len, client)
    if (client.nextOpsEMStop or 0) > CurTime() then return end
    client.nextOpsEMStop = CurTime() + 1

    if not client:IsEventAdmin() then return end

    local seqName = net.ReadString()

    if not impulse.Ops.EventManager.Sequences[seqName] then
        return client:Notify("Sequence does not exist on server (push first).")
    end

    if impulse.Ops.EventManager.GetSequence() != seqName then
        return client:Notify("Sequence not playing.")
    end

    impulse.Ops.EventManager.StopSequence(seqName)

    print("[ops-em] Stopping sequence "..seqName.." (by "..client:SteamName()..").")
    client:Notify("Stopped sequence "..seqName..".")
end)

net.Receive("impulseOpsEMIntroCookie", function(len, client)
    if client.usedIntroCookie or not impulse.Ops.EventManager.GetEventMode() then return end
    
    client.usedIntroCookie = true

    client:AllowScenePVSControl(true)

    timer.Simple(900, function()
        if IsValid(client) then
            client:AllowScenePVSControl(false)
        end
    end)
end)
