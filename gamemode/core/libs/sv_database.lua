--- Database library for impulse, ported directly from Helix.
-- @module impulse.Database
local logs = impulse.Logs

impulse.Database = impulse.Database or {
    Schema = {},
    SchemaQueue = {},
    Type = {
        -- TODO: more specific types, lengths, and defaults
        -- i.e INT(11) UNSIGNED, SMALLINT(4), LONGTEXT, VARCHAR(350), NOT NULL, DEFAULT NULL, etc
        [impulse.Util.Type.string] = "VARCHAR(255)",
        [impulse.Util.Type.text] = "TEXT",
        [impulse.Util.Type.number] = "INT(11)",
        [impulse.Util.Type.steamid] = "VARCHAR(20)",
        [impulse.Util.Type.bool] = "TINYINT(1)"
    }
}

impulse.Database.Config = impulse.Config.YML.database or {}

--- Connects to the database using the specified adapter.
-- @realm server
-- @internal
function impulse.Database:Connect()
    impulse.Database.Config.adapter = impulse.Database.Config.adapter or "sqlite"

    local dbmodule = impulse.Database.Config.adapter
    local hostname = impulse.Database.Config.hostname
    local username = impulse.Database.Config.username
    local password = impulse.Database.Config.password
    local database = impulse.Database.Config.database
    local port = impulse.Database.Config.port

    mysql:SetModule(dbmodule)
    mysql:Connect(hostname, username, password, database, port)
end

