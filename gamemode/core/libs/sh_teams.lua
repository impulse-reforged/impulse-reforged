impulse.Teams = impulse.Teams or {}
impulse.Teams.Stored = {}
impulse.Teams.List = {}
impulse.Teams.NameRef = {} -- Maps codeName to team ID for whitelist lookups

--- Registers a new team in the schema.
-- @realm shared
-- @table teamData Team data
-- @treturn number Team ID
function impulse.Teams:Register(teamData)
    if ( !teamData.name ) then
        ErrorNoHalt("Attempted to register a team without a name.\n")
        return
    end

    if ( !teamData.color ) then
        ErrorNoHalt("Attempted to register a team without a color.\n")
        return
    end

    local niceName = string.lower(string.gsub(teamData.name, "%s", "_"))
    local id = self.List[niceName] or table.Count(self.List) + 1

    teamData.index = id
    teamData.codeName = niceName

    team.SetUp(id, teamData.name, teamData.color, false)

    if ( teamData.classes ) then
        teamData.ClassRef = {}

        for k, v in ipairs(teamData.classes) do
            teamData.ClassRef[k] = v.name
        end
    end

    if ( teamData.ranks ) then
        teamData.RankRef = {}

        for k, v in ipairs(teamData.ranks) do
            teamData.RankRef[k] = v.name
        end
    end

    self.List[niceName] = id
    self.Stored[id] = teamData
    self.NameRef[niceName] = id

    return id
end

function impulse.Teams:FindTeam(identifier)
    if ( !identifier ) then return end

    for k, v in ipairs(impulse.Teams.Stored) do
        if ( impulse.Util:StringMatches(tostring(v.name), identifier) ) then
            return v
        elseif ( k == tonumber(identifier) ) then
            return v
        end
    end
end

function impulse.Teams:FindClass(identifier)
    if ( !identifier ) then return end

    for k, v in ipairs(impulse.Teams.Stored) do
        if ( !v.classes ) then continue end

        for k2, v2 in ipairs(v.classes) do
            if ( impulse.Util:StringMatches(tostring(v2.name), identifier) ) then
                return v2
            elseif ( k2 == tonumber(identifier) ) then
                return v2
            end
        end
    end
end

function impulse.Teams:FindRank(identifier)
    if ( !identifier ) then return end

    for k, v in ipairs(impulse.Teams.Stored) do
        if ( !v.ranks ) then continue end

        for k2, v2 in ipairs(v.ranks) do
            if ( impulse.Util:StringMatches(tostring(v2.name), identifier) ) then
                return v2
            elseif ( k2 == tonumber(identifier) ) then
                return v2
            end
        end
    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:CanBecomeTeam(teamID, notify)
    local teamData = impulse.Teams.Stored[teamID]
    local teamPlayers = team.NumPlayers(teamID)

    if ( !self:Alive() ) then return false end

    if ( self:GetRelay("arrested", false) ) then return false end

    if ( teamID == self:Team() ) then return false end

    if ( teamData.donatorOnly and !self:IsDonator() ) then return false end

    local canSwitch = hook.Run("CanPlayerChangeTeam", self, teamID)
    if canSwitch != nil and canSwitch == false then return false end

    if ( teamData.xp and teamData.xp > self:GetXP() ) then
        if ( notify ) then
            self:Notify("You do not have the required XP to play as this team.")
        end

        return false
    end

    if ( SERVER and teamData.cp and self:HasIllegalInventoryItem() ) then
        if ( notify ) then
            self:Notify("You cannot join this team while carrying illegal items in your inventory.")
        end

        return false
    end

    if ( teamData.limit ) then
        if ( teamData.percentLimit and teamData.percentLimit == true ) then
            local percentTeam = teamPlayers / player.GetCount()

            if ( !self:IsDonator() and percentTeam > teamData.limit ) then
                if notify then self:Notify("The " .. teamData.name .. " team is currently full.") end
                return false
            end
        else
            if ( !self:IsDonator() and teamPlayers >= teamData.limit ) then
                if notify then self:Notify("The " .. teamData.name .. " team is currently full.") end
                return false
            end
        end
    end

    if ( teamData.customCheck ) then
        local customCheck, customCheckReason = teamData:customCheck(self, teamID)
        if ( customCheck != nil and customCheck == false ) then
            if ( notify and customCheckReason ) then
                self:Notify(customCheckReason)
            end

            return false
        end
    end

    return true
end

