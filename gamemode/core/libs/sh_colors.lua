--- Various color related functions.
-- @module impulse.Colors

impulse.Colors = impulse.Colors or {}
impulse.Colors.Stored = impulse.Colors.Stored or {}

--- Adds a color to the color table.
-- @realm shared
-- @string name Name of the color
-- @color color Color to add
-- @usage impulse.Colors:Add("blue", Color(0, 0, 255))
function impulse.Colors:Add(name, color)
    table.insert(self.Stored, {name, color})
end

--- Gets a color from the color table.
-- @realm shared
-- @string name Name of the color
-- @treturn table Color table
-- @usage print(impulse.Colors:Get("blue"))
-- > Color(0, 0, 255)
function impulse.Colors:Get(name)
    for k, v in ipairs(self.Stored) do
        if ( impulse.Util:StringMatches(v[1], name) ) then
            return v[2]
        end
    end

    return nil
end

-- Some default colors
impulse.Colors:Add("red", Color(255, 0, 0))
impulse.Colors:Add("green", Color(0, 255, 0))
impulse.Colors:Add("blue", Color(0, 0, 255))
impulse.Colors:Add("yellow", Color(255, 255, 0))
impulse.Colors:Add("cyan", Color(0, 255, 255))
impulse.Colors:Add("magenta", Color(255, 0, 255))
impulse.Colors:Add("white", Color(255, 255, 255))
impulse.Colors:Add("black", Color(0, 0, 0))
impulse.Colors:Add("orange", Color(255, 165, 0))
impulse.Colors:Add("purple", Color(128, 0, 128))
impulse.Colors:Add("pink", Color(255, 192, 203))
impulse.Colors:Add("brown", Color(165, 42, 42))
impulse.Colors:Add("gray", Color(128, 128, 128))
impulse.Colors:Add("lightgray", Color(211, 211, 211))
impulse.Colors:Add("darkgray", Color(64, 64, 64))
impulse.Colors:Add("lime", Color(50, 205, 50))
impulse.Colors:Add("skyblue", Color(135, 206, 235))
impulse.Colors:Add("gold", Color(255, 215, 0))
impulse.Colors:Add("silver", Color(192, 192, 192))
impulse.Colors:Add("navy", Color(0, 0, 128))

-- Framework specific colors
impulse.Colors:Add("impulse", Color(83, 143, 239))

--- Default colors for the framework.
-- @realm shared
-- @field red
-- @field green
-- @field blue
-- @field yellow
-- @field cyan
-- @field magenta
-- @field white
-- @field black
-- @field orange
-- @field purple
-- @field pink
-- @field brown
-- @field gray
-- @field lightgray
-- @field darkgray
-- @field lime
-- @field skyblue
-- @field gold
-- @field silver
-- @field navy
-- @field impulse Framework color
-- @table impulse.Colors.Stored
