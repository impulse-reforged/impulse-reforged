# Team Whitelist Management Commands

This system provides comprehensive commands for managing team whitelists in impulse-reforged.

## Chat Commands (In-Game)

All chat commands require admin permissions. Use these in chat by typing the command.

### `/addwhitelist <player> <team> <level>`
**Aliases:** `/whitelist`

Adds or updates a whitelist for a player on a specific team.

**Arguments:**
- `<player>` - Player name or partial name
- `<team>` - Team name (partial match) or team ID number
- `<level>` - Whitelist level (1, 2, 3, etc.)

**Examples:**
```
/addwhitelist John "Security Division" 2
/addwhitelist John 5 2
/whitelist John security 1
```

---

### `/removewhitelist <player> <team>`
**Aliases:** `/delwhitelist`, `/unwhitelist`

Removes a player's whitelist for a specific team.

**Arguments:**
- `<player>` - Player name or partial name
- `<team>` - Team name (partial match) or team ID number

**Examples:**
```
/removewhitelist John "Security Division"
/unwhitelist John 5
/delwhitelist John security
```

---

### `/checkwhitelist <player> [team]`
**Aliases:** `/whitelistcheck`, `/wlcheck`

Checks a player's whitelist status. If no team is specified, shows all whitelists for that player.

**Arguments:**
- `<player>` - Player name or partial name
- `[team]` - (Optional) Team name or ID to check specific team

**Examples:**
```
/checkwhitelist John
/checkwhitelist John "Security Division"
/wlcheck John security
```

---

### `/listwhitelists <team>`
**Aliases:** `/whitelistlist`, `/wllist`

Lists all players who have whitelists for a specific team, including offline players.

**Arguments:**
- `<team>` - Team name (partial match) or team ID number

**Examples:**
```
/listwhitelists "Security Division"
/listwhitelists 5
/wllist security
```

---

### `/teaminfo <team>`
**Aliases:** `/teamsinfo`

Shows detailed information about a team including:
- Team ID and name
- XP requirements
- All ranks with their requirements and whitelist levels
- All classes with their requirements and whitelist levels

**Arguments:**
- `<team>` - Team name (partial match) or team ID number

**Examples:**
```
/teaminfo "Security Division"
/teaminfo 5
/teamsinfo security
```

---

## Console Commands (Server & Client Console)

These commands can be used in the server console or client console (requires admin).

### `impulse_whitelists_add <steamid64> <team> <level>`

Adds or updates a whitelist using SteamID64. Useful for offline players.

**Arguments:**
- `<steamid64>` - 17-digit SteamID64
- `<team>` - Team name (partial match) or team ID number
- `<level>` - Whitelist level (1, 2, 3, etc.)

**Examples:**
```
impulse_whitelists_add 76561198012345678 "Security Division" 2
impulse_whitelists_add 76561198012345678 5 2
impulse_whitelists_add 76561198012345678 security 1
```

---

### `impulse_whitelists_remove <steamid64> <team>`

Removes a whitelist using SteamID64.

**Arguments:**
- `<steamid64>` - 17-digit SteamID64
- `<team>` - Team name (partial match) or team ID number

**Examples:**
```
impulse_whitelists_remove 76561198012345678 "Security Division"
impulse_whitelists_remove 76561198012345678 5
impulse_whitelists_remove 76561198012345678 security
```

---

### `impulse_whitelists_list <team>`

Lists all whitelisted players for a team.

**Arguments:**
- `<team>` - Team name (partial match) or team ID number

**Examples:**
```
impulse_whitelists_list "Security Division"
impulse_whitelists_list 5
impulse_whitelists_list security
```

---

### `impulse_listteams`

Lists all available teams with their IDs and XP requirements. Useful for finding team IDs.

**Example:**
```
impulse_listteams
```

---

## Finding Team Names and IDs

### Method 1: Use `/teaminfo` or `impulse_listteams`
The easiest way to find team information:
```
impulse_listteams
```

### Method 2: Check Classes & Ranks Tab
Open the F4 menu and go to Information > Classes & Ranks to browse all teams.

### Method 3: Partial Matching
You don't need the full team name - partial matches work:
- "Security Division" can be: `security`, `sec`, `division`
- "Medical Division" can be: `medical`, `medic`, `med`
- "Research and Development" can be: `research`, `development`, `rd`

---

## Understanding Whitelist Levels

Whitelist levels control access to specific ranks or classes within a team:

- **Level 1** - Access to ranks/classes marked with `whitelistLevel = 1`
- **Level 2** - Access to Level 1 AND ranks/classes marked with `whitelistLevel = 2`
- **Level 3** - Access to Level 1, 2, AND ranks/classes marked with `whitelistLevel = 3`

Higher levels include all lower levels.

### Example: Security Division Ranks
```
1. Trainee (No whitelist needed)
2. Junior Security Officer (No whitelist needed)
3. Security Officer (No whitelist needed)
4. Senior Security Officer (No whitelist needed)
5. Security Sergeant (Whitelist Level 1)
6. Security Lieutenant (Whitelist Level 2)
7. Security Captain (Whitelist Level 3)
```

If you give a player Whitelist Level 2, they can play as:
- All ranks with no whitelist requirement (1-4)
- Sergeant (Level 1)
- Lieutenant (Level 2)
- But NOT Captain (requires Level 3)

---

## Tips

1. **Use Tab Completion**: When typing player names in commands, you can use partial names
2. **Team IDs**: Team IDs are faster to type than full names: `/addwhitelist John 5 2`
3. **Check First**: Use `/checkwhitelist` before removing to verify what level they have
4. **Bulk Operations**: For multiple whitelists, use the console commands in a script
5. **Offline Players**: Use console commands with SteamID64 for players who are offline

---

## Troubleshooting

### "Invalid team" error
- Make sure you're using a valid team name or ID
- Try using `impulse_listteams` to see available teams
- Check spelling or try a partial match

### "Could not find player" error
- Player must be online for chat commands
- Use console commands with SteamID64 for offline players
- Check spelling of player name

### Player still can't access rank/class
1. Check they have the correct XP: Use `/teaminfo <team>` to see requirements
2. Verify whitelist level: Use `/checkwhitelist <player> <team>`
3. Make sure the rank/class requires the whitelist level you gave them
4. Try removing and re-adding the whitelist

---

## Admin Logging

All whitelist operations are logged to Lead Admins (super admins) in their chat, including:
- Who performed the action
- What action was performed
- Target player and their SteamID64
- Team and whitelist level

This helps maintain accountability and audit trails.
