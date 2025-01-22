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
    path = name .. "/schema/config/maps/" .. map .. ".lua"
    if ( file.Exists(path, "LUA") ) then
        MsgC(Color(0, 255, 0), "[impulse-reforged] Loading map config for \"" .. map .. "\" in Schema \"" .. name .. "\".\n")
        impulse.Util:Include(path, "shared")
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

    -- Load schema plugins
    impulse.Plugins:Load(name .. "/plugins")

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