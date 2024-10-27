function GM:ForceDermaSkin()
	return "impulse"
end

function GM:OnSchemaLoaded()
	if not impulse.MainMenu and !IsValid(impulse.MainMenu) then
		impulse.SplashScreen = vgui.Create("impulseSplash")

		if system.IsWindows() then
			system.FlashWindow()
		end
	end

	local dir = "impulse-reforged/menumsgs/"
	for v, k in ipairs(file.Find(dir.."*.dat", "DATA")) do
		local f = file.Read(dir..k, "DATA")
		local data = util.JSONToTable(f)

		if not data then
			print("[impulse-reforged] Error loading menu message "..v.."!")
			continue
		end

		impulse.MenuMessage.Stored[data.type] = data
	end
end

if engine.ActiveGamemode() == "impulse-reforged" then -- debug fallback
	impulse.SplashScreen = vgui.Create("impulseSplash")
end

local lastServerData1
local lastServerData2
local nextCrashThink = 0
local nextCrashAnalysis
local crashAnalysisAttempts = 0

function GM:Think()
	if ( LocalPlayer():Team() != 0 and !vgui.CursorVisible() and !impulse_ActiveWorkbar ) then
		if ( !IsValid(impulse.MainMenu) ) then
			if ( input.IsKeyDown(KEY_F1) ) then
				impulse.MainMenu = vgui.Create("impulseMainMenu")
				impulse.MainMenu:SetAlpha(0)
				impulse.MainMenu:AlphaTo(255, 0.2, 0)
				impulse.MainMenu.popup = true

				hook.Run("DisplayMenuMessages", impulse.MainMenu)
			elseif input.IsKeyDown(KEY_F4) and !IsValid(impulse.playerMenu) and LocalPlayer():Alive() then
				impulse.playerMenu = vgui.Create("impulsePlayerMenu")
			elseif input.IsKeyDown(KEY_F2) and LocalPlayer():Alive() then
				local trace = {}
				trace.start = LocalPlayer():EyePos()
				trace.endpos = trace.start + LocalPlayer():GetAimVector() * 85
				trace.filter = LocalPlayer()

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
			elseif ( input.IsKeyDown(KEY_F6) and !IsValid(groupEditor) and hook.Run("CanOpenGroupEditor") != false ) then
				impulse.groupEditor = vgui.Create("impulseGroupEditor")
			end

			hook.Run("CheckMenuInput")
		end
	end

	if (nextLoopThink or 0) < CurTime() then
		for v, k in player.Iterator() do
			local isArrested = k:GetSyncVar(SYNC_ARRESTED, false)

			if isArrested != (k.BoneArrested or false) then
				k:SetHandsBehindBack(isArrested)
				k.BoneArrested = isArrested
			end
		end

		nextLoopThink = CurTime() + 0.5
	end

	if not SERVER_DOWN and nextCrashAnalysis and nextCrashAnalysis < CurTime() then
		nextCrashAnalysis = CurTime() + 0.05

		local a, b = engine.ServerFrameTime()

		if crashAnalysisAttempts <= 15 then
			if a != (lastServerData1 or 0) or b != (lastServerData2 or 0) then
				nextCrashAnalysis = nil
				crashAnalysisAttempts = 0
				return
			end

			crashAnalysisAttempts = crashAnalysisAttempts + 1

			if crashAnalysisAttempts == 15 then
				nextCrashAnalysis = nil
				crashAnalysisAttempts = 0
				SERVER_DOWN = true
			end
		else
			nextCrashAnalysis = nil
			crashAnalysisAttempts = 0
		end

		lastServerData1 = a
		lastServerData2 = b
	end

	if (nextCrashThink or 0) < CurTime() then
		nextCrashThink = CurTime() + 0.66

		local a, b = engine.ServerFrameTime()

		if a == (lastServerData1 or 0) and b == (lastServerData2 or 0) then
			nextCrashAnalysis = CurTime()
		else
			SERVER_DOWN = false
			nextCrashAnalysis = nil
		end

		lastServerData1 = a
		lastServerData2 = b
	end
