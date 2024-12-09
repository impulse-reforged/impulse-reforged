impulse.Ops.ST = impulse.Ops.ST or {}

util.AddNetworkString("impulseOpsSTOpenTool")
util.AddNetworkString("impulseOpsSTDoRefund")
util.AddNetworkString("impulseOpsSTGetRefund")
util.AddNetworkString("impulseOpsSTDoOOCEnabled")
util.AddNetworkString("impulseOpsSTDoTeamLocked")
util.AddNetworkString("impulseOpsSTDoGroupRemove")

local function isSupport(ply)
    if ( !ply:IsSuperAdmin() ) then
        if ( ply:GetUserGroup() != "communitymanager" ) then
            return false
        end
    end

    return true
end

local lockedTeams = lockedTeams or {}

net.Receive("impulseOpsSTDoOOCEnabled", function(len, ply)
    if ( !isSupport(ply) ) then return end

    local enabled = net.ReadBool()

    impulse.OOCClosed = !enabled

    ply:Notify("OOC enabled set to "..(enabled and "true" or "false")..".")
end)

net.Receive("impulseOpsSTDoGroupRemove", function(len, ply)
    if ( !isSupport(ply) ) then return end

    local name = net.ReadString()
    local groupData = impulse.Group.Groups[name]

    if not groupData or not groupData.ID then
        impulse.Group.RemoveByName(name)
        ply:Notify("No loaded group found, however, we have attempted to remove it from the database.")
        return
    end
    
    for v, k in pairs(groupData.Members) do
        local targEnt = player.GetBySteamID(v)

        if IsValid(targEnt) then
            targEnt:SetNetVar("groupName", nil)
            targEnt:SetNetVar("groupRank", nil)
            targEnt:Notify("You were removed from the "..name.." group as it has been removed by the staff team for violations of the RP group rules.")
        end
    end

    impulse.Group.Remove(groupData.ID)
    impulse.Group.RemovePlayerMass(groupData.ID)
    impulse.Group.Groups[name] = nil

    ply:Notify("The "..name.." group has been removed.")
end)

net.Receive("impulseOpsSTDoTeamLocked", function(len, ply)
    if ( !isSupport(ply) ) then return end

    local teamid = net.ReadUInt(8)
    local locked = net.ReadBool()

    if teamid == impulse.Config.DefaultTeam then
        return ply:Notify("You can't lock the default team.")
    end

    lockedTeams[teamid] = locked

    ply:Notify("Team "..teamid.." has been "..(locked and "locked" or "unlocked")..".")
end)

net.Receive("impulseOpsSTDoRefund", function(len, ply)
    if ( !isSupport(ply) ) then return end

    local steamid = net.ReadString()
    local len = net.ReadUInt(32)
    local items = pon.decode(net.ReadData(len))
    local steamid64 = util.SteamIDTo64(steamid)

    local query = mysql:Select("impulse_players")
    query:Select("id")
    query:Where("steamid", steamid64)
    query:Callback(function(result)
        if ( !IsValid(ply) ) then return end

        if ( type(result) != "table" or #result == 0 ) then
            return ply:Notify("This Steam account has not joined the server yet or the SteamID is invalid.")
        end

        local impulseID = result[1].id
        local refundData = {}

        for k, v in pairs(items) do
            if ( !impulse.Inventory.ItemsRef[k] ) then continue end

            refundData[k] = v
        end

        file.CreateDir("impulse-reforged/support-refunds")
        file.Write("impulse-reforged/support-refunds/"..steamid64..".txt", util.TableToJSON(refundData))

        ply:Notify("Issued support refund for user "..steamid64..".")
    end)

    query:Execute()
end)

function impulse.Ops.ST.Open(ply)
    net.Start("impulseOpsSTOpenTool")
    net.Send(ply)
end

function PLUGIN:PostInventorySetup(ply)
    local refundData = file.Read("impulse-reforged/support-refunds/"..ply:SteamID64()..".txt", "DATA")
    if ( refundData ) then
        if ( !IsValid(ply) ) then return end
        
        for k, v in pairs(refundData) do
            if ( !impulse.Inventory.ItemsRef[k] ) then continue end
            
            for i = 1, v do
                ply:GiveItem(v, INVENTORY_STORAGE) -- refund to storage 
            end
        end

        file.Delete("impulse-reforged/support-refunds/"..ply:SteamID64()..".txt")

        local data = pon.encode(refundData)

        net.Start("impulseOpsSTGetRefund")
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
        net.Send(ply)
    end
end

function PLUGIN:CanPlayerChangeTeam(ply, newTeam)
    if ( lockedTeams[newTeam] ) then
        if ( SERVER ) then
            ply:Notify("Sorry, this team is temporarily locked! Please try again later.")
        end

        return false
    end
end