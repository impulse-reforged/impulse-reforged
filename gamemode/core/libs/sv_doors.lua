impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

local logs = impulse.Logs
local eMeta = FindMetaTable("Entity")
local fileName = "impulse-reforged/doors/" .. game.GetMap()

file.CreateDir("impulse-reforged/doors")

function impulse.Doors:Save()
    local doors = {}

    for _, door in ents.Iterator() do
        if ( door:IsDoor() and door:CreatedByMap() ) then
            doors[door:MapCreationID()] = {
                buyable = door:GetRelay("doorBuyable", true),
                group = door:GetRelay("doorGroup", nil),
                name = door:GetRelay("doorName", nil),
                pos = door:GetPos()
            }
        end
    end

    logs:Debug("Saving doors to impulse-reforged/doors/" .. game.GetMap() .. ".json | Doors saved: " .. #doors)
    file.Write(fileName .. ".json", util.TableToJSON(doors))

    impulse.Relay:Sync()
end

function impulse.Doors:Load()
    impulse.Doors.Data = {}

    local resetCount = 0
    for _, door in ents.Iterator() do
        if ( door:IsDoor() and door:CreatedByMap() ) then
            door:SetRelay("doorBuyable", true)
            door:SetRelay("doorGroup", nil)
            door:SetRelay("doorName", nil)
            resetCount = resetCount + 1
        end
    end

    if ( file.Exists(fileName .. ".json", "DATA") ) then
        local mapDoorData = util.JSONToTable(file.Read(fileName .. ".json", "DATA"))
        local posBuffer = {}
        local posFinds = {}

        -- use position hashes so we dont take several seconds
        for doorID, doorData in pairs(mapDoorData) do
            if ( !doorData.pos ) then continue end

            posBuffer[doorData.pos.x .. "|" .. doorData.pos.y .. "|" .. doorData.pos.z] = doorID
        end

        -- try to find every door via the pos value (update safeish)
        for _, door in ents.Iterator() do
            local doorPos = door:GetPos()
            local found = posBuffer[doorPos.x .. "|" .. doorPos.y .. "|" .. doorPos.z]

            if ( found and door:IsDoor() ) then
                local doorEnt = door
                local doorData = mapDoorData[found]
                local doorIndex = doorEnt:EntIndex()
                posFinds[doorIndex] = true

                if ( doorData.name ) then
                    doorEnt:SetRelay("doorName", doorData.name)
                end

                if ( doorData.group ) then
                    doorEnt:SetRelay("doorGroup", doorData.group)
                end

                if ( doorData.buyable != nil ) then
                    doorEnt:SetRelay("doorBuyable", doorData.buyable == nil and true or doorData.buyable)
                end
            end
        end

        -- and doors we couldnt get by pos, we'll fallback to hammerID's (less update safe) (old method)
        for doorID, doorData in pairs(mapDoorData) do
            local doorEnt = ents.GetMapCreatedEntity(doorID)

            if ( IsValid(doorEnt) and doorEnt:IsDoor() ) then
                local doorIndex = doorEnt:EntIndex()

                if posFinds[doorIndex] then
                    continue
                end

                if ( doorData.name ) then
                    doorEnt:SetRelay("doorName", doorData.name)
                end

                if ( doorData.group ) then
                    doorEnt:SetRelay("doorGroup", doorData.group)
                end

                if ( doorData.buyable != nil ) then
                    doorEnt:SetRelay("doorBuyable", doorData.buyable == nil and true or doorData.buyable)
                end

                logs:Warning("Added door by HammerID value because it could not be found via pos. Door index: " .. doorIndex .. ". Please investigate.")
            end
        end

        local appliedCount = 0
        for idx, _ in pairs(posFinds) do appliedCount = appliedCount + 1 end
        logs:Debug("[Doors] Applied hidden state to " .. appliedCount .. " doors via position matching")

        posBuffer = nil
        posFinds = nil
    end

    impulse.Relay:Sync()

    hook.Run("DoorsSetup")
end

function eMeta:DoorLock()
    self:Fire("lock", "", 0)
end

function eMeta:DoorUnlock()
    self:Fire("unlock", "", 0)

    if ( self:GetClass() == "func_door" ) then
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
        if IsValid(self) then self:Notify("This door is hidden and cannot be purchased.") end
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

concommand.Add("impulse_door_buyable_set", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 512
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and traceEnt:IsDoor() ) then
        if ( args[1] == "1" ) then
            traceEnt:SetRelay("doorBuyable", true)
        else
            traceEnt:SetRelay("doorBuyable", false)
        end

        local status = traceEnt:GetRelay("doorBuyable", false) and true or false

        traceEnt:SetRelay("doorGroup", nil)
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify("You have set door the door to be " .. (status and "buyable" or "not buyable") .. ".")

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_buyable_toggle", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 512
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and traceEnt:IsDoor() ) then
        local currentStatus = traceEnt:GetRelay("doorBuyable", true)
        local newStatus = !currentStatus

        traceEnt:SetRelay("doorBuyable", newStatus)
        traceEnt:SetRelay("doorGroup", nil)
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("You have set door %d to be %s.", traceEnt:EntIndex(), newStatus and "buyable" or "not buyable"))

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_buyable_set_all", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local buyable = tostring(args[1] or "1") == "1"
    local affected = 0

    for _, door in ents.Iterator() do
        if ( IsValid(door) and door:IsDoor() ) then
            door:SetRelay("doorBuyable", buyable)
            door:SetRelay("doorGroup", nil)
            door:SetRelay("doorName", nil)
            door:SetRelay("doorOwners", nil)

            affected = affected + 1
        end
    end

    if ( IsValid(client) ) then
        client:Notify(string.format("You have set all doors to be %s (%d were affected).", buyable and "buyable" or "not buyable", affected))
    end

    impulse.Doors:Save()
