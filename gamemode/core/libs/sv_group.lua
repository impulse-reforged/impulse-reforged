--- Handles the creation and editing of player groups
-- @module impulse.Group

local DEFAULT_RANKS = pon.encode({
    ["Owner"] = {
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [8] = true,
        [99] = true
    },
    ["Member"] = {
        [0] = true,
        [1] = true,
        [2] = true
    }
})

--- Creates a new group
-- @realm server
-- @string name The name of the group
-- @number ownerid Owner's SteamID64
-- @number maxsize Maximum amount of members
-- @number maxstorage Maximum storage amount
-- @table ranks Table of ranks
-- @func callback Callback function
function impulse.Group:Create(name, ownerid, maxsize, maxstorage, ranks, callback)
    impulse.Group:IsNameUnique(name, function(unique)
        if unique then
            local query = mysql:Insert("impulse_rpgroups")
            query:Insert("ownerid", ownerid)
            query:Insert("name", name)
            query:Insert("maxsize", maxsize)
            query:Insert("maxstorage", maxstorage)
            query:Insert("ranks", ranks and pon.encode(ranks) or DEFAULT_RANKS)
            query:Callback(function(result, status, id)
                if callback then
                    callback(id)
                end
            end)

            query:Execute()
        else
            callback()
        end
    end)
end

--- Removes a group
-- @realm server
-- @number groupID Group ID
function impulse.Group:Remove(groupID)
    local query = mysql:Delete("impulse_rpgroups")
    query:Where("id", groupID)
    query:Execute()
end

--- Removes a group by name
-- @realm server
-- @string name Group name
function impulse.Group:RemoveByName(name)
    local query = mysql:Delete("impulse_rpgroups")
    query:Where("name", name)
    query:Execute()
end

--- Adds a player to a group
-- @realm server
-- @string steamid Player's SteamID64
-- @number groupID Group ID
-- @string rank Rank
-- @func[opt] callback Callback function
function impulse.Group:AddPlayer(steamid, groupID, rank, callback)
    local query = mysql:Update("impulse_players")
    query:Update("rpgroup", groupID)
    query:Update("rpgrouprank", rank or impulse.Group:GetDefaultRank(name))
    query:Where("steamid", steamid)
    query:Callback(function()
        if callback then
            callback()
        end
    end)
    query:Execute()
end

--- Removes a player from a group
-- @realm server
-- @string steamid Player's SteamID64
-- @number groupID Group ID
function impulse.Group:RemovePlayer(steamid, groupID)
    local query = mysql:Update("impulse_players")
    query:Update("rpgroup", nil)
    query:Update("rpgrouprank", "")
    query:Where("steamid", steamid)
    query:Execute()
end

--- Removes all players from a group
-- @realm server
-- @number groupID Group ID
function impulse.Group:RemovePlayerMass(groupID)
    local query = mysql:Update("impulse_players")
    query:Update("rpgroup", nil)
    query:Update("rpgrouprank", "")
    query:Where("rpgroup", groupID)
    query:Execute()
end

--- Updates a player's rank
-- @realm server
-- @string steamid Player's SteamID64
-- @string rank Rank
function impulse.Group:UpdatePlayerRank(steamid, rank)
    local query = mysql:Update("impulse_players")
    query:Update("rpgrouprank", rank)
    query:Where("steamid", steamid)
    query:Execute()
end

--- Shifts everyone in a group from one rank to another
-- @realm server
-- @number groupID Group ID
-- @string rank Rank to shift from
-- @string newRank Rank to shift to
function impulse.Group:PlayerRankShift(groupID, rank, newRank)
    local query = mysql:Update("impulse_players")
    query:Update("rpgrouprank", newRank)
    query:Where("rpgroup", groupID)
    query:Where("rpgrouprank", rank)
    query:Execute()
end

--- Updates a group's ranks
-- @realm server
-- @number groupID Group ID
-- @table ranks Table of ranks
function impulse.Group:UpdateRanks(groupID, ranks)
    local query = mysql:Update("impulse_rpgroups")
    query:Update("ranks", pon.encode(ranks))
    query:Where("id", groupID)
    query:Execute()
