file.CreateDir("impulse-reforged")
file.CreateDir("impulse-reforged/saves")

function LoadSaveEnts()
	if file.Exists( "impulse-reforged/saves/"..string.lower(game.GetMap())..".dat", "DATA") then
		local savedEnts = util.JSONToTable( file.Read( "impulse-reforged/saves/" .. string.lower( game.GetMap() ) .. ".dat" ) )
		for v, k in pairs(savedEnts) do
			local x = ents.Create(k.class)

			if not IsValid(x) then
				print("[impulse-reforged] [save] Entity "..k.class.." does not exist! Skipping!")
				continue
			end

			x:SetPos(k.pos)
			x:SetAngles(k.angle)
			
			if k.class == "prop_physics" or k.class == "prop_dynamic" or k.class == "impulse_hl2rp_scavengable" then
				x:SetModel(k.model)
				x:SetMaterial(k.material)

				k.submaterials = k.submaterials or {}
				for i = 0, 31 do
					if k.submaterials[i] then
						x:SetSubMaterial(i, k.submaterials[i])
					end
				end
			end

			if k.bench then
				x.Bench = k.bench
			end

			x.impulseSaveEnt = true

			if k.keyvalue then
				x.impulseSaveKeyValue = k.keyvalue

				if k.keyvalue["nopos"] then
					x.AlwaysPos = k.pos
				end
			end

			x:Spawn()
			x:Activate()

			local phys = x:GetPhysicsObject()

			if phys and phys:IsValid() then
				phys:EnableMotion(false)
			end
		end
	end

	hook.Run("PostLoadSaveEnts")
end

concommand.Add("impulse_save_saveall", function(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end

	local savedEnts = {}

	for v, k in ents.Iterator() do
		if k.impulseSaveEnt then
			local data = {}

			data.pos = k.AlwaysPos or k:GetPos()
			data.angle = k:GetAngles()

			data.class = k:GetClass()
			data.model = k:GetModel()
			data.material = k:GetMaterial()

			data.submaterials = {}
			for i = 0, 31 do
				if k:GetSubMaterial(i) == 0 then
					continue
				end

				data.submaterials[i] = k:GetSubMaterial(i)
			end

			data.keyvalue = (k.impulseSaveKeyValue or nil)

			if k.Bench then
				data.bench = k.Bench
			end

			savedEnts[#savedEnts + 1] = data
		end
	end

	file.Write("impulse-reforged/saves/"..string.lower(game.GetMap())..".dat", util.TableToJSON(savedEnts, true))

	ply:AddChatText("All marked ents have been saved, all un-marked ents have been omitted from the save.")
end)

concommand.Add("impulse_save_reload", function(ply)
	if not ply:IsSuperAdmin() then return end
	for v, k in ents.Iterator() do
		if k.impulseSaveEnt then
			k:Remove()
		end
	end

	LoadSaveEnts()

	ply:AddChatText("All saved ents have been reloaded.")
end)

concommand.Add("impulse_save_mark", function(ply)
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity

	if IsValid(ent) then
		ent.impulseSaveEnt = true
		ply:AddChatText("Marked "..ent:GetClass().." for saving.")
	end
end)

concommand.Add("impulse_save_unmark", function(ply)
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity

	if IsValid(ent) then
		ent.impulseSaveEnt = nil
		ply:AddChatText("Removed "..ent:GetClass().." for saving.")
	end
end)

concommand.Add("impulse_save_keyvalue", function(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	local key = args[1]
	local value = args[2]

	if not key or not value then
		return ply:AddChatText("Missing key/value.")
	end

	if IsValid(ent) then
		if ent.impulseSaveEnt then
			if tonumber(value) then
				value = tonumber(value)
			end

			if value == "nil" then
				value = nil
			end

			ent.impulseSaveKeyValue = ent.impulseSaveKeyValue or {}
			ent.impulseSaveKeyValue[key] = value
			ply:AddChatText("Key/Value ("..key.."="..(value or "VALUE REMOVED")..") pair set on "..ent:GetClass()..".")
		else
			ply:AddChatText("Mark this entity for saving first.")
		end
	end
end)

concommand.Add("impulse_save_printkeyvalues", function(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity

	if IsValid(ent) then
		if ent.impulseSaveEnt then
			if not ent.impulseSaveKeyValue then
				return ply:AddChatText("Entity has no keyvalue table.")
			end

			ply:AddChatText(table.ToString(ent.impulseSaveKeyValue))
		else
			ply:AddChatText("Entity not saving marked.")
		end
	end
end)

concommand.Add("impulse_save_help", function(ply)
	if not ply:IsSuperAdmin() then return end
	
	ply:AddChatText("Mark entities you want to save with save_mark and save_unmark. Ensure all entities are in correct state/position before using save_saveall to save them. Then use save_reload to cleanup.")
end)

concommand.Add("impulse_save_wipe", function(ply)
	if not ply:IsSuperAdmin() then return end
	file.Delete("impulse-reforged/saves/"..string.lower(game.GetMap())..".dat")
	ply:AddChatText("Save file for this map has been wiped.")

	for v, k in ents.Iterator() do
		if k.impulseSaveEnt then
			k:Remove()
		end
	end
end)