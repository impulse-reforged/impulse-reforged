--- Allows for control of the boot process of the schema such as piggybacking from other schemas
-- @module impulse.Schema

impulse.Schema = impulse.Schema or {}

SCHEMA = {}

local default = {
    Name = "Unknown",
    Description = "No description available.",
    Author = "Unknown",
}

--- Loads the schema, loading all necessary files and plugins for the schema to function. This function should not be called directly unless you know what you are doing.
-- @realm shared
-- @internal
-- @usage impulse.Schema:Load() -- Called by impulse:Boot()
function impulse.Schema:Load()
    MsgC(Color(255, 255, 0), "[impulse-reforged] Starting schema load ...\n")

    local name = engine.ActiveGamemode()
    if ( name == "impulse-reforged" ) then
        MsgC(Color(255, 0, 0), "[impulse-reforged] Attempted to load Schema \"impulse-reforged\", aborting. This is the framework!\n")
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"impulse-reforged\", aborting. This is the framework!")
        return
    end

    MsgC(Color(83, 143, 239), "[impulse-reforged] Loading \"" .. name .. "\" schema...\n")

    if ( SERVER and !file.IsDir(name, "LUA") ) then
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"" .. name .. "\", does not exist.")
        MsgC(Color(255, 0, 0), "[impulse-reforged] Failed to load Schema \"" .. name .. "\", does not exist.\n")
        return
    end

    local path = name .. "/schema/sh_schema.lua"
    if ( !file.Exists(path, "LUA") ) then
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"" .. name .. "\", no sh_schema.lua found.")
        MsgC(Color(255, 0, 0), "[impulse-reforged] Failed to load Schema \"" .. name .. "\", no sh_schema.lua found.\n")
        return
    end

    -- Prepare the schema information
    for k, v in pairs(default) do
        if ( !SCHEMA[k] ) then
            SCHEMA[k] = v
        end
    end

    -- Prepare the schema hook system
    impulse.Hooks:Register("SCHEMA")

    path = name .. "/schema"

    -- Load schema base files
    impulse.Util:IncludeDir(path, true)
    impulse.Util:IncludeDir(path .. "/teams", true)
    impulse.Util:IncludeDir(path .. "/items", true)
    impulse.Util:IncludeDir(path .. "/benches", true)
    impulse.Util:IncludeDir(path .. "/mixtures", true)
    impulse.Util:IncludeDir(path .. "/buyables", true)
    impulse.Util:IncludeDir(path .. "/vendors", true)
    impulse.Util:IncludeDir(path .. "/config", true)

    -- Load the current map config if it exists
    local map = game.GetMap()
    path = name .. "/schema/config/maps/" .. map
    print(path .. ".lua")
    if ( file.Exists(path, "LUA") ) then
        MsgC(Color(83, 143, 239), "[impulse-reforged] Loading map config for \"" .. map .. "\" in Schema \"" .. name .. "\"...\n")
        impulse.Util:Include(path, true)
    else
        MsgC(Color(255, 0, 0), "[impulse-reforged] Failed to find map config for \"" .. map .. "\" in Schema \"" .. name .. "\".\n")
    end

    hook.Run("PostConfigLoad")
    
    path = name .. "/schema"

    -- Load schema scripts such as hooks, meta, etc.
    impulse.Util:IncludeDir(path .. "/scripts", true)
    impulse.Util:IncludeDir(path .. "/scripts/vgui", true)
    impulse.Util:IncludeDir(path .. "/scripts/hooks", true)
    impulse.Util:IncludeDir(path .. "/scripts/meta", true)

    GAMEMODE.Name = "impulse: " .. SCHEMA.Name

    hook.Run("OnSchemaLoaded")

    MsgC(Color(0, 255, 0), "[impulse-reforged] Schema \"" .. name .. "\" loaded successfully.\n")
end

--- Boots a specified object from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @string object The folder in the schema to load
-- @usage impulse.Schema:PiggyBoot("impulse-hl2rp", "items")
function impulse.Schema:PiggyBoot(schema, object)
    MsgC(Color(83, 143, 239), "[impulse-reforged] [" .. schema .. "] Loading " .. object .. " (via PiggyBoot)\n")
    impulse.Util:IncludeDir(schema .. "/" .. object)
end

