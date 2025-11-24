
DEFINE_BASECLASS("DModelPanel")

local PANEL = {}
local MODEL_ANGLE = Angle(0, 45, 0)

function PANEL:Init()
    self.brightness = 1
    self:SetCursor("none")
end

function PANEL:SetModel(model, skin, bodygroups)
    if (IsValid(self.Entity)) then
        self.Entity:Remove()
        self.Entity = nil
    end

    if (!ClientsideModel) then return end

    local entity = ClientsideModel(model, RENDERGROUP_OPAQUE)

    if (!IsValid(entity)) then return end

    entity:SetNoDraw(true)
    entity:SetIK(false)

    if (skin) then
        entity:SetSkin(skin)
    end

    if (isstring(bodygroups)) then
        entity:SetBodyGroups(bodygroups)
    end

    local sequence = entity:LookupSequence("idle_unarmed")

    if (sequence <= 0) then
        sequence = entity:SelectWeightedSequence(ACT_IDLE)
    end

    if (sequence > 0) then
        entity:ResetSequence(sequence)
    else
        local found = false

        for _, v in ipairs(entity:GetSequenceList()) do
            if ((v:lower():find("idle") or v:lower():find("fly")) and v != "idlenoise") then
                entity:ResetSequence(v)
                found = true

                break
            end
        end

        if (!found) then
            entity:ResetSequence(4)
        end
    end

    self.Entity = entity
end

function PANEL:LayoutEntity()
    local entity = self.Entity

    entity:SetAngles(MODEL_ANGLE)
    entity:SetIK(false)

    if (self.copyLocalSequence) then
        entity:SetSequence(LocalPlayer():GetSequence())

        for i = 0, entity:GetNumPoseParameters() - 1 do
            local name = entity:GetPoseParameterName(i)
            local value = LocalPlayer():GetPoseParameter(name)
            entity:SetPoseParameter(name, value)
        end
    end

    self:RunAnimation()
end

function PANEL:DrawModel()
    local brightness = self.brightness * 0.4
    local brightness2 = self.brightness * 1.5

    render.SetStencilEnable(false)
    render.SetColorMaterial()
    render.SetColorModulation(1, 1, 1)
    render.SetModelLighting(0, brightness2, brightness2, brightness2)

    for i = 1, 4 do
        render.SetModelLighting(i, brightness, brightness, brightness)
    end

    local fraction = (brightness / 1) * 0.1

    render.SetModelLighting(5, fraction, fraction, fraction)

    -- Excecute Some stuffs
    if (self.enableHook) then
        hook.Run("DrawImpulseModelView", self, self.Entity)
    end

    self.Entity:DrawModel()

    if (self.enableHook) then
        hook.Run("PostDrawImpulseModelView", self, self.Entity)
    end
end

function PANEL:OnMousePressed()
end

vgui.Register("impulseModelPanel", PANEL, "DModelPanel")
