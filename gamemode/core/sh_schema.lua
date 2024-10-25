--- Allows for control of the boot process of the schema such as piggybacking from other schemas
-- @module impulse.Schema

impulse.Schema = impulse.Schema or {}

HOOK_CACHE = {}

--- Boots the schema, loading all necessary files and plugins for the schema to function. This is called by impulse:Boot(). This function should not be called directly unless you know what you are doing.
-- @realm shared
-- @internal
-- @usage impulse.Schema:Boot() -- Called by impulse:Boot()
function impulse.Schema:Boot()
    local name = engine.ActiveGamemode()
    SCHEMA_NAME = name
    MsgC(Color(83, 143, 239), "[impulse-reforged] Loading \"" .. SCHEMA_NAME .. "\" schema...\n")

    if ( SERVER and !file.IsDir(SCHEMA_NAME, "LUA") ) then
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"" .. name .. "\", does not exist.")
    end

    local bootController = SCHEMA_NAME .. "/schema/bootcontroller.lua"

    if ( file.Exists(bootController, "LUA") ) then
        MsgC(Color(83, 143, 239), "[impulse-reforged] Loading bootcontroller...\n")

        if ( SERVER ) then
            include(bootController)
            AddCSLuaFile(bootController)
        else
            include(bootController)
        end
    end
    
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/teams")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/items")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/benches")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/mixtures")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/buyables")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/vendors")
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/config")

    local mapPath = SCHEMA_NAME .. "/schema/config/maps/" .. game.GetMap() .. ".lua"

    if ( SERVER and file.Exists("gamemodes/" .. mapPath, "GAME") ) then
        MsgC(Color(83, 143, 239), "[impulse-reforged] Loading map config for \"" .. game.GetMap() .. "\"\n")
        include(mapPath)
        AddCSLuaFile(mapPath)
        
        if ( impulse.Config.MapWorkshopID ) then
            resource.AddWorkshop(impulse.Config.MapWorkshopID)
        end

        if ( impulse.Config.MapContentWorkshopID ) then
            resource.AddWorkshop(impulse.Config.MapContentWorkshopID)
        end
    elseif CLIENT then
        include(mapPath)
        AddCSLuaFile(mapPath) 
    else
        MsgC(Color(255, 0, 0), "[impulse-reforged] No map config found!\"\n")
    end

    hook.Run("PostConfigLoad")

    impulse:IncludeDir(SCHEMA_NAME .. "/schema/scripts", true, "SCHEMA", name)
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/scripts/vgui", true, "SCHEMA", name)
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/scripts/hooks", true, "SCHEMA", name)
    impulse:IncludeDir(SCHEMA_NAME .. "/schema/scripts/meta", true, "SCHEMA", name)
    
    local files, plugins = file.Find(SCHEMA_NAME .. "/plugins/*", "LUA")
    for v, dir in ipairs(plugins) do
        if ( impulse.Config.DisabledPlugins and impulse.Config.DisabledPlugins[dir] ) then continue end
        
        MsgC(Color(83, 143, 239), "[impulse-reforged] [" .. SCHEMA_NAME .. "] [plugins] Loading plugin \"" .. dir .. "\"...\n")
        self:LoadPlugin(SCHEMA_NAME .. "/plugins/" .. dir, dir)
    end

    GM.Name = "impulse: " .. impulse.Config.SchemaName

    timer.Simple(1, function() -- hackyfix needs changing to something reliable
        hook.Run("OnSchemaLoaded")
    end)
end

--- Boots a specified object from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @string object The folder in the schema to load
-- @usage impulse.Schema:PiggyBoot("impulse-hl2rp", "items")
function impulse.Schema:PiggyBoot(schema, object)
    MsgC(Color(83, 143, 239), "[impulse-reforged] [" .. schema .. "] Loading " .. object .. " (via PiggyBoot)\n")
    impulse:IncludeDir(schema .. "/" .. object)
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
    impulse:IncludeDir(path .. "/setup", true, "PLUGIN", name)
    impulse:IncludeDir(path, true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/vgui", true, "PLUGIN", name)
    self:LoadEntites(path .. "/entities")
    impulse:IncludeDir(path .. "/hooks", true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/items", true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/benches", true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/mixtures", true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/buyables", true, "PLUGIN", name)
    impulse:IncludeDir(path .. "/vendors", true, "PLUGIN", name)
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