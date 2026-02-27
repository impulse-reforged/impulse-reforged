local logs = impulse.Logs

util.AddNetworkString("impulseATMDeposit")
util.AddNetworkString("impulseATMOpen")
util.AddNetworkString("impulseATMWithdraw")
util.AddNetworkString("impulseAchievementGet")
util.AddNetworkString("impulseAchievementSync")
util.AddNetworkString("impulseBenchUse")
util.AddNetworkString("impulseBuyItem")
util.AddNetworkString("impulseChangeRPName")
util.AddNetworkString("impulseCharacterCreate")
util.AddNetworkString("impulseCharacterEdit")
util.AddNetworkString("impulseCharacterEditorOpen")
util.AddNetworkString("impulseChatMessage")
util.AddNetworkString("impulseChatState")
util.AddNetworkString("impulseChatText")
util.AddNetworkString("impulseCinematicMessage")
util.AddNetworkString("impulseClassChange")
util.AddNetworkString("impulseClearWorkbar")
util.AddNetworkString("impulseConfiscateCheck")
util.AddNetworkString("impulseDoConfiscate")
util.AddNetworkString("impulseDoorAdd")
util.AddNetworkString("impulseDoorBuy")
util.AddNetworkString("impulseDoorLock")
util.AddNetworkString("impulseDoorRemove")
util.AddNetworkString("impulseDoorSell")
util.AddNetworkString("impulseDoorUnlock")
util.AddNetworkString("impulseGetButtons")
util.AddNetworkString("impulseGetRefund")
util.AddNetworkString("impulseGroupDoCreate")
util.AddNetworkString("impulseGroupDoDelete")
util.AddNetworkString("impulseGroupDoInvite")
util.AddNetworkString("impulseGroupDoInviteAccept")
util.AddNetworkString("impulseGroupDoLeave")
util.AddNetworkString("impulseGroupDoRankAdd")
util.AddNetworkString("impulseGroupDoRankRemove")
util.AddNetworkString("impulseGroupDoRemove")
util.AddNetworkString("impulseGroupDoSetColor")
util.AddNetworkString("impulseGroupDoSetInfo")
util.AddNetworkString("impulseGroupDoSetRank")
util.AddNetworkString("impulseGroupInvite")
util.AddNetworkString("impulseGroupMember")
util.AddNetworkString("impulseGroupMemberRemove")
util.AddNetworkString("impulseGroupMetadata")
util.AddNetworkString("impulseGroupRank")
util.AddNetworkString("impulseGroupRanks")
util.AddNetworkString("impulseInvClear")
util.AddNetworkString("impulseInvClearRestricted")
util.AddNetworkString("impulseInvContainerClose")
util.AddNetworkString("impulseInvContainerCodeReply")
util.AddNetworkString("impulseInvContainerCodeTry")
util.AddNetworkString("impulseInvContainerDoMove")
util.AddNetworkString("impulseInvContainerDoSetCode")
util.AddNetworkString("impulseInvContainerOpen")
util.AddNetworkString("impulseInvContainerRemovePadlock")
util.AddNetworkString("impulseInvContainerSetCode")
util.AddNetworkString("impulseInvContainerUpdate")
util.AddNetworkString("impulseInvDoDrop")
util.AddNetworkString("impulseInvDoEquip")
util.AddNetworkString("impulseInvDoMove")
util.AddNetworkString("impulseInvDoMoveMass")
util.AddNetworkString("impulseInvDoSearch")
util.AddNetworkString("impulseInvDoSearchConfiscate")
util.AddNetworkString("impulseInvDoUse")
util.AddNetworkString("impulseInvGive")
util.AddNetworkString("impulseInvGiveSilent")
util.AddNetworkString("impulseInvMove")
util.AddNetworkString("impulseInvRemove")
util.AddNetworkString("impulseInvRequestSync")
util.AddNetworkString("impulseInvStorageOpen")
util.AddNetworkString("impulseInvUpdateData")
util.AddNetworkString("impulseInvUpdateEquip")
util.AddNetworkString("impulseInvUpdateStorage")
util.AddNetworkString("impulseJoinData")
util.AddNetworkString("impulseMakeWorkbar")
util.AddNetworkString("impulseMixDo")
util.AddNetworkString("impulseMixTry")
util.AddNetworkString("impulseNotify")
util.AddNetworkString("impulsePlayGesture")
util.AddNetworkString("impulseQuizForce")
util.AddNetworkString("impulseQuizSubmit")
util.AddNetworkString("impulseRagdollLink")
util.AddNetworkString("impulseReadNote")
util.AddNetworkString("impulseRequestWhitelists")
util.AddNetworkString("impulseScenePVS")
util.AddNetworkString("impulseSellAllDoors")
util.AddNetworkString("impulseSkillUpdate")
util.AddNetworkString("impulseSurfaceSound")
util.AddNetworkString("impulseTeamChange")
util.AddNetworkString("impulseUnRestrain")
util.AddNetworkString("impulseUpdateDefaultModelSkin")
util.AddNetworkString("impulseUpdateOOCLimit")
util.AddNetworkString("impulseVendorBuy")
util.AddNetworkString("impulseVendorSell")
util.AddNetworkString("impulseVendorUse")
util.AddNetworkString("impulseVendorUseDownload")
util.AddNetworkString("impulseViewWhitelists")
util.AddNetworkString("impulseZoneUpdate")

local AUTH_FAILURE = "Invalid argument (rejoin to continue)"

net.Receive("impulseCharacterCreate", function(len, client)
    if (client.NextCreate or 0) > CurTime() then return end
    client.NextCreate = CurTime() + 10

    local charName = net.ReadString()
    local charModel = net.ReadString()
    local charSkin = net.ReadUInt(8)

    local clientSteamID64 = client:SteamID64()
    local timestamp = math.floor(os.time())

    local canUseName, filteredName = impulse.CanUseName(charName)

    if canUseName then
        charName = filteredName
    else
        return client:Kick(AUTH_FAILURE)
    end

    if !table.HasValue(impulse.Config.DefaultMaleModels, charModel) and !table.HasValue(impulse.Config.DefaultFemaleModels, charModel) then
        return client:Kick(AUTH_FAILURE)
    end

    if ( impulse.Config.DefaultSkinBlacklist ) then
        local skinBlacklist = impulse.Config.DefaultSkinBlacklist[charModel]
        if skinBlacklist and table.HasValue(skinBlacklist, charSkin) then
            return client:Kick(AUTH_FAILURE)
        end
    end

    local query = mysql:Select("impulse_players")
    query:Where("steamid", clientSteamID64)
    query:Callback(function(result)
        -- If we already have a rp name, we can't create a new character
        if istable(result) and #result > 0 and result[1].rpname and result[1].rpname != "" then
            logs:Info(client:SteamName() .. " attempted to create a new character when they already have one.")
            client:Kick("You already have a character, stop trying to exploit.")
            return
        end

        local insertQuery = mysql:Update("impulse_players")
        insertQuery:Update("rpname", charName)
        insertQuery:Update("steamid", clientSteamID64)
        insertQuery:Update("steamname", client:SteamName())
        insertQuery:Update("group", "user")
        insertQuery:Update("xp", 0)
        insertQuery:Update("money", impulse.Config.StartingMoney)
        insertQuery:Update("bankmoney", impulse.Config.StartingBankMoney)
        insertQuery:Update("model", charModel)
        insertQuery:Update("skin", charSkin)
        insertQuery:Update("firstjoin", timestamp)
        insertQuery:Update("lastjoin", timestamp)
        insertQuery:Update("data", "[]")
        insertQuery:Update("skills", "[]")
        insertQuery:Update("rpgroup", 0)
        insertQuery:Update("rpgrouprank", "[]")
        insertQuery:Update("address", "[]")
        insertQuery:Update("playtime", 0)
        insertQuery:Where("steamid", clientSteamID64)
        insertQuery:Callback(function(result, status, lastID)
            if IsValid(client) then
                local setupData = {
                    id = lastID,
                    rpname = charName,
                    steamid = clientSteamID64,
                    steamname = client:SteamName(),
                    group = "user",
                    xp = 0,
                    money = impulse.Config.StartingMoney,
                    bankmoney = impulse.Config.StartingBankMoney,
                    model = charModel,
                    data = "[]",
                    skills = "[]",
                    skin = charSkin,
                    firstjoin = timestamp,
                    lastjoin = timestamp,
                    rpgroup = 0,
                    rpgrouprank = "[]",
                    address = "[]",
                    playtime = 0
                }

                logs:Debug(client:SteamName() .. " has created their character with the name \"" .. charName .. "\".")

                client:Freeze(false)
                client:AllowScenePVSControl(false) -- stop cutscene
                client:SaveData()

                hook.Run("PlayerSetup", client, setupData)
            end
        end)
        insertQuery:Execute()
    end)
    query:Execute()
end)

