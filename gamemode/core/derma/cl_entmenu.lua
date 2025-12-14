local PANEL = {}

function PANEL:Init()
    self:SetSize(ScreenScale(64), ScrH() / 1.75)
    self:Center()
    self:SetTitle("Entity Interaction")
    self:MakePopup()

    self.list = vgui.Create("DScrollPanel", self)
    self.list:Dock(FILL)
    self.list:InvalidateParent(true)
    self.list:GetVBar():SetWide(0)
end

function PANEL:AddAction(icon, name, onClick)
    local actionButton = vgui.Create("DButton", self.list)
    actionButton:Dock(TOP)
    actionButton:SetText("")
    actionButton:SetSize(self.list:GetWide(), self.list:GetWide())

    local actionIcon = vgui.Create("DImage", actionButton)
    actionIcon:SetSize(actionButton:GetTall() * 0.75, actionButton:GetTall() * 0.75)
    actionIcon:Center()
    actionIcon:SetImage(icon)

    actionButton.Paint = function(this)
        if ( this:IsHovered() ) then
            actionIcon:SetImageColor(impulse.Config.MainColour)
        else
            actionIcon:SetImageColor(color_white)
        end
    end

    actionButton.DoClick = onClick

    local actionLabel = vgui.Create("DLabel", actionButton)
    actionLabel:SetText(name)
    actionLabel:SetFont("Impulse-Elements18")
    actionLabel:SizeToContents()
    actionLabel:SetPos(actionButton:GetTall() / 2 - actionLabel:GetWide() / 2, actionButton:GetTall() - actionLabel:GetTall() * 2)

    actionIcon:SetY(actionIcon:GetY() - actionLabel:GetTall())

    self.hasAction = true
end

function PANEL:SetRangeEnt(ent)
    self.rangeEnt = ent
end

function PANEL:SetDoor(door)
    local panel = self
    local doorOwners = door:GetRelay("doorOwners", nil)
    local doorGroup = door:GetRelay("doorGroup", nil)
    local doorBuyable = door:GetRelay("doorBuyable", true)
    local isDoorMaster = false
    if doorOwners and doorOwners[1] == LocalPlayer():EntIndex() then
        isDoorMaster = true
    end

    local customCanEditDoor = hook.Run("CanEditDoor", LocalPlayer(), door)

    if door:IsDoor() then
        if LocalPlayer():CanLockUnlockDoor(doorOwners, doorGroup) then
            self:AddAction("impulse-reforged/icons/padlock-2-256.png", "Unlock", function()
                net.Start("impulseDoorUnlock")
                net.SendToServer()

                panel:Remove()
            end)
            self:AddAction("impulse-reforged/icons/padlock-256.png", "Lock", function()
                net.Start("impulseDoorLock")
                net.SendToServer()

                panel:Remove()
            end)
        end

        if LocalPlayer():CanBuyDoor(doorOwners, doorBuyable) and (customCanEditDoor or customCanEditDoor == nil) then
            self:AddAction("impulse-reforged/icons/banknotes-256.png", "Buy", function()
                net.Start("impulseDoorBuy")
                net.SendToServer()

                panel:Remove()
            end)
        end

        if LocalPlayer():IsDoorOwner(doorOwners) and isDoorMaster and (customCanEditDoor or customCanEditDoor == nil) then
            self:AddAction("impulse-reforged/icons/group-256.png", "Permissions", function()
                doorOwners = door:GetRelay("doorOwners", nil)

                local perm = DermaMenu()

                local addMenu, x = perm:AddSubMenu("Add")
                x:SetIcon("icon16/add.png")
                local removeMenu, x = perm:AddSubMenu("Remove")
                x:SetIcon("icon16/delete.png")

                local exclude = {}

                for v, k in pairs(doorOwners) do
                    k = Entity(k)

                    exclude[k] = true

                    if !IsValid(k) or !k:IsPlayer() or k == LocalPlayer() then
                        continue
                    end

                    local name = k:Nick()

                    if k:GetFriendStatus() == "friend" then
                        name = "(FRIEND) " .. name
                    end

                    local x = removeMenu:AddOption(name, function()
                        if IsValid(k) then
                            net.Start("impulseDoorRemove")
                            net.WriteEntity(k)
                            net.SendToServer()
                        else
                            LocalPlayer():Notify("Player has disconnected.")
                        end
                    end)
                    x:SetIcon("icon16/user_delete.png")
                end

                for v, k in player.Iterator() do
                    if exclude[k] or k == LocalPlayer() then
                        continue
                    end

                    local name = k:Nick()

                    if k:GetFriendStatus() == "friend" then
                        name = "(FRIEND) " .. name
                    end

                    local x = addMenu:AddOption(name, function()
                        if IsValid(k) then
                            net.Start("impulseDoorAdd")
                            net.WriteEntity(k)
                            net.SendToServer()
                        else
                            LocalPlayer():Notify("Player has disconnected.")
                        end
                    end)
                    x:SetIcon("icon16/user_add.png")
                end

                perm:Open()
            end)
            self:AddAction("impulse-reforged/icons/banknotes-256.png", "Sell", function()
                net.Start("impulseDoorSell")
                net.SendToServer()

                panel:Remove()
            end)
        end
    end

    hook.Run("DoorMenuAddOptions", self, door, doorOwners, doorGroup, doorBuyable)

    if !self.hasAction then return self:Remove() end
end

function PANEL:SetPlayer(client)
    if LocalPlayer():IsPolice() and LocalPlayer():CanArrest(client) and client:GetRelay("arrested", false) then
        self:AddAction("impulse-reforged/icons/search-3-256.png", "Search Inventory", function()
            LocalPlayer():ConCommand("say /invsearch")

            self:Remove()
        end)

        self:AddAction("impulse-reforged/icons/padlock-2-256.png", "Unrestrain", function()
            net.Start("impulseUnRestrain")
            net.SendToServer()

            self:Remove()
        end)
    end

    hook.Run("PlayerMenuAddOptions", self, client)

    if !self.hasAction then return self:Remove() end
end

function PANEL:SetContainer(ent)
    if ent:GetClass() == "impulse_container" and !ent:GetLoot() then
        if LocalPlayer():IsPolice() then
            self:AddAction("impulse-reforged/icons/padlock-2-256.png", "Remove Padlock", function()
                impulse.Util:MakeWorkbar(15, "Breaking padlock...", function()
                    if !IsValid(ent) then return end

                    net.Start("impulseInvContainerRemovePadlock")
                    net.SendToServer()
                end, true)

                self:Remove()
            end)
        end
    end

    if !self.hasAction then return self:Remove() end
end

function PANEL:SetBody(ragdoll)
    hook.Run("RagdollMenuAddOptions", self, ragdoll)

    if !self.hasAction then return self:Remove() end
end

function PANEL:Think()
    if self.rangeEnt and IsValid(self.rangeEnt) then
        local dist = self.rangeEnt:GetPos():DistToSqr(LocalPlayer():GetPos())

        if dist > (200 ^ 2) then
            LocalPlayer():Notify("The target moved too far away.")
            self:Remove()
        end
    end
end


vgui.Register("impulseEntityMenu", PANEL, "DFrame")
