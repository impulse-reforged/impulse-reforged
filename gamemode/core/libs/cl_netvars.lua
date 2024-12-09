local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

impulse.NetVar = impulse.NetVar or {}
impulse.NetVar.Globals = impulse.NetVar.Globals or {}

net.Receive("impulseGlobalVarSet", function()
    impulse.NetVar.Globals[net.ReadString()] = net.ReadType()
end)

net.Receive("impulseNetVarSet", function()
    local index = net.ReadUInt(16)

    impulse.NetVar[index] = impulse.NetVar[index] or {}
    impulse.NetVar[index][net.ReadString()] = net.ReadType()
end)

net.Receive("impulseNetVarDelete", function()
    impulse.NetVar[net.ReadUInt(16)] = nil
end)

net.Receive("impulseLocalVarSet", function()
    local key = net.ReadString()
    local var = net.ReadType()

    impulse.NetVar[LocalPlayer():EntIndex()] = impulse.NetVar[LocalPlayer():EntIndex()] or {}
    impulse.NetVar[LocalPlayer():EntIndex()][key] = var

    hook.Run("OnLocalVarSet", key, var)
end)

function GetNetVar(key, default) -- luacheck: globals GetNetVar
    local value = impulse.NetVar.Globals[key]

    return value != nil and value or default
end

function entityMeta:GetNetVar(key, default)
    local index = self:EntIndex()

    if (impulse.NetVar[index] and impulse.NetVar[index][key] != nil) then
        return impulse.NetVar[index][key]
    end

    return default
end

playerMeta.GetLocalVar = entityMeta.GetNetVar