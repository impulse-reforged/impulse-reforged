local logs = impulse.Logs

function GM:ForceDermaSkin()
    return "impulse"
end

function GM:OnSchemaLoaded()
    if ( !impulse.MainMenu and !IsValid(impulse.MainMenu) ) then
        impulse.SplashScreen = vgui.Create("impulseSplash")

        if ( system.IsWindows() ) then
            system.FlashWindow()
        end
    end

    local dir = "impulse-reforged/menumsgs/"
    for _, v in ipairs(file.Find(dir .. "*.json", "DATA")) do
        local f = file.Read(dir .. v, "DATA")
        local data = util.JSONToTable(f)
        if ( !data ) then
            logs:Error("Error loading menu message " .. v .. "!")
            continue
        end

        impulse.MenuMessage.Stored[data.type] = data
    end
end

-- debug fallback
if ( engine.ActiveGamemode() == "impulse-reforged" ) then
    impulse.SplashScreen = vgui.Create("impulseSplash")
end

function GM:CheckMenuInput()
    local client = LocalPlayer()
    if ( input.IsKeyDown(KEY_F1) ) then
        impulse.MainMenu = vgui.Create("impulseMainMenu")
        impulse.MainMenu:SetAlpha(0)
        impulse.MainMenu:AlphaTo(255, 0.2, 0)
        impulse.MainMenu.popup = true

        hook.Run("DisplayMenuMessages", impulse.MainMenu)
    elseif ( input.IsKeyDown(KEY_F2) and client:Alive() ) then
        local trace = {}
        trace.start = client:EyePos()
        trace.endpos = trace.start + client:GetAimVector() * 96
        trace.filter = client
        local traceEnt = util.TraceLine(trace).Entity

        if ( ( !impulse.entityMenu or !IsValid(impulse.entityMenu) ) and IsValid(traceEnt) ) then
            if ( traceEnt:IsDoor() or traceEnt:IsPropDoor() ) then
                impulse.entityMenu = vgui.Create("impulseEntityMenu")
                impulse.entityMenu:SetDoor(traceEnt)
            elseif ( traceEnt:IsPlayer() ) then
                impulse.entityMenu = vgui.Create("impulseEntityMenu")
                impulse.entityMenu:SetRangeEnt(traceEnt)
                impulse.entityMenu:SetPlayer(traceEnt)
            elseif ( traceEnt:GetClass() == "impulse_container" ) then
                impulse.entityMenu = vgui.Create("impulseEntityMenu")
                impulse.entityMenu:SetRangeEnt(traceEnt)
                impulse.entityMenu:SetContainer(traceEnt)
            elseif ( traceEnt:GetClass() == "prop_ragdoll" ) then
                impulse.entityMenu = vgui.Create("impulseEntityMenu")
                impulse.entityMenu:SetRangeEnt(traceEnt)
                impulse.entityMenu:SetBody(traceEnt)
            end
        end
    elseif ( input.IsKeyDown(KEY_F4) and !IsValid(impulse.playerMenu) and client:Alive() ) then
        impulse.playerMenu = vgui.Create("impulsePlayerMenu")
    elseif ( input.IsKeyDown(KEY_F6) and !IsValid(groupEditor) and hook.Run("CanOpenGroupEditor") != false ) then
        impulse.groupEditor = vgui.Create("impulseGroupEditor")
    end
end

local lastServerData1
local lastServerData2
local nextLoopThink = 0
local nextCrashThink = 0
local nextCrashAnalysis = 0
local crashAnalysisAttempts = 0
function GM:Think()
    if ( !lastServerData1 ) then lastServerData1 = 0 end
    if ( !lastServerData2 ) then lastServerData2 = 0 end
    if ( !nextCrashAnalysis ) then nextCrashAnalysis = 0 end

    if ( IMPULSE_SERVER_DOWN == nil ) then IMPULSE_SERVER_DOWN = false end

    local client = LocalPlayer()
    if ( client:Team() != 0 and !vgui.CursorVisible() and !impulse_ActiveWorkbar and !IsValid(impulse.MainMenu) ) then
        hook.Run("CheckMenuInput")
    end

    if ( nextLoopThink < CurTime() ) then
        for _, v in player.Iterator() do
            local isArrested = v:GetRelay("arrested", false)
            if ( isArrested != ( v.BoneArrested or false ) ) then
                v:SetHandsBehindBack(isArrested)
                v.BoneArrested = isArrested
            end
        end

        nextLoopThink = CurTime() + 0.33
    end

    if ( !IMPULSE_SERVER_DOWN and nextCrashAnalysis and nextCrashAnalysis < CurTime() ) then
        nextCrashAnalysis = CurTime() + 0.05

        local a, b = engine.ServerFrameTime()
        if ( crashAnalysisAttempts <= 15 ) then
            if ( a != lastServerData1 or b != lastServerData2 ) then
                nextCrashAnalysis = nil
                crashAnalysisAttempts = 0
                return
            end

            crashAnalysisAttempts = crashAnalysisAttempts + 1

            if ( crashAnalysisAttempts == 15 ) then
                nextCrashAnalysis = nil
                crashAnalysisAttempts = 0
                IMPULSE_SERVER_DOWN = true
            end
        else
            nextCrashAnalysis = nil
            crashAnalysisAttempts = 0
        end

        lastServerData1 = a
        lastServerData2 = b
    end

    if ( nextCrashThink < CurTime() ) then
        nextCrashThink = CurTime() + 0.66

        local a, b = engine.ServerFrameTime()
        if ( a == lastServerData1 and b == lastServerData2 ) then
            nextCrashAnalysis = CurTime()
        else
            IMPULSE_SERVER_DOWN = false
            nextCrashAnalysis = nil
        end

        lastServerData1 = a
        lastServerData2 = b
    end