net.Receive("impulseScenePVS", function(len, client)
    if (client.nextPVSTry or 0) > CurTime() then return end
    client.nextPVSTry = CurTime() + 0.1

    if client:Team() == 0 or client.allowPVS then -- this code needs to be looked at later on, it trusts client too much, pvs locations should be stored in a shared tbl
        local pos = net.ReadVector()
        local last = client.lastPVS or 1

        if last == 1 then
            client.extraPVS = pos
            client.lastPVS = 2
        else
            client.extraPVS2 = pos
            client.lastPVS = 1
        end

        timer.Simple(1.33, function()
            if !IsValid(client) then return end

            if last == 1 then
                client.extraPVS2 = nil
            else
                client.extraPVS = nil
            end
        end)
    end
end)

net.Receive("impulseChatMessage", function(len, client) -- should implement a check on len here instead of string.len
    if (client.nextChat or 0) < CurTime() then
        if len > 15000 then
            client.nextChat = CurTime() + 0.1
            return
        end

        local text = net.ReadString()
        client.nextChat = CurTime() + 0.3 + math.Clamp(#text / 300, 0, 4)

        text = string.sub(text, 1, 1024)
        text = string.Replace(text, "\n", "")
        hook.Run("PlayerSay", client, text, false, true)
    end
end)

net.Receive("impulseATMWithdraw", function(len, client)
    if (client.nextATM or 0) > CurTime() or !client.currentATM then return end
    if !IsValid(client.currentATM) or (client:GetPos() - client.currentATM:GetPos()):LengthSqr() > (120 ^ 2) then return end

    local amount = net.ReadUInt(32)
    if !isnumber(amount) or amount < 1 or amount >= 1 / 0 or amount > 1000000000 then return end

    amount = math.floor(amount)

    if client:CanAffordBank(amount) then
        client:TakeBankMoney(amount)
        client:AddMoney(amount)
        client:Notify("You have successfully withdrawn " .. impulse.Config.CurrencyPrefix .. amount .. " from your bank account.")
    else
        client:Notify("You do not have enough money in your bank to withdraw this amount.")
    end
    client.nextATM = CurTime() + 0.1
end)

net.Receive("impulseATMDeposit", function(len, client)
    if (client.nextATM or 0) > CurTime() or !client.currentATM then return end
    if !IsValid(client.currentATM) or (client:GetPos() - client.currentATM:GetPos()):LengthSqr() > (120 ^ 2) then return end

    local amount = net.ReadUInt(32)
    if !isnumber(amount) or amount < 1 or amount >= 1 / 0 or amount > 10000000000 then return end

    amount = math.floor(amount)

    if client:CanAfford(amount) then
        client:TakeMoney(amount)
        client:AddBankMoney(amount)
        client:Notify("You have successfully deposited " .. impulse.Config.CurrencyPrefix .. amount .. " to your bank account.")
    else
        client:Notify("You do not have enough money to deposit this amount.")
    end
    client.nextATM = CurTime() + 0.1
end)

net.Receive("impulseTeamChange", function(len, client)
    if (client.lastTeamTry or 0) > CurTime() then return end
    client.lastTeamTry = CurTime() + 0.1

    local teamChangeTime = tonumber(impulse.Config.TeamChangeTime) or 15

    if client:IsDonator() or client:IsAdmin() then
        teamChangeTime = tonumber(impulse.Config.TeamChangeTimeDonator) or teamChangeTime
    end

    if client.lastTeamChange and client.lastTeamChange + teamChangeTime > CurTime() then
        client:Notify("Wait " .. math.ceil((client.lastTeamChange + teamChangeTime) - CurTime()) .. " seconds before switching team again.")
        return
    end

    local teamID = net.ReadUInt(8)
    local teamData = impulse.Teams:FindTeam(teamID)

    if teamData then
        if client:CanBecomeTeam(teamID, true) then
            if teamData.quiz then
                local data = client:GetData("quiz")

                if !data or !data[teamData.codeName] then
                    if client.nextQuiz and client.nextQuiz > CurTime() then
                        client:Notify("Wait" .. string.NiceTime(math.ceil(CurTime() - client.nextQuiz)) .. " before attempting to retry the quiz.")
                        return
                    end

                    client.quizzing = true
                    net.Start("impulseQuizForce")
                    net.WriteUInt(teamID, 8)
                    net.Send(client)
                    return
                end
            end

            client:SetTeam(teamID)
            client.lastTeamChange = CurTime()
            client:Notify("You have changed your team to " .. team.GetName(teamID) .. ".")
            client:EmitSound("items/ammo_pickup.wav")
        end
    end
end)

net.Receive("impulseClassChange",function(len, client)
    if (client.lastTeamTry or 0) > CurTime() then return end
    client.lastTeamTry = CurTime() + 0.1

    if client:GetRelay("arrested", false) then return end

    local classChangeTime = tonumber(impulse.Config.ClassChangeTime) or 15

    if client:IsAdmin() then
        classChangeTime = 5
    end

    if client.lastClassChange and client.lastClassChange + classChangeTime > CurTime() then
        client:Notify("Wait " .. math.ceil((client.lastClassChange + classChangeTime) - CurTime()) .. " seconds before switching class again.")
        return
    end

    local classID = net.ReadUInt(8)
    local classes = impulse.Teams.Stored[client:Team()].classes

    if classID and isnumber(classID) and classID > 0 and classes and classes[classID] and !classes[classID].noMenu and client:CanBecomeTeamClass(classID, true) then
        client:SetTeamClass(classID)
        client:SetTeamRank(client:GetTeamRank()) -- reapply rank to update weapons/skills
        client.lastClassChange = CurTime()
        client:Notify("You have changed your class to " .. classes[classID].name .. ".")
    end
end)

net.Receive("impulseBuyItem", function(len, client)
    if (client.nextBuy or 0) > CurTime() then return end
    client.nextBuy = CurTime() + 0.1

    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local buyableID = net.ReadUInt(8)

    local buyableName = impulse.Business.Stored[buyableID]
    local buyable = impulse.Business.Data[buyableName]

    if buyable and client:CanBuy(buyableName) and client:CanAfford(buyable.price) then
        local item = buyable.item

        if item and !client:CanHoldItem(item) then
            client:Notify("You do not have the inventory space to hold this item.")
            return
        end

        if !item then
            local count = 0

            client.BusinessSpawnCount = client.BusinessSpawnCount or {}

            for v, k in pairs(client.BusinessSpawnCount) do
                if IsValid(k) then
                    count = count + 1
                else
                    client.BusinessSpawnCount[v] = nil
                end
            end

            if count >= impulse.Config.BuyableSpawnLimit then
                client:Notify("You have reached the buyable spawn limit.")
                return
            end
        end

        client:TakeMoney(buyable.price)

        if item then
            local newItemID = client:GiveItem(item)
            if ( !newItemID ) then
                -- Failed to give item (likely unregistered/missing class); refund and inform player
                client:AddMoney(buyable.price)
                client:Notify("Something internally went wrong with your purchase, please contact a developer.")
                logs:Warning("Refunded purchase for '" .. tostring(buyableName) .. "' due to missing item class '" .. tostring(item) .. "' for player " .. tostring(client))
                return
            end
        else
            local trace = {}
            trace.start = client:EyePos()
            trace.endpos = trace.start + client:GetAimVector() * 85
            trace.filter = client

            local tr = util.TraceLine(trace)

            local ang = Angle(0, 0, 0)

            local ent = impulse.Business:SpawnBuyable(tr.HitPos, ang, buyable, client)

            table.insert(client.BusinessSpawnCount, ent)
        end

        client:Notify("You have purchased " .. buyableName .. " for " .. impulse.Config.CurrencyPrefix..buyable.price .. ".")

        hook.Run("PlayerBuyablePurchase", client, buyableName)
    else
        client:Notify("You cannot afford this purchase.")
    end
end)

net.Receive("impulseChatState", function(len, client)
    if ( ( client.impulseNextChatState or 0 ) > CurTime() ) then return end
    client.impulseNextChatState = CurTime() + 0.02

    local isTyping = net.ReadBool()
    local state = client:GetRelay("typing", false)

    if ( state != isTyping ) then
        client:SetRelay("typing", isTyping)

        hook.Run("ChatStateChanged", client, state, isTyping)
    end
end)

net.Receive("impulseDoorBuy", function(len, client)
    if (client.nextDoorBuy or 0) > CurTime() then return end
    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and client:CanBuyDoor(traceEnt:GetRelay("doorOwners", nil), traceEnt:GetRelay("doorBuyable", true)) and hook.Run("CanEditDoor", client, traceEnt) != false then
        if client:CanAfford(impulse.Config.DoorPrice) then
            client:TakeMoney(impulse.Config.DoorPrice)
            client:SetDoorMaster(traceEnt)

            client:Notify("You have bought a door for " .. impulse.Config.CurrencyPrefix..impulse.Config.DoorPrice .. ".")

            hook.Run("PlayerPurchaseDoor", client, traceEnt)
        else
            client:Notify("You cannot afford to buy this door.")
        end
    end
    client.nextDoorBuy = CurTime() + 0.1
end)

net.Receive("impulseDoorSell", function(len, client)
    if (client.nextDoorSell or 0) > CurTime() then return end
    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and client:IsDoorOwner(traceEnt:GetRelay("doorOwners", nil)) and traceEnt:GetDoorMaster() == client and hook.Run("CanEditDoor", client, traceEnt) != false then
        client:RemoveDoorMaster(traceEnt)
        client:AddMoney(impulse.Config.DoorPrice - 2)

        client:Notify("You have sold a door for " .. impulse.Config.CurrencyPrefix..(impulse.Config.DoorPrice - 2) .. ".")

        hook.Run("PlayerSellDoor", client, traceEnt)
    end
    client.nextDoorSell = CurTime() + 0.1
end)

net.Receive("impulseDoorLock", function(len, client)
    if (client.nextDoorLock or 0) > CurTime() then return end
    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and traceEnt:IsDoor() then
        local doorOwners, doorGroup = traceEnt:GetRelay("doorOwners", nil), traceEnt:GetRelay("doorGroup", nil)

        if client:CanLockUnlockDoor(doorOwners, doorGroup) then
            traceEnt:DoorLock()
            traceEnt:EmitSound("doors/latchunlocked1.wav")
        end
    end

    client.nextDoorLock = CurTime() + 0.1
end)

net.Receive("impulseDoorUnlock", function(len, client)
    if (client.nextDoorUnlock or 0) > CurTime() then return end
    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 96
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity
    if IsValid(traceEnt) and traceEnt:IsDoor() then
        local doorOwners, doorGroup = traceEnt:GetRelay("doorOwners", nil), traceEnt:GetRelay("doorGroup", nil)

        if client:CanLockUnlockDoor(doorOwners, doorGroup) then
            traceEnt:DoorUnlock()
            traceEnt:EmitSound("doors/latchunlocked1.wav")
        end
    end

    client.nextDoorUnlock = CurTime() + 0.1
end)

net.Receive("impulseDoorAdd", function(len, client)
    if (client.nextDoorChange or 0) > CurTime() then return end
    client.nextDoorChange = CurTime() + 0.1

    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local target = net.ReadEntity()

    if !IsValid(target) or !target:IsPlayer() or !client.impulseBeenSetup then return end

    local cost = math.ceil(impulse.Config.DoorPrice / 2)

    if !client:CanAfford(cost) then
        return client:Notify("You cannot afford to add a player to this door.")
    end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity
    local owners = traceEnt:GetRelay("doorOwners", nil)

    if IsValid(traceEnt) and client:IsDoorOwner(owners) and traceEnt:GetDoorMaster() == client then
        if target == client then return end

        if target.impulseOwnedDoors and target.impulseOwnedDoors[traceEnt] then return end

        if table.Count(owners) > 9 then
            return client:Notify("Door user limit reached (9).")
        end

        client:TakeMoney(cost)
        target:SetDoorUser(traceEnt)

        client:Notify("You have added " .. target:Nick() .. " to this door for " .. impulse.Config.CurrencyPrefix..cost .. ".")

        hook.Run("PlayerAddUserToDoor", client, owners)
    end
end)

net.Receive("impulseDoorRemove", function(len, client)
    if (client.nextDoorChange or 0) > CurTime() then return end
    client.nextDoorChange = CurTime() + 0.1

    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local target = net.ReadEntity()

    if !IsValid(target) or !target:IsPlayer() or !client.impulseBeenSetup then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client
    trace.mask = MASK_ALL

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and client:IsDoorOwner(traceEnt:GetRelay("doorOwners", nil)) and traceEnt:GetDoorMaster() == client then
        if target == client then return end

        if !target.impulseOwnedDoors or !target.impulseOwnedDoors[traceEnt] then return end

        if traceEnt:GetDoorMaster() == target then
            return client:Notify("The door's master cannot be removed.")
        end

        target:RemoveDoorUser(traceEnt)

        client:Notify("You have removed " .. target:Nick() .. " from this door.")
    end
end)

net.Receive("impulseQuizSubmit", function(len, client)
    if !client.quizzing then return end
    client.quizzing = false

    local teamID = net.ReadUInt(8)
    if !impulse.Teams.Stored[teamID] or !impulse.Teams.Stored[teamID].quiz then return end

    local quizPassed = net.ReadBool()

    if !quizPassed then
        client.nextQuiz = CurTime() + (impulse.Config.QuizWaitTime * 60)
        return client:Notify("Quiz failed. You may retry the quiz in " .. impulse.Config.QuizWaitTime .. " minutes.")
    end

    local data = client:GetData("quiz") or {}
    data[impulse.Teams.Stored[teamID].codeName] = true

    client:SetData("quiz", data)
    client:SaveData()

    client:Notify("You have passed the quiz. You will not need to retake it again.")

    if client:CanBecomeTeam(teamID, true) then
        client:SetTeam(teamID)
        client:Notify("You have changed your team to " .. team.GetName(teamID) .. ".")
    else
        client:Notify("You passed the quiz, however " .. team.GetName(teamID) .. " cannot be joined right now. Rejoin the team when it is available to play again.")
    end
end)

net.Receive("impulseSellAllDoors", function(len, client)
    if (client.nextSellAllDoors or 0) > CurTime() then return end
    client.nextSellAllDoors = CurTime() + 5
    if !client.impulseOwnedDoors or table.Count(client.impulseOwnedDoors) == 0 then return end

    local sold = 0
    for v, k in pairs(client.impulseOwnedDoors) do
        if IsValid(v) and hook.Run("CanEditDoor", client, v) != false then
            if v:GetDoorMaster() == client then
                local noUnlock = v.NoDCUnlock or false
                client:RemoveDoorMaster(v, noUnlock)
                sold = sold + 1
            else
                client:RemoveDoorUser(v)
            end
        end
    end

    client.impulseOwnedDoors = {}

    local amount = sold * (impulse.Config.DoorPrice - 2)
    client:AddMoney(amount)
    client:Notify("You have sold all your doors for " .. impulse.Config.CurrencyPrefix..amount .. ".")
end)

net.Receive("impulseInvDoEquip", function(len, client)
    if !client.impulseBeenInventorySetup or (client.nextInvEquip or 0) > CurTime() then return end
    client.nextInvEquip = CurTime() + 0.1

    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)
    local equipState = net.ReadBool()

    local hasItem, item = client:HasInventoryItemSpecific(itemID)

    if hasItem then
        client:SetInventoryItemEquipped(itemID, equipState or false)
    end
end)

