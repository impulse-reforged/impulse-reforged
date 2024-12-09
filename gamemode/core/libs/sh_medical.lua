local PLAYER = FindMetaTable("Player")

function PLAYER:HasBrokenLegs()
    return self:GetNetVar("brokenLegs", false)
end