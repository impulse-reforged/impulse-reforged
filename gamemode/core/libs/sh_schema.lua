--- Allows for control of the boot process of the schema such as piggybacking from other schemas
-- @module impulse.Schema

impulse.Schema = impulse.Schema or {}

SCHEMA = {}

local logs =  impulse.Logs

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
    logs:Info("Starting schema load ...")

    local name = engine.ActiveGamemode()
    if ( name == "impulse-reforged" ) then
        logs:Error("Attempted to load Schema \"impulse-reforged\", aborting. This is the framework!")
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"impulse-reforged\", aborting. This is the framework!")
        return
    end

    logs:Info("Loading Schema \"" .. name .. "\"...")

    if ( SERVER and !file.IsDir(name, "LUA") ) then
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"" .. name .. "\", does not exist.")
        logs:Error("Failed to load Schema \"" .. name .. "\", does not exist.")
        return
    end

    local path = name .. "/schema/sh_schema.lua"
    if ( !file.Exists(path, "LUA") ) then
        SetGlobalString("impulse_fatalerror", "Failed to load Schema \"" .. name .. "\", no sh_schema.lua found.")
        logs:Error("Failed to load Schema \"" .. name .. "\", no sh_schema.lua found.")
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
        logs:Info("Loading map config for \"" .. map .. "\" in Schema \"" .. name .. "\".")
        impulse.Util:Include(path, "shared")
    else
        logs:Error("Failed to find map config for \"" .. map .. "\" in Schema \"" .. name .. "\".")
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

    logs:Success("Schema \"" .. name .. "\" loaded successfully.")
end

--- Boots a specified object from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @string object The folder in the schema to load
-- @usage impulse.Schema:PiggyBoot("impulse-hl2rp", "items")
function impulse.Schema:PiggyBoot(schema, object)
    logs:Info("[" .. schema .. "] Loading " .. object .. " (via PiggyBoot)")
    impulse.Util:IncludeDir(schema .. "/" .. object)
end

--- Boots a specified plugin from a foreign schema using the piggbacking system
-- @realm shared
-- @string schema Schema file name
-- @string plugin The plugin folder name
-- @usage impulse.Schema:PiggyBootPlugin("impulse-hl2rp", "pluginname")
function impulse.Schema:PiggyBootPlugin(schema, plugin)
    logs:Info("[" .. schema .. "] [plugins] Loading plugin (via PiggyBoot) \"" .. plugin .. "\"")
    self:LoadPlugin(schema .. "/plugins/" .. plugin, plugin)
end