end

--- Updates a group's max size
-- @realm server
-- @number groupID Group ID
-- @number max Max size
function impulse.Group:UpdateMaxMembers(groupID, max)
    local query = mysql:Update("impulse_rpgroups")
    query:Update("maxsize", max)
    query:Where("id", groupID)
    query:Execute()
end

--- Updates a group's data
-- @realm server
-- @number groupID Group ID
-- @table data Data
function impulse.Group:UpdateData(groupID, data)
    local query = mysql:Update("impulse_rpgroups")
    query:Update("data", pon.encode(data))
    query:Where("id", groupID)
    query:Execute()
end

--- Computes a group's members
-- @realm server
-- @string name Group name
-- @func[opt] callback Callback function
function impulse.Group:ComputeMembers(name, callback)
    local id = impulse.Group.Groups[name].ID

    local query = mysql:Select("impulse_players")
    query:Select("steamid")
    query:Select("rpname")
    query:Select("rpgroup")
    query:Select("rpgrouprank")
    query:Where("rpgroup", id)
    query:Callback(function(result)
        local members = {}
        local membercount = 0

        if type(result) == "table" and #result > 0 then
            for v, k in pairs(result) do
                membercount = membercount + 1
                members[k.steamid] = {Name = k.rpname, Rank = k.rpgrouprank or impulse.Group:GetDefaultRank(name)}
            end
        end

        impulse.Group.Groups[name].Members = members
        impulse.Group.Groups[name].MemberCount = membercount

        if callback then
            callback()
        end
    end)

    query:Execute()
end

--- Shifts all members in a group from one rank to another
-- @realm server
-- @string name Group name
-- @string from Rank to shift from
-- @string to Rank to shift to
function impulse.Group:RankShift(name, from, to)
    local group = impulse.Group.Groups[name]

    impulse.Group:PlayerRankShift(group.ID, from, to)

    for v, k in pairs(group.Members) do
        if k.Rank == from then
            local client = player.GetBySteamID(v)

            impulse.Group.Groups[name].Members[v].Rank = to

            if type(client) == "Player" then
                client:GroupAdd(name, to, true)
            else
                impulse.Group:NetworkMemberToOnline(name, v)
            end
        end
    end

    impulse.Group:NetworkRankToOnline(name, to)
end

--- Gets a group's default rank
-- @realm server
-- @string name Group name
-- @treturn string Default rank
function impulse.Group:GetDefaultRank(name)
    local data = impulse.Group.Groups[name]

    for v, k in pairs(data.Ranks) do
        if k[0] then
            return v
        end
    end

    return "Member"
end

function impulse.Group:SetMetaData(name, info, col)
    local grp = impulse.Group.Groups[name]
    local id = grp.ID
    local data = grp.Data or {}

    data.Info = info or grp.Data.Info
    data.Col = col or (grp.Data.Col and Color(grp.Data.Col.r, grp.Data.Col.g, grp.Data.Col.b)) or nil

    impulse.Group.Groups[name].Data = data
    impulse.Group:UpdateData(id, data)
end

function impulse.Group:NetworkMetaData(to, name)
    local grp = impulse.Group.Groups[name]

    net.Start("impulseGroupMetadata")
    net.WriteString(grp.Data.Info or "")

    if grp.Data.Col then
        net.WriteColor(Color(grp.Data.Col.r, grp.Data.Col.g, grp.Data.Col.b))
    else
        net.WriteColor(color_black)
    end

    net.Send(to)
end

function impulse.Group:NetworkMetaDataToOnline(name)
    local grp = impulse.Group.Groups[name]

    local rf = RecipientFilter()

    for v, k in player.Iterator() do
        local x = k:GetRelay("groupName", nil)

        if x and x == name then
            rf:AddPlayer(k)
        end
    end

    net.Start("impulseGroupMetadata")
    net.WriteString(grp.Data.Info or "")
    net.WriteColor(grp.Data.Col or color_black)
    net.Send(rf)
