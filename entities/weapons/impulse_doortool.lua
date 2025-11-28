AddCSLuaFile()
if( CLIENT ) then
    SWEP.PrintName = "Door Editor"
    SWEP.Slot = 0
    SWEP.SlotPos = 0
    SWEP.CLMode = 0
end
SWEP.HoldType = "fists"

SWEP.Category = "impulse"
SWEP.Spawnable            = true
SWEP.AdminSpawnable        = true

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.Delay            = 1
SWEP.Primary.Recoil            = 0
SWEP.Primary.Damage            = 0
SWEP.Primary.NumShots        = 0
SWEP.Primary.Cone            = 0
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic       = false
SWEP.Primary.Ammo             = "none"
SWEP.IsAlwaysRaised = true

SWEP.Secondary.Delay        = 0.25
SWEP.Secondary.Recoil        = 0
SWEP.Secondary.Damage        = 0
SWEP.Secondary.NumShots        = 1
SWEP.Secondary.Cone            = 0
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo         = "none"
SWEP.DoorGroup = 0
SWEP.NextGo = 0

if ( CLIENT ) then
    function SWEP:PrimaryAttack()
        local client = self.Owner
        local tr = client:GetEyeTrace()
        if IsValid(tr.Entity) then
            local ent = tr.Entity
            if ent:IsDoor() or ent:IsPropDoor() then
                RunConsoleCommand("impulse_door_setgroup", self.DoorGroup)
            end
        end
    end

    function SWEP:SecondaryAttack()
        if ( input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT) ) then
            local menu = DermaMenu()
            for k,v in pairs(impulse.Config.DoorGroups) do
                menu:AddOption(v, function()
                    self.DoorGroup = k
                end)
            end
            menu:Open(ScrW() / 2, ScrH() / 2)
            return
        end

        self.DoorGroup = self.DoorGroup + 1
        if self.DoorGroup > table.Count(impulse.Config.DoorGroups) then
            self.DoorGroup = 1
        end
    end

    function SWEP:Reload()
        if self.NextGo > CurTime() then return end
        self.NextGo = CurTime() + 1
        local client = self.Owner
        local tr = client:GetEyeTrace()
        if IsValid(tr.Entity) then
            local ent = tr.Entity
            if ent:IsDoor() or ent:IsPropDoor() then
                local b = ((ent:GetRelay("doorBuyable", nil) != nil)) and 0 or 1
                RunConsoleCommand("impulse_door_sethidden",tostring(b))
            end
        end
    end
end

if ( CLIENT ) then
    local watermarkCol = Color(255, 255, 255, 120)
    function SWEP:DrawHUD()
        draw.SimpleText("LEFT: Apply group to door, RIGHT: Cycle door group, ALT + RIGHT: Select door group, RELOAD: Toggle buyable", "Impulse-Elements18-Shadow", 100, 100, watermarkCol)
        draw.SimpleText("STATE: " .. (impulse.Config.DoorGroups[self.DoorGroup] or "No group selected..."), "Impulse-Elements18-Shadow", 100, 120, watermarkCol)
    end
end