end

function GM:ScoreboardShow()
    if ( LocalPlayer():Team() == 0 ) then return end -- players who have not been loaded yet

    impulse_scoreboard = vgui.Create("impulseScoreboard")
end

function GM:ScoreboardHide()
    if ( LocalPlayer():Team() == 0 ) then return end -- players who have not been loaded yet

    impulse_scoreboard:Remove()
end

impulse.Settings:Define("font_scale", {name = "Font scale", category = "Other", type = "slider", default = 1, minValue = 0.5, maxValue = 1.5, decimals = 2, onChanged = function(newValue)
    hook.Run("LoadFonts")
end})
impulse.Settings:Define("hud_vignette", {name = "Vignette enabled", category = "HUD", type = "tickbox", default = true})
impulse.Settings:Define("hud_iconcolours", {name = "Icon colours enabled", category = "HUD", type = "tickbox", default = false})
impulse.Settings:Define("hud_crosshair", {name = "Crosshair enabled", category = "HUD", type = "tickbox", default = true})
impulse.Settings:Define("view_thirdperson", {name = "Thirdperson enabled", category = "View", type = "tickbox", default = false})
impulse.Settings:Define("view_thirdperson_offset_x", {name = "Thirdperson X Offset", category = "View", type = "slider", default = 75, minValue = -50, maxValue = 50})
impulse.Settings:Define("view_thirdperson_offset_y", {name = "Thirdperson Y Offset", category = "View", type = "slider", default = 20, minValue = -50, maxValue = 50})
impulse.Settings:Define("view_thirdperson_offset_z", {name = "Thirdperson Z Offset", category = "View", type = "slider", default = 5, minValue = -50, maxValue = 50})
impulse.Settings:Define("view_thirdperson_offset_z", {name = "Thirdperson Z Offset", category = "View", type = "slider", default = 5, minValue = -50, maxValue = 50})
impulse.Settings:Define("view_thirdperson_smooth_origin", {name = "Thirdperson Smoothness for Origin", category = "View", type = "tickbox", default = false})
impulse.Settings:Define("view_thirdperson_smooth_angles", {name = "Thirdperson Smoothness for Angles", category = "View", type = "tickbox", default = false})
impulse.Settings:Define("view_firstperson_smooth_origin", {name = "Firstperson Smoothness for Origin", category = "View", type = "tickbox", default = false})
impulse.Settings:Define("view_firstperson_smooth_angles", {name = "Firstperson Smoothness for Angles", category = "View", type = "tickbox", default = false})
impulse.Settings:Define("perf_mcore", {name = "Multi-core rendering enabled", category = "Performance", type = "tickbox", default = false, onChanged = function(newValue)
    RunConsoleCommand("gmod_mcore_test", tostring(tonumber(newValue)))

    if ( newValue == 1 ) then
        RunConsoleCommand("mat_queue_mode", "-1")
        RunConsoleCommand("cl_threaded_bone_setup", "1")
    else
        RunConsoleCommand("cl_threaded_bone_setup", "0")
    end
end})
impulse.Settings:Define("perf_blur", {name = "Blur enabled", category = "Performance", type = "tickbox", default = true})
impulse.Settings:Define("perf_anim", {name = "Animations enabled", category = "Performance", type = "tickbox", default = true})
impulse.Settings:Define("inv_sortequippablesattop", {name = "Sort equipped at top", category = "Inventory", type = "tickbox", default = true})
impulse.Settings:Define("inv_sortweight", {name = "Sort by weight", category = "Inventory", type = "dropdown", default = "Inventory only", options = {"Never", "Inventory only", "Containers only", "Always"}})
impulse.Settings:Define("misc_vendorgreeting", {name = "Vendor greeting sound enabled", category = "Other", type = "tickbox", default = true})
impulse.Settings:Define("chat_oocenabled", {name = "OOC enabled", category = "Chatbox", type = "tickbox", default = true})
impulse.Settings:Define("chat_pmpings", {name = "PM and tag sound enabled", category = "Chatbox", type = "tickbox", default = true})

