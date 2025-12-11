impulse.Ops = impulse.Ops or {}
impulse.Ops.Snapshots = impulse.Ops.Snapshots or {}

local snapshotCommand = {
    description = "Plays the snapshot specified by the snapshot ID.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local id = arg[1]

        if !tonumber(id) then
            return client:Notify("The ID must be a number.")
        end

        id = tonumber(id)

        if !impulse.Ops.Snapshots[id] then
            return client:Notify("A snapshot could not be found with that ID.")
        end

        client:Notify("Downloading snapshot #" .. id .. " .. .")

        local snapshot = impulse.Ops.Snapshots[id]
        snapshot = pon.encode(snapshot)

        net.Start("opsSnapshot")
        net.WriteUInt(id, 16)
        net.WriteUInt(#snapshot, 32)
        net.WriteData(snapshot, #snapshot)
        net.Send(client)
    end
}

impulse.RegisterChatCommand("/snapshot", snapshotCommand)
