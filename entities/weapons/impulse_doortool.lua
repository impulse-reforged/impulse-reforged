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

SWEP.Primary.Delay            = 0
SWEP.Primary.Recoil            = 0
SWEP.Primary.Damage            = 0
SWEP.Primary.NumShots        = 0
SWEP.Primary.Cone            = 0
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Ammo             = "none"
SWEP.IsAlwaysRaised = true

SWEP.Secondary.Delay        = 0
SWEP.Secondary.Recoil        = 0
SWEP.Secondary.Damage        = 0
SWEP.Secondary.NumShots        = 1
SWEP.Secondary.Cone            = 0
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic       = true
SWEP.Secondary.Ammo         = "none"

SWEP.DoorGroup = 0
SWEP.NextGo = 0

if ( CLIENT ) then
    function SWEP:PrimaryAttack()
        if ( self.NextGo > CurTime() ) then return end
        self.NextGo = CurTime() + 0.33

        local client = self:GetOwner()
        local tr = client:GetEyeTrace()
        if ( IsValid(tr.Entity) ) then
            local ent = tr.Entity
            if ( ent:IsDoor() or ent:IsPropDoor() ) then
                RunConsoleCommand("impulse_door_group_set", self.DoorGroup)
            end
        end
    end

    function SWEP:SecondaryAttack()
        if ( self.NextGo > CurTime() ) then return end
        self.NextGo = CurTime() + 0.33

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

        if ( self.DoorGroup > table.Count(impulse.Config.DoorGroups) ) then
            self.DoorGroup = 0
        end
    end

    function SWEP:Reload()
        if ( self.NextGo > CurTime() ) then return end
        self.NextGo = CurTime() + 0.33

        local client = self:GetOwner()
        local tr = client:GetEyeTrace()
        if ( IsValid(tr.Entity) ) then
            local ent = tr.Entity
            if ( ent:IsDoor() or ent:IsPropDoor() ) then
                RunConsoleCommand("impulse_door_buyable_toggle")
            end
        end
    end
end

if ( CLIENT ) then
    local watermarkCol = Color(255, 255, 255, 120)
    function SWEP:DrawHUD()
        draw.SimpleText("LEFT: Apply group to door, RIGHT: Cycle door group, ALT + RIGHT: Select door group, RELOAD: Toggle buyable", "Impulse-Elements18-Shadow", 100, 100, watermarkCol)
        draw.SimpleText("STATE: " .. (impulse.Config.DoorGroups[self.DoorGroup] or "No group selected..."), "Impulse-Elements18-Shadow", 100, 120, watermarkCol)

        for _, door in ents.Iterator() do
            if ( !door:IsDoor() ) then continue end

            local doorBuyable = door:GetRelay("doorBuyable", true)
            local doorGroup = door:GetRelay("doorGroup", 0)
            local doorGroupName = impulse.Config.DoorGroups[doorGroup] or "None"
            local doorName = door:GetRelay("doorName", nil)
            local doorOwners = door:GetRelay("doorOwners", nil)

            local color = Color(100, 255, 100)
            if ( doorGroup != 0 ) then
                color = Color(100, 200, 255)
            elseif ( !doorBuyable ) then
                color = Color(255, 100, 100)
            end

            local pos = door:LocalToWorld(door:OBBCenter()):ToScreen()
            draw.SimpleText("Door ID: " .. door:EntIndex(), "Impulse-Elements18-Shadow", pos.x, pos.y - 40, color, TEXT_ALIGN_CENTER)
            draw.SimpleText("Group: " .. doorGroupName, "Impulse-Elements18-Shadow", pos.x, pos.y - 25, color, TEXT_ALIGN_CENTER)
            draw.SimpleText("Name: " .. tostring(doorName or "None"), "Impulse-Elements18-Shadow", pos.x, pos.y - 10, color, TEXT_ALIGN_CENTER)
            draw.SimpleText("Owners: " .. tostring(doorOwners or "None"), "Impulse-Elements18-Shadow", pos.x, pos.y + 5, color, TEXT_ALIGN_CENTER)
        end
    end
end
