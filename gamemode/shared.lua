MsgC(Color(83, 143, 239), "[impulse-reforged] Starting shared load ...\n")

impulse.Version = "2.0"

-- Define gamemode information.
GM.Name = "impulse"
GM.Author = "vin, Riggs"
GM.Website = "https://impulse.minerva-servers.com"
GM.Version = impulse.Version

meta = FindMetaTable("Player")

-- Called after the gamemode has loaded.
function GM:Initialize()
	impulse:Boot()
end

-- Called when a file has been modified.
function GM:OnReloaded()
	impulse:Boot()
end

if (SERVER) then
	concommand.Remove("gm_save")
	concommand.Remove("gmod_admin_cleanup")
	RunConsoleCommand("sv_defaultdeployspeed", 1)
end

-- disable widgets cause it uses like 30% server cpu lol
function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")

local install = "https://github.com/riggs9162/impulse-reforged/archive/refs/heads/main.zip"
function impulse:CheckVersion()
	http.Fetch("https://raw.githubusercontent.com/riggs9162/impulse-reforged/main/version.txt", function(body)
		if body == impulse.Version then
			MsgC(Color(0, 255, 0), "[impulse-reforged] You are running the latest version of impulse-reforged.\n")
		else
			MsgC(Color(255, 0, 0), "[impulse-reforged] You are running an outdated version of impulse-reforged! Please update to the latest version: " .. body .. "\n")
			MsgC(Color(255, 0, 0), "[impulse-reforged] Download the latest version here: " .. install .. "\n")
		end
	end, function(err)
		MsgC(Color(255, 0, 0), "[impulse-reforged] Error checking for updates: " .. err .. "\n")
	end)
end

function impulse:Include(fileName)
	if ( !fileName ) then
		error("[impulse-reforged] File to include has no name!")
	end

	if ( fileName:find("sv_") ) then
		if ( SERVER ) then
			include(fileName)
		end
	elseif ( fileName:find("sh_") ) then
		if ( SERVER ) then
			AddCSLuaFile(fileName)
		end

		include(fileName)
	elseif ( fileName:find("cl_") ) then
		if ( SERVER ) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	elseif ( fileName:find("rq_") ) then
		if ( SERVER ) then
			AddCSLuaFile(fileName)
		end

		_G[string.sub(fileName, 26, string.len(fileName) - 4)] = include(fileName)
	end
end

function impulse:IncludeDir(directory, hookMode, variable, uid)
	for k, v in ipairs(file.Find(directory .. "/*.lua", "LUA")) do
    	if ( hookMode ) then
    		self.Schema:LoadHooks(directory .. "/" .. v, variable, uid)
    	else
    		self:Include(directory .. "/" .. v)
    	end
	end
end

-- Loading 3rd party libs
impulse:IncludeDir("impulse-reforged/gamemode/libs")

-- Loading 3rd party data
impulse:IncludeDir("impulse-reforged/gamemode/libs/data")

-- Load config
impulse.Config = impulse.Config or {}

-- Create impulse folder
file.CreateDir("impulse-reforged")

local isPreview = CreateConVar("impulse_preview", 0, FCVAR_REPLICATED, "If the current build is in preview mode.")

if ( SERVER ) then
	impulse.YML = {}
	local dbFile = "impulse-reforged/config.yml"

	impulse.DB = {
		ip = "localhost",
		username = "root",
		password = "",
		database = "impulse_development",
		port = 3306
	}

	MsgC(Color(83, 143, 239), "[impulse-reforged] [config.yml] Searching for config.yml...\n")

	local configLoaded = false
	if ( file.Exists(dbFile, "DATA") ) then
		MsgC(Color(0, 255, 0), "[impulse-reforged] [config.yml] Found config.yml! Loading...\n")
		local worked, err = pcall(function() impulse.Yaml.Read("data/" .. dbFile) end) 
		if ( worked ) then
			MsgC(Color(0, 255, 0), "[impulse-reforged] [config.yml] config.yml is valid! Loading...\n")

			local config = impulse.Yaml.Read("data/" .. dbFile)
			if ( config and type(config) == "table" ) then
				if ( config.db and type(config.db) == "table" ) then
					table.Merge(impulse.DB, config.db)
					MsgC(Color(0, 255, 0), "[impulse-reforged] [config.yml] Database configuration loaded!\n")
					configLoaded = true

					if ( config.dev and type(config.dev) == "table" ) then
						if ( config.dev.preview == "true" ) then
							isPreview:SetInt(1)
							MsgC(Color(255, 255, 0), "[impulse-reforged] [config.yml] Server is running in preview mode!\n")
						else
							isPreview:SetInt(0)
							MsgC(Color(255, 0, 0), "[impulse-reforged] [config.yml] Server is running in live mode!\n")
						end
					end
				end

				if ( config.schemadb and config.schemadb[engine.ActiveGamemode()] ) then
					impulse.DB.database = config.schemadb[engine.ActiveGamemode()]
				end

				impulse.YML = config
			else
				MsgC(Color(255, 0, 0), "[impulse-reforged] [config.yml] Error reading config.yml: Invalid format!\n")
				SetGlobalString("impulse_fatalerror", "Error reading config.yml: Invalid format!")
			end
		else
			MsgC(Color(255, 0, 0), "[impulse-reforged] [config.yml] Error reading config.yml: " .. err .. "\n")
			SetGlobalString("impulse_fatalerror", "Error reading config.yml: " .. err)
		end
	else
		MsgC(Color(255, 0, 0), "[impulse-reforged] [config.yml] No config.yml found. Cannot proceed without this file!\n")
		SetGlobalString("impulse_fatalerror", "No config.yml found. Cannot proceed without this file!")
	end

	impulse.YML = impulse.YML or {}
	impulse.YML.apis = impulse.YML.apis or {}

	if ( !configLoaded ) then
		MsgC(Color(255, 100, 0), "[impulse-reforged] [config.yml] No database configuration found. Assuming development database configuration. If this is a live server please setup this file!\n")
		isPreview:SetInt(1) -- assume we\"re running a preview build then i guess?
	end
end

-- Load DB
if SERVER then
	mysql:Connect(impulse.DB.ip, impulse.DB.username, impulse.DB.password, impulse.DB.database, impulse.DB.port)
end

function impulse:Boot()
	GM = GM or GAMEMODE

    MsgC(Color(255, 255, 0), "[impulse-reforged] Booting impulse...\n")

    self:IncludeDir("impulse-reforged/gamemode/core")
	self:BootPlugins()

	self.Schema:Boot()

	self:CheckVersion()

	MsgC(Color(0, 255, 0), "[impulse-reforged] Booted!\n")

	GM = nil
end

function impulse:BootPlugins()
	local files, folders = file.Find("impulse-reforged/plugins/*", "LUA")

    for k, v in ipairs(folders) do
        MsgC(Color(83, 143, 239), "[impulse-reforged] [plugins] Loading plugin \""..v.."\"...\n")
        self.Schema:LoadPlugin("impulse-reforged/plugins/" .. v, v)
    end
end

-- Load core
impulse:IncludeDir("impulse-reforged/gamemode/core")

-- Load meta tables
impulse:IncludeDir("impulse-reforged/gamemode/core/meta")

-- Load core vgui elements
impulse:IncludeDir("impulse-reforged/gamemode/core/vgui")

-- Load hooks
impulse:IncludeDir("impulse-reforged/gamemode/core/hooks")

MsgC(Color(0, 255, 0), "[impulse-reforged] Completing shared load ...\n")