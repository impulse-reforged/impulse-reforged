impulse.Teams = impulse.Teams or {}
impulse.Teams.Data = impulse.Teams.Data or {}
impulse.Teams.ClassRef = impulse.Teams.ClassRef or {}
impulse.Teams.NameRef = impulse.Teams.NameRef or {}
teamID = 0

CLASS_EMPTY = 0

function impulse.Teams.Define(teamData)
    teamID = teamID + 1
    impulse.Teams.Data[teamID] = teamData
    impulse.Teams.NameRef[teamData.name] = teamID

    if teamData.classes then
    	impulse.Teams.Data[teamID].ClassRef = {}

    	for id,k in pairs(teamData.classes) do
    		impulse.Teams.Data[teamID].ClassRef[id] = k.name
    	end
    end

    if teamData.ranks then
    	impulse.Teams.Data[teamID].RankRef = {}

    	for id,k in pairs(teamData.ranks) do
    		impulse.Teams.Data[teamID].RankRef[id] = k.name
    	end
    end

    team.SetUp(teamID, teamData.name, teamData.color, false)
    return teamID
end

function meta:CanBecomeTeam(teamID, notify)
	local teamData = impulse.Teams.Data[teamID]
	local teamPlayers = team.NumPlayers(teamID)

	if not self:Alive() then return false end

	if self:GetSyncVar(SYNC_ARRESTED, false) then
		return false
	end

	if teamID == self:Team() then
		return false
	end

	if teamData.donatorOnly and !self:IsDonator() then
		return false
	end

	local canSwitch = hook.Run("CanPlayerChangeTeam", self, teamID)

	if canSwitch != nil and canSwitch == false then
		return false
	end

	if teamData.xp and teamData.xp > self:GetXP() then
		if notify then self:Notify("You don't have the XP required to play as this team.") end
		return false
	end

	if SERVER and teamData.cp then
		if self:HasIllegalInventoryItem() then
			if notify then self:Notify("You cannot become this team with illegal items in your inventory.") end
			return false
		end
	end

	if teamData.limit then
		if teamData.percentLimit and teamData.percentLimit == true then
			local percentTeam = teamPlayers / player.GetCount()

			if not self:IsDonator() and percentTeam > teamData.limit then
				if notify then self:Notify(teamData.name .. " is full.") end
				return false
			end
		else
			if not self:IsDonator() and teamPlayers >= teamData.limit then
				if notify then self:Notify(teamData.name .. " is full.") end
				return false
			end
		end
	end

	if teamData.customCheck then
		local r = teamData.customCheck(self, teamID)

		if r != nil and r == false then
			return false
		end
	end

	return true
end

function meta:CanBecomeTeamClass(classID, forced)
	local teamData = impulse.Teams.Data[self:Team()]
	local classData = teamData.classes[classID]
	local classPlayers = 0

	if not ( classData ) then
		return
	end

	if not self:Alive() then
		return false, "You are not alive, bro how the fuck did this happen man?"
	end

	--[[
	if self:GetTeamClass() == classID then
		return false, "You are already on this class!"
	end
	]]

	if classData.whitelistLevel and classData.whitelistUID then
		if not ( self:HasTeamWhitelist(classData.whitelistUID, classData.whitelistLevel) ) then
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
		local r = classData.customCheck(self, classID)

		if r != nil and r == false then
			return false, "Failed custom check!"
		end
	end

	return true
end

function meta:CanBecomeTeamRank(rankID, forced)
	local teamData = impulse.Teams.Data[self:Team()]
	local rankData = teamData.ranks[rankID]
	local rankPlayers = 0

	if not self:Alive() then
		return false, "You are not alive, bro how the fuck did this happen man?"
	end

	--[[
	if self:GetTeamRank() == rankID then
		return false, "You are already on this rank!"
	end
	]]

	if rankData.whitelistLevel and !self:HasTeamWhitelist(self:Team(), rankData.whitelistLevel) then
		local add = rankData.whitelistFailMessage or ""
		return false, "You must be whitelisted to play as this rank. "..add
	end

	if rankData.xp and rankData.xp > self:GetXP() and forced != true then
		return false, "You don't have the XP required to play as this rank."
	end

	if rankData.limit then
		local rankPlayers = 0

		for v, k in player.Iterator() do
			if not k:Team() == self:Team() then continue end
			if k:GetTeamRank() == rankID then
				rankPlayers = rankPlayers + 1
			end
		end

		if rankData.percentLimit and rankData.percentLimit == true then
			local percentRank = rankPlayers / player.GetCount()

			if percentRank > rankData.limit then
				return false, rankData.name .. " is full."
			end
		else
			if rankPlayers >= rankData.limit then
				return false, rankData.name .. " is full."
			end
		end
	end

	if rankData.customCheck then
		local r = rankData.customCheck(self, rankID)

		if r != nil and r == false then
			return false
		end
	end

	return true
end

function meta:GetTeamClassName()
	if not impulse.Teams.Data[self:Team()] then return "" end

	local classRef = impulse.Teams.Data[self:Team()].ClassRef
	local plyClass = self:GetSyncVar(SYNC_CLASS, nil)

	if classRef and plyClass then
		return classRef[plyClass]
	end

	return "Default"
end

function meta:GetTeamClass()
	return self:GetSyncVar(SYNC_CLASS, 0)
end

function meta:GetTeamRankName()
	local rankData = impulse.Teams.Data[self:Team()].ranks
	local plyRank = self:GetSyncVar(SYNC_RANK, nil)

	if rankData and plyRank then
		return rankData[plyRank].name
	end

	return "Default"
end

function meta:GetTeamRank()
	return self:GetSyncVar(SYNC_RANK, 0)
end

function meta:GetTeamData()
	return impulse.Teams.Data[self:Team()]
end

function meta:GetTeamClassData()
	local teamData = self:GetTeamData()
	if not teamData then return end
	if not teamData.classes then return end

	local classID = self:GetTeamClass()
	if not classID then return end

	return teamData.classes[classID]
end

function meta:GetTeamRankData()
	local teamData = self:GetTeamData()
	if not teamData then return end
	if not teamData.ranks then return end

	local rankID = self:GetTeamRank()
	if not rankID then return end

	return teamData.ranks[rankID]
end

function meta:IsCP()
	local teamData = impulse.Teams.Data[self:Team()]

	if teamData then
		return teamData.cp or false
	end
end

function meta:GetAmbientSound()
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

function impulse.Teams.FindTeam(identifier)
	for k, v in pairs(impulse.Teams.Data) do
		if v.name:lower():find(identifier:lower()) then
			return k, v
		elseif k == tonumber(identifier) then
			return k, v
		end
	end
end

function impulse.Teams.FindClass(identifier)
	for k, v in pairs(impulse.Teams.Data) do
		if not v.classes then continue end
		for id, class in pairs(v.classes) do
			if class.name:lower():find(identifier:lower()) then
				return id, class
			elseif id == tonumber(identifier) then
				return id, class
			end
		end
	end
end

function impulse.Teams.FindRank(identifier)
	for k, v in ipairs(impulse.Teams.Data) do
		if not ( v.ranks ) then
			continue
		end

		for id, rank in ipairs(v.ranks) do
			if rank.name:lower():find(identifier:lower()) or id == tonumber(identifier) then
				return id, rank
			end
		end
	end
end