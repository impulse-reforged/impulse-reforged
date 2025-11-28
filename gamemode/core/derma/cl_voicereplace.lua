local PANEL = {}
local PlayerVoicePanels = {}
function PANEL:Init()
    self.LabelName = vgui.Create("DLabel", self)
    self.LabelName:SetFont("Impulse-Elements18-Shadow")
    self.LabelName:Dock(FILL)
    self.LabelName:DockMargin(8, 0, 0, 0)
    self.LabelName:SetTextColor(Color(255, 255, 255, 255))
    self.Color = color_transparent
    self:SetSize(250, 32 + 8)
    self:DockPadding(4, 4, 4, 4)
    self:DockMargin(2, 2, 2, 2)
    self:Dock(BOTTOM)
end

function PANEL:Setup(client)
    self.client = client
    self.LabelName:SetText(client:KnownName())
    self.Color = team.GetColor(client:Team())
    self:InvalidateLayout()
end

function PANEL:Paint(w, h)
    if not IsValid(self.client) then return end
    local vol = self.client:VoiceVolume()
    local col = team.GetColor(self.client:Team())
    draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 235))
    draw.RoundedBox(4, 0, 0, w, h, Color(vol * col.r, vol * col.g, vol * col.b, 170))
end

function PANEL:Think()
    if IsValid(self.client) then self.LabelName:SetText(self.client:KnownName()) end
    if self.fadeAnim then self.fadeAnim:Run() end
end

function PANEL:FadeOut(anim, delta, data)
    if anim.Finished then
        if IsValid(PlayerVoicePanels[self.client]) then
            PlayerVoicePanels[self.client]:Remove()
            PlayerVoicePanels[self.client] = nil
            return
        end
        return
    end

    self:SetAlpha(255 - (255 * delta))
end

derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")
function GM:PlayerStartVoice(client)
    if not IsValid(g_VoicePanelList) then return end
    -- There'd be an exta one if voice_loopback is on, so remove it.
    GAMEMODE:PlayerEndVoice(client)
    if IsValid(PlayerVoicePanels[client]) then
        if PlayerVoicePanels[client].fadeAnim then
            PlayerVoicePanels[client].fadeAnim:Stop()
            PlayerVoicePanels[client].fadeAnim = nil
        end

        PlayerVoicePanels[client]:SetAlpha(255)
        return
    end

    if not IsValid(client) then return end
    local pnl = g_VoicePanelList:Add("VoiceNotify")
    pnl:Setup(client)
    PlayerVoicePanels[client] = pnl
end

local function VoiceClean()
    for k, v in pairs(PlayerVoicePanels) do
        if not IsValid(k) then GAMEMODE:PlayerEndVoice(k) end
    end
end

timer.Create("VoiceClean", 10, 0, VoiceClean)

function GM:PlayerEndVoice(client)
    if IsValid(PlayerVoicePanels[client]) then
        if PlayerVoicePanels[client].fadeAnim then return end
        PlayerVoicePanels[client].fadeAnim = Derma_Anim("FadeOut", PlayerVoicePanels[client], PlayerVoicePanels[client].FadeOut)
        PlayerVoicePanels[client].fadeAnim:Start(2)
    end
end

local function CreateVoiceVGUI()
    if IsValid(g_VoicePanelList) then
        g_VoicePanelList:Remove()
        g_VoicePanelList = nil
    end

    g_VoicePanelList = vgui.Create("DPanel")
    g_VoicePanelList:ParentToHUD()
    g_VoicePanelList:SetPos(ScrW() - 300, 100)
    g_VoicePanelList:SetSize(250, ScrH() - 200)
    g_VoicePanelList:SetPaintBackground(false)
end

hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)
hook.Add("OnReloaded", "CreateVoiceVGUI", CreateVoiceVGUI)
hook.Add("OnScreenSizeChanged", "CreateVoiceVGUI", CreateVoiceVGUI)
