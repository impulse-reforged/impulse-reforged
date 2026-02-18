
function impulse.Ops.EventManager.GetSequence()
    local val = GetGlobalString("opsEventSequence", "")

    if val == "" then return end

    return val
end

function impulse.Ops.EventManager.SetSequence(val)
    return SetGlobalString("opsEventSequence", val)
end

function impulse.Ops.EventManager.GetCurEvents()
    return impulse_OpsEM_CurEvents
end