end

function GM:ScoreboardShow()
	if LocalPlayer():Team() == 0 then return end -- players who have not been loaded yet

	impulse_scoreboard = vgui.Create("impulseScoreboard")
end

function GM:ScoreboardHide()
	if LocalPlayer():Team() == 0 then return end -- players who have not been loaded yet
	
	impulse_scoreboard:Remove()
end

function GM:DefineSettings()
	impulse.Settings:Define("font_scale", {name="Font scale", category="Other", type="slider", default=1, minValue=0.5, maxValue=1.5, decimals = 2, onChanged = function(newValue)
		hook.Run("LoadFonts")
	end})
	impulse.Settings:Define("hud_vignette", {name="Vignette enabled", category="HUD", type="tickbox", default=true})
	impulse.Settings:Define("hud_iconcolours", {name="Icon colours enabled", category="HUD", type="tickbox", default=false})
	impulse.Settings:Define("hud_crosshair", {name="Crosshair enabled", category="HUD", type="tickbox", default=true})
	impulse.Settings:Define("view_thirdperson", {name="Thirdperson enabled", category="View", type="tickbox", default=false})
	impulse.Settings:Define("view_thirdperson_fov", {name="Thirdperson FOV", category="View", type="slider", default=100, minValue=75, maxValue=120})
	impulse.Settings:Define("view_thirdperson_offset_x", {name="Thirdperson X Offset", category="View", type="slider", default=75, minValue=-50, maxValue=50})
	impulse.Settings:Define("view_thirdperson_offset_y", {name="Thirdperson Y Offset", category="View", type="slider", default=20, minValue=-50, maxValue=50})
	impulse.Settings:Define("view_thirdperson_offset_z", {name="Thirdperson Z Offset", category="View", type="slider", default=5, minValue=-50, maxValue=50})
	impulse.Settings:Define("view_thirdperson_offset_z", {name="Thirdperson Z Offset", category="View", type="slider", default=5, minValue=-50, maxValue=50})
	impulse.Settings:Define("view_thirdperson_smooth_origin", {name="Thirdperson Smoothness for Origin", category="View", type="tickbox", default=false})
	impulse.Settings:Define("view_thirdperson_smooth_angles", {name="Thirdperson Smoothness for Angles", category="View", type="tickbox", default=false})
	impulse.Settings:Define("view_firstperson_smooth_origin", {name="Firstperson Smoothness for Origin", category="View", type="tickbox", default=false})
	impulse.Settings:Define("view_firstperson_smooth_angles", {name="Firstperson Smoothness for Angles", category="View", type="tickbox", default=false})
	impulse.Settings:Define("view_firstperson_fov", {name="Firstperson FOV", category="View", type="slider", default=90, minValue=75, maxValue=120})
	impulse.Settings:Define("perf_mcore", {name="Multi-core rendering enabled", category="Performance", type="tickbox", default=false, onChanged = function(newValue)
		RunConsoleCommand("gmod_mcore_test", tostring(tonumber(newValue)))

		if newValue == 1 then
			RunConsoleCommand("mat_queue_mode", "-1")
			RunConsoleCommand("cl_threaded_bone_setup", "1")
		else
			RunConsoleCommand("cl_threaded_bone_setup", "0")
		end
	end})
	--[[
	impulse.Settings:Define("perf_dynlight", {name="Dynamic light rendering enabled", category="Performance", type="tickbox", default=true, onChanged = function(newValue)
		local v = 0
		if newValue == 1 then
			v = 1
		end

		RunConsoleCommand("r_shadows", v)
		RunConsoleCommand("r_dynamic", v)
	end})
	]]
	impulse.Settings:Define("perf_blur", {name="Blur enabled", category="Performance", type="tickbox", default=true})
	impulse.Settings:Define("perf_anim", {name="Animations enabled", category="Performance", type="tickbox", default=true})
	impulse.Settings:Define("inv_sortequippablesattop", {name="Sort equipped at top", category="Inventory", type="tickbox", default=true})
	impulse.Settings:Define("inv_sortweight", {name="Sort by weight", category="Inventory", type="dropdown", default="Inventory only", options={"Never", "Inventory only", "Containers only", "Always"}})
	impulse.Settings:Define("misc_vendorgreeting", {name="Vendor greeting sound enabled", category="Other", type="tickbox", default=true})
	impulse.Settings:Define("chat_oocenabled", {name="OOC enabled", category="Chatbox", type="tickbox", default=true})
	impulse.Settings:Define("chat_pmpings", {name="PM and tag sound enabled", category="Chatbox", type="tickbox", default=true})