--- Boots a specified plugin from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @string plugin The plugin folder name
-- @usage impulse.Schema:PiggyBootPlugin("impulse-hl2rp", "pluginname")
function impulse.Schema:PiggyBootPlugin(schema, plugin)
    MsgC(Color(83, 143, 239), "[impulse-reforged] [" .. schema .. "] [plugins] Loading plugin (via PiggyBoot) \"" .. plugin .. "\"\n")
    self:LoadPlugin(schema .. "/plugins/" .. plugin, plugin)
end

--- Boots all entities from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @usage impulse.Schema:PiggyBootEntities("impulse-hl2rp")
function impulse.Schema:PiggyBootEntities(schema)
    self:LoadEntites(schema .. "/entities")
end

--- Creates actual entities from a specified path
-- @realm shared
-- @string path Path to entities
-- @internal
-- @usage impulse.Schema:LoadEntites("path/to/entities")
function impulse.Schema:LoadEntites(path)
    local files, folders

    local function IncludeFiles(path2, clientOnly)
        if ( SERVER and file.Exists(path2 .. "init.lua", "LUA") or CLIENT ) then
            if (clientOnly and CLIENT) or SERVER then
                include(path2 .. "init.lua")
            end

            if ( file.Exists(path2 .. "cl_init.lua", "LUA") ) then
                if SERVER then
                    AddCSLuaFile(path2 .. "cl_init.lua")
                else
                    include(path2 .. "cl_init.lua")
                end
            end

            return true
        elseif ( file.Exists(path2 .. "shared.lua", "LUA") ) then
            AddCSLuaFile(path2 .. "shared.lua")
            include(path2 .. "shared.lua")

            return true
        end

        return false
    end

    local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
        files, folders = file.Find(path .. "/" .. folder .. "/*", "LUA")
        default = default or {}

        for k, v in ipairs(folders) do
            local path2 = path .. "/" .. folder .. "/" .. v .. "/"

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = v

                if ( IncludeFiles(path2, clientOnly) and !client ) then
                    if (clientOnly) then
                        if (CLIENT) then
                            register(_G[variable], v)
                        end
                    else
                        register(_G[variable], v)
                    end
                end
            _G[variable] = nil
        end

        for k, v in ipairs(files) do
            local niceName = string.StripExtension(v)

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = niceName

                AddCSLuaFile(path .. "/" .. folder .. "/" .. v)
                include(path .. "/" .. folder .. "/" .. v)

                if ( clientOnly ) then
                    if ( CLIENT ) then
                        register(_G[variable], niceName)
                    end
                else
                    register(_G[variable], niceName)
                end
            _G[variable] = nil
        end
    end

    -- Include entities.
    HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    -- Include weapons.
    HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    -- Include effects.
    HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
end

--- Loads a plugin from a specified path
-- @realm shared
-- @string path Plugin path
-- @string name Plugin name
-- @internal
-- @usage impulse.Schema:LoadPlugin("path/to/plugin", "pluginname")
function impulse.Schema:LoadPlugin(path, name)
    impulse.Util:IncludeDir(path .. "/setup")
    impulse.Util:IncludeDir(path)
    impulse.Util:IncludeDir(path .. "/derma")
    self:LoadEntites(path .. "/entities")
    impulse.Util:IncludeDir(path .. "/hooks")
    impulse.Util:IncludeDir(path .. "/items")
    impulse.Util:IncludeDir(path .. "/benches")
    impulse.Util:IncludeDir(path .. "/mixtures")
    impulse.Util:IncludeDir(path .. "/buyables")
    impulse.Util:IncludeDir(path .. "/vendors")
end

--- Loads hooks from a specified file
-- @realm shared
-- @string file File path
-- @string variable Variable name
-- @string uid Unique identifier
-- @internal
-- @usage impulse.Schema:LoadHooks("path/to/file.lua", "PLUGIN", "uniqueid")
function impulse.Schema:LoadHooks(file, variable, uid)
    local PLUGIN = {}
    _G[variable] = PLUGIN
    PLUGIN.impulseLoading = true

    impulse:Include(file)

    local c = 0

    for v, k in pairs(PLUGIN) do
        if type(k) == "function" then
            c = c + 1
            hook.Add(v, "impulse" .. uid .. c, function(...)
                return k(nil, ...)
            end)
        end
    end

    if ( PLUGIN.OnLoaded ) then
        PLUGIN.OnLoaded()
    end

    PLUGIN.impulseLoading = nil
    _G[variable] = nil
end