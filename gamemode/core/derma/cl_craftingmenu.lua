local PANEL = {}

function PANEL:Init()
    if ( IsValid(impulse.CraftingMenu) ) then
        impulse.CraftingMenu:Remove()
    end

    impulse.CraftingMenu = self

    self:SetSize(ScrW() / 1.5, ScrH() / 1.5)
    self:Center()
    self:SetTitle("")
    self:MakePopup()

    self:SetupCrafting()
end

function PANEL:SetupCrafting()
    local client = LocalPlayer()

    local traceData = util.TraceLine({
        start = client:EyePos(),
        endpos = client:EyePos() + client:GetAimVector() * 96,
        filter = client
    })

    if ( !traceData.Entity or !IsValid(traceData.Entity) or traceData.Entity:GetClass() != "impulse_bench" ) then
        return self:Remove()
    end

    self.bench = traceData.Entity

    local benchType = traceData.Entity:GetBenchType()
    local benchClass = impulse.Inventory.Benches[benchType]
    local panel = self

    self:SetTitle(benchClass.Name)

    self.mixes = {}

    self.craftingLevel = self:Add("DLabel")
    self.craftingLevel:Dock(TOP)
    self.craftingLevel:SetFont("Impulse-Elements22-Shadow")
    self.craftingLevel:SetText("Crafting Level: " .. LocalPlayer():GetSkillLevel("craft"))
    self.craftingLevel:SizeToContents()

    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)

    self.availibleMixes = vgui.Create("DCollapsibleCategory", self.scroll)
    self.availibleMixes:SetLabel("Unlocked mixes")
    self.availibleMixes:Dock(TOP)

    function self.availibleMixes:Paint()
        self:SetBGColor(colInv)
    end

    self.availibleMixesLayout = vgui.Create("DListLayout")
    self.availibleMixesLayout:Dock(FILL)
    self.availibleMixes:SetContents(self.availibleMixesLayout)

    self.unAvailibleMixes = self.scroll:Add("DCollapsibleCategory")
    self.unAvailibleMixes:SetLabel("Locked mixes")
    self.unAvailibleMixes:Dock(TOP)

    function self.unAvailibleMixes:Paint()
        self:SetBGColor(colInv)
    end

    self.unAvailibleMixesLayout = vgui.Create("DListLayout")
    self.unAvailibleMixesLayout:Dock(FILL)
    self.unAvailibleMixes:SetContents(self.unAvailibleMixesLayout)

    local level = LocalPlayer():GetSkillLevel("craft")
    local mix = impulse.Inventory.Mixtures[benchType]
    local sortedMix = {}

    for v, k in pairs(mix) do
        table.insert(sortedMix, k)
    end

    table.sort(sortedMix, function(a, b)
        return a.Level < b.Level
    end)

    for v, k in pairs(sortedMix) do
        local cat = self.availibleMixesLayout

        if level < k.Level then
            cat = self.unAvailibleMixesLayout
        end

        local mix = cat:Add("impulseCraftingItem")
        mix:Dock(TOP)
        mix:SetMix(k)
        mix.dad = self

        table.insert(self.mixes, mix)
    end
end

function PANEL:Think()
    if self.bench and (not IsValid(self.bench) or self.bench:GetPos():DistToSqr(LocalPlayer():GetPos()) > (120 ^ 2)) then
        return self:Remove()
    end

    if not LocalPlayer():Alive() or LocalPlayer():IsCP() then
        return self:Remove()
    end

    if LocalPlayer():GetRelay("arrested", false) then
        return self:Remove()
    end
end

function PANEL:ShowNormal(should)
    if ( should ) then
        self.scroll:Show()
        self.craftingLevel:Show()
    else
        self.scroll:Hide()
        self.craftingLevel:Hide()
    end
end

