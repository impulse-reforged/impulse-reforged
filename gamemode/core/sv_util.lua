--- A generic module that holds anything that doesnt fit elsewhere
-- @module impulse.Util

impulse.Util = impulse.Util or {}

function impulse.Util:IsEmpty(vector, ignore) -- findpos and isempty are from darkrp
    ignore = ignore or {}

    local point = util.PointContents(vector)
    local a = point ~= CONTENTS_SOLID
        and point ~= CONTENTS_MOVEABLE
        and point ~= CONTENTS_LADDER
        and point ~= CONTENTS_PLAYERCLIP
        and point ~= CONTENTS_MONSTERCLIP
    if not a then return false end

    local b = true

    for _, v in ipairs(ents.FindInSphere(vector, 35)) do
        if (v:IsNPC() or v:IsPlayer() or v:GetClass() == "prop_physics" or v.NotEmptyPos) and !table.HasValue(ignore, v) then
            b = false
            break
        end
    end

    return a and b
end

function impulse.Util:FindEmptyPos(pos, ignore, distance, step, area)
    if self:IsEmpty(pos, ignore) and self:IsEmpty(pos + area, ignore) then
        return pos
    end

    for j = step, distance, step do
        for i = -1, 1, 2 do -- alternate in direction
            local k = j * i

            -- Look North/South
            if self:IsEmpty(pos + Vector(k, 0, 0), ignore) and self:IsEmpty(pos + Vector(k, 0, 0) + area, ignore) then
                return pos + Vector(k, 0, 0)
            end

            -- Look East/West
            if self:IsEmpty(pos + Vector(0, k, 0), ignore) and self:IsEmpty(pos + Vector(0, k, 0) + area, ignore) then
                return pos + Vector(0, k, 0)
            end

            -- Look Up/Down
            if self:IsEmpty(pos + Vector(0, 0, k), ignore) and self:IsEmpty(pos + Vector(0, 0, k) + area, ignore) then
                return pos + Vector(0, 0, k)
            end
        end
    end

    return pos
end

function impulse.Util:PlayGesture(ply, gesture, slot)
    local slot = slot or GESTURE_SLOT_CUSTOM

    net.Start("impulsePlayGesture")
        net.WritePlayer(ply)
        net.WriteString(gesture)
        net.WriteInt(slot, 16)
    net.Broadcast()
end