net.Receive("impulseInvDoDrop", function(len, client)
    if !client.impulseBeenInventorySetup or (client.nextInvDrop or 0) > CurTime() then return end
    client.nextInvDrop = CurTime() + 0.1

    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)

    local hasItem, item = client:HasInventoryItemSpecific(itemID)

    if hasItem then
        client:DropInventoryItem(itemID)
        hook.Run("PlayerDropItem", client, item, itemID)
    end
end)

net.Receive("impulseInvDoUse", function(len, client)
    if !client.impulseBeenInventorySetup or (client.nextInvUse or 0) > CurTime() then return end
    client.nextInvUse = CurTime() + 0.1

    if !client:Alive() or client:GetRelay("arrested", false) then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)

    local hasItem, item = client:HasInventoryItemSpecific(itemID)

    if hasItem then
        client:UseInventoryItem(itemID)
    end
end)

net.Receive("impulseInvDoSearchConfiscate", function(len, client)
    if !client:IsPolice() then return end
    if (client.nextInvConf or 0) > CurTime() then return end
    client.nextInfConf = CurTime() + 0.1

    local targ = client.impulseInventorySearching
    if !IsValid(targ) or !client:CanArrest(targ) then return end

    local count = net.ReadUInt(8) or 0

    if count > 0 then
        for i = 1,count do
            local netid = net.ReadUInt(10)
            local item = impulse.Inventory.Items[netid]

            if !item then continue end

            if item.Illegal and targ:HasInventoryItem(item.UniqueID) then
                targ:TakeInventoryItemClass(item.UniqueID, 1)

                hook.Run("PlayerConfiscateItem", client, targ, item.UniqueID)
            end
        end

        client:Notify("You have confiscated " .. count .. " items.")
        targ:Notify("The search has been completed and " .. count .. " items have been confiscated.")
    else
        targ:Notify("The search has been completed.")
    end

    client.impulseInventorySearching = nil
    targ:Freeze(false)
end)

