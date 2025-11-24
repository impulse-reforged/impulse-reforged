local PLAYER = FindMetaTable("Player")

if ( SERVER ) then
    function PLAYER:SetRPName(name, save)
        if save then
            local query = mysql:Update("impulse_players")
            query:Update("rpname", name)
            query:Where("steamid", self:SteamID64())
            query:Execute(true)

            self.impulseDefaultName = name
        end

        hook.Run("PlayerRPNameChanged", self, self:Name(), name)

        self:SetRelay("roleplayName", name)
    end

    function PLAYER:GetSavedRPName()
        return self.impulseDefaultName
    end
end

local blacklistNames = {
    ["ooc"] = true,
    ["shared"] = true,
    ["world"] = true,
    ["world prop"] = true,
    ["blocked"] = true,
    ["admin"] = true,
    ["server admin"] = true,
    ["mod"] = true,
    ["game moderator"] = true,
    ["adolf hitler"] = true,
    ["masked person"] = true,
    ["masked player"] = true,
    ["unknown"] = true,
    ["nigger"] = true,
    ["tyrone jenson"] = true
}

function impulse.CanUseName(name)
    if name:len() >= 24 then
        return false, "Name too long. (max. 24)" 
    end

    name = name:Trim()
    name = impulse.Util:SafeString(name)

    if name:len() <= 6 then
        return false, "Name too short. (min. 6)"
    end

    if name == "" then
        return false, "No name was provided."
    end


    local numFound = string.match(name, "%d") -- no numerics

    if numFound then
        return false, "Name contains numbers."
    end
    
    if blacklistNames[name:lower()] then
        return false, "Blacklisted/reserved name."    
    end

    return true, name
end

PLAYER.steamName = PLAYER.steamName or PLAYER.Name
function PLAYER:SteamName()
    return self.steamName(self)
end

function PLAYER:Name()
    return self:GetRelay("roleplayName", self:SteamName())
end

function PLAYER:KnownName()
    local custom = hook.Run("PlayerGetKnownName", self)
    return custom or self:GetRelay("roleplayName", self:SteamName())
end

PLAYER.GetName = PLAYER.Name
PLAYER.Nick = PLAYER.Name
