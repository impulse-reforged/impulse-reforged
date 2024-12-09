AddCSLuaFile()

if( CLIENT ) then
    SWEP.PrintName = "Vendor Placer"
    SWEP.Slot = 0
    SWEP.SlotPos = 0
    SWEP.CLMode = 0
    SWEP.Author = "Riggs"
end
SWEP.HoldType = "revolver"

SWEP.Category = "impulse"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.IsAlwaysRaised = true

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true

SWEP.Primary.Delay            = 1
SWEP.Primary.Recoil            = 0    
SWEP.Primary.Damage            = 0
SWEP.Primary.NumShots        = 0
SWEP.Primary.Cone            = 0     
SWEP.Primary.ClipSize        = -1    
SWEP.Primary.DefaultClip    = -1    
SWEP.Primary.Automatic       = false    
SWEP.Primary.Ammo             = "none"
 
SWEP.Secondary.Delay        = 1
SWEP.Secondary.Recoil        = 0
SWEP.Secondary.Damage        = 0
SWEP.Secondary.NumShots        = 1
SWEP.Secondary.Cone            = 0
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo         = "none"

if SERVER then
    function SWEP:Equip(owner)
        if not owner:IsAdmin() then
            owner:StripWeapon("impulse_vendorplacer")
        end
    end
else
    function SWEP:DrawHUD()
        draw.SimpleText("LEFT: Place Vendor", "BudgetLabel", 100, 100)
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

    local function sendVendorReq(uniqueID)
        net.Start("impulseVendorPlace")
            net.WriteString(uniqueID)
        net.SendToServer()
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Vendor Placer")
    frame:SetSize(ScrW() * 0.2, ScrH() * 0.4)
    frame:Center()
    frame:MakePopup()

    frame.place = frame:Add("DButton")
    frame.place:SetText("Select a vendor")
    frame.place:Dock(BOTTOM)

    panel = frame:Add("DScrollPanel")
    panel:Dock(FILL)

    for k, v in pairs(impulse.Vendor.Data) do
        button = panel:Add("DButton")
        button:SetText(v.Name)
        button:Dock(TOP)
        button.DoClick = function(this)
            frame.place:SetText("Spawn "..v.Name)
            frame.place.DoClick = function(this)
                sendVendorReq(v.UniqueID)
            end
        end
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

if SERVER then
    util.AddNetworkString("impulseVendorPlace")

    net.Receive("impulseVendorPlace", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        
        local uniqueID = net.ReadString()
        
        if not impulse.Vendor.Data[uniqueID] then return end
        
        local trace = ply:GetEyeTrace()
        local ang = ply:EyeAngles()
        ang:RotateAroundAxis(ang:Right(), 180)
        ang:RotateAroundAxis(ang:Up(), 180)
        ang.x = 180
        ang:SnapTo("y", 45)

        local vendor = ents.Create("impulse_vendor")
        vendor.impulseSaveKeyValue = {}
        vendor.impulseSaveKeyValue["vendor"] = uniqueID
        vendor:SetPos(trace.HitPos)
        vendor:SetAngles(ang)
        vendor:Spawn()

        ply:Notify("Vendor with Unique ID "..uniqueID.." created. Please mark and save the spawned vendor.")
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