net.Receive("impulseInvDoMove", function(len, client)
    if (client.nextInvMove or 0) > CurTime() then return end
    client.nextInvMove = CurTime() + 0.1

    if !client.currentStorage or !IsValid(client.currentStorage) then return end
    if client.currentStorage:GetPos():DistToSqr(client:GetPos()) > (100 ^ 2) then return end
    if client:IsPolice() then return end
    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    if !client.currentStorage:CanPlayerUse(client) then return end

    local itemid = net.ReadUInt(16)
    local from = net.ReadUInt(4)
    local to = 1

    if from != 1 and from != 2 then return end

    if from == 1 then
        to = 2
    end

    if to == 2 and (client.impulseNextStorage or 0) > CurTime() then
        client.nextInvMove = CurTime() + 0.1
        return client:Notify("Because you were recently in combat you must wait " .. string.NiceTime(client.impulseNextStorage - CurTime()) .. " before depositing items into your storage.")
    end

    local hasItem, item = client:HasInventoryItemSpecific(itemid, from)

    if !hasItem then return end

    if client.currentStorage:GetClass() == "impulse_storage_public" then
        local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(item.class)]

        if !item then return end

        if item.Illegal then
            return client:Notify("You may not access or store illegal items at public storage lockers.")
        end
    end

    if item.restricted then
        return client:Notify("You cannot store a restricted item.")
    end

    if from == 2 and !client:CanHoldItem(item.class) then
        return client:Notify("Item is too heavy to hold.")
    end

    if from == 1 and !client:CanHoldItemStorage(item.class) then
        return client:Notify("Item is too heavy to store.")
    end

    local canStore = hook.Run("CanStoreItem", client, client.currentStorage, item.class, from)

    if canStore != nil and canStore == false then return end

    client:MoveInventoryItem(itemid, from, to)
end)

net.Receive("impulseInvDoMoveMass", function(len, client)
    if (client.nextInvMove or 0) > CurTime() then return end
    client.nextInvMove = CurTime() + 0.1

    if !client.currentStorage or !IsValid(client.currentStorage) then return end
    if client.currentStorage:GetPos():DistToSqr(client:GetPos()) > (100 ^ 2) then return end
    if client:IsPolice() then return end
    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    if !client.currentStorage:CanPlayerUse(client) then return end

    local class = net.ReadString()
    local amount = net.ReadUInt(8)
    local from = net.ReadUInt(4)
    local to = 1

    if from != 1 and from != 2 then return end

    if from == 1 then
        to = 2
    end

    amount = math.Clamp(amount, 0, 9999)

    if to == 2 and (client.impulseNextStorage or 0) > CurTime() then
        client.nextInvMove = CurTime() + 0.1
        return client:Notify("Because you were recently in combat you must wait " .. string.NiceTime(client.impulseNextStorage - CurTime()) .. " before depositing items into your storage.")
    end

    local classid = impulse.Inventory:ClassToNetID(class)
    if !classid or !impulse.Inventory.Items[classid] then return end

    local item = impulse.Inventory.Items[classid]
    local hasItem

    if from == 1 then
        hasItem = client:HasInventoryItem(class, amount)
    else
        hasItem = client:HasInventoryItemStorage(class, amount)
    end

    if !hasItem then return end

    if client.currentStorage:GetClass() == "impulse_storage_public" then
        if item.Illegal then
            return client:Notify("You may !access or store illegal items at public storage lockers.")
        end
    end

    local runs = 0
    for v, k in pairs(client:GetInventory(from)) do
        runs = runs + 1

        if k.class == class then -- id pls
            if k.restricted then -- get out
                return client:Notify("You cannot store a restricted item.")
            end
        end

        if runs >= amount then -- youve passed :D
            break
        end
    end

    if from == 2 and !client:CanHoldItem(class, amount) then
        return client:Notify("Items are too heavy to hold.")
    end

    if from == 1 and !client:CanHoldItemStorage(class, amount) then
        return client:Notify("Items are too heavy to store.")
    end

    local canStore = hook.Run("CanStoreItem", client, client.currentStorage, class, from)

    if canStore != nil and canStore == false then return end

    client:MoveInventoryItemMass(class, from, to, amount)
end)

net.Receive("impulseChangeRPName", function(len, client)
    if !client.impulseBeenSetup then return end
    if (client.nextRPNameTry or 0) > CurTime() then return end
    client.nextRPNameTry = CurTime() + 0.1

    if impulse.Teams.Stored[client:Team()] and impulse.Teams.Stored[client:Team()].blockNameChange then
        return client:Notify("Your team can not change their name.")
    end

    if (client.nextRPNameChange or 0) > CurTime() then
        return client:Notify("You must wait " .. string.NiceTime(client.nextRPNameChange - CurTime()) .. " before changing your name again.")
    end

    local name = net.ReadString()

    if client:CanAfford(impulse.Config.RPNameChangePrice) then
        local canUseName, output = impulse.CanUseName(name)

        if canUseName then
            client:TakeMoney(impulse.Config.RPNameChangePrice)
            client:SetRPName(output, true)

            hook.Run("PlayerChangeRPName", client, output)

            client.nextRPNameChange = CurTime() + 240
            client:Notify("You have changed your name to " .. output .. " for " .. impulse.Config.CurrencyPrefix .. impulse.Config.RPNameChangePrice .. ".")
        else
            client:Notify("Name rejected: " .. output)
        end
    else
        client:Notify("You cannot afford to change your name.")
    end
end)

