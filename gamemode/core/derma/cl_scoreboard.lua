local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 2, ScrH() / 1.25)
    self:Center()
    self:SetTitle("Scoreboard")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    self:MoveToFront()
    self:SetKeyboardInputEnabled(false)

    self.scrollPanel = vgui.Create("DScrollPanel", self)
    self.scrollPanel:Dock(FILL)

    local playerList = {}
    for _, client in player.Iterator() do
        if ( client:IsAdmin() and client:GetRelay("incognito", false) ) then continue end

        table.insert(playerList, client)
    end

    table.sort(playerList, function(a,b)
        return a:Team() > b:Team()
    end)

    for _, client in ipairs(playerList) do
        local playerCard = self.scrollPanel:Add("impulseScoreboardCard")
        playerCard:Dock(TOP)
        playerCard:SetPlayer(client)
    end
end


vgui.Register("impulseScoreboard", PANEL, "DFrame")
