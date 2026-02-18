local managerCommand = {
    description = "Opens the support tool.",
    cami = "impulse: Handle Support Tool",
    onRun = function(client)
        impulse.Ops.ST.Open(client)
    end
}

impulse.RegisterChatCommand("/supporttool", managerCommand)

if ( CLIENT ) then
    net.Receive("impulseOpsSTOpenTool", function()
        vgui.Create("impulseSupportTool")
    end)

    local refundData

    net.Receive("impulseOpsSTGetRefund", function()
        local len = net.ReadUInt(32)
        local items = pon.decode(net.ReadData(len))

        refundData = items
    end)

    function PLUGIN:DisplayMenuMessages()
        if !refundData then return end

        local msg = "You have been refunded items by support.\nYou can find these items in your private storage.\n\nRefunded items:"

        for v, k in pairs(refundData) do
            local netid = impulse.Inventory:ClassToNetID(v)
            if !netid then continue end -- invalid item?

            local item = impulse.Inventory.Items[netid]


            msg = msg .. "\n" .. item.Name .. " x" .. k
        end

        Derma_Message(msg, "impulse", "Claim Refund")
        refundData = nil
    end
end