net.Receive("impulseCharacterEdit", function(len, client)
    if !client.impulseBeenSetup then return end
    if (client.nextCharEditTry or 0) > CurTime() then return end
    client.nextCharEditTry = CurTime() + 3

    if !client.currentCosmeticEditor or !IsValid(client.currentCosmeticEditor) or client.currentCosmeticEditor:GetPos():DistToSqr(client:GetPos()) > (120 ^ 2) then return end

    if client:Team() != impulse.Config.DefaultTeam then return end

    local newIsFemale = false
    local newModel = net.ReadString()
    local newSkin = net.ReadUInt(8)
    local cost = 0
    local isCurFemale = client:IsCharacterFemale()
    local curModel = client.impulseDefaultModel
    local curSkin = client.impulseDefaultSkin

    if !table.HasValue(impulse.Config.DefaultMaleModels, newModel) and !table.HasValue(impulse.Config.DefaultFemaleModels, newModel) then return end

    if table.HasValue(impulse.Config.DefaultFemaleModels, newModel) then
        newIsFemale = true
    end

    local skinBlacklist = impulse.Config.DefaultSkinBlacklist[newModel]

    if skinBlacklist and table.HasValue(skinBlacklist, newSkin) then return end

    if newIsFemale != isCurFemale then
        cost = cost + impulse.Config.CosmeticGenderPrice
    end

    if curModel != newModel or curSkin != newSkin then
        cost = cost + impulse.Config.CosmeticModelSkinPrice
    end

    if cost == 0 then return end

    if client:CanAfford(cost) then
        local query = mysql:Update("impulse_players")
        query:Update("skin", newSkin)
        query:Update("model", newModel)
        query:Where("steamid", client:SteamID64())
        query:Execute()

        client.impulseDefaultModel = newModel
        client.impulseDefaultSkin = newSkin

        client:UpdateDefaultModelSkin()

        local oldBodyGroupsTemp = {}
        local oldBodyGroups = client:GetBodyGroups()

        for v, k in pairs(oldBodyGroups) do
            oldBodyGroupsTemp[k.id] = client:GetBodygroup(k.id)
        end

        client:SetModel(client.impulseDefaultModel)
        client:SetSkin(client.impulseDefaultSkin)

        for v, k in pairs(oldBodyGroups) do
            client:SetBodygroup(k.id, oldBodyGroupsTemp[k.id])
        end

        client:TakeMoney(cost)
        client:Notify("You have changed your appearance for " .. impulse.Config.CurrencyPrefix..cost .. ".")
    else
        client:Notify("You cannot afford to change your appearance.")
    end

    client.currentCosmeticEditor = nil
end)

net.Receive("impulseDoConfiscate", function(len, client)
    if (client.nextDoConfiscate or 0) > CurTime() then return end
    if !client:IsPolice() then return end

    local item = client.ConfiscatingItem

    if !item or !IsValid(item) then return end

    local itemName = item.Item.Name

    if item:GetPos():DistToSqr(client:GetPos()) < (200 ^ 2) then
        client:Notify("You have confiscated a " .. itemName .. ".")
        item:Remove()
    end

    client.nextDoConfiscate = CurTime() + 0.1
end)

net.Receive("impulseMixTry", function(len, client)
    print("Received mix try from " .. client:Nick())
    if (client.nextMixTry or 0) > CurTime() then return end
    client.nextMixTry = CurTime() + 0.1
    print("Passed time check")

    if client.IsCrafting then
        client:Notify("You are already crafting an item!")
        return -- already crafting
    end

    if !client:Alive() or client:GetRelay("arrested", false) then
        client:Notify("You cannot craft while dead or arrested!")
        return -- ded or arrested
    end

    if client:IsPolice() then
        client:Notify("You cannot craft items as a Police Officer!")
        return -- is police
    end

    local bench = client.currentBench

    if !bench or !IsValid(bench) or bench:GetPos():DistToSqr(client:GetPos()) > (128 ^ 2) then
        client:Notify("You are too far away from the workbench!")
        return -- bench not real or too far from
    end

    if bench.InUse then
        return client:Notify("This workbench is already in use.")
    end

    local benchEnt = bench

    local mix = net.ReadUInt(8)
    local mixClass = impulse.Inventory.MixturesStored[mix]

    if !mixClass then
        client:Notify("Invalid mixture selected, please contact a developer.")
        return
    end

    bench = mixClass[1]
    mix = mixClass[2]

    mixClass = impulse.Inventory.Mixtures[bench][mix]

    local output = mixClass.Output
    local takeWeight = 0

    local can, reason = client:CanMakeMix(mixClass)
    if !can then -- checks input items + craft level
        if reason then
            client:Notify(reason)
        end
        return
    end

    local oWeight = impulse.Inventory.ItemsQW[output]

    for v, k in pairs(mixClass.Input) do
        local iWeight = impulse.Inventory.ItemsQW[v]

        if iWeight then
            iWeight = iWeight * k.take
        end

        takeWeight = takeWeight + iWeight
    end

    if (client.InventoryWeight - takeWeight) + oWeight >= impulse.Config.InventoryMaxWeight then
        client:Notify("You do not have enough inventory space to craft this item!")
        return
    end

    benchEnt.InUse = true

    local startTeam = client:Team()
    local time, sounds = impulse.Inventory:GetCraftingTime(mixClass)
    client.CraftFail = false

    for v, k in pairs(sounds) do
        timer.Simple(k[1], function()
            if !IsValid(client) or !IsValid(benchEnt) or !client:Alive() or client:GetRelay("arrested", false) or client.CraftFail or benchEnt:GetPos():DistToSqr(client:GetPos()) > (120 ^ 2) then
                if IsValid(client) then
                    client.CraftFail = true
                end

                return
            end

            local crafttype = k[2]
            local snd = impulse.Inventory:PickRandomCraftSound(crafttype)

            benchEnt:EmitSound(snd, 100)
        end)
    end

    hook.Run("PlayerStartCrafting", client, mixClass.Output)

    if benchEnt.Bench.OnCraft then
        benchEnt.Bench.OnCraft(benchEnt, client, mixClass)
    end

    timer.Simple(time, function()
        if IsValid(benchEnt) then
            benchEnt.InUse = false
        end

        local can, reason = client:CanMakeMix(mixClass)
        if IsValid(client) and client:Alive() and IsValid(benchEnt) then
            if !can then
                client.CraftFail = true
                if reason then
                    client:Notify(reason)
                end
            end
            if benchEnt:GetPos():DistToSqr(client:GetPos()) > (128 ^ 2) then return end

            if client.CraftFail then return end

            if client:GetRelay("arrested", false) or client:IsPolice() then return end

            if startTeam != client:Team() then return end

            local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(mixClass.Output)]

            for v, k in pairs(mixClass.Input) do
                client:TakeInventoryItemClass(v, nil, k.take)
            end

            local amount = mixClass.OutputAmount or 1

            for i = 1, amount do
                client:GiveItem(mixClass.Output)
            end

            if ( amount > 1 ) then
                client:Notify("You have crafted a " .. item.Name .. ".")
            else
                client:Notify("You have crafted " .. amount .. " " .. item.Name .. "es .")
            end

            local xp = 28 + ((math.Clamp(mixClass.Level, 2, 9)  * 1.8) * 2) -- needs balancing

            if mixClass.XPMultiplier then
                xp = xp * mixClass.XPMultiplier
            end

            client:AddSkillXP("craft", xp)

            hook.Run("PlayerCraftItem", client, mixClass.Output)
        end
    end)

    net.Start("impulseMixDo") -- send response to allow crafting to client
    net.Send(client)