function PANEL:PaintOver(w, h)
    -- if ( self.IsCrafting ) then
    --     draw.SimpleText("Crafting " .. self.CraftingItem .. " .. .", "Impulse-Elements22-Shadow", w / 2, h - ScreenScale(16) / 2 - ScreenScale(8), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    -- end
end

function PANEL:DoCraft(item, mix)
    local panel = self
    local length = impulse.Inventory:GetCraftingTime(mix)

    self:ShowNormal(false)
    self:ShowCloseButton(false)

    self.IsCrafting = true
    self.CraftingItem = item.Name

    self.craftBar = self:Add("DProgress")
    self.craftBar:Dock(BOTTOM)
    self.craftBar:DockMargin(ScreenScale(8), 0, ScreenScale(8), ScreenScale(8))
    self.craftBar:SetTall(ScreenScale(16))
    self.craftBar:SetFraction(0.5)

    self.crafting = self.craftBar:Add("DLabel")
    self.crafting:Dock(FILL)
    self.crafting:SetFont("Impulse-Elements22-Shadow")
    self.crafting:SetText("Crafting " .. item.Name)
    self.crafting:SetContentAlignment(5)
    self.crafting.dots = 0
    self.crafting.nextDot = CurTime() + 0.5
    self.crafting.Think = function(this)
        if ( CurTime() < this.nextDot ) then return end
        this.nextDot = CurTime() + 0.5

        this.dots = this.dots + 1
        if ( this.dots > 3 ) then
            this.dots = 0
        end

        local str = "Crafting " .. item.Name
        for i = 1, this.dots do
            str = str .. "."
        end

        this:SetText(str)
    end

    self.StartTime = CurTime()
    self.EndTime = CurTime() + length

    function self.craftBar:Think()
        -- local timeDist = panel.EndTime - CurTime()
        local progress = math.Clamp((panel.StartTime - CurTime()) / (panel.StartTime - panel.EndTime), 0, 1)

        self:SetFraction(progress)
        panel.model:SetColor(Color(255, 255, 255, progress * 255))

        if progress == 1 then
            panel:ShowNormal(true)
            panel:ShowCloseButton(true)
            panel.craftBar:Remove()
            panel.model:Remove()
            panel.IsCrafting = false

            timer.Simple(0.2, function()
                if IsValid(panel) then
                    for v, k in pairs(panel.mixes) do
                        if IsValid(k) then
                            k:RefreshCanCraft()
                        end
                    end
                end
            end)
        end
    end

    self.model = vgui.Create("DModelPanel", self)
    self.model:SetPaintBackground(false)
    self.model:SetSize(self:GetWide() / 2, self:GetTall() / 2)
    self.model:SetPos(self:GetWide() / 2 - (self.model:GetWide() / 2), self:GetTall() / 2 - (self.model:GetTall() / 2))
    self.model:SetMouseInputEnabled(true)
    self.model:SetModel(item.Model)
    self.model:SetSkin(item.Skin or 0)
    self.model:SetFOV(item.FOV or 35)
    self.model:SetCursor("none")

    function self.model:LayoutEntity(ent)
        ent:SetAngles(Angle(0, 90, 0))

        if item.Material then
            ent:SetMaterial(item.Material)
        end

        if not item.NoCenter then
            self:SetLookAt(vector_origin)
        end
    end

    function self.model:Think()
        if self.Entity and IsValid(self.Entity) and !self.Entity.rmSet then
            self.Entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
            self.Entity.rmSet = true
        end
    end

    local camPos = self.model.Entity:GetPos()
    camPos:Add(Vector(0, 25, 25))

    local min, max = self.model.Entity:GetRenderBounds()

    if item.CamPos then
        self.model:SetCamPos(item.CamPos)
    else
        self.model:SetCamPos(camPos -  Vector(10, 0, 16))
    end

    self.model:SetLookAt((max + min) / 2)
end

vgui.Register("impulseCraftingMenu", PANEL, "DFrame")

if ( IsValid(impulse.CraftingMenu) ) then
    impulse.CraftingMenu:Remove()

    vgui.Create("impulseCraftingMenu")
end
