--- Allows for the creation of persistent menu messages similar in style to CS:GO's menu notifications
-- @module impulse.MenuMessage

file.CreateDir("impulse-reforged/menumsgs")

impulse.MenuMessage = impulse.MenuMessage or {}
impulse.MenuMessage.Stored = impulse.MenuMessage.Stored or {}

--- Creates a new MenuMessage and displays it
-- @realm client
-- @string uid Unique name
-- @string title Message title
-- @string message Message content
-- @color[opt] color The message colour
-- @string[opt] url The URL to open if pressed
-- @string[opt] urlText The text of the URL button
-- @int[opt] expiry UNIX time until when this message will automatically expire
function impulse.MenuMessage:Add(uid, title, message, color, url, urlText, expiry)
    if self.Stored[uid] then return end

    self.Stored[uid] = {
        type = uid,
        title = title,
        message = message,
        colour = color or impulse.Config.MainColour,
        url = url or nil,
        urlText = urlText or nil,
        expiry = expiry or nil
    }
end

--- Removes an active MenuMessage
-- @realm client
-- @string uid Unique name
function impulse.MenuMessage:Remove(uid)
    local msg = self.Stored[uid]
    if not msg then return end

    self.Stored[uid] = nil

    local fname = "impulse-reforged/menumsgs/"..uid..".json"

    if file.Exists(fname, "DATA") then
        file.Delete(fname)
    end
end

--- Saves the specified MenuMessage to file so it persists
-- @realm client
-- @string uid Unique name
function impulse.MenuMessage:Save(uid)
    local msg = self.Stored[uid]
    if not msg then return end

    local compiled = util.TableToJSON(msg)

    file.Write("impulse-reforged/menumsgs/"..uid..".json", compiled)
end

--- Returns if a MenuMessage can be seen
-- @realm client
-- @string uid Unique name
-- @internal
function impulse.MenuMessage:CanSee(uid)
    local msg = self.Stored[uid]
    if not msg then return end
    if not msg.scheduled then return true end

    if msg.scheduledTime and msg.scheduledTime != 0 then
        if os.time() > msg.scheduledTime then
            return true
        end
    end

    return false
end