function PLAYER:CanBecomeTeamClass(classID, forced)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[classID]
    if ( !classData ) then return end

    if ( !self:Alive() ) then
        return false, "You are not alive, bro how the fuck did this happen man?"
    end

    --[[
    if self:GetTeamClass() == classID then
        return false, "You are already on this class!"
    end
    ]]

    if ( classData.whitelistLevel and classData.whitelistUID and !self:HasTeamWhitelist(classData.whitelistUID, classData.whitelistLevel) ) then
        local add = classData.whitelistFailMessage or ""
        return false, "You must be whitelisted to play as this rank. " .. add
    end

    if classData.xp and classData.xp > self:GetXP() and forced != true then
        return false, "You don't have the XP required to play as this class."
    end

    if classData.limit then
        local classPlayers = 0

        for v, k in player.Iterator() do
            if ( k:Team() != self:Team() ) then continue end
            if ( k:GetTeamClass() == classID ) then
                classPlayers = classPlayers + 1
            end
        end

        if ( classData.percentLimit and classData.percentLimit == true ) then
            local percentClass = classPlayers / player.GetCount()
            if ( percentClass > classData.limit ) then
                return false, classData.name .. " is full."
            end
        else
            if ( classPlayers >= classData.limit ) then
                return false, classData.name .. " is full."
            end
        end
    end

    if ( classData.customCheck ) then
        local customCheck, customCheckReason = classData:customCheck(self, classID)
        if ( customCheck != nil and customCheck == false ) then
            if ( notify and customCheckReason ) then
                self:Notify(customCheckReason)
            end

            return false, "Failed custom check!"
        end
    end

    return true
end

function PLAYER:CanBecomeTeamRank(rankID, forced)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local rankData = teamData.ranks[rankID]

    if ( !self:Alive() ) then
        return false, "You are not alive, bro how the fuck did this happen man?"
    end

    --[[
    if ( self:GetTeamRank() == rankID ) then
        return false, "You are already on this rank!"
    end
    ]]

    if ( rankData.whitelistLevel and !self:HasTeamWhitelist(self:Team(), rankData.whitelistLevel) ) then
        local add = rankData.whitelistFailMessage or ""
        return false, "You must be whitelisted to play as this rank. " .. add
    end

    if ( rankData.xp and rankData.xp > self:GetXP() and forced != true ) then
        return false, "You don't have the XP required to play as this rank."
    end

    if ( rankData.limit ) then
        local rankPlayers = 0

        for k, v in player.Iterator() do
            if ( v:Team() != self:Team() ) then continue end
            if ( v:GetTeamRank() == rankID ) then
                rankPlayers = rankPlayers + 1
            end
        end

        if ( rankData.percentLimit and rankData.percentLimit == true ) then
            local percentRank = rankPlayers / player.GetCount()
            if ( percentRank > rankData.limit ) then
                return false, rankData.name .. " is full."
            end
        else
            if ( rankPlayers >= rankData.limit ) then
                return false, rankData.name .. " is full."
            end
        end
    end

    if ( rankData.customCheck ) then
        local customCheck, customCheckReason = rankData:customCheck(self, rankID)
        if ( customCheck != nil and customCheck == false ) then
            if ( notify and customCheckReason ) then
                self:Notify(customCheckReason)
            end

            return false
        end
    end

    return true
end

function PLAYER:GetTeamClass()
    return self:GetRelay("class", nil)
end

function PLAYER:GetTeamRank()
    return self:GetRelay("rank", nil)
end

function PLAYER:GetTeamClassName()
    if ( !impulse.Teams:FindTeam(self:Team()) ) then
        return ""
    end

    local classData = impulse.Teams:FindTeam(self:Team()).ClassRef
    local plyClass = self:GetRelay("class", nil)

    if ( classData and plyClass and classData[plyClass] ) then
        return classData[plyClass]
    end

    return ""
end

function PLAYER:GetTeamRankName()
    if ( !impulse.Teams:FindTeam(self:Team()) ) then
        return ""
    end

    local rankData = impulse.Teams:FindTeam(self:Team()).ranks
    local plyRank = self:GetRelay("rank", nil)

    if ( rankData and plyRank and rankData[plyRank] ) then
        return rankData[plyRank].name
    end

    return ""
end

function PLAYER:GetTeamData()
    return impulse.Teams:FindTeam(self:Team())
end

function PLAYER:GetTeamClassData()
    local teamData = self:GetTeamData()
    if ( !teamData or !teamData.classes ) then return end

    local classID = self:GetTeamClass()
    if ( !classID ) then return end

    return teamData.classes[classID]
end

function PLAYER:GetTeamRankData()
    local teamData = self:GetTeamData()
    if ( !teamData or !teamData.ranks ) then return end

    local rankID = self:GetTeamRank()
    if ( !rankID ) then return end

    return teamData.ranks[rankID]
end

function PLAYER:IsCP()
    local teamData = impulse.Teams:FindTeam(self:Team())
    if ( teamData ) then
        return teamData.cp or false
    end
end

function PLAYER:GetAmbientSound()
    local rankData = self:GetTeamRankData()
    local classData = self:GetTeamClassData()
    local teamData = self:GetTeamData()

    if ( rankData and rankData.ambientSounds ) then
        return rankData.ambientSounds[math.random(#rankData.ambientSounds)]
    elseif ( classData and classData.ambientSounds ) then
        return classData.ambientSounds[math.random(#classData.ambientSounds)]
    elseif ( teamData and teamData.ambientSounds ) then
        return teamData.ambientSounds[math.random(#teamData.ambientSounds)]
    end
end
