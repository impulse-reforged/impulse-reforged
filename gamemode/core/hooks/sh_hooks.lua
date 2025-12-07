function GM:PlayerCheckLimit(client, limitName, current, defaultMax)
    if ( client:IsAdmin() ) then
        return true
    end
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2
function GM:StartCommand(client, cmd)
    if ( !client:IsWeaponRaised() ) then
        cmd:RemoveKey(KEY_BLACKLIST)
    end

    if ( SERVER ) then
        local dragger = client.impulseArrestedDragger
        if ( IsValid(dragger) and client == dragger.impulseArrestedDragging and client:Alive() and dragger:Alive() ) then
            cmd:ClearMovement()
            cmd:ClearButtons()

            if ( client:GetPos():DistToSqr(dragger:GetPos()) > 60 ^ 2 ) then
                cmd:SetForwardMove(200)
            end

            cmd:SetViewAngles((dragger:GetShootPos() - client:GetShootPos()):GetNormalized():Angle())
        end
    else
        cmd:RemoveKey(IN_ZOOM)
    end
end

function GM:PlayerSwitchWeapon(client, oldWep, newWep)
    if ( SERVER ) then
        client:SetWeaponRaised(false)
    end
end

function GM:Move(client, mvData)
    -- alt walk thing based on nutscripts
    if client.GetMoveType(client) == MOVETYPE_WALK and ((client.HasBrokenLegs(client) and !client.GetRelay(client, "arrested", false)) or mvData.KeyDown(mvData, IN_WALK)) then
        local speed = client:GetWalkSpeed()
        local forwardRatio = 0
        local sideRatio = 0
        local ratio = impulse.Config.SlowWalkRatio

        if (mvData:KeyDown(IN_FORWARD)) then
            forwardRatio = ratio
        elseif (mvData:KeyDown(IN_BACK)) then
            forwardRatio = -ratio
        end

        if (mvData:KeyDown(IN_MOVELEFT)) then
            sideRatio = -ratio
        elseif (mvData:KeyDown(IN_MOVERIGHT)) then
            sideRatio = ratio
        end

        mvData:SetForwardSpeed(forwardRatio * speed)
        mvData:SetSideSpeed(sideRatio * speed)
    end
end

function GM:IsContainer(ent)
    if ( !IsValid(ent) ) then return false end

    if ( ent:GetClass() == "impulse_container" ) then
        return true
    end
end

local function CheckSpawnPoints(client, spawnPoints)
    local pos = client:GetPos()

    for _, v in ipairs(spawnPoints) do
        if ( istable(v) and v.pos ) then
            local spawnPos = v.pos
            if ( spawnPos and pos:DistToSqr(spawnPos) <= 128 ^ 2 ) then
                return true
            end
        elseif ( isvector(v) ) then
            if ( pos:DistToSqr(v) <= 128 ^ 2 ) then
                return true
            end
        end
    end
end

function GM:PlayerIsInSpawn(client)
    local teamData = client:GetTeamData()
    if ( !teamData ) then return end

    local teamRankData = client:GetTeamRankData()
    local teamClassData = client:GetTeamClassData()

    local isNearSpawn = false
    if ( teamRankData and teamRankData.spawnPoints ) then
        isNearSpawn = CheckSpawnPoints(client, teamRankData.spawnPoints)
    elseif ( teamClassData and teamClassData.spawnPoints ) then
        isNearSpawn = CheckSpawnPoints(client, teamClassData.spawnPoints)
    elseif ( teamData.spawnPoints ) then
        isNearSpawn = CheckSpawnPoints(client, teamData.spawnPoints)
    elseif ( impulse.Config.SpawnPoints ) then
        isNearSpawn = CheckSpawnPoints(client, impulse.Config.SpawnPoints)
    end

    if ( isNearSpawn ) then
        return true
    end
end
