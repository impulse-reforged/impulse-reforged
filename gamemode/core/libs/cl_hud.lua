impulse.HUDEnabled = impulse.HUDEnabled or true

local hidden = {}
hidden["CHudHealth"] = true
hidden["CHudBattery"] = true
hidden["CHudAmmo"] = true
hidden["CHudSecondaryAmmo"] = true
hidden["CHudCrosshair"] = true
hidden["CHudHistoryResource"] = true
hidden["CHudDeathNotice"] = true
hidden["CHudDamageIndicator"] = true

function GM:HUDShouldDraw(element)
    if (hidden[element]) then return false end

    return true
end

local vignette = Material("impulse-reforged/vignette.png")
local vig_alpha_normal = Color(10,10,10,190)
local lasthealth
local time = 0
local zoneLbl
local gradient = Material("vgui/gradient-l")
local watermark = Material("impulse-reforged/impulse-white.png")
local watermarkCol = Color(255,255,255,120)
local fde = 0
local hudBlackGrad = Color(40,40,40,180)
local hudBlack = Color(20,20,20,140)
local darkCol = Color(30, 30, 30, 190)
local whiteCol = color_white
local iconsWhiteCol = Color(255, 255, 255, 220)
local bleedFlashCol = Color(230, 0, 0, 220)
local painCol = Color(255,10,10,80)
local crosshairGap = 5
local crosshairLength = crosshairGap + 5
local healthIcon = Material("impulse-reforged/icons/heart-128.png")
local healthCol = Color(210, 0, 0, 255)
local armourIcon = Material("impulse-reforged/icons/shield-128.png")
local armourCol = Color(205, 190, 0, 255)
local hungerIcon = Material("impulse-reforged/icons/bread-128.png")
local hungerCol = Color(205, 133, 63, 255)
local moneyIcon = Material("impulse-reforged/icons/banknotes-128.png")
local moneyCol = Color(133, 227, 91, 255)
local timeIcon = Material("impulse-reforged/icons/clock-128.png")
local xpIcon = Material("impulse-reforged/icons/star-128.png")
local warningIcon = Material("impulse-reforged/icons/warning-128.png")
local infoIcon = Material("impulse-reforged/icons/info-128.png")
local announcementIcon = Material("impulse-reforged/icons/megaphone-128.png")
local exitIcon = Material("impulse-reforged/icons/exit-128.png")
local bleedingIcon = Material("impulse-reforged/icons/droplet-256.png")

local lastModel = ""
local lastSkin = ""
local lastTeam = 99
local lastBodygroups = {}
local iconLoaded = false

local painFt
local painFde = 1

local bleedFlash = false
local hotPink = Color(148, 0, 211)

local function DrawPlayerInfo(target, alpha)
    local preDrawPlayerInfo = hook.Run("PreDrawPlayerInfo", target, alpha)
    if ( preDrawPlayerInfo == false ) then return end

    local pos = target:EyePos()

    pos.z = pos.z + 5
    pos = pos:ToScreen()
    pos.y = pos.y - 50

    local myGroup = LocalPlayer():GetSyncVar(SYNC_GROUP_NAME, nil)
    local group = target:GetSyncVar(SYNC_GROUP_NAME, nil)
    local rank = target:GetSyncVar(SYNC_GROUP_RANK, nil)
    local col = ColorAlpha(team.GetColor(target:Team()), alpha)

    if myGroup and !LocalPlayer():IsCP() and !target:IsCP() and group and rank and group == myGroup then
        draw.DrawText(group .. " - " .. rank, "Impulse-Elements16-Shadow", pos.x, pos.y - 15, ColorAlpha(hotPink, alpha), 1)
    end

    draw.DrawText(target:KnownName(), "Impulse-Elements18-Shadow", pos.x, pos.y, col, 1)

    if target:GetSyncVar(SYNC_TYPING, false) then
        draw.DrawText("Typing .. .", "Impulse-Elements16-Shadow", pos.x, pos.y + 15, ColorAlpha(color_white, alpha), 1)
    elseif target:GetSyncVar(SYNC_ARRESTED, false) and LocalPlayer():CanArrest(target) then
        draw.DrawText("(F2 to unrestrain | E to drag)", "Impulse-Elements16-Shadow", pos.x, pos.y + 15, ColorAlpha(color_white, alpha), 1)
    end

    hook.Run("PostDrawPlayerInfo", target, alpha)
