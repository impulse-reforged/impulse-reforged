impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

function meta:CanLockUnlockDoor(doorOwners, doorGroup)
    if not doorOwners and !doorGroup then return end

    hook.Run("PlayerCanUnlockLock", self, doorOwners, doorGroup)

    local teamDoorGroups = self.DoorGroups or {}

    if CLIENT then
        local t = impulse.Teams.Stored[LocalPlayer():Team()]
        teamDoorGroups = t.doorGroup

        local class = LocalPlayer():GetTeamClass()
        local rank = LocalPlayer():GetTeamRank()

        if class != 0 and t.classes[class].doorGroup then
            teamDoorGroups = t.classes[class].doorGroup
        end

        if rank != 0 and t.ranks[rank].doorGroup then
            teamDoorGroups = t.ranks[rank].doorGroup
        end
    end

    if doorOwners and table.HasValue(doorOwners, self:EntIndex()) then
        return true
    elseif doorGroup and teamDoorGroups and table.HasValue(teamDoorGroups, doorGroup) then
        return true
    end
end

function meta:IsDoorOwner(doorOwners)
    if doorOwners and table.HasValue(doorOwners, self:EntIndex()) then
        return true
    end
    return false
end

function meta:CanBuyDoor(doorOwners, doorBuyable)
    if doorOwners or doorBuyable == false then return false end
    return true
end