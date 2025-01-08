function GM:PlayerUseSpawnSaver(ply)
    return false
end

function GM:DatabaseConnected()
    -- Create the SQL tables if they do not exist.
    impulse.Database:LoadTables()

    MsgC(Color(0, 255, 0), "Database Type: " .. impulse.Database.Config.adapter .. ".\n")

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

function GM:PlayerInitialSpawn(ply)
    local isNew = false
    local plyTable = ply:GetTable()

    ply:SetCanZoom(false)

    ply:LoadData(function(data)
        if ( !IsValid(ply) ) then return end
    
        local address = impulse.Util:GetAddress()
        local bNoCache = ply:GetData("lastIP", address) != address
        ply:SetData("lastIP", address)

        net.Start("impulseDataSync")
            net.WriteTable(data or {})
            net.WriteUInt(plyTable.impulsePlayTime or 0, 32)
        net.Send(ply)

        local query = mysql:Select("impulse_players")
        query:Select("id")
        query:Select("rpname")
        query:Select("group")
        query:Select("rpgroup")
        query:Select("rpgrouprank")
        query:Select("xp")
        query:Select("money")
        query:Select("bankmoney")
        query:Select("model")
        query:Select("skin")
        query:Select("data")
        query:Select("skills")
        query:Select("ammo")
        query:Select("firstjoin")
        query:Select("lastjoin")
        query:Select("address")
        query:Select("playtime")
        query:Where("steamid", ply:SteamID64())
        query:Callback(function(result)
            if ( !IsValid(ply) ) then return end

            local db = result[1]

            -- Set the isNew flag to false if the player has already joined the server.
            isNew = db.rpname == nil or db.rpname == ""
    
            net.Start("impulseChatText")
                net.WriteTable({Color(150, 150, 200), ply:SteamName() .. " has connected to the server."})
            net.Broadcast()
    
            if ( isNew ) then
                net.Start("impulseJoinData")
                    net.WriteBool(isNew)
                net.Send(ply)
    
                ply:Freeze(true)
                hook.Run("PlayerFirstJoin", ply, db)
            else
                ply:Freeze(false)
                hook.Run("PlayerSetup", ply, db)
            end
        end)

        query:Execute()
    end)

    local xpTimerName = "impulseXP." .. ply:UserID()
    timer.Create(xpTimerName, impulse.Config.XPTime, 0, function()
        if ( !IsValid(ply) ) then
            timer.Remove(xpTimerName)
            return
        end

        if ( !ply:IsAFK() ) then
            ply:GiveTimedXP()
        end
    end)

    local oocTimerName = "impulseOOCLimit." .. ply:UserID()
    timer.Create(oocTimerName, 1800, 0, function()
        if ( !IsValid(ply) ) then
            timer.Remove(oocTimerName)
            return
        end

        if ( ply:IsDonator() ) then
            plyTable.OOCLimit = impulse.Config.OOCLimitVIP
        else
            plyTable.OOCLimit = impulse.Config.OOCLimit
        end

        net.Start("impulseUpdateOOCLimit")
            net.WriteUInt(1800, 16)
            net.WriteBool(true)
        net.Send(ply)
    end)

    local loadTimerName = "impulseFullLoad." .. ply:UserID()
    timer.Create(loadTimerName, 0.5, 0, function()
        if ( !IsValid(ply) ) then
            timer.Remove(loadTimerName)
            return
        end

        if ( ply:GetModel() != "player/default.mdl" ) then
            timer.Remove(loadTimerName)
            hook.Run("PlayerInitialSpawnLoaded", ply)
        end
    end)

    plyTable.impulseAFKTimer = CurTime() + 720
end

