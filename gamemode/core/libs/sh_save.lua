properties.Add("impulse_save_mark", {
    MenuLabel = "[impulse-reforged] Mark for Save",
    Order = 9999,
    MenuIcon = "icon16/arrow_up.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()

        if not self:Filter(ent, ply) then return end

        ent.impulseSaveEnt = true
        ply:AddChatText("Marked "..ent:GetClass().." for saving.")
    end
})

properties.Add("impulse_save_unmark", {
    MenuLabel = "[impulse-reforged] Unmark for Save",
    Order = 9999,
    MenuIcon = "icon16/arrow_down.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()

        if not self:Filter(ent, ply) then return end

        ent.impulseSaveEnt = nil
        ply:AddChatText("Removed "..ent:GetClass().." for saving.")
    end
})

properties.Add("impulse_save_keyvalue", {
    MenuLabel = "[impulse-reforged] Set Key/Value",
    Order = 9999,
    MenuIcon = "icon16/tag_blue_add.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        Derma_StringRequest("Set Key/Value", "Enter key/value pair for this entity.", "", function(value)
            if not value then return end

            local key, value = string.match(value, "(.-)=(.+)")

            if not key or not value then return end

            if tonumber(value) then
                value = tonumber(value)
            end

            if value == "nil" then
                value = nil
            end

            self:MsgStart()
                net.WriteEntity(ent)
                net.WriteString(key)
                net.WriteString(tostring(value))
            self:MsgEnd()
        end)
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local key = net.ReadString()
        local value = net.ReadString()

        if not self:Filter(ent, ply) then return end

        if not key or not value then
            return ply:AddChatText("Missing key/value.")
        end

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
})

properties.Add("impulse_save_printkeyvalues", {
    MenuLabel = "[impulse-reforged] Print Key/Values",
    Order = 9999,
    MenuIcon = "icon16/tag_blue.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()

        if not self:Filter(ent, ply) then return end

        if ent.impulseSaveEnt then
            if not ent.impulseSaveKeyValue then
                return ply:AddChatText("Entity has no keyvalue table.")
            end

            ply:AddChatText(table.ToString(ent.impulseSaveKeyValue))
        else
            ply:AddChatText("Entity not saving marked.")
        end
    end
})

properties.Add("impulse_save_saveall", {
    MenuLabel = "[impulse-reforged] Save All",
    Order = 9999,
    MenuIcon = "icon16/disk.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        if not ply:IsSuperAdmin() then return end

        ply:ConCommand("impulse_save_saveall")
    end
})