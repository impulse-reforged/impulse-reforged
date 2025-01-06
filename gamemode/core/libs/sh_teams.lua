impulse.Teams = impulse.Teams or {}
impulse.Teams.Stored = impulse.Teams.Stored or {}
impulse.Teams.List = impulse.Teams.List or {}

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

    return id
end

function impulse.Teams:FindTeam(identifier)
    if ( !identifier ) then return end

    tostring(identifier)

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

    tostring(identifier)

    for k, v in ipairs(impulse.Teams.Stored) do
        if ( !v.classes ) then continue end

        for k, v in ipairs(v.classes) do
            if ( impulse.Util:StringMatches(tostring(v.name), identifier) ) then
                return v
            elseif ( k == tonumber(identifier) ) then
                return v
            end
        end
    end
end

function impulse.Teams:FindRank(identifier)
    if ( !identifier ) then return end

    tostring(identifier)
    
    for k, v in ipairs(impulse.Teams.Stored) do
        if ( !v.ranks ) then continue end

        for k, v in ipairs(v.ranks) do
            if ( impulse.Util:StringMatches(tostring(v.name), identifier) ) then
                return v
            elseif ( k == tonumber(identifier) ) then
                return kv
            end
        end
    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:CanBecomeTeam(teamID, notify)
    local teamData = impulse.Teams.Stored[teamID]
    local teamPlayers = team.NumPlayers(teamID)

    if ( !self:Alive() ) then return false end

    if ( self:GetNetVar("arrested", false) ) then return false end

    if ( teamID == self:Team() ) then return false end

    if ( teamData.donatorOnly and !self:IsDonator() ) then return false end

    local canSwitch = hook.Run("CanPlayerChangeTeam", self, teamID)
    if canSwitch != nil and canSwitch == false then return false end

    if ( teamData.xp and teamData.xp > self:GetXP() ) then
        if ( notify ) then
            self:Notify("You don't have the XP required to play as this team.")
        end

        return false
    end

    if ( SERVER and teamData.cp ) then
        if ( self:HasIllegalInventoryItem() ) then
            if ( notify ) then
                self:Notify("You cannot become this team with illegal items in your inventory.")
            end

            return false
        end
    end

    if ( teamData.limit ) then
        if ( teamData.percentLimit and teamData.percentLimit == true ) then
            local percentTeam = teamPlayers / player.GetCount()

            if ( !self:IsDonator() and percentTeam > teamData.limit ) then
                if notify then self:Notify(teamData.name .. " is full.") end
                return false
            end
        else
            if ( !self:IsDonator() and teamPlayers >= teamData.limit ) then
                if notify then self:Notify(teamData.name .. " is full.") end
                return false
            end
        end
    end

    if ( teamData.customCheck ) then
        local customCheck = teamData.customCheck(self, teamID)
        if ( customCheck != nil and customCheck == false ) then
            return false
        end
    end

    return true
end

function PLAYER:CanBecomeTeamClass(classID, forced)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[classID]
    local classPlayers = 0

    if ( !classData ) then return end

    if not self:Alive() then
        return false, "You are not alive, bro how the fuck did this happen man?"
    end

    --[[
    if self:GetTeamClass() == classID then
        return false, "You are already on this class!"
    end
    ]]

    if classData.whitelistLevel and classData.whitelistUID then
        if ( !self:HasTeamWhitelist(classData.whitelistUID, classData.whitelistLevel) ) then
            local add = classData.whitelistFailMessage or ""
            return false, "You must be whitelisted to play as this rank. "..add
        end
    end

    if classData.xp and classData.xp > self:GetXP() and forced != true then
        return false, "You don't have the XP required to play as this class."
    end

    if classData.limit then
        local classPlayers = 0

        for v, k in player.Iterator() do
            if not k:Team() == self:Team() then continue end
            if k:GetTeamClass() == classID then
                classPlayers = classPlayers + 1
            end
        end

        if classData.percentLimit and classData.percentLimit == true then
            local percentClass = classPlayers / player.GetCount()
            if percentClass > classData.limit then
                return false, classData.name .. " is full."
            end
        else
            if classPlayers >= classData.limit then
                return false, classData.name .. " is full."
            end
        end
    end

    if classData.customCheck then
        local customCheck = classData.customCheck(self, classID)
        if ( customCheck != nil and customCheck == false ) then
            return false, "Failed custom check!"
        end
    end

    return true
end

function PLAYER:CanBecomeTeamRank(rankID, forced)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local rankData = teamData.ranks[rankID]
    local rankPlayers = 0

    if ( !self:Alive() ) then
        return false, "You are not alive, bro how the fuck did this happen man?"
    end

    --[[
    if self:GetTeamRank() == rankID then
        return false, "You are already on this rank!"
    end
    ]]

    if ( rankData.whitelistLevel and !self:HasTeamWhitelist(self:Team(), rankData.whitelistLevel) ) then
        local add = rankData.whitelistFailMessage or ""
        return false, "You must be whitelisted to play as this rank. "..add
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
        local customCheck = rankData.customCheck(self, rankID)
        if ( customCheck != nil and customCheck == false ) then
            return false
        end
    end

    return true
end

function PLAYER:GetTeamClass()
    return self:GetNetVar("class", nil)
end

function PLAYER:GetTeamRank()
    return self:GetNetVar("rank", nil)
end

function PLAYER:GetTeamClassName()
    if ( !impulse.Teams:FindTeam(self:Team()) ) then
        return ""
    end

    local classData = impulse.Teams:FindTeam(self:Team()).ClassRef
    local plyClass = self:GetNetVar("class", nil)

    if ( classData and plyClass ) then
        return classData[plyClass]
    end

    return "Default"
end

function PLAYER:GetTeamRankName()
    if ( !impulse.Teams:FindTeam(self:Team()) ) then
        return ""
    end

    local rankData = impulse.Teams:FindTeam(self:Team()).ranks
    local plyRank = self:GetNetVar("rank", nil)

    if ( rankData and plyRank ) then
        return rankData[plyRank].name
    end

    return "Default"
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
        return rankData.ambientSounds[math.random(1, #rankData.ambientSounds)]
    elseif ( classData and classData.ambientSounds ) then
        return classData.ambientSounds[math.random(1, #classData.ambientSounds)]
    elseif ( teamData and teamData.ambientSounds ) then
        return teamData.ambientSounds[math.random(1, #teamData.ambientSounds)]
    end
end