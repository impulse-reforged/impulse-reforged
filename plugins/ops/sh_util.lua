if ( SERVER ) then
    util.AddNetworkString("opsGiveWarn")
    util.AddNetworkString("opsGetRecord")
end

local setHealthCommand = {
    description = "Sets health of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( !client:IsLeadAdmin() ) then
            amount = math.Clamp(amount, 1, 100)
        end


        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") health to "..amount)
            target:SetHealth(amount)
            client:Notify("You have successfully set " .. target:Nick() .. "'s health to " .. amount .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") health to " .. amount .. " | Old: " .. target:Health() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/sethp", setHealthCommand)
impulse.RegisterChatCommand("/sethealth", setHealthCommand)

local setArmorCommand = {
    description = "Sets armor of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( !client:IsLeadAdmin() ) then
            amount = math.Clamp(amount, 1, 100)
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") armor to "..amount)
            target:SetArmor(amount)
            client:Notify("You have successfully set " .. target:Nick() .. "'s armor to " .. amount .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") armor to " .. amount .. " | Old: " .. target:Armor() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setarmor", setArmorCommand)

local setHungerCommand = {
    description = "Sets hunger of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( !client:IsLeadAdmin() ) then
            amount = math.Clamp(amount, 1, 100)
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") hunger to "..amount)
            target:SetHunger(amount)
            client:Notify("You have successfully set " .. target:Nick() .. "'s hunger to " .. amount .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") hunger to " .. amount .. " | Old: " .. target:GetHunger() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/sethunger", setHungerCommand)

local setMoneyCommand = {
    description = "Sets money of the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") money to $"..amount)
            target:SetMoney(amount)
            client:Notify("You have successfully set " .. target:Nick() .. "'s money to $" .. amount .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") money to $" .. amount .. " | Old: $" .. target:GetMoney() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setmoney", setMoneyCommand)

local addMoneyCommand = {
    description = "Adds money to the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") added $"..amount.." to "..target:Name().."'s ("..target:SteamID64()..") money")
            target:AddMoney(amount)
            client:Notify("You have successfully added $" .. amount .. " to " .. target:Nick() .. "'s money.")

            local oldMoney = target:GetMoney()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has added $" .. amount .. " to " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") money | Old: $" .. oldMoney .. " | New: $" .. (oldMoney + amount) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/addmoney", addMoneyCommand)

local takeMoneyCommand = {
    description = "Takes money from the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") took $"..amount.." from "..target:Name().."'s ("..target:SteamID64()..") money")
            target:TakeMoney(amount)
            client:Notify("You have successfully taken $" .. amount .. " from " .. target:Nick() .. "'s money.")

            local oldMoney = target:GetMoney()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has taken $" .. amount .. " from " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") money | Old: $" .. oldMoney .. " | New: $" .. (oldMoney - amount) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/takemoney", takeMoneyCommand)

local setBankMoneyCommand = {
    description = "Sets bank money of the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") bank money to $"..amount)
            target:SetBankMoney(amount)
            client:Notify("You have successfully set " .. target:Nick() .. "'s bank money to $" .. amount .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") bank money to $" .. amount .. " | Old: $" .. target:GetBankMoney() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setbankmoney", setBankMoneyCommand)

local addBankMoneyCommand = {
    description = "Adds bank money to the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") added $"..amount.." to "..target:Name().."'s ("..target:SteamID64()..") bank money")
            target:AddBankMoney(amount)
            client:Notify("You have successfully added $" .. amount .. " to " .. target:Nick() .. "'s bank money.")

            local oldBankMoney = target:GetBankMoney()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has added $" .. amount .. " to " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") bank money | Old: $" .. oldBankMoney .. " | New: $" .. (oldBankMoney + amount) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/addbankmoney", addBankMoneyCommand)

local takeBankMoneyCommand = {
    description = "Takes bank money from the specified player.",
    requiresArg = true,
    superAdminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local amount = args[2]

        if ( !amount or !tonumber(amount) ) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") took $"..amount.." from "..target:Name().."'s ("..target:SteamID64()..") bank money")
            target:TakeBankMoney(amount)
            client:Notify("You have successfully taken $" .. amount .. " from " .. target:Nick() .. "'s bank money.")

            local oldBankMoney = target:GetBankMoney()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has taken $" .. amount .. " from " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") bank money | Old: $" .. oldBankMoney .. " | New: $" .. (oldBankMoney - amount) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/takebankmoney", takeBankMoneyCommand)

