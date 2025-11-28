impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

local PLAYER = FindMetaTable("Player")

function PLAYER:CanLockUnlockDoor(doorOwners, doorGroup)
    if not doorOwners and not doorGroup then return false end

    local hookResult = hook.Run("PlayerCanUnlockLock", self, doorOwners, doorGroup)
    if hookResult != nil then return hookResult end

    -- Check if player owns the door
    if doorOwners and table.HasValue(doorOwners, self:EntIndex()) then
        return true
    end

    -- Check door group access
    if not doorGroup then return false end

    local teamDoorGroups = self.DoorGroups
    local t = impulse.Teams.Stored[self:Team()]

    if not t then return false end

    -- Priority: rank > class > team
    local rank = self:GetTeamRank()
    local class = self:GetTeamClass()

    if not teamDoorGroups then
        if rank != 0 and t.ranks and t.ranks[rank] and t.ranks[rank].doorGroup then
            teamDoorGroups = t.ranks[rank].doorGroup
        elseif class != 0 and t.classes and t.classes[class] and t.classes[class].doorGroup then
            teamDoorGroups = t.classes[class].doorGroup
        elseif t.doorGroup or t.doorGroups then
            teamDoorGroups = t.doorGroup or t.doorGroups
        end
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
