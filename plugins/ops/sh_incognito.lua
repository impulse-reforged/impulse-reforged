local PLAYER = FindMetaTable("Player")

function PLAYER:IsIncognito()
    return self:GetNetVar("incognito", false)
end

local incognitoCommand = {
    description = "Toggles incognito mode. DO NOT USE FOR LONG PERIODS.",
    requiresArg = false,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        ply:SetNetVar("incognito", !ply:IsIncognito())

        if ply:IsIncognito() then
            ply:Notify("You have entered incognito mode. Please go back to normal mode as soon as you can.")
        else
            ply:Notify("You have exited incognito mode.")
        end
    end
}

impulse.RegisterChatCommand("/incognitotoggle", incognitoCommand)