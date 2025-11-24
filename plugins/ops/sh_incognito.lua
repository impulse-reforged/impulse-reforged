local PLAYER = FindMetaTable("Player")

function PLAYER:IsIncognito()
    return tobool(self:GetRelay("incognito", false))
end

local incognitoCommand = {
    description = "Toggles incognito mode. DO NOT USE FOR LONG PERIODS.",
    requiresArg = false,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        client:SetRelay("incognito", !client:IsIncognito())

        if client:IsIncognito() then
            client:Notify("You have entered incognito mode. Please go back to normal mode as soon as you can.")
        else
            client:Notify("You have exited incognito mode.")
        end
    end
}

impulse.RegisterChatCommand("/incognitotoggle", incognitoCommand)
