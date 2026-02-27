local PANEL = {}

function PANEL:Init()
    self:SetTall(ScreenScaleH(32))
    self:SetText("")

    self.itemModel = vgui.Create("impulseModelPanel", self)
    self.itemModel:Dock(LEFT)
    self.itemModel:SetWide(self:GetTall())
    self.itemModel:SetMouseInputEnabled(false)

    self.topRow = vgui.Create("DPanel", self)
    self.topRow:Dock(TOP)
    self.topRow:DockMargin(ScreenScale(2), ScreenScaleH(2), ScreenScale(2), 0)
    self.topRow:SetMouseInputEnabled(false)
    self.topRow.Paint = nil

    self.itemName = vgui.Create("DLabel", self.topRow)
    self.itemName:Dock(LEFT)
    self.itemName:SetFont("Impulse-Elements19-Shadow")
    self.itemName:SetTextColor(color_white)

    self.itemWeight = vgui.Create("DLabel", self.topRow)
    self.itemWeight:Dock(RIGHT)
    self.itemWeight:SetFont("Impulse-Elements16")
    self.itemWeight:SetTextColor(color_white)

    self.itemDescription = vgui.Create("DLabel", self)
    self.itemDescription:Dock(FILL)
    self.itemDescription:DockMargin(ScreenScale(2), 0, ScreenScale(2), ScreenScaleH(2))
    self.itemDescription:SetFont("Impulse-Elements14")
    self.itemDescription:SetTextColor(color_white)
    self.itemDescription:SetMouseInputEnabled(false)
end

function PANEL:SetItem(itemNet, wide)
    local itemData = itemNet
    local itemID = impulse.Inventory:ResolveItemNetID(itemData)

    if ( !istable(itemData) ) then
        itemData = {id = itemID}
    end

    if ( !itemID ) then return end

    local item = impulse.Inventory.Items[itemID]
    if ( !item ) then return end

    self.Item = item

    local direct = self.ContainerType
    if ( !direct ) then
        self.IsEquipped = itemData.equipped or false
        self.IsRestricted = itemData.restricted or false
    end

    self.Weight = item.Weight or 0
    self.Count = 1

    local panel = self
    self.itemModel:SetModel(item.Model)
    self.itemModel:SetFOV(item.FOV or 35)

    if ( self.Item.ItemColour ) then
        self.itemModel:SetColor(self.Item.ItemColour)
    end

    local camPos = self.itemModel.Entity:GetPos()
    camPos:Add(Vector(0, 25, 25))

    local min, max = self.itemModel.Entity:GetRenderBounds()

    if ( item.CamPos ) then
        self.itemModel:SetCamPos(item.CamPos)
    else
        self.itemModel:SetCamPos(camPos -  Vector(10, 0, 16))
    end

    self.itemModel:SetLookAt((max + min) / 2)

    self.itemName:SetText(item.Name or "Unknown Item")
    self.itemName:SetTextColor(item.Colour or item.Color or color_white)
    self.itemName:SizeToContents()

    self.itemWeight:SetText((item.Weight or 0) .. "kg")
    self.itemWeight:SetTextColor(color_white)
    self.itemWeight:SizeToContents()

    self.topRow:SetTall(math.max(self.itemName:GetTall(), self.itemWeight:GetTall()) + 4)

    if ( wide < 800 ) then
        self.itemDescription:SetFont("Impulse-Elements14")
    else
        self.itemDescription:SetFont("Impulse-Elements16")
    end

    self.itemDescription:SetText(item.Desc or "")
    self.itemDescription:SetWrap(true)
    self.itemDescription:SizeToContentsY()
    self.itemDescription:SetContentAlignment(7)

    self.count = vgui.Create("DLabel", self)

    if ( self.IsRestricted or self.Item.Illegal ) then
        self.count:SetPos(42, 28)
    else
        self.count:SetPos(42, 38)
    end

    self.count:SetText("")
    self.count:SetTextColor(impulse.Config.MainColour)
    self.count:SetFont("Impulse-Elements19-Shadow")
    self.count:SetSize(36, 20)

    function self.count:Think()
        if panel.Count > 1 and panel.Count != self.lastCount then
            self:SetText("x" .. panel.Count)
            self.lastCount = panel.Count
            panel.Weight = panel.Count * panel.Item.Weight

            local wShift = 0

            if panel.Count > 99 then
                wShift = -16
            elseif panel.Count > 9 then
                wShift = -8
            end

            if panel.IsRestricted or panel.Item.Illegal then
                self:SetPos(42 + wShift, 28)
            else
                self:SetPos(42 + wShift, 38)
            end
        end
    end

    if ( self.Basic ) then return end

    local restrictedMat = "icon16/error.png"
    local illegalMat = "icon16/exclamation.png"

    if ( self.IsRestricted ) then
        self.tip = vgui.Create("DImageButton", self.itemModel)
        self.tip:SetPos(self.itemModel:GetWide() - 20, self.itemModel:GetWide() - 20)
        self.tip:SetSize(16, 16)
        self.tip:SetImage(restrictedMat)
    elseif ( self.Item.Illegal ) then
        self.tip = vgui.Create("DImageButton", self.itemModel)
        self.tip:SetPos(self.itemModel:GetWide() - 20, self.itemModel:GetWide() - 20)
        self.tip:SetSize(16, 16)
        self.tip:SetImage(illegalMat)
    end
