
impulse.chatCommands = impulse.chatCommands or {}
impulse.chatClasses = impulse.chatClasses or {}

function impulse.RegisterChatCommand(name, cmdData)
    if not cmdData.adminOnly then cmdData.adminOnly = false end
    if not cmdData.leadAdminOnly then cmdData.leadAdminOnly = false end
    if not cmdData.superAdminOnly then cmdData.superAdminOnly = false end
    if not cmdData.description then cmdData.description = "" end
    if not cmdData.requiresArg then cmdData.requiresArg = false end
    if not cmdData.requiresAlive then cmdData.requiresAlive = false end

    impulse.chatCommands[name] = cmdData
end

if ( SERVER ) then
    local PLAYER = FindMetaTable("Player")

    util.AddNetworkString("impulseChatNetMessage")
    function PLAYER:SendChatClassMessage(id, message, target)
        net.Start("impulseChatNetMessage")
        net.WriteUInt(id, 8)
        net.WriteString(message)
        if target then
            net.WriteUInt(target:EntIndex(), 8)
        end
        net.Send(self)
    end
else
    function impulse.RegisterChatClass(id, onReceive)
        impulse.chatClasses[id] = onReceive
    end
end

local oocCol = color_white
local oocTagCol = Color(200, 0, 0)
local yellCol = Color(255, 140, 0)
local whisperCol = Color(65, 105, 225)
local infoCol = Color(135, 206, 250)
local talkCol = Color(255, 255, 100)
local radioCol = Color(55, 146, 21)
local pmCol = Color(45, 154, 6)

local oocCommand = {
    description = "Talk out of character globally.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        if impulse.OOCClosed then
            return client:Notify("OOC chat has been suspsended and will return shortly.")    
        end

        local timeout = impulse.OOCTimeouts[client:SteamID64()]
        if timeout then
            return client:Notify("You have an active OOC timeout that will remain for "..string.NiceTime(timeout - CurTime())..".")
        end

        client.OOCLimit = client.OOCLimit or ((client:IsDonator() and impulse.Config.OOCLimitVIP) or impulse.Config.OOCLimit)
        local timeLeft = timer.TimeLeft(client:UserID().."impulseOOCLimit")

        if client.OOCLimit < 1 and !client:IsAdmin() then
            return client:Notify("You have ran out of OOC messages. Wait "..string.NiceTime(timeLeft).." for more.")
        end

        for v, k in player.Iterator() do
            k:SendChatClassMessage(2, rawText, client)
        end

        client.OOCLimit = client.OOCLimit - 1

        net.Start("impulseUpdateOOCLimit")
        net.WriteUInt(timeLeft, 16)
        net.WriteBool(false)
        net.Send(client)

        hook.Run("ProcessOOCMessage", rawText)
    end
}

impulse.RegisterChatCommand("/ooc", oocCommand)
impulse.RegisterChatCommand("//", oocCommand)

local loocCommand = {
    description = "Talk out of character locally.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        if client.hasOOCTimeout then
            return client:Notify("You have an active OOC timeout that will remain for "..string.NiceTime(client.hasOOCTimeout - CurTime())..".")
        end

        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.TalkDistance ^ 2) then 
                k:SendChatClassMessage(3, rawText, client)
            end
        end

        hook.Run("ProcessOOCMessage", rawText)
    end
}

impulse.RegisterChatCommand("/looc", loocCommand)
impulse.RegisterChatCommand("//.", loocCommand)

local pmCommand = {
    description = "Directly messages the player specified.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        local name = arg[1]
        local message = string.sub(rawText, (string.len(name) + 2))
        message = string.Trim(message)

        if not message or message == "" then
            return client:Notify("Invalid argument.")
        end

        local plyTarget = impulse.Util:FindPlayer(name)

        if plyTarget and client != plyTarget then
            plyTarget:SendChatClassMessage(4, message, client)
            plyTarget.PMReply = client

            client:SendChatClassMessage(5, message, client)
        else
            return client:Notify("Could not find player: "..tostring(name))
        end
    end
}

impulse.RegisterChatCommand("/pm", pmCommand)

local replyCommand = {
    description = "Replies to the last player who directly messaged you.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        local message = rawText

        if not message or message == "" then
            return client:Notify("Invalid argument.")
        end

        if not client.PMReply or not IsValid(client.PMReply) then
            return client:Notify("Target not found.")
        end

        local plyTarget = client.PMReply

        if plyTarget and client != plyTarget then
            plyTarget:SendChatClassMessage(4, message, client)
            plyTarget.PMReply = client

            client:SendChatClassMessage(5, message, client)
        end
    end
}

