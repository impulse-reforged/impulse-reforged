local cleanupCommand = {
    description = "Removes all the props of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        if plyTarget then
            impulse.Ops.CleanupPlayer(plyTarget)

            plyTarget:Notify("Your props have been removed by a game moderator (" .. client:SteamName() .. ").")
            client:Notify("You have cleaned up " .. plyTarget:Name() .. "'s props.")
        else
            return client:Notify("Could not find player: " .. tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/cleanup", cleanupCommand)

local cleanupAllCommand = {
    description = "Cleans up ALL props on the server. (optional) countdown argument (in seconds)",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local countdown = arg[1]

        if DOING_CLEANUP and countdown then
            return client:Notify("A cleanup is already queued.")
        end

        if countdown and tonumber(countdown) and tonumber(countdown) > 0 then
            countdown = math.Clamp(math.floor(tonumber(countdown)), 40, 600)
            local countdownEnd = CurTime() + countdown
            local r = countdown / 10
            local left = countdown

            DOING_CLEANUP = true
            timer.Create("impulseOpsCleanupClock", 10, r, function()
                left = left - 10

                if left == 0 then
                    impulse.Ops.CleanupAll()

                    for v, k in player.Iterator() do
                        k:Notify("Your props have been removed due to a server cleanup.")
                    end

                    DOING_CLEANUP = false
                else
                    for v, k in player.Iterator() do
                        k:Notify("WARNING: All props will be cleaned up in " .. left .. " seconds.")
                    end
                end
            end)

            for v, k in player.Iterator() do
                k:Notify("WARNING: All props will be cleaned up in " .. countdown .. " seconds.")
            end

            client:Notify("Cleanup countdown for " .. countdown .. " seconds has started.")
        else
            impulse.Ops.CleanupAll()

            for v, k in player.Iterator() do
                k:Notify("Your props have been removed due to a server cleanup.")
            end
        end
    end
}

impulse.RegisterChatCommand("/cleanupall", cleanupAllCommand)

local clearDecalsCommand = {
    description = "Clears all decals on the server.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ClearDecals()
        client:Notify("You have cleared all the decals on the map.")
    end
}

impulse.RegisterChatCommand("/cleardecals", clearDecalsCommand)

local clearCorpsesCommand = {
    description = "Clears all corpses (ragdolls) on the server.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ClearCorpses()
        client:Notify("You have cleared all the corpses on the map.")
    end
}

impulse.RegisterChatCommand("/clearcorpses", clearCorpsesCommand)
