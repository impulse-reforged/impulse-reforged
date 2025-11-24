function PLUGIN:PlayerShouldGetHungry(client)
    if client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP then return false end
end
