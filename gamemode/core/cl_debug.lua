-- Get player's position and copy to clipboard
concommand.Add("impulse_debug_pos", function(ply)
    local pos = ply:GetPos()
    local output = string.format("Vector(%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z)

    chat.AddText(output)

    SetClipboardText(output)
end)

-- Get player's eye position and copy to clipboard
concommand.Add("impulse_debug_eyepos", function(ply)
    local pos = ply:EyePos()
    local output = string.format("Vector(%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z)

    chat.AddText(output)

    SetClipboardText(output)
end)

-- Get player's eye angles and copy to clipboard
concommand.Add("impulse_debug_ang", function(ply)
    local ang = ply:EyeAngles()
    local output = string.format("Angle(%.2f, %.2f, %.2f)", ang.p, ang.y, ang.r)

    chat.AddText(output)

    SetClipboardText(output)
end)

-- Get the angles of the entity player is looking at and copy to clipboard
concommand.Add("impulse_debug_ent_ang", function(ply)
    local entity = LocalPlayer():GetEyeTrace().Entity
    if ( !IsValid(entity) ) then
        return chat.AddText("You must be looking at an entity!")
    end

    local ang = entity:GetAngles()
    local output = string.format("Angle(%.2f, %.2f, %.2f)", ang.p, ang.y, ang.r)

    chat.AddText(entity)
    chat.AddText(output)

    SetClipboardText(output)
end)

-- Get the position of the entity player is looking at and copy to clipboard
concommand.Add("impulse_debug_ent_pos", function(ply)
    local entity = LocalPlayer():GetEyeTrace().Entity
    if ( !IsValid(entity) ) then
        return chat.AddText("You must be looking at an entity!")
    end

    local pos = entity:GetPos()
    local output = string.format("Vector(%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z)

    chat.AddText(entity)
    chat.AddText(output)

    SetClipboardText(output)
end)

-- Print player's velocity to console
concommand.Add("impulse_debug_velocity", function(ply)
    local velocity = ply:GetVelocity()
    local output = string.format("Velocity: Vector(%.2f, %.2f, %.2f)", velocity.x, velocity.y, velocity.z)

    chat.AddText(output)
    SetClipboardText(output)
end)

-- Get the model of the entity the player is looking at and copy to clipboard
concommand.Add("impulse_debug_ent_model", function(ply)
    local entity = LocalPlayer():GetEyeTrace().Entity
    if ( !IsValid(entity) ) then
        return chat.AddText("You must be looking at an entity!")
    end

    local model = entity:GetModel()
    chat.AddText("Entity Model: " .. model)
    
    SetClipboardText(model)
end)

-- Get bone positions of the entity player is looking at
concommand.Add("impulse_debug_ent_bones", function(ply)
    local entity = LocalPlayer():GetEyeTrace().Entity
    if ( !IsValid(entity) ) then
        return chat.AddText("You must be looking at an entity!")
    end

    chat.AddText("Bones of entity " .. tostring(entity) .. ":")
    
    for i = 0, entity:GetBoneCount() - 1 do
        local bonePos, boneAng = entity:GetBonePosition(i)
        local output = string.format("Bone %d: Position (%.2f, %.2f, %.2f) - Angle (%.2f, %.2f, %.2f)", i, bonePos.x, bonePos.y, bonePos.z, boneAng.p, boneAng.y, boneAng.r)
        chat.AddText(output)
    end
end)

-- Print player health, armor, and ammo stats
concommand.Add("impulse_debug_player_stats", function(ply)
    local entity = LocalPlayer():GetEyeTrace().Entity
    if ( !IsValid(entity) ) then
        entity = ply
    end

	local name = entity:Nick() .. " (" .. entity:SteamName() .. " / " .. entity:SteamID64() .. ")"
    local health = entity:Health()
    local armor = entity:Armor()
    local ammo = entity:GetActiveWeapon():Clip1()

    local output = string.format("Player: %s | Health: %d | Armor: %d | Ammo: %d", name, health, armor, ammo)
    
    chat.AddText(output)
    SetClipboardText(output)
end)

concommand.Add("impulse_debug_toggle_hud", function(ply)
	impulse_DevHud = !impulse_DevHud
end)

concommand.Add("impulse_debug_iconeditor", function(ply)
	if ply:IsSuperAdmin() or ply:IsDeveloper() then
		vgui.Create("impulseIconEditor")
	end
end)

concommand.Add("impulse_debug_wtl", function(ply)
	local entity = LocalPlayer():GetEyeTrace().Entity

	if not entity or not IsValid(entity) then
		return chat.AddText("You must be looking at an entity.")
	end

	if impulse_DebugTargPos then
		local pos = entity:WorldToLocal(impulse_DebugTargPos)
		local ang = entity:WorldToLocalAngles(impulse_DebugTargAng)

		chat.AddText("Base entity selected. World-To-Local output below and in console:")

		local output = "Vector("..pos.x..", "..pos.y..", "..pos.z..")"
		chat.AddText(output)

		local output = "Angle("..ang.p..", "..ang.y..", "..ang.r..")"
		chat.AddText(output)
		
		impulse_DebugTargAng = nil
		impulse_DebugTargPos = nil
		return
	end

	impulse_DebugTargPos = entity:GetPos()
	impulse_DebugTargAng = entity:GetAngles()
	chat.AddText("Target entity selected as "..tostring(entity)..". Please run the command looking at the child entity for output.")
end)

concommand.Add("impulse_debug_dump", function(ply, cmd, arg)
	if arg[1] and arg[1] == "help" then
		print("Available memory targets: (does not include sub-targets)")

		for v, k in pairs(impulse) do
			if v and istable(k) and isstring(v) then
				print(v)
			end	
		end

		return
	end
	
	if string.Trim(arg[1] or "", " ") == "" then
		return print("Please provide a memory target. (type 'impulse_debug_dump help' for a list of targets)")
	end

	local route = string.Split(arg[1], ".")
	local c

	for v, k in pairs(route) do
		c = (c or impulse)[k]

		if not c or type(c) != "table" then
			return print("Memory target invalid. (must be a path in the impulse.X data structure)")
		end
	end

	local output = c

	print("Start dump for table "..arg[1])
	PrintTable(output)
	print("End dump for table "..arg[1])
end)

local format = [[
	pos = Vector(%s, %s, %s),
	ang = Angle(%s, %s, %s),]]

concommand.Add("impulse_debug_intro", function(ply, cmd, args)
	local bEnd = args[1]
	local pos = ply:EyePos()

	local output = string.format(format, pos.x, pos.y, pos.z, ply:EyeAngles().p, ply:EyeAngles().y, ply:EyeAngles().r)
	if bEnd then
		output = string.Replace(output, "pos", "endpos")
		output = string.Replace(output, "ang", "endang")
	end

	chat.AddText(output)

	SetClipboardText(output)
end)