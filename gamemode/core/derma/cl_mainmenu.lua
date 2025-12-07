local PANEL = {}

AccessorFunc(PANEL, "defaultColor", "DefaultColor", FORCE_STRINGFORCE_COLOR)
AccessorFunc(PANEL, "highlightColor", "HighlightColor", FORCE_STRINGFORCE_COLOR)

function PANEL:Init()
    self.defaultColor = color_white
    self.highlightColor = impulse.Config.MainColour

    self:SetFont("Impulse-Elements32")
    self:SetContentAlignment(4)
    self:SetColor(color_white)
end

function PANEL:Paint(width, height)
    if ( self:IsHovered() ) then
        self:SetColor(self.highlightColor or impulse.Config.MainColour)
    else
        self:SetColor(self.defaultColor or color_white)
    end
end

function PANEL:OnCursorEntered()
    surface.PlaySound("ui/buttonrollover.wav")
end

function PANEL:OnMousePressed()
    surface.PlaySound("ui/buttonclick.wav")

    if ( self.DoClick ) then
        self:DoClick()
    end
end

vgui.Register("impulseMainMenuButton", PANEL, "DButton")

local bodyCol = Color(30, 30, 30, 190)

PANEL = {}

function PANEL:Init()
    if ( IsValid(impulse.MainMenu) ) then
        impulse.MainMenu:Remove()
    end

    impulse.MainMenu = self
    impulse.HUDEnabled = false

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetPopupStayAtBack(true)

    self.core = vgui.Create("DPanel", self)
    self.core:SetPos(0, 0)
    self.core:SetSize(ScrW(), ScrH())

    self.core.Paint = function(this, width, height)
        if ( self.popup ) then
            impulse.Util:DrawBlurAt(70, 0, 400, height) -- left panel

            if ( impulse.Config.WordPressURL != "" or !table.IsEmpty(impulse.Config.SchemaChangelogs) ) then
                impulse.Util:DrawBlurAt(self:GetWide() - 600, 0, 500, 380) -- news panel
            end
        end
    end

    self.left = self.core:Add("DPanel")
    self.left:SetPos(70, 0)
    self.left:SetSize(400, ScrH())

    self.left.Paint = function(this, width, height)
        surface.SetDrawColor(bodyCol)
        surface.DrawRect(0, 0, width, height)

        impulse.Util:DrawLogo(30, 30, 340, 140)

        local isPreview = GetConVar("impulse_preview"):GetBool()
        if ( isPreview ) then
            draw.SimpleText("preview build", "Impulse-Elements24-Italic", 240, 100, Color(255, 242, 0), TEXT_ALIGN_TOP, TEXT_ALIGN_RIGHT)
        end
    end

    local button = self.left:Add("impulseMainMenuButton")
    button:Dock(TOP)
    button:DockMargin(30, 250, 0, 0)
    button:SetFont("Impulse-Elements48")
    button:SetText("Play")
    button:SizeToContents()

    timer.Simple(0, function()
        if ( self.popup ) then
            button:SetText("Resume")
            button:SizeToContents()
        end
    end)

    button.DoClick = function(this)
        if ( impulse_isNewPlayer == true ) then
            vgui.Create("impulseCharacterCreator", self)
        elseif ( self.popup ) then
            self:SetMouseInputEnabled(false)
            self:SetKeyboardInputEnabled(false)
            self:AlphaTo(0, 0.2, 0, function()
                self:Remove()
            end)

            impulse.HUDEnabled = true
        else
            LocalPlayer():ScreenFade(SCREENFADE.OUT, color_black, 1, 0.5)
            self:AlphaTo(0, 1, 0, function()
                self:Remove()
            end)

            timer.Simple(1, function()
                LocalPlayer():ScreenFade(SCREENFADE.IN, color_black, 4, 0.5)
                impulse.HUDEnabled = true
                FORCE_FADESPAWN = true
            end)
        end

        CRASHSCREEN_ALLOW = true
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(TOP)
    button:DockMargin(30, 0, 0, 0)
    button:SetFont("Impulse-Elements32")
    button:SetText("Settings")
    button:SizeToContents()

    button.DoClick = function(this)
        vgui.Create("impulseSettings", self)
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(TOP)
    button:DockMargin(30, 0, 0, 0)
    button:SetFont("Impulse-Elements32")
    button:SetText("Achievements")
    button:SizeToContents()

    button.DoClick = function(this)
        vgui.Create("impulseAchievements", self)
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(TOP)
    button:DockMargin(30, 0, 0, 0)
    button:SetFont("Impulse-Elements32")
    button:SetText("Community")
    button:SizeToContents()

    button.DoClick = function(this)
        gui.OpenURL(impulse.Config.CommunityURL or "www.google.com")
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(TOP)
    button:DockMargin(30, 0, 0, 0)
    button:SetFont("Impulse-Elements32")
    button:SetText("Donate")
    button:SizeToContents()
    button:SetDefaultColor(Color(218, 165, 32))

    button.DoClick = function(this)
        gui.OpenURL(impulse.Config.DonateURL or "www.google.com")
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(BOTTOM)
    button:DockMargin(30, 0, 0, 200)
    button:SetFont("Impulse-Elements32")
    button:SetText("Disconnect")
    button:SizeToContents()
    button:SetHighlightColor(Color(240, 0, 0))

    button.OnCursorEntered = function(this)
        surface.PlaySound("ui/buttonrollover.wav")
    end

    button.DoClick = function(this)
        Derma_Query("Are you sure you want to disconnect?",
            "impulse",
            "Yes",
            function()
                print("bye :(")
                RunConsoleCommand("disconnect")
            end,
            "No")
    end

    button = self.left:Add("impulseMainMenuButton")
    button:Dock(BOTTOM)
    button:DockMargin(30, 0, 0, 0)
    button:SetFont("Impulse-Elements32")
    button:SetText("Credits")
    button:SizeToContents()

    button.DoClick = function(this)
        if ( self.popup or IsValid(impulse.CreditsPanel) ) then return end

        self:AlphaTo(0, 1, 0, function()
            self:SetMouseInputEnabled(false)

            impulse.CreditsPanel = vgui.Create("impulseCredits")
            impulse.CreditsPanel:SetAlpha(0)
            impulse.CreditsPanel:AlphaTo(255, 4, 0)
        end)
    end

    timer.Simple(0, function()
        if ( self.popup ) then
            button:Hide()
        else
            button:Show()
        end
    end)

    button = self.core:Add("DImageButton")
    button:SetPos(self:GetWide() - 30 - 53, 10)
    button:SetImage("impulse-reforged/icons/social/discord.png")
    button:SetSize(62, 55)

    local highlightCol = Color(impulse.Config.MainColour.r, impulse.Config.MainColour.g, impulse.Config.MainColour.b)
    button.Paint = function(this, width, height)
        if ( this:IsHovered() ) then
            this:SetColor(highlightCol)
        else
            this:SetColor(color_white)
        end
    end

    button.OnCursorEntered = function(this)
        surface.PlaySound("ui/buttonrollover.wav")
    end

    button.DoClick = function(this)
        surface.PlaySound("ui/buttonclick.wav")
        gui.OpenURL(impulse.Config.DiscordURL or "https://discord.minerva-servers.com")
    end

    local schemaLabel = self.left:Add("DLabel")
    schemaLabel:SetFont("Impulse-Elements32")
    schemaLabel:SetText(impulse.Config.SchemaName)
    schemaLabel:SizeToContents()
    schemaLabel:SetPos(30, 170)

    if ( schemaLabel:GetWide() > 300 ) then
        schemaLabel:SetFont("Impulse-Elements27")
    end

    local year = os.date("%Y", os.time())
    local copyrightLabel = vgui.Create("DLabel", self.core)
    copyrightLabel:SetFont("Impulse-Elements14")
    copyrightLabel:SetText("Powered by impulse\nCopyright Minerva Servers " .. year .. "\nimpulse version: " .. impulse.Version.version)
    copyrightLabel:SizeToContents()
    copyrightLabel:SetPos(ScrW() - copyrightLabel:GetWide(), ScrH() - copyrightLabel:GetTall() - 5)

    if ( impulse.Config.WordPressURL != "" or !table.IsEmpty(impulse.Config.SchemaChangelogs) ) then
        local newsContainer = vgui.Create("DPanel", self.core)
        newsContainer:SetPos(self:GetWide() - 600, 0)
        newsContainer:SetSize(500, 400)
        newsContainer.Paint = function(this, width, height)
            surface.SetDrawColor(bodyCol)
            surface.DrawRect(0, 0, width, height - 20)
        end

        local newsLabel = vgui.Create("DLabel", newsContainer)
        newsLabel:Dock(TOP)
        newsLabel:DockMargin(10, 40, 0, 5)
        newsLabel:SetFont("Impulse-Elements32")
        newsLabel:SetText("News")
        newsLabel:SizeToContents()

        local newsFeed = vgui.Create("impulseNewsfeed", newsContainer)
        newsFeed:Dock(FILL)
    end

    local testMessage = function()
        hook.Run("ShowMenuModalMessage", self)
    end

    timer.Simple(0, function()
        if ( self.popup ) then return end

        hook.Run("DisplayMenuMessages", self)
        hook.Run("OnMenuFirstLoad", self)

        if ( REFUND_MSG ) then
            Derma_Message(REFUND_MSG, "impulse", "Claim Refund")
        end

        local missing = {}
        local addons = impulse.Addons or {}
        if ( #addons != 0 ) then
            for _, addon in ipairs(addons) do
                if ( !steamworks.IsSubscribed(addon.id) ) then
                    table.insert(missing, addon)
                end
            end
        end

        if ( #missing != 0 ) then
            local msg = "You are missing the following addons:\n\n"
            for _, addon in ipairs(missing) do
                msg = msg .. "- " .. addon.title .. "\n"
            end
            msg = msg .. "\nPlease subscribe to these addons to avoid missing textures and errors."

            Derma_Query(msg,
                "impulse",
                "Subscribe",
                function()
                    for _, addon in ipairs(missing) do
                        gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. addon.id)
                    end
                end,
                "No thanks")
        end

        if ( impulse.Settings:Get("perf_mcore") == false ) then
            Derma_Query("Would you like to enable Multi-core rendering?\nThis will often greatly improve your FPS, however if your computer has a low core count and/or\na small amount of RAM, it can cause crashes and performance problems.",
                "impulse",
                "Enable Multi-core rendering",
                function()
                    impulse.Settings:Set("perf_mcore", true)
                    testMessage()
                end,
                "No thanks")
        else
            testMessage()
        end
    end)
end

local konamiCode = {KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A}
local keyPos = 1
function PANEL:OnKeyCodePressed(key)
    if ( key == konamiCode[keyPos] ) then
        if ( key == KEY_A ) then
            vgui.Create("impulseMinigame", self)
            keyPos = 1
        end

        keyPos = keyPos + 1
    end
end

local vignette = Material("impulse-reforged/vignette.png")
local gradient = Material("vgui/gradient-l")
function PANEL:Paint(width, height)
    if ( self.popup ) then
        surface.SetDrawColor(0, 0, 0, 255)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, width, height)
    else
        impulse.Util:DrawBlur(self)

        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, width, height)

        surface.SetDrawColor(0, 0, 0, 100)
        surface.SetMaterial(vignette)
        surface.DrawTexturedRect(0, 0, width, height)
    end
end

function PANEL:OnRemove()
    impulse.HUDEnabled = true

    if ( IsValid(impulse.CreditsPanel) ) then
        impulse.CreditsPanel:Remove()
    end
end

vgui.Register("impulseMainMenu", PANEL, "DPanel")

concommand.Add("impulse_gui_mainmenu", function()
    if ( IsValid(impulse.MainMenu) ) then
        impulse.MainMenu:Remove()
    end

    vgui.Create("impulseMainMenu")
end)

if ( IsValid(impulse.MainMenu) ) then
    local popup = impulse.MainMenu.popup
    impulse.MainMenu:Remove()

    timer.Simple(0, function()
        impulse.MainMenu = vgui.Create("impulseMainMenu")
        impulse.MainMenu.popup = popup
        impulse.MainMenu:AlphaTo(255, 1)
    end)
end
