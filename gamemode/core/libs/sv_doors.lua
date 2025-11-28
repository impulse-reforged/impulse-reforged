impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

local logs = impulse.Logs
local eMeta = FindMetaTable("Entity")
local fileName = "impulse-reforged/doors/"..game.GetMap()

file.CreateDir("impulse-reforged/doors")

function impulse.Doors:Save()
    local doors = {}

    for v, k in ents.Iterator() do
        if k:IsDoor() and k:CreatedByMap() then
            if k:GetRelay("doorBuyable", true) == false then
                doors[k:MapCreationID()] = {
                    name = k:GetRelay("doorName", nil),
                    group = k:GetRelay("doorGroup", nil),
                    pos = k:GetPos(),
                    buyable = k:GetRelay("doorBuyable", false)
                }
            end
        end
    end

    logs:Debug("Saving doors to impulse-reforged/doors/"..game.GetMap()..".json | Doors saved: "..#doors)
    file.Write(fileName..".json", util.TableToJSON(doors))
end

function impulse.Doors:Load()
    impulse.Doors.Data = {}

    if file.Exists(fileName..".json", "DATA") then
        local mapDoorData = util.JSONToTable(file.Read(fileName..".json", "DATA"))
        local posBuffer = {}
        local posFinds = {}

        -- use position hashes so we dont take several seconds
        for doorID, doorData in pairs(mapDoorData) do
            if ( !doorData.pos ) then continue end

            posBuffer[doorData.pos.x.."|"..doorData.pos.y.."|"..doorData.pos.z] = doorID
        end

        -- try to find every door via the pos value (update safeish)
        for v, k in ents.Iterator() do
            local p = k.GetPos(k)
            local found = posBuffer[p.x.."|"..p.y.."|"..p.z]

            if found and k:IsDoor() then
                local doorEnt = k
                local doorData = mapDoorData[found]
                local doorIndex = doorEnt:EntIndex()
                posFinds[doorIndex] = true

                if doorData.name then doorEnt:SetRelay("doorName", doorData.name) end
                if doorData.group then doorEnt:SetRelay("doorGroup", doorData.group) end
                if doorData.buyable != nil then doorEnt:SetRelay("doorBuyable", false) end
            end
        end

        -- and doors we couldnt get by pos, we'll fallback to hammerID's (less update safe) (old method)
        for doorID, doorData in pairs(mapDoorData) do
            local doorEnt = ents.GetMapCreatedEntity(doorID)

            if IsValid(doorEnt) and doorEnt:IsDoor() then
                local doorIndex = doorEnt:EntIndex()

                if posFinds[doorIndex] then
                    continue
                end

                if doorData.name then doorEnt:SetRelay("doorName", doorData.name) end
                if doorData.group then doorEnt:SetRelay("doorGroup", doorData.group) end
                if doorData.buyable != nil then doorEnt:SetRelay("doorBuyable", false) end

                logs:Warning("Added door by HammerID value because it could not be found via pos. Door index: "..doorIndex..". Please investigate.")
            end
        end

        posBuffer = nil
        posFinds = nil
    end

    hook.Run("DoorsSetup")
end

function eMeta:DoorLock()
    self:Fire("lock", "", 0)
end

function eMeta:DoorUnlock()
    self:Fire("unlock", "", 0)
    if self:GetClass() == "func_door" then
        self:Fire("open")
    end
end

function eMeta:GetDoorMaster()
    return self.MasterUser
end

local PLAYER = FindMetaTable("Player")

function PLAYER:SetDoorMaster(door)
    -- Prevent owning doors that are marked hidden/non-buyable
    if ( door:GetRelay("doorBuyable", true) == false ) then
        if IsValid(self) then self:Notify("This door is hidden and cannot be owned.") end
        return false, "Door is hidden"
    end

    local owners = {self:EntIndex()}

    door:SetRelay("doorOwners", owners)
    door.MasterUser = self

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorMaster(door, noUnlock)
    local owners = door:GetRelay("doorOwners")
    door:SetRelay("doorOwners", nil)
    door.MasterUser = nil

    for v, k in pairs(owners) do
        local owner = Entity(k)

        if IsValid(owner) and owner:IsPlayer() then
            owner.impulseOwnedDoors[door] = nil
        end
    end

    if ( !noUnlock ) then
        door:DoorUnlock()
    end
end

function PLAYER:SetDoorUser(door)
    -- Prevent adding users to hidden/non-buyable doors
    if ( door:GetRelay("doorBuyable", true) == false ) then
        if IsValid(self) then self:Notify("This door is hidden and cannot be owned.") end
        return false, "Door is hidden"
    end

    local doorOwners = door:GetRelay("doorOwners")

    if ( !doorOwners ) then return end

    table.insert(doorOwners, self:EntIndex())
    door:SetRelay("doorOwners", doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorUser(door)
    local doorOwners = door:GetRelay("doorOwners")

    if ( !doorOwners ) then return end

    table.RemoveByValue(doorOwners, self:EntIndex())
    door:SetRelay("doorOwners", doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = nil
end

concommand.Add("impulse_door_sethidden", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 200
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and (traceEnt:IsDoor() or traceEnt:IsPropDoor()) then
        if args[1] == "1" then
            traceEnt:SetRelay("doorBuyable", false)
        else
            traceEnt:SetRelay("doorBuyable", nil)
        end
        traceEnt:SetRelay("doorGroup", nil)
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("Door %d show = %s", traceEnt:EntIndex(), tostring(args[1])))

        impulse.Doors:Save()
    end
end)

-- Sets ALL map-created doors on the current map to hidden (not buyable) or visible
-- Usage: impulse_doors_setallhidden 1 (hide) | 0 (show)
concommand.Add("impulse_doors_setallhidden", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local hide = tostring(args[1] or "1") == "1"
    local affected = 0

    for v, k in ents.Iterator() do
        if IsValid(k) and (k:IsDoor() or k:IsPropDoor()) then
            if hide then
                k:SetRelay("doorBuyable", false)
                k:SetRelay("doorGroup", nil)
                k:SetRelay("doorName", nil)
                k:SetRelay("doorOwners", nil)
            else
                k:SetRelay("doorBuyable", nil)
                -- Do not restore group/name/owners when showing; keep them cleared unless set individually
            end

            affected = affected + 1
        end
    end

    if IsValid(client) then
        client:Notify(string.format("Set all map doors hidden = %s (%d affected)", hide and "1" or "0", affected))
    end

    impulse.Doors:Save()
end)

-- Assigns ALL map-created doors to a specific door group and makes them non-buyable
-- Usage: impulse_doors_setallgroup <groupId>
concommand.Add("impulse_doors_setallgroup", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local groupId = tonumber(args[1])
    if ( !groupId ) then
        if IsValid(client) then client:Notify("Usage: impulse_doors_setallgroup <groupId>") end
        return
    end

    local affected = 0
    for v, k in ents.Iterator() do
        if IsValid(k) and (k:IsDoor() or k:IsPropDoor()) then
            k:SetRelay("doorBuyable", false)
            k:SetRelay("doorGroup", groupId)
            k:SetRelay("doorName", nil)
            k:SetRelay("doorOwners", nil)
            affected = affected + 1
        end
    end

    if IsValid(client) then
        client:Notify(string.format("Set all map doors to group = %d (%d affected)", groupId, affected))
    end

    impulse.Doors:Save()
end)

-- Removes door group from ALL map-created doors and resets buyable flag
-- Usage: impulse_doors_removeallgroup
concommand.Add("impulse_doors_removeallgroup", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local affected = 0
    for v, k in ents.Iterator() do
        if IsValid(k) and (k:IsDoor() or k:IsPropDoor()) then
            k:SetRelay("doorBuyable", nil)
            k:SetRelay("doorGroup", nil)
            k:SetRelay("doorName", nil)
            k:SetRelay("doorOwners", nil)
            affected = affected + 1
        end
    end

    if IsValid(client) then
        client:Notify(string.format("Removed group from all map doors (%d affected)", affected))
    end

    impulse.Doors:Save()
end)

concommand.Add("impulse_door_setgroup", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 200
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and (traceEnt:IsDoor() or traceEnt:IsPropDoor()) then
        traceEnt:SetRelay("doorBuyable", false)
        traceEnt:SetRelay("doorGroup", tonumber(args[1]))
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("Door %d group = %s", traceEnt:EntIndex(), tostring(args[1])))

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_removegroup", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 200
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and (traceEnt:IsDoor() or traceEnt:IsPropDoor()) ) then
        traceEnt:SetRelay("doorBuyable", nil)
        traceEnt:SetRelay("doorGroup", nil)
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("Door %d group = nil", traceEnt:EntIndex()))

        impulse.Doors:Save()
    end
end)