end)

net.Receive("impulseVendorBuy", function(len, client)
    if (client.nextVendorBuy or 0) > CurTime() then return end
    client.nextVendorBuy = CurTime() + 0.1

    if !client.currentVendor or !IsValid(client.currentVendor) then return end

    local vendor = client.currentVendor

    if (client:GetPos() - vendor:GetPos()):LengthSqr() > (120 ^ 2) then return end

    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    if vendor.Vendor.CanUse and vendor.Vendor.CanUse(vendor, client) == false then return end

    local class = net.ReadString()

    if string.len(class) > 128 then return end

    local sellData = vendor.Vendor.Sell[class]

    if !sellData then return end

    if sellData.Cost and !client:CanAfford(sellData.Cost) then return end

    if sellData.Max then
        local hasItem, amount = client:HasInventoryItem(class)

        if hasItem and amount >= sellData.Max then return end
    end

    if sellData.CanBuy and sellData.CanBuy(client) == false then return end

    if !client:CanHoldItem(class) then
        return client:Notify("You don't have enough inventory space to hold this item.")
    end

    if sellData.Cooldown then
        client.VendorCooldowns = client.VendorCooldowns or {}
        local cooldown = client.VendorCooldowns[class]

        if cooldown and cooldown > CurTime() then
            return client:Notify("Please wait " .. string.NiceTime(cooldown - CurTime()) .. " before attempting to purchase this item again.")
        else
            client.VendorCooldowns[class] = CurTime() + sellData.Cooldown
        end
    end

    if sellData.BuyMax then
        client.VendorBuyMax = client.VendorBuyMax or {}
        local tMax = client.VendorBuyMax[class]

        if tMax then
            if tMax.Cooldown and tMax.Cooldown > CurTime() then
                local cooldown = tMax.Cooldown

                return client:Notify("This vendor has no more of this item to give you. Come back in " .. string.NiceTime(cooldown - CurTime()) .. " for more.")
            elseif tMax.Cooldown then
                client.VendorBuyMax[class] = {
                    Count = 0,
                    Cooldown = nil
                }
            end

            if client.VendorBuyMax[class].Count >= sellData.BuyMax then
                local cooldown = CurTime() + sellData.TempCooldown
                client.VendorBuyMax[class].Cooldown = cooldown

                return client:Notify("This vendor has no more of this item to give you. Come back in " .. string.NiceTime(cooldown - CurTime()) .. " for more.")
            end
        else
            client.VendorBuyMax[class] = {
                Count = 0
            }
        end

        tMax = client.VendorBuyMax[class]

        client.VendorBuyMax[class].Count = ((tMax and tMax.Count) or 0) + 1

        if tMax then
            if client.VendorBuyMax[class].Count >= sellData.BuyMax then
                local cooldown = CurTime() + sellData.TempCooldown
                client.VendorBuyMax[class].Cooldown = cooldown
            end
        end
    end

    local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]

    if sellData.Cost then
        client:TakeMoney(sellData.Cost)
        client:Notify("You have purchased " .. item.Name .. " for " .. impulse.Config.CurrencyPrefix..sellData.Cost .. ".")
    else
        client:Notify("You have acquired a " .. item.Name .. ".")
    end

    client:GiveItem(class, 1, sellData.Restricted or false)

    if vendor.Vendor.OnItemPurchased then
        vendor.Vendor.OnItemPurchased(vendor, class, client)
    end

    hook.Run("PlayerVendorBuy", client, vendor, class, sellData.Cost or 0)
end)

net.Receive("impulseVendorSell", function(len, client)
    if (client.nextVendorSell or 0) > CurTime() then return end
    client.nextVendorSell = CurTime() + 0.1

    if !client.currentVendor or !IsValid(client.currentVendor) then return end

    local vendor = client.currentVendor

    if (client:GetPos() - vendor:GetPos()):LengthSqr() > (120 ^ 2) then return end

    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    if vendor.Vendor.CanUse and vendor.Vendor.CanUse(vendor, client) == false then return end

    if vendor.Vendor.MaxBuys and (vendor.Buys or 0) >= vendor.Vendor.MaxBuys then
        return client:Notify("This vendor can not afford to purchase this item.")
    end

    local itemid = net.ReadUInt(16)
    local hasItem, itemData = client:HasInventoryItemSpecific(itemid)

    if !hasItem then return end

    if itemData.restricted then return end

    local class = itemData.class

    local buyData = vendor.Vendor.Buy[class]
    local itemName = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)].Name

    if !buyData then return end

    if buyData.CanBuy and buyData.CanBuy(client) == false then return end

    if vendor.Vendor.MaxBuys then
        vendor.Buys = (vendor.Buys or 0) + 1
    end

    client:TakeInventoryItem(itemid)

    if buyData.Cost then
        client:AddMoney(buyData.Cost)
        client:Notify("You have sold a " .. itemName .. " for " .. impulse.Config.CurrencyPrefix..buyData.Cost .. ".")
    else
        client:Notify("You have handed over a " .. itemName .. ".")
    end

    hook.Run("PlayerVendorSell", client, vendor, class, buyData.Cost or "free")
end)

net.Receive("impulseRequestWhitelists", function(len, client)
    if (client.nextWhitelistReq or 0) > CurTime() then return end
    client.nextWhitelistReq = CurTime() + 5

    local id = net.ReadUInt(8)
    local targ = Entity(id)

    if targ and IsValid(targ) and targ:IsPlayer() and targ.Whitelists then
        local whitelists = targ.Whitelists
        local count = 0

        for v, k in pairs(whitelists) do
            if isnumber(v) then
                count = count + 1
            end
        end

        net.Start("impulseViewWhitelists")
        net.WriteUInt(count, 4)

        for v, k in pairs(whitelists) do
            if isnumber(v) then
                net.WriteUInt(v, 8)
                net.WriteUInt(k, 8)
            end
        end

        net.Send(client)
    end
end)

net.Receive("impulseUnRestrain", function(len, client)
    if (client.nextUnRestrain or 0) > CurTime() then return end
    client.nextUnRestrain = CurTime() + 0.1

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client

    local tr = util.TraceLine(trace)
    local ent = tr.Entity

    if !ent or !IsValid(ent) then return end

    if !ent:IsPlayer() or ent:GetRelay("arrested", false) == false or !client:CanArrest(ent) then return end

    if ent.impulseBeingJailed then return end

    if ent.InJail then
        return client:Notify("You can't unrestrain someone who is in jail.")
    end

    ent:UnArrest()

    client:Notify("You have released " .. ent:Name() .. ".")
    ent:Notify("You have been released by " .. client:Name() .. ".")

    hook.Run("PlayerUnArrested", ent, client)
    hook.Run("PlayerUnRestrain", client, ent)
end)

net.Receive("impulseInvContainerCodeReply", function(len, client)
    if (client.nextPassCodeTry or 0) > CurTime() then return end
    client.nextPassCodeTry = CurTime() + 3

    local container = client.currentContainerPass

    if !container or !IsValid(container) then return end

    if !client:Alive() then return end

    if (client:GetPos() - container:GetPos()):LengthSqr() > (120 ^ 2) then return end

    local code = net.ReadUInt(16)
    code = math.floor(code)

    if code < 0 then return end

    if code == container.Code then
        container:AddAuthorised(client)
        container:AddUser(client)

        client:Notify("Passcode accepted.")
    else
        client:Notify("Incorrect container passcode.")
    end
end)

net.Receive("impulseInvContainerClose", function(len, client)
    local container = client.currentContainer

    if container then
        if IsValid(container) and container.Users[client] then
            container:RemoveUser(client)
        else
            client.currentContainer = nil
        end
    end
end)

