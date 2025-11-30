impulse.Ops = impulse.Ops or {}

function impulse.Ops.CleanupPlayer(client)
    local count = 0
    for v, k in ents.Iterator() do
        local owner = k:CPPIGetOwner()

        if owner == client then
            if not k.IsBuyable then
                count = count + 1
                k:Remove()
            end
        end
    end
    print("[ops] Cleaned up " .. count .. " entities for " .. client:Name() .. " (" .. client:SteamID64() .. ")")
end

function impulse.Ops.CleanupAll()
    local count = 0
    for v, k in ents.Iterator() do
        local owner = k:CPPIGetOwner()

        if owner and !k.IsBuyable then
            count = count + 1
            k:Remove()
        end
    end
    print("[ops] Cleaned up " .. count .. " total entities from the map")
end

function impulse.Ops.ClearDecals()
    local count = 0
    for v, k in player.Iterator() do
        k:ConCommand("r_cleardecals")
        count = count + 1
    end
    print("[ops] Cleared decals for " .. count .. " players")
end

function impulse.Ops.ClearCorpses()
    local count = 0
    for v, k in ents.Iterator() do
        if k:GetClass() == "prop_ragdoll" and k.DeadPlayer then
            SafeRemoveEntity(k)
            count = count + 1
        end
    end
    print("[ops] Cleared " .. count .. " corpses from the map")
end
