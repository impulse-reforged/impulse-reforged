impulse.Plugins = impulse.Plugins or {}
impulse.Plugins.List = impulse.Plugins.List or {}

function impulse.Plugins:Load(path)
    MsgC(Color(83, 143, 239), "[impulse-reforged] Loading plugins...\n")

    path = path or "impulse-reforged/plugins"

    local files, folders = file.Find(path .. "/*", "LUA")

    for k, v in ipairs(folders) do
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

        impulse.Plugins.List[v] = PLUGIN

        PLUGIN = nil
    end

    for k, v in ipairs(files) do
        PLUGIN = {}
        PLUGIN.Name = v
        PLUGIN.Folder = path .. "/" .. v
        PLUGIN.Author = "Unknown"
        PLUGIN.Description = "No description provided."
        PLUGIN.Version = "1.0"

        impulse.Util:Include(path .. "/" .. v, true)

        impulse.Plugins.List[v] = PLUGIN

        PLUGIN = nil
    end

    MsgC(Color(0, 255, 0), "[impulse-reforged] Loaded plugins.\n")
end