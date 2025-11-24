local managerCommand = {
    description = "Opens the staff manager tool.",
    leadAdminOnly = true,
    onRun = function(client)
        impulse.Ops.SM.Open(client)
    end
}

impulse.RegisterChatCommand("/staffmanager", managerCommand)
