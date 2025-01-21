--- A generic module that holds anything that doesnt fit elsewhere
-- @module impulse.Util

impulse.Util = impulse.Util or {}

impulse.Util.Type = impulse.Util.Type or {
    [2] = "string",
    [4] = "text",
    [8] = "number",
    [16] = "player",
    [32] = "steamid",
    [64] = "character",
    [128] = "bool",
    [1024] = "color",
    [2048] = "vector",

    string = 2,
    text = 4,
    number = 8,
    player = 16,
    steamid = 32,
    character = 64,
    bool = 128,
    color = 1024,
    vector = 2048,

    optional = 256,
    array = 512
}

--- Includes a lua file based on the prefix of the file. This will automatically call `include` and `AddCSLuaFile` based on the
-- current realm. This function should always be called shared to ensure that the client will receive the file from the server.
-- @realm shared
-- @string fileName Path of the Lua file to include. The path is relative to the file that is currently running this function
-- @string[opt] realm Realm that this file should be included in. You should usually ignore this since it
-- will be automatically be chosen based on the `SERVER` and `CLIENT` globals. This value should either be `"server"` or
-- `"client"` if it is filled in manually
-- @usage impulse.Util:Include("sh_config.lua")
-- @usage impulse.Util:Include("cl_init.lua", "client")
-- @usage impulse.Util:Include("sv_hooks.lua", "server")
function impulse.Util:Include(fileName, realm)
    if ( !fileName ) then
        error("[impulse] No file name specified for including.")
    end

    --MsgC(Color(83, 143, 239), "[impulse-reforged] [util] Including file \""..fileName.."\"...\n")

    -- Only include server-side if we're on the server.
    if ( ( realm == "server" or fileName:find("sv_") ) and SERVER ) then
        return include(fileName)
    -- Shared is included by both server and client.
    elseif ( realm == "shared" or fileName:find("shared.lua") or fileName:find("sh_") ) then
        if ( SERVER ) then
            -- Send the file to the client if shared so they can run it.
            AddCSLuaFile(fileName)
        end

        return include(fileName)
    -- File is sent to client, included on client.
    elseif (realm == "client" or fileName:find("cl_")) then
        if ( SERVER ) then
            AddCSLuaFile(fileName)
        else
            return include(fileName)
        end
    end
end

--- Includes multiple files in a directory.
-- @realm shared
-- @string directory Directory to include files from
-- @bool[opt] bFromLua Whether or not to search from the base `lua/` folder, instead of contextually basing from `schema/`
-- or `gamemode/`
-- @see impulse.Util:Include
-- @usage impulse.Util:IncludeDir("libs/thirdparty")
function impulse.Util:IncludeDir(directory, bFromLua)
    -- By default, we include relatively to impulse.
    local baseDir = "impulse-reforged"

    -- If we're in a schema, include relative to the schema.
    if ( SCHEMA_NAME ) then
        baseDir = SCHEMA_NAME .. "/schema/"
    else
        baseDir = baseDir .. "/gamemode/"
    end

    -- Find all of the files within the directory.
    for _, v in ipairs(file.Find((bFromLua and "" or baseDir)..directory.."/*.lua", "LUA")) do
        -- Include the file from the prefix.
        impulse.Util:Include(directory.."/"..v)
    end
end

if ( SERVER ) then
    function impulse:CinematicIntro(message)
        net.Start("impulseCinematicMessage")
            net.WriteString(message)
        net.Broadcast()
    end

    concommand.Add("impulse_cinemessage", function(ply, cmd, args)
        if ( !ply:IsSuperAdmin() ) then return end

        impulse:CinematicIntro(args[1] or "")
    end)
end

function impulse.Util:AngleToBearing(ang)
    return math.Round(360 - (ang.y % 360))
end

function impulse.Util:PosToString(pos)
    return pos.x .. "|" .. pos.y .. "|" .. pos.x
end

--- Seraches for a player by their SteamID, Name or SteamName.
-- @realm shared
-- @string identifier The identifier to search for
-- @treturn Player The player that was found
-- @usage print(impulse.Util:FindPlayer("STEAM_0:0:1234567"))
-- > Player[1][Bob]
function impulse.Util:FindPlayer(identifier)
    for k, v in player.Iterator() do
        -- Search by all possible steam id variants
        if ( identifier == v:SteamID() or identifier == v:SteamID64() or identifier == v:AccountID() ) then
            return v
        end

        -- Search by name
        if ( self:StringMatches(v:Name(), identifier) or self:StringMatches(v:SteamName(), identifier) ) then
            return v
        end
    end

    return nil
end

function impulse.Util:SafeString(str)
    local pattern = "[^0-9a-zA-Z%s]+"
    local clean = tostring(str)
    local first, last = string.find(str, pattern)

    if first != nil and last != nil then
        clean = string.gsub(clean, pattern, "") -- remove bad sequences
    end

    return clean
end

