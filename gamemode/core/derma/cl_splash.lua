local PANEL = {}

function PANEL:Init()
    if ( IsValid(impulse.SplashScreen) ) then
        impulse.SplashScreen:Remove()
    end

    impulse.SplashScreen = self
    impulse.HUDEnabled = false

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetPopupStayAtBack(true)

    self.core = vgui.Create("DPanel", self)
    self.core:SetPos(0, 0)
    self.core:SetSize(ScrW(), ScrH())

    local splashCol = Color(200, 200, 200, 190)
    function self.core:Paint(width, height)
        local x = width / 2
        local y = height * .4
        local logo_scale = 1.2
        local logo_w = logo_scale * 340
        local logo_h = logo_scale * 140
        impulse.Util:DrawLogo(x - (logo_w / 2), y, logo_w, logo_h, true)

        local isPreview = GetConVar("impulse_preview"):GetBool()
        if ( isPreview ) then
            draw.SimpleText("preview build", "Impulse-SpecialFont", x, y + logo_h - 25, Color(255, 242, 0))
        end

        draw.DrawText("press left mouse button to continue", "Impulse-Elements27-Shadow", x, y + logo_h + 40, splashCol, TEXT_ALIGN_CENTER)
    end

    self.core.OnMousePressed = function(this, keyCode)
        self:OnKeyCodeReleased(keyCode)
    end
end

function PANEL:OnKeyCodeReleased(keyCode)
    if ( keyCode != MOUSE_LEFT ) then return end
    if ( self.used ) then return end

    self.used = true
    impulse_IsReady = true
    self.core:AlphaTo(0, 1.5, 0, function()
        if ( !IsValid(self) ) then return end

        timer.Simple(0.33, function()
            if ( GetGlobalString("impulse_fatalerror", "") != "" ) then
                local x, y = ScrW() * .3, ScrH() * .3

                local sad = vgui.Create("DImage", self)
                sad:SetPos(x + 210, y - 100)
                sad:SetSize(224, 60)
                sad:SetImage("impulse-reforged/impulse-logo-white.png")
                sad:SetAlpha(100)

                local sad = vgui.Create("DImage", self)
                sad:SetPos(x, y)
                sad:SetSize(180, 180)
                sad:SetImage("impulse-reforged/icons/sad.png")

                local title = vgui.Create("DLabel", self)
                title:SetPos(x + 210, y)
                title:SetFont("Impulse-Elements32-Shadow")
                title:SetText("Fatal Error")
                title:SizeToContents()

                local desc = vgui.Create("DLabel", self)
                desc:SetPos(x + 210, y + 70)
                desc:SetSize(410, 500)
                desc:SetFont("Impulse-Elements19-Shadow")
                desc:SetContentAlignment(7)
                desc:SetWrap(true)
                desc:SetText(GetGlobalString("impulse_fatalerror", "") .. "\n\nCheck the server console for more details. When you have corrected the fault, restart the server.")

                return
            end

            self:Remove()

            -- Check if player needs to complete entrance quiz
            if ( impulse.Quiz and impulse.Quiz:IsEnabled() and !impulse.Quiz:HasPassed() ) then
                -- Show entrance quiz instead of main menu
                impulse.Quiz:Show()
                return
            end

            if ( impulse_isNewPlayer or cookie.GetString("impulse_intro", "") == "true" ) then
                if ( cookie.GetString("impulse_intro", "") == "true" ) then
                    cookie.Delete("impulse_intro")
                end

                if ( impulse.Config.IntroScenes ) then
                    impulse.Scenes.PlaySet(impulse.Config.IntroScenes, impulse.Config.IntroMusic, function()
                        local mainMenu = vgui.Create("impulseMainMenu")
                        mainMenu:SetAlpha(0)
                        mainMenu:AlphaTo(255, 1)
                    end)
                else
                    local mainMenu = vgui.Create("impulseMainMenu")
                    mainMenu:SetAlpha(0)
                    mainMenu:AlphaTo(255, 1)
                end
            else
                local mainMenu = vgui.Create("impulseMainMenu")
                mainMenu.core:SetAlpha(0)
                mainMenu.core:AlphaTo(255, 1)
            end
        end)
    end)

    surface.PlaySound("ui/buttonclick.wav")

    hook.Run("PostReloadToolsMenu")
end

function PANEL:OnMousePressed(keyCode)
    self:OnKeyCodeReleased(keyCode)
end

local vignette = Material("impulse-reforged/vignette.png")
function PANEL:Paint(width, height)
    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 100)
    surface.SetMaterial(vignette)
    surface.DrawTexturedRect(0, 0, width, height)

    impulse.Util:DrawBlur(self)
end

vgui.Register("impulseSplash", PANEL, "DPanel")

concommand.Add("impulse_gui_splash", function()
    if ( IsValid(impulse.SplashScreen) ) then
        impulse.SplashScreen:Remove()
    end

    vgui.Create("impulseSplash")
end)

concommand.Add("impulse_intro_reset", function()
    cookie.Set("impulse_intro", "true")
    print("Intro reset. It will play next time you join.")
end)

if ( IsValid(impulse.SplashScreen) ) then
    impulse.SplashScreen:Remove()

    timer.Simple(0, function()
        vgui.Create("impulseSplash")
    end)
end
