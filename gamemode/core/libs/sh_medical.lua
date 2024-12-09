local PLAYER = FindMetaTable("Player")

function PLAYER:HasBrokenLegs()
    return self:GetSyncVar(SYNC_BROKENLEGS, false)
end