end)

concommand.Add("impulse_door_group_set", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 512
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and traceEnt:IsDoor() ) then
        local groupID = tonumber(args[1] or "0")

        traceEnt:SetRelay("doorBuyable", false)
        traceEnt:SetRelay("doorGroup", groupID == 0 and nil or groupID)
        traceEnt:SetRelay("doorName", nil)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("You have set door %d to group %s.", traceEnt:EntIndex(), groupID == 0 and "None" or tostring(groupID)))

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_group_set_all", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local groupID = tonumber(args[1] or "0")
    local affected = 0

    for _, door in ents.Iterator() do
        if ( IsValid(door) and door:IsDoor() ) then
            door:SetRelay("doorBuyable", false)
            door:SetRelay("doorGroup", groupID)
            door:SetRelay("doorName", nil)
            door:SetRelay("doorOwners", nil)

            affected = affected + 1
        end
    end

    if ( IsValid(client) ) then
        client:Notify(string.format("You have set all doors to group %s (%d were affected).", tostring(groupID), affected))
    end

    impulse.Doors:Save()
end)

concommand.Add("impulse_door_name_set", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = client:EyePos()
    trace.endpos = trace.start + client:GetAimVector() * 512
    trace.filter = client

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and traceEnt:IsDoor() ) then
        local name = table.concat(args, " ")

        traceEnt:SetRelay("doorBuyable", false)
        traceEnt:SetRelay("doorName", name)
        traceEnt:SetRelay("doorOwners", nil)

        client:Notify(string.format("You have set door %d name to '%s'.", traceEnt:EntIndex(), name))

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_name_set_all", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local name = tostring(args[1] or "")
    local affected = 0

    for _, door in ents.Iterator() do
        if ( IsValid(door) and door:IsDoor() ) then
            door:SetRelay("doorBuyable", false)
            door:SetRelay("doorName", name)
            door:SetRelay("doorOwners", nil)

            affected = affected + 1
        end
    end

    if ( IsValid(client) ) then
        client:Notify(string.format("You have set all doors name to '%s' (%d were affected).", name, affected))
    end

    impulse.Doors:Save()
end)

concommand.Add("impulse_door_reset_all", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    local affected = 0

    for _, door in ents.Iterator() do
        if ( IsValid(door) and door:IsDoor() ) then
            door:SetRelay("doorBuyable", true)
            door:SetRelay("doorGroup", nil)
            door:SetRelay("doorName", nil)
            door:SetRelay("doorOwners", nil)

            affected = affected + 1
        end
    end

    if ( IsValid(client) ) then
        client:Notify(string.format("You have reset all doors (%d were affected).", affected))
    end

    impulse.Doors:Save()
end)

concommand.Add("impulse_door_save", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    impulse.Doors:Save()

    if ( IsValid(client) ) then
        client:Notify("Door data saved.")
    end
end)

concommand.Add("impulse_door_load", function(client, cmd, args)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then return end

    impulse.Doors:Load()

    if ( IsValid(client) ) then
        client:Notify("Door data loaded.")
    end
end)
