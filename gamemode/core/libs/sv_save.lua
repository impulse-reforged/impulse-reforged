--- Saving mechanic in order to preserve entities between server restarts.
-- @module impulse.Save

impulse.Save = impulse.Save or {}

file.CreateDir("impulse-reforged")
file.CreateDir("impulse-reforged/saves")


local logs = impulse.Logs
function impulse.Save:Load()
    local map = string.lower(game.GetMap())
    if ( file.Exists("impulse-reforged/saves/" .. map .. ".json", "DATA") ) then
        local savedEnts = util.JSONToTable( file.Read( "impulse-reforged/saves/" ..  map ..  ".json" ) )
        for k, v in pairs(savedEnts) do
            local ent = ents.Create(v.class)
            if ( !IsValid(ent) ) then
                logs:Error("[save] Entity " .. v.class .. " does not exist! Skipping!")
                continue
            end

            ent:SetPos(v.pos)
            ent:SetAngles(v.angle)
            
            if ( v.class == "prop_physics" or v.class == "prop_dynamic" or v.class == "impulse_hl2rp_scavengable" ) then
                ent:SetModel(v.model)
                ent:SetMaterial(v.material)

                -- Load bodygroups
                v.bodygroups = v.bodygroups or {}
                for i = 0, ent:GetNumBodyGroups() - 1 do
                    if ( v.bodygroups[i] ) then
                        ent:SetBodygroup(i, v.bodygroups[i])
                    end
                end

                -- Load submaterials
                v.submaterials = v.submaterials or {}
                for i = 0, 31 do
                    if ( v.submaterials[i] ) then
                        ent:SetSubMaterial(i, v.submaterials[i])
                    end
                end
            end

            if ( v.bench ) then
                ent.Bench = v.bench
            end

            ent.impulseSaveEnt = true

            if ( v.keyvalue ) then
                ent.impulseSaveKeyValue = v.keyvalue

                if ( v.keyvalue["nopos"] ) then
                    ent.AlwaysPos = v.pos
                end
            end

            ent:Spawn()
            ent:Activate()

            local physObj = ent:GetPhysicsObject()
            if ( IsValid(physObj) ) then
                physObj:EnableMotion(false)
                physObj:Sleep()
            end
        end
    end

    hook.Run("PostLoadSaveEnts")
end

concommand.Add("impulse_save_all", function(ply, cmd, args)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local savedEnts = {}

    for k, v in ents.Iterator() do
        if ( v.impulseSaveEnt ) then
            local data = {}

            data.pos = v.AlwaysPos or v:GetPos()
            data.angle = v:GetAngles()

            data.class = v:GetClass()
            data.model = v:GetModel()
            data.material = v:GetMaterial()

            data.bodygroups = {}

            for i = 0, v:GetNumBodyGroups() - 1 do
                if ( v:GetBodygroup(i) == 0 ) then
                    continue
                end

                data.bodygroups[i] = v:GetBodygroup(i)
            end

            data.submaterials = {}

            for i = 0, 31 do
                if ( v:GetSubMaterial(i) == 0 ) then
                    continue
                end

                data.submaterials[i] = v:GetSubMaterial(i)
            end

            data.keyvalue = (v.impulseSaveKeyValue or nil)

            if ( v.Bench ) then
                data.bench = v.Bench
            end

            table.insert(savedEnts, data)
        end
    end

    file.Write("impulse-reforged/saves/" .. string.lower(game.GetMap()) .. ".json", util.TableToJSON(savedEnts, true))

    ply:AddChatText("All marked entities have been saved, and have been written to the save file.")
end, nil, "Saves all marked entities.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_reload", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    for k, v in ents.Iterator() do
        if ( v.impulseSaveEnt ) then
            SafeRemoveEntity(v)
        end
    end

    impulse.Save:Load()

    ply:AddChatText("All saved ents have been reloaded.")
end, nil, "Reloads all saved entities.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_mark", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local ent = ply:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then
        return ply:AddChatText("Invalid entity.")
    end

    ent.impulseSaveEnt = true
    ply:AddChatText("Marked " .. ent:GetClass() .. " for saving.")
end, nil, "Marks an entity for saving.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_unmark", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local ent = ply:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then
        return ply:AddChatText("Invalid entity.")
    end

    ent.impulseSaveEnt = nil
    ply:AddChatText("Removed " .. ent:GetClass() .. " for saving.")
end, nil, "Unmarks an entity for saving.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_set_keyvalue", function(ply, cmd, args)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local ent = ply:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then
        return ply:AddChatText("Invalid entity.")
    end

    local key = args[1]
    local value = args[2]
    if ( !key or !value ) then
        return ply:AddChatText("Invalid key/value pair.")
    end

    if ( ent.impulseSaveEnt ) then
        if ( tonumber(value) ) then
            value = tonumber(value)
        end

        if ( value == "nil" ) then
            value = nil
        end

        ent.impulseSaveKeyValue = ent.impulseSaveKeyValue or {}
        ent.impulseSaveKeyValue[key] = value
        ply:AddChatText("Set keyvalue " .. key .. " to " .. tostring(value) .. " on " .. ent:GetClass() .. ".")
    else
        ply:AddChatText("Entity is not marked for saving, cannot set keyvalue.")
    end
end, nil, "Sets a keyvalue on a save marked entity.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_print_keyvalues", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local ent = ply:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then
        return ply:AddChatText("Invalid entity.")
    end

    if ( ent.impulseSaveEnt ) then
        if ( !ent.impulseSaveKeyValue ) then
            return ply:AddChatText("Entity is marked for saving but has no keyvalues.")
        end

        ply:AddChatText(table.ToString(ent.impulseSaveKeyValue))
    else
        ply:AddChatText("Entity is not marked for saving.")
    end
end, nil, "Prints keyvalues of a save marked entity.", FCVAR_CLIENTCMD_CAN_EXECUTE)

local help = [[impulse Save System Help
The impulse save system is a tool to save entities between server restarts. This is useful for saving progress in a map, or saving entities that are not saved by default, such as detailed props or custom entities.

impulse_save_all - Saves all marked entities.
impulse_save_reload - Reloads all saved entities.
impulse_save_mark - Marks an entity for saving.
impulse_save_unmark - Unmarks an entity for saving.
impulse_save_set_keyvalue - Sets a keyvalue on a save marked entity.
impulse_save_print_keyvalues - Prints keyvalues of a save marked entity.
impulse_save_wipe - Wipes the save file for the current map.

If you need further help, please contact a developer.]]

concommand.Add("impulse_save_help", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    for k, v in pairs(string.Explode("\n", help)) do
        ply:AddChatText(v)
    end
    
end, nil, "Shows save system help.", FCVAR_CLIENTCMD_CAN_EXECUTE)

concommand.Add("impulse_save_wipe", function(ply)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local map = string.lower(game.GetMap())
    file.Delete("impulse-reforged/saves/" .. map .. ".json")
    ply:AddChatText("Save file for this map has been wiped.")

    for k, v in ents.Iterator() do
        if ( v.impulseSaveEnt ) then
            SafeRemoveEntity(v)
        end
    end
end)