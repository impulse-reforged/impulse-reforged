local PANEL = {}

function PANEL:Init()
    if IsValid(impulse.CreditsPanel) then
        impulse.CreditsPanel:Remove()
    end

    impulse.CreditsPanel = self

    local year = os.date("%Y", os.time())

    self:SetAlpha(255)
    self:SetSize(600, ScrH())
    self:Center()

    self.killTime = CurTime() + 40
    self.killing = false

    self.mainCredits = markup.Parse([[
<font=Impulse-Elements32>
Framework creator</font><font=Impulse-Elements23>
vin</font>

<font=Impulse-Elements32>
Framework maintainer</font><font=Impulse-Elements23>
Riggs</font>

<font=Impulse-Elements32>
Framework contributor(s)</font><font=Impulse-Elements23>
aLoneWitness</font>

<font=Impulse-Elements32>
Third-party contrbutors</font><font=Impulse-Elements23>
Alex Grist — mysql wrapper
FredyH — mysqloo
thelastpenguin — pon
Kyle Smith — UTF-8 module
rebel1234 and Chessnut — animations base
wyozi — medialib
Dominic Letz — yaml parser
Falco — CPPI
vin — impulse markup language
kikito — tween.lua</font>

<font=Impulse-Elements32>
Powered by</font><font=Impulse-Elements23>
Discord — Discord API
Osyris — RbxDiscordProxy
Wordpress — Wordpress API</font>

<font=Impulse-Elements32>
Inspired by</font><font=Impulse-Elements23>
Aerolite, Apex-Roleplay and Cookie-Network</font>

<font=Impulse-Elements32>
Testing team</font><font=Impulse-Elements23>
Angrycrumpet
Aquaman
Baker
Bee
Bobby
Bwah
Desxon
EnigmaFusion
Ho
Jamsu
KTG
Law
Lefton
Lukyn150
Mats
Morgan
Ramtin
Shadow
Solo_D
StrangerThanYou
ThePersonWhoPlaysGames
Twatted
Y Tho
confuseth
greasy breads
psycho</font>

<font=Impulse-Elements32>
Special thanks</font><font=Impulse-Elements23>
Bee — Moderator
Bwah — Moderator
Law — Moderator
Lefton — Moderator
StrangerThanYou — Map development
Y Tho — Moderator & Early feedback
aLoneWitness — Framework development
morgan — Moderator & Early feedback
oscar holmes — Early feedback</font>

<font=Impulse-Elements32>
]] .. impulse.Config.SchemaName .. [[
]] .. impulse.Config.SchemaCredits .. [[</font>


<font=Impulse-Elements32>
Copyright Minerva Servers ]] .. year .. [[</font>]], 550)

    self.scrollY = ScrH() + 160

    if CREDIT_MUSIC and CREDIT_MUSIC:IsPlaying() then
        CREDIT_MUSIC:Stop()
    end

    CREDIT_MUSIC = CreateSound(LocalPlayer(), "music/HL2_song20_submix4.mp3")
    CREDIT_MUSIC:SetSoundLevel(0)
    CREDIT_MUSIC:ChangeVolume(1)
    CREDIT_MUSIC:Play()
end

local bodyCol = Color(30, 30, 30, 190)
function PANEL:Paint(w,h)
    impulse.Util:DrawBlur(self)

    surface.SetDrawColor(bodyCol)
    surface.DrawRect(0, 0, w, h)

    self.scrollY = self.scrollY - (FrameTime() * 88)

    impulse.Util:DrawLogo((w / 2) - 160, self.scrollY, 340, 140)
    self.mainCredits:Draw(100, self.scrollY + 190, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:OnRemove()
    if CREDIT_MUSIC and CREDIT_MUSIC:IsPlaying() then
        CREDIT_MUSIC:FadeOut(4)

        timer.Simple(4, function()
            if CREDIT_MUSIC:IsPlaying() then
                CREDIT_MUSIC:Stop()
            end
        end)
    end
end

function PANEL:Think()
    if CurTime() > self.killTime then
        if self.killing then return end

        self.killing = true
        self:AlphaTo(0, 2, 0, function()
            self:Remove()

            impulse.MainMenu:SetMouseInputEnabled(true)
            impulse.MainMenu:AlphaTo(255, 2, 0)
        end)
    end
end

vgui.Register("impulseCredits", PANEL, "DPanel")

if IsValid(impulse.CreditsPanel) then
    impulse.CreditsPanel:Remove()
end
