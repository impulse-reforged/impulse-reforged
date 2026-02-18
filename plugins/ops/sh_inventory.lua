if ( SERVER ) then
    util.AddNetworkString("impulseOpsViewInv")
    util.AddNetworkString("impulseOpsRemoveInv")

    net.Receive("impulseOpsRemoveInv", function(len, client)
        if !CAMI.PlayerHasAccess(client, "impulse: Remove Items") then return end

        local targ = net.ReadUInt(8)
        local invSize = net.ReadUInt(16)

        targ = Entity(targ)
        if !IsValid(targ) then return end

        for i = 1,invSize do
            local itemid = net.ReadUInt(16)
            local hasItem = targ:HasInventoryItemSpecific(itemid)

            if hasItem then
                targ:TakeInventoryItem(itemid)
            end
        end

        client:Notify("Removed " .. invSize .. " items from " .. targ:Nick() .. "'s inventory.")
    end)
else
    net.Receive("impulseOpsViewInv", function()
        local searchee = Entity(net.ReadUInt(8))
        local invSize = net.ReadUInt(16)
        local invCompiled = {}

        if !IsValid(searchee) then return end

        for i = 1,invSize do
            local itemnetid = net.ReadUInt(10)
            local itemrestricted = net.ReadBool()
            local itemequipped = net.ReadBool()
            local itemid = net.ReadUInt(16)
            local item = impulse.Inventory.Items[itemnetid]

            table.insert(invCompiled, {item, itemrestricted, itemequipped, itemid})
        end

        local searchMenu = vgui.Create("impulseSearchMenuAdmin")
        searchMenu:SetInv(invCompiled)
        searchMenu:SetPlayer(searchee)
    end)
end

local viewInvCommand = {
    description = "Allows you to view and delete items from the player specified.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        if plyTarget then
            if !plyTarget.impulseBeenInventorySetup then return client:Notify("Target is loading still...") end

            local inv = plyTarget:GetInventory(1)
            net.Start("impulseOpsViewInv")
            net.WriteUInt(plyTarget:EntIndex(), 8)
            net.WriteUInt(table.Count(inv), 16)

            for v, k in pairs(inv) do
                local netid = impulse.Inventory:ClassToNetID(k.class)
                net.WriteUInt(netid, 10)
                net.WriteBool(k.restricted or false)
                net.WriteBool(k.equipped or false)
                net.WriteUInt(v, 16)
            end

            net.Send(client)
        else
            return client:Notify("Could not find player: " .. tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/viewinv", viewInvCommand)

local restoreInvCommand = {
    description = "Restores a players inventory to the last state before death. (SteamID64 only)",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local plyTarget = player.GetBySteamID64(name)

        if plyTarget then
            if plyTarget.InventoryRestorePoint then
                plyTarget:ClearInventory(1)

                for v, k in pairs(plyTarget.InventoryRestorePoint) do
                    plyTarget:GiveItem(k)
                end

                plyTarget.InventoryRestorePoint = nil

                plyTarget:Notify("Your inventory has been restored to its last state by a game moderator.")
                client:Notify("You have restored " .. plyTarget:Nick() .. "'s inventory to the last state.")

                for v, k in player.Iterator() do
                    if CAMI.PlayerHasAccess(k, "impulse: Ban Players") then
                        k:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " restored " .. plyTarget:SteamName() .. "'s inventory.")
                    end
                end
            else
                return client:Notify("No restore point found for this player.")
            end
        else
            return client:Notify("Could not find player: " .. tostring(name) .. " (needs SteamID64 value)")
        end
    end
}

impulse.RegisterChatCommand("/restoreinv", restoreInvCommand)
