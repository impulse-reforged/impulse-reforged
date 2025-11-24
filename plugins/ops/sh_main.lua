hook.Add("PhysgunPickup", "opsPhysgunPickup", function(client, ent)
    if client:IsAdmin() and ent:IsPlayer() then
        ent:SetMoveType(MOVETYPE_NONE)
        return true
    end
end)

hook.Add("PhysgunDrop", "opsPhysgunDrop", function(client, ent)
    if ent:IsPlayer() then
        ent:SetMoveType(MOVETYPE_WALK)
    end
end)

local adminChatCol = Color(34, 88, 216)
local adminChatCommand = {
    description = "A super-secret chatroom for staff members.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        for v, k in player.Iterator() do
            if k:IsAdmin() then
                k:SendChatClassMessage(13, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/ac", adminChatCommand)