--- Adds a field to a schema.
-- @realm server
-- @string schemaType The schema to add the field to
-- @string field The field name
-- @string fieldType The field type
-- @usage impulse.Database:AddToSchema("impulse_players", "xp", impulse.Util.Type.number)
-- @internal
function impulse.Database:AddToSchema(schemaType, field, fieldType)
    if ( !impulse.Database.Type[fieldType] ) then
        error(string.format("attempted to add field in schema with invalid type '%s'", fieldType))
        return
    end

    if ( !mysql:IsConnected() or !impulse.Database.Schema[schemaType] ) then
        impulse.Database.SchemaQueue[#impulse.Database.SchemaQueue + 1] = {schemaType, field, fieldType}
        return
    end

    impulse.Database:InsertSchema(schemaType, field, fieldType)
end

--- Inserts a field into a schema.
-- @realm server
-- @string schemaType The schema to insert the field into
-- @string field The field name
-- @string fieldType The field type
-- @usage impulse.Database:InsertSchema("impulse_players", "xp", impulse.Util.Type.number)
-- @internal
function impulse.Database:InsertSchema(schemaType, field, fieldType)
    local schema = impulse.Database.Schema[schemaType]
    if ( !schema ) then
        error(string.format("attempted to insert into schema with invalid schema type '%s'", schemaType))
        return
    end

    if ( !schema[field] ) then
        schema[field] = true

        local query = mysql:Update("impulse_schema")
            query:Update("columns", util.TableToJSON(schema))
            query:Where("table", schemaType)
        query:Execute()

        query = mysql:Alter(schemaType)
            query:Add(field, impulse.Database.Type[fieldType])
        query:Execute()
    end
end

--- Loads and prepares all tables for use.
-- @realm server
-- @internal
function impulse.Database:LoadTables()
    local query
    logs:Database("loading tables...")

    query = mysql:Create("impulse_schema")
        query:Create("table", "VARCHAR(64) NOT NULL")
        query:Create("columns", "TEXT NOT NULL")
        query:PrimaryKey("table")
    query:Execute()

    query = mysql:Create("impulse_players")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("rpname", "VARCHAR(70) NOT NULL")
        query:Create("steamid", "VARCHAR(25) NOT NULL")
        query:Create("steamname", "VARCHAR(70) NOT NULL")
        query:Create("group", "VARCHAR(70) NOT NULL")
        query:Create("rpgroup", "INT(11) UNSIGNED NOT NULL")
        query:Create("rpgrouprank", "VARCHAR(255) NOT NULL")
        query:Create("xp", "INT(11) UNSIGNED DEFAULT NULL")
        query:Create("money", "INT(11) UNSIGNED DEFAULT NULL")
        query:Create("bankmoney", "INT(11) UNSIGNED DEFAULT NULL")
        query:Create("skills", "TEXT")
        query:Create("ammo", "TEXT")
        query:Create("model", "VARCHAR(160) NOT NULL")
        query:Create("skin", "TINYINT")
        query:Create("cosmetic", "TEXT")
        query:Create("data", "TEXT")
        query:Create("firstjoin", "INT(11) UNSIGNED NOT NULL")
        query:Create("lastjoin", "INT(11) UNSIGNED NOT NULL")
        query:Create("address", "VARCHAR(15) NOT NULL")
        query:Create("playtime", "INT(11) UNSIGNED NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_inventory")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("uniqueid", "VARCHAR(25) NOT NULL")
        query:Create("ownerid", "INT(11) UNSIGNED NOT NULL")
        query:Create("storagetype", "INT(11) UNSIGNED NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_reports")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("reporter", "VARCHAR(25) NOT NULL")
        query:Create("mod", "VARCHAR(25) NOT NULL")
        query:Create("message", "TEXT")
        query:Create("start", "DATETIME NOT NULL")
        query:Create("claimwait", "INT(11) UNSIGNED NOT NULL")
        query:Create("closewait", "INT(11) UNSIGNED NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_whitelists")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("steamid", "VARCHAR(25) NOT NULL")
        query:Create("team", "VARCHAR(90) NOT NULL")
        query:Create("level", "INT(11) UNSIGNED NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_refunds")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("steamid", "VARCHAR(25) NOT NULL")
        query:Create("item", "VARCHAR(75) NOT NULL")
        query:Create("date", "INT(11) UNSIGNED NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_rpgroups")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("ownerid", "INT(11) UNSIGNED DEFAULT NULL")
        query:Create("name", "VARCHAR(255) NOT NULL")
        query:Create("type", "INT(11) UNSIGNED NOT NULL")
        query:Create("maxsize", "INT(11) UNSIGNED NOT NULL")
        query:Create("maxstorage", "INT(11) UNSIGNED NOT NULL")
        query:Create("ranks", "TEXT")
        query:Create("data", "TEXT")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("impulse_data")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("name", "VARCHAR(255) NOT NULL")
        query:Create("data", "TEXT")
        query:PrimaryKey("id")
    query:Execute()

    -- populate schema table if rows don't exist
    query = mysql:InsertIgnore("impulse_schema")
        query:Insert("table", "impulse_players")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    -- load schema from database
    query = mysql:Select("impulse_schema")
        query:Callback(function(result)
            if (!istable(result)) then return end

            for _, v in pairs(result) do
                impulse.Database.Schema[v.table] = util.JSONToTable(v.columns)
            end

            -- update schema if needed
            for i = 1, #impulse.Database.SchemaQueue do
                local entry = impulse.Database.SchemaQueue[i]
                impulse.Database:InsertSchema(entry[1], entry[2], entry[3])
            end
        end)
    query:Execute()

    logs:Database("tables loaded.")
end

--- Wipes all tables in the database, meaning all data will be lost.
-- @realm server
function impulse.Database:WipeTables(callback)
    local query

    query = mysql:Drop("impulse_players")
    query:Execute()

    query = mysql:Drop("impulse_inventory")
    query:Execute()

    query = mysql:Drop("impulse_reports")
    query:Execute()

    query = mysql:Drop("impulse_whitelists")
    query:Execute()

    query = mysql:Drop("impulse_refunds")
    query:Execute()

    query = mysql:Drop("impulse_rpgroups")
    query:Execute()

    query = mysql:Drop("impulse_data")
    query:Execute()

    query = mysql:Drop("impulse_schema")
        query:Callback(callback)
    query:Execute()
end

--- Prints all possible data from the impulse_players table
-- @realm server
function impulse.Database:PrintAllPlayers()
    local query = mysql:Select("impulse_players")
    query:Callback(function(result)
        print("Printing impulse_players table:")
        PrintTable(result)
    end)
    query:Execute()
end

concommand.Add("impulse_players_printall", function(client)
    if ( !IsValid(client) or !client:IsSuperAdmin() ) then return end

    impulse.Database:PrintAllPlayers()
end)

hook.Add("InitPostEntity", "impulseDatabaseConnect", function()
    -- Connect to the database using SQLite, mysqoo, or tmysql4.
    impulse.Database:Connect()
end)

local resetCalled = 0

concommand.Add("impulse_database_reset", function(client, cmd, arguments)
    -- can only be ran through the server's console
    if ( !IsValid(client) or client:IsListenServerHost() ) then
        if ( resetCalled < RealTime() ) then
            resetCalled = RealTime() + 3

            logs:Error("WIPING THE DATABASE WILL PERMENANTLY REMOVE ALL PLAYER, CHARACTER, ITEM, AND INVENTORY DATA.")
            logs:Error("THE SERVER WILL RESTART TO APPLY THESE CHANGES WHEN COMPLETED.")
            logs:Error("TO CONFIRM DATABASE RESET, RUN 'impulse_database_reset' AGAIN WITHIN 3 SECONDS.")
        else
            resetCalled = 0
            logs:Error("DATABASE WIPE IN PROGRESS...")

            hook.Run("OnWipeTables")

            impulse.Database:WipeTables(function()
                logs:Warning("DATABASE WIPE COMPLETED! RESTARTING SERVER...")
                RunConsoleCommand("changelevel", game.GetMap())
            end)
        end
    end
end)