local loweredAngles = Angle(30, -30, -25)
function GM:CalcViewModelView(weapon, viewmodel, oldEyePos, oldEyeAng, eyePos, eyeAngles)
    if ( type(weapon) != "Weapon" ) then return end

    local vm_origin, vm_angles = eyePos, eyeAngles

    local client = LocalPlayer()
    local raiseTarg = 0

    if ( !client:IsWeaponRaised() ) then
        raiseTarg = 100
    end

    local frac = (client.raiseFraction or 0) / 100
    local rot = weapon.LowerAngles or loweredAngles

    vm_angles:RotateAroundAxis(vm_angles:Up(), rot.p * frac)
    vm_angles:RotateAroundAxis(vm_angles:Forward(), rot.y * frac)
    vm_angles:RotateAroundAxis(vm_angles:Right(), rot.r * frac)

    client.raiseFraction = Lerp(FrameTime() * 2, client.raiseFraction or 0, raiseTarg)

    local func = weapon.GetViewModelPosition
    if ( func ) then
        local pos, ang = func(weapon, eyePos * 1, eyeAngles * 1)
        vm_origin = pos or vm_origin
        vm_angles = ang or vm_angles
    end

    func = weapon.CalcViewModelView
    if ( func ) then
        local pos, ang = func(weapon, viewmodel, oldEyePos * 1, oldEyeAng * 1, eyePos * 1, eyeAngles * 1)
        vm_origin = pos or vm_origin
        vm_angles = ang or vm_angles
    end

    return vm_origin, vm_angles
end

function GM:ShouldDrawLocalPlayer()
    if ( LocalPlayer():GetRelay("falloverRagdoll", 0) ) then
        local entity = Entity(LocalPlayer():GetRelay("falloverRagdoll", 0))
        if ( IsValid(entity) ) then
            return false
        end
    end

    if ( impulse.Settings:Get("view_thirdperson") ) then
        return true
    end
end