local idleVO = {
    "question23.wav",
    "question25.wav",
    "question09.wav",
    "question06.wav",
    "question05.wav"
}

local idleCPVO = {
    "copy.wav",
    "needanyhelpwiththisone.wav",
    "unitis10-8standingby.wav",
    "affirmative.wav",
    "affirmative2.wav",
    "rodgerthat.wav",
    "checkformiscount.wav"
}

local idleFishVO = {
    "fish_crabpot01.wav",
    "fish_likeleeches.wav",
    "fish_oldleg.wav",
    "fish_resumetalk02.wav",
    "fish_stayoutwater.wav",
    "fish_wipeouttown01.wav",
    "fish_resumetalk01.wav",
    "fish_resumetalk02.wav",
    "fish_resumetalk03.wav"
}

local idleZombVO = {
    "npc/zombie/zombie_voice_idle9.wav",
    "npc/zombie/zombie_voice_idle4.wav",
    "npc/zombie/zombie_voice_idle10.wav",
    "npc/zombie/zombie_voice_idle13.wav",
    "npc/zombie/zombie_voice_idle6.wav",
    "npc/zombie/zombie_voice_idle7.wav"
}

--- Returns a random ambient VO for specific type of vendor
-- @realm shared
-- @string gender The type of vendor to get the ambient VO for
-- @treturn string A Random ambient VO for the specific type of vendor
-- @usage print(impulse.Util:GetRandomAmbientVO("female"))
-- > vo/npc/female01/question23.wav
function impulse.Util:GetRandomAmbientVO(gender)
    if gender == "male" then
        return "vo/npc/male01/"..idleVO[math.random(1, #idleVO)]
    elseif gender == "fisherman" then
        return "lostcoast/vo/fisherman/"..idleFishVO[math.random(1, #idleFishVO)]
    elseif gender == "cp" then
        return "npc/metropolice/vo/"..idleCPVO[math.random(1, #idleCPVO)]
    elseif gender == "zombie" then
        return idleZombVO[math.random(1, #idleZombVO)]
    else
        return "vo/npc/female01/"..idleVO[math.random(1, #idleVO)]
    end
end

--- Returns a new string with all special characters removed from the original string.
-- @realm shared
-- @string str String to remove special characters from
-- @treturn string New string with special characters removed
-- @usage print(impulse.Util:RemoveSpecialCharacters("Hello, World!"))
-- > Hello World
function impulse.Util:RemoveSpecialCharacters(str)
    return string.gsub(str, "[^%w%s]", "")
end

--- Returns the position and angle of the head of an entity. If the entity is not valid, it will return the eye position and angles of the entity.
-- @realm shared
-- @param ent Entity to find the head position of
-- @treturn Vector Position of the head
-- @treturn Angle Angle of the head
-- @usage local pos, ang = impulse.Util:FindHeadPos(LocalPlayer())
-- print(pos, ang)
function impulse.Util:FindHeadPos(ent)
    if ( !IsValid(ent) ) then return end

    for i = 1, ent:GetBoneCount() do
        local name = ent:GetBoneName(i):lower()

        if ( name:find("head") ) then
            return ent:GetBonePosition(i)
        end
    end

    for k, v in ipairs(ent:GetAttachments()) do
        local name = v.name:lower()
        if ( name:find("head") ) then
            return ent:GetAttachment(k).Pos
        end
    end

    return ent:EyePos(), ent:EyeAngles()
end

--- Converts a number to a string with a certain length, adding zeroes to the front if necessary.
-- @realm shared
-- @number number Number to convert
-- @number length Length of the string
-- @treturn string Converted number
-- @usage print(impulse.Util:ZeroNumber(5, 3))
-- > 005
function impulse.Util:ZeroNumber(number, length)
    local amount = math.max(0, length - string.len(number))
    return string.rep("0", amount)..tostring(number)
end

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0 and "" or "../../hl2/sound/"

function impulse.Util:EmitQueuedSounds(entity, sounds, delay, spacing, volume, pitch)
    -- Let there be a delay before any sound is played.
    delay = delay or 0
    spacing = spacing or 0.1

    -- Loop through all of the sounds.
    for _, v in ipairs(sounds) do
        local postSet, preSet = 0, 0

        -- Determine if this sound has special time offsets.
        if (istable(v)) then
            postSet, preSet = v[2] or 0, v[3] or 0
            v = v[1]
        end

        -- Get the length of the sound.
        local length = SoundDuration(ADJUST_SOUND..v)
        -- If the sound has a pause before it is played, add it here.
        delay = delay + preSet

        -- Have the sound play in the future.
        timer.Simple(delay, function()
            -- Check if the entity still exists and play the sound.
            if (IsValid(entity)) then
                entity:EmitSound(v, volume, pitch)
            end
        end)

        -- Add the delay for the next sound.
        delay = delay + length + postSet + spacing
    end

    -- Return how long it took for the whole thing.
    return delay
end

--- Checks to see if two strings are equivalent using a fuzzy manner. Both strings will be lowered, and will return `true` if
-- the strings are identical, or if `b` is a substring of `a`.
-- @realm shared
-- @string a First string to check
-- @string b Second string to check
-- @treturn bool Whether or not the strings are equivalent
function impulse.Util:StringMatches(a, b)
    if (!a or !b) then return false end

    if (a and b) then
        a = tostring(a)
        b = tostring(b)

        local a2, b2 = string.utf8lower(a), string.utf8lower(b)

        -- Check if the actual letters match.
        if (a == b) then return true end
        if (a2 == b2) then return true end

        -- Be less strict and search.
        if (a:find(b)) then return true end
        if (a2:find(b2)) then return true end
    end

    return false
end

--- A more advanced version of `impulse.Util:StringMatches` that will check if two strings are equivalent by breaking them down into
-- tables of words and checking if any of the words match.
-- @realm shared
-- @string a First string to check
-- @string b Second string to check
-- @treturn bool Whether or not the strings are equivalent
function impulse.Util:StringMatchesTable(a, b)
    if (!a or !b) then return false end

    if (a and b) then
        a = tostring(a)
        b = tostring(b)

        local a2, b2 = string.utf8lower(a), string.utf8lower(b)

        -- Check if the actual letters match.
        if (a == b) then return true end
        if (a2 == b2) then return true end

        -- Be less strict and search.
        if (a:find(b)) then return true end
        if (a2:find(b2)) then return true end

        -- Take apart the strings into tables of words.
        for _, v in ipairs(string.Explode("%s", a2, true)) do
            for _, v2 in ipairs(string.Explode("%s", b2, true)) do
                -- Now check if the words match.
                if (impulse.Util:StringMatches(v, v2)) then
                    return true
                end
            end
        end
    end

    return false
end

--- Converts a unit to meters.
-- @realm shared
-- @number unit Unit to convert
-- @treturn number Converted unit
-- @usage print(impulse.Util:UnitToMeters(256))
-- > 6.5024
function impulse.Util:UnitToMeters(unit)
    return unit * 0.0254
end

--- Converts meters to a unit.
-- @realm shared
-- @number meters Meters to convert
-- @treturn number Converted meters
-- @usage print(impulse.Util:MetersToUnit(20))
-- > 787.40157480315
function impulse.Util:MetersToUnit(meters)
    return meters / 0.0254
end

--- Returns the address:port of the server.
-- @realm shared
-- @treturn string Address:Port of the server
-- @usage print(impulse.Util:GetAddress())
function impulse.Util:GetAddress()
    local address = tonumber(GetConVarString("hostip"))

    if (!address) then
        return "127.0.0.1"..":"..GetConVarString("hostport")
    end

    local ip = {}
        ip[1] = bit.rshift(bit.band(address, 0xFF000000), 24)
        ip[2] = bit.rshift(bit.band(address, 0x00FF0000), 16)
        ip[3] = bit.rshift(bit.band(address, 0x0000FF00), 8)
        ip[4] = bit.band(address, 0x000000FF)
    return table.concat(ip, ".")..":"..GetConVarString("hostport")
end

--- Finds a target in the player's crosshair, with an optional range.
-- @realm shared
-- @player ply Player to find the target for
-- @entity target Target entity to check
-- @number[opt=0.9] range Range to check for the target
-- @treturn bool Whether or not the target is in the player's crosshair
-- @usage -- returns true if Entity(2) is in Entity(1)'s crosshair
-- print(impulse.Util:FindInCrosshair(Entity(1), Entity(2)))
-- > true
-- @usage -- returns true if Entity(2) is in Entity(1)'s crosshair within 0.5 range
-- print(impulse.Util:FindInCrosshair(Entity(1), Entity(2), 0.5))
-- > true
-- @usage -- returns false if Entity(2) is not in Entity(1)'s crosshair within 0.1 range
-- print(impulse.Util:FindInCrosshair(Entity(1), Entity(2), 0.1))
-- > false
function impulse.Util:FindInCrosshair(ply, target, range)
    if ( !IsValid(ply) and !IsValid(target) ) then return end

    if ( !IsValid(target) ) then return end

    if ( !range ) then
        range = 0.9
    end

    range = math.Clamp(range, 0, 1)

    local origin, originVector = ply:EyePos(), ply:GetAimVector()

    local targetOrigin = target.EyePos and target:EyePos() or target:WorldSpaceCenter()
    local direction = targetOrigin - origin

    if ( originVector:Dot(direction:GetNormalized()) > range ) then return true end

    return false
end

--- Sends a chat message to all players
-- @realm shared
-- @tab package Chat message package
-- @usage impulse.Util:AddChatText(Color(255, 0, 0), "Hello, ", Color(0, 255, 0), "world!")
function impulse.Util:AddChatText(...)
    for k, v in player.Iterator() do
        v:AddChatText(...)
    end
end