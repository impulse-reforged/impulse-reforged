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
            if k:GetNetVar("doorBuyable", true) == false then
                doors[k:MapCreationID()] = {
                    name = k:GetNetVar("doorName", nil),
                    group = k:GetNetVar("doorGroup", nil),
                    pos = k:GetPos(),
                    buyable = k:GetNetVar("doorBuyable", false)
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
            if not doorData.pos then continue end

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
                
                if doorData.name then doorEnt:SetNetVar("doorName", doorData.name) end
                if doorData.group then doorEnt:SetNetVar("doorGroup", doorData.group) end
                if doorData.buyable != nil then doorEnt:SetNetVar("doorBuyable", false) end
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
                
                if doorData.name then doorEnt:SetNetVar("doorName", doorData.name) end
                if doorData.group then doorEnt:SetNetVar("doorGroup", doorData.group) end
                if doorData.buyable != nil then doorEnt:SetNetVar("doorBuyable", false) end

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
    local owners = {self:EntIndex()}

    door:SetNetVar("doorOwners", owners)
    door.MasterUser = self

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorMaster(door, noUnlock)
    local owners = door:GetNetVar("doorOwners")
    door:SetNetVar("doorOwners", nil)
    door.MasterUser = nil

    for v, k in pairs(owners) do
        local owner = Entity(k)

        if IsValid(owner) and owner:IsPlayer() then
            owner.impulseOwnedDoors[door] = nil
        end
    end

    if not noUnlock then
        door:DoorUnlock()
    end
end

function PLAYER:SetDoorUser(door)
    local doorOwners = door:GetNetVar("doorOwners")

    if not doorOwners then return end

    table.insert(doorOwners, self:EntIndex())
    door:SetNetVar("doorOwners", doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorUser(door)
    local doorOwners = door:GetNetVar("doorOwners")

    if not doorOwners then return end

    table.RemoveByValue(doorOwners, self:EntIndex())
    door:SetNetVar("doorOwners", doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = nil
end

concommand.Add("impulse_door_sethidden", function(ply, cmd, args)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and traceEnt:IsDoor() then
        if args[1] == "1" then
            traceEnt:SetNetVar("doorBuyable", false)
        else
            traceEnt:SetNetVar("doorBuyable", nil)
        end
        traceEnt:SetNetVar("doorGroup", nil)
        traceEnt:SetNetVar("doorName", nil)
        traceEnt:SetNetVar("doorOwners", nil)

        ply:Notify("Door "..traceEnt:EntIndex().." show = "..args[1])

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_setgroup", function(ply, cmd, args)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and traceEnt:IsDoor() then
        traceEnt:SetNetVar("doorBuyable", false)
        traceEnt:SetNetVar("doorGroup", tonumber(args[1]))
        traceEnt:SetNetVar("doorName", nil)
        traceEnt:SetNetVar("doorOwners", nil)

        ply:Notify("Door "..traceEnt:EntIndex().." group = "..args[1])

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_removegroup", function(ply, cmd, args)
    if ( IsValid(ply) and !ply:IsSuperAdmin() ) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity
    if ( IsValid(traceEnt) and traceEnt:IsDoor() ) then
        traceEnt:SetNetVar("doorBuyable", nil)
        traceEnt:SetNetVar("doorGroup", nil)
        traceEnt:SetNetVar("doorName", nil)
        traceEnt:SetNetVar("doorOwners", nil)

        ply:Notify("Door "..traceEnt:EntIndex().." group = nil")

        impulse.Doors:Save()
    end
end)