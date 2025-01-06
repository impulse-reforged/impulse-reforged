--- Allows for control of "grouped" hooks, allowing for things like SCHEMA hooks to exist.
-- @module impulse.Hooks

impulse.Hooks = impulse.Hooks or {}
impulse.Hooks.Stored = impulse.Hooks.Stored or {}

--- Registers a new hook group
-- @realm shared
-- @string name Name of the hook group
function impulse.Hooks:Register(name)
    self.Stored[name] = true
end

--- Unregisters a hook group
-- @realm shared
-- @string name Name of the hook group
function impulse.Hooks:UnRegister(name)
    self.Stored[name] = nil
end

hook.impulseCall = hook.impulseCall or hook.Call

function hook.Call(name, gm, ...)
    for k, v in pairs(impulse.Hooks.Stored) do
        local tab = _G[k]
        if ( !tab ) then continue end

        local fn = tab[name]
        if ( !fn ) then continue end

        local a, b, c, d, e, f = fn(tab, ...)

        if ( a != nil ) then
            return a, b, c, d, e, f
        end
    end

    for k, v in pairs(impulse.Plugins.List) do
        for k2, v2 in pairs(v) do
            if ( type(v2) == "function" ) then
                if ( k2 == name ) then
                    local a, b, c, d, e, f = v2(v, ...)

                    if ( a != nil ) then
                        return a, b, c, d, e, f
                    end
                end
            end
        end
    end

    return hook.impulseCall(name, gm, ...)
end