local camera_fov = CreateConVar("impulse_camera_fov", "90", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set the camera FOV when using a view entity.")
local thirdperson_smooth_origin
local thirdperson_smooth_angles
local firstperson_smooth_origin
local firstperson_smooth_angles
function GM:CalcView(client, origin, angles, fov)
    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client and viewEntity:GetClass() != "gmod_camera" ) then
        local pos = viewEntity:GetPos()
        local ang = viewEntity:GetAngles()

        return {
            origin = pos,
            angles = ang,
            fov = camera_fov:GetFloat()
        }
    end

    local view
    if ( IsValid(impulse.SplashScreen) or ( IsValid(impulse.MainMenu) and impulse.MainMenu:IsVisible() and !impulse.MainMenu.popup ) ) then
        view = {
            origin = impulse.Config.MenuCamPos,
            angles = impulse.Config.MenuCamAng,
            fov = impulse.Config.MenuCamFOV or 75
        }

        return view
    end

    if ( LocalPlayer():GetRelay("falloverRagdoll", 0) ) then
        local entity = Entity(LocalPlayer():GetRelay("falloverRagdoll", 0))
        if ( IsValid(entity) ) then
            return
        end
    end

    local ragdoll = client.Ragdoll
    if ( IsValid(ragdoll) ) then
        local eyes = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
        if ( !eyes ) then return end

        local pos, ang = eyes.Pos, eyes.Ang

        local traceHull = util.TraceHull({
            start = ragdoll:WorldSpaceCenter(),
            endpos = pos,
            filter = ragdoll,
            mins = Vector(-10, -10, -10),
            maxs = Vector(10, 10, 10),
            mask = MASK_SHOT_HULL,
            filter = function(ent)
                if ( ent == ragdoll ) then
                    return false
                end

                return true
            end
        })

        pos = traceHull.HitPos

        view = {
            origin = pos,
            angles = ang,
            fov = 75
        }

        return view
    end

    if ( impulse.Settings:Get("view_thirdperson") and client:GetViewEntity() == client ) then
        if ( !thirdperson_smooth_origin ) then thirdperson_smooth_origin = origin end
        if ( !thirdperson_smooth_angles ) then thirdperson_smooth_angles = angles end
        if ( firstperson_smooth_origin ) then firstperson_smooth_origin = nil end
        if ( firstperson_smooth_angles ) then firstperson_smooth_angles = nil end

        local angles = client:GetAimVector():Angle()
        local targetpos = Vector(0, 0, 60)

        if ( client:KeyDown(IN_DUCK) ) then
            if ( client:GetVelocity():Length() > 0 ) then
                targetpos.z = 50
            else
                targetpos.z = 40
            end
        end

        client:SetAngles(angles)

        local pos = targetpos
        local offset = Vector(5, 5, 5)

        offset.x = impulse.Settings:Get("view_thirdperson_offset_x")
        offset.y = impulse.Settings:Get("view_thirdperson_offset_y")
        offset.z = impulse.Settings:Get("view_thirdperson_offset_z")
        angles.yaw = angles.yaw + 3

        local traceData = {}
        traceData.start = client:GetPos() + pos
        traceData.endpos = traceData.start + angles:Forward() * -offset.x

        traceData.endpos = traceData.endpos + angles:Right() * offset.y
        traceData.endpos = traceData.endpos + angles:Up() * offset.z
        traceData.mask = MASK_SHOT
        traceData.filter = function(ent)
            if ( ent == LocalPlayer() ) then
                return false
            end

            if ( ent.GetNoDraw(ent) ) then
                return false
            end

            return true
        end

        traceData = util.TraceLine(traceData)
        traceData.mask = MASK_SHOT

        pos = traceData.HitPos

        if ( traceData.Fraction < 1.0 ) then
            pos = pos + traceData.HitNormal * 5
        end

        local wep = client:GetActiveWeapon()
        if ( IsValid(wep) and wep.GetIronsights and !wep.NoThirdpersonIronsights ) then
            fov = Lerp(FrameTime() * 15, wep.FOVMultiplier, wep:GetIronsights() and wep.IronsightsFOV or 1) * fov
        end

        local delta = client:EyePos() - origin

        if ( impulse.Settings:Get("view_thirdperson_smooth_origin") ) then
            thirdperson_smooth_origin = LerpVector(FrameTime() * 10, thirdperson_smooth_origin, pos + delta)
        else
            thirdperson_smooth_origin = pos + delta
        end

        if ( impulse.Settings:Get("view_thirdperson_smooth_angles") ) then
            thirdperson_smooth_angles = LerpAngle(FrameTime() * 10, thirdperson_smooth_angles, angles)
        else
            thirdperson_smooth_angles = angles
        end

        -- if we havent done anything, dont return anything
        if ( thirdperson_smooth_origin == origin and thirdperson_smooth_angles == angles ) then
            return
        end

        return {
            origin = thirdperson_smooth_origin,
            angles = thirdperson_smooth_angles,
            fov = fov
        }
    else
        if ( thirdperson_smooth_origin ) then thirdperson_smooth_origin = nil end
        if ( thirdperson_smooth_angles ) then thirdperson_smooth_angles = nil end
        if ( !firstperson_smooth_origin ) then firstperson_smooth_origin = origin end
        if ( !firstperson_smooth_angles ) then firstperson_smooth_angles = angles end

        if ( impulse.Settings:Get("view_firstperson_smooth_origin") ) then
            firstperson_smooth_origin = LerpVector(FrameTime() * 10, firstperson_smooth_origin, origin)
        else
            firstperson_smooth_origin = origin
        end

        if ( impulse.Settings:Get("view_firstperson_smooth_angles") ) then
            firstperson_smooth_angles = LerpAngle(FrameTime() * 10, firstperson_smooth_angles, angles)
        else
            firstperson_smooth_angles = angles
        end

        -- if we havent done anything, dont return anything
        if ( firstperson_smooth_origin == origin and firstperson_smooth_angles == angles ) then
            return
        end

        return {
            origin = firstperson_smooth_origin,
            angles = firstperson_smooth_angles
        }
    end
end

local blackandwhite = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

function GM:RenderScreenspaceEffects()
    if ( impulse.HUDEnabled == false or ( IsValid(impulse.MainMenu) and impulse.MainMenu:IsVisible() ) ) then return end

    if ( LocalPlayer():Health() < 20 ) then
        DrawColorModify(blackandwhite)
    end
end

function GM:StartChat()
    net.Start("impulseChatState")
        net.WriteBool(true)
    net.SendToServer()
end

