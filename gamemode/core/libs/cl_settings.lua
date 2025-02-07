--- Allows the creation, updating and reading of persistent settings
-- @module impulse.Settings

impulse.Settings = impulse.Settings or {}
impulse.Settings.Stored = {}

--- A collection of data that defines how a setting will behave
-- @realm client
-- @string name The pretty name for the setting (we'll see this in the settings menu)
-- @string category The category the setting will belong to
-- @string type tickbox, dropdown, slider, plainint
-- @param default The default value of the setting
-- @int[opt] minValue Minimum value (slider only)
-- @int[opt] maxValue Maximum value (slider only)
-- @int[opt] decimals Number of decimal places (slider only)
-- @param options A table of string options (dropdown only)
-- @func[opt] onChanged Called when setting is changed
-- @table SettingData

--- Defines a new setting for use
-- @realm client
-- @string name Setting class name
-- @param settingData A table containg setting data (see below)
-- @see SettingData
-- @usage impulse.Settings:Define("tickbox_setting", {
--     name = "Tickbox Setting",
--     category = "Example Category",
--     type = "tickbox",
--     default = 1,
--     onChanged = function(newVal)
--         print("Tickbox setting changed to: "..newVal)
--     end
-- })
-- @usage impulse.Settings:Define("slider_setting", {
--     name = "Slider Setting",
--     category = "Example Category",
--     type = "slider",
--     default = 50,
--     minValue = 0,
--     maxValue = 100,
--     decimals = 2,
--     onChanged = function(newVal)
--         print("Slider setting changed to: "..newVal)
--     end
-- })
-- @usage impulse.Settings:Define("dropdown_setting", {
--     name = "Dropdown Setting",
--     category = "Example Category",
--     type = "dropdown",
--     default = "Option 1",
--     options = {"Option 1", "Option 2", "Option 3"},
--     onChanged = function(newVal)
--         print("Dropdown setting changed to: "..newVal)
--     end
-- })
-- @usage impulse.Settings:Define("textbox_setting", {
--     name = "Textbox Setting",
--     category = "Example Category",
--     type = "textbox",
--     default = "Default text",
--     onChanged = function(newVal)
--         print("Textbox setting changed to: "..newVal)
--     end
-- })

local logs = impulse.Logs
function impulse.Settings:Define(name, settingData)
    if not settingData then
        logs:Error("Could not Define Setting. Data is nil, attempted name: "..name)
    end

    if not type(settingData) == "table" then
        logs:Error("Could not Define Setting. Data is not a table, attempted name: "..name)
    end

    if not settingData.name then
        logs:Error("Could not Define Setting. Name is nil, attempted name: "..name)
    end

    if not settingData.type then
        logs:Error("Could not Define Setting. Type is nil, attempted name: "..name)
    end

    if settingData.default == nil then
        logs:Error("Could not Define Setting. Default is nil, attempted name: "..name)
    end

    if settingData.type == "slider" then
        if not settingData.minValue then
            settingData.minValue = 0
        end

        if not settingData.maxValue then
            settingData.maxValue = 100
        end

        if not settingData.decimals then
            settingData.decimals = 0
        end
    elseif settingData.type == "dropdown" then
        if not settingData.options then
            logs:Error("Could not Define Setting. Options is nil, attempted name: "..name)
        end
    end

    if not settingData.category then
        settingData.category = "Other"
    end

    self.Stored[name] = settingData
    self:Load()

    return settingData
end

local toBool = tobool
local optX = {["tickbox"] = true} -- hash comparisons faster than string

--- Gets the value of a setting
-- @realm client
-- @string name Setting class name
-- @return Setting value
function impulse.Settings:Get(name)
    local settingData = self.Stored[name]
    if not settingData then
        return --MsgC(Color(255, 0, 0), "[impulse-reforged] Error, could not GetSetting. Please contact a developer, attempted name: "..name.."\n")
    end

    if optX[settingData.type] then
        if settingData.value == nil then
            return settingData.default
        end

        return toBool(settingData.value)
    end

    return settingData.value or settingData.default
end

--- Loads the settings from the clientside database
-- @realm client
-- @internal
function impulse.Settings:Load()
    for v, k in pairs(self.Stored) do
        if not k then
            logs:Error("Could not load setting. Please contact a developer. Attempted name: "..v)
            continue
        end

        if k.type == "tickbox" or k.type == "slider" or k.type == "plainint" then
            local def = k.default
            if k.type == "tickbox" then 
                def = tonumber(k.default) 
            end

            k.value = cookie.GetNumber("impulse-setting-"..v, def) -- Cache the data into a variable instead of sql so its fast
        elseif k.type == "dropdown" or k.type == "textbox" then
            k.value = cookie.GetString("impulse-setting-"..v, k.default)
        end

        if k.onChanged then
            k.onChanged(k.value)
        end
    end
end

--- Sets a setting to a specified value
-- @realm client
-- @string name Setting class name
-- @param value New value
function impulse.Settings:Set(name, value)
    local settingData = self.Stored[name]
    if settingData then
        if type(value) == "boolean" then -- convert them boolz to intz. it's basically a gang war
            value = value and 1 or 0
        end

        cookie.Set("impulse-setting-"..name, value)
        settingData.value = value

        if settingData.onChanged then
            settingData.onChanged(value)
        end

        return
    end

    return logs:Error("Could not SetSetting. Please contact a developer, attempted name: "..name)
end

concommand.Add("impulse_settings_reset", function()
    for v, k in pairs(impulse.Settings.Stored) do
        impulse.Settings:Set(v, k.default)
    end

    return logs:Success("Settings reset to default.")
end)