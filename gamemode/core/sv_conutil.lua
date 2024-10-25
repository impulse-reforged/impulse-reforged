local function IsSteamID(str)
	return string.match(str, "STEAM_%d:%d:%d+") or string.match(str, "7656119%d+")
end

concommand.Add("impulse_set_group", function(ply, cmd, args)
	if ply != NULL or IsValid(ply) then
		return
	end
	
	local find = args[1]
	if !find then
		MsgC(Color(255, 0, 0), "[impulse-reforged] No player target specified.\n")
		return
	end

	local group = args[2]
	if !group then
		MsgC(Color(255, 0, 0), "[impulse-reforged] No group specified.\n")
		return
	end

	local targ = impulse.Util:FindPlayer(find)
	if IsValid(targ) then
		targ:SetUserGroup(group)
		MsgC(Color(83, 143, 239), "[impulse-reforged] Set '" .. targ:SteamID() .. " (" .. targ:Name() .. ")' to group '" .. group .. "'.\n")

		local query = mysql:Update("impulse_players")
		query:Update("group", group)
		query:Where("steamid", targ:SteamID())
		query:Execute()

		return
	else
		MsgC(Color(255, 200, 0), "[impulse-reforged] Target not found, checking for SteamID...\n")
	end

	local steamid = IsSteamID(find)
	if !steamid then
		MsgC(Color(255, 0, 0), "[impulse-reforged] Target not found, and '" .. find .. "' is not a valid SteamID.\n")
		return
	end

	local query = mysql:Update("impulse_players")
	query:Update("group", group)
	query:Where("steamid", steamid)
	query:Execute()

	MsgC(Color(83, 143, 239), "[impulse-reforged] Set '" .. steamid .. "' to group '" .. group .. "'.\n")
end)