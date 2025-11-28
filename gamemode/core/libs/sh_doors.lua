impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

local PLAYER = FindMetaTable("Player")

function PLAYER:CanLockUnlockDoor(doorOwners, doorGroup)
    if not doorOwners and not doorGroup then 
        if SERVER then print("[DOOR DEBUG] " .. self:Nick() .. " - No owners or group") end
        return false 
    end

    local hookResult = hook.Run("PlayerCanUnlockLock", self, doorOwners, doorGroup)
    if hookResult != nil then return hookResult end

    -- Check if player owns the door
    if doorOwners and table.HasValue(doorOwners, self:EntIndex()) then
        if SERVER then print("[DOOR DEBUG] " .. self:Nick() .. " - Owns door") end
        return true
    end

    -- Check door group access
    if not doorGroup then return false end

    local t = impulse.Teams.Stored[self:Team()]
    if not t then return false end

    -- Priority: rank > class > team
    local rank = self:GetTeamRank()
    local class = self:GetTeamClass()
    local teamDoorGroups = nil

    -- Check rank door groups first
    if rank and rank != 0 and t.ranks and t.ranks[rank] then
        teamDoorGroups = t.ranks[rank].doorGroups or t.ranks[rank].doorGroup
    end

    -- If no rank groups, check class door groups
    if not teamDoorGroups and class and class != 0 and t.classes and t.classes[class] then
        teamDoorGroups = t.classes[class].doorGroups or t.classes[class].doorGroup
    end

    -- If no class groups, use team door groups
    if not teamDoorGroups then
        teamDoorGroups = t.doorGroups or t.doorGroup
    end

    if not teamDoorGroups then return false end

    return table.HasValue(teamDoorGroups, doorGroup)
end

function PLAYER:IsDoorOwner(doorOwners)
    if doorOwners and table.HasValue(doorOwners, self:EntIndex()) then return true end
    return false
end

function PLAYER:CanBuyDoor(doorOwners, doorBuyable)
    if doorOwners or doorBuyable == false then return false end
    return true
end
