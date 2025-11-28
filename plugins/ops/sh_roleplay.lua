local unArrestCommand = {
    description = "Un arrests the player specified.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local plyTarget = impulse.Util:FindPlayer(name)

        if plyTarget then
            print("[ops] "..client:Name().." ("..client:SteamID64()..") un-arrested "..plyTarget:Name().." ("..plyTarget:SteamID64()..")")
            plyTarget:UnArrest()
            plyTarget:Notify("You have been un-arrested by a game moderator.")
            client:Notify(plyTarget:Name().." has been successfully un-arrested.")

            if plyTarget.InJail then
                impulse.Arrest.Prison[plyTarget.InJail][plyTarget:EntIndex()] = nil
                plyTarget.InJail = nil
                timer.Remove("impulsePrison." .. plyTarget:UserID())
                plyTarget:StopDrag()
                plyTarget:Spawn()
            end
        else
            return client:Notify("Could not find the player: "..tostring(name).."..")
        end
    end
}

impulse.RegisterChatCommand("/unarrest", unArrestCommand)

local setTeamCommand = {
    description = "Sets the team of the player specified. Teams are refrenced with their team ID number.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local teamID = arg[2]
        local plyTarget = impulse.Util:FindPlayer(name)

        if not tonumber(teamID) then
            return client:Notify("The team ID must be a number.")
        end

        teamID = tonumber(teamID)

        if plyTarget then
            if teamID and impulse.Teams.Stored[teamID] then
                local teamName = team.GetName(teamID)
                print("[ops] "..client:Name().." ("..client:SteamID64()..") set "..plyTarget:Name().." ("..plyTarget:SteamID64()..") to team "..teamName.." (ID: "..teamID..")")
                plyTarget:SetTeam(teamID)
                plyTarget:Notify("Your team has been set to "..teamName.." by a game moderator.")
                client:Notify(plyTarget:Name().." has been successfully set to "..teamName.."..")
            else
                client:Notify("The team ID is invalid. Please check the F4 menu for the correct order.")
            end
        else
            return client:Notify("Could not find player: "..tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/setteam", setTeamCommand)

local forceUnlockCommand = {
    description = "Unlocks the door you are looking at.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local door = client:GetEyeTrace().Entity

        if not door or not IsValid(door) or not door:IsDoor() then
            return client:Notify("You are not looking at a door.")
        end

        print("[ops] "..client:Name().." ("..client:SteamID64()..") used /forceunlock on door "..door:EntIndex().." at "..tostring(door:GetPos()))
        door:DoorUnlock()
        client:Notify("Door unlocked.")
    end
}

impulse.RegisterChatCommand("/forceunlock", forceUnlockCommand)

local forceLockCommand = {
    description = "Locks the door you are looking at.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local door = client:GetEyeTrace().Entity

        if not door or not IsValid(door) or not door:IsDoor() then
            return client:Notify("You are not looking at a door.")
        end

        print("[ops] "..client:Name().." ("..client:SteamID64()..") used /forcelock on door "..door:EntIndex().." at "..tostring(door:GetPos()))
        door:DoorLock()
        client:Notify("Door locked.")
    end
}

impulse.RegisterChatCommand("/forcelock", forceLockCommand)

local removeDoorCommand = {
    description = "Removed a bugged door spawned with the door tool.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local door = client:GetEyeTrace().Entity

        if not door or not IsValid(door) or (not door:IsDoor() and !door:IsPropDoor()) then
            return client:Notify("You are not looking at a door.")
        end

        if door:MapCreationID() != -1 then
            return client:Notify("This is a map door, you can not remove it.")
        end

        print("[ops] "..client:Name().." ("..client:SteamID64()..") removed bugged door "..door:EntIndex().." ("..door:GetClass()..") at "..tostring(door:GetPos()))
        door:Remove()
        client:Notify("Door removed.")
    end
}

impulse.RegisterChatCommand("/removebuggeddoor", removeDoorCommand)

local sellDoorCommand = {
    description = "Sells the door you are looking at.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        local door = client:GetEyeTrace().Entity

        if not door or not IsValid(door) or not door:IsDoor() then
            return client:Notify("You are not looking at a door.")
        end

        local owners = door:GetRelay("doorOwners", nil)

        if not owners then
            return client:Notify("No door owners to remove.")
        end

        print("[ops] "..client:Name().." ("..client:SteamID64()..") force-sold door "..door:EntIndex().." at "..tostring(door:GetPos()))
        client:RemoveDoorMaster(door)
        client:Notify("Door sold.")
    end
}

impulse.RegisterChatCommand("/forceselldoor", sellDoorCommand)
