-- Client-side entrance quiz UI panel
-- Displays quiz questions and handles answer submission

local PANEL = {}

local bodyCol = Color(30, 30, 30, 190)
local highlightCol = Color(51, 153, 255)

function PANEL:Init()
    if IsValid(impulse.EntranceQuizPanel) then
        impulse.EntranceQuizPanel:Remove()
    end

    impulse.EntranceQuizPanel = self
    impulse.HUDEnabled = false

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetPopupStayAtBack(true)

    self.questions = {}
    self.currentQuestion = 1
    self.answers = {} -- Store player's selections: {questionID = {answerID1, answerID2, ...}}
    self.submitted = false
    self.waiting = false

    -- Create main quiz panel
    self.quizPanel = self:Add("DFrame")
    self.quizPanel:SetSize(ScrW() * 0.4, ScrH() * 0.6)
    self.quizPanel:Center()
    self.quizPanel:SetTitle("")
    self.quizPanel:ShowCloseButton(false)
    self.quizPanel:SetDraggable(false)
    self.quizPanel:MakePopup()

    self.quizPanel.PaintOver = function(this, width, height)
        -- Draw title
        draw.SimpleText("Server Quiz", "Impulse-Elements48", width / 2, 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Draw subtitle
        local subtitle = "You must pass this quiz to access the server"
        if self.waiting then
            subtitle = "Submitting your answers..."
        end
        draw.SimpleText(subtitle, "Impulse-Elements19", width / 2, 85, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Create scroll panel for questions
    self.scroll = self.quizPanel:Add("DScrollPanel")
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(20, 120, 20, 10)

    -- Create controls panel (navigation buttons)
    self.controlsPanel = self.quizPanel:Add("DPanel")
    self.controlsPanel:Dock(BOTTOM)
    self.controlsPanel:DockMargin(20, 0, 20, 20)
    self.controlsPanel:SetTall(70)
    self.controlsPanel.Paint = function() end

    -- Progress label
    self.progressLabel = self.controlsPanel:Add("DLabel")
    self.progressLabel:Dock(TOP)
    self.progressLabel:SetTall(30)
    self.progressLabel:SetFont("Impulse-Elements24")
    self.progressLabel:SetContentAlignment(5)
    self.progressLabel:SetText("")

    -- Button container
    local btnContainer = self.controlsPanel:Add("DPanel")
    btnContainer:Dock(TOP)
    btnContainer:SetTall(35)
    btnContainer.Paint = function() end

    -- Previous button
    self.prevBtn = btnContainer:Add("DButton")
    self.prevBtn:Dock(LEFT)
    self.prevBtn:SetWide(180)
    self.prevBtn:SetFont("Impulse-Elements24")
    self.prevBtn:SetText("← Previous")
    self.prevBtn.DoClick = function()
        self:PreviousQuestion()
    end
    self.prevBtn.Paint = function(this, w, h)
        if this:IsHovered() then
            surface.SetDrawColor(highlightCol)
        else
            surface.SetDrawColor(60, 60, 60)
        end
        surface.DrawRect(0, 0, w, h)

        return false
    end

    -- Next button
    self.nextBtn = btnContainer:Add("DButton")
    self.nextBtn:Dock(LEFT)
    self.nextBtn:DockMargin(10, 0, 0, 0)
    self.nextBtn:SetWide(180)
    self.nextBtn:SetFont("Impulse-Elements24")
    self.nextBtn:SetText("Next →")
    self.nextBtn.DoClick = function()
        self:NextQuestion()
    end
    self.nextBtn.Paint = function(this, w, h)
        if this:IsHovered() then
            surface.SetDrawColor(highlightCol)
        else
            surface.SetDrawColor(60, 60, 60)
        end
        surface.DrawRect(0, 0, w, h)

        return false
    end

    -- Submit button
    self.submitBtn = btnContainer:Add("DButton")
    self.submitBtn:Dock(RIGHT)
    self.submitBtn:SetWide(180)
    self.submitBtn:SetFont("Impulse-Elements24")
    self.submitBtn:SetText("Submit Quiz")
    self.submitBtn.DoClick = function()
        self:SubmitQuiz()
    end
    self.submitBtn.Paint = function(this, w, h)
        local canSubmit = self:CanSubmit()

        if !canSubmit then
            surface.SetDrawColor(40, 40, 40)
            this:SetTextColor(Color(100, 100, 100))
        elseif this:IsHovered() then
            surface.SetDrawColor(Color(71, 193, 255))
            this:SetTextColor(color_white)
        else
            surface.SetDrawColor(highlightCol)
            this:SetTextColor(color_white)
        end

        surface.DrawRect(0, 0, w, h)

        return false
    end

    -- Request quiz from server
    self:RequestQuiz()
end

function PANEL:RequestQuiz()
    net.Start("impulseQuizRequest")
    net.SendToServer()
end

function PANEL:ReceiveQuiz(questions)
    self.questions = questions

    -- Shuffle answers if needed
    for _, question in ipairs(self.questions) do
        if question.shuffle then
            -- Shuffle using Fisher-Yates algorithm
            local answers = question.answers
            for i = #answers, 2, -1 do
                local j = math.random(i)
                answers[i], answers[j] = answers[j], answers[i]
            end
        end
    end

    self.currentQuestion = 1
    self:UpdateQuestion()
end

function PANEL:UpdateQuestion()
    -- Clear scroll panel
    self.scroll:Clear()

    local question = self.questions[self.currentQuestion]
    if !question then return end

    -- Update progress label
    self.progressLabel:SetText("Question " .. self.currentQuestion .. " of " .. #self.questions)

    -- Update button states
    self.prevBtn:SetEnabled(self.currentQuestion > 1)
    self.nextBtn:SetEnabled(self.currentQuestion < #self.questions)

    -- Create question container
    local container = self.scroll:Add("DPanel")
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 10)
    container.Paint = function() end

    local height = 0

    -- Question text
    local questionLabel = container:Add("DLabel")
    questionLabel:Dock(TOP)
    questionLabel:DockMargin(10, 10, 10, 10)
    questionLabel:SetFont("Impulse-Elements24")
    questionLabel:SetText(question.text)
    questionLabel:SetWrap(true)
    questionLabel:SetAutoStretchVertical(true)
    questionLabel:SetTextColor(color_white)

    height = height + questionLabel:GetTall() + 20

    -- Question type indicator
    local typeLabel = container:Add("DLabel")
    typeLabel:Dock(TOP)
    typeLabel:DockMargin(10, 5, 10, 10)
    typeLabel:SetFont("Impulse-Elements19")

    if question.type == "single" then
        typeLabel:SetText("(Select one answer)")
    else
        typeLabel:SetText("(Select all correct answers)")
    end
    typeLabel:SetTextColor(Color(200, 200, 200))

    height = height + typeLabel:GetTall() + 15

    -- Create answer options
    for _, answer in ipairs(question.answers) do
        local answerPanel = container:Add("DButton")
        answerPanel:Dock(TOP)
        answerPanel:DockMargin(10, 5, 10, 5)
        answerPanel:SetText("")
        answerPanel:SetTall(40)

        answerPanel.PaintOver = function(this, w, h)
            local hovering = this:IsHovered()
            local isSelected = self:IsAnswerSelected(question.id, answer.id)

            if isSelected then
                surface.SetDrawColor(highlightCol)
            elseif hovering then
                surface.SetDrawColor(70, 70, 70)
            else
                surface.SetDrawColor(50, 50, 50)
            end

            surface.DrawRect(0, 0, w, h)

            -- Draw selection indicator
            if isSelected then
                surface.SetDrawColor(color_white)
                surface.DrawRect(5, 5, 30, 30)
                surface.SetDrawColor(highlightCol)
                surface.DrawRect(7, 7, 26, 26)

                draw.SimpleText("✓", "Impulse-Elements24", 20, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                surface.SetDrawColor(color_white)
                surface.DrawOutlinedRect(5, 5, 30, 30, 2)
            end

            -- Draw answer text
            draw.SimpleText(answer.text, "Impulse-Elements19", 45, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        answerPanel.DoClick = function()
            self:ToggleAnswer(question.id, answer.id, question.type)
            surface.PlaySound("ui/buttonclick.wav")
        end

        height = height + answerPanel:GetTall() + 10
    end

    container:SetTall(height)
end

function PANEL:IsAnswerSelected(questionId, answerId)
    local questionAnswers = self.answers[tostring(questionId)] or {}
    return table.HasValue(questionAnswers, tostring(answerId))
end

function PANEL:ToggleAnswer(questionId, answerId, questionType)
    questionId = tostring(questionId)
    answerId = tostring(answerId)

    self.answers[questionId] = self.answers[questionId] or {}
    local questionAnswers = self.answers[questionId]

    if questionType == "single" then
        -- Single choice: replace any existing answer
        if self:IsAnswerSelected(questionId, answerId) then
            -- Unselect
            self.answers[questionId] = {}
        else
            -- Select this one only
            self.answers[questionId] = {answerId}
        end
    else
        -- Multiple choice: toggle this answer
        if self:IsAnswerSelected(questionId, answerId) then
            -- Remove from selection
            table.RemoveByValue(questionAnswers, answerId)
        else
            -- Add to selection
            table.insert(questionAnswers, answerId)
        end
    end
end

function PANEL:PreviousQuestion()
    if self.currentQuestion > 1 then
        self.currentQuestion = self.currentQuestion - 1
        self:UpdateQuestion()
        surface.PlaySound("ui/buttonrollover.wav")
    end
end

function PANEL:NextQuestion()
    if self.currentQuestion < #self.questions then
        self.currentQuestion = self.currentQuestion + 1
        self:UpdateQuestion()
        surface.PlaySound("ui/buttonrollover.wav")
    end
end

function PANEL:CanSubmit()
    if self.submitted or self.waiting then
        return false
    end

    -- Check that all questions have at least one answer
    for _, question in ipairs(self.questions) do
        local questionAnswers = self.answers[tostring(question.id)] or {}
        if #questionAnswers == 0 then
            return false
        end
    end

    return true
end

function PANEL:SubmitQuiz()
    if !self:CanSubmit() then
        surface.PlaySound("buttons/button10.wav")
        return
    end

    self.waiting = true
    self.submitted = true

    -- Send answers to server
    net.Start("impulseQuizEntrySubmit")
        net.WriteTable(self.answers)
    net.SendToServer()

    surface.PlaySound("ui/buttonclick.wav")

    -- Disable controls
    self.prevBtn:SetEnabled(false)
    self.nextBtn:SetEnabled(false)
    self.submitBtn:SetEnabled(false)

    -- Show waiting message
    self.scroll:Clear()

    local waitLabel = self.scroll:Add("DLabel")
    waitLabel:Dock(FILL)
    waitLabel:SetFont("Impulse-Elements32")
    waitLabel:SetText("Submitting your answers... Please wait.")
    waitLabel:SetContentAlignment(5)
    waitLabel:SetTextColor(color_white)
end

function PANEL:ShowResult(passed, score, total)
    self.waiting = false

    -- Clear everything
    self.scroll:Remove()
    self.controlsPanel:SetVisible(false)

    -- Show result
    local resultPanel = self.quizPanel:Add("DPanel")
    resultPanel:Dock(FILL)
    resultPanel:DockMargin(20, 20, 20, 20)
    resultPanel.Paint = function() end

    local resultLabel = resultPanel:Add("DLabel")
    resultLabel:Dock(TOP)
    resultLabel:DockMargin(0, 50, 0, 20)
    resultLabel:SetFont("Impulse-Elements48")
    resultLabel:SetContentAlignment(5)

    local scoreLabel = resultPanel:Add("DLabel")
    scoreLabel:Dock(TOP)
    scoreLabel:DockMargin(0, 0, 0, 30)
    scoreLabel:SetFont("Impulse-Elements32")
    scoreLabel:SetText("Score: " .. score .. " / " .. total)
    scoreLabel:SetContentAlignment(5)

    local messageLabel = resultPanel:Add("DLabel")
    messageLabel:Dock(TOP)
    messageLabel:DockMargin(50, 0, 50, 0)
    messageLabel:SetFont("Impulse-Elements24")
    messageLabel:SetWrap(true)
    messageLabel:SetAutoStretchVertical(true)
    messageLabel:SetContentAlignment(5)

    if passed then
        resultLabel:SetText("Quiz Passed!")
        resultLabel:SetTextColor(Color(0, 255, 100))
        scoreLabel:SetTextColor(color_white)
        messageLabel:SetText("Congratulations! You passed the quiz. You will now be granted access to the server.")
        messageLabel:SetTextColor(Color(200, 200, 200))

        surface.PlaySound("buttons/button14.wav")

        -- Close quiz and open main menu after delay
        timer.Simple(5, function()
            if IsValid(self) then
                self:Remove()

                -- Open main menu
                local mainMenu = vgui.Create("impulseMainMenu")
                mainMenu:SetAlpha(0)
                mainMenu:AlphaTo(255, 1)
            end
        end)
    else
        resultLabel:SetText("Quiz Failed")
        resultLabel:SetTextColor(Color(255, 50, 50))
        scoreLabel:SetTextColor(color_white)
        messageLabel:SetText("Unfortunately, you did not pass the quiz. Please review the server rules and try again.")
        messageLabel:SetTextColor(Color(200, 200, 200))

        surface.PlaySound("buttons/button10.wav")

        -- Player will be kicked/banned by server
    end
end

local vignette = Material("impulse-reforged/vignette.png")
function PANEL:Paint(width, height)
    impulse.Util:DrawBlur(self)

    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 100)
    surface.SetMaterial(vignette)
    surface.DrawTexturedRect(0, 0, width, height)
end

vgui.Register("impulseEntranceQuiz", PANEL, "DPanel")

-- Network message receivers
net.Receive("impulseQuizSend", function()
    local questions = net.ReadTable()

    if IsValid(impulse.EntranceQuizPanel) then
        impulse.EntranceQuizPanel:ReceiveQuiz(questions)
    end
end)

net.Receive("impulseQuizResult", function()
    local passed = net.ReadBool()
    local score = net.ReadUInt(8)
    local total = net.ReadUInt(8)

    if IsValid(impulse.EntranceQuizPanel) then
        impulse.EntranceQuizPanel:ShowResult(passed, score, total)
    end
end)

-- Console command for testing
concommand.Add("impulse_gui_entrancequiz", function()
    if IsValid(impulse.EntranceQuizPanel) then
        impulse.EntranceQuizPanel:Remove()
    end

    vgui.Create("impulseEntranceQuiz")
end)
