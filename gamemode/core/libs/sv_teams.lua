local PLAYER = FindMetaTable("Player")

PLAYER.OldSetTeam = PLAYER.OldSetTeam or PLAYER.SetTeam

function PLAYER:SetTeam(teamID)
    local selfTable = self:GetTable()
    
    local teamData = impulse.Teams.Stored[teamID]
    if ( !teamData ) then
        return false, "Invalid team ID!"
    end

    local teamPlayers = team.NumPlayers(teamID)
    if ( teamData.max and teamPlayers >= teamData.max ) then
        return false, "You cannot join this team as it is full!"
    end

    self:SetModel(teamData.model or selfTable.impulseDefaultModel)
    self:SetSkin(teamData.skin or selfTable.impulseDefaultSkin)
    print("Set model and skin")

    if ( teamData.bodygroups ) then
        for v, bodygroupData in pairs(teamData.bodygroups) do
            self:SetBodygroup(bodygroupData[1], (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    else
        for i = 0, self:GetNumBodyGroups() - 1 do
            self:SetBodygroup(i, 0)
        end
    end
    print("Set bodygroups")

    self:ResetSubMaterials()
    print("Reset sub materials")

    if ( self:HasBrokenLegs() ) then
        self:FixLegs()
        print("Fixed legs")
    end

    if ( self:IsCP() or teamData.cp ) then
        self:StripAmmo()
        print("Stripped ammo")
    end

    self:UnEquipInventory()
    self:ClearRestrictedInventory()
    self:StripWeapons()
    print("Stripped weapons and inventory")

    if ( teamData.loadout ) then
        for k, v in pairs(teamData.loadout) do
            self:Give(v)
            print("Gave weapon: " .. v)
        end
    end

    if ( teamData.runSpeed ) then
        self:SetRunSpeed(teamData.runSpeed)
    else
        self:SetRunSpeed(impulse.Config.JogSpeed)
    end
    print("Set run speed to: " .. self:GetRunSpeed())

    selfTable.DoorGroups = teamData.doorGroup or {}

    if ( self:Team() != teamID ) then
        hook.Run("OnPlayerChangedTeam", self, self:Team(), teamID)
        print("Player changed team from " .. self:Team() .. " to " .. teamID)
    end

    self:SetNetVar("class", nil)
    self:SetNetVar("rank", nil)
    print("Set class and rank to nil")

    self:OldSetTeam(teamID)
    print("Set team to " .. teamID)

    if ( teamData.spawns ) then
        self:SetPos(teamData.spawns[math.random(1, #teamData.spawns)])
        print("Set player position to random spawn for team " .. teamData.name)
    end

    if ( teamData.onBecome ) then
        teamData.onBecome(self)
        print("Ran onBecome for team " .. teamData.name)
    end

    return true
end

function PLAYER:SetTeamClass(classID, skipLoadout)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[classID]
    local classPlayers = 0

    if classData.model then
        self:SetModel(classData.model)
    else
        self:SetModel(teamData.model or self.impulseDefaultModel)
    end

    self:SetupHands()

    if classData.skin then
        self:SetSkin(classData.skin)
    else
        self:SetSkin(teamData.skin or self.impulseDefaultSkin)
    end

    for i = 0, self:GetNumBodyGroups() - 1 do
        self:SetBodygroup(i, 0)
    end

    if classData.bodygroups then
        for v, bodygroupData in pairs(classData.bodygroups) do
            self:SetBodygroup(bodygroupData[1], (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    elseif teamData.bodygroups then
        for v, bodygroupData in pairs(teamData.bodygroups) do
            self:SetBodygroup(bodygroupData[1], (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    end

    if not skipLoadout then
        if ( self:HasBrokenLegs() ) then
            self:FixLegs()
        end

        self:StripWeapons()

        if classData.loadout then
            for v,weapon in pairs(classData.loadout) do
                self:Give(weapon)
            end
        else
            for v,weapon in pairs(teamData.loadout) do
                self:Give(weapon)
            end

            if classData.loadoutAdd then
                for v,weapon in pairs(classData.loadoutAdd) do
                    self:Give(weapon)
                end
            end
        end

        self:ClearRestrictedInventory()

        if classData.items then
            for v,item in pairs(classData.items) do
                for i=1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        else
            if teamData.items then
                for v,item in pairs(teamData.items) do
                    for i=1, (item.amount or 1) do
                        self:GiveItem(item.class, 1, true)
                    end
                end
            end

            if classData.itemsAdd then
                for v,item in pairs(classData.itemsAdd) do
                    for i=1, (item.amount or 1) do
                        self:GiveItem(item.class, 1, true)
                    end
                end
            end
        end
    end

    if classData.armour then
        self:SetArmor(classData.armour)
        self.MaxArmour = classData.armour
    else
        self:SetArmor(0)
        self.MaxArmour = nil
    end

    if classData.doorGroup then
        self.DoorGroups = classData.doorGroup
    else
        self.DoorGroups = teamData.doorGroup or {}
    end

    if classData.onBecome then
        classData.onBecome(self)
    end

    self:SetNetVar("class", classID)

    hook.Run("PlayerChangeClass", self, classID, classData.name)

    return true
end

function PLAYER:SetTeamRank(rankID)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[self:GetTeamClass()]
    local rankData = teamData.ranks[rankID]

    if !(classData) then self:Notify("Player does not have a valid class selected!") return false end

    if rankData.model then
        self:SetModel(rankData.model)
    else
        if classData.model and self:GetModel() != classData.model then
            self:SetModel(classData.model)
        end
    end

    self:SetupHands()

    if rankData.skin then
        self:SetSkin(rankData.skin)
    end

    if rankData.bodygroups then
        for v, bodygroupData in pairs(rankData.bodygroups) do
            self:SetBodygroup(bodygroupData[1], (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    elseif teamData.bodygroups then
        for v, bodygroupData in pairs(teamData.bodygroups) do
            self:SetBodygroup(bodygroupData[1], (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    else
        for i = 0, self:GetNumBodyGroups() - 1 do
            self:SetBodygroup(i, 0)
        end
    end

    if rankData.subMaterial and !classData.noSubMats then
        for v, k in pairs(rankData.subMaterial) do
            self:SetSubMaterial(v - 1, k)

            self.SetSubMats = self.SetSubMats or {}
            self.SetSubMats[v] = true
        end
    elseif self.SetSubMats then
        self:ResetSubMaterials()
    end

    if ( self:HasBrokenLegs() ) then
        self:FixLegs()
    end

    self:StripWeapons()

    if rankData.loadout then
        for v,weapon in pairs(rankData.loadout) do
            self:Give(weapon)
        end
    else
        for v,weapon in pairs(teamData.loadout) do
            self:Give(weapon)
        end

        if classData and classData.loadoutAdd then
            for v,weapon in pairs(classData.loadoutAdd) do
                self:Give(weapon)
            end
        end

        if rankData.loadoutAdd then
            for v,weapon in pairs(rankData.loadoutAdd) do
                self:Give(weapon)
            end
        end
    end

    self:ClearRestrictedInventory()

    if rankData.items then
        for v,item in pairs(rankData.items) do
            for i=1, (item.amount or 1) do
                self:GiveItem(item.class, 1, true)
            end
        end
    else
        if teamData.items then
            for v,item in pairs(teamData.items) do
                for i=1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end

        if classData.itemsAdd then
            for v,item in pairs(classData.itemsAdd) do
                for i=1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end

        if rankData.itemsAdd then
            for v,item in pairs(rankData.itemsAdd) do
                for i=1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end
    end

    if rankData.doorGroup then
        self.DoorGroups = rankData.doorGroup
    else
        if classData.doorGroup then
            self.DoorGroups = classData.doorGroup
        else
            self.DoorGroups = teamData.doorGroup or {}
        end
    end

    if rankData.onBecome then
        rankData.onBecome(self)
    end

    self:SetNetVar("rank", rankID)

    hook.Run("PlayerChangeRank", self, rankID, rankData.name)

    return true
end

function impulse.Teams.WhitelistSetup(steamid)
    local query = mysql:Insert("impulse_whitelists")
    query:Insert("steamid")
end

function impulse.Teams.SetWhitelist(steamid, team, level)
    local inTable = impulse.Teams.GetWhitelist(steamid, team, function(exists)
        if exists then
            local query = mysql:Update("impulse_whitelists")
            query:Update("level", level)
            query:Where("team", team)
            query:Where("steamid", steamid)
            query:Execute()
        else
            local query = mysql:Insert("impulse_whitelists")
            query:Insert("level", level)
            query:Insert("team", team)
            query:Insert("steamid", steamid)
            query:Execute()
        end
    end)
end

function impulse.Teams.GetAllWhitelists(team, callback)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("steamid")
    query:Where("team", team)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 and callback then -- if player exists in db
            callback(result)
        end
    end)
    query:Execute()
end

function impulse.Teams.GetAllWhitelistsPlayer(steamid, callback)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("team")
    query:Where("steamid", steamid)
    query:Callback(function(result)
        if (type(result) == "table" and #result > 0) and callback then -- if player exists in db
            callback(result)
        end
    end)
    query:Execute()
end

function impulse.Teams.GetWhitelist(steamid, team, callback)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Where("team", team)
    query:Where("steamid", steamid)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 and callback then -- if player exists in db
            callback(result[1].level)
        else
            callback()
        end
    end)
    query:Execute()
end

function PLAYER:HasTeamWhitelist(team, level)
    if not self.Whitelists then return false end

    local whitelist = self.Whitelists[team]

    if whitelist then
        if level then
            return whitelist >= level
        else
            return true
        end
    end

    return false
end

function PLAYER:SetupWhitelists()
    self.Whitelists = {}

    impulse.Teams.GetAllWhitelistsPlayer(self:SteamID64(), function(result)
        if not result or not IsValid(self) then return end

        for v, k in pairs(result) do
            local teamName = k.team
            local level = k.level
            local realTeam = impulse.Teams.NameRef[teamName]

            --[[
            if not realTeam then -- team does not exist
                continue
            end
            ]]

            self.Whitelists[realTeam or k.team] = level
        end
    end)
end