end

local loweredAngles = Angle(30, -30, -25)

function GM:CalcViewModelView(weapon, viewmodel, oldEyePos, oldEyeAng, eyePos, eyeAngles)
	if not IsValid(weapon) then return end

	local vm_origin, vm_angles = eyePos, eyeAngles

	do
		local ply = LocalPlayer()
		local raiseTarg = 0

		if !ply:IsWeaponRaised() then
			raiseTarg = 100
		end

		local frac = (ply.raiseFraction or 0) / 100
		local rot = weapon.LowerAngles or loweredAngles

		vm_angles:RotateAroundAxis(vm_angles:Up(), rot.p * frac)
		vm_angles:RotateAroundAxis(vm_angles:Forward(), rot.y * frac)
		vm_angles:RotateAroundAxis(vm_angles:Right(), rot.r * frac)

		ply.raiseFraction = Lerp(FrameTime() * 2, ply.raiseFraction or 0, raiseTarg)
	end

	local func = weapon.GetViewModelPosition
	if ( func ) then
		local pos, ang = func( weapon, eyePos*1, eyeAngles*1 )
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
	end

	func = weapon.CalcViewModelView
	if ( func ) then
		local pos, ang = func( weapon, viewModel, oldEyePos*1, oldEyeAng*1, eyePos*1, eyeAngles*1 )
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
	end

	return vm_origin, vm_angles
end

function GM:ShouldDrawLocalPlayer()
	if ( SYNC_FALLOVER_RAGDOLL ) then
		local entity = Entity(LocalPlayer():GetSyncVar(SYNC_FALLOVER_RAGDOLL, 0))
		if IsValid(entity) then
			return false
		end
	end

	if impulse.Settings:Get("view_thirdperson") then
		return true
	end
end

