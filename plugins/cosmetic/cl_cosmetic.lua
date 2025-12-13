impulse.impulseCosmetics = impulse.impulseCosmetics or {}

function MakeCosmetic(client, id, bone, data, slot)
    if !data then return end

    client.impulseCosmetics = client.impulseCosmetics or {}

    SafeRemoveEntity(client.impulseCosmetics[slot])

    client.impulseCosmetics[slot] = ClientsideModel(data.model, RENDERGROUP_BOTH)
    client.impulseCosmetics[slot]:SetNoDraw(true)

    if data.bodygroups then
        client.impulseCosmetics[slot]:SetBodyGroups(data.bodygroups)
    end

    if data.skin then
        client.impulseCosmetics[slot]:SetSkin(data.skin)
    end

    if data.onEntLoad then
        if client:GetClass() == "class C_BaseFlex" then -- ui support
            data.onEntLoad(LocalPlayer(), client.impulseCosmetics[slot])
        else
            data.onEntLoad(client, client.impulseCosmetics[slot])
        end
    end

    local t = LocalPlayer():Team()

    if client:IsPlayer() then
        t = client:Team()
    end

    if data.teamCustomScale and data.teamCustomScale[t] then
        client.impulseCosmetics[slot]:SetModelScale(client.impulseCosmetics[slot]:GetModelScale() * data.teamCustomScale[t])
    elseif client:IsFemale() and data.femaleScale then
        client.impulseCosmetics[slot]:SetModelScale(client.impulseCosmetics[slot]:GetModelScale() * data.femaleScale)
    else
        client.impulseCosmetics[slot]:SetModelScale(client.impulseCosmetics[slot]:GetModelScale() * data.scale)
    end

    if data.matrixScale then
        local mat = Matrix()
        mat:Scale(data.matrixScale)
        client.impulseCosmetics[slot]:EnableMatrix("RenderMultiply", mat)
    end

    if data.subMaterials then
        for v, k in pairs(data.subMaterials) do
            client.impulseCosmetics[slot]:SetSubMaterial(v, k)
        end
    end

    client.impulseCosmetics[slot].drawdata = data
    client.impulseCosmetics[slot].bone = bone
    client.impulseCosmetics[slot].owner = client
end

function RemoveCosmetic(client, ent, slot)
    client.impulseCosmetics[slot] = nil
    SafeRemoveEntity(ent)
end

local lastFace = -1
local lastHat = -1
local lastChest = -1

hook.Add("PostPlayerDraw", "impulseCosmeticDraw", function(k)
    if !k:Alive() then return end

    if k.impulseCosmetics then
        for a,b in pairs(k.impulseCosmetics) do
            if !IsValid(b) then continue end
            local bone
            local attach
            local matrix
            local pos
            local ang

            if b.drawdata.attachment then
                local lk = k:LookupAttachment(b.drawdata.attachment)

                if lk == "0" then
                    return
                end

                local attach = k:GetAttachment(lk)
                
                pos = attach.Pos
                ang = attach.Ang
            else
                bone = k:LookupBone(b.bone)

                if !bone then
                    return
                end
                
                matrix = k:GetBoneMatrix(bone)

                if !matrix then
                    return
                end

                pos = matrix:GetTranslation()
                ang = matrix:GetAngles()
            end

            local f = ang:Forward()
            local u = ang:Up()
            local r = ang:Right()
            local isFemale = k:IsFemale()
            local teamCustom = b.drawdata.teamCustomPos

            local t = LocalPlayer():Team()

            if k:IsPlayer() then
                t = k:Team()
            end

            if teamCustom and teamCustom[t] then
                pos = pos + (r * teamCustom[t].x) + (f * teamCustom[t].y) + (u * teamCustom[t].z)
            elseif isFemale and b.drawdata.femalePos then
                pos = pos + (r * b.drawdata.femalePos.x) + (f * b.drawdata.femalePos.y) + (u * b.drawdata.femalePos.z)
            else
                pos = pos + (r * b.drawdata.pos.x) + (f * b.drawdata.pos.y) + (u * b.drawdata.pos.z)
            end

            b:SetRenderOrigin(pos)

            if isFemale and b.drawdata.femaleAng then
                ang:RotateAroundAxis(f, b.drawdata.femaleAng.p)
                ang:RotateAroundAxis(u, b.drawdata.femaleAng.y)
                ang:RotateAroundAxis(r, b.drawdata.femaleAng.r)
            else
                ang:RotateAroundAxis(f, b.drawdata.ang.p)
                ang:RotateAroundAxis(u, b.drawdata.ang.y)
                ang:RotateAroundAxis(r, b.drawdata.ang.r)
            end

            b:SetRenderAngles(ang)
            
            if b.drawdata.renderSetting then
                if impulse.Settings:Get(b.drawdata.renderSetting) then
                    b:DrawModel()
                end
            else
                b:DrawModel()
            end
        end
    end

    local faceCos = k:GetRelay("cosmeticFace") -- uses bone 6 face
    local hatCos = k:GetRelay("cosmeticHead") -- uses bone 6 face
    local chestCos = k:GetRelay("cosmeticChest") -- uses bone 1 spine

    if faceCos then
        if faceCos != (k.lastFace or -1) then
            MakeCosmetic(k, faceCos, "ValveBiped.Bip01_Head1", impulse.impulseCosmetics[faceCos], 1)
            k.lastFace = faceCos
        end  
    elseif k.impulseCosmetics and k.impulseCosmetics[1] and IsValid(k.impulseCosmetics[1]) then -- cosmetic removed
        RemoveCosmetic(k, k.impulseCosmetics[1], 1)
        k.lastFace = -1
    end

    if hatCos then
        if hatCos != (k.lastHat or -1) then
            MakeCosmetic(k, hatCos, "ValveBiped.Bip01_Head1", impulse.impulseCosmetics[hatCos], 2)
            k.lastHat = hatCos
        end  
    elseif k.impulseCosmetics and k.impulseCosmetics[2] and IsValid(k.impulseCosmetics[2]) then -- cosmetic removed
        RemoveCosmetic(k, k.impulseCosmetics[2], 2)
        k.lastHat = -1
    end

    if chestCos then
        if chestCos != (k.lastChest or -1) then
            MakeCosmetic(k, chestCos, "ValveBiped.Bip01_Spine2", impulse.impulseCosmetics[chestCos], 3)
            k.lastChest = hatCos
        end  
    elseif k.impulseCosmetics and k.impulseCosmetics[3] and IsValid(k.impulseCosmetics[3]) then -- cosmetic removed
        RemoveCosmetic(k, k.impulseCosmetics[3], 3)
        k.lastChest = -1
    end
end)

