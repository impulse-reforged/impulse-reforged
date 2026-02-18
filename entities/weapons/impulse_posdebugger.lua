AddCSLuaFile()

if ( CLIENT ) then
    SWEP.PrintName = "Position Debugger"
    SWEP.Slot = 0
    SWEP.SlotPos = 0
    SWEP.CLMode = 0
    SWEP.Author = "Riggs"
end

SWEP.HoldType = "fists"

SWEP.Category = "impulse"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

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
SWEP.IsAlwaysRaised = true

SWEP.Secondary.Delay = 0.9
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots = 1
SWEP.Secondary.Cone = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.NextGo = 0

if ( SERVER ) then
    function SWEP:Equip(owner)
        if !owner:HasPrivilege("impulse: Admin Settings") then
            owner:StripWeapon("impulse_posdebugger")
        end
    end
    function SWEP:PrimaryAttack()
    end

    function SWEP:Reload()
    end

    function SWEP:SecondaryAttack()
    end
else
    function SWEP:PrimaryAttack()
        if !self.Pos1 then
            self.Pos1 = self:GetOwner():GetEyeTrace().HitPos
            self.State = "First position registered, awaiting second position."

            surface.PlaySound("buttons/blip1.wav")
        else
            self.Pos2 = self:GetOwner():GetEyeTrace().HitPos
            self.State = "Both positions registered, ready for export."

            surface.PlaySound("buttons/blip1.wav")
            self:GetOwner():Notify("Ready for export!")
        end
    end

    function SWEP:SecondaryAttack()
        self.Pos1 = nil
        self.Pos2 = nil
        self.State = nil

        surface.PlaySound("buttons/button10.wav")
    end

    function SWEP:Reload()
        if self.Pos1 and self.Pos2 then
            local pos1 = "Vector(" .. self.Pos1.x .. ", " .. self.Pos1.y .. ", " .. self.Pos1.z .. ")"
            local pos2 = "Vector(" .. self.Pos2.x .. ", " .. self.Pos2.y .. ", " .. self.Pos2.z .. ")"
            local output = pos1 .. "\n" .. pos2

            chat.AddText("-----------------OUTPUT-----------------")
            chat.AddText(output)
            chat.AddText("Output copied to clipboard.")
            SetClipboardText(output)

            self.Pos1 = nil
            self.Pos2 = nil
            self.State = nil
        end
    end

    local watermarkCol = Color(255, 255, 255, 120)
    function SWEP:DrawHUD()
        draw.SimpleText("LEFT: Register point, RIGHT: Reset, RELOAD: Export", "Impulse-Elements18-Shadow", 100, 100, watermarkCol)
        draw.SimpleText("STATE: " .. (self.State or "Nothing selected"), "Impulse-Elements18-Shadow", 100, 120, watermarkCol)
        draw.SimpleText("Warning, when you click your current position\nwill be registered, not your weapon aim position!", "Impulse-Elements18-Shadow", 100, 140, watermarkCol)
        if ( impulse.GasZones.Config and impulse.GasZones.Config[game.GetMap()] ) then
            for name,k in pairs(impulse.GasZones.Config[game.GetMap()]) do
                local cent = (LerpVector(.5, k.pos1 or k[1], k.pos2 or k[2])):ToScreen()
                draw.SimpleText(name, "Impulse-Elements18-Shadow", cent.x, cent.y, impulse.Util:GetUniqueColour(k), TEXT_ALIGN_CENTER)
            end
        end
    end

    hook.Add("PostDrawOpaqueRenderables", "posDebugger3D", function()
        local activeWep = LocalPlayer():GetActiveWeapon()
        if activeWep and IsValid(activeWep) and activeWep:GetClass() == "impulse_posdebugger" then
            local pos1, pos2
            local col
            local cent

            if ( impulse.GasZones.Config and impulse.GasZones.Config[game.GetMap()] ) then
                for name,k in pairs(impulse.GasZones.Config[game.GetMap()]) do
                    pos1 = k.pos1 or k[1]
                    pos2 = k.pos2 or k[2]
                    col = impulse.Util:GetUniqueColour(k)

                    -- i cba to do this maths, this is from ns
                    local c1, c2, c3, c4
                    c1 = Vector(pos1[1], pos2[2], pos1[3])
                    render.DrawLine(pos1, c1, col)
                    c2 = Vector(pos2[1], pos1[2], pos1[3])
                    render.DrawLine(pos1, c2, col)
                    c3 = Vector(pos2[1], pos2[2], pos1[3])
                    render.DrawLine(c3, c1, col)
                    c4 = Vector(pos2[1], pos2[2], pos1[3])
                    render.DrawLine(c3, c2, col)

                    c1 = Vector(pos1[1], pos2[2], pos2[3])
                    render.DrawLine(pos2, c1, col)
                    c2 = Vector(pos2[1], pos1[2], pos2[3])
                    render.DrawLine(pos2, c2, col)
                    c3 = Vector(pos1[1], pos1[2], pos2[3])
                    render.DrawLine(c3, c1, col)
                    c4 = Vector(pos1[1], pos1[2], pos2[3])
                    render.DrawLine(c3, c2, col)

                    local c5, c6, c7, c8
                    c5 = Vector(pos1[1], pos2[2], pos1[3])
                    render.DrawLine(c1, c5, col)
                    c6 = Vector(pos2[1], pos1[2], pos1[3])
                    render.DrawLine(c2, c6, col)
                    c7 = Vector(pos1[1], pos1[2], pos1[3])
                    render.DrawLine(c3, c7, col)
                    c4 = Vector(pos2[1], pos2[2], pos2[3])
                    c8 = Vector(pos2[1], pos2[2], pos1[3])
                    render.DrawLine(c4, c8, col)
                end
            end

            local pos1 = activeWep.Pos1
            local pos2 = activeWep.Pos2 or LocalPlayer():GetEyeTrace().HitPos
            col = Color(255, 140, 60)

            if pos1 then
                local c1, c2, c3, c4
                c1 = Vector(pos1[1], pos2[2], pos1[3])
                render.DrawLine(pos1, c1, col)
                c2 = Vector(pos2[1], pos1[2], pos1[3])
                render.DrawLine(pos1, c2, col)
                c3 = Vector(pos2[1], pos2[2], pos1[3])
                render.DrawLine(c3, c1, col)
                c4 = Vector(pos2[1], pos2[2], pos1[3])
                render.DrawLine(c3, c2, col)

                c1 = Vector(pos1[1], pos2[2], pos2[3])
                render.DrawLine(pos2, c1, col)
                c2 = Vector(pos2[1], pos1[2], pos2[3])
                render.DrawLine(pos2, c2, col)
                c3 = Vector(pos1[1], pos1[2], pos2[3])
                render.DrawLine(c3, c1, col)
                c4 = Vector(pos1[1], pos1[2], pos2[3])
                render.DrawLine(c3, c2, col)

                local c5, c6, c7, c8
                c5 = Vector(pos1[1], pos2[2], pos1[3])
                render.DrawLine(c1, c5, col)
                c6 = Vector(pos2[1], pos1[2], pos1[3])
                render.DrawLine(c2, c6, col)
                c7 = Vector(pos1[1], pos1[2], pos1[3])
                render.DrawLine(c3, c7, col)
                c4 = Vector(pos2[1], pos2[2], pos2[3])
                c8 = Vector(pos2[1], pos2[2], pos1[3])
                render.DrawLine(c4, c8, col)
            end
        end
    end)
end