local thirdperson_smooth_origin
local thirdperson_smooth_angles
local firstperson_smooth_origin
local firstperson_smooth_angles
function GM:CalcView(player, origin, angles, fov)
	local view

	if IsValid(impulse.SplashScreen) or (IsValid(impulse.MainMenu) and impulse.MainMenu:IsVisible() and !impulse.MainMenu.popup) then
		view = {
			origin = impulse.Config.MenuCamPos,
			angles = impulse.Config.MenuCamAng,
			fov = impulse.Config.MenuCamFOV or 70
		}

		return view
	end

	if ( SYNC_FALLOVER_RAGDOLL ) then
		local entity = Entity(LocalPlayer():GetSyncVar(SYNC_FALLOVER_RAGDOLL, 0))
		if IsValid(entity) then return end
	end
	
	local ragdoll = player.Ragdoll

	if ragdoll and IsValid(ragdoll) then
		local eyes = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
		if not eyes then return end

		local pos, ang = eyes.Pos, eyes.Ang

		local traceHull = util.TraceHull({
			start = ragdoll:WorldSpaceCenter(),
			endpos = pos,
			filter = ragdoll,
			mins = Vector(-10, -10, -10),
			maxs = Vector(10, 10, 10),
			mask = MASK_SHOT_HULL,
			filter = function(ent)
				if ent == ragdoll then
					return false
				end

				return true
			end
		})

		pos = traceHull.HitPos

		view = {
			origin = pos,
			angles = ang,
			fov = 70
		}

		return view
	end

	if impulse.Settings:Get("view_thirdperson") and player:GetViewEntity() == player then
		if not thirdperson_smooth_origin then
			thirdperson_smooth_origin = origin
		end

		if not thirdperson_smooth_angles then
			thirdperson_smooth_angles = angles
		end

		if firstperson_smooth_origin then
			firstperson_smooth_origin = nil
		end

		if firstperson_smooth_angles then
			firstperson_smooth_angles = nil
		end

		local angles = player:GetAimVector():Angle()
		local targetpos = Vector(0, 0, 60)

		if player:KeyDown(IN_DUCK) then
			if player:GetVelocity():Length() > 0 then
				targetpos.z = 50
			else
				targetpos.z = 40
			end
		end

		player:SetAngles(angles)

		local pos = targetpos

		local offset = Vector(5, 5, 5)

		offset.x = impulse.Settings:Get("view_thirdperson_offset_x")
		offset.y = impulse.Settings:Get("view_thirdperson_offset_y")
		offset.z = impulse.Settings:Get("view_thirdperson_offset_z")
		angles.yaw = angles.yaw + 3

		local t = {}

		t.start = player:GetPos() + pos
		t.endpos = t.start + angles:Forward() * -offset.x

		t.endpos = t.endpos + angles:Right() * offset.y
		t.endpos = t.endpos + angles:Up() * offset.z
		t.mask = MASK_SHOT
		t.filter = function(ent)
			if ent == LocalPlayer() then
				return false
			end
			
			if ent.GetNoDraw(ent) then
				return false
			end

			return true
		end
		
		local tr = util.TraceLine(t)
		tr.mask = MASK_SHOT

		pos = tr.HitPos

		if (tr.Fraction < 1.0) then
			pos = pos + tr.HitNormal * 5
		end

		local fov = impulse.Settings:Get("view_thirdperson_fov")
		local wep = player:GetActiveWeapon()

		if wep and IsValid(wep) and wep.GetIronsights and !wep.NoThirdpersonIronsights then
			fov = Lerp(FrameTime() * 15, wep.FOVMultiplier, wep:GetIronsights() and wep.IronsightsFOV or 1) * fov
		end

		local delta = player.EyePos(player) - origin

		if impulse.Settings:Get("view_thirdperson_smooth_origin") then
			thirdperson_smooth_origin = LerpVector(FrameTime() * 10, thirdperson_smooth_origin, pos + delta)
		else
			thirdperson_smooth_origin = pos + delta
		end
		
		if impulse.Settings:Get("view_thirdperson_smooth_angles") then
			thirdperson_smooth_angles = LerpAngle(FrameTime() * 10, thirdperson_smooth_angles, angles)
		else
			thirdperson_smooth_angles = angles
		end

		-- if we havent done anything, dont return anything
		if thirdperson_smooth_origin == origin and thirdperson_smooth_angles == angles and fov == 90 then return end

		return {
			origin = thirdperson_smooth_origin,
			angles = thirdperson_smooth_angles,
			fov = fov
		}
	else
		if thirdperson_smooth_origin then
			thirdperson_smooth_origin = nil
		end

		if thirdperson_smooth_angles then
			thirdperson_smooth_angles = nil
		end

		if not firstperson_smooth_origin then
			firstperson_smooth_origin = origin
		end

		if not firstperson_smooth_angles then
			firstperson_smooth_angles = angles
		end

		local fov = impulse.Settings:Get("view_firstperson_fov")

		if impulse.Settings:Get("view_firstperson_smooth_origin") then
			firstperson_smooth_origin = LerpVector(FrameTime() * 10, firstperson_smooth_origin, origin)
		else
			firstperson_smooth_origin = origin
		end

		if impulse.Settings:Get("view_firstperson_smooth_angles") then
			firstperson_smooth_angles = LerpAngle(FrameTime() * 10, firstperson_smooth_angles, angles)
		else
			firstperson_smooth_angles = angles
		end

		-- if we havent done anything, dont return anything
		if firstperson_smooth_origin == origin and firstperson_smooth_angles == angles and fov == 90 then return end

		return {
			origin = firstperson_smooth_origin,
			angles = firstperson_smooth_angles,
			fov = fov
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
	if impulse.HUDEnabled == false or (IsValid(impulse.MainMenu) and impulse.MainMenu:IsVisible()) then return end

	if LocalPlayer():Health() < 20 then
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
	if LocalPlayer():Team() == 0 or not LocalPlayer():Alive() or impulse_ActiveWorkbar then return end
	if LocalPlayer():GetSyncVar(SYNC_ARRESTED, false) then return end

	local canUse = hook.Run("CanUseInventory", LocalPlayer())

	if canUse != nil and canUse == false then return end

	if not input.IsKeyDown(KEY_LALT) then
		impulse_inventory = vgui.Create("impulseInventory")
		gui.EnableScreenClicker(true)
	else
		if IsValid(g_ContextMenu) and !g_ContextMenu:IsVisible() then
			g_ContextMenu:Open()
			menubar.ParentTo(g_ContextMenu)

			hook.Call("ContextMenuOpened", self)
		end
	end
end

function GM:OnContextMenuClose()
	if IsValid(g_ContextMenu) then 
		g_ContextMenu:Close()
		hook.Call("ContextMenuClosed", self)
	end

	if IsValid(impulse_inventory) then
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
	["#spawnmenu.category.weapons"] = true,
	["#spawnmenu.category.npcs"] = true
}

