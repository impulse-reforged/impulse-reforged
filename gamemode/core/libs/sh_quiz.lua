-- Shared quiz system utilities
-- Functions accessible on both client and server

impulse.Quiz = impulse.Quiz or {}

if CLIENT then
    --- Check if quiz system is enabled (client-side)
    -- @realm client
    -- @treturn bool Whether quiz is enabled
    function impulse.Quiz:IsEnabled()
        return impulse.Config.Quiz and impulse.Config.Quiz.Enabled or false
    end

    --- Check if local player has passed the quiz
    -- @realm client
    -- @treturn bool Whether player has passed
    function impulse.Quiz:HasPassed()
        if !self:IsEnabled() then
            return true
        end

        -- Check if player data is available yet
        if !impulse.localData then
            return false -- Data not synced yet, assume not passed
        end

        return LocalPlayer():GetData("quizPassed", false) == true
    end

    --- Show the entrance quiz panel
    -- @realm client
    function impulse.Quiz:Show()
        if IsValid(impulse.EntranceQuizPanel) then
            impulse.EntranceQuizPanel:Remove()
        end

        vgui.Create("impulseEntranceQuiz")
    end

    --- Check if player needs to show quiz on data sync
    -- @realm client
    -- @internal
    hook.Add("impulseLocalDataLoaded", "impulseQuizCheckOnDataLoad", function()
        -- If quiz panel is already open, update it
        if IsValid(impulse.EntranceQuizPanel) then
            return
        end

        -- If splash screen is showing and player hasn't passed, it will handle showing quiz
        if IsValid(impulse.SplashScreen) then
            return
        end

        -- This handles the case where data loads after splash screen is dismissed
        -- but before main menu opens (edge case)
    end)
end
