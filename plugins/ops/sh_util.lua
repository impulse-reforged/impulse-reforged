if ( SERVER ) then
    util.AddNetworkString("opsGiveWarn")
    util.AddNetworkString("opsGetRecord")
end

local setHealthCommand = {
    description = "Sets health of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local hp = arg[2]

        if not hp or not tonumber(hp) then return end

        if not ply:IsLeadAdmin() then
            hp = math.Clamp(hp, 1, 100)
        end

 
        if targ and IsValid(targ) then
            targ:SetHealth(hp)
            ply:Notify("You have set " .. targ:Nick() .. "'s health to " .. hp .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") health to " .. hp .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/sethp", setHealthCommand)
impulse.RegisterChatCommand("/sethealth", setHealthCommand)

local setArmorCommand = {
    description = "Sets armor of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local hp = arg[2]

        if not hp or not tonumber(hp) then return end

        if not ply:IsLeadAdmin() then
            hp = math.Clamp(hp, 1, 100)
        end

        if targ and IsValid(targ) then
            targ:SetArmor(hp)
            ply:Notify("You have set " .. targ:Nick() .. "'s armor to " .. hp .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") armor to " .. hp .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setarmor", setArmorCommand)

local setHungerCommand = {
    description = "Sets hunger of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local hp = arg[2]

        if not hp or not tonumber(hp) then return end

        if not ply:IsLeadAdmin() then
            hp = math.Clamp(hp, 1, 100)
        end

        if targ and IsValid(targ) then
            targ:SetHunger(hp)
            ply:Notify("You have set " .. targ:Nick() .. "'s hunger to " .. hp .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") hunger to " .. hp .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/sethunger", setHungerCommand)

local fixLegsCommand = {
    description = "Fixes the legs of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])

        if targ and IsValid(targ) then
            if targ:HasBrokenLegs() then
                targ:FixLegs()
                ply:Notify("You have fixed " .. targ:Nick() .. "'s legs.")

                for k, v in player.Iterator() do
                    if v:IsLeadAdmin() then
                        v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has fixed " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") legs.")
                    end
                end
            else
                ply:Notify(targ:Nick() .. " does not have broken legs.")
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/fixlegs", fixLegsCommand)

local setClassCommand = {
    description = "Sets the class of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        if not arg[2] then
            return ply:Notify("No class specified.")
        end

        local id, class = impulse.Teams:FindClass(arg[2])

        if not class then
            return ply:Notify("Invalid class.")
        end

        if targ and IsValid(targ) then
            targ:SetTeamClass(id)
            ply:Notify("You have set " .. targ:Nick() .. "'s class to " .. class.name .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") class to " .. class.name .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setclass", setClassCommand)

local setRankCommand = {
    description = "Sets the rank of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        if not arg[2] then
            return ply:Notify("No rank specified.")
        end

        local id, rank = impulse.Teams:FindRank(arg[2])

        if not rank then
            return ply:Notify("Invalid rank.")
        end

        if targ and IsValid(targ) then
            if targ:SetTeamRank(id) then
                ply:Notify("You have set " .. targ:Nick() .. "'s rank to " .. rank.name .. ".")

                for k, v in player.Iterator() do
                    if v:IsLeadAdmin() then
                        v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") rank to " .. rank.name .. ".")
                    end
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setrank", setRankCommand)

local setSavedModelCommand = {
    description = "Sets the saved model of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newModel = arg[2]
        if not newModel then
            return ply:Notify("No model specified.")
        end

        if not Model(newModel) then
            return ply:Notify("Invalid model.")
        end

        if targ and IsValid(targ) then
            local query = mysql:Update("impulse_players")
            query:Update("model", newModel)
            query:Where("steamid", targ:SteamID64())
            query:Execute()
    
            targ.impulseDefaultModel = newModel
            targ:SetModel(newModel)

            ply:Notify("You have set " .. targ:Nick() .. "'s saved model to " .. newModel .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") saved model to " .. newModel .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setsavedmodel", setSavedModelCommand)

local setModelCommand = {
    description = "Sets the model of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newModel = arg[2]
        if not newModel then
            return ply:Notify("No model specified.")
        end

        if not Model(newModel) then
            return ply:Notify("Invalid model.")
        end

        if targ and IsValid(targ) then
            targ:SetModel(newModel)

            ply:Notify("You have set " .. targ:Nick() .. "'s model to " .. newModel .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") model to " .. newModel .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setmodel", setModelCommand)

local setSavedSkinCommand = {
    description = "Sets the saved skin of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newSkin = arg[2]
        if not newSkin then
            return ply:Notify("No skin specified.")
        end

        if not tonumber(newSkin) then
            return ply:Notify("Invalid skin.")
        end

        if targ and IsValid(targ) then
            local query = mysql:Update("impulse_players")
            query:Update("skin", newSkin)
            query:Where("steamid", targ:SteamID64())
            query:Execute()
    
            targ.impulseDefaultSkin = newSkin
            targ:SetSkin(newSkin)

            ply:Notify("You have set " .. targ:Nick() .. "'s saved skin to " .. newSkin .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") saved skin to " .. newSkin .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setsavedskin", setSavedSkinCommand)

local setSkinCommand = {
    description = "Sets the skin of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newSkin = arg[2]
        if not newSkin then
            return ply:Notify("No skin specified.")
        end

        if not tonumber(newSkin) then
            return ply:Notify("Invalid skin.")
        end

        if targ and IsValid(targ) then
            targ:SetSkin(newSkin)

            ply:Notify("You have set " .. targ:Nick() .. "'s skin to " .. newSkin .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") skin to " .. newSkin .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setskin", setSkinCommand)

local setSavedNameCommand = {
    description = "Sets the saved name of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newName = arg[2]
        if not newName then
            return ply:Notify("No name specified.")
        end

        newName = table.concat(arg, " ", 2)

        if targ and IsValid(targ) then
            targ:SetRPName(newName, true)

            ply:Notify("You have set " .. targ:Nick() .. "'s saved name to " .. newName .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") saved name to " .. newName .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setsavedname", setSavedNameCommand)

local setNameCommand = {
    description = "Sets the name of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local newName = arg[2]
        if not newName then
            return ply:Notify("No name specified.")
        end

        newName = table.concat(arg, " ", 2)

        if targ and IsValid(targ) then
            targ:SetRPName(newName)

            ply:Notify("You have set " .. targ:Nick() .. "'s name to " .. newName .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") name to " .. newName .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setname", setNameCommand)

local respawnCommand = {
    description = "Respawns the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])

        if targ and IsValid(targ) then
            targ:Spawn()
            ply:Notify("You have respawned " .. targ:Nick() .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has respawned " .. targ:Nick() .. " (" .. targ:SteamID64() .. ").")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/respawn", respawnCommand)

local addXPCommand = {
    description = "Adds XP to the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local xp = tonumber(arg[2])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:AddXP(xp)
            ply:Notify("You have added " .. xp .. " XP to " .. targ:Nick() .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has added " .. xp .. " XP to " .. targ:Nick() .. " (" .. targ:SteamID64() .. ").")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/addxp", addXPCommand)

local setXPCommand = {
    description = "Sets XP of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local xp = tonumber(arg[2])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:SetXP(xp)
            ply:Notify("You have set " .. targ:Nick() .. "'s XP to " .. xp .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") XP to " .. xp .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setxp", setXPCommand)

local takeXPCommand = {
    description = "Takes XP from the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local xp = tonumber(arg[2])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:TakeXP(xp)
            ply:Notify("You have taken " .. xp .. " XP from " .. targ:Nick() .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has taken " .. xp .. " XP from " .. targ:Nick() .. " (" .. targ:SteamID64() .. ").")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/takexp", takeXPCommand)

local addSkillXPCommand = {
    description = "Adds skill XP to the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local skill = arg[2]
        local xp = tonumber(arg[3])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:AddSkillXP(skill, xp)
            ply:Notify("You have added " .. xp .. " XP to " .. targ:Nick() .. "'s " .. skill .. " skill.")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has added " .. xp .. " XP to " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") " .. skill .. " skill.")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/addskillxp", addSkillXPCommand)

local setSkillXPCommand = {
    description = "Sets skill XP of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local skill = arg[2]
        local xp = tonumber(arg[3])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:SetSkillXP(skill, xp)
            ply:Notify("You have set " .. targ:Nick() .. "'s " .. skill .. " skill XP to " .. xp .. ".")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has set " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") " .. skill .. " skill XP to " .. xp .. ".")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/setskillxp", setSkillXPCommand)

local takeSkillXPCommand = {
    description = "Takes skill XP from the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local skill = arg[2]
        local xp = tonumber(arg[3])

        if not xp or not tonumber(xp) then return end

        if targ and IsValid(targ) then
            targ:TakeSkillXP(skill, xp)
            ply:Notify("You have taken " .. xp .. " XP from " .. targ:Nick() .. "'s " .. skill .. " skill.")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has taken " .. xp .. " XP from " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") " .. skill .. " skill.")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/takeskillxp", takeSkillXPCommand)

local quizBypassCommand = {
    description = "Bypasses a quiz from a team, allowing the player to join without taking it.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local targ = impulse.Util:FindPlayer(arg[1])
        local data = impulse.Teams:FindTeam(arg[2])

        if not data then
            return ply:Notify("You entered and incorrect team name or index.")
        end

        if targ and IsValid(targ) then
            if not data.quiz then
                return ply:Notify("This team does not have a quiz!")
            end

            ply:Notify("You have bypassed " .. targ:Nick() .. "'s " .. data.name .. " quiz.")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has bypassed " .. targ:Nick() .. "'s (" .. targ:SteamID64() .. ") " .. data.name .. " quiz.")
                end
            end

            local quizData = ply:GetData("quiz") or {}
            quizData[data.codeName] = true

            ply:SetData("quiz", quizData)
            ply:SaveData()
        else
            return ply:Notify("Could not find player: " .. tostring(arg[1]))
        end
    end
}

impulse.RegisterChatCommand("/quizbypass", quizBypassCommand)

local kickCommand = {
    description = "Kicks the specified player from the server.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local name = arg[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        local reason = ""

        for v, k in pairs(arg) do
            if v != 1 then
                reason = reason .. " " .. k
            end
        end

        reason = string.Trim(reason)

        if reason == "" then reason = nil end

        if plyTarget and ply != plyTarget then
            ply:Notify("You have kicked " .. plyTarget:Name() .. " from the server.")
            plyTarget:Kick(reason or "Kicked by a game moderator.")

            for k, v in player.Iterator() do
                if v:IsLeadAdmin() then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. ply:SteamName() .. " (" .. ply:SteamID64() .. ") has kicked " .. plyTarget:Nick() .. " (" .. plyTarget:SteamID64() .. ") from the server.")
                end
            end
        else
            return ply:Notify("Could not find player: " .. tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/kick", kickCommand)

if GExtension then
    local banCommand = {
        description = "Bans the specified player from the server. (time in minutes)",
        requiresArg = true,
        adminOnly = true,
        onRun = function(ply, arg, rawText)
            local name = arg[1]
            local plyTarget = impulse.Util:FindPlayer(name)

            local time = arg[2]

            if not time or not tonumber(time) then
                return ply:Notify("No time value supplied.")
            end

            time = tonumber(time)

            if time < 0 then
                return ply:Notify("Negative time values are not allowed.")
            end

            local reason = ""

            for v, k in pairs(arg) do
                if v > 2 then
                    reason = reason .. " " .. k
                end
            end

            reason = string.Trim(reason)

            if plyTarget and ply != plyTarget then
                if ply:GE_CanBan(plyTarget:SteamID64(), time) then
                    if plyTarget:IsSuperAdmin() then
                        return ply:Notify("You can not ban this user.")
                    end
                    
                    plyTarget:GE_Ban(time, reason, ply:SteamID64())
                    ply:Notify("You have banned " .. plyTarget:SteamName() .. " for " .. time .. " minutes.")

                    local steamid = plyTarget:SteamID64()
                    local embeds = {
                        title = "Manual ban issued",
                        description = "User was banned by a staff member.",
                        url = "https://panel.impulse-community.com/index.php?t=admin_bans&id=" .. steamid,
                        color = 8801791,
                        fields = {
                            {
                                name = "User",
                                value = "**" .. plyTarget:SteamName() .. "** (" .. steamid .. ") (" .. plyTarget:Nick() .. ")"
                            },
                            {
                                name = "Moderator",
                                value = "**" .. ply:SteamName() .. "** (" .. ply:SteamID64() .. ")"
                            },
                            {
                                name = "Reason",
                                value = reason
                            },
                            {
                                name = "Length",
                                value = string.NiceTime(time * 60) .. " (" .. time .. " minutes)"
                            }
                        }
                    }
                    
                    if reqwest then
                        if embeds then
                            embeds.timestamp = os.date("%Y-%m-%dT%H:%M:%S.000Z", os.time())
                            embeds.footer = {}
                            embeds.footer.text = "ops (GMT)"
                        end
                        reqwest({
                            method = "POST",
                            url = impulse.Config.ReqwestDiscordWebhookURL,
                            timeout = 30,
                            body = util.TableToJSON({ embeds = {embeds} }),
                            type = "application/json",
                            headers = { ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36" },
                            success = function(status, body, headers)
                                print("HTTP " .. status)
                                PrintTable(headers)
                                print(body)
                            end,
                            failed = function(err, errExt)
                                print("Error: " .. err .. " (" .. errExt .. ")")
                            end
                        })
                    else
                        opsDiscordLog(nil, embeds)
                    end
                else
                    ply:Notify("This user can not be banned.")
                end
            else
                return ply:Notify("Could not find player: " .. tostring(name))
            end
        end
    }

    impulse.RegisterChatCommand("/ban", banCommand)

    local warnCommand = {
        description = "Warns the specified player (reason is required).",
        requiresArg = true,
        adminOnly = true,
        onRun = function(ply, arg, rawText)
            local name = arg[1]
            local plyTarget = impulse.Util:FindPlayer(name)
            local reason = ""

            for v, k in pairs(arg) do
                if v > 1 then
                    reason = reason .. " " .. k
                end
            end

            reason = string.Trim(reason)

            if reason == "" then
                return ply:Notify("No reason provided.")
            end

            if plyTarget and ply != plyTarget then
                if not ply:GE_HasPermission("warnings_add") then 
                    return ply:Notify("You don't have permission do this.")
                end
                
                GExtension:Warn(plyTarget:SteamID64(), reason, ply:SteamID64())
                ply:Notify("You have warned " .. plyTarget:SteamName() .. " for " .. reason .. ".")

                net.Start("opsGiveWarn")
                net.WriteString(reason)
                net.Send(plyTarget)

                local steamid = plyTarget:SteamID64()
                local embeds = {
                    title = "Warning issued",
                    description = "User was warned by a staff member.",
                    url = "https://panel.impulse-community.com/index.php?t=admin_warnings&id=" .. steamid,
                    color = 16774400,
                    fields = {
                        {
                            name = "User",
                            value = "**" .. plyTarget:SteamName() .. "** (" .. steamid .. ") (" .. plyTarget:Nick() .. ")"
                        },
                        {
                            name = "Moderator",
                            value = "**" .. ply:SteamName() .. "** (" .. ply:SteamID64() .. ")"
                        },
                        {
                            name = "Reason",
                            value = reason
                        }
                    }
                }
                
                    if reqwest then

                        if embeds then
                            embeds.timestamp = os.date("%Y-%m-%dT%H:%M:%S.000Z", os.time())
                            embeds.footer = {}
                            embeds.footer.text = "ops (GMT)"
                        end

                        reqwest({
                            method = "POST",
                            url = impulse.Config.ReqwestDiscordWebhookURL,
                            timeout = 30,
                            body = util.TableToJSON({ embeds = {embeds} }),
                            type = "application/json",
                            headers = { ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36" },
                            success = function(status, body, headers)
                                print("HTTP " .. status)
                                PrintTable(headers)
                                print(body)
                            end,
                            failed = function(err, errExt)
                                print("Error: " .. err .. " (" .. errExt .. ")")
                            end
                        })
                    else
                        opsDiscordLog(nil, embeds)
                    end
            else
                return ply:Notify("Could not find player: " .. tostring(name))
            end
        end
    }

    impulse.RegisterChatCommand("/warn", warnCommand)
end