function GM:PostReloadToolsMenu()
	local spawnMenu = g_SpawnMenu

	if spawnMenu then
		local tabs = spawnMenu.CreateMenu
		local closeMe = {}

		for v, k in pairs(tabs:GetItems()) do
			if blockedTabs[k.Name] then
				table.insert(closeMe, k.Tab)
			end

			if LocalPlayer() and LocalPlayer().IsAdmin and LocalPlayer().IsDonator then -- when u first load ply doesnt exist
				if blockNormalTabs[k.Name] and !LocalPlayer():IsAdmin() then
					table.insert(closeMe, k.Tab)
				end

				if k.Name == "#spawnmenu.category.vehicles" and !LocalPlayer():IsDonator() then
					table.insert(closeMe, k.Tab)
				end
			end
		end

		for v, k in pairs(closeMe) do
			tabs:CloseTab(k, true)
		end
	end
end

function GM:SpawnMenuOpen()
	if LocalPlayer():Team() == 0 or not LocalPlayer():Alive() then
		return false
	else
		return true
	end
end

function GM:DisplayMenuMessages(menu)
	menu.Messages = menu.Messages or {}

	for v, k in pairs(menu.Messages) do
		k:Remove()
	end

	hook.Run("CreateMenuMessages")

	local time = os.time()

	for v, k in pairs(impulse.MenuMessage.Stored) do
		if k.expiry and k.expiry < time then
			impulse.MenuMessage:Remove(v)
			continue
		end

		menu.AddingMsgs = true
		local msg = vgui.Create("impulseMenuMessage", menu)
		local w = menu:GetWide() - 1100

		if w < 300 then
			msg:SetSize(520, 180)
			msg:SetPos(menu:GetWide() - 540, 390)
		else
			msg:SetSize(w, 120)
			msg:SetPos(520, 30)
		end

		msg:SetMessage(v)

		msg.OnClosed = function()
			impulse.MenuMessage:Remove(v)

			if IsValid(menu) then
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

concommand.Add("impulse_togglethirdperson", function() -- ease of use command for binds
	impulse.Settings:Set("view_thirdperson", (!impulse.Settings:Get("view_thirdperson")))
end)