--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Entity")

util.AddNetworkString("impulseDataSync")
util.AddNetworkString("impulseData")

function PLAYER:LoadData(callback)
    hook.Run("PrePlayerDataLoaded", self)

    local name = self:SteamName()
    local steamID64 = self:SteamID64()
    local timestamp = math.floor(os.time())
    local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

    local query = mysql:Select("impulse_players")
        query:Select("data")
        query:Select("playtime")
        query:Where("steamid", steamID64)
        query:Callback(function(result)
            if (IsValid(self) and istable(result) and #result > 0 and result[1].data) then
                local updateQuery = mysql:Update("impulse_players")
                    updateQuery:Update("lastjoin", timestamp)
                    updateQuery:Update("address", ip)
                    updateQuery:Where("steamid", steamID64)
                updateQuery:Execute()

                self.impulsePlayTime = tonumber(result[1].playtime) or 0
                self.impulseData = util.JSONToTable(result[1].data)

                PrintTable(result)

                if (callback) then
                    callback(self.impulseData)
                end
            else
                local insertQuery = mysql:Insert("impulse_players")
                    insertQuery:Insert("rpname", "")
                    insertQuery:Insert("steamid", steamID64)
                    insertQuery:Insert("steamname", name)
                    insertQuery:Insert("group", "user")
                    insertQuery:Insert("rpgroup", 0)
                    insertQuery:Insert("rpgrouprank", "")
                    insertQuery:Insert("xp", 0)
                    insertQuery:Insert("money", 0)
                    insertQuery:Insert("bankmoney", 0)
                    insertQuery:Insert("skills", "")
                    insertQuery:Insert("ammo", "")
                    insertQuery:Insert("model", "")
                    insertQuery:Insert("skin", 0)
                    insertQuery:Insert("cosmetic", "")
                    insertQuery:Insert("data", util.TableToJSON({}))
                    insertQuery:Insert("firstjoin", timestamp)
                    insertQuery:Insert("lastjoin", timestamp)
                    insertQuery:Insert("address", ip)
                    insertQuery:Insert("playtime", 0)
                insertQuery:Execute()

                if (callback) then
                    callback({})
                end
            end

            hook.Run("PostPlayerDataLoaded", self)
        end)
    query:Execute()

    hook.Run("PlayerDataLoaded", self)
end

function PLAYER:SaveData()
    if (self:IsBot()) then return end

    local name = self:SteamName()
    local steamID64 = self:SteamID64()

    local query = mysql:Update("impulse_players")
        query:Update("steamname", name)
        query:Update("playtime", math.floor((self.impulsePlayTime or 0) + (RealTime() - (self.impulseJoinTime or RealTime() - 1))))
        query:Update("data", util.TableToJSON(self.impulseData))
        query:Where("steamid", steamID64)
    query:Execute()

    hook.Run("PlayerDataSaved", self)
end

function PLAYER:SetData(key, value, bNoNetworking)
    self.impulseData = self.impulseData or {}
    self.impulseData[key] = value

    if (!bNoNetworking) then
        net.Start("impulseData")
            net.WriteString(key)
            net.WriteType(value)
        net.Send(self)
    end

    hook.Run("PlayerDataUpdated", self, key, value)
end

--- Allows the player to control the PVS of the scene
-- @realm server
-- @bool bool Allow PVS control
function PLAYER:AllowScenePVSControl(bool)
    self.allowPVS = bool

    if ( !bool ) then
        self.extraPVS = nil
        self.extraPVS2 = nil
    end
end

function PLAYER:UpdateDefaultModelSkin()
    net.Start("impulseUpdateDefaultModelSkin")
        net.WriteString(self.impulseDefaultModel)
        net.WriteUInt(self.impulseDefaultSkin, 8)
    net.Send(self)
end

function PLAYER:GetPropCount(skip)
    if ( !self:IsValid() ) then return end

    local key = self:UniqueID()
    local tab = g_SBoxObjects[key]

    if ( !tab or !tab["props"] ) then
        return 0
    end

    local c = 0

    for k, v in pairs(tab["props"]) do
        if ( IsValid(v) and !v:IsMarkedForDeletion() ) then
            c = c + 1
        else
            tab["props"][k] = nil
        end

    end

    if not skip then
        self:SetLocalVar("propCount", c)
    end

    return c
end

function PLAYER:AddPropCount(ent)
    local key = self:UniqueID()
    g_SBoxObjects[ key ] = g_SBoxObjects[ key ] or {}
    g_SBoxObjects[ key ]["props"] = g_SBoxObjects[ key ]["props"] or {}

    local tab = g_SBoxObjects[ key ]["props"]

    table.insert( tab, ent )

    self:GetPropCount()

    ent:CallOnRemove("GetPropCountUpdate", function(ent, ply) ply:GetPropCount() end, self)
end

function PLAYER:ResetSubMaterials()
    if not self.SetSubMats then return end

    for v, k in pairs(self.SetSubMats) do
        self:SetSubMaterial(v - 1, nil)
    end

    self.SetSubMats = nil
end

function PLAYER:ClearWorkbar()
    net.Start("impulseClearWorkbar")
    net.Send(self)
end

function PLAYER:MakeWorkbar(time, text, onDone, popup)
    self:ClearWorkbar()

    if ( !time ) then
        net.Start("impulseMakeWorkbar")
        net.Send(self)

        return
    end

    net.Start("impulseMakeWorkbar")
        net.WriteUInt(time, 6)
        net.WriteString(text)
        net.WriteBool(popup)
    net.Send(self)

    if ( time and onDone ) then
        timer.Simple(time, function()
            if ( !IsValid(self) ) then return end

            onDone()
        end)
    end
end