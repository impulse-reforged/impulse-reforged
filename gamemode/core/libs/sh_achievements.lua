
--[[
    Helper functions for achievements

    These functions are used to give, take, check and calculate achievement points for players
]]

-- @module impulse.Achievements

impulse.Achievements = impulse.Achievements or {}

local PLAYER = FindMetaTable("Player")

if ( SERVER ) then
    --- Player class methods
    -- @classmod Player

    --- Gives an achievement to a player
    -- @realm server
    -- @string class Achievement class
    -- @bool[opt=false] skipPoints Wether to skip calculating the points from this achievement
    function PLAYER:AchievementGive(class, skipPoints)
        if not self.impulseData then return end

        self.impulseData.Achievements = self.impulseData.Achievements or {}
        if self.impulseData.Achievements[class] then return end

        self.impulseData.Achievements[class] = math.floor(os.time())
        self:SaveData()

        net.Start("impulseAchievementGet")
        net.WriteString(class)
        net.Send(self)

        if not skipPoints then
            self:CalculateAchievementPoints()
        end
    end

    --- Takes an achievement from a player
    -- @realm server
    -- @string class Achievement class
    function PLAYER:AchievementTake(class)
        if not self.impulseData then return end

        self.impulseData.Achievements = self.impulseData.Achievements or {}
        self.impulseData.Achievements[class] = nil
        self:SaveData()
    end

    --- Returns if a player has an achievement
    -- @realm server
    -- @string class Achievement class
    -- @treturn bool Has achievement
    function PLAYER:AchievementHas(class)
        if not self.impulseData then
            return false
        end

        self.impulseData.Achievements = self.impulseData.Achievements or {}

        if self.impulseData.Achievements[class] then
            return true
        end

        return false
    end

    --- Runs the achievement's check function and if it returns true, awards the achievement
    -- @realm server
    -- @string class Achievement class
    function PLAYER:AchievementCheck(class)
        if not self.impulseData then return end

        self.impulseData.Achievements = self.impulseData.Achievements or {}
        local ach = impulse.Config.Achievements[class]

        if ach.OnJoin and ach.Check and !self:AchievementHas(class) and ach.Check(self) then
            self:AchievementGive(class)
        end
    end

    --- Calculates the achievement points and stores them in the "achievementPoints" SyncVar on the player
    -- @realm server
    -- @treturn int Achievement points
    function PLAYER:CalculateAchievementPoints()
        if not self.impulseData then
            return 0
        end

        local val = 0

        for v, k in pairs(self.impulseData.Achievements) do
            val = val + 60
        end

        self:SetNetVar("achievementPoints", val)
        return val
    end
end