impulse.Arrest = impulse.Arrest or {}
impulse.Arrest.Dragged = impulse.Arrest.Dragged or {}
impulse.Arrest.Prison = impulse.Arrest.Prison or {}
impulse.Arrest.DisconnectRemember = impulse.Arrest.DisconnectRemember or {}

util.AddNetworkString("impulseSendJailInfo")

local PLAYER = FindMetaTable("Player")

function PLAYER:Arrest()
    self.impulseArrestedWeapons = {}

    for k, v in pairs(self:GetWeapons()) do
        table.insert(self.impulseArrestedWeapons, v:GetClass())
    end

    self:StripWeapons()
    self:StripAmmo()
    self:SetRunSpeed(impulse.Config.WalkSpeed - 30)
    self:SetWalkSpeed(impulse.Config.WalkSpeed - 30)

    self:SetRelay("arrested", true)
end

function PLAYER:UnArrest()
    self:SetRelay("arrested", false)

    if ( self.impulseArrestedWeapons ) then
        for k, v in ipairs(self.impulseArrestedWeapons) do
            local weapon = self:Give(v)
            weapon:SetClip1(0)
        end

        self.impulseArrestedWeapons = nil
    end

    self:SetRunSpeed(impulse.Config.JogSpeed)
    self:SetWalkSpeed(impulse.Config.WalkSpeed)
    self:SelectWeapon("impulse_hands")
    self:StopDrag()
    self:StripAmmo()
end

function PLAYER:DragPlayer(client)
    if ( self:CanArrest(client) and client:GetRelay("arrested", false) ) then
        client.impulseArrestedDragger = self
        self.impulseArrestedDragging = client
        impulse.Arrest.Dragged[client] = true

        self:Say("/me starts dragging " .. client:Name() .. ".")
    end
end

function PLAYER:StopDrag()
    impulse.Arrest.Dragged[self] = nil

    local dragger = self.impulseArrestedDragger
    if ( IsValid(dragger) ) then
        dragger.impulseArrestedDragging = nil
    end

    self.impulseArrestedDragger = nil
end

function PLAYER:SendJailInfo(time, jailData)
    net.Start("impulseSendJailInfo")
    net.WriteUInt(time, 16)

    if ( jailData ) then
        net.WriteBool(true)
        net.WriteTable(jailData)
    else
        net.WriteBool(false)
    end

    net.Send(self)
end

function PLAYER:Jail(time, jailData)
    local doCellMates = false
    local pos
    local cellID

    if ( self.InJail ) then return end

    if ( table.Count(impulse.Arrest.Prison) >= table.Count(impulse.Config.PrisonCells) ) then
        doCellMates = true
    end

    if ( !self:GetRelay("arrested", false) ) then
        self:Arrest()
    end

    for v, k in pairs(impulse.Config.PrisonCells) do
        local cellData = impulse.Arrest.Prison[v]
        if ( cellData and !doCellMates ) then
            continue
        end

        pos = k
        cellID = v

        if ( doCellMates ) then
            local cell = impulse.Arrest.Prison[v]
            cell[self:EntIndex()] = {
                inmate = self,
                jailData = jailData,
                duration = time,
                start = CurTime()
            }

            break
        else
            impulse.Arrest.Prison[v] = {}
            impulse.Arrest.Prison[v][self:EntIndex()] = {
                inmate = self,
                jailData = jailData,
                duration = time,
                start = CurTime()
            }

            break
        end
    end

    if ( pos ) then
        self:SetPos(impulse.Util:FindEmptyPos(pos, {self}, 100, 30, Vector(16, 16, 64)))
        self:SetEyeAngles(impulse.Config.PrisonAngle)

        self:ClearIllegalInventory()
        self:ClearRestrictedInventory()

        self:Notify("You have been imprisoned for " .. string.NiceTime(time) .. ".")
        self:SendJailInfo(time, jailData)
        self.InJail = cellID

        local prisonTimerName = "impulsePrison." .. self:UserID()
        timer.Create(prisonTimerName, time, 1, function()
            if ( !IsValid(self) ) then
                timer.Remove(prisonTimerName)
                return
            end

            if ( self.InJail ) then
                self:UnJail()
            end
        end)
    end
end

function PLAYER:UnJail()
    impulse.Arrest.Prison[self.InJail][self:EntIndex()] = nil
    self.InJail = nil

    if ( self.JailEscaped ) then
        self.JailEscaped = false
        return
    end

    if ( self:Alive() ) then
        self:Spawn()
    end

    self:UnArrest()

    self:Notify("You have been released from prison. Your sentence has ended.")

    hook.Run("PlayerUnJailed", self)
end