local fixLegsCommand = {
    description = "Fixes the legs of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])

        if ( IsValid(target) ) then
            if ( target:HasBrokenLegs() ) then
                print("[ops] "..client:Name().." ("..client:SteamID64()..") fixed "..target:Name().."'s ("..target:SteamID64()..") broken legs")
                target:FixLegs()
                client:Notify("You have successfully fixed " .. target:Nick() .. "'s legs.")

                for k, v in player.Iterator() do
                    if ( v:IsLeadAdmin() ) then
                        v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has fixed " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") broken legs | Pos: " .. tostring(target:GetPos()))
                    end
                end
            else
                client:Notify(target:Nick() .. " does not have any broken legs.")
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/fixlegs", fixLegsCommand)

local setClassCommand = {
    description = "Sets the class of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        if ( !args[2] ) then
            return client:Notify("No class was specified.")
        end

        local id, class = impulse.Teams:FindClass(args[2])

        if not class then
            return client:Notify("The specified class is invalid.")
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") class to "..class.name.." (ID: "..id..")")
            target:SetTeamClass(id)
            client:Notify("You have successfully set " .. target:Nick() .. "'s class to " .. class.name .. ".")

            local oldClassName = target:GetTeamClassName() or "None"
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") class to " .. class.name .. " | Old: " .. oldClassName .. " | Team: " .. team.GetName(target:Team()) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setclass", setClassCommand)

local setRankCommand = {
    description = "Sets the rank of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        if ( !args[2] ) then
            return client:Notify("No rank was specified.")
        end

        local id, rank = impulse.Teams:FindRank(args[2])
        if ( !rank ) then
            return client:Notify("The specified rank is invalid.")
        end

        if ( IsValid(target) ) then
            if ( target:SetTeamRank(id) ) then
                print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") rank to "..rank.name.." (ID: "..id..")")
                client:Notify("You have successfully set " .. target:Nick() .. "'s rank to " .. rank.name .. ".")

                local oldRankName = target:GetTeamRankName() or "None"
                for k, v in player.Iterator() do
                    if ( v:IsLeadAdmin() ) then
                        v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") rank to " .. rank.name .. " | Old: " .. oldRankName .. " | Team: " .. team.GetName(target:Team()) .. " | Pos: " .. tostring(target:GetPos()))
                    end
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setrank", setRankCommand)

local setSavedModelCommand = {
    description = "Sets the saved model of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newModel = args[2]
        if not newModel then
            return client:Notify("No model was specified.")
        end

        if not Model(newModel) then
            return client:Notify("The specified model is invalid.")
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") saved model to "..newModel)
            local query = mysql:Update("impulse_players")
            query:Update("model", newModel)
            query:Where("steamid", target:SteamID64())
            query:Execute()

            target.impulseDefaultModel = newModel
            target:SetModel(newModel)

            client:Notify("You have successfully set " .. target:Nick() .. "'s saved model to " .. newModel .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") saved model to " .. newModel .. " | Old: " .. (target.impulseDefaultModel or "None") .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setsavedmodel", setSavedModelCommand)

local setModelCommand = {
    description = "Sets the model of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newModel = args[2]
        if not newModel then
            return client:Notify("No model was specified.")
        end

        if not Model(newModel) then
            return client:Notify("The specified model is invalid.")
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") model to "..newModel)
            target:SetModel(newModel)

            client:Notify("You have successfully set " .. target:Nick() .. "'s model to " .. newModel .. ".")

            local oldModel = target:GetModel()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") model to " .. newModel .. " | Old: " .. oldModel .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setmodel", setModelCommand)

local setSavedSkinCommand = {
    description = "Sets the saved skin of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newSkin = args[2]
        if not newSkin then
            return client:Notify("No skin was specified.")
        end

        if not tonumber(newSkin) then
            return client:Notify("The specified skin is invalid.")
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") saved skin to "..newSkin)
            local query = mysql:Update("impulse_players")
            query:Update("skin", newSkin)
            query:Where("steamid", target:SteamID64())
            query:Execute()

            target.impulseDefaultSkin = newSkin
            target:SetSkin(newSkin)

            client:Notify("You have successfully set " .. target:Nick() .. "'s saved skin to " .. newSkin .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") saved skin to " .. newSkin .. " | Old: " .. (target.impulseDefaultSkin or "0") .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setsavedskin", setSavedSkinCommand)

local setSkinCommand = {
    description = "Sets the skin of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newSkin = args[2]
        if not newSkin then
            return client:Notify("No skin was specified.")
        end

        if not tonumber(newSkin) then
            return client:Notify("The specified skin is invalid.")
        end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") skin to "..newSkin)
            target:SetSkin(newSkin)

            client:Notify("You have successfully set " .. target:Nick() .. "'s skin to " .. newSkin .. ".")

            local oldSkin = target:GetSkin()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") skin to " .. newSkin .. " | Old: " .. oldSkin .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setskin", setSkinCommand)

local setSavedNameCommand = {
    description = "Sets the saved name of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newName = args[2]
        if not newName then
            return client:Notify("No name was specified.")
        end

        newName = table.concat(args, " ", 2)

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") saved name to "..newName)
            target:SetRPName(newName, true)

            client:Notify("You have successfully set " .. target:Nick() .. "'s saved name to " .. newName .. ".")

            local oldName = target:Name()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") saved name to \"" .. newName .. "\" | Old: \"" .. oldName .. "\" | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setsavedname", setSavedNameCommand)

local setNameCommand = {
    description = "Sets the name of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local newName = args[2]
        if not newName then
            return client:Notify("No name was specified.")
        end

        newName = table.concat(args, " ", 2)

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") name to "..newName)
            target:SetRPName(newName)

            client:Notify("You have successfully set " .. target:Nick() .. "'s name to " .. newName .. ".")

            local oldName = target:Name()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") name to \"" .. newName .. "\" | Old: \"" .. oldName .. "\" | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setname", setNameCommand)

