local logs = impulse.Logs

local bodyCol = Color(50, 50, 50, 210)
local secCol = Color(209, 209, 209, 255)
local noCol = Color(215, 40, 40, 255)

local PANEL = {}

function PANEL:Init()
    self:SetTall(ScreenScale(24))

    self.model = self:Add("DModelPanel")
    self.model:Dock(LEFT)
    self.model:DockMargin(0, 0, 8, 0)
    self.model:SetWide(self:GetTall())
    self.model:SetPaintBackground(false)
    self.model:SetCursor("none")
end

function PANEL:SetMix(mix)
    local wide = self:GetWide()
    local class = mix.Output
    local id = impulse.Inventory:ClassToNetID(class)
    local item = impulse.Inventory.Items[id]

    if ( !item ) then
        logs:Error("Could not find item: " .. class .. " for use in mix: " .. mix.Class .. "!")
        return self:Remove()
    end

    self.Item = item
    self.Mix = mix

    local panel = self

    self.model:SetMouseInputEnabled(true)
    self.model:SetModel(item.Model)
    self.model:SetSkin(item.Skin or 0)
    self.model:SetFOV(item.FOV or 35)

    self.model.LayoutEntity = function(this, ent)
        ent:SetAngles(Angle(0, 90, 0))

        if ( panel.Item.Material ) then
            ent:SetMaterial(panel.Item.Material)
        end

        if ( !item.NoCenter ) then
            this:SetLookAt(vector_origin)
        end
    end

    local camPos = self.model.Entity:GetPos()
    camPos:Add(Vector(0, 25, 25))

    if ( item.CamPos ) then
        self.model:SetCamPos(item.CamPos)
    else
        self.model:SetCamPos(camPos -  Vector(10, 0, 16))
    end

    local min, max = self.model.Entity:GetRenderBounds()
    self.model:SetLookAt(( max + min ) / 2)

    self.craft = self:Add("DButton")
    self.craft:Dock(RIGHT)
    self.craft:DockMargin(8, 8, 8, 8)
    self.craft:SetText("Craft")
    self.craft:SetFont("Impulse-Elements17")
    self.craft:SetWide(self:GetTall())
    self.craft:SetDisabled(true)
    self.craft.DoClick = function(this)
        panel.dad.UseItem = panel.Item
        panel.dad.UseMix = panel.Mix

        net.Start("impulseMixTry")
            net.WriteUInt(panel.Mix.NetworkID, 8)
        net.SendToServer()
    end

    self.canCraft = true


    self.title = self:Add("DLabel")
    self.title:Dock(TOP)
    self.title:DockMargin(0, 8, 0, 0)
    self.title:SetFont("Impulse-Elements19-Shadow")
    self.title:SetTextColor(item.Colour or color_white)
    self.title:SetText(item.Name)
    self.title:SetContentAlignment(4)

    self.level = self:Add("DLabel")
    self.level:Dock(TOP)
    self.level:SetFont("Impulse-Elements16")
    self.level:SetTextColor(mix.Level > LocalPlayer():GetSkillLevel("craft") and noCol or secCol)
    self.level:SetText("Level: " .. mix.Level)
    self.level:SetContentAlignment(4)
    
    self.required = self:Add("DLabel")
    self.required:Dock(TOP)
    self.required:SetFont("Impulse-Elements16")
    self.required:SetTextColor(secCol)
    self.required:SetText("Required items:")
    self.required:SetContentAlignment(4)

    self:RefreshCanCraft()
end

function PANEL:RefreshCanCraft()
    local mix = self.Mix

    self.canCraft = true

    self.required:Clear()

    local index = 0
    local row = 0
    for k, v in pairs(mix.Input) do
        local id = impulse.Inventory:ClassToNetID(k)
        if ( id ) then
            local name = impulse.Inventory.Items[id].Name
            local has, amount = LocalPlayer():HasInventoryItem(id)
            local need = v.take or 1
            amount = amount or 0

            local color = secCol
            if ( amount < need ) then
                self.canCraft = false
                color = noCol
            end

            local lbl = self.required:Add("DLabel")
            lbl:Dock(LEFT)
            lbl:DockMargin(index == 0 and impulse.Util:GetTextWidth("Required items: ", "Impulse-Elements16") or 4, 0, 0, 0)
            lbl:SetFont("Impulse-Elements16")
            lbl:SetTextColor(color)
            lbl:SetText(name .. " (" .. amount .. "/" .. need .. ")")
            lbl:SizeToContents()

            self.required:SizeToChildren(false, true)

            index = index + 1
        end
    end

    if ( self.canCraft ) then
        self.craft:SetDisabled(false)
    end
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(bodyCol)
    surface.DrawRect(0, 0, width, height)
end


vgui.Register("impulseCraftingItem", PANEL, "DPanel")