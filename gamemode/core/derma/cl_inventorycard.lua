local PANEL = {}

function PANEL:Init()
    self:Receiver("impulseInv")
end

local outlineCol = Color(10, 10, 10, 255)
local darkCol = Color(30, 30, 30, 190)
local fullCol = Color(139, 0, 0, 15)

function PANEL:Paint(width, height)
    surface.SetDrawColor(darkCol)
    surface.DrawRect(0, 0, width, height)

    if ( self.Unusable ) then
        surface.SetDrawColor(fullCol)
        surface.DrawRect(0, 0, width, height)
    end

    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(0, 0, width, height)
end

vgui.Register("impulseInventoryCard", PANEL, "DPanel")
