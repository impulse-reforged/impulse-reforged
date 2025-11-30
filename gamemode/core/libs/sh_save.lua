properties.Add("impulse_save_mark", {
    MenuLabel = "[impulse-reforged] Mark for Save",
    Order = 9999,
    MenuIcon = "icon16/arrow_up.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) ) then return false end
        if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, client)
        local ent = net.ReadEntity()

        if !self:Filter(ent, client) then return end

        ent.impulseSaveEnt = true
        client:AddChatText("Marked " .. ent:GetClass() .. " for saving.")
    end
})

properties.Add("impulse_save_unmark", {
    MenuLabel = "[impulse-reforged] Unmark for Save",
    Order = 9999,
    MenuIcon = "icon16/arrow_down.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) ) then return false end
        if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, client)
        local ent = net.ReadEntity()

        if !self:Filter(ent, client) then return end

        ent.impulseSaveEnt = nil
        client:AddChatText("Removed " .. ent:GetClass() .. " for saving.")
    end
})

properties.Add("impulse_save_keyvalue", {
    MenuLabel = "[impulse-reforged] Set Key/Value",
    Order = 9999,
    MenuIcon = "icon16/tag_blue_add.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) ) then return false end
        if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        Derma_StringRequest("Set Key/Value", "Enter key/value pair for this entity.", "", function(valueRaw)
            if !valueRaw then return end

            local key, value = string.match(valueRaw, "(.-)=(.+)")

            if !key or !value then return end

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
    Receive = function(self, length, client)
        local ent = net.ReadEntity()
        local key = net.ReadString()
        local value = net.ReadString()

        if !self:Filter(ent, client) then return end

        if !key or !value then
            return client:AddChatText("Missing key/value.")
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
            client:AddChatText("Key/Value (" .. key .. "=" .. (value or "VALUE REMOVED") .. ") pair set on " .. ent:GetClass() .. ".")
        else
            client:AddChatText("Mark this entity for saving first.")
        end
    end
})

properties.Add("impulse_save_printkeyvalues", {
    MenuLabel = "[impulse-reforged] Print Key/Values",
    Order = 9999,
    MenuIcon = "icon16/tag_blue.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) ) then return false end
        if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, client)
        local ent = net.ReadEntity()

        if !self:Filter(ent, client) then return end

        if ent.impulseSaveEnt then
            if !ent.impulseSaveKeyValue then
                return client:AddChatText("Entity has no keyvalue table.")
            end

            client:AddChatText(table.ToString(ent.impulseSaveKeyValue))
        else
            client:AddChatText("Entity not saving marked.")
        end
    end
})

properties.Add("impulse_save_all", {
    MenuLabel = "[impulse-reforged] Save All",
    Order = 9999,
    MenuIcon = "icon16/disk.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) ) then return false end
        if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
        self:MsgEnd()
    end,
    Receive = function(self, length, client)
        if !client:IsSuperAdmin() then return end

        client:ConCommand("impulse_save_all")
    end
})
