local PLAYER = FindMetaTable("Player")

--- Parses model data and returns model path, skin, and bodygroups
-- @param modelData string or table - Can be "model.mdl", {"model.mdl", skin}, or {"model.mdl", skin, {bodygroups}}
-- @return string model, number skin, table bodygroups
function PLAYER:ParseModelData(modelData)
    if ( type(modelData) == "string" ) then
        return modelData, nil, nil
    elseif ( type(modelData) == "table" ) then
        local model = modelData[1]
        local skin = modelData[2]
        local bodygroups = modelData[3]

        -- Handle random skin if it's a table
        if ( type(skin) == "table" ) then
            skin = skin[math.random(#skin)]
        end

        -- Handle random bodygroup values if they're tables
        if ( bodygroups and type(bodygroups) == "table" ) then
            local parsedBodygroups = {}
            for name, value in pairs(bodygroups) do
                if ( type(value) == "table" ) then
                    parsedBodygroups[name] = value[math.random(#value)]
                else
                    parsedBodygroups[name] = value
                end
            end
            bodygroups = parsedBodygroups
        end

        return model, skin, bodygroups
    end
    return nil, nil, nil
end

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

    local modelData
    if ( teamData.models ) then
        modelData = teamData.models[math.random(#teamData.models)]
    elseif ( teamData.model ) then
        modelData = teamData.model
    else
        modelData = selfTable.impulseDefaultModel
    end

    local model, skin, bodygroups = self:ParseModelData(modelData)
    self:SetModel(model)
    self:SetSkin(skin or selfTable.impulseDefaultSkin)

    -- Reset all bodygroups first
    for i = 0, self:GetNumBodyGroups() - 1 do
        self:SetBodygroup(i, 0)
    end

    -- Apply model-specific bodygroups if any
    if ( bodygroups ) then
        for name, value in pairs(bodygroups) do
            self:SetBodygroup(self:FindBodygroupByName(name), value)
        end
    end

    self:ResetSubMaterials()

    if ( self:HasBrokenLegs() ) then
        self:FixLegs()
    end

    if ( self:IsCP() or teamData.cp ) then
        self:StripAmmo()
    end

    self:UnEquipInventory()
    self:ClearRestrictedInventory()
    self:StripWeapons()

    if ( teamData.loadout ) then
        for k, v in pairs(teamData.loadout) do
            self:Give(v)
        end
    end

    if ( teamData.runSpeed ) then
        self:SetRunSpeed(teamData.runSpeed)
    else
        self:SetRunSpeed(impulse.Config.JogSpeed)
    end

    selfTable.DoorGroups = teamData.doorGroup or {}

    self:SetRelay("class", nil)
    self:SetRelay("rank", nil)

    local oldTeam = self:Team()
    self:OldSetTeam(teamID)

    self:SpawnAtTeamSpawn()

    if ( teamData.onBecome ) then
        teamData:onBecome(self)
    end

    if ( oldTeam != teamID ) then
        hook.Run("OnPlayerChangedTeam", self, oldTeam, teamID)
    else
        print(string.format("[impulse] Warning: OnPlayerChangedTeam not called for %s as team did not change (%s)", self:Nick(), teamData.name))
    end

    return true
end

function PLAYER:SetTeamClass(classID, skipLoadout)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[classID]
    if ( !classData ) then
        return false, "Invalid class ID! (" .. tostring(classID) .. ")"
    end

    local modelData
    if ( classData and classData.models ) then
        modelData = classData.models[math.random(#classData.models)]
    elseif ( classData and classData.model ) then
        modelData = classData.model
    else
        if ( teamData and teamData.models ) then
            modelData = teamData.models[math.random(#teamData.models)]
        elseif ( teamData and teamData.model ) then
            modelData = teamData.model
        else
            modelData = self.impulseDefaultModel
        end
    end

    local model, skin, bodygroups = self:ParseModelData(modelData)
    self:SetModel(model)
    self:SetSkin(skin or self.impulseDefaultSkin)

    self:SetupHands()

    -- Reset all bodygroups first
    for i = 0, self:GetNumBodyGroups() - 1 do
        self:SetBodygroup(i, 0)
    end

    -- Apply model-specific bodygroups if any
    if ( bodygroups ) then
        for name, value in pairs(bodygroups) do
            self:SetBodygroup(self:FindBodygroupByName(name), value)
        end
    end

    if ( !skipLoadout ) then
        if ( self:HasBrokenLegs() ) then
            self:FixLegs()
        end

        self:StripWeapons()

        if ( classData.loadout ) then
            for v,weapon in pairs(classData.loadout) do
                self:Give(weapon)
            end
        else
            for v,weapon in pairs(teamData.loadout) do
                self:Give(weapon)
            end

            if ( classData.loadoutAdd ) then
                for v,weapon in pairs(classData.loadoutAdd) do
                    self:Give(weapon)
                end
            end
        end

        self:ClearRestrictedInventory()

        if ( classData.items ) then
            for v, item in pairs(classData.items) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        else
            if ( teamData.items ) then
                for v, item in pairs(teamData.items) do
                    for i = 1, (item.amount or 1) do
                        self:GiveItem(item.class, 1, true)
                    end
                end
            end

            if ( classData.itemsAdd ) then
                for v, item in pairs(classData.itemsAdd) do
                    for i = 1, (item.amount or 1) do
                        self:GiveItem(item.class, 1, true)
                    end
                end
            end
        end
    end

    if ( classData and classData.armour ) then
        self:SetArmor(classData.armour)
        self.MaxArmour = classData.armour
    else
        self:SetArmor(0)
        self.MaxArmour = nil
    end

    if ( classData.onBecome ) then
        classData:onBecome(self)
    end

    self:SetRelay("class", classID)

    hook.Run("PlayerChangeClass", self, classID, classData.name)

    return true
end

function PLAYER:SetTeamRank(rankID)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes and teamData.classes[self:GetTeamClass()] or nil
    local rankData = teamData.ranks and teamData.ranks[rankID] or nil

    if ( !rankData ) then
        return false, "Invalid rank ID! (" .. tostring(rankID) .. ")"
    end

    local modelData
    if ( rankData and rankData.models ) then
        modelData = rankData.models[math.random(#rankData.models)]
    elseif ( rankData and rankData.model ) then
        modelData = rankData.model
    elseif ( classData ) then
        if ( classData.models ) then
            modelData = classData.models[math.random(#classData.models)]
        elseif ( classData.model ) then
            modelData = classData.model
        else
            if ( teamData.models ) then
                modelData = teamData.models[math.random(#teamData.models)]
            elseif ( teamData.model ) then
                modelData = teamData.model
            end
        end
    else
        if ( teamData.models ) then
            modelData = teamData.models[math.random(#teamData.models)]
        elseif ( teamData.model ) then
            modelData = teamData.model
        end
    end

    if ( modelData ) then
        local model, skin, bodygroups = self:ParseModelData(modelData)
        self:SetModel(model)
        self:SetSkin(skin or self.impulseDefaultSkin)

        self:SetupHands()

        -- Reset all bodygroups first
        for i = 0, self:GetNumBodyGroups() - 1 do
            self:SetBodygroup(i, 0)
        end

        -- Apply model-specific bodygroups if any
        if ( bodygroups ) then
            for name, value in pairs(bodygroups) do
                self:SetBodygroup(self:FindBodygroupByName(name), value)
            end
        end
    end

    if ( rankData and rankData.subMaterial and !classData.noSubMats ) then
        for v, k in pairs(rankData.subMaterial) do
            self:SetSubMaterial(v - 1, k)

            self.SetSubMats = self.SetSubMats or {}
            self.SetSubMats[v] = true
        end
    elseif ( self.SetSubMats ) then
        self:ResetSubMaterials()
    end

    if ( self:HasBrokenLegs() ) then
        self:FixLegs()
    end

    self:StripWeapons()

    if ( rankData and rankData.loadout ) then
        for _,weapon in pairs(rankData.loadout) do
            self:Give(weapon)
        end
    else
        for _, weapon in pairs(teamData.loadout) do
            self:Give(weapon)
        end

        if ( classData and classData.loadoutAdd ) then
            for _, weapon in pairs(classData.loadoutAdd) do
                self:Give(weapon)
            end
        end

        if ( rankData and rankData.loadoutAdd ) then
            for _, weapon in pairs(rankData.loadoutAdd) do
                self:Give(weapon)
            end
        end
    end

    self:ClearRestrictedInventory()

    if ( rankData and rankData.items ) then
        for _, item in pairs(rankData.items) do
            for i = 1, (item.amount or 1) do
                self:GiveItem(item.class, 1, true)
            end
        end
    else
        if ( teamData and teamData.items ) then
            for _, item in pairs(teamData.items) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end

        if ( classData and classData.itemsAdd ) then
            for _, item in pairs(classData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end

        if ( rankData and rankData.itemsAdd ) then
            for _, item in pairs(rankData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end
    end

    if ( rankData and rankData.onBecome ) then
        rankData:onBecome(self)
    end

    self:SetRelay("rank", rankID)

    hook.Run("PlayerChangeRank", self, rankID, rankData and rankData.name or nil)

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
    if !self.Whitelists then return false end

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
        if !result or not IsValid(self) then return end

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

function PLAYER:SpawnAtTeamSpawn()
    local teamData = self:GetTeamData()
    local spawnData

    -- Check Rank
    local rankName = self:GetTeamRank()
    if ( rankName and teamData.ranks ) then
        for _, rank in ipairs(teamData.ranks) do
            if ( rank.name == rankName and rank.spawnPoints ) then
                spawnData = table.Random(rank.spawnPoints)
                break
            end
        end
    end

    -- Check Class
    if ( !spawnData ) then
        local className = self:GetTeamClass()
        if ( className and teamData.classes ) then
            for _, class in ipairs(teamData.classes) do
                if ( class.name == className and class.spawnPoints ) then
                    spawnData = table.Random(class.spawnPoints)
                    break
                end
            end
        end
    end

    -- Check Team
    if ( !spawnData and teamData.spawnPoints ) then
        spawnData = table.Random(teamData.spawnPoints)
    end

    -- Fallback to old 'spawns' key
    if ( !spawnData and teamData.spawns ) then
        spawnData = table.Random(teamData.spawns)
    end

    -- Check Global Config
    if ( !spawnData and impulse.Config.SpawnPoints and impulse.Config.SpawnPoints[self:Team()] ) then
        local points = impulse.Config.SpawnPoints[self:Team()]
        if ( istable(points) and !points.pos ) then
            spawnData = table.Random(points)
        else
            spawnData = points
        end
    end

    if ( spawnData ) then
        if ( isvector(spawnData) ) then
            self:SetPos(spawnData)
        elseif ( istable(spawnData) and spawnData.pos ) then
            self:SetPos(spawnData.pos)

            if ( spawnData.ang ) then
                self:SetEyeAngles(spawnData.ang)
            end
        end
    end
end
