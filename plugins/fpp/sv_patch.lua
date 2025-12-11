
if FPP then
    local function runIfAccess(priv, f)
        return function(client, cmd, args)
            CAMI.PlayerHasAccess(client, priv, function(allowed, _)
                if allowed then return f(client, cmd, args) end

                FPP.Notify(client, string.format("You need the '%s' privilege in order to be able to use this command", priv), false)
            end)
        end
    end
    
    local function CleanupDisconnected(client, cmd, args)
        if !args[1] then FPP.Notify(client, "Invalid argument", false) return end
        if args[1] == "disconnected" then
            for _, v in ents.Iterator() do
                local Owner = v:CPPIGetOwner()
                if Owner and !IsValid(Owner) then
                    v:Remove()
                end
            end
            FPP.NotifyAll(((client.Nick and client:Nick()) or "Console") .. " removed all disconnected players' props", true)
            return
        elseif not tonumber(args[1]) or !IsValid(Player(tonumber(args[1]))) then
            FPP.Notify(client, "Invalid player", false)
            return
        end
    end
    concommand.Add("FPP_Cleanup", runIfAccess("FPP_Cleanup", CleanupDisconnected))

    local function nothin()
        return false
    end
    concommand.Add("FPP_FallbackOwner", nothin) -- turn this off cause it causes a lot of issues
end