local respawnCommand = {
    description = "Respawns the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") respawned "..target:Name().." ("..target:SteamID64()..")")
            target:Spawn()
            client:Notify("You have successfully respawned " .. target:Nick() .. ".")

            local wasAlive = target:Alive()
            local oldPos = target:GetPos()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has respawned " .. target:Nick() .. " (" .. target:SteamID64() .. ") | Was Alive: " .. tostring(wasAlive) .. " | Team: " .. team.GetName(target:Team()) .. " | Old Pos: " .. tostring(oldPos))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/respawn", respawnCommand)

local addXPCommand = {
    description = "Adds XP to the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local xp = tonumber(args[2])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") added "..xp.." XP to "..target:Name().." ("..target:SteamID64()..")")
            target:AddXP(xp)
            client:Notify("You have successfully added " .. xp .. " XP to " .. target:Nick() .. ".")

            local oldXP = target:GetXP()
            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has added " .. xp .. " XP to " .. target:Nick() .. " (" .. target:SteamID64() .. ") | Old: " .. oldXP .. " | New: " .. (oldXP + xp) .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/addxp", addXPCommand)

local setXPCommand = {
    description = "Sets XP of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local xp = tonumber(args[2])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..target:Name().."'s ("..target:SteamID64()..") XP to "..xp)
            target:SetXP(xp)
            client:Notify("You have successfully set " .. target:Nick() .. "'s XP to " .. xp .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") XP to " .. xp .. " | Old: " .. target:GetXP() .. " | Pos: " .. tostring(target:GetPos()))
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setxp", setXPCommand)

local takeXPCommand = {
    description = "Takes XP from the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local xp = tonumber(args[2])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            target:TakeXP(xp)
            client:Notify("You have successfully taken " .. xp .. " XP from " .. target:Nick() .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has taken " .. xp .. " XP from " .. target:Nick() .. " (" .. target:SteamID64() .. ").")
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/takexp", takeXPCommand)

local addSkillXPCommand = {
    description = "Adds skill XP to the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local skill = args[2]
        local xp = tonumber(args[3])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            target:AddSkillXP(skill, xp)
            client:Notify("You have successfully added " .. xp .. " XP to " .. target:Nick() .. "'s " .. skill .. " skill.")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has added " .. xp .. " XP to " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") " .. skill .. " skill.")
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/addskillxp", addSkillXPCommand)

local setSkillXPCommand = {
    description = "Sets skill XP of the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local skill = args[2]
        local xp = tonumber(args[3])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            target:SetSkillXP(skill, xp)
            client:Notify("You have successfully set " .. target:Nick() .. "'s " .. skill .. " skill XP to " .. xp .. ".")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has set " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") " .. skill .. " skill XP to " .. xp .. ".")
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/setskillxp", setSkillXPCommand)

local takeSkillXPCommand = {
    description = "Takes skill XP from the specified player.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local skill = args[2]
        local xp = tonumber(args[3])

        if not xp or not tonumber(xp) then return end

        if ( IsValid(target) ) then
            target:TakeSkillXP(skill, xp)
            client:Notify("You have successfully taken " .. xp .. " XP from " .. target:Nick() .. "'s " .. skill .. " skill.")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has taken " .. xp .. " XP from " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") " .. skill .. " skill.")
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/takeskillxp", takeSkillXPCommand)

local quizBypassCommand = {
    description = "Bypasses a quiz from a team, allowing the player to join without taking it.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local target = impulse.Util:FindPlayer(args[1])
        local data = impulse.Teams:FindTeam(args[2])

        if not data then
            return client:Notify("You have entered an incorrect team name or index.")
        end

        if ( IsValid(target) ) then
            if not data.quiz then
                return client:Notify("This team does not have a quiz.")
            end

            client:Notify("You have successfully bypassed " .. target:Nick() .. "'s " .. data.name .. " quiz.")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has bypassed " .. target:Nick() .. "'s (" .. target:SteamID64() .. ") " .. data.name .. " quiz.")
                end
            end

            local quizData = client:GetData("quiz") or {}
            quizData[data.codeName] = true

            client:SetData("quiz", quizData)
            client:SaveData()
        else
            return client:Notify("Could not find the player: " .. tostring(args[1]) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/quizbypass", quizBypassCommand)

local kickCommand = {
    description = "Kicks the specified player from the server.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, args, rawText)
        local name = args[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        local reason = ""

        for v, k in pairs(args) do
            if v != 1 then
                reason = reason .. " " .. k
            end
        end

        reason = string.Trim(reason)

        if reason == "" then reason = nil end

        if plyTarget and client != plyTarget then
            client:Notify("You have successfully kicked " .. plyTarget:Name() .. " from the server.")
            plyTarget:Kick(reason or "Kicked by a game moderator.")

            for k, v in player.Iterator() do
                if ( v:IsLeadAdmin() ) then
                    v:AddChatText(Color(135, 206, 235), "[ops] Moderator " .. client:SteamName() .. " (" .. client:SteamID64() .. ") has kicked " .. plyTarget:Nick() .. " (" .. plyTarget:SteamID64() .. ") from the server.")
                end
            end
        else
            return client:Notify("Could not find the player: " .. tostring(name) .. ".")
        end
    end
}

impulse.RegisterChatCommand("/kick", kickCommand)

if GExtension then
    local banCommand = {
        description = "Bans the specified player from the server. (time in minutes)",
        requiresArg = true,
        adminOnly = true,
        onRun = function(client, args, rawText)
            local name = args[1]
            local plyTarget = impulse.Util:FindPlayer(name)

            local time = args[2]

            if not time or not tonumber(time) then
                return client:Notify("No time value was supplied.")
            end

            time = tonumber(time)

            if time < 0 then
                return client:Notify("Negative time values are not allowed.")
            end

            local reason = ""

            for v, k in pairs(args) do
                if v > 2 then
                    reason = reason .. " " .. k
                end
            end

            reason = string.Trim(reason)

            if plyTarget and client != plyTarget then
                if client:GE_CanBan(plyTarget:SteamID64(), time) then
                    if plyTarget:IsSuperAdmin() then
                        return client:Notify("You cannot ban this user.")
                    end

                    plyTarget:GE_Ban(time, reason, client:SteamID64())
                    client:Notify("You have successfully banned " .. plyTarget:SteamName() .. " for " .. time .. " minutes.")

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
                                value = "**" .. client:SteamName() .. "** (" .. client:SteamID64() .. ")"
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
                    client:Notify("This user cannot be banned.")
                end
            else
                return client:Notify("Could not find the player: " .. tostring(name) .. ".")
            end
        end
    }

    impulse.RegisterChatCommand("/ban", banCommand)

    local warnCommand = {
        description = "Warns the specified player (reason is required).",
        requiresArg = true,
        adminOnly = true,
        onRun = function(client, args, rawText)
            local name = args[1]
            local plyTarget = impulse.Util:FindPlayer(name)
            local reason = ""

            for v, k in pairs(args) do
                if v > 1 then
                    reason = reason .. " " .. k
                end
            end

            reason = string.Trim(reason)

            if reason == "" then
                return client:Notify("No reason was provided.")
            end

            if plyTarget and client != plyTarget then
                if not client:GE_HasPermission("warnings_add") then
                    return client:Notify("You don't have permission to do this.")
                end

                GExtension:Warn(plyTarget:SteamID64(), reason, client:SteamID64())
                client:Notify("You have successfully warned " .. plyTarget:SteamName() .. " for: " .. reason .. ".")

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
                            value = "**" .. client:SteamName() .. "** (" .. client:SteamID64() .. ")"
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
                return client:Notify("Could not find the player: " .. tostring(name) .. ".")
            end
        end
    }

    impulse.RegisterChatCommand("/warn", warnCommand)
end