function GM:PlayerSetup(ply, data)
    local plyTable = ply:GetTable()

    local playerCount = player.GetCount()
    local donatorCount = 0
    for k, v in player.Iterator() do
        if ( !IsValid(v) or !v:IsDonator() ) then continue end

        donatorCount = donatorCount + 1
    end

    local userCount = playerCount - donatorCount
    if ( !ply:IsDonator() and userCount >= ( impulse.Config.UserSlots or 9999 ) ) then
        local donateURL = impulse.Config.DonateURL
        local message = "The server is currently at full user capacity. Please try again later."
        if ( donateURL and donateURL != "" ) then
            message = message .. " Consider donating at " .. donateURL .. " to gain access to reserved slots."
        end

        ply:Kick(message)

        return
    end

	ply:SetNetVar("roleplayName", data.rpname)
	ply:SetNetVar("xp", data.xp)

	ply:SetNetVar("money", data.money)
	ply:SetNetVar("bankMoney", data.bankmoney)

    local jsonData = util.JSONToTable(data.data or "") or {}

    plyTable.impulseData = jsonData
    plyTable.impulseID = data.id

    if ( plyTable.impulseData and plyTable.impulseData.Achievements ) then
        local count = table.Count(plyTable.impulseData.Achievements)
        if ( count > 0 ) then
            net.Start("impulseAchievementSync")
            net.WriteUInt(count, 8)

            for k, v in pairs(plyTable.impulseData.Achievements) do
                net.WriteString(k)
                net.WriteUInt(v, 32)
            end

            net.Send(ply)
        end

        ply:CalculateAchievementPoints()
    end

    local skills = util.JSONToTable(data.skills or "") or {}
    plyTable.impulseSkills = skills

    for k, v in pairs(plyTable.impulseSkills) do
        local xp = ply:GetSkillXP(k)
        ply:NetworkSkill(k, xp)
    end

    local query = mysql:Update("impulse_players")
    query:Update("ammo", util.TableToJSON(ply:GetAmmo()))
    query:Where("steamid", ply:SteamID64())
    query:Execute()

    local ammo = util.JSONToTable(data.ammo or "") or {}
    local give = {}

    for k, v in pairs(ammo) do
        local ammoName = game.GetAmmoName(k)
        if ( impulse.Config.SaveableAmmo[ammoName] ) then
            give[ammoName] = v
        end
    end

    plyTable.impulseAmmoToGive = give

    plyTable.impulseDefaultModel = data.model
    plyTable.impulseDefaultSkin = data.skin
    plyTable.impulseDefaultName = data.rpname

    ply:UpdateDefaultModelSkin()
    ply:SetTeam(impulse.Config.DefaultTeam)

    local id = plyTable.impulseID
    impulse.Inventory.Data[id] = {}
    impulse.Inventory.Data[id][INVENTORY_PLAYER] = {}
    impulse.Inventory.Data[id][INVENTORY_STORAGE] = {}

    plyTable.InventoryWeight = 0
    plyTable.InventoryWeightStorage = 0
    plyTable.InventoryRegister = {}
    plyTable.InventoryStorageRegister = {}
    plyTable.InventoryEquipGroups = {}

    hook.Run("PreEarlyInventorySetup", ply)

    local query = mysql:Select("impulse_inventory")
    query:Select("id")
    query:Select("uniqueid")
    query:Select("ownerid")
    query:Select("storagetype")
    query:Where("ownerid", data.id)
    query:Callback(function(result)
        if ( IsValid(ply) and type(result) == "table" and #result > 0 ) then
            local userid = plyTable.impulseID
            local userInv = impulse.Inventory.Data[userid]

            for k, v in pairs(result) do
                local netid = impulse.Inventory:ClassToNetID(v.uniqueid)
                if ( !netid ) then continue end -- when items are removed from a live server we will remove them manually in the db, if an item is broken auto doing this would break peoples items

                local storagetype = v.storagetype
                if ( !userInv[storagetype] ) then
                    userInv[storagetype] = {}
                end
                
                ply:GiveItem(v.uniqueid, v.storagetype, false, true)
            end
        end

        if ( IsValid(ply) ) then
            plyTable.impulseBeenInventorySetup = true
            hook.Run("PostInventorySetup", ply)
        end
    end)

    query:Execute()

    ply:SetupWhitelists()

    local rankColor = impulse.Config.RankColours[ply:GetUserGroup()]
    if ( rankColor ) then
        ply:SetWeaponColor(Vector(rankColor.r / 255, rankColor.g / 255, rankColor.b / 255))
    end

    local query = mysql:Select("impulse_refunds")
    query:Select("item")
    query:Where("steamid", ply:SteamID64())
    query:Callback(function(result)
        if ( IsValid(ply) and type(result) == "table" and #result > 0 ) then
            local sid = ply:SteamID64()
            local money = 0
            local names = {}

            for k, v in pairs(result) do
                if ( string.sub(v.item, 1, 4) == "buy_" ) then
                    local class = string.sub(v.item, 5)
                    local buyable = impulse.Business.Data[class]

                    impulse.Refunds.Remove(sid, v.item)

                    if not buyable then
                        continue
                    end

                    names[class] = (names[class] or 0) + 1
                    money = money + (buyable.price or 0) + (buyable.refundAdd or 0)
                end
            end

            if ( money == 0 ) then return end

            ply:GiveBankMoney(money)
            
            net.Start("impulseGetRefund")
            net.WriteUInt(table.Count(names), 8)
            net.WriteUInt(money, 16)

            for k, v in pairs(names) do
                net.WriteString(k)
                net.WriteUInt(v, 8)
            end

            net.Send(ply)
        end
    end)

    query:Execute()

    if ( data.rpgroup ) then
        ply:GroupLoad(data.rpgroup, data.rpgrouprank or nil)
    end

    plyTable.impulseBeenSetup = true

    hook.Run("PostSetupPlayer", ply)
end

function GM:PlayerLoadout(ply)
    if ( ply:Team() == 0 ) then return end

    local data = ply:GetTeamData()
    if ( data and data.spawns ) then
        ply:SetPos(data.spawns[math.random(1, #data.spawns)])
    end

    ply:SetRunSpeed(impulse.Config.JogSpeed)
    ply:SetWalkSpeed(impulse.Config.WalkSpeed)

    return true
end

function GM:PostSetupPlayer(ply)
    local plyTable = ply:GetTable()
    plyTable.impulseData.Achievements = plyTable.impulseData.Achievements or {}

    for k, v in pairs(impulse.Config.Achievements) do
        ply:AchievementCheck(k)
    end

    ply:Spawn()
end

function GM:PlayerInitialSpawnLoaded(ply)
    local jailTime = impulse.Arrest.DisconnectRemember[ply:SteamID64()]

    local plyTable = ply:GetTable()
    if ( plyTable.ammoToGive ) then
        for v, k in pairs(plyTable.ammoToGive) do
            if ( game.GetAmmoID(v) != -1 ) then
                ply:GiveAmmo(k, v)
            end
        end

        plyTable.ammoToGive = nil
    end

    if ( jailTime ) then
        ply:Arrest()
        ply:Jail(jailTime)
        impulse.Arrest.DisconnectRemember[ply:SteamID64()] = nil
    end

    local steamID64 = ply:SteamID64()
    if ( GExtension and GExtension.Warnings[steamID64] ) then
        local bans = GExtension:GetBans(steamID64)
        local warns = GExtension.Warnings[steamID64]

        net.Start("opsGetRecord")
            net.WriteUInt(table.Count(warns), 8)
            net.WriteUInt(table.Count(bans), 8)
        net.Send(ply)
    end
end

function GM:PlayerSpawn(ply)
    local plyTable = ply:GetTable()
    local cellID = plyTable.InJail

    if ( plyTable.InJail ) then
        local pos = impulse.Config.PrisonCells[cellID]
        ply:SetPos(impulse.Util:FindEmptyPos(pos, {self}, 150, 30, Vector(16, 16, 64)))
        ply:SetEyeAngles(impulse.Config.PrisonAngle)
        ply:Arrest()

        return
    end

    local killSilent = plyTable.IsKillSilent
    if ( killSilent ) then
        plyTable.IsKillSilent = false

        for k, v in pairs(plyTable.TempWeapons) do
            local weapon = ply:Give(v.weapon)
            weapon:SetClip1(v.clip)
        end

        for k, v in pairs(plyTable.TempAmmo) do
            ply:SetAmmo(v, k)
        end

        if ( plyTable.TempSelected ) then
            ply:SelectWeapon(plyTable.TempSelected)
            ply:SetWeaponRaised(plyTable.TempSelectedRaised)
        end

        return
    end

    if ( ply:GetNetVar("arrested", false) ) then
        ply:SetNetVar("arrested", false)
    end

    if ( ply:HasBrokenLegs() ) then
        ply:FixLegs()
    end

    if ( plyTable.impulseBeenSetup ) then
        ply:SetTeam(impulse.Config.DefaultTeam)

        if ( plyTable.HasDied ) then
            ply:SetHunger(70)
        else
            ply:SetHunger(100)
        end
    end

    plyTable.impulseArrestedWeapons = nil
    plyTable.SpawnProtection = true

    ply:SetJumpPower(impulse.Config.JumpPower or 160)

    timer.Simple(10, function()
        if ( !IsValid(ply) ) then return end

        plyTable.SpawnProtection = false
    end)

    hook.Run("PlayerLoadout", ply)
end

function GM:PlayerDisconnected(ply)
    local userID = ply:UserID()
    local steamID = ply:SteamID64()
    local entIndex = ply:EntIndex()
    local arrested = ply:GetNetVar("arrested", false)

    local plyTable = ply:GetTable()
    local dragger = plyTable.impulseArrestedDragger
    if ( IsValid(dragger) ) then
        impulse.Arrest.Dragged[ply] = nil
        dragger.impulseArrestedDragging = nil
    end

    local loadTimerName = "impulseFullLoad." .. userID
    if ( timer.Exists(loadTimerName) ) then
        timer.Remove(loadTimerName)
    end

    local jailCell = plyTable.InJail
    if ( jailCell ) then
        timer.Remove("impulsePrison." .. userID)
        local duration = impulse.Arrest.Prison[jailCell][entIndex].duration
        impulse.Arrest.Prison[jailCell][entIndex] = nil
        impulse.Arrest.DisconnectRemember[steamID] = duration
    elseif ( plyTable.impulseBeingJailed ) then
        impulse.Arrest.DisconnectRemember[steamID] = plyTable.impulseBeingJailed
    elseif ( arrested ) then
        impulse.Arrest.DisconnectRemember[steamID] = impulse.Config.MaxJailTime
    end

    if ( plyTable.CanHear ) then
        for k, v in player.Iterator() do
            if ( !v.CanHear ) then continue end
            v.CanHear[ply] = nil
        end
    end

    if ( plyTable.impulseID ) then
        impulse.Inventory.Data[plyTable.impulseID] = nil

        if ( !ply:IsCP() ) then
            local query = mysql:Update("impulse_players")
            query:Update("ammo", util.TableToJSON(ply:GetAmmo()))
            query:Where("steamid", steamID)
            query:Execute()
        end
    end

    if ( plyTable.impulseOwnedDoors ) then
        for k, v in pairs(plyTable.impulseOwnedDoors) do
            if ( !IsValid(k) ) then continue end

            if ( k:GetDoorMaster() == ply ) then
                local noUnlock = k.NoDCUnlock or false
                ply:RemoveDoorMaster(k, noUnlock)
            else
                ply:RemoveDoorUser(k)
            end
        end
    end

    if ( IsValid(plyTable.impulseInventorySearching) ) then
        plyTable.impulseInventorySearching:Freeze(false)
    end

    for k, v in pairs(ents.FindByClass("impulse_item")) do
        if ( v.ItemOwner and v.ItemOwner == ply ) then
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
function GM:PlayerSay(ply, text, teamChat, newChat)
    local plyTable = ply:GetTable()
    if ( !plyTable.impulseBeenSetup or teamChat ) then return "" end

    text = strTrim(text, " ")

    hook.Run("PostPlayerSay", ply, text)

    if ( string.StartWith(text, "/") ) then
        local args = string.Explode(" ", text)
        local command = impulse.chatCommands[string.lower(args[1])]
        if ( command ) then
            if ( command.cooldown and command.lastRan ) then
                if ( command.lastRan + command.cooldown > CurTime() ) then
                    return ""
                end
            end

            if ( command.adminOnly and !ply:IsAdmin() ) then
                ply:Notify("You must be an admin to use this command.")
                return ""
            end

            if ( command.leadAdminOnly and !ply:IsLeadAdmin() ) then
                ply:Notify("You must be a lead admin to use this command.")
                return ""
            end

            if ( command.superAdminOnly and !ply:IsSuperAdmin() ) then
                ply:Notify("You must be a super admin to use this command.")
                return ""
            end

            if ( command.requiresArg and ( !args[2] or string.Trim(args[2]) == "" ) ) then return "" end
            if ( command.requiresAlive and !ply:Alive() ) then return "" end

            text = string.sub(text, string.len(args[1]) + 2)

            table.remove(args, 1)
            command.onRun(ply, args, text)
        else
            ply:Notify("The " .. args[1] .. " command does not exist.")
        end
    elseif ( ply:Alive() ) then
        text = hook.Run("ProcessICChatMessage", ply, text) or text
        text = hook.Run("ChatClassMessageSend", 1, text, ply) or text

        for k, v in player.Iterator() do
            if ( ply:GetPos() - v:GetPos() ):LengthSqr() <= ( impulse.Config.TalkDistance ^ 2 ) then
                v:SendChatClassMessage(1, text, ply)
            end
        end

        hook.Run("PostChatClassMessageSend", 1, text, ply)
    end

    return ""
end

local function canHearCheck(listener) -- based on darkrps voice chat optomization this is called every 0.5 seconds in the think hook
    if ( !IsValid(listener) ) then return end

    listener.CanHear = listener.CanHear or {}
    local listPos = listener:GetShootPos()
    local voiceDistance = impulse.Config.VoiceDistance ^ 2

    for _,speaker in player.Iterator() do
        listener.CanHear[speaker] = (listPos:DistToSqr(speaker:GetShootPos()) < voiceDistance)
        hook.Run("PlayerCanHearCheck", listener, speaker)
    end
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    if ( !speaker:Alive() ) then return false end

    local canHear = listener.CanHear and listener.CanHear[speaker]
    return canHear, true
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
    local vel = ply:GetVelocity()

    local ragCount = table.Count(ents.FindByClass("prop_ragdoll"))
    if ( ragCount > 32 ) then
        print("[impulse-reforged] Avoiding ragdoll body spawn for performance reasons .. . (rag count: " .. ragCount .. ")")
        return
    end

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetSkin(ply:GetSkin())
    ragdoll.DeadPlayer = ply
    ragdoll.Killer = attacker
    ragdoll.DmgInfo = dmginfo

    local plyTable = ply:GetTable()
    if ( plyTable.impulseLastFall and plyTable.impulseLastFall > CurTime() - 0.5 ) then
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

    for k, v in pairs(ply:GetBodyGroups()) do
        ragdoll:SetBodygroup(v.id, ply:GetBodygroup(v.id))
    end

    hook.Run("PlayerRagdollPreSpawn", ragdoll, ply, attacker)

    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local velocity = ply:GetVelocity()

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local physObj = ragdoll:GetPhysicsObjectNum(i)
        if ( IsValid(physObj) ) then
            physObj:SetVelocity(velocity)

            local index = ragdoll:TranslatePhysBoneToBone(i)
            if ( index ) then
                local pos, ang = ply:GetBonePosition(index)

                physObj:SetPos(pos)
                physObj:SetAngles(ang)
            end
        end
    end

    timer.Simple(impulse.Config.BodyDeSpawnTime, function()
        if ( !IsValid(ragdoll) ) then return end

        ragdoll:Fire("FadeAndRemove", 7)

        timer.Simple(10, function()
            SafeRemoveEntity(ragdoll)
        end)
    end)

    timer.Simple(0.1, function()
        if ( !IsValid(ragdoll) or !IsValid(ply) ) then return end

        net.Start("impulseRagdollLink")
            net.WriteEntity(ragdoll)
        net.Send(ply)
    end)

    return true
end

function GM:PlayerDeath(ply, killer)
    local wait = impulse.Config.RespawnTime
    if ( ply:IsDonator() ) then
        wait = impulse.Config.RespawnTimeDonator
    end

    local plyTable = ply:GetTable()
    plyTable.impulseRespawnWait = CurTime() + wait

    local money = ply:GetMoney()
    if ( money > 0 ) then
        ply:SetMoney(0)
        impulse.Currency:SpawnMoney(ply:GetPos(), money)
    end

    if ( !plyTable.impulseBeenInventorySetup ) then
        return
    end

    ply:UnEquipInventory()

    local inv = ply:GetInventory()
    local restorePoint = {}
    local pos = ply:LocalToWorld(ply:OBBCenter())
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

    hook.Run("PlayerDropDeathItems", ply, killer, pos, dropped, inv)

    ply:ClearInventory(1)
    plyTable.InventoryRestorePoint = restorePoint
    plyTable.HasDied = true
end

function GM:PlayerSilentDeath(ply)
    local plyTable = ply:GetTable()
    plyTable.IsKillSilent = true
    plyTable.TempWeapons = {}

    for k, v in pairs(ply:GetWeapons()) do
        plyTable.TempWeapons[k] = {weapon = v:GetClass(), clip = v:Clip1()}
    end

    plyTable.TempAmmo = ply:GetAmmo()

    local weapon = ply:GetActiveWeapon()
    if ( IsValid(weapon) ) then
        plyTable.TempSelected = weapon:GetClass()
        plyTable.TempSelectedRaised = ply:IsWeaponRaised()
    end
end

local nextDeathThink = 0
function GM:PlayerDeathThink(ply)
    local curTime = CurTime()
    if ( curTime < nextDeathThink ) then return end
    nextDeathThink = curTime + 0.5

    local plyTable = ply:GetTable()
    if ( !plyTable.impulseRespawnWait or plyTable.impulseRespawnWait < CurTime() ) then
        ply:Spawn()
    end

    return true
end

function GM:PlayerDeathSound()
    return true
end

function GM:CanPlayerSuicide()
    return false
end

function GM:OnPlayerChangedTeam(ply)
    local plyTable = ply:GetTable()
    if ( plyTable.BuyableTeamRemove ) then
        for v, k in pairs(plyTable.BuyableTeamRemove) do
            if ( IsValid(v) and v.BuyableOwner == ply ) then
                SafeEntityRemove(v)
            end
        end
    end
end

function GM:SetupPlayerVisibility(ply)
    local plyTable = ply:GetTable()
    if ( plyTable.extraPVS ) then
        AddOriginToPVS(plyTable.extraPVS)
    end

    if ( plyTable.extraPVS2 ) then
        AddOriginToPVS(plyTable.extraPVS2)
    end
end

function GM:KeyPress(ply, key)
    if ( ply:IsAFK() ) then
        ply:UnMakeAFK()
    end

    local plyTable = ply:GetTable()
    plyTable.impulseAFKTimer = CurTime() + impulse.Config.AFKTime

    if ( key == IN_RELOAD ) then
        timer.Create("impulseRaiseWait" .. ply:SteamID64(), impulse.Config.WeaponRaiseTime or 0.3, 1, function()
            if ( IsValid(ply) ) then
                ply:ToggleWeaponRaised()
            end
        end)
    elseif key == IN_USE and !ply:InVehicle() then
        local trace = {}
        trace.start = ply:GetShootPos()
        trace.endpos = trace.start + ply:GetAimVector() * 96
        trace.filter = ply

        local entity = util.TraceLine(trace).Entity
        if ( IsValid(entity) and entity:IsPlayer() and ply:CanArrest(entity) ) then
            if ( !entity.impulseArrestedDragger ) then
                ply:DragPlayer(entity)
            else
                entity:StopDrag()
            end
        end
    end
end

function GM:PlayerUse(ply, entity)
    local plyTable = ply:GetTable()
    if ( ( plyTable.useNext or 0)  > CurTime() ) then return false end
    plyTable.useNext = CurTime() + 0.3

    local buttons = impulse.Config.Buttons
    if ( !buttons or table.Count(buttons) < 1 ) then return end

    local btnKey = entity.impulseButtonCheck
    if ( !btnKey ) then return end

    local btnData = impulse.Config.Buttons[btnKey]
    if ( !btnData ) then return end

    if ( btnData.customCheck and !btnData.customCheck(ply, entity) ) then
        plyTable.useNext = CurTime() + 1
        return false
    end

    if ( btnData.doorgroup ) then
        local teamDoorGroups = plyTable.DoorGroups
        if ( !teamDoorGroups or !table.HasValue(teamDoorGroups, btnData.doorgroup) ) then
            plyTable.useNext = CurTime() + 1
            ply:Notify("You don't have access to use this button.")
            return false
        end
    end
end

function GM:KeyRelease(ply, key)
    if ( key == IN_RELOAD ) then
        timer.Remove("impulseRaiseWait" .. ply:SteamID64())
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
            SafeEntityRemove(v)
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
        -- Slower version
        -- for k, v in ents.Iterator() do
        --     if ( impulse.Config.BlacklistEnts[v:GetClass()] ) then
        --         SafeEntityRemove(v)
        --     end
        -- end

        -- Faster version
        for k, v in pairs(impulse.Config.BlacklistEnts) do
            for _, ent in ipairs(ents.FindByClass(k)) do
                SafeEntityRemove(ent)
            end
        end
    end

    impulse.Save:Load()
    LoadButtons()

    hook.Run("PostInitPostEntity")
end

function GM:PostCleanupMap()
    hook.Run("InitPostEntity")
end

function GM:GetFallDamage(ply, speed)
    local plyTable = ply:GetTable()
    plyTable.impulseLastFall = CurTime()

    local dmg = speed * 0.05
    if ( speed > 780 ) then
        dmg = dmg + 75
    end

    local shouldBreakLegs = hook.Run("PlayerShouldBreakLegs", ply, dmg)
    if ( shouldBreakLegs != nil and shouldBreakLegs == false ) then
        return dmg
    end

    local strength = ply:GetSkillLevel("strength")
    local r = math.random(0, 20 + (strength * 2))
    if ( r <= 20 and dmg < ply:Health() ) then
        ply:BreakLegs()
    end

    return dmg
end

local nextThink = 0
function GM:Think()
    for k, v in player.Iterator() do
        hook.Run("PlayerThink", v)
    end

    local curTime = CurTime()
    if ( curTime < nextThink ) then return end
    nextThink = curTime + 0.2

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
local nextPlayerThink = 0
function GM:PlayerThink(ply)
    local curTime = CurTime()
    if ( curTime < nextPlayerThink ) then return end
    nextPlayerThink = curTime + 0.2

    if ( !IsValid(ply) or ply:Team() == 0 ) then return end

    local plyTable = ply:GetTable()
    if ( !plyTable.impulseNextHunger ) then
        plyTable.impulseNextHunger = curTime + impulse.Config.HungerTime
    end

    if ( !plyTable.impulseNextHeal ) then
        plyTable.impulseNextHeal = curTime + impulse.Config.HungerHealTime
    end

    if ( ply:Alive() ) then
        if ( plyTable.impulseNextHunger < curTime ) then
            local shouldTakeHunger = hook.Run("PlayerShouldGetHungry", ply)
            if ( shouldTakeHunger == nil or shouldTakeHunger ) then
                ply:TakeHunger(1)
            end

            if ( ply:GetNetVar("hunger", 100) < 1 ) then
                if ( ply:Health() > 10 ) then
                    ply:TakeDamage(1, ply, ply)
                end

                plyTable.impulseNextHunger = curTime + 1
            else
                plyTable.impulseNextHunger = curTime + impulse.Config.HungerTime
            end
        end

        if ( plyTable.impulseNextHeal < curTime ) then
            local hunger = ply:GetNetVar("hunger", 10)
            if ( hunger >= 90 and ply:Health() < 75 ) then
                ply:SetHealth(math.Clamp(ply:Health() + 1, 0, 75))
                plyTable.impulseNextHeal = curTime + impulse.Config.HungerHealTime
            else
                plyTable.impulseNextHeal = curTime + 2
            end
        end
    end

    if ( !plyTable.impulseNextHear or plyTable.impulseNextHear < CurTime() ) then
        canHearCheck(ply)
        plyTable.impulseNextHear = curTime + 1
    end

    if ( curTime > nextAFK ) then
        nextAFK = curTime + 2

        if ( plyTable.impulseAFKTimer and plyTable.impulseAFKTimer < curTime and !impulse.Arrest.Dragged[ply] and !ply:IsAFK() ) then
            ply:MakeAFK()
        end
    
        plyTable.impulseLastPos = ply:GetPos()

        if ( plyTable.impulseBrokenLegs and plyTable.BrokenLegsTime < curTime and ply:Alive() and ply:HasBrokenLegs() ) then
            ply:FixLegs()
            ply:Notify("Your broken legs have healed naturally.")
        end
    end

    local plyTable = ply:GetTable()
    if ( ( plyTable.impulseNextAmbientSound or 0 ) < CurTime() ) then
        local ambientSound = ply:GetAmbientSound()
        if ( ambientSound and ambientSound != "" ) then
            ply:EmitSound(ambientSound, 60, nil, 0.3, CHAN_AUTO)

            plyTable.impulseNextAmbientSound = CurTime() + math.random(30, 120)
        end
    end
end

function GM:PlayerCanPickupWeapon(ply)
    if ( ply:GetNetVar("arrested", false) ) then return false end

    return true
end

local exploitRagBlock = {
    ["models/dpfilms/metropolice/playermodels/pm_zombie_police.mdl"] = true,
    ["models/dpfilms/metropolice/zombie_police.mdl"] = true,
    ["models/zombie/zmanims.mdl"] = true
}

function GM:PlayerSpawnRagdoll(ply, model)
    if ( exploitRagBlock[model] ) then return false end

    return ply:IsLeadAdmin()
end

function GM:PlayerSpawnSENT(ply)
    return ply:IsSuperAdmin()
end

function GM:PlayerSpawnSWEP(ply)
    return ply:IsSuperAdmin()
end

function GM:PlayerGiveSWEP(ply)
    return ply:IsSuperAdmin()
end

function GM:PlayerSpawnEffect(ply)
    return ply:IsAdmin()
end

function GM:PlayerSpawnNPC(ply)
    return ply:IsSuperAdmin() or ( ply:IsAdmin() and impulse.Ops.EventManager.GetEventMode() )
end

function GM:PlayerSpawnProp(ply, model)
    local plyTable = ply:GetTable()
    if ( !ply:Alive() or !plyTable.impulseBeenSetup or ply:GetNetVar("arrested", false) ) then return false end

    if ( ply:IsAdmin() ) then return true end

    local limit
    local price

    if ( ply:IsDonator() ) then
        limit = impulse.Config.PropLimitDonator
        price = impulse.Config.PropPriceDonator
    else
        limit = impulse.Config.PropLimit
        price = impulse.Config.PropPrice
    end

    if ( ply:GetPropCount(true) >= limit ) then
        ply:Notify("You have reached your prop limit.")
        return false
    end

    if ( ply:CanAfford(price) ) then
        ply:TakeMoney(price)
        ply:Notify("You have purchased a prop for " .. impulse.Config.CurrencyPrefix .. price .. ".")
    else
        ply:Notify("You need " .. impulse.Config.CurrencyPrefix .. price .. " to spawn this prop.")
        return false
    end

    return true
end

function GM:PlayerSpawnedProp(ply, model, ent)
    ply:AddPropCount(ent)
end

function GM:PlayerSpawnVehicle(ply, model)
    if ( ply:GetNetVar("arrested", false) ) then return false end

    if ( ply:IsDonator() and ( model:find("chair") or model:find("seat") or model:find("pod") ) ) then
        local plyTable = ply:GetTable()
        local count = 0
        plyTable.SpawnedVehicles = plyTable.SpawnedVehicles or {}

        for v, k in pairs(plyTable.SpawnedVehicles) do
            if k and IsValid(k) then
                count = count + 1
            else
                plyTable.SpawnedVehicles[v] = nil
            end
        end

        if count >= impulse.Config.ChairsLimit then
            ply:Notify("You have spawned the maximum amount of chairs.")
            return false
        end

        return true
    else
        return ply:IsSuperAdmin()
    end
end

function GM:PlayerSpawnedVehicle(ply, ent)
    local plyTable = ply:GetTable()
    plyTable.SpawnedVehicles = plyTable.SpawnedVehicles or {}

    table.insert(plyTable.SpawnedVehicles, ent)
end

function GM:CanDrive()
    return false
end

local whitelistProp = {
    ["collision"] = true,
    ["remover"] = true
}

local adminProp = {
    ["bodygroups"] = true,
    ["extinguish"] = true,
    ["ignite"] = true,
    ["skin"] = true
}

function GM:CanProperty(ply, prop)
    if ( whitelistProp[prop] ) then return true end

    if ( ply:IsAdmin() and adminProp[prop] ) then return true end

    return false
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

function GM:CanTool(ply, tr, tool)
    if ( !ply:IsAdmin() and tool == "spawner" ) then return false end

    if ( bannedTools[tool] ) then return false end

    if ( donatorTools[tool] and !ply:IsDonator() ) then
        ply:Notify("This tool is restricted to donators only.")
        return false
    end

    local ent = tr.Entity
    if ( IsValid(ent) ) then
        if ent.onlyremover then
            if tool == "remover" then
                return ply:IsAdmin() or ply:IsSuperAdmin()
            else
                return false
            end
        end

        if ent.nodupe and dupeBannedTools[tool] then
            return false
        end

        if tool == "remover" and ply:IsAdmin() and !ply:IsSuperAdmin() then
            local owner = ent:CPPIGetOwner()

            if not owner and !adminWorldRemoveWhitelist[ent:GetClass()] then
                ply:Notify("You can not remove this entity.")
                return false
            end
        end

        if string.sub(ent:GetClass(), 1, 8) == "impulse_" then
            if tool != "remover" and !ply:IsSuperAdmin() then
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

function GM:ADVDupeIsAllowed(ply, class, entclass) -- adv dupe 2 can be easily exploited, this fixes it. you must have the impulse version of AD2 for this to work
    if ( bannedDupeEnts[class] ) then return false end

    if ( donatorDupeEnts[class] ) then
        if ( ply:IsDonator() ) then
            return true
        else
            ply:Notify("This entity is restricted to donators only.")
            return false
        end
    end

    if ( whitelistDupeEnts[class] or string.sub(class, 1, 9) == "gmod_wire" ) then return true end

    return false
end

function GM:SetupMove(ply, mvData)
    local plyTable = ply:GetTable()
    if ( IsValid(plyTable.impulseArrestedDragging) ) then
        mvData:SetMaxClientSpeed(impulse.Config.WalkSpeed - 30)
    end
end

function GM:CanPlayerEnterVehicle(ply, veh)
    local plyTable = ply:GetTable()
    if ( ply:GetNetVar("arrested", false) ) or plyTable.impulseArrestedDragging then return false end

    return true
end

function GM:CanExitVehicle(veh, ply)
    if ( ply:GetNetVar("arrested", false) ) then return false end

    return true
end

function GM:PlayerSetHandsModel(ply, hands)
    local handModel = impulse.Teams.Stored[ply:Team()].handModel
    if ( handModel ) then
        hands:SetModel(handModel)
        return
    end

    local simplemodel = player_manager.TranslateToPlayerModelName(ply:GetModel())
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

function GM:PlayerShouldTakeDamage(ply, attacker)
    if ply:Team() == 0 then return false end

    local plyTable = ply:GetTable()
    if plyTable.SpawnProtection and attacker:IsPlayer() then return false end

    if ( attacker and IsValid(attacker) and attacker:IsPlayer() and attacker != Entity(0) and attacker != ply ) then
        local curTime = CurTime()
        if ( ( plyTable.impulseNextStorage or 0 ) < curTime ) then
            plyTable.impulseNextStorage = curTime + 60
        end

        attacker.impulseNextStorage = curTime + 180
    end

    return true
end

function GM:LongswordCalculateMeleeDamage(ply, damage, ent)
    local skill = ply:GetSkillLevel("strength")
    local dmg = damage * (1 + (skill * .059))
    local override = hook.Run("CalculateMeleeDamage", ply, dmg, ent)

    return override or dmg
end

function GM:LongswordMeleeHit(ply)
    local plyTable = ply:GetTable()
    if ( plyTable.impulseStrengthUp and plyTable.impulseStrengthUp > 5 ) then
        ply:AddSkillXP("strength", math.random(1, 6))
        plyTable.impulseStrengthUp = 0
        return
    end

    plyTable.impulseStrengthUp = ( plyTable.impulseStrengthUp or 0 ) + 1
end

function GM:LongswordHitEntity(ply, ent)
    -- if tree then vood ect.
end