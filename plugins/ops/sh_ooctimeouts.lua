local infoCol = Color(135, 206, 250)

if ( SERVER ) then
    util.AddNetworkString("opsGiveOOCBan")
end

impulse.OOCTimeouts = impulse.OOCTimeouts or {}

local timeoutCommand = {
    description = "Gives the player an OOC ban for the time provided, in minutes. Reason is optional.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local time = arg[2]
        local reason = arg[3]
        local plyTarget = impulse.Util:FindPlayer(name)

        if not time or not tonumber(time) then
            return client:Notify("Please specific a valid time value in minutes.")
        end

        time = tonumber(time)
        time = time * 60

        if plyTarget then
            local sid = plyTarget:SteamID64()
            impulse.OOCTimeouts[sid] = CurTime() + time
            plyTarget:Notify("Reason: "..(reason or "Behaviour that violates the community guidelines")..".")
            plyTarget:Notify("You have been issued an OOC communication timeout by a game moderator that will last "..(time / 60).." minutes.")

            timer.Create("impulseOOCTimeout"..sid, time, 1, function()
                if not impulse.OOCTimeouts[sid] then return end

                impulse.OOCTimeouts[sid] = nil

                if IsValid(plyTarget) then
                    plyTarget:Notify("You OOC communication timeout has expired. You may now use OOC again. Please review the community guidelines before sending messages again.")
                end
            end)

            local t = (time / 60)

            client:Notify("You have issued "..plyTarget:SteamName().." an OOC timeout for "..t.." minutes.")

            for v, k in player.Iterator() do
                k:AddChatText(infoCol, plyTarget:SteamName().." has been given an OOC timeout for "..t.." minutes by a game moderator.")
            end

            net.Start("opsGiveOOCBan")
            net.WriteUInt(os.time() + time, 16)
            net.Send(plyTarget)
        else
            return client:Notify("Could not find player: "..tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/ooctimeout", timeoutCommand)

local unTimeoutCommand = {
    description = "Revokes an OOC communication timeout from the player specified.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        if plyTarget then
            impulse.OOCTimeouts[plyTarget:SteamID64()] = nil
            client:Notify("The OOC communication timeout has been removed from "..plyTarget:Name()..".")
        else
            return client:Notify("Could not find player: "..tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/unooctimeout", unTimeoutCommand)