net.Receive("impulseInvContainerDoMove", function(len, client)
    if (client.nextInvMove or 0) > CurTime() then return end
    client.nextInvMove = CurTime() + 0.1

    local container = client.currentContainer

    if !container or !IsValid(container) then return end

    if container:GetPos():DistToSqr(client:GetPos()) > (120 ^ 2) then return end

    local isLoot = container.GetLoot and container:GetLoot() or false
    if isLoot then
        if client:IsPolice() then return end
    elseif container.Code and !container.Authorised[client] then return end

    if client:GetRelay("arrested", false) or !client:Alive() then return end

    local canUse = hook.Run("CanUseInventory", client)

    if canUse != nil and canUse == false then return end

    local from = net.ReadUInt(4)
    local to = 1

    if from != 1 and from != 2 then return end

    if from == 1 then
        to = 2
    end

    if from == 2 then
        local class = net.ReadString()
        if !class or class == "" then return end

        local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(class)]
        if !item then return end

        if !container.Inventory or table.Count(container.Inventory) < 1 then return end

        if !container.Inventory[class] then
            return client:Notify("That item is no longer in this container.")
        end

        if !client:CanHoldItem(class) then
            return client:Notify("Item is too heavy to hold.")
        end

        if item.Illegal and client:IsPolice() then
            container:TakeItem(class)
            return client:Notify(item.Name .. " (illegal item) destroyed.")
        end

        container:TakeItem(class, 1, true)

        local newItemID = client:GiveItem(class)
        if ( !newItemID ) then
            -- Revert if the item could not be inserted into the player's inventory.
            container:AddItem(class, 1, true)
            container:UpdateUsers()
            return client:Notify("Unable to move item into your inventory.")
        end

        container:UpdateUsers()
    elseif from == 1 then
        local itemid = net.ReadUInt(16)
        local hasItem, item = client:HasInventoryItemSpecific(itemid, 1)

        if !hasItem then return end

        if item.restricted then
            return client:Notify("You cannot store a restricted item.")
        end

        if !container:CanHoldItem(item.class) then
            return client:Notify("Item is too heavy to store.")
        end

        client:TakeInventoryItem(itemid)
        container:AddItem(item.class)
    end
end)

net.Receive("impulseInvContainerRemovePadlock", function(len, client)
    if (client.nextPadlockBreak or 0) > CurTime() then return end
    client.nextPadlockBreak = CurTime() + 6

    if !client:IsPolice() then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 85
    trace.filter = client

    local tr = util.TraceLine(trace)
    local ent = tr.Entity

    if !ent or !IsValid(ent) then return end

    if ent:GetClass() != "impulse_container" then return end

    ent:SetCode(nil)
    client:Notify("Padlock removed from container.")
end)

net.Receive("impulseInvContainerDoSetCode", function(len, client)
    if (client.nextSetContCode or 0) > CurTime() then return end
    client.nextSetContCode = CurTime() + 0.1

    if !client.ContainerCodeSet or !IsValid(client.ContainerCodeSet) then return end

    local container = client.ContainerCodeSet

    if container:CPPIGetOwner() != client then return end

    local passcode = net.ReadUInt(16)
    passcode = math.floor(passcode)

    if passcode < 1000 or passcode > 9999 then return end

    container:SetCode(passcode)
    client.ContainerCodeSet = nil

    client:Notify("You have set the containers passcode to " .. passcode .. ".")

    hook.Run("ContainerPasscodeSet", client, container)
end)

local NCHANGE_ANTISPAM = NCHANGE_ANTISPAM or {}
net.Receive("impulseGroupDoRankAdd", function(len, client)
    if (client.nextRPGroupRankEdit or 0) > CurTime() then return end
    client.nextRPGroupRankEdit = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(6) then return end

    local rankName = net.ReadString()
    local nChange = net.ReadBool()
    local newName
    if nChange then
        if NCHANGE_ANTISPAM[name] and NCHANGE_ANTISPAM[name] > CurTime() then
            return client:Notify("Wait a few seconds before changing a ranks name...")
        else
            NCHANGE_ANTISPAM[name] = CurTime() + 7
        end

        newName = string.sub(net.ReadString(), 1, 32)

        if string.Trim(newName, " ") == "" then
            return client:Notify("Invalid rank name.")
        end

        if groupData.Ranks[newName] then
            return client:Notify("This rank name is already in use.")
        end
    end

    local permissions = {}
    local isDefault = false
    local isOwner = false

    local r = groupData.Ranks[rankName]
    if r then
        if r[99] then
            isOwner = true
        end

        if r[0] then
            isDefault = true
        end
    else
        local isBig = false
        if groupData.MemberCount >= 30 then
            isBig = true
        end

        if isBig then
            if table.Count(groupData.Ranks) >= impulse.Config.GroupMaxRanksVIP then
                return client:Notify("Max ranks reached.")
            end
        elseif table.Count(groupData.Ranks) >= impulse.Config.GroupMaxRanks then
            return client:Notify("Max ranks reached. (once the group reaches 30 members you will unlock more)")
        end

        rankName = string.sub(rankName, 1, 32)

        if string.Trim(rankName, " ") == "" then
            return client:Notify("Invalid rank name.")
        end
    end

    for v, k in pairs(RPGROUP_PERMISSIONS) do
        local permId = net.ReadUInt(8)
        local enabled = net.ReadBool()

        -- protected permissions that can not be changed
        if permId == 0 or permId == 99 then
            if isOwner then
                permissions[99] = true
            end

            if isDefault then
                permissions[0] = true
            end

            continue
        end

        if enabled then
            permissions[permId] = true
        end
    end

    if nChange then
        impulse.Group.Groups[name].Ranks[rankName] = nil
    end

    impulse.Group.Groups[name].Ranks[newName or rankName] = permissions

    if nChange then
        impulse.Group:RankShift(name, rankName, newName)
    end

    impulse.Group:NetworkRanksToOnline(name)
    impulse.Group:UpdateRanks(groupData.ID, impulse.Group.Groups[name].Ranks)
end)

local INVITE_ANTISPAM = INVITE_ANTISPAM or {}
net.Receive("impulseGroupDoInvite", function(len, client)
    if (client.nextRPGroupRankInv or 0) > CurTime() then return end
    client.nextRPGroupRankInv = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(3) then return end

    local targ = net.ReadEntity()

    if !IsValid(targ) or !targ:IsPlayer() or !targ.impulseBeenSetup or targ:GetRelay("groupName", nil) then return end

    if targ.GroupInvites and targ.GroupInvites[name] then
        return client:Notify("This player already has a pending invite for this group.")
    end

    if groupData.MemberCount >= groupData.MaxSize then
        return client:Notify("This group is full.")
    end

    if INVITE_ANTISPAM[name] and INVITE_ANTISPAM[name].Amount > 8 then
        if INVITE_ANTISPAM[name].Expire > CurTime() then
            return client:Notify("Please wait a while before sending more invites.")
        end

        INVITE_ANTISPAM[name].Amount = 0
    end

    INVITE_ANTISPAM[name] = INVITE_ANTISPAM[name] or {}

    INVITE_ANTISPAM[name].Amount = (INVITE_ANTISPAM[name].Amount or 0) + 1
    INVITE_ANTISPAM[name].Expire = CurTime() + 360

    targ.GroupInvites = targ.GroupInvites or {}
    targ.GroupInvites[name] = true

    net.Start("impulseGroupInvite")
    net.WriteString(name)
    net.WriteString(client:Nick())
    net.Send(targ)

    client:Notify("You invited " .. targ:Nick() .. " to your group.")
end)

net.Receive("impulseGroupDoInviteAccept", function(len, client)
    if (client.nextRPGroupRankAccept or 0) > CurTime() then return end
    client.nextRPGroupRankAccept = CurTime() + 6

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if name or rank then return end

    local name = net.ReadString()

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client.GroupInvites or !client.GroupInvites[name] then return end

    if groupData.MemberCount >= groupData.MaxSize then
        return client:Notify("This group is full.")
    end

    client.GroupInvites[name] = nil

    client:GroupAdd(name)
    client:Notify("You have joined the " .. name .. " group.")
end)

