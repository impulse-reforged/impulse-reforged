impulse.Ops = impulse.Ops or {}
impulse.Ops.AutoMod = impulse.Ops.AutoMod or {}


function impulse.Ops.AutoMod.Ban(client, reason, risk, details)
    local steamid = client:SteamID64()

    for v, k in player.Iterator() do
        if CAMI.PlayerHasAccess(k, "impulse: Bypass AutoMod") then
            k:AddChatText(Color(0, 163, 118), "[AutoMod] " .. steamid .. " issued ban for suspected " .. reason .. " (risk score " .. risk .. ")")
        end
    end

    local ban_reason = "AutoMod ban for suspected " .. reason .. ". Appeal @ impulse-community.com for review."

    if GExtension then
        GExtension:AddBan(client:SteamID64(), 0, ban_reason, "0", GExtension:CurrentTime(), function()
            GExtension:InitBans()
        end)
    elseif VyHub then
        VyHub.Ban:create(client:SteamID64(), nil, ban_reason)
    end

    local embeds = {
        title = "AutoMod ban issued",
        description = "User was identified as high risk by the automated moderator.\n<@&" .. impulse.Config.DiscordLeadModRoleID .. "> please investigate and review.",
        url = "https://panel.impulse-community.com/index.php?t=admin_bans&id=" .. client:SteamID64(),
        color = 7774976,
        fields = {
            {
                name = "User",
                value = "**" .. client:SteamName() .. "** (" .. client:SteamID64() .. ") (" .. client:Nick() .. ")"
            },
            {
                name = "Risk Score",
                value = risk or 0
            },
            {
                name = "Reason",
                value = reason
            },
            {
                name = "Details",
                value = "```" .. string.sub(details, 1, 1000) .. "```"
            }
        }
    }

    if IsValid(client) then
        client:Kick("Automatic punishment issued")
    end

                    if reqwest then

                        if embeds then
                            embeds.timestamp = os.date("%Y-%m-%dT%H:%M:%S.000Z", os.time())
                            embeds.footer = {}
                            embeds.footer.text = "ops (GMT)"
                        end

                        reqwest({
                            method = "POST",
                            url = impulse.Config.ReqwestDiscordWebhookURL,
                            timeout = 30,
                            body = util.TableToJSON({ embeds = {embeds} }),
                            type = "application/json",
                            headers = { ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36" },
                            success = function(status, body, headers)
                                print("HTTP " .. status)
                                PrintTable(headers)
                                print(body)
                            end,
                            failed = function(err, errExt)
                                print("Error: " .. err .. " (" .. errExt .. ")")
                            end
                        })
                    else
                opsDiscordLog("<@&" .. impulse.Config.DiscordLeadModRoleID .. ">", embeds)
                    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:AutoModLogAdd(msg)
    self.AutoModLog = self.AutoModLog or {}

    table.insert(self.AutoModLog, "[" .. os.date("%H:%M:%S", os.time()) .. "] " .. msg)
end

function PLAYER:AutoModLogGet()
    local o = ""
    for v, k in pairs(self.AutoModLog or {}) do
        o = o .. "\n" .. k
    end

    return o
end