end

local function DrawDoorInfo(target, alpha)
    local preDrawDoorInfo = hook.Run("PreDrawDoorInfo", target, alpha)
    if ( preDrawDoorInfo == false ) then return end

    local pos = target.LocalToWorld(target, target:OBBCenter()):ToScreen()
    local doorOwners = target:GetSyncVar(SYNC_DOOR_OWNERS, nil)
    local doorName = target:GetSyncVar(SYNC_DOOR_NAME, nil)
    local doorGroup =  target:GetSyncVar(SYNC_DOOR_GROUP, nil)
    local doorBuyable = target:GetSyncVar(SYNC_DOOR_BUYABLE, nil)
    local col = ColorAlpha(impulse.Config.MainColour, alpha)

    if doorName then
        draw.DrawText(doorName, "Impulse-Elements18-Shadow", pos.x, pos.y, col, 1)
    elseif doorGroup then
        draw.DrawText(impulse.Config.DoorGroups[doorGroup], "Impulse-Elements18-Shadow", pos.x, pos.y, col, 1)
    elseif doorOwners then
        local ownedBy
        if #doorOwners > 1 then
            ownedBy = "Owners:"
        else
            ownedBy = "Owner:"
        end

        for v, k in pairs(doorOwners) do
            local owner = Entity(k)

            if IsValid(owner) and owner:IsPlayer() then
                ownedBy = ownedBy .. "\n" .. owner:Name()
            end
        end
        draw.DrawText(ownedBy, "Impulse-Elements18-Shadow", pos.x, pos.y, col, 1)
    end

    if LocalPlayer():CanBuyDoor(doorOwners, doorBuyable) then
        draw.DrawText("Ownable door (F2)", "Impulse-Elements18-Shadow", pos.x, pos.y, col, 1)
    end

    hook.Run("PostDrawDoorInfo", target, alpha)
end

local function DrawEntInfo(target, alpha)
    local preDrawEntInfo = hook.Run("PreDrawEntInfo", target, alpha)
    if ( preDrawEntInfo == false ) then return end

    local pos = target.LocalToWorld(target, target:OBBCenter()):ToScreen()
    local scrW = ScrW()
    local scrH = ScrH()
    local hudName = target.HUDName
    local hudDesc = target.HUDDesc
    local hudCol = target.HUDColour or impulse.Config.InteractColour

    draw.DrawText(hudName, "Impulse-Elements19-Shadow", pos.x, pos.y, ColorAlpha(hudCol, alpha), 1)

    if hudDesc then
        draw.DrawText(hudDesc, "Impulse-Elements16-Shadow", pos.x, pos.y + 20, ColorAlpha(color_white, alpha), 1)
    end

    hook.Run("PostDrawEntInfo", target, alpha)
end

local function DrawButtonInfo(target, alpha)
    local preDrawButtonInfo = hook.Run("PreDrawButtonInfo", target, alpha)
    if ( preDrawButtonInfo == false ) then return end

    local pos = target:LocalToWorld(target:OBBCenter()):ToScreen()
    local scrW = ScrW()
    local scrH = ScrH()
    local buttonId = impulse_ActiveButtons[target:EntIndex()]
    local hudCol = impulse.Config.InteractColour
    local buttonData = impulse.Config.Buttons[buttonId]

    if ( buttonData and buttonData.desc ) then
        draw.DrawText(buttonData.desc, "Impulse-Elements18-Shadow", pos.x, pos.y + 20, ColorAlpha(hudCol, alpha), 1)
    end

    hook.Run("PostDrawButtonInfo", target, alpha)
