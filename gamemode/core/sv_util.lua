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

function meta:UpdateDefaultModelSkin()
    net.Start("impulseUpdateDefaultModelSkin")
    net.WriteString(self.defaultModel)
    net.WriteUInt(self.defaultSkin, 8)
    net.Send(self)
end

-- divert from slow nwvar shit
function meta:GetPropCount(skip)
    if ( !self:IsValid() ) then return end

    local key = self:UniqueID()
    local tab = g_SBoxObjects[key]

    if ( !tab || !tab["props"] ) then
        return 0
    end

    local c = 0

    for k, v in pairs(tab["props"]) do
        if ( IsValid(v) and !v:IsMarkedForDeletion() ) then
            c = c + 1
        else
            tab["props"][k] = nil
        end

    end

    if not skip then
        self:SetLocalSyncVar(SYNC_PROPCOUNT, c)
    end

    return c
end

function meta:AddPropCount(ent)
    local key = self:UniqueID()
    g_SBoxObjects[ key ] = g_SBoxObjects[ key ] or {}
    g_SBoxObjects[ key ]["props"] = g_SBoxObjects[ key ]["props"] or {}

    local tab = g_SBoxObjects[ key ]["props"]

    table.insert( tab, ent )

    self:GetPropCount()

    ent:CallOnRemove("GetPropCountUpdate", function(ent, ply) ply:GetPropCount() end, self)
end

function meta:ResetSubMaterials()
    if not self.SetSubMats then
        return
    end

    for v, k in pairs(self.SetSubMats) do
        self:SetSubMaterial(v - 1, nil)
    end

    self.SetSubMats = nil
end

function meta:ClearWorkbar()
    net.Start("impulseClearWorkbar")
    net.Send(self)
end

function meta:MakeWorkbar(time, text, onDone, popup)
    self:ClearWorkbar()

    if ( !time ) then
        net.Start("impulseMakeWorkbar")
        net.Send(self)

        return
    end

    net.Start("impulseMakeWorkbar")
        net.WriteUInt(time, 6)
        net.WriteString(text)
        net.WriteBool(popup)
    net.Send(self)

    if ( time and onDone ) then
        timer.Simple(time, function()
            if ( !IsValid(self) ) then return end

            onDone()
        end)
    end
end