end

function impulse.Group:NetworkMember(to, name, sid)
    local member = impulse.Group.Groups[name].Members[sid]

    net.Start("impulseGroupMember")
    net.WriteString(sid)
    net.WriteString(member.Name)
    net.WriteString(member.Rank)
    net.Send(to)
end

function impulse.Group:NetworkMemberToOnline(name, sid)
    local member = impulse.Group.Groups[name].Members[sid]

    local rf = RecipientFilter()

    for v, k in player.Iterator() do
        local x = k:GetRelay("groupName", nil)

        if x and x == name then
            rf:AddPlayer(k)
        end
    end

    net.Start("impulseGroupMember")
    net.WriteString(sid)
    net.WriteString(member.Name)
    net.WriteString(member.Rank)
    net.Send(rf)
end

function impulse.Group:NetworkMemberRemoveToOnline(name, sid)
    local rf = RecipientFilter()

    for v, k in player.Iterator() do
        local x = k:GetRelay("groupName", nil)

        if x and x == name then
            rf:AddPlayer(k)
        end
    end

    net.Start("impulseGroupMemberRemove")
    net.WriteString(sid)
    net.Send(rf)
end

function impulse.Group:NetworkAllMembers(to, name)
    local members = impulse.Group.Groups[name].Members

    for v, k in pairs(members) do
        impulse.Group:NetworkMember(to, name, v)
    end
end

function impulse.Group:NetworkRanksToOnline(name)
    local ranks = impulse.Group.Groups[name].Ranks
    local data = pon.encode(ranks)
    local rf = RecipientFilter()

    for v, k in player.Iterator() do
        local x = k:GetRelay("groupName", nil)

        if x and x == name then
            if k:GroupHasPermission(5) or k:GroupHasPermission(6) then
                rf:AddPlayer(k)
            end
        end
    end

    net.Start("impulseGroupRanks")
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.Send(rf)
end

function impulse.Group:NetworkRank(name, to, rankName)
    local rank = impulse.Group.Groups[name].Ranks[rankName]
    local data = pon.encode(rank)

    net.Start("impulseGroupRank")
    net.WriteString(rankName)
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.Send(to)
end

function impulse.Group:NetworkRankToOnline(name, rankName)
    local rank = impulse.Group.Groups[name].Ranks[rankName]
    local data = pon.encode(rank)
    local rf = RecipientFilter()

    for v, k in player.Iterator() do
        local x = k:GetRelay("groupName", nil)
        local r = k:GetRelay("groupRank", nil)

        if x and x == name and r == rank then
            if k:GroupHasPermission(5) or k:GroupHasPermission(6) then continue end

            rf:AddPlayer(k)
        end
    end

    net.Start("impulseGroupRank")
    net.WriteString(rankName)
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.Send(rf)
end

--- Networks all ranks to a player
-- @realm server
-- @param to Player
-- @string name Group name
function impulse.Group:NetworkRanks(to, name)
    local ranks = impulse.Group.Groups[name].Ranks
    local data = pon.encode(ranks)

    net.Start("impulseGroupRanks")
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.Send(to)
end

local function postCompute(self, name, rank, skipDb)
    if !IsValid(self) then return end

    impulse.Group:NetworkMemberToOnline(name, self:SteamID64())

    self:SetRelay("groupName", name)
    self:SetRelay("groupRank", rank)

    if !skipDb then
        impulse.Group:NetworkAllMembers(self, name)
    end

    if self:GroupHasPermission(5) or self:GroupHasPermission(6) then
        impulse.Group:NetworkRanks(self, name)
    else
        impulse.Group:NetworkRank(name, self, rank)
    end

    impulse.Group:NetworkMetaData(self, name)
end

local PLAYER = FindMetaTable("Player")