net.Receive("impulseGroupDoRankRemove", function(len, client)
    if (client.nextRPGroupRankEdit or 0) > CurTime() then return end
    client.nextRPGroupRankEdit = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(6) then return end

    local rankName = net.ReadString()
    local r = groupData.Ranks[rankName]

    if !r then return end

    if r[99] or r[0] then return end

    impulse.Group:RankShift(name, rankName, impulse.Group:GetDefaultRank(name))
    impulse.Group.Groups[name].Ranks[rankName] = nil
    impulse.Group:NetworkRanksToOnline(name)
    impulse.Group:UpdateRanks(groupData.ID, impulse.Group.Groups[name].Ranks)
end)

net.Receive("impulseGroupDoSetRank", function(len, client)
    if (client.nextRPGroupRankSet or 0) > CurTime() then return end
    client.nextRPGroupRankSet = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(5) then return end

    local targ = net.ReadString()

    if !targ or !groupData.Members[targ] then return end

    local memberData = groupData.Members[targ]

    if groupData.Ranks[memberData.Rank][99] then -- its the owner!!!
        return client:Notify("You can not change the rank of the group owner.")
    end

    local targEnt = player.GetBySteamID(targ)
    local rankName = net.ReadString()
    local r = groupData.Ranks[rankName]

    if !r then return end

    if r[99] then return end

    if rankName == memberData.Rank then
        return client:Notify("This player is already set to this rank.")
    end

    local n = targ

    if IsValid(targEnt) then
        targEnt:GroupAdd(name, rankName)
        targEnt:Notify(client:Nick() .. " set your group rank to " .. rankName .. ".")
        n = targEnt:Nick()
    else
        impulse.Group:UpdatePlayerRank(targ, rankName)
        impulse.Group.Groups[name].Members[targ].Rank = rankName
        impulse.Group:NetworkMemberToOnline(name, targ)
    end

    client:Notify("You set the group rank of " .. n .. " to " .. rankName .. ".")
end)

net.Receive("impulseGroupDoRemove", function(len, client)
    if (client.nextRPGroupRankSet or 0) > CurTime() then return end
    client.nextRPGroupRankSet = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(4) then return end

    local targ = net.ReadString()

    if !targ or !groupData.Members[targ] then return end

    local memberData = groupData.Members[targ]

    if groupData.Ranks[memberData.Rank][99] then -- its the owner!!!
        return client:Notify("You can not remove the group owner.")
    end

    if targ == client:SteamID64() then
        return client:Notify("You can not remove yourself.")
    end

    local targEnt = player.GetBySteamID(targ)
    local n = targ

    if IsValid(targEnt) then
        targEnt:GroupRemove(name)
        targEnt:Notify(client:Nick() .. " has removed you from the " .. name .. " group.")
        n = targEnt:Nick()
    else
        impulse.Group:RemovePlayer(targ, groupData.ID)
        impulse.Group.Groups[name].Members[targ] = nil
        impulse.Group:NetworkMemberRemoveToOnline(name, targ)
    end

    client:Notify("You removed " .. n .. " from the group.")
end)

net.Receive("impulseGroupDoCreate", function(len, client)
    if (client.nextRPGroupCreate or 0) > CurTime() then return end
    client.nextRPGroupCreate = CurTime() + 4

    if !client.impulseID then return end

    if client:IsPolice() then return end

    if client:GetXP() < impulse.Config.GroupXPRequirement then return end

    if !client:CanAfford(impulse.Config.GroupMakeCost) then return end

    local curName = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if name or curName then return end

    local name = string.Trim(string.sub(net.ReadString(), 1, 32), " ")

    if name == "" then
        return client:Notify("Invalid group name.")
    end

    if impulse.Group.Groups[name] then
        return client:Notify("This group name is already in use.")
    end

    local slots = client:IsDonator() and impulse.Config.GroupMaxMembersVIP or impulse.Config.GroupMaxMembers

    impulse.Group:Create(name, client.impulseID, slots, 30, nil, function(groupid)
        if !IsValid(client) then return end

        if !groupid then
            return client:Notify("This group name is already in use.")
        end

        client:TakeMoney(impulse.Config.GroupMakeCost)

        impulse.Group:AddPlayer(client:SteamID64(), groupid, "Owner", function()
            if !IsValid(client) then return end

            client:GroupLoad(groupid, "Owner")
            client:Notify("You have created a new group called " .. name .. ".")
        end)
    end)
end)

net.Receive("impulseGroupDoDelete", function(len, client)
    if (client.nextRPGroupDelete or 0) > CurTime() then return end
    client.nextRPGroupDelete = CurTime() + 3

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData or !groupData.ID then return end

    if !client:GroupHasPermission(99) then return end

    for v, k in pairs(groupData.Members) do
        local targEnt = player.GetBySteamID(v)

        if IsValid(targEnt) then
            targEnt:SetRelay("groupName", nil)
            targEnt:SetRelay("groupRank", nil)
            targEnt:Notify("You were removed from the " .. name .. " group as it has been deleted by the owner.")
        end
    end

    impulse.Group.Groups[name] = nil
    impulse.Group:Remove(groupData.ID)
    impulse.Group:RemovePlayerMass(groupData.ID)

    client:Notify("You deleted the " .. name .. " group.")
end)

net.Receive("impulseGroupDoLeave", function(len, client)
    if (client.nextRPGroupDelete or 0) > CurTime() then return end
    client.nextRPGroupDelete = CurTime() + 3

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if client:GroupHasPermission(99) then return end

    client:GroupRemove(name)
    client:Notify("You have left the " .. name .. " group.")
end)

net.Receive("impulseGroupDoSetColor", function(len, client)
    if (client.nextRPGroupDataSet or 0) > CurTime() then return end
    client.nextRPGroupDataSet = CurTime() + 0.1

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(99) then return end

    local col = net.ReadColor()

    if !col then return end

    col.a = 255

    impulse.Group:SetMetaData(name, nil, col)
    impulse.Group:NetworkMetaDataToOnline(name)

    client:Notify("You have updated the colour of your group.")
end)

net.Receive("impulseGroupDoSetInfo", function(len, client)
    if (client.nextRPGroupDataSet or 0) > CurTime() then return end
    client.nextRPGroupDataSet = CurTime() + 3

    if client:IsPolice() then return end

    local name = client:GetRelay("groupName", nil)
    local rank = client:GetRelay("groupRank", nil)

    if !name or !rank then return end

    local groupData = impulse.Group.Groups[name]

    if !groupData then return end

    if !client:GroupHasPermission(8) then return end

    local info = net.ReadString()

    if !info then return end

    info = string.sub(info, 1, 1024)

    impulse.Group:SetMetaData(name, info)
    impulse.Group:NetworkMetaDataToOnline(name)

    client:Notify("You have updated the info for your group.")
end)

net.Receive("impulseInvRequestSync", function(len, client)
    if !client.impulseBeenInventorySetup then return end
    if (client.nextInvSync or 0) > CurTime() then return end
    client.nextInvSync = CurTime() + 5 -- Prevent spam

    -- Resend entire inventory to client
    local impulseID = client.impulseID

    for storageType = INVENTORY_PLAYER, INVENTORY_STORAGE do
        local inv = impulse.Inventory.Data[impulseID][storageType]
        if inv then
            for itemID, itemData in pairs(inv) do
                local itemNet = impulse.Inventory:ClassToNetID(itemData.class)

                net.Start("impulseInvGive")
                    net.WriteUInt(itemNet, 16)
                    net.WriteUInt(itemID, 16)
                    net.WriteUInt(storageType, 4)
                    net.WriteBool(itemData.restricted or false)
                    net.WriteString(itemData.class) -- Send class so client can store and resolve items
                net.Send(client)
            end
        end
    end
end)
