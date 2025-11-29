function PLUGIN:PlayerShouldGetHungry(client)
    if client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP then return false end
end

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "impulse_ops_disconnect", function(data)
    for _, target in player.Iterator() do
        if ( target:IsLeadAdmin() ) then
            target:AddChatText(Color(135, 206, 235), "[ops] " .. data.name .. " has disconnected from the server. (" .. data.reason .. ")")
        end
    end
end)

hook.Add("PlayerInitialSpawn", "impulse_ops_spawnmsg", function(client)
    for _, target in player.Iterator() do
        if ( target:IsLeadAdmin() ) then
            target:AddChatText(Color(135, 206, 235), "[ops] " .. client:SteamName() .. " has connected to the server.")
        end
    end
end)