end

local function DrawCrosshair(x, y)
    local preDrawCrosshair = hook.Run("PreDrawCrosshair", x, y)
    if ( preDrawCrosshair == false ) then return end

    surface.SetDrawColor(color_white)

    surface.DrawLine(x - crosshairLength, y, x - crosshairGap, y)
    surface.DrawLine(x + crosshairLength, y, x + crosshairGap, y)
    surface.DrawLine(x, y - crosshairLength, x, y - crosshairGap)
    surface.DrawLine(x, y + crosshairLength, x, y + crosshairGap)

    hook.Run("PostDrawCrosshair")
end

local deathEndingFade
local deathEnding
function GM:HUDPaint()
    local ply = LocalPlayer()
    local health = ply:Health()
    local plyTeam = ply:Team()
    if ( plyTeam == 0 ) then return end

    local scrW, scrH = ScrW(), ScrH()
    local hudWidth, hudHeight = 300, 178
    local x, y

    local seeColIcons = impulse.Settings:Get("hud_iconcolours")
    local aboveHUDUsed = false
    local deathSoundPlayed

    if SERVER_DOWN and CRASHSCREEN_ALLOW then
        if not IsValid(CRASH_SCREEN) then
            CRASH_SCREEN = vgui.Create("impulseCrashScreen")
        end
    elseif IsValid(CRASH_SCREEN) and !CRASH_SCREEN.fadin then
        CRASH_SCREEN.fadin = true
        CRASH_SCREEN:AlphaTo(0, 1.2, nil, function()
            if IsValid(CRASH_SCREEN) then
                CRASH_SCREEN:Remove()
            end
        end)
    end

    if not ply:Alive() and !SCENES_PLAYING then
        local ft = FrameTime()

        if not deathRegistered then
            local deathSound = hook.Run("GetDeathSound") or "impulse-reforged/death.mp3"
            surface.PlaySound(deathSound)

            deathWait = CurTime() + impulse.Config.RespawnTime
            if ply:IsDonator() then
                deathWait = CurTime() + impulse.Config.RespawnTimeDonator
            end

            deathRegistered = true
            deathEnding = true
        end

        fde = math.Clamp(fde + ft * .2, 0, 1)
        painFde = 0.7

        surface.SetDrawColor(ColorAlpha(color_black, math.ceil(fde * 255)))
        surface.DrawRect(-1, -1, ScrW() +2, ScrH() +2)

        local textCol = Color(255, 255, 255, math.ceil(fde * 255))

        draw.SimpleText("You have died", "Impulse-Elements32", scrW / 2, scrH / 2, textCol, TEXT_ALIGN_CENTER)

        local wait = math.ceil(deathWait - CurTime())

        if wait > 0 then
            draw.SimpleText("You will respawn in " .. wait .. " " .. (wait == 1 and "second" or "seconds") .. ".", "Impulse-Elements23", scrW/2, (scrH/2)+30, textCol, TEXT_ALIGN_CENTER)
            draw.SimpleText("WARNING: NLR applies, you may not return to this area until 5 minutes after your death.", "Impulse-Elements18", scrW/2, (scrH/2)+70, textCol, TEXT_ALIGN_CENTER)

            draw.SimpleText("If you feel you were unfairly killed, submit a report (F3) for assistance.", "Impulse-Elements16", scrW/2, scrH-20, textCol, TEXT_ALIGN_CENTER)
        end

        if IsValid(PlayerIcon) then
            PlayerIcon:Remove()
        end

        return
    else
        if FORCE_FADESPAWN or deathEnding then
            deathEnding = true
            FORCE_FADESPAWN = nil

            local ft = FrameTime()
            deathEndingFade = math.Clamp((deathEndingFade or 0) + ft * .15, 0, 1)

            local val = 255 - math.ceil(deathEndingFade * 255)

            if deathEndingFade != 1 then
                surface.SetDrawColor(ColorAlpha(color_black, val))
                surface.DrawRect(0, 0, ScrW(), ScrH())
            else
                deathEnding = false
                deathEndingFade = 0
            end
        end

        fde = 0

        if deathRegistered then
            deathRegistered = false
        end

        ply.Ragdoll = nil
    end

    if impulse.HUDEnabled == false or (impulse.CinematicIntro and ply:Alive()) or (IsValid(impulse.MainMenu) and impulse.MainMenu:IsVisible()) or hook.Run("ShouldDrawHUDBox") == false then
        if IsValid(PlayerIcon) then
            PlayerIcon:Remove()
        end

        return
    end

    -- Draw any HUD stuff under this comment
    if lasthealth and health < lasthealth then
        painFde = 0
    end

    painFt = FrameTime() * 2
    painFde = math.Clamp(painFde + painFt, 0, 0.7)

    surface.SetDrawColor(ColorAlpha(painCol, 255 * (0.7 - painFde)))
    surface.DrawRect(0, 0, scrW, scrH)

    --Crosshair
    local hud_crosshair = impulse.Settings:Get("hud_crosshair")
    if hud_crosshair == true then
        local curWep = ply:GetActiveWeapon()

        if not curWep or not curWep.ShouldDrawCrosshair or (curWep.ShouldDrawCrosshair and curWep.ShouldDrawCrosshair(curWep) != false) then
            if impulse.Settings:Get("view_thirdperson") == true or impulse.Settings:Get("view_firstperson_smooth_origin") == true or impulse.Settings:Get("view_firstperson_smooth_angles") == true then
                --local p = ply:GetEyeTrace().HitPos:ToScreen()
                local p = util.TraceLine({
                    start = ply:GetShootPos(),
                    endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
                    filter = ply,
                    mask = MASK_SHOT
                }).HitPos:ToScreen()
                x, y = p.x, p.y
            else
                x, y = scrW/2, scrH/2
            end

            DrawCrosshair(x, y)
        end
    end

    -- HUD

    local shouldDraw = hook.Run("ShouldDrawHUD")
    if shouldDraw != false then
        y = scrH-hudHeight-8-10
        impulse.Util:DrawBlurAt(10, y, hudWidth, hudHeight)
        surface.SetDrawColor(darkCol)
        surface.DrawRect(10, y, hudWidth, hudHeight)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(10, y, hudWidth, hudHeight)

        surface.SetFont("Impulse-Elements23")
        surface.SetTextColor(color_white)
        surface.SetDrawColor(color_white)
        surface.SetTextPos(30, y+10)
        surface.DrawText(LocalPlayer():Name())

        surface.SetTextColor(team.GetColor(plyTeam))
        surface.SetTextPos(30, y+30)
        surface.DrawText(team.GetName(plyTeam))

        local yAdd = 0

        surface.SetTextColor(color_white)
        surface.SetFont("Impulse-Elements19")

        surface.SetTextPos(136, y+64+yAdd)
        surface.DrawText("Health: " .. LocalPlayer():Health())
        if seeColIcons == true then surface.SetDrawColor(healthCol) end
        surface.SetMaterial(healthIcon)
        surface.DrawTexturedRect(110, y+66+yAdd, 18, 16)

        surface.SetTextPos(136, y+86+yAdd)
        surface.DrawText("Hunger: " .. LocalPlayer():GetSyncVar(SYNC_HUNGER, 100))
        if seeColIcons == true then surface.SetDrawColor(hungerCol) end
        surface.SetMaterial(hungerIcon)
        surface.DrawTexturedRect(110, y+87+yAdd, 18, 18)

        surface.SetTextPos(136, y+108+yAdd)
        surface.DrawText("Money: " .. impulse.Config.CurrencyPrefix .. LocalPlayer():GetSyncVar(SYNC_MONEY, 0))
        if seeColIcons == true then surface.SetDrawColor(moneyCol) end
        surface.SetMaterial(moneyIcon)
        surface.DrawTexturedRect(110, y+107+yAdd, 18, 18)

        surface.SetDrawColor(color_white)

        if ply:GetSyncVar(SYNC_ARRESTED, false) == true and impulse_JailTimeEnd and impulse_JailTimeEnd > CurTime() then
            local timeLeft = math.ceil(impulse_JailTimeEnd - CurTime())

            surface.SetMaterial(exitIcon)
            surface.DrawTexturedRect(10, y-30, 18, 18)
            draw.DrawText("Sentence remaining: " .. string.FormattedTime(timeLeft, "%02i:%02i"), "Impulse-Elements19", 35, y-30, color_white, TEXT_ALIGN_LEFT)
            aboveHUDUsed = true
        end

        draw.DrawText(ply:GetSyncVar(SYNC_XP, 0) .. "XP", "Impulse-Elements19", 55, y+150+(yAdd-8), color_white, TEXT_ALIGN_LEFT)
        surface.SetMaterial(xpIcon)
        surface.DrawTexturedRect(30, y+150+(yAdd-8), 18, 18)

        local iconsX = 315
        local bleedIconCol

        if ply:GetSyncVar(SYNC_BLEEDING, false) then
            if (nextBleedFlash or 0) < CurTime() then
                bleedFlash = !bleedFlash
                nextBleedFlash = CurTime() + 1
            end

            if bleedFlash then
                bleedIconCol = bleedFlashCol
            else
                bleedIconCol = iconsWhiteCol
            end

            surface.SetDrawColor(bleedIconCol)
            surface.SetMaterial(bleedingIcon)
            surface.DrawTexturedRect(iconsX, y + 10, 30, 30)
        end

        surface.SetDrawColor(color_white)


        local weapon = ply:GetActiveWeapon()
        if IsValid(weapon) then
            if weapon:GetMaxClip1() != -1 then
                surface.SetDrawColor(darkCol)
                surface.DrawRect(scrW-70, scrH-45, 70, 30)
                surface.SetTextPos(scrW-60, scrH-40)
                surface.DrawText(weapon:Clip1() .. "/" .. ply:GetAmmoCount(weapon:GetPrimaryAmmoType()))
            elseif weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "gmod_tool" then
                draw.DrawText("Don't have this weapon out in RP.\nYou may be punished for this.", "Impulse-Elements16", 35, y-35, color_white, TEXT_ALIGN_LEFT)
                surface.SetMaterial(warningIcon)
                surface.DrawTexturedRect(10, y-32, 18, 18)
                aboveHUDUsed = true

                surface.SetDrawColor(darkCol)
                surface.DrawRect(scrW-140, scrH-55, 140, 30)

                surface.SetFont("Impulse-Elements18-Shadow")
                surface.SetTextPos(scrW-130, scrH-50)
                surface.DrawText("Props: " .. ply:GetSyncVar(SYNC_PROPCOUNT, 0) .. "/" .. ((ply:IsDonator() and impulse.Config.PropLimitDonator) or impulse.Config.PropLimit))
            end
        end

        if not aboveHUDUsed then
            if impulse.ShowZone then
                if IsValid(zoneLbl) then
                    zoneLbl:Remove()
                end

                zoneLbl = vgui.Create("impulseZoneLabel")
                zoneLbl:SetPos(30, y - 25)
                zoneLbl.Zone = ply:GetZoneName()

                impulse.ShowZone = false
            end
        elseif zoneLbl and IsValid(zoneLbl) then
            zoneLbl:Remove()
        end

        if not IsValid(PlayerIcon) and impulse.HUDEnabled == true then
            PlayerIcon = vgui.Create("impulseSpawnIcon")
            PlayerIcon:SetPos(30, y+60)
            PlayerIcon:SetSize(64, 64)
            PlayerIcon:SetModel(LocalPlayer():GetModel(), LocalPlayer():GetSkin())

            timer.Simple(0, function()
                if not IsValid(PlayerIcon) then
                    return
                end

                local ent = PlayerIcon.Entity

                if IsValid(ent) then
                    for v, k in pairs(LocalPlayer():GetBodyGroups()) do
                        ent:SetBodygroup(k.id, LocalPlayer():GetBodygroup(k.id))
                    end
                end
            end)
        end

        local bodygroupChange = false

        if (nextBodygroupChangeCheck or 0) < CurTime() and IsValid(PlayerIcon) then
            local curBodygroups = ply:GetBodyGroups()
            local ent = PlayerIcon.Entity

            for v, k in pairs(lastBodygroups) do
                if not curBodygroups[v] or ent:GetBodygroup(k.id) != LocalPlayer():GetBodygroup(curBodygroups[v].id) then
                    bodygroupChange = true
                    break
                end
            end

            nextBodygroupChangeCheck = CurTime() + 0.5
        end

        if (ply:GetModel() != lastModel) or (ply:GetSkin() != lastSkin) or bodygroupChange == true or (iconLoaded == false and input.IsKeyDown(KEY_W)) and IsValid(PlayerIcon) then -- input is super hacking fix for SpawnIcon issue
            PlayerIcon:SetModel(ply:GetModel(), ply:GetSkin())
            lastModel = ply:GetModel()
            lastSkin = ply:GetSkin()
            lastTeam = ply:Team()
            lastBodygroups = ply:GetBodyGroups()

            iconLoaded = true
            bodygroupChange = false

            timer.Simple(0, function()
                if not IsValid(PlayerIcon) then
                    return
                end

                local ent = PlayerIcon.Entity

                if IsValid(ent) then
                    for v, k in ipairs(ply:GetBodyGroups()) do
                        ent:SetBodygroup(k.id, ply:GetBodygroup(k.id))
                    end
                end
            end)
        end
    else
        if IsValid(PlayerIcon) then
            PlayerIcon:Remove()
        end
    end

    hook.Run("impulseHUDPaint")

    if impulse.ShowZone then
        if IsValid(zoneLbl) then
            zoneLbl:Remove()
        end

        zoneLbl = vgui.Create("impulseZoneLabel")
        zoneLbl.Zone = ply:GetZoneName()
        zoneLbl.ZoneDescription = ply:GetZoneDescription()

        local x, y = 75, ScrH() - 300
        local bZoneDescription = zoneLbl.ZoneDescription and zoneLbl.ZoneDescription != ""
        if ( bZoneDescription ) then
            y = ScrH() - 320
        end

        if ( hook.Run("GetZoneLabelPos", bZoneDescription) ) then
            x, y = hook.Run("GetZoneLabelPos", bZoneDescription)
        end

        zoneLbl:SetPos(x, y)

        impulse.ShowZone = false
    end

    local isPreview = GetConVar("impulse_preview"):GetBool()

    if isPreview then
        y = ScrH() / 2
        -- watermark
        surface.SetDrawColor(watermarkCol)
        surface.SetMaterial(watermark)
        surface.DrawTexturedRect(390, y, 112, 30)

        surface.SetTextPos(390, y + 30)
        surface.SetTextColor(watermarkCol)
        surface.SetFont("Impulse-Elements18-Shadow")
        surface.DrawText("PREVIEW BUILD - VERSION: " .. impulse.Version .. " - " .. ply:SteamID64() ..  " - " ..  os.date("%H:%M:%S - %d/%m/%Y", os.time()))
        surface.SetTextPos(390, y + 50)
        surface.DrawText("SCHEMA: " .. SCHEMA_NAME .. " - VERSION: " .. impulse.Config.SchemaVersion or "?")
    end

    -- dev hud

    if impulse_DevHud and (ply:IsSuperAdmin() or ply:IsDeveloper()) then
        surface.SetTextColor(watermarkCol)

        local trace = {}
        trace.start = ply:EyePos()
        trace.endpos = trace.start + ply:GetAimVector() * 3000
        trace.filter = ply

        local traceData = util.TraceLine(trace)
        local traceEnt = traceData.Entity

        if traceEnt and traceEnt != NULL then
            surface.SetTextPos((scrW / 2) + 30, (scrH / 2) - 100)
            surface.DrawText(tostring(traceEnt))

            surface.SetTextPos((scrW / 2) + 30, (scrH / 2) - 80)
            surface.DrawText(traceEnt:GetModel() .. "     " .. traceData.HitTexture or "")

            local syncData = impulse.Sync.Data[traceEnt:EntIndex()]
            local netData
            local y = (scrH / 2) - 40

            if syncData then
                for v, k in pairs(syncData) do
                    if type(k) == "table" then
                        k = table.ToString(k)
                    end

                    surface.SetTextPos((scrW / 2) + 30, y)
                    surface.DrawText("syncvalue: " .. v .. " ; " .. tostring(k))
                    y = y + 20
                end
            end

            if IsValid(traceEnt) and traceEnt.GetNetworkVars then
                netData = traceEnt:GetNetworkVars()
            end

            if netData then
                for v, k in pairs(netData) do
                    surface.SetTextPos((scrW / 2) + 30, y)
                    surface.DrawText("netvalue: " .. v .. " ; " .. tostring(k))
                    y = y + 20
                end
            end
        end

        surface.SetTextPos(400, scrH / 1.5 - 20)
        surface.DrawText(ply:SteamName() .. " / " .. ply:Nick() .. " / " .. ply:SteamID64())

        surface.SetTextPos(400, scrH / 1.5)
        surface.DrawText(tostring(ply:GetPos()))
        surface.SetTextPos(400, (scrH / 1.5) + 20)
        surface.DrawText(tostring(ply:GetAngles()))
        surface.SetTextPos(400, (scrH / 1.5) + 40)
        surface.DrawText(ply:GetVelocity():Length2D())

        local team_current = ply:Team()
        local team_name = team.GetName(team_current)
        local team_col = team.GetColor(team_current)
        surface.SetTextPos(400, (scrH / 1.5) + 60)
        surface.SetTextColor(team_col)
        surface.DrawText("Team: " .. team_name .. " (" .. team_current .. ")")

        local class_current = ply:GetTeamClass()
        local class_name = ply:GetTeamClassName()
        surface.SetTextPos(400, (scrH / 1.5) + 80)
        surface.SetTextColor(watermarkCol)
        surface.DrawText("Class: " .. class_name .. " (" .. class_current .. ")")

        local rank_current = ply:GetTeamRank()
        local rank_name = ply:GetTeamRankName()
        surface.SetTextPos(400, (scrH / 1.5) + 100)
        surface.SetTextColor(watermarkCol)
        surface.DrawText("Rank: " .. rank_name .. " (" .. rank_current .. ")")
    end

    lasthealth = health
