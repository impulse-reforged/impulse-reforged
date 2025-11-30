local swep = weapons.GetStored("gmod_tool")
function swep:DoShootEffect(hitpos, hitnormal, entity, physbone, bFirstTimePredicted)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK) -- View model animation
    -- There's a bug with the model that's causing a muzzle to
    -- appear on everyone's screen when we fire this animation.
    self:GetOwner():SetAnimation(PLAYER_ATTACK1) -- 3rd Person Animation
    if !bFirstTimePredicted then return end
    if GetConVar("gmod_drawtooleffects"):GetInt() == 0 then return end
    if self:GetOwner():GetMoveType() == MOVETYPE_NOCLIP then return end
    self:EmitSound(self.ShootSound)
    local effectdata = EffectData()
    effectdata:SetOrigin(hitpos)
    effectdata:SetNormal(hitnormal)
    effectdata:SetEntity(entity)
    effectdata:SetAttachment(physbone)
    util.Effect("selection_indicator", effectdata)
    effectdata = EffectData()
    effectdata:SetOrigin(hitpos)
    effectdata:SetStart(self:GetOwner():GetShootPos())
    effectdata:SetAttachment(1)
    effectdata:SetEntity(self)
    util.Effect("ToolTracer", effectdata)
end
