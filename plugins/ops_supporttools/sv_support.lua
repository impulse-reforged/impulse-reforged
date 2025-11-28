impulse.Ops.ST = impulse.Ops.ST or {}

util.AddNetworkString("impulseOpsSTOpenTool")
util.AddNetworkString("impulseOpsSTDoRefund")
util.AddNetworkString("impulseOpsSTGetRefund")
util.AddNetworkString("impulseOpsSTDoOOCEnabled")
util.AddNetworkString("impulseOpsSTDoTeamLocked")
util.AddNetworkString("impulseOpsSTDoGroupRemove")

local function isSupport(client)
    if ( !client:IsSuperAdmin() ) then
        if ( client:GetUserGroup() != "communitymanager" ) then
            return false
        end
    end

    return true
end

local lockedTeams = lockedTeams or {}

net.Receive("impulseOpsSTDoOOCEnabled", function(len, client)
    if ( !isSupport(client) ) then return end

    local enabled = net.ReadBool()

    impulse.OOCClosed = !enabled

    client:Notify("OOC has been "..(enabled and "enabled" or "disabled").."..")
end)

net.Receive("impulseOpsSTDoGroupRemove", function(len, client)
    if ( !isSupport(client) ) then return end

    local name = net.ReadString()
    local groupData = impulse.Group.Groups[name]

    if not groupData or not groupData.ID then
        impulse.Group:RemoveByName(name)
        client:Notify("No loaded group was found, however, we have attempted to remove it from the database.")
        return
    end
    
    for v, k in pairs(groupData.Members) do
        local targEnt = player.GetBySteamID(v)

        if IsValid(targEnt) then
            targEnt:SetRelay("groupName", nil)
            targEnt:SetRelay("groupRank", nil)
            targEnt:Notify("You have been removed from the "..name.." group as it has been removed by the staff team for violations of the RP group rules.")
        end
    end

    impulse.Group:Remove(groupData.ID)
    impulse.Group:RemovePlayerMass(groupData.ID)
    impulse.Group.Groups[name] = nil

    client:Notify("The "..name.." group has been successfully removed.")
end)

net.Receive("impulseOpsSTDoTeamLocked", function(len, client)
    if ( !isSupport(client) ) then return end

    local teamid = net.ReadUInt(8)
    local locked = net.ReadBool()

    if teamid == impulse.Config.DefaultTeam then
        return client:Notify("You cannot lock the default team.")
    end

    lockedTeams[teamid] = locked

    client:Notify("Team "..teamid.." has been successfully "..(locked and "locked" or "unlocked").."..")
end)

net.Receive("impulseOpsSTDoRefund", function(len, client)
    if ( !isSupport(client) ) then return end

    local steamid = net.ReadString()
    local len = net.ReadUInt(32)
    local items = pon.decode(net.ReadData(len))
    local steamid64 = util.SteamIDTo64(steamid)

    local query = mysql:Select("impulse_players")
    query:Select("id")
    query:Where("steamid", steamid64)
    query:Callback(function(result)
        if ( !IsValid(client) ) then return end

        if ( type(result) != "table" or #result == 0 ) then
            return client:Notify("This Steam account has not joined the server yet, or the SteamID64 is invalid.")
        end

        local impulseID = result[1].id
        local refundData = {}

        for k, v in pairs(items) do
            if ( !impulse.Inventory.ItemsStored[k] ) then continue end

            refundData[k] = v
        end

        file.CreateDir("impulse-reforged/support-refunds")
        file.Write("impulse-reforged/support-refunds/"..steamid64..".txt", util.TableToJSON(refundData))

        client:Notify("Successfully issued a support refund for user "..steamid64.."..")
    end)

    query:Execute()
end)

function impulse.Ops.ST.Open(client)
    net.Start("impulseOpsSTOpenTool")
    net.Send(client)
end

function PLUGIN:PostInventorySetup(client)
    local refundData = file.Read("impulse-reforged/support-refunds/"..client:SteamID64()..".txt", "DATA")
    if ( refundData ) then
        if ( !IsValid(client) ) then return end
        
        for k, v in pairs(refundData) do
            if ( !impulse.Inventory.ItemsStored[k] ) then continue end
            
            for i = 1, v do
                client:GiveItem(v, INVENTORY_STORAGE) -- refund to storage 
            end
        end

        file.Delete("impulse-reforged/support-refunds/"..client:SteamID64()..".txt")

        local data = pon.encode(refundData)

        net.Start("impulseOpsSTGetRefund")
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
        net.Send(client)
    end
end

function PLUGIN:CanPlayerChangeTeam(client, newTeam)
    if ( lockedTeams[newTeam] ) then
        if ( SERVER ) then
            client:Notify("Sorry, this team is temporarily locked. Please try again later.")
        end

        return false
    end
end
