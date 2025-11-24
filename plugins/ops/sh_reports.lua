local reportCommand = {
    description = "Sends (or updates) a report to the game moderators.",
    requiresArg = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ReportNew(client, arg, rawText)
    end
}

impulse.RegisterChatCommand("/report", reportCommand)

local claimReportCommand = {
    description = "Claims a report for review.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ReportClaim(client, arg, rawText)
    end
}

impulse.RegisterChatCommand("/rc", claimReportCommand)

local closeReportCommand = {
    description = "Closes a report.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ReportClose(client, arg, rawText)
    end
}

impulse.RegisterChatCommand("/rcl", closeReportCommand)

local gotoReportCommand = {
    description = "Teleports yourself to the reportee of your claimed report.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ReportGoto(client, arg, rawText)
    end
}

impulse.RegisterChatCommand("/rgoto", gotoReportCommand)

local msgReportCommand = {
    description = "Messages the reporter of your claimed report.",
    adminOnly = true,
    onRun = function(client, arg, rawText)
        impulse.Ops.ReportMsg(client, arg, rawText)
    end
}

impulse.RegisterChatCommand("/rmsg", msgReportCommand)
