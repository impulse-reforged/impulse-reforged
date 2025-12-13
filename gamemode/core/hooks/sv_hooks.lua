local logs = impulse.Logs

function GM:PlayerUseSpawnSaver(client)
    return false
end

function GM:DatabaseConnected()
    -- Create the SQL tables if they do not exist.
    impulse.Database:LoadTables()

    logs:Database("Database type: " .. impulse.Database.Config.adapter .. ".")

    if ( impulse.Database.Config.dev and impulse.Database.Config.dev.preview ) then
        GetConVar("impulse_preview"):SetBool(true)
    end

    timer.Create("impulseDatabaseThink", 0.5, 0, function()
        mysql:Think()
    end)
end

function GM:DatabaseConnectionFailed()
    SetGlobalString("impulse_fatalerror", "Failed to connect to database. See server console for error.")
end

function GM:PlayerInitialSpawn(client)
    local isNew = false
    local clientTable = client:GetTable()

    client:SetCanZoom(false)

    client:LoadData(function(data)
        if ( !IsValid(client) ) then return end

        local address = impulse.Util:GetAddress()
        local bNoCache = client:GetData("lastIP", address) != address
        client:SetData("lastIP", address)

        net.Start("impulseDataSync")
            net.WriteTable(data or {})
            net.WriteUInt(clientTable.impulsePlayTime or 0, 32)
        net.Send(client)

        local query = mysql:Select("impulse_players")
        query:Where("steamid", client:SteamID64())
        query:Callback(function(result)
            if ( !IsValid(client) ) then return end

            if ( !result or !result[1] ) then
                ErrorNoHalt("[impulse] Failed to load player data for " .. client:SteamName() .. " (" .. client:SteamID64() .. ")\n")
                client:Kick("Failed to load character data from database.")
                return
            end

            local db = result[1]

            -- Set the isNew flag to false if the player has already joined the server.
            isNew = db.rpname == nil or db.rpname == ""

            net.Start("impulseChatText")
                net.WriteTable({Color(150, 150, 200), client:SteamName() .. " has connected to the server."})
            net.Broadcast()

            if ( isNew ) then
                net.Start("impulseJoinData")
                    net.WriteBool(isNew)
                net.Send(client)

                client:Freeze(true)
                hook.Run("PlayerFirstJoin", client, db)
            else
                client:Freeze(false)
                hook.Run("PlayerSetup", client, db)
            end

            if ( GExtension ) then
                logs:Database("GExtension detected, skipping group setting for '" .. client:SteamID64() .. " (" .. client:Name() .. ")'.")
            elseif ( VyHub ) then
                logs:Database("VyHub detected, skipping group setting for '" .. client:SteamID64() .. " (" .. client:Name() .. ")'.")
            else
                if ( db.group ) then
                    client:SetUserGroup(db.group, true)
                    logs:Database("Set '" .. client:SteamID64() .. " (" .. client:Name() .. ")' to group '" .. db.group .. "'.")
                else
                    client:SetUserGroup("user", true)
                    logs:Database("No group found for '" .. client:SteamID64() .. " (" .. client:Name() .. ")'. Defaulting to user.")

                    local queryGroup = mysql:Update("impulse_players")
                    queryGroup:Update("group", "user")
                    queryGroup:Where("steamid", client:SteamID64())
                    queryGroup:Callback(function(result)
                        if ( !result ) then
                            client:Kick("Failed to update group in database.")
                        end
                    end)

                    queryGroup:Execute()

                    client:SaveData()
                end
            end
        end)

        query:Execute()
    end)

    local xpTimerName = "impulseXP." .. client:UserID()
    timer.Create(xpTimerName, impulse.Config.XPTime, 0, function()
        if ( !IsValid(client) ) then
            timer.Remove(xpTimerName)
            return
        end

        if ( !client:IsAFK() ) then
            client:GiveTimedXP()
        end
    end)

    local payTimerName = "impulsePayDay." .. client:UserID()
    timer.Create(payTimerName, impulse.Config.PayDayTime or 600, 0, function()
        if ( !IsValid(client) ) then
            timer.Remove(payTimerName)
            return
        end

        if ( !client:IsAFK() ) then
            local teamData = impulse.Teams.Stored[client:Team()]
            if ( !teamData ) then return end

            local salary = teamData.salary or 0

            local classID = client:GetTeamClass()
            if ( classID ) then
                local classData = teamData.classes[classID]
                if ( classData and classData.salary ) then
                    salary = salary + classData.salary
                end
            end

            local rankID = client:GetTeamRank()
            if ( rankID ) then
                local rankData = teamData.ranks[rankID]
                if ( rankData and rankData.salary ) then
                    salary = salary + rankData.salary
                end
            end

            if ( salary > 0 ) then
                client:AddBankMoney(salary)
                client:Notify("You have received a salary of " .. impulse.Config.CurrencyPrefix .. salary .. ".")
            end
        end
    end)

    local oocTimerName = "impulseOOCLimit." .. client:UserID()
    timer.Create(oocTimerName, 1800, 0, function()
        if ( !IsValid(client) ) then
            timer.Remove(oocTimerName)
            return
        end

        if ( client:IsDonator() ) then
            clientTable.OOCLimit = impulse.Config.OOCLimitVIP
        else
            clientTable.OOCLimit = impulse.Config.OOCLimit
        end

        net.Start("impulseUpdateOOCLimit")
            net.WriteUInt(1800, 16)
            net.WriteBool(true)
        net.Send(client)
    end)

    local loadTimerName = "impulseFullLoad." .. client:UserID()
    timer.Create(loadTimerName, 0.5, 0, function()
        if ( !IsValid(client) ) then
            timer.Remove(loadTimerName)
            return
        end

        if ( client:GetModel() != "player/default.mdl" ) then
            timer.Remove(loadTimerName)
            hook.Run("PlayerInitialSpawnLoaded", client)
        end
    end)

    clientTable.impulseAFKTimer = CurTime() + 720
