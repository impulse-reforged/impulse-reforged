
local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

impulse.Networking = impulse.Networking or {}
impulse.Networking.Globals = impulse.Networking.Globals or {}

net.Receive("impulseGlobalVarSet", function()
    impulse.Networking.Globals[net.ReadString()] = net.ReadType()
end)

net.Receive("impulseNetVarSet", function()
    local index = net.ReadUInt(16)

    impulse.Networking[index] = impulse.Networking[index] or {}
    impulse.Networking[index][net.ReadString()] = net.ReadType()
end)

net.Receive("impulseNetVarDelete", function()
    impulse.Networking[net.ReadUInt(16)] = nil
end)

net.Receive("impulseLocalVarSet", function()
    local ply = LocalPlayer()
    local index = ply:EntIndex()

    local key = net.ReadString()
    local var = net.ReadType()

    impulse.Networking[index] = impulse.Networking[index] or {}
    impulse.Networking[index][key] = var

    hook.Run("OnLocalVarSet", key, var)
end)

function GetNetVar(key, default) -- luacheck: globals GetNetVar
    local value = impulse.Networking.Globals[key]

    return value != nil and value or default
end

function entityMeta:GetNetVar(key, default)
    local index = self:EntIndex()

    if (impulse.Networking[index] and impulse.Networking[index][key] != nil) then
        return impulse.Networking[index][key]
    end

    return default
end

playerMeta.GetLocalVar = entityMeta.GetNetVar