end

function PANEL:OnMousePressed(keycode)
    if ( self.Disabled ) then return end

    if ( self.ContainerType or self.ContainerInv ) then
        net.Start("impulseInvContainerDoMove")
            net.WriteUInt(self.Type, 4)

            if ( self.Type == 1 ) then
                net.WriteUInt(self.InvID, 16)
            else
                net.WriteString(self.InvClass or self.Item.UniqueID)
            end
        net.SendToServer()

        return
    end

    if ( self.Basic ) then
        local itemID = self.InvID
        local count = self.Count

        if ( keycode == MOUSE_RIGHT and count > 1 ) then
            local m = DermaMenu(self)
            local opt

            local function moveItems(panel)
                if ( !IsValid(self) ) then
                    return
                end

                local amount = panel.Moving or 2

                if ( self.Count < amount ) then
                    return
                end

                net.Start("impulseInvDoMoveMass")
                    net.WriteString(self.Item.UniqueID)
                    net.WriteUInt(amount, 8)
                    net.WriteUInt(self.Type, 4)
                net.SendToServer()
            end

            if ( count >= 2 ) then
                opt = m:AddOption("Move 2", moveItems)
                opt.Moving = 2
                opt:SetIcon("icon16/arrow_right.png")
            end

            if ( count >= 5 ) then
                opt = m:AddOption("Move 5", moveItems)
                opt.Moving = 5
                opt:SetIcon("icon16/arrow_right.png")
            end

            if ( count >= 10 ) then
                opt = m:AddOption("Move 10", moveItems)
                opt.Moving = 10
                opt:SetIcon("icon16/arrow_right.png")
            end

            if ( count >= 15 ) then
                opt = m:AddOption("Move 15", moveItems)
                opt.Moving = 15
                opt:SetIcon("icon16/arrow_right.png")
            end

            if ( count >= 2 ) then -- Doing it again cus I want the option to be last
                opt2 = m:AddOption("Move All", moveItems)
                opt2.Moving = count
                opt2:SetIcon("icon16/arrow_right.png")
            end

            m:Open()

            return
        else
            net.Start("impulseInvDoMove")
                net.WriteUInt(itemID, 16)
                net.WriteUInt(self.Type, 4)
            net.SendToServer()
            return
        end
    end

    hook.Run("PrePopulateInventoryItemMenu", self)

    local popup = DermaMenu(self)
    popup.Inv = self

    if ( self.Item.OnUse ) then
        local shouldUse = true

        if ( self.Item.ShouldTraceUse ) then
            local trace = {}
            trace.start = LocalPlayer():EyePos()
            trace.endpos = trace.start + LocalPlayer():GetAimVector() * 85
            trace.filter = LocalPlayer()

            local trEnt = util.TraceLine(trace).Entity
            shouldUse = false

            if ( IsValid(trEnt) and self.Item.ShouldTraceUse(self.Item, LocalPlayer(), trEnt) ) then
                shouldUse = true
            end
        end

        if ( shouldUse ) then
            popup:AddOption(self.Item.UseName or "Use", function()
                if ( self.Item.ShouldTraceUse ) then
                    local trace = {}
                    trace.start = LocalPlayer():EyePos()
                    trace.endpos = trace.start + LocalPlayer():GetAimVector() * 85
                    trace.filter = LocalPlayer()

                    local trEnt = util.TraceLine(trace).Entity

                    if ( !IsValid(trEnt) or !self.Item.ShouldTraceUse(self.Item, LocalPlayer(), trEnt) ) then
                        return
                    end
                end

                if ( self.Item.UseWorkBarTime ) then
                    local itemID = self.InvID
                    gui.EnableScreenClicker(false)

                    if ( self.Item.UseWorkBarSound ) then
                        surface.PlaySound(self.Item.UseWorkBarSound)
                    end

                    impulse.Util:MakeWorkbar(self.Item.UseWorkBarTime, self.Item.UseWorkBarName or "Using...", function()
                        net.Start("impulseInvDoUse")
                            net.WriteUInt(itemID, 16)
                        net.SendToServer()
                    end, self.Item.UseWorkBarFreeze or false)

                    self.InvPanel:Remove()
                else
                    net.Start("impulseInvDoUse")
                        net.WriteUInt(self.InvID, 16)
                    net.SendToServer()
                end
            end)
        end
    end

    if ( self.Item.OnEquip and ( !self.Item.CanEquip or self.Item.CanEquip(LocalPlayer()) ) ) then
        if ( !self.IsEquipped ) then
            popup:AddOption(self.Item.EquipName or "Equip", function()
                net.Start("impulseInvDoEquip")
                    net.WriteUInt(self.InvID, 16)
                    net.WriteBool(true)
                net.SendToServer()
            end)
        else
            popup:AddOption(self.Item.UnEquipName or "Un-Equip", function()
                net.Start("impulseInvDoEquip")
                    net.WriteUInt(self.InvID, 16)
                    net.WriteBool(false)
                net.SendToServer()
            end)
        end
    end

    if ( !self.IsRestricted and !self.Item.DropIfRestricted) then
        popup:AddOption("Drop", function()
            net.Start("impulseInvDoDrop")
            net.WriteUInt(self.InvID, 16)
            net.SendToServer()
        end)
    end

    popup.Think = function(this)
        if ( !IsValid(this.Inv) ) then
            return this:Remove()
        end
    end

    popup:Open()

    hook.Run("PostPopulateInventoryItemMenu", self, popup)
end

local bodyCol = Color(50, 50, 50, 210)
local equippedCol = Color(0, 220, 0, 140)
function PANEL:Paint(width, height)
    surface.SetDrawColor(bodyCol)
    surface.DrawRect(0, 0, width, height)
end

local disabledCol = Color(15, 15, 15, 210)
function PANEL:PaintOver(width, height)
    if ( !self.Basic and self.IsEquipped ) then
        surface.SetDrawColor(equippedCol)
        surface.DrawRect(0, 0, ScreenScale(1), height)
    end

    if ( self.Disabled ) then
        surface.SetDrawColor(disabledCol)
        surface.DrawRect(0, 0, width, height)
    end
end

vgui.Register("impulseInventoryItem", PANEL, "DButton")
