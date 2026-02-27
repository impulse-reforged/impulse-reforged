-- Server-side quiz system logic
-- Handles quiz validation, result processing, and enforcement

impulse.Quiz = impulse.Quiz or {}

-- Network strings
util.AddNetworkString("impulseQuizRequest")
util.AddNetworkString("impulseQuizSend")
util.AddNetworkString("impulseQuizEntrySubmit")
util.AddNetworkString("impulseQuizResult")

--- Check if quiz system is enabled
-- @realm server
-- @treturn bool Whether quiz is enabled
function impulse.Quiz:IsEnabled()
    return impulse.Config.Quiz and impulse.Config.Quiz.Enabled or false
end

--- Check if a player has already passed the quiz
-- @realm server
-- @player client The player to check
-- @treturn bool Whether player has passed
function impulse.Quiz:HasPassed(client)
    if ( !self:IsEnabled() ) then
        return true -- If quiz disabled, consider everyone passed
    end

    return client:GetData("quizPassed", false) == true
end

--- Mark a player as having passed the quiz
-- @realm server
-- @player client The player to mark
function impulse.Quiz:MarkPassed(client)
    client:SetData("quizPassed", true)
    client:SaveData()

    local name = client:Nick()
    local steamID = client:SteamID()

    print("[Quiz] " .. name .. " (" .. steamID .. ") passed the quiz")
end

--- Get quiz questions without correct answers marked
-- Sanitizes questions for client transmission
-- @realm server
-- @treturn table Sanitized questions
function impulse.Quiz:GetSanitizedQuestions()
    if !impulse.Config.Quiz or !impulse.Config.Quiz.Questions then
        return {}
    end

    local questions = {}

    for _, question in ipairs(impulse.Config.Quiz.Questions) do
        local sanitized = {
            id = question.id,
            text = question.text,
            type = question.type,
            shuffle = question.shuffle ~= false, -- Default to true
            answers = {}
        }

        -- Remove correct flags from answers
        for _, answer in ipairs(question.answers) do
            table.insert(sanitized.answers, {
                id = answer.id,
                text = answer.text
            })
        end

        table.insert(questions, sanitized)
    end

    return questions
end

--- Validate player's quiz answers
-- @realm server
-- @player client The player submitting answers
-- @table answers Table of answers in format: {questionID = {answerID1, answerID2, ...}}
-- @treturn bool Whether player passed
-- @treturn number Score (correct answers)
-- @treturn number Total questions
function impulse.Quiz:ValidateAnswers(client, answers)
    if !impulse.Config.Quiz or !impulse.Config.Quiz.Questions then
        return false, 0, 0
    end

    local correctCount = 0
    local totalQuestions = #impulse.Config.Quiz.Questions

    -- Check each question
    for _, question in ipairs(impulse.Config.Quiz.Questions) do
        local playerAnswers = answers[tostring(question.id)] or {}
        local correctAnswers = {}

        -- Build list of correct answer IDs
        for _, answer in ipairs(question.answers) do
            if answer.correct then
                table.insert(correctAnswers, tostring(answer.id))
            end
        end

        -- Compare player answers with correct answers
        local isCorrect = false

        if question.type == "single" then
            -- For single choice, player should have exactly one answer
            if #playerAnswers == 1 and table.HasValue(correctAnswers, playerAnswers[1]) then
                isCorrect = true
            end
        elseif question.type == "multiple" then
            -- For multiple choice, all selected must be correct and all correct must be selected
            if #playerAnswers == #correctAnswers then
                isCorrect = true
                for _, answerId in ipairs(playerAnswers) do
                    if !table.HasValue(correctAnswers, answerId) then
                        isCorrect = false
                        break
                    end
                end
            end
        end

        if isCorrect then
            correctCount = correctCount + 1
        end
    end

    -- Determine if player passed
    local requiredCorrect = impulse.Config.Quiz.RequiredCorrect or 0.8
    local passed = false

    if requiredCorrect < 1 then
        -- Percentage-based requirement
        local percentage = correctCount / totalQuestions
        passed = percentage >= requiredCorrect
    else
        -- Absolute number requirement
        passed = correctCount >= requiredCorrect
    end

    return passed, correctCount, totalQuestions
end

--- Apply configured action for quiz failure
-- @realm server
-- @player client The player who failed
-- @number score Their score
-- @number total Total questions
function impulse.Quiz:ApplyFailureAction(client, score, total)
    local action = impulse.Config.Quiz.Action or "none"
    local name = client:Nick()
    local steamID = client:SteamID()

    print("[Quiz] " .. name .. " (" .. steamID .. ") failed the quiz (" .. score .. "/" .. total .. ")")

    if ( action == "kick" ) then
        local reason = impulse.Config.Quiz.KickReason or "You failed the server quiz."
        client:Kick(reason)

    elseif ( action == "ban" ) then
        local reason = impulse.Config.Quiz.BanReason or "Failed server quiz."
        local length = impulse.Config.Quiz.BanLength or 60

        -- Try to use external ban systems if available
        if ( GExtension ) then
            GExtension:AddBan(client:SteamID64(), length * 60, reason, "0", GExtension:CurrentTime(), function()
                GExtension:InitBans()
            end)
        elseif ( VyHub ) then
            VyHub.Ban:create(client:SteamID64(), length * 60, reason)
        else
            -- Fallback to built-in ban
            print("[Quiz] Warning: No external ban system detected, using built-in ban")
            client:Ban(length * 60, false)
            client:Kick(reason)
        end

        if ( type(client) == "Player" ) then
            client:Kick(reason)
        end

    else
        -- Action is "none" - just log
        print("[Quiz] Player failed but no action configured")
    end
end

-- Network message handlers

-- Client requests quiz questions
net.Receive("impulseQuizRequest", function(len, client)
    if !impulse.Quiz:IsEnabled() then return end

    -- Send sanitized questions to client
    local questions = impulse.Quiz:GetSanitizedQuestions()

    net.Start("impulseQuizSend")
        net.WriteTable(questions)
    net.Send(client)

    print("[Quiz] Sent quiz to " .. client:Nick() .. " (" .. client:SteamID() .. ")")
end)

-- Client submits quiz answers
net.Receive("impulseQuizEntrySubmit", function(len, client)
    if !impulse.Quiz:IsEnabled() then return end

    -- Prevent re-submission if already passed
    if impulse.Quiz:HasPassed(client) then
        print("[Quiz] " .. client:Nick() .. " attempted to re-submit quiz (already passed)")
        return
    end

    -- Read answers
    local answers = net.ReadTable()

    -- Validate answers
    local passed, score, total = impulse.Quiz:ValidateAnswers(client, answers)

    -- Send result to client
    net.Start("impulseQuizResult")
        net.WriteBool(passed)
        net.WriteUInt(score, 8)
        net.WriteUInt(total, 8)
    net.Send(client)

    if passed then
        -- Mark player as passed
        impulse.Quiz:MarkPassed(client)
    else
        -- Apply failure action
        timer.Simple(3, function()
            if type(client) == "Player" then
                impulse.Quiz:ApplyFailureAction(client, score, total)
            end
        end)
    end
end)

-- Hook to check if player needs quiz when they connect
hook.Add("PlayerInitialSpawn", "impulseQuizCheck", function(client)
    if !impulse.Quiz:IsEnabled() then return end

    -- Data will be loaded by the framework's existing systems
    -- We just need to wait for it
    timer.Simple(1, function()
        if type(client) != "Player" then return end

        if !impulse.Quiz:HasPassed(client) then
            print("[Quiz] " .. client:Nick() .. " needs to complete the quiz")
        end
    end)
end)