end

function GM:PlayerSetup(client, data)
    local clientTable = client:GetTable()

    local playerCount = player.GetCount()
    local donatorCount = 0
    for k, v in player.Iterator() do
        if ( !IsValid(v) or !v:IsDonator() ) then continue end

        donatorCount = donatorCount + 1
    end

    local userCount = playerCount - donatorCount
    if ( !client:IsDonator() and userCount >= ( impulse.Config.UserSlots or 9999 ) ) then
        local donateURL = impulse.Config.DonateURL
        local message = "The server is currently at full user capacity. Please try again later."
        if ( donateURL and donateURL != "" ) then
            message = message .. " Consider donating at " .. donateURL .. " to gain access to reserved slots."
        end

        client:Kick(message)

        return
    end

    client:SetRelay("roleplayName", data.rpname)

    local xpValue = tonumber(data.xp) or 0
    local moneyValue = tonumber(data.money) or 0
    local bankMoneyValue = tonumber(data.bankmoney) or 0

    client:SetRelay("xp", xpValue)
    client:SetRelay("money", moneyValue)
    client:SetRelay("bankMoney", bankMoneyValue)

    local jsonData = util.JSONToTable(data.data or "") or {}

    clientTable.impulseData = jsonData
    clientTable.impulseID = tonumber(data.id)

    if ( clientTable.impulseData and clientTable.impulseData.Achievements ) then
        local count = table.Count(clientTable.impulseData.Achievements)
        if ( count > 0 ) then
            net.Start("impulseAchievementSync")
            net.WriteUInt(count, 8)

            for k, v in pairs(clientTable.impulseData.Achievements) do
                net.WriteString(k)
                net.WriteUInt(v, 32)
            end

            net.Send(client)
        end

        client:CalculateAchievementPoints()
    end

    local skills = util.JSONToTable(data.skills or "") or {}
    clientTable.impulseSkills = skills

    for k, v in pairs(clientTable.impulseSkills) do
        local xp = client:GetSkillXP(k)
        client:NetworkSkill(k, xp)
    end

    local query = mysql:Update("impulse_players")
    query:Update("ammo", util.TableToJSON(client:GetAmmo()))
    query:Where("steamid", client:SteamID64())
    query:Execute()

    local ammo = util.JSONToTable(data.ammo or "") or {}
    local give = {}

    for k, v in pairs(ammo) do
        local ammoName = game.GetAmmoName(k)
        if ( impulse.Config.SaveableAmmo[ammoName] ) then
            give[ammoName] = v
        end
    end

    clientTable.impulseAmmoToGive = give

    clientTable.impulseDefaultModel = data.model
    clientTable.impulseDefaultSkin = data.skin
    clientTable.impulseDefaultName = data.rpname

    client:UpdateDefaultModelSkin()

    -- Initialize inventory containers and bookkeeping BEFORE SetTeam is called,
    -- as SetTeam may trigger inventory operations (e.g., UnEquipInventory).
    local id = clientTable.impulseID
    impulse.Inventory.Data[id] = {}
    impulse.Inventory.Data[id][INVENTORY_PLAYER] = {}
    impulse.Inventory.Data[id][INVENTORY_STORAGE] = {}

    clientTable.InventoryWeight = 0
    clientTable.InventoryWeightStorage = 0
    clientTable.InventoryRegister = {}
    clientTable.InventoryStorageRegister = {}
    clientTable.InventoryEquipGroups = {}

    client:SetTeam(impulse.Config.DefaultTeam)

    hook.Run("PreEarlyInventorySetup", client)

    local query = mysql:Select("impulse_inventory")
    query:Select("id")
    query:Select("uniqueid")
    query:Select("ownerid")
    query:Select("storagetype")
    query:Where("ownerid", data.id)
    query:Callback(function(result)
        if ( IsValid(client) and type(result) == "table" and #result > 0 ) then
            local userid = clientTable.impulseID
            local userInv = impulse.Inventory.Data[userid]

            for k, v in pairs(result) do
                local netid = impulse.Inventory:ClassToNetID(v.uniqueid)
                if ( !netid ) then continue end -- when items are removed from a live server we will remove them manually in the db, if an item is broken auto doing this would break peoples items

                local storagetype = tonumber(v.storagetype)
                if ( !userInv[storagetype] ) then
                    userInv[storagetype] = {}
                end

                client:GiveItem(v.uniqueid, storagetype, false, true)
            end
        end

        if ( IsValid(client) ) then
            clientTable.impulseBeenInventorySetup = true
            hook.Run("PostInventorySetup", client)
        end
    end)

    query:Execute()

    client:SetupWhitelists()

    local rankColor = impulse.Config.RankColours[client:GetUserGroup()]
    if ( rankColor ) then
        client:SetWeaponColor(Vector(rankColor.r / 255, rankColor.g / 255, rankColor.b / 255))
    end

    local query = mysql:Select("impulse_refunds")
    query:Select("item")
    query:Where("steamid", client:SteamID64())
    query:Callback(function(result)
        if ( IsValid(client) and type(result) == "table" and #result > 0 ) then
            local sid = client:SteamID64()
            local money = 0
            local names = {}

            for k, v in pairs(result) do
                if ( string.sub(v.item, 1, 4) == "buy_" ) then
                    local class = string.sub(v.item, 5)
                    local buyable = impulse.Business.Data[class]

                    impulse.Refunds.Remove(sid, v.item)

                    if !buyable then
                        continue
                    end

                    names[class] = (names[class] or 0) + 1
                    money = money + (buyable.price or 0) + (buyable.refundAdd or 0)
                end
            end

            if ( money == 0 ) then return end

            client:AddBankMoney(money)

            net.Start("impulseGetRefund")
            net.WriteUInt(table.Count(names), 8)
            net.WriteUInt(money, 16)

            for k, v in pairs(names) do
                net.WriteString(k)
                net.WriteUInt(v, 8)
            end

            net.Send(client)
        end
    end)

    query:Execute()

    if ( data.rpgroup ) then
        client:GroupLoad(data.rpgroup, data.rpgrouprank or nil)
    end

    clientTable.impulseBeenSetup = true

    hook.Run("PostSetupPlayer", client)
end

function GM:PlayerLoadout(client)
    if ( client:Team() == 0 ) then return end

    client:SetRunSpeed(impulse.Config.JogSpeed)
    client:SetWalkSpeed(impulse.Config.WalkSpeed)

    client:SetupHands()

    hook.Run("PostPlayerLoadout", client)

    return true
end

function GM:PostSetupPlayer(client)
    local clientTable = client:GetTable()
    clientTable.impulseData.Achievements = clientTable.impulseData.Achievements or {}

    for k, v in pairs(impulse.Config.Achievements) do
        client:AchievementCheck(k)
    end

    client:Spawn()
end

function GM:PlayerInitialSpawnLoaded(client)
    local jailTime = impulse.Arrest.DisconnectRemember[client:SteamID64()]

    local clientTable = client:GetTable()
    if ( clientTable.ammoToGive ) then
        for v, k in pairs(clientTable.ammoToGive) do
            if ( game.GetAmmoID(v) != -1 ) then
                client:GiveAmmo(k, v)
            end
        end

        clientTable.ammoToGive = nil
    end

    if ( jailTime ) then
        client:Arrest()
        client:Jail(jailTime)
        impulse.Arrest.DisconnectRemember[client:SteamID64()] = nil
    end

    local steamID64 = client:SteamID64()
    if ( GExtension and GExtension.Warnings[steamID64] ) then
        local bans = GExtension:GetBans(steamID64)
        local warns = GExtension.Warnings[steamID64]

        net.Start("opsGetRecord")
            net.WriteUInt(table.Count(warns), 8)
            net.WriteUInt(table.Count(bans), 8)
        net.Send(client)
    end
end

function GM:PlayerSpawn(client)
    local clientTable = client:GetTable()
    local cellID = clientTable.InJail

    if ( clientTable.InJail ) then
        local pos = impulse.Config.PrisonCells[cellID]
        client:SetPos(impulse.Util:FindEmptyPos(pos, {self}, 150, 30, Vector(16, 16, 64)))
        client:SetEyeAngles(impulse.Config.PrisonAngle)
        client:Arrest()

        return
    end

    local killSilent = clientTable.IsKillSilent
    if ( killSilent ) then
        clientTable.IsKillSilent = false

        for k, v in pairs(clientTable.TempWeapons) do
            local weapon = client:Give(v.weapon)
            weapon:SetClip1(v.clip)
        end

        for k, v in pairs(clientTable.TempAmmo) do
            client:SetAmmo(v, k)
        end

        if ( clientTable.TempSelected ) then
            client:SelectWeapon(clientTable.TempSelected)
            client:SetWeaponRaised(clientTable.TempSelectedRaised)
        end

        return
    end

    if ( client:GetRelay("arrested", false) ) then
        client:SetRelay("arrested", false)
    end

    if ( client:HasBrokenLegs() ) then
        client:FixLegs()
    end

    if ( clientTable.impulseBeenSetup ) then
        if ( impulse.Config.ResetTeamOnDeath ) then
            client:SetTeam(impulse.Config.DefaultTeam)
        else
            -- yeah i know, not the best fix
            local oldTeam, oldClass, oldRank = client:Team(), client:GetTeamClass(), client:GetTeamRank()
            client:SetTeam(oldTeam)

            -- Only restore class if the team supports classes
            if ( oldClass and oldClass != 0 ) then
                client:SetTeamClass(oldClass)
            end

            if ( oldRank and oldRank != 0 ) then
                client:SetTeamRank(oldRank)
            end
        end

        if ( clientTable.HasDied ) then
            client:SetHunger(math.random(50, 70))
        else
            client:SetHunger(100)
        end
    end

    clientTable.impulseArrestedWeapons = nil
    clientTable.SpawnProtection = true

    client:SetJumpPower(impulse.Config.JumpPower or 160)

    timer.Simple(10, function()
        if ( !IsValid(client) ) then return end

        clientTable.SpawnProtection = false
    end)

    hook.Run("PlayerLoadout", client)
end

function GM:PlayerDisconnected(client)
    local userID = client:UserID()
    local steamID = client:SteamID64()
    local entIndex = client:EntIndex()
    local arrested = client:GetRelay("arrested", false)

    local clientTable = client:GetTable()
    local dragger = clientTable.impulseArrestedDragger
    if ( IsValid(dragger) ) then
        impulse.Arrest.Dragged[client] = nil
        dragger.impulseArrestedDragging = nil
    end

    local loadTimerName = "impulseFullLoad." .. userID
    if ( timer.Exists(loadTimerName) ) then
        timer.Remove(loadTimerName)
    end

    local payTimerName = "impulsePayDay." .. userID
    if ( timer.Exists(payTimerName) ) then
        timer.Remove(payTimerName)
    end

    local jailCell = clientTable.InJail
    if ( jailCell ) then
        timer.Remove("impulsePrison." .. userID)
        local duration = impulse.Arrest.Prison[jailCell][entIndex].duration
        impulse.Arrest.Prison[jailCell][entIndex] = nil
        impulse.Arrest.DisconnectRemember[steamID] = duration
    elseif ( clientTable.impulseBeingJailed ) then
        impulse.Arrest.DisconnectRemember[steamID] = clientTable.impulseBeingJailed
    elseif ( arrested ) then
        impulse.Arrest.DisconnectRemember[steamID] = impulse.Config.MaxJailTime
    end

    if ( clientTable.CanHear ) then
        for k, v in player.Iterator() do
            if ( !v.CanHear ) then continue end
            v.CanHear[client] = nil
        end
    end

    if ( clientTable.impulseID ) then
        impulse.Inventory.Data[clientTable.impulseID] = nil

        if ( !client:IsCP() ) then
            local query = mysql:Update("impulse_players")
            query:Update("ammo", util.TableToJSON(client:GetAmmo()))
            query:Where("steamid", steamID)
            query:Execute()
        end
    end

    if ( clientTable.impulseOwnedDoors ) then
        for k, v in pairs(clientTable.impulseOwnedDoors) do
            if ( !IsValid(k) ) then continue end

            if ( k:GetDoorMaster() == client ) then
                local noUnlock = k.NoDCUnlock or false
                client:RemoveDoorMaster(k, noUnlock)
            else
                client:RemoveDoorUser(k)
            end
        end
    end

    if ( IsValid(clientTable.impulseInventorySearching) ) then
        clientTable.impulseInventorySearching:Freeze(false)
    end

    for k, v in pairs(ents.FindByClass("impulse_item")) do
        if ( v.ItemOwner and v.ItemOwner == client ) then
            v.RemoveIn = CurTime() + impulse.Config.InventoryItemDeSpawnTime
        end
    end

    impulse.Refunds.RemoveAll(steamID)
end

function GM:ShowHelp()
    return
end

local talkCol = Color(255, 255, 100)
local infoCol = Color(135, 206, 250)
local strTrim = string.Trim
function GM:PlayerSay(client, text, teamChat, newChat)
    local clientTable = client:GetTable()
    if ( !clientTable.impulseBeenSetup or teamChat ) then return "" end

    text = strTrim(text, " ")

    hook.Run("PostPlayerSay", client, text)

    if ( string.StartWith(text, "/") ) then
        local args = string.Explode(" ", text)
        local command = impulse.chatCommands[string.lower(args[1])]
        if ( command ) then
            if ( command.cooldown and command.lastRan ) then
                if ( command.lastRan + command.cooldown > CurTime() ) then
                    return ""
                end
            end

            if ( command.adminOnly and !client:IsAdmin() ) then
                client:Notify("You must be an admin to use this command.")
                return ""
            end

            if ( command.leadAdminOnly and !client:IsLeadAdmin() ) then
                client:Notify("You must be a lead admin to use this command.")
                return ""
            end

            if ( command.superAdminOnly and !client:IsSuperAdmin() ) then
                client:Notify("You must be a super admin to use this command.")
                return ""
            end

            if ( command.requiresArg and ( !args[2] or string.Trim(args[2]) == "" ) ) then return "" end
            if ( command.requiresAlive and !client:Alive() ) then return "" end

            text = string.sub(text, string.len(args[1]) + 2)

            table.remove(args, 1)
            command.onRun(client, args, text)
        else
            client:Notify("The " .. args[1] .. " command does not exist.")
        end
    elseif ( client:Alive() ) then
        text = hook.Run("ProcessICChatMessage", client, text) or text
        text = hook.Run("ChatClassMessageSend", 1, text, client) or text

        for k, v in player.Iterator() do
            if ( client:GetPos() - v:GetPos() ):LengthSqr() <= ( impulse.Config.TalkDistance ^ 2 ) then
                v:SendChatClassMessage(1, text, client)
            end
        end

        hook.Run("PostChatClassMessageSend", 1, text, client)
    end

    return ""
end

local voiceDistance
local function CalcPlayerCanHearPlayersVoice(listener)
    if ( !IsValid(listener) ) then return end

    if ( !voiceDistance ) then
        voiceDistance = impulse.Config.VoiceDistance ^ 2
    end

    listener.impulseVoiceHear = listener.impulseVoiceHear or {}

    local eyePos = listener:EyePos()
    for _, speaker in player.Iterator() do
        local speakerEyePos = speaker:EyePos()
        listener.impulseVoiceHear[speaker] = eyePos:DistToSqr(speakerEyePos) < voiceDistance
    end
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    if ( !speaker:Alive() ) then return false end

    local bCanHear = listener.impulseVoiceHear and listener.impulseVoiceHear[speaker]
    return bCanHear, true
end

function GM:DoPlayerDeath(client, attacker, dmginfo)
    local ragCount = table.Count(ents.FindByClass("prop_ragdoll"))
    if ( ragCount > 32 ) then
        logs:Debug("Avoiding ragdoll body spawn for performance reasons... (rag count: " .. ragCount .. ")")
        return
    end

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(client:GetModel())
    ragdoll:SetPos(client:GetPos())
    ragdoll:SetSkin(client:GetSkin())
    ragdoll.DeadPlayer = client
    ragdoll.Killer = attacker
    ragdoll.DmgInfo = dmginfo

    local clientTable = client:GetTable()
    if ( clientTable.impulseLastFall and clientTable.impulseLastFall > CurTime() - 0.5 ) then
        ragdoll.FallDeath = true
    end

    if ( IsValid(attacker) and attacker:IsPlayer() ) then
        local weapon = attacker:GetActiveWeapon()
        if ( IsValid(weapon) ) then
            ragdoll.DmgWep = weapon:GetClass()
        end
    end

    ragdoll.CanConstrain = false
    ragdoll.NoCarry = true

    for k, v in pairs(client:GetBodyGroups()) do
        ragdoll:SetBodygroup(v.id, client:GetBodygroup(v.id))
    end

    hook.Run("PrePlayerDeathRagdoll", client, ragdoll)

    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local velocity = client:GetVelocity()
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local physObj = ragdoll:GetPhysicsObjectNum(i)
        if ( IsValid(physObj) ) then
            physObj:SetVelocity(velocity)

            local index = ragdoll:TranslatePhysBoneToBone(i)
            if ( index ) then
                local pos, ang = client:GetBonePosition(index)

                physObj:SetPos(pos)
                physObj:SetAngles(ang)
            end
        end
    end

    hook.Run("PostPlayerDeathRagdoll", client, ragdoll)

    timer.Simple(impulse.Config.BodyDeSpawnTime, function()
        if ( !IsValid(ragdoll) ) then return end

        ragdoll:Fire("FadeAndRemove", 7)

        timer.Simple(10, function()
            SafeRemoveEntity(ragdoll)

            hook.Run("OnPlayerRagdollRemove", client, ragdoll)
        end)
    end)

    timer.Simple(0.1, function()
        if ( !IsValid(ragdoll) or !IsValid(client) ) then return end

        net.Start("impulseRagdollLink")
            net.WriteEntity(ragdoll)
        net.Send(client)
    end)

    return true
end

function GM:PlayerDeath(client, killer)
    local wait = impulse.Config.RespawnTime
    if ( client:IsDonator() ) then
        wait = impulse.Config.RespawnTimeDonator
    end

    local clientTable = client:GetTable()
    clientTable.impulseRespawnWait = CurTime() + wait

    local money = client:GetMoney()
    if ( money > 0 ) then
        client:SetMoney(0)
        impulse.Currency:SpawnMoney(client:GetPos(), money)
    end

    if ( !clientTable.impulseBeenInventorySetup ) then
        return
    end

    client:UnEquipInventory()

    local shouldSpawn = hook.Run("PlayerShouldDropDeathItems", client, killer)
    if ( shouldSpawn != false ) then
        local inv = client:GetInventory()
        local restorePoint = {}
        local pos = client:LocalToWorld(client:OBBCenter())
        local dropped = 0

        for k, v in pairs(inv) do
            local class = impulse.Inventory:ClassToNetID(v.class)
            local item = impulse.Inventory.Items[class]

            if ( !v.restricted ) then
                table.insert(restorePoint, v.class)
            end

            if ( item.DropOnDeath and !v.restricted ) then
                local ent = impulse.Inventory:SpawnItem(v.class, pos)
                ent.ItemClip = v.clip

                dropped = dropped + 1

                if ( dropped > 4 ) then
                    break
                end
            end
        end

        hook.Run("PlayerDropDeathItems", client, killer, pos, dropped, inv)

        clientTable.InventoryRestorePoint = restorePoint
    end

    client:ClearInventory(1)
    clientTable.HasDied = true
end

function GM:PlayerSilentDeath(client)
    local clientTable = client:GetTable()
    clientTable.IsKillSilent = true
    clientTable.TempWeapons = {}

    for k, v in pairs(client:GetWeapons()) do
        clientTable.TempWeapons[k] = {weapon = v:GetClass(), clip = v:Clip1()}
    end

    clientTable.TempAmmo = client:GetAmmo()

    local weapon = client:GetActiveWeapon()
    if ( IsValid(weapon) ) then
        clientTable.TempSelected = weapon:GetClass()
        clientTable.TempSelectedRaised = client:IsWeaponRaised()
    end
end

local nextDeathThink = 0
function GM:PlayerDeathThink(client)
    local curTime = CurTime()
    if ( curTime < nextDeathThink ) then return end
    nextDeathThink = curTime + 0.5

    local clientTable = client:GetTable()
    if ( !clientTable.impulseRespawnWait or clientTable.impulseRespawnWait < CurTime() ) then
        client:Spawn()
    end

    return true
end

function GM:PlayerDeathSound()
    return true
end

function GM:CanPlayerSuicide()
    return false
end

function GM:OnPlayerChangedTeam(client)
    local clientTable = client:GetTable()
    if ( clientTable.BuyableTeamRemove ) then
        for k, v in pairs(clientTable.BuyableTeamRemove) do
            if ( isentity(v) and IsValid(v) and v.BuyableOwner == client ) then
                SafeRemoveEntity(v)
            end
        end
    end
end

function GM:SetupPlayerVisibility(client)
    local clientTable = client:GetTable()
    if ( clientTable.extraPVS ) then
        AddOriginToPVS(clientTable.extraPVS)
    end

    if ( clientTable.extraPVS2 ) then
        AddOriginToPVS(clientTable.extraPVS2)
    end
end

function GM:KeyPress(client, key)
    if ( client:IsAFK() ) then
        client:UnMakeAFK()
    end

    local clientTable = client:GetTable()
    clientTable.impulseAFKTimer = CurTime() + impulse.Config.AFKTime

    if ( key == IN_RELOAD ) then
        timer.Create("impulseRaiseWait" .. client:SteamID64(), impulse.Config.WeaponRaiseTime or 0.3, 1, function()
            if ( IsValid(client) ) then
                client:ToggleWeaponRaised()
            end
        end)
    elseif ( key == IN_USE and !client:InVehicle() ) then
        local trace = {}
        trace.start = client:GetShootPos()
        trace.endpos = trace.start + client:GetAimVector() * 96
        trace.filter = client

        local entity = util.TraceLine(trace).Entity
        if ( IsValid(entity) and entity:IsPlayer() and client:CanArrest(entity) ) then
            if ( !entity.impulseArrestedDragger ) then
                client:DragPlayer(entity)
            else
                entity:StopDrag()
            end
        end
    end
end

function GM:PlayerUse(client, entity)
    local clientTable = client:GetTable()
    if ( ( clientTable.useNext or 0)  > CurTime() ) then return false end
    clientTable.useNext = CurTime() + 0.3

    local buttons = impulse.Config.Buttons
    if ( !buttons or table.Count(buttons) < 1 ) then return end

    local btnKey = entity.impulseButtonCheck
    if ( !btnKey ) then return end

    local btnData = impulse.Config.Buttons[btnKey]
    if ( !btnData ) then return end

    if ( btnData.customCheck and !btnData.customCheck(client, entity) ) then
        clientTable.useNext = CurTime() + 1
        return false
    end

    if ( btnData.doorgroup ) then
        local teamDoorGroups = clientTable.DoorGroups
        if ( !teamDoorGroups or !table.HasValue(teamDoorGroups, btnData.doorgroup) ) then
            clientTable.useNext = CurTime() + 1
            client:Notify("You don't have access to use this button.")
            return false
        end
    end
end

function GM:KeyRelease(client, key)
    if ( key == IN_RELOAD ) then
        timer.Remove("impulseRaiseWait" .. client:SteamID64())
    end
end

local function LoadButtons()
    impulse.ActiveButtons = impulse.ActiveButtons or {}

    for k, v in ipairs(ents.FindByClass("func_button")) do
        if ( !IsValid(v) or v.impulseButtonCheck ) then continue end

        v.impulseButtonCheck = true
    end

    if ( !impulse.Config.Buttons or table.Count(impulse.Config.Buttons) < 1 ) then return end

    for k, v in pairs(ents.FindByClass("func_button")) do
        if ( !IsValid(v) or !v.impulseButtonCheck ) then continue end

        for k2, v2 in pairs(impulse.Config.Buttons) do
            if ( v2.pos:DistToSqr(v:GetPos()) < ( 9 ^ 2 ) ) then -- getpos client/server innaccuracy
                v.impulseButtonCheck = k2
                impulse.ActiveButtons[v:EntIndex()] = k2

                if ( v2.init ) then
                    v2.init(v)
                end
            end
        end
    end
end

function GM:InitPostEntity()
    impulse.Doors:Load()

    local doors = ents.FindByClass("prop_door_rotating")
    for _, v in ipairs(doors) do
        local parent = v:GetOwner()

        if ( IsValid(parent) ) then
            v.impulsePartner = parent
            parent.impulsePartner = v
        else
            for _, v2 in ipairs(doors) do
                if ( v2:GetOwner() == v ) then
                    v2.impulsePartner = v
                    v.impulsePartner = v2

                    break
                end
            end
        end
    end

    for k, v in ents.Iterator() do
        if ( v.impulseSaveEnt or v.IsZoneTrigger ) then
            SafeRemoveEntity(v)
        end
    end

    if ( impulse.Config.LoadScript ) then
        impulse.Config.LoadScript()
    end

    if ( impulse.Config.Zones ) then
        for k, v in pairs(impulse.Config.Zones) do
            local zone = ents.Create("impulse_zone")
            zone:SetBounds(v.pos1, v.pos2)
            zone.Zone = k
        end
    end

    if ( impulse.Config.BlacklistEnts ) then
        for k, v in pairs(impulse.Config.BlacklistEnts) do
            for _, ent in ipairs(ents.FindByClass(k)) do
                SafeRemoveEntity(ent)
            end
        end
    end

    impulse.Save:Load()

    LoadButtons()

    hook.Run("PostInitPostEntity")
end

function GM:PostCleanupMap()
    -- After a cleanup, some map entities (doors/buttons) may not be fully re-created
    -- in the same tick. Defer reinitialisation to the next frame to ensure reliability.
    timer.Simple(0, function()
        hook.Run("InitPostEntity")
    end)
end

function GM:GetFallDamage(client, speed)
    local clientTable = client:GetTable()
    clientTable.impulseLastFall = CurTime()

    local dmg = speed * 0.05
    if ( speed > 780 ) then
        dmg = dmg + 75
    end

    local shouldBreakLegs = hook.Run("PlayerShouldBreakLegs", client, dmg)
    if ( shouldBreakLegs != nil and shouldBreakLegs == false ) then
        return dmg
    end

    local strength = client:GetSkillLevel("strength")
    local r = math.random(0, 20 + (strength * 2))
    if ( r <= 20 and dmg < client:Health() ) then
        client:BreakLegs()
    end

    return dmg
end

function GM:Think()
    for k, v in player.Iterator() do
        hook.Run("PlayerThink", v)
    end

    for k, v in pairs(impulse.Arrest.Dragged) do
        if ( !IsValid(k) ) then
            impulse.Arrest.Dragged[k] = nil
            continue
        end

        local dragger = k.impulseArrestedDragger
        if ( IsValid(dragger) ) then
            if ( dragger:GetPos() - k:GetPos()):LengthSqr() >= ( 192 ^ 2 ) then
                k:StopDrag()
            end
        else
            k:StopDrag()
        end
    end
end

local nextAFK = 0
function GM:PlayerThink(client)
    local curTime = CurTime()
    if ( !IsValid(client) or client:Team() == 0 ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable.impulseNextHunger ) then
        clientTable.impulseNextHunger = curTime + impulse.Config.HungerTime
    end

    if ( !clientTable.impulseNextHeal ) then
        clientTable.impulseNextHeal = curTime + impulse.Config.HungerHealTime
    end

    if ( client:Alive() ) then
        if ( clientTable.impulseNextHunger < curTime ) then
            local shouldTakeHunger = hook.Run("PlayerShouldGetHungry", client)
            if ( shouldTakeHunger == nil or shouldTakeHunger ) then
                client:TakeHunger(1)
            end

            if ( client:GetHunger() < 1 ) then
                if ( client:Health() > 10 ) then
                    client:TakeDamage(1, client, client)
                end

                clientTable.impulseNextHunger = curTime + 1
            else
                clientTable.impulseNextHunger = curTime + impulse.Config.HungerTime
            end
        end

        if ( clientTable.impulseNextHeal < curTime ) then
            local hunger = client:GetHunger()
            if ( hunger >= 90 and client:Health() < 75 ) then
                client:SetHealth(math.Clamp(client:Health() + 1, 0, 75))
                clientTable.impulseNextHeal = curTime + impulse.Config.HungerHealTime
            else
                clientTable.impulseNextHeal = curTime + 2
            end
        end
    end

    if ( !clientTable.impulseNextHear or clientTable.impulseNextHear < CurTime() ) then
        CalcPlayerCanHearPlayersVoice(client)
        clientTable.impulseNextHear = curTime + 0.33
    end

    if ( curTime > nextAFK ) then
        nextAFK = curTime + 1

        if ( clientTable.impulseAFKTimer and clientTable.impulseAFKTimer < curTime and !impulse.Arrest.Dragged[client] and !client:IsAFK() ) then
            client:MakeAFK()
        end

        clientTable.impulseLastPos = client:GetPos()

        if ( client:HasBrokenLegs() and client:GetBrokenLegsStartTime() + impulse.Config.BrokenLegsHealTime < curTime ) then
            client:FixLegs()
            client:Notify("Your broken legs have healed naturally.")
        end
    end

    if ( ( clientTable.impulseNextAmbientSound or 0 ) < CurTime() ) then
        local ambientSound = client:GetAmbientSound()
        if ( ambientSound and ambientSound != "" ) then
            client:EmitSound(ambientSound, 60, nil, 0.25, CHAN_AUTO)

            clientTable.impulseNextAmbientSound = CurTime() + math.random(30, 120)
        end
    end
end

function GM:PlayerCanPickupWeapon(client)
    if ( client:GetRelay("arrested", false) ) then return false end

    return true
end

local exploitRagBlock = {
    ["models/dpfilms/metropolice/playermodels/pm_zombie_police.mdl"] = true,
    ["models/dpfilms/metropolice/zombie_police.mdl"] = true,
    ["models/zombie/zmanims.mdl"] = true
}

function GM:PlayerSpawnRagdoll(client, model)
    if ( exploitRagBlock[model] ) then return false end

    return client:IsLeadAdmin()
end

function GM:PlayerSpawnSENT(client)
    return client:IsSuperAdmin()
end

function GM:PlayerSpawnSWEP(client)
    return client:IsSuperAdmin()
end

function GM:PlayerGiveSWEP(client)
    return client:IsSuperAdmin()
end

function GM:PlayerSpawnEffect(client)
    return client:IsAdmin()
end

function GM:PlayerSpawnNPC(client)
    return client:IsSuperAdmin() or ( client:IsAdmin() and impulse.Ops.EventManager.GetEventMode() )
end

function GM:PlayerSpawnProp(client, model)
    local clientTable = client:GetTable()
    if ( !client:Alive() or !clientTable.impulseBeenSetup or client:GetRelay("arrested", false) ) then return false end

    if ( client:IsAdmin() ) then return true end

    local limit
    local price

    if ( client:IsDonator() ) then
        limit = impulse.Config.PropLimitDonator
        price = impulse.Config.PropPriceDonator
    else
        limit = impulse.Config.PropLimit
        price = impulse.Config.PropPrice
    end

    if ( client:GetPropCount(true) >= limit ) then
        client:Notify("You have reached your prop limit.")
        return false
    end

    if ( price > 0 ) then
        if ( client:CanAfford(price) ) then
            client:TakeMoney(price)
            client:Notify("You have purchased a prop for " .. impulse.Config.CurrencyPrefix .. price .. ".")
        else
            client:Notify("You need " .. impulse.Config.CurrencyPrefix .. price .. " to spawn this prop.")
            return false
        end
    end

    return true
end

function GM:PlayerSpawnedProp(client, model, ent)
    client:AddPropCount(ent)
end

function GM:PlayerSpawnVehicle(client, model)
    if ( client:GetRelay("arrested", false) ) then return false end

    if ( client:IsDonator() and ( model:find("chair") or model:find("seat") or model:find("pod") ) ) then
        local clientTable = client:GetTable()
        local count = 0
        clientTable.SpawnedVehicles = clientTable.SpawnedVehicles or {}

        for k, v in pairs(clientTable.SpawnedVehicles) do
            if ( IsValid(v) ) then
                count = count + 1
            else
                clientTable.SpawnedVehicles[k] = nil
            end
        end

        if ( count >= impulse.Config.ChairsLimit ) then
            client:Notify("You have spawned the maximum amount of chairs.")
            return false
        end

        return true
    else
        return client:IsSuperAdmin()
    end
end

function GM:PlayerSpawnedVehicle(client, ent)
    local clientTable = client:GetTable()
    clientTable.SpawnedVehicles = clientTable.SpawnedVehicles or {}

    table.insert(clientTable.SpawnedVehicles, ent)
end

function GM:CanDrive()
    return false
end

local whitelistProp = {
    ["bodygroups"] = true,
    ["collision"] = true,
    ["remover"] = true,
    ["skin"] = true
}

local adminProp = {
    ["extinguish"] = true,
    ["ignite"] = true,
}

function GM:CanProperty(client, prop)
    if ( whitelistProp[prop] ) then return true end
    if ( client:IsAdmin() and adminProp[prop] ) then return true end

    return client:IsSuperAdmin()
end

local bannedTools = {
    ["duplicator"] = true,
    ["dynamite"] = true,
    ["eyeposer"] = true,
    ["faceposer"] = true,
    ["fingerposer"] = true,
    ["inflator"] = true,
    ["paint"] = true,
    ["physprop"] = true,
    ["trails"] = true,
    ["wire_detonator"] = true,
    ["wire_detonators"] = true,
    ["wire_explosive"] = true,
    ["wire_eyepod"] = true,
    ["wire_field_device"] = true,
    ["wire_hsholoemitter"] = true,
    ["wire_hsranger"] = true,
    ["wire_magnet"] = true,
    ["wire_pod"] = true,
    ["wire_simple_explosive"] = true,
    ["wire_spu"] = true,
    ["wire_teleporter"] = true,
    ["wire_trail"] = true,
    ["wire_trigger"] = true,
    ["wire_turret"] = true,
    ["wire_user"] = true,
    ["wnpc"] = true
}

local dupeBannedTools = {
    ["adv_duplicator"] = true,
    ["duplicator"] = true,
    ["spawner"] = true,
    ["weld"] = true,
    ["weld_ez"] = true
}

local donatorTools = {
    ["wire_egp"] = true,
    ["wire_expression2"] = true,
    ["wire_soundemitter"] = true
}

local adminWorldRemoveWhitelist = {
    ["impulse_item"] = true,
    ["impulse_letter"] = true,
    ["impulse_money"] = true,
    ["prop_physics"] = true,
    ["prop_ragdoll"] = true
}

function GM:CanTool(client, tr, tool)
    if ( !client:IsAdmin() and tool == "spawner" ) then return false end

    if ( bannedTools[tool] ) then return false end

    if ( donatorTools[tool] and !client:IsDonator() ) then
        client:Notify("This tool is restricted to donators only.")
        return false
    end

    local ent = tr.Entity
    if ( IsValid(ent) ) then
        if ( ent.onlyremover ) then
            if ( tool == "remover" ) then
                return client:IsAdmin() or client:IsSuperAdmin()
            else
                return false
            end
        end

        if ( ent.nodupe and dupeBannedTools[tool] ) then
            return false
        end

        if ( tool == "remover" and client:IsAdmin() and !client:IsSuperAdmin() ) then
            local owner = ent:CPPIGetOwner()
            if ( !owner and !adminWorldRemoveWhitelist[ent:GetClass()] ) then
                client:Notify("You can not remove this entity.")
                return false
            end
        end

        if ( string.StartsWith(ent:GetClass(), "impulse_") ) then
            if ( tool != "remover" and !client:IsSuperAdmin() ) then
                return false
            end
        end
    end

    return true
end

local bannedDupeEnts = {
    ["gmod_wire_detonator"] = true,
    ["gmod_wire_explosive"] = true,
    ["gmod_wire_eyepod"] = true,
    ["gmod_wire_hsholoemitter"] = true,
    ["gmod_wire_hsranger"] = true,
    ["gmod_wire_realmagnet"] = true,
    ["gmod_wire_rtcam"] = true,
    ["gmod_wire_simple_explosive"] = true,
    ["gmod_wire_spu"] = true,
    ["gmod_wire_teleporter"] = true,
    ["gmod_wire_thruster"] = true,
    ["gmod_wire_trail"] = true,
    ["gmod_wire_trigger"] = true,
    ["gmod_wire_trigger_entity"] = true,
    ["gmod_wire_turret"] = true,
    ["gmod_wire_user"] = true
}

local donatorDupeEnts = {
    ["gmod_wire_epg"] = true,
    ["gmod_wire_expression2"] = true,
    ["gmod_wire_soundemitter"] = true,
    ["prop_vehicle_prisoner_pod"] = true
}

local whitelistDupeEnts = {
    ["gmod_button"] = true,
    ["gmod_emitter"] = true,
    ["gmod_lamp"] = true,
    ["gmod_light"] = true,
    ["gmod_wheel"] = true,
    ["prop_door_rotating"] = true,
    ["prop_dynamic"] = true,
    ["prop_physics"] = true
}

function GM:ADVDupeIsAllowed(client, class, entclass) -- adv dupe 2 can be easily exploited, this fixes it. you must have the impulse version of AD2 for this to work
    if ( bannedDupeEnts[class] ) then return false end

    if ( donatorDupeEnts[class] ) then
        if ( client:IsDonator() ) then
            return true
        else
            client:Notify("This entity is restricted to donators only.")
            return false
        end
    end

    if ( whitelistDupeEnts[class] or string.sub(class, 1, 9) == "gmod_wire" ) then return true end

    return false
end

function GM:SetupMove(client, mvData)
    local clientTable = client:GetTable()
    if ( IsValid(clientTable.impulseArrestedDragging) ) then
        mvData:SetMaxClientSpeed(impulse.Config.WalkSpeed - 30)
    end
end

function GM:CanPlayerEnterVehicle(client, veh)
    local clientTable = client:GetTable()
    if ( client:GetRelay("arrested", false) ) or clientTable.impulseArrestedDragging then return false end

    return true
end

function GM:CanExitVehicle(veh, client)
    if ( client:GetRelay("arrested", false) ) then return false end

    return true
end

function GM:PlayerSetHandsModel(client, hands)
    local handModel = impulse.Teams.Stored[client:Team()].handModel
    if ( handModel ) then
        hands:SetModel(handModel)
        return
    end

    local simplemodel = player_manager.TranslateToPlayerModelName(client:GetModel())
    local info = player_manager.TranslatePlayerHands(simplemodel)
    if ( info ) then
        hands:SetModel(info.model)
        hands:SetSkin(info.skin)
        hands:SetBodyGroups(info.body)
    end
end

function GM:PlayerSpray()
    return true
end

function GM:PlayerShouldTakeDamage(client, attacker)
    if ( client:Team() == 0 ) then return false end

    local clientTable = client:GetTable()
    if clientTable.SpawnProtection and attacker:IsPlayer() then return false end

    if ( attacker and IsValid(attacker) and attacker:IsPlayer() and attacker != Entity(0) and attacker != client ) then
        local curTime = CurTime()
        if ( ( clientTable.impulseNextStorage or 0 ) < curTime ) then
            clientTable.impulseNextStorage = curTime + 60
        end

        attacker.impulseNextStorage = curTime + 180
    end

    return true
end

function GM:LongswordCalculateMeleeDamage(client, damage, ent)
    local skill = client:GetSkillLevel("strength")
    local dmg = damage * (1 + (skill * .059))
    local override = hook.Run("CalculateMeleeDamage", client, dmg, ent)

    return override or dmg
end

function GM:LongswordMeleeHit(client)
    local clientTable = client:GetTable()
    if ( clientTable.impulseStrengthUp and clientTable.impulseStrengthUp > 5 ) then
        client:AddSkillXP("strength", math.random(1, 6))
        clientTable.impulseStrengthUp = 0
        return
    end

    clientTable.impulseStrengthUp = ( clientTable.impulseStrengthUp or 0 ) + 1
end

function GM:LongswordHitEntity(client, ent)
    -- if tree then vood ect.
end