end

local nextOverheadCheck = 0
local lastEnt
local trace = {}
local approach = math.Approach
local letterboxFde = 0
local textFde = 0
local holdTime
overheadEntCache = {}
-- overhead info is HEAVILY based off nutscript. I'm not taking credit for it. but it saves clients like 70 fps so its worth it
function GM:HUDPaintBackground()
    if impulse.Settings:Get("hud_vignette") == true then
        hook.Run("PreDrawVignette")

        surface.SetMaterial(vignette)
        surface.SetDrawColor(vig_alpha_normal)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

        hook.Run("PostDrawVignette")
    end

    if ( impulse.HUDEnabled == false ) then return end

    local ply = LocalPlayer()
    local realTime = RealTime()
    local frameTime = FrameTime()

    local shouldDrawOverhead = hook.Run("ShouldDrawOverhead")
    if shouldDrawOverhead != false then
        if ( nextOverheadCheck < realTime ) then
            nextOverheadCheck = realTime + 0.5

            trace.start = ply.GetShootPos(ply)
            trace.endpos = trace.start + ply.GetAimVector(ply) * impulse.Config.TalkDistance
            trace.filter = ply
            trace.mins = Vector(-4, -4, -4)
            trace.maxs = Vector(4, 4, 4)
            trace.mask = MASK_SHOT_HULL

            lastEnt = util.TraceHull(trace).Entity

            if IsValid(lastEnt) then
                overheadEntCache[lastEnt] = true
            end
        end

        for entTarg, shouldDraw in pairs(overheadEntCache) do
            if IsValid(entTarg) then
                local goal = shouldDraw and 255 or 0
                local alpha = approach(entTarg.overheadAlpha or 0, goal, frameTime * 1000)

                if lastEnt != entTarg then
                    overheadEntCache[entTarg] = false
                end

                if alpha > 0 then
                    if not entTarg:GetNoDraw() then
                        hook.Run("DrawOverheadInfo", entTarg, alpha)

                        if entTarg:IsPlayer() and hook.Run("ShouldDrawPlayerInfo", entTarg) != false then
                            DrawPlayerInfo(entTarg, alpha)
                        elseif entTarg.HUDName and hook.Run("ShouldDrawEntityInfo", entTarg) != false then
                            DrawEntInfo(entTarg, alpha)
                        elseif entTarg:IsDoor() and hook.Run("ShouldDrawDoorInfo", entTarg) != false then
                            DrawDoorInfo(entTarg, alpha)
                        elseif impulse_ActiveButtons and impulse_ActiveButtons[entTarg:EntIndex()] and hook.Run("ShouldDrawButtonInfo", entTarg) != false then
                            DrawButtonInfo(entTarg, alpha)
                        else
                            hook.Run("DrawOtherOverheadInfo", entTarg, alpha)
                        end
                    end
                end

                entTarg.overheadAlpha = alpha

                if alpha == 0 and goal == 0 then
                    overheadEntCache[entTarg] = nil
                end
            else
                overheadEntCache[entTarg] = nil
            end
        end
    end

    if impulse.CinematicIntro and ply:Alive() then
        local ft = FrameTime()
        local maxTall =  ScrH() * .12

        if holdTime and holdTime + 6 < CurTime() then
            letterboxFde = math.Clamp(letterboxFde - ft / 2, 0, 1)
            textFde = math.Clamp(textFde - ft * .3, 0, 1)

            if letterboxFde == 0 then
                impulse.CinematicIntro = false
            end
        elseif holdTime and holdTime + 4 < CurTime() then
            textFde = math.Clamp(textFde - ft * .3, 0, 1)
        else
            letterboxFde = math.Clamp(letterboxFde + ft / 2, 0, 1)

            if letterboxFde == 1 then
                textFde = math.Clamp(textFde + ft * .1, 0, 1)
                holdTime = holdTime or CurTime()
            end
        end

        surface.SetDrawColor(color_black)
        surface.DrawRect(0, 0, ScrW(), (maxTall * letterboxFde))
        surface.DrawRect(0, (ScrH() - (maxTall * letterboxFde)) + 1, ScrW(), maxTall)

        draw.DrawText(impulse.CinematicTitle, "Impulse-Elements36", ScrW() - 150, ScrH() * .905, ColorAlpha(color_white, (255 * textFde)), TEXT_ALIGN_RIGHT)
    else
        letterboxFde = 0
        textFde = 0
        holdTime = nil
    end
end

concommand.Add("impulse_cameratoggle", function()
    impulse.HUDEnabled = (!impulse.HUDEnabled)

    if not IsValid(impulse.chatBox.frame) then return end

    if impulse.HUDEnabled then
        impulse.chatBox.frame:Show()
    else
        impulse.chatBox.frame:Hide()
    end
end)