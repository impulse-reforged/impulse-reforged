impulse.Plugins = impulse.Plugins or {}
impulse.Plugins.List = impulse.Plugins.List or {}

local logs = impulse.Logs

function impulse.Plugins:LoadEntities(path)
    local files, folders

    local function IncludeFiles(path2, clientOnly)
        if ( SERVER and file.Exists(path2 .. "init.lua", "LUA") or CLIENT ) then
            if (clientOnly and CLIENT) or SERVER then
                include(path2 .. "init.lua")
            end

            if ( file.Exists(path2 .. "cl_init.lua", "LUA") ) then
                if ( SERVER ) then
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

function impulse.Plugins:Load(path)
    logs:Info("Loading plugins...")

    path = path or "impulse-reforged/plugins"

    local files, folders = file.Find(path .. "/*", "LUA")
    local disabledPlugins = impulse.Config.DisabledPlugins

    for k, v in ipairs(folders) do
        if ( disabledPlugins and disabledPlugins[v] ) then
            logs:Debug("Skipping disabled plugin: " .. v)
            continue
        end

        PLUGIN = {}
        PLUGIN.Name = v
        PLUGIN.Folder = path .. "/" .. v
        PLUGIN.Author = "Unknown"
        PLUGIN.Description = "No description provided."
        PLUGIN.Version = "1.0"

        impulse.Util:IncludeDir(path .. "/" .. v .. "/setup", true)
        impulse.Util:IncludeDir(path .. "/" .. v, true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/vgui", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/hooks", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/items", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/benches", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/mixtures", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/buyables", true)
        impulse.Util:IncludeDir(path .. "/" .. v .. "/vendors", true)

        self:LoadEntities(path .. "/" .. v .. "/entities")

        self.List[v] = PLUGIN

        PLUGIN = nil
    end

    for k, v in ipairs(files) do
        if ( disabledPlugins and disabledPlugins[v] ) then
            logs:Debug("Skipping disabled plugin: " .. v)
            continue
        end

        PLUGIN = {}
        PLUGIN.Name = v
        PLUGIN.Folder = path .. "/" .. v
        PLUGIN.Author = "Unknown"
        PLUGIN.Description = "No description provided."
        PLUGIN.Version = "1.0"

        impulse.Util:Include(path .. "/" .. v, true)

        self.List[v] = PLUGIN

        PLUGIN = nil
    end

    logs:Success("Loaded plugins.")
end