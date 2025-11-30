AddCSLuaFile()

if ( CLIENT ) then
    SWEP.PrintName = "Loot Editor"
    SWEP.Slot = 0
    SWEP.SlotPos = 0
    SWEP.CLMode = 0
    SWEP.Author = "vin"
end

SWEP.HoldType = "fists"

SWEP.Category = "impulse"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.IsAlwaysRaised = true

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true

SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 0
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo  = "none"

SWEP.Secondary.Delay = 1
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots = 1
SWEP.Secondary.Cone = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

if ( SERVER ) then
    function SWEP:Equip(owner)
        if not owner:IsAdmin() then
            owner:StripWeapon("impulse_looteditor")
        end
    end
else
    local watermarkCol = Color(255, 255, 255, 120)
    function SWEP:DrawHUD()
        draw.SimpleText("LEFT: Register entity, RIGHT: Reset, RELOAD: Set as loot", "Impulse-Elements18-Shadow", 100, 100, watermarkCol)
        draw.SimpleText("STATE: " .. (self.State or "Spawn a prop and select it..."), "Impulse-Elements18-Shadow", 100, 120, watermarkCol)

        local count = 0
        for k, v in pairs(ents.FindByClass("impulse_container")) do
            if v.GetLoot and v:GetLoot() then
                count = count + 1

                local sPos = v:GetPos():ToScreen()
                draw.SimpleText("Loot#" .. v:EntIndex(), "Impulse-Elements18-Shadow", sPos.x, sPos.y, Color(255, 0, 0, 120), TEXT_ALIGN_CENTER)
            end
        end

        draw.SimpleText("INFO: LOOT CONTAINER COUNT: " .. count, "Impulse-Elements18-Shadow", 100, 140, watermarkCol)
    end
end

function SWEP:PrimaryAttack()
    if ( !self.nextPrimaryAttack ) then self.nextPrimaryAttack = 0 end
    if ( CurTime() < self.nextPrimaryAttack ) then return end

    local owner = self:GetOwner()

    local tr = util.GetPlayerTrace( owner )
    tr.mask = toolmask
    tr.mins = vector_origin
    tr.maxs = tr.mins
    local trace = util.TraceLine( tr )
    if ( !trace.Hit ) then trace = util.TraceHull( tr ) end
    if ( !trace.Hit ) then return end

    self:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted() )

    self.nextPrimaryAttack = CurTime() + self.Primary.Delay

    if ( SERVER ) then return end

    local trace = {}
    trace.start = self:GetOwner():EyePos()
    trace.endpos = trace.start + self:GetOwner():GetAimVector() * 140
    trace.filter = self:GetOwner()

    local tr = util.TraceLine(trace)
    local ent = tr.Entity

    if not self.SelectedStorage and IsValid(ent) and ent:GetClass() == "prop_physics" then
        self.SelectedStorage = ent
        self.State = "Prop " .. ent:EntIndex() .. " (" .. ent:GetModel() .. ") selected, ready for export..."

        surface.PlaySound("buttons/blip1.wav")
        self:GetOwner():Notify("Ready for export!")
    end

    local function sendLootReq(pool)
        if not IsValid(self.SelectedStorage) then
            return LocalPlayer():Notify("Entity missing.")
        end

        net.Start("impulseLootEditorSet")
            net.WriteString(pool)
            net.WriteEntity(self.SelectedStorage)
        net.SendToServer()

        self.SelectedStorage = nil
        self.State = nil
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Loot Pool Selector")
    frame:SetSize(ScrW() * 0.2, ScrH() * 0.4)
    frame:Center()
    frame:MakePopup()

    panel = frame:Add("DScrollPanel")
    panel:Dock(FILL)

    for k, v in SortedPairs(impulse.Config.LootPools) do
        button = panel:Add("DButton")
        button:SetText(k)
        button:Dock(TOP)
        button.DoClick = function(this)
            sendLootReq(k)
            frame:Remove()
        end
    end
end

function SWEP:SecondaryAttack()
    if ( !self.nextSecondaryAttack ) then self.nextSecondaryAttack = 0 end
    if ( CurTime() < self.nextSecondaryAttack ) then return end

    if ( SERVER ) then return end

    self.SelectedStorage = nil
    self.SelectedDoor = nil
    self.State = nil

    if ( CLIENT ) then
        surface.PlaySound("buttons/button10.wav")
    end

    self.nextSecondaryAttack = CurTime() + self.Secondary.Delay
end

function SWEP:Reload()
end

if ( SERVER ) then
    util.AddNetworkString("impulseLootEditorSet")

    net.Receive("impulseLootEditorSet", function(len, client)
        if not client:IsSuperAdmin() then return end

        local pool = net.ReadString()
        local ent = net.ReadEntity()

        if not IsValid(ent) or ent:GetClass() != "prop_physics" then return end

        if not impulse.Config.LootPools[pool] then return end

        local entModel = ent:GetModel()
        local entPos = ent:GetPos()
        local entAng = ent:GetAngles()

        ent:Remove()

        local container = ents.Create("impulse_container")
        container.impulseSaveKeyValue = {}
        container.impulseSaveKeyValue["model"] = entModel
        container.impulseSaveKeyValue["lootpool"] = pool
        container:SetPos(entPos)
        container:SetAngles(entAng)
        container:Spawn()

        client:Notify("Lootable container for with pool as " .. pool .. " created. Please mark and save the generated entity.")
    end)
end

function SWEP:DoShootEffect( hitpos, hitnormal, entity, physbone, bFirstTimePredicted )
    local owner = self:GetOwner()

    self:EmitSound( Sound( "Airboat.FireGunRevDown" ) )
    self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

    owner:SetAnimation( PLAYER_ATTACK1 )

    if ( !bFirstTimePredicted ) then return end
    if ( GetConVarNumber( "gmod_drawtooleffects" ) == 0 ) then return end

    local effectdata = EffectData()
    effectdata:SetOrigin( hitpos )
    effectdata:SetNormal( hitnormal )
    effectdata:SetEntity( entity )
    effectdata:SetAttachment( physbone )
    util.Effect( "selection_indicator", effectdata )

    local effect_tr = EffectData()
    effect_tr:SetOrigin( hitpos )
    effect_tr:SetStart( owner:GetShootPos() )
    effect_tr:SetAttachment( 1 )
    effect_tr:SetEntity( self )
    util.Effect( "ToolTracer", effect_tr )
end