--- Adds a player to a group
-- @realm server
-- @string name Group name
-- @string[opt] rank Rank
-- @bool[opt = false] skipDb If true, the player will not be added to the database
function PLAYER:GroupAdd(name, rank, skipDb)
    local id = impulse.Group.Groups[name].ID
    local rank = rank or impulse.Group:GetDefaultRank(name)

    if !skipDb then
        impulse.Group:AddPlayer(self:SteamID64(), id, rank)
    end

    impulse.Group:ComputeMembers(name, function()
        postCompute(self, name, rank, skipDb)
    end)
end

--- Removes a player from a group
-- @realm server
-- @string name Group name
function PLAYER:GroupRemove(name)
    local id = impulse.Group.Groups[name].ID
    local sid = self:SteamID64()

    impulse.Group:RemovePlayer(sid)
    impulse.Group:ComputeMembers(name)
    impulse.Group:NetworkMemberRemoveToOnline(name, sid)

    self:SetRelay("groupName", nil)
    self:SetRelay("groupRank", nil)
end

--- Loads a group for a player
-- @realm server
-- @number groupID Group ID
-- @string[opt] rank Rank
function PLAYER:GroupLoad(groupID, rank)
    impulse.Group:Load(groupID, function(name)
        if !IsValid(self) then return end

        impulse.Group:ComputeMembers(name, function()
            if !IsValid(self) then return end

            impulse.Group:NetworkAllMembers(self, name)

            if self:GroupHasPermission(5) or self:GroupHasPermission(6) then
                impulse.Group:NetworkRanks(self, name)
            end

            impulse.Group:NetworkMetaData(self, name)
        end)

        if rank then
            if !impulse.Group.Groups[name].Ranks[rank] then
                rank = impulse.Group:GetDefaultRank(name)
                impulse.Group:UpdatePlayerRank(self:SteamID64(), rank)
            end
        end

        rank = rank or impulse.Group:GetDefaultRank(name)

        self:SetRelay("groupName", name)
        self:SetRelay("groupRank", rank)

        impulse.Group:NetworkRank(name, self, rank)

        if self:IsDonator() and self:GroupHasPermission(99) and impulse.Group.Groups[name].MaxSize < impulse.Config.GroupMaxMembersVIP then
            impulse.Group:UpdateMaxMembers(groupID, impulse.Config.GroupMaxMembersVIP)
            impulse.Group.Groups[name].MaxSize = impulse.Config.GroupMaxMembersVIP
        end
    end)
end

--- Returns wether or !the provided group name is unique or not
-- @realm server
-- @string name Group name
-- @func callback Callback function
-- @usage impulse.Group:IsNameUnique("My Group", function(unique)
--     if unique then
--         print("Group name is unique!")
--     else
--         print("Group name is not unique!")
--     end
-- end)
function impulse.Group:IsNameUnique(name, callback)
    local query = mysql:Select("impulse_rpgroups")
    query:Select("name")
    query:Where("name", name)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 then
            return callback(false)
        else
            return callback(true)
        end
    end)

    query:Execute()
end

--- Loads a group by ID
-- @realm server
-- @number id Group ID
-- @func onLoaded Callback function
-- @internal
-- @usage impulse.Group:Load(1, function(name)
--     print("Loaded group: " .. name)
-- end)
function impulse.Group:Load(id, onLoaded)
    local query = mysql:Select("impulse_rpgroups")
    query:Select("ownerid")
    query:Select("name")
    query:Select("type")
    query:Select("maxsize")
    query:Select("maxstorage")
    query:Select("ranks")
    query:Select("data")
    query:Where("id", id)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 then
            local data = result[1]

            if impulse.Group.Groups[data.name] then
                return onLoaded(data.name)
            end

            impulse.Group.Groups[data.name] = {
                ID = id,
                OwnerID = data.ownerid,
                Type = data.type,
                MaxSize = data.maxsize,
                MaxStorage = data.maxstorage,
                Ranks = pon.decode(data.ranks),
                Data = (data.data and pon.decode(data.data) or {})
            }

            if onLoaded then
                onLoaded(data.name)
            end
        end
    end)

    query:Execute()
end
