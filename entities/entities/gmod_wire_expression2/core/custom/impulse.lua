if !E2Lib then
    return
end

E2Lib.RegisterExtension("impulse", true, "Allows E2 to interact with certain methods in the impulse framework.")

local function checkOwner(self)
    return IsValid(self.player);
end

__e2setcost(35)

e2function string impulseGetItemClass(entity ent)
    if !IsValid(ent) then return end
    if ent:GetClass() != "impulse_item" or !ent.Item then return end

    return ent.Item.UniqueID or "unknown"
end

e2function number impulseGetMoneyValue(entity ent)
    if !IsValid(ent) then return 0 end
    if ent:GetClass() != "impulse_money" or !ent.money then
        return 0
    end

    return ent.money
end

e2function number impulseGetPlayerFirstJoinDate(entity ent)
    if !IsValid(ent) then return end
    if !ent:IsPlayer() or !ent.impulseFirstJoin then
        return 0
    end

    return ent.impulseFirstJoin
end