function GM:FinishChat()
    net.Start("impulseChatState")
        net.WriteBool(false)
    net.SendToServer()
end

function GM:OnContextMenuOpen()
    local client = LocalPlayer()
    if ( client:Team() == 0 or !client:Alive() or impulse_ActiveWorkbar ) then return end
    if ( client:GetRelay("arrested", false) ) then return end

    local canUse = hook.Run("CanUseInventory", client)
    if ( canUse != nil and canUse == false ) then return end

    if ( !input.IsKeyDown(KEY_LALT) ) then
        impulse_inventory = vgui.Create("impulseInventory")
        gui.EnableScreenClicker(true)
    else
        if ( IsValid(g_ContextMenu) and !g_ContextMenu:IsVisible() ) then
            g_ContextMenu:Open()
            menubar.ParentTo(g_ContextMenu)

            hook.Call("ContextMenuOpened", self)
        end
    end
end

function GM:OnContextMenuClose()
    if ( IsValid(g_ContextMenu) ) then
        g_ContextMenu:Close()
        hook.Call("ContextMenuClosed", self)
    end

    if ( IsValid(impulse_inventory) ) then
        impulse_inventory:Remove()
        gui.EnableScreenClicker(false)
    end
end

local blockedTabs = {
    ["#spawnmenu.category.saves"] = true,
    ["#spawnmenu.category.dupes"] = true,
    ["#spawnmenu.category.postprocess"] = true
}

local blockNormalTabs = {
    ["#spawnmenu.category.entities"] = true,
    ["#spawnmenu.category.npcs"] = true,
    ["#spawnmenu.category.weapons"] = true,
    ["VJ Base"] = true,
    ["ZBase"] = true
}

function GM:PostReloadToolsMenu()
    local client = LocalPlayer()
    if ( type(client) != "Player" or client:Team() == 0 ) then return end

    local spawnMenu = g_SpawnMenu
    if ( spawnMenu ) then
        local tabs = spawnMenu.CreateMenu
        local closeMe = {}

        for _, v in pairs(tabs:GetItems()) do
            if ( blockedTabs[v.Name] ) then
                table.insert(closeMe, v.Tab)
            end

            if ( client and client.IsAdmin and client.IsDonator ) then -- when u first load client doesnt exist
                if ( blockNormalTabs[v.Name] and !client:IsAdmin() ) then
                    table.insert(closeMe, v.Tab)
                end

                if ( v.Name == "#spawnmenu.category.vehicles" and !client:IsDonator() ) then
                    table.insert(closeMe, v.Tab)
                end
            end
        end

        for _, v in pairs(closeMe) do
            tabs:CloseTab(v, true)
        end
    end
end

function GM:SpawnMenuOpen()
    if ( LocalPlayer():Team() == 0 or !LocalPlayer():Alive() ) then
        return false
    else
        return true
    end
end

function GM:DisplayMenuMessages(menu)
    menu.Messages = menu.Messages or {}

    for _, v in pairs(menu.Messages) do
        v:Remove()
    end

    hook.Run("CreateMenuMessages")

    local time = os.time()

    for k, v in pairs(impulse.MenuMessage.Stored) do
        if ( v.expiry and v.expiry < time ) then
            impulse.MenuMessage:Remove(k)
            continue
        end

        menu.AddingMsgs = true

        local msg = vgui.Create("impulseMenuMessage", menu)
        local w = menu:GetWide() - 1100
        if ( w < 300 ) then
            msg:SetSize(520, 180)
            msg:SetPos(menu:GetWide() - 540, 390)
        else
            msg:SetSize(w, 120)
            msg:SetPos(520, 30)
        end

        msg:SetMessage(k)

        msg.OnClosed = function()
            impulse.MenuMessage:Remove(k)

            if ( IsValid(menu) ) then
                hook.Run("DisplayMenuMessages", menu)
            end

            surface.PlaySound("buttons/button14.wav")
        end

        table.insert(menu.Messages, msg)
        menu.AddingMsgs = false

        break
    end
end

function GM:OnAchievementAchieved() -- disable steam achievement chat messages
    return
end

function GM:PostProcessPermitted()
    return false
end

gameevent.Listen("player_spawn")
hook.Add("player_spawn", "impulsePlayerSpawn", function(data)
    local client = Player(data.userid)
    if ( client == LocalPlayer() ) then
        hook.Run("PostReloadToolsMenu")
    end
end)

concommand.Add("impulse_togglethirdperson", function() -- ease of use command for binds
    impulse.Settings:Set("view_thirdperson", !impulse.Settings:Get("view_thirdperson"))
end)