hook.Add("SetupInventoryModel", "impulseDrawCosmetics", function(panel)
    panel.lastFaceI = -1
    panel.lastHatI = -1
    panel.lastChestI = -1

    function panel:PostDrawModel(k)
        if k.impulseCosmetics then
            for a,b in pairs(k.impulseCosmetics) do
                if !IsValid(b) then continue end

                local bone
                local attach
                local matrix
                local pos
                local ang

                if b.attachment then
                    local lk = k:LookupAttachment(b.attachment)

                    if lk == "0" then
                        return
                    end

                    local attach = k:GetAttachment(lk)
                    
                    pos = attach.Pos
                    ang = attach.Ang
                else
                    bone = k:LookupBone(b.bone)

                    if !bone then
                        return
                    end
                    
                    matrix = k:GetBoneMatrix(bone)

                    if !matrix then
                        return
                    end

                    pos = matrix:GetTranslation()
                    ang = matrix:GetAngles()
                end

                local f = ang:Forward()
                local u = ang:Up()
                local r = ang:Right()
                local isFemale = k:IsFemale()
                local teamCustom = b.drawdata.teamCustomPos

                local t = LocalPlayer():Team()

                if teamCustom and teamCustom[t] then
                    pos = pos + (r * teamCustom[t].x) + (f * teamCustom[t].y) + (u * teamCustom[t].z)
                elseif isFemale and b.drawdata.femalePos then
                    pos = pos + (r * b.drawdata.femalePos.x) + (f * b.drawdata.femalePos.y) + (u * b.drawdata.femalePos.z)
                else
                    pos = pos + (r * b.drawdata.pos.x) + (f * b.drawdata.pos.y) + (u * b.drawdata.pos.z)
                end

                b:SetRenderOrigin(pos)

                if isFemale and b.drawdata.femaleAng then
                    ang:RotateAroundAxis(f, b.drawdata.femaleAng.p)
                    ang:RotateAroundAxis(u, b.drawdata.femaleAng.y)
                    ang:RotateAroundAxis(r, b.drawdata.femaleAng.r)
                else
                    ang:RotateAroundAxis(f, b.drawdata.ang.p)
                    ang:RotateAroundAxis(u, b.drawdata.ang.y)
                    ang:RotateAroundAxis(r, b.drawdata.ang.r)
                end
                
                b:SetRenderAngles(ang)
                b:DrawModel()
            end
        end

        local faceCos = LocalPlayer():GetRelay("cosmeticFace") -- uses bone 6 face
        local hatCos = LocalPlayer():GetRelay("cosmeticHead") -- uses bone 6 face
        local chestCos = LocalPlayer():GetRelay("cosmeticChest") -- uses bone 1 spine

        if faceCos then
            if faceCos != self.lastFaceI then
                MakeCosmetic(k, faceCos, "ValveBiped.Bip01_Head1", impulse.impulseCosmetics[faceCos], 1)
                self.lastFaceI = faceCos
            end  
        elseif k.impulseCosmetics and k.impulseCosmetics[1] and IsValid(k.impulseCosmetics[1]) then -- cosmetic removed
            RemoveCosmetic(k, k.impulseCosmetics[1], 1)
            self.lastFaceI = -1
        end

        if hatCos then
            if hatCos != self.lastHatI then
                MakeCosmetic(k, hatCos, "ValveBiped.Bip01_Head1", impulse.impulseCosmetics[hatCos], 2)
                self.lastHatI = hatCos
            end  
        elseif k.impulseCosmetics and k.impulseCosmetics[2] and IsValid(k.impulseCosmetics[2]) then -- cosmetic removed
            RemoveCosmetic(k, k.impulseCosmetics[2], 2)
            self.lastHatI = -1
        end

        if chestCos then
            if chestCos != self.lastChestI then
                MakeCosmetic(k, chestCos, "ValveBiped.Bip01_Spine2", impulse.impulseCosmetics[chestCos], 3)
                self.lastChestI = hatCos
            end  
        elseif k.impulseCosmetics and k.impulseCosmetics[3] and IsValid(k.impulseCosmetics[3]) then -- cosmetic removed
            RemoveCosmetic(k, k.impulseCosmetics[3], 3)
            self.lastChestI = -1
        end
    end
end)