impulse.RegisterChatCommand("/reply", replyCommand)

local yellCommand = {
    description = "Yell in character.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        rawText = hook.Run("ChatClassMessageSend", 6, rawText, client) or rawText

        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.YellDistance ^ 2) then 
                k:SendChatClassMessage(6, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/y", yellCommand)

local whisperCommand = {
    description = "Whisper in character.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        rawText = hook.Run("ChatClassMessageSend", 7, rawText, client) or rawText

        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.WhisperDistance ^ 2) then 
                k:SendChatClassMessage(7, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/w", whisperCommand)

local radioCommand = {
    description = "Send a radio message to all units.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        rawText = hook.Run("ChatClassMessageSend", 8, rawText, client) or rawText

        if client:IsCP() then
            for v, k in player.Iterator() do
                if k:IsCP() then 
                    k:SendChatClassMessage(8, rawText, client)
                end
            end
        else
            hook.Run("RadioMessageFallback", client, rawText)
        end
    end
}

impulse.RegisterChatCommand("/radio", radioCommand)
impulse.RegisterChatCommand("/r", radioCommand)

local meCommand = {
    description = "Preform an action in character.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.TalkDistance ^ 2) then 
                k:SendChatClassMessage(9, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/me", meCommand)

local itCommand = {
    description = "Perform an action from a third party.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.TalkDistance ^ 2) then 
                k:SendChatClassMessage(10, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/it", itCommand)

local advertCommand = {
    description = "Broadcasts the advert provided.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        if not impulse.Teams.Stored[client:Team()].canAdvert or impulse.Teams.Stored[client:Team()].canAdvert == false then 
            return client:Notify("Your team cannot make an advert.") 
        end

        if client:GetRelay("arrested", false) then
            return client:Notify("You cannot make an advert while arrested.")
        end


        timer.Simple(15, function()
            if IsValid(client) and client:IsPlayer() then
                for v, k in player.Iterator() do
                    k:SendChatClassMessage(12, rawText, client)
                end
            end
        end)

        client:Notify("Your advert has been sent and will be broadcast shortly.")
    end
}

impulse.RegisterChatCommand("/advert", advertCommand)

local rollCommand = {
    description = "Generate a random number between 0 and 100.",
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        local rollResult = (tostring(math.random(1,100)))

        for v, k in player.Iterator() do
            if (client:GetPos() - k:GetPos()):LengthSqr() <= (impulse.Config.TalkDistance ^ 2) then 
                k:SendChatClassMessage(11, rollResult, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/roll", rollCommand)

local dropMoneyCommand = {
    description = "Drops the specified amount of money on the floor.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, arg, rawText)
        if arg[1] and tonumber(arg[1]) then
            local value = math.floor(tonumber(arg[1]))
            if client:CanAfford(value) and value > 0 then
                client:TakeMoney(value)

                local trace = {}
                trace.start = client:EyePos()
                trace.endpos = trace.start + client:GetAimVector() * 85
                trace.filter = client

                local tr = util.TraceLine(trace)
                local note = impulse.Currency:SpawnMoney(tr.HitPos, value, client)

                client.DroppedMoneyC = math.Clamp((client.DroppedMoneyC and client.DroppedMoneyC + 1) or 1, 0, impulse.Config.DroppedMoneyLimit)
                client.DroppedMoney = client.DroppedMoney or {}
                client.DroppedMoneyCA = (client.DroppedMoneyCA and client.DroppedMoneyCA + 1) or 1

                client.DroppedMoney[client.DroppedMoneyCA] = note
                note.DropKey = client.DroppedMoneyCA

                if client.DroppedMoneyC == impulse.Config.DroppedMoneyLimit then
                    for v, k in pairs(client.DroppedMoney) do
                        if k and IsValid(k) then
                            k:Remove()
                            break
                        end
                    end
                end

                hook.Run("PlayerDropMoney", client, note)
                client:Notify("You have dropped "..impulse.Config.CurrencyPrefix..value..".")
            else
                return client:Notify("You cannot afford to drop that amount of money.")
            end
        else
            return client:Notify("Invalid argument.")
        end
    end
}

impulse.RegisterChatCommand("/dropmoney", dropMoneyCommand)

local writeCommand = {
    description = "Writes a letter with the text specified.",
    requiresArg = true,
    requiresAlive = true,
    onRun = function(client, args, text)
        if client.letterCount and client.letterCount > impulse.Config.MaxLetters then
            client:Notify("You have reached the max amount of letters.")
            return
        end

        if string.len(text) > 900 then
            client:Notify("Letter max character limit reached. (900)")
            return
        end

        text = impulse.Util:SafeString(text)

        local trace = {}
        trace.start = client:EyePos()
        trace.endpos = trace.start + client:GetAimVector() * 85
        trace.filter = client

        local tr = util.TraceLine(trace)

        local letter = ents.Create("impulse_letter")
        letter:SetPos(tr.HitPos)
        letter:SetText(text)
        letter:SetPlayerOwner(client)
        letter:Spawn()

        undo.Create("letter")
        undo.AddEntity(letter)
        undo.SetPlayer(client)
        undo.Finish()
    end
}

impulse.RegisterChatCommand("/write", writeCommand)

local searchCommand = {
    description = "Searches a players inventory.",
    requiresArg = false,
    requiresAlive = true,
    onRun = function(client, args, text)
        if not client:IsCP() then return end
        if client.impulseInventorySearching and IsValid(client.impulseInventorySearching) then return end

        local trace = {}
        trace.start = client:EyePos()
        trace.endpos = trace.start + client:GetAimVector() * 50
        trace.filter = client

        local tr = util.TraceLine(trace)
        local targ = tr.Entity

        if targ and IsValid(targ) and targ:IsPlayer() and targ:OnGround() then
            if not targ.impulseBeenInventorySetup then return end

            if not client:CanArrest(targ) then
                return client:Notify("You cannot search this player.")
            end

            if not targ:GetRelay("arrested", false) then
                return client:Notify("You must detain a player before searching them.")
            end

            targ:Freeze(true)
            targ:Notify("You are currently being searched.")
            client:Notify("You have started searching "..targ:Nick()..".")
            client.impulseInventorySearching = targ
            hook.Run("DoInventorySearch", client, targ)

            local inv = targ:GetInventory(1)
            net.Start("impulseInvDoSearch")
            net.WriteUInt(targ:EntIndex(), 8)
            net.WriteUInt(table.Count(inv), 16)
            for v, k in pairs(inv) do
                local netid = impulse.Inventory:ClassToNetID(k.class)
                net.WriteUInt(netid, 10)
            end
            net.Send(client)
        else
            client:Notify("No player in search range.")
        end
    end
}

impulse.RegisterChatCommand("/invsearch", searchCommand)

local eventCommand = {
    description = "Sends a global chat message to all players. Only for use in events.",
    leadAdminOnly = true,
    requiresArg = true,
    onRun = function(client, arg, rawText)
        if client:GetUserGroup() == "leadadmin" then return end
        
        for v, k in player.Iterator() do
            k:SendChatClassMessage(14, rawText, client)
        end
    end
}

impulse.RegisterChatCommand("/event", eventCommand)

local groupChatCommand = {
    description = "Sends a message to members of your group.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        local group = client:GetRelay("groupName", nil)

        if not group then
            return client:Notify("You must be in a group to use this command.")
        end

        if client:IsCP() then
            return client:Notify("You can not use this command as this team.")
        end

        if not client:GroupHasPermission(2) then
            return client:Notify("Your group rank does not have permission to do this.")
        end

        for v, k in player.Iterator() do
            if k:GetRelay("groupName", "") == group and !k:IsCP() then
                k:SendChatClassMessage(15, rawText, client)
            end
        end
    end
}

impulse.RegisterChatCommand("/group", groupChatCommand)
impulse.RegisterChatCommand("/g", groupChatCommand)

if ( CLIENT ) then
    local talkCol = Color(255, 255, 100)
    local infoCol = Color(135, 206, 250)
    local oocCol = color_white
    local oocTagCol = Color(200, 0, 0)
    local yellCol = Color(255, 140, 0)
    local whisperCol = Color(65, 105, 225)
    local infoCol = Color(135, 206, 250)
    local talkCol = Color(255, 255, 100)
    local radioCol = Color(65, 120, 200)
    local pmCol = Color(45, 154, 6)
    local advertCol = Color(255, 174, 66)
    local acCol = Color(0, 235, 0, 255)
    local eventCol = Color(255, 69, 0)
    local fallbackRankCol = Color(211, 211, 211)
    local groupCol = Color(148, 0, 211)
    local rankCols = impulse.Config.RankColours or {}

    impulse.RegisterChatClass(1, function(message, speaker)
        message = hook.Run("ProcessICChatMessage", speaker, message) or message

        chat.AddText(speaker, talkCol, " says: ", message)
    end)

    local strFind = string.find
    impulse.RegisterChatClass(2, function(message, speaker)
        if not impulse.Settings:Get("chat_oocenabled", true) then
            return print("(OOC DISABLED) [OOC] "..speaker:SteamName()..": "..message)
        end

        impulse.customChatPlayer = speaker

        if LocalPlayer and IsValid(LocalPlayer()) then
            local tag = "@"..LocalPlayer():SteamName()
            local findStart, findEnd = strFind(string.lower(message), string.lower(tag), 1, true)

            if findStart then
                local pre = string.sub(message, 1, findStart - 1)
                local post = string.sub(message, findEnd + 1)

                if impulse.Settings:Get("chat_pmpings") then
                    surface.PlaySound("buttons/blip1.wav")
                end

                chat.AddText(oocTagCol, "[OOC] ", (rankCols[speaker:IsIncognito() and "user" or speaker:GetUserGroup()] or fallbackRankCol), speaker:SteamName(), oocCol, ": ", pre, infoCol, tag, oocCol, post)
                return
            end
        end

        chat.AddText(oocTagCol, "[OOC] ", (rankCols[speaker:IsIncognito() and "user" or speaker:GetUserGroup()] or fallbackRankCol), speaker:SteamName(), oocCol, ": ", message)
    end)

    impulse.RegisterChatClass(3, function(message, speaker)
        impulse.customChatPlayer = speaker
        chat.AddText(oocTagCol, "[LOOC] ", (rankCols[speaker:IsIncognito() and "user" or speaker:GetUserGroup()] or fallbackRankCol), speaker:SteamName(), (team.GetColor(speaker:Team())), " (", speaker:Name(), ")", oocCol, ": ",  message)
    end)

    impulse.RegisterChatClass(4, function(message, speaker)
        if impulse.Settings:Get("chat_pmpings") then
            surface.PlaySound("buttons/blip1.wav")
        end
        
        chat.AddText(pmCol, "[PM] ", speaker:SteamName(), (team.GetColor(speaker:Team())), " (", speaker:Name(), ")", pmCol, ": ", message)
    end)

    impulse.RegisterChatClass(5, function(message, speaker)
        surface.PlaySound("buttons/blip1.wav")
        chat.AddText(pmCol, "[PM SENT] ", speaker:SteamName(), (team.GetColor(speaker:Team())), " (", speaker:Name(), ")", pmCol, ": ", message)
    end)

    impulse.RegisterChatClass(6, function(message, speaker)
        message = hook.Run("ProcessICChatMessage", speaker, message) or message

        impulse.customChatFont = "Impulse-ChatLarge"
        chat.AddText(speaker, yellCol, " yells: ", message)
    end)

    impulse.RegisterChatClass(7, function(message, speaker)
        message = hook.Run("ProcessICChatMessage", speaker, message) or message
        
        impulse.customChatFont = "Impulse-ChatSmall"
        chat.AddText(speaker, whisperCol, " whispers: ", message)
    end)

    impulse.RegisterChatClass(8, function(message, speaker)
        impulse.customChatFont = "Impulse-ChatRadio" 
        chat.AddText(radioCol, "[RADIO] ", speaker:Name(), ": ", message)
    end)

    impulse.RegisterChatClass(9, function(message, speaker)
        chat.AddText(talkCol, speaker:KnownName(), " ", message)
    end)

    impulse.RegisterChatClass(10, function(message, speaker)
        chat.AddText(infoCol, "** ", message)
    end)

    impulse.RegisterChatClass(11, function(message, speaker)
        chat.AddText(speaker, yellCol, " rolled ", message)
    end)

    impulse.RegisterChatClass(12, function(message, speaker)
        chat.AddText(advertCol, "[ADVERT] ", speaker:Name(), ": ", message)
    end)

    impulse.RegisterChatClass(13, function(message, speaker)
        chat.AddText(acCol, "[Admin Chat] ", speaker:SteamName(), ": ", acCol, message)
    end)

    impulse.RegisterChatClass(14, function(message, speaker)
        chat.AddText(eventCol, "[EVENT] ", message)
    end)

    impulse.RegisterChatClass(15, function(message, speaker)
        local groupName = LocalPlayer():GetRelay("groupName", nil)
        local groupRank = speaker:GetRelay("groupRank", nil)

        if not groupName or not groupRank then return end

        local myGroup = impulse.Group.Groups[1]

        if not myGroup then return end
        
        if myGroup.Color then
            chat.AddText(myGroup.Color, "["..groupName.."] ("..groupRank..") ", speaker:Nick(), ": ", message)
        else
            chat.AddText(groupCol, "["..groupName.."] ("..groupRank..") ", speaker:Nick(), ": ", message)
        end
    end)
end
