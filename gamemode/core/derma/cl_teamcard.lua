local PANEL = {}

--- Parses model data and returns model path, skin, and bodygroups
-- @param modelData string or table - Can be "model.mdl", {"model.mdl", skin}, or {"model.mdl", skin, {bodygroups}}
-- @return string model, number skin, table bodygroups
local function ParseModelData(modelData)
    if ( type(modelData) == "string" ) then
        return modelData, nil, nil
    elseif ( type(modelData) == "table" ) then
        local model = modelData[1]
        local skin = modelData[2]
        local bodygroups = modelData[3]

        -- Handle random skin if it's a table
        if ( type(skin) == "table" ) then
            skin = skin[math.random(#skin)]
        end

        -- Handle random bodygroup values if they're tables
        if ( bodygroups and type(bodygroups) == "table" ) then
            local parsedBodygroups = {}
            for name, value in pairs(bodygroups) do
                if ( type(value) == "table" ) then
                    parsedBodygroups[name] = value[math.random(#value)]
                else
                    parsedBodygroups[name] = value
                end
            end
            bodygroups = parsedBodygroups
        end

        return model, skin, bodygroups
    end
    return nil, nil, nil
end

function PANEL:Init()
    self.colour = Color(60,255,105,150)
    self.name = "error"

    self:SetCursor("hand")
    self:SetHeight(ScreenScaleH(16))
end

function PANEL:SetTeam(teamID)
    self.teamID = teamID
    local teamData = impulse.Teams.Stored[teamID]
    self.colour = team.GetColor(teamID)
    self.name = team.GetName(teamID)
    self.players = #team.GetPlayers(teamID)
    self.playerCount = self.players
    self.model = impulse_defaultModel or "models/Humans/Group01/male_02.mdl"
    self.skin = impulse_defaultSkin or 0
    self.bodygroups = teamData.bodygroups or {}
    self.requirements = ""

    if ( teamData.limit ) then
        if ( teamData.percentLimit and teamData.percentLimit == true ) then
            self.playerCount = self.players .. "/" .. math.ceil(teamData.limit * player.GetCount())
        else
            self.playerCount = self.players .. "/" .. teamData.limit
        end
    else
        self.playerCount = self.players .. "/∞"
    end

    local modelData
    if ( teamData.models ) then
        modelData = teamData.models[math.random(#teamData.models)]
    elseif ( teamData.model ) then
        modelData = teamData.model
    end

    if ( modelData ) then
        self.model, self.skin, self.bodygroups = ParseModelData(modelData)
    end

    if ( teamData.xp and teamData.xp > 0 ) then
        self.requirements = teamData.xp .. "XP"
    end

    if ( teamData.donatorOnly and teamData.donatorOnly == true ) then
        self.requirements = self.requirements .. " (Donator only)"
    end

    self.modelIcon = vgui.Create("impulseSpawnIcon", self)
    self.modelIcon:Dock(LEFT)
    self.modelIcon:SetWide(self:GetTall())
    self.modelIcon:SetModel(self.model, self.skin or 0)
    self.modelIcon:SetTooltip(false)
    self.modelIcon:SetDisabled(true)
    self.modelIcon:SetDrawBorder(false)
    self.modelIcon.LayoutEntity = function(this, ent)
        if ( !IsValid(ent) ) then return end

        -- Apply model-specific bodygroups if any
        if ( self.bodygroups ) then
            for name, value in pairs(self.bodygroups) do
                ent:SetBodygroup(ent:FindBodygroupByName(name), value)
            end
        end
    end
end

local gradient = Material("vgui/gradient-l")
local outlineCol = Color(190,190,190,240)
local darkCol = Color(30,30,30,200)

function PANEL:Paint(width, height)
    surface.SetMaterial(gradient)
    surface.SetDrawColor(self.colour)
    surface.DrawTexturedRect(0, 0, width, height)

    surface.SetDrawColor(darkCol)
    surface.DrawTexturedRect(0, 0, width, height)

    if ( self.requirements != "" ) then
        draw.SimpleText(self.name, "Impulse-Elements18-Shadow", self.modelIcon:GetWide() + ScreenScale(2), height / 2, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(self.requirements, "Impulse-Elements18-Shadow", self.modelIcon:GetWide() + ScreenScale(2), height / 2, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText(self.name, "Impulse-Elements20-Shadow", self.modelIcon:GetWide() + ScreenScale(2), height / 2, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    draw.SimpleText(self.playerCount, "Impulse-Elements18-Shadow", width - ScreenScale(2), height / 2, nil, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function PANEL:PaintOver(width, height)
    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(0, 0, width, height)
end

vgui.Register("impulseTeamCard", PANEL, "DPanel")
