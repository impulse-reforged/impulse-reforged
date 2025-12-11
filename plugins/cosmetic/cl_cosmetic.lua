impulse.Cosmetics = impulse.Cosmetics or {}

function MakeCosmetic(client, id, bone, data, slot)
    client.Cosmetics = client.Cosmetics or {}

    SafeRemoveEntity(client.Cosmetics[slot])

    client.Cosmetics[slot] = ClientsideModel(data.model, RENDERGROUP_BOTH)
    client.Cosmetics[slot]:SetNoDraw(true)

    if data.bodygroups then
        client.Cosmetics[slot]:SetBodyGroups(data.bodygroups)
    end

    if data.skin then
        client.Cosmetics[slot]:SetSkin(data.skin)
    end

    if data.onEntLoad then
        if client:GetClass() == "class C_BaseFlex" then -- ui support
            data.onEntLoad(LocalPlayer(), client.Cosmetics[slot])
        else
            data.onEntLoad(client, client.Cosmetics[slot])
        end
    end

    local t = LocalPlayer():Team()

    if client:IsPlayer() then
        t = client:Team()
    end

    if data.teamCustomScale and data.teamCustomScale[t] then
        client.Cosmetics[slot]:SetModelScale(client.Cosmetics[slot]:GetModelScale() * data.teamCustomScale[t])
    elseif client:IsFemale() and data.femaleScale then
        client.Cosmetics[slot]:SetModelScale(client.Cosmetics[slot]:GetModelScale() * data.femaleScale)
    else
        client.Cosmetics[slot]:SetModelScale(client.Cosmetics[slot]:GetModelScale() * data.scale)
    end

    if data.matrixScale then
        local mat = Matrix()
        mat:Scale(data.matrixScale)
        client.Cosmetics[slot]:EnableMatrix("RenderMultiply", mat)
    end

    if data.subMaterials then
        for v, k in pairs(data.subMaterials) do
            client.Cosmetics[slot]:SetSubMaterial(v, k)
        end
    end

    client.Cosmetics[slot].drawdata = data
    client.Cosmetics[slot].bone = bone
    client.Cosmetics[slot].owner = client
end

function RemoveCosmetic(client, ent, slot)
    client.Cosmetics[slot] = nil
    SafeRemoveEntity(ent)
end

local lastFace = -1
local lastHat = -1
local lastChest = -1

hook.Add("PostPlayerDraw", "impulseCosmeticDraw", function(k)
    if !k:Alive() then return end

    if k.Cosmetics then
        for a,b in pairs(k.Cosmetics) do
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
            MakeCosmetic(k, faceCos, "ValveBiped.Bip01_Head1", impulse.Cosmetics[faceCos], 1)
            k.lastFace = faceCos
        end  
    elseif k.Cosmetics and k.Cosmetics[1] and IsValid(k.Cosmetics[1]) then -- cosmetic removed
        RemoveCosmetic(k, k.Cosmetics[1], 1)
        k.lastFace = -1
    end

    if hatCos then
        if hatCos != (k.lastHat or -1) then
            MakeCosmetic(k, hatCos, "ValveBiped.Bip01_Head1", impulse.Cosmetics[hatCos], 2)
            k.lastHat = hatCos
        end  
    elseif k.Cosmetics and k.Cosmetics[2] and IsValid(k.Cosmetics[2]) then -- cosmetic removed
        RemoveCosmetic(k, k.Cosmetics[2], 2)
        k.lastHat = -1
    end

    if chestCos then
        if chestCos != (k.lastChest or -1) then
            MakeCosmetic(k, chestCos, "ValveBiped.Bip01_Spine2", impulse.Cosmetics[chestCos], 3)
            k.lastChest = hatCos
        end  
    elseif k.Cosmetics and k.Cosmetics[3] and IsValid(k.Cosmetics[3]) then -- cosmetic removed
        RemoveCosmetic(k, k.Cosmetics[3], 3)
        k.lastChest = -1
    end
end)

hook.Add("SetupInventoryModel", "impulseDrawCosmetics", function(panel)
    panel.lastFaceI = -1
    panel.lastHatI = -1
    panel.lastChestI = -1

    function panel:PostDrawModel(k)
        if k.Cosmetics then
            for a,b in pairs(k.Cosmetics) do
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
                MakeCosmetic(k, faceCos, "ValveBiped.Bip01_Head1", impulse.Cosmetics[faceCos], 1)
                self.lastFaceI = faceCos
            end  
        elseif k.Cosmetics and k.Cosmetics[1] and IsValid(k.Cosmetics[1]) then -- cosmetic removed
            RemoveCosmetic(k, k.Cosmetics[1], 1)
            self.lastFaceI = -1
        end

        if hatCos then
            if hatCos != self.lastHatI then
                MakeCosmetic(k, hatCos, "ValveBiped.Bip01_Head1", impulse.Cosmetics[hatCos], 2)
                self.lastHatI = hatCos
            end  
        elseif k.Cosmetics and k.Cosmetics[2] and IsValid(k.Cosmetics[2]) then -- cosmetic removed
            RemoveCosmetic(k, k.Cosmetics[2], 2)
            self.lastHatI = -1
        end

        if chestCos then
            if chestCos != self.lastChestI then
                MakeCosmetic(k, chestCos, "ValveBiped.Bip01_Spine2", impulse.Cosmetics[chestCos], 3)
                self.lastChestI = hatCos
            end  
        elseif k.Cosmetics and k.Cosmetics[3] and IsValid(k.Cosmetics[3]) then -- cosmetic removed
            RemoveCosmetic(k, k.Cosmetics[3], 3)
            self.lastChestI = -1
        end
    end
end)
