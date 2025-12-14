
--[[--
Relationship Management System for Garry's Mod NPCs.

This module implements a team-based relationship management system for Garry's Mod NPCs,
enabling developers to assign unique dispositions (friend/foe status) between NPCs and players based on team.
The system automatically manages NPC relationships by tracking specific events, such as player team changes, 
player spawns, deaths, and NPC creation.<br/>
<br/>
### Setting Up Relationships for Each Team
Each team's relationship configuration is defined directly within the team's file, using the `relationships` table.
This table specifies how each NPC class should interact with players of the team. 
Relationships use the following disposition values:<br/>
`D_HT`: Hostile (NPC will attack the player)<br/>
`D_LI`: Friendly (NPC will not attack the player and might assist)<br/>
`D_FR`: Fear (NPC will flee from the player)<br/>
`D_NU`: Neutral (NPC will ignore the player)<br/>
<br/>
### Example of a team definition with relationships
<pre><code>TEAM_CITIZEN = impulse.Teams:Register({
    name = "Citizen",
    color = Color(20, 150, 20, 255),
    description = \[\[The lowest class of Combine society.\]\],
    loadout = {"impulse_hands", "weapon_physgun", "gmod_tool"},
    salary = 100,
    xp = 0,
    police = false,
    relationships = {
        ["npc_combine_s"] = D_HT, -- Combine soldiers are hostile to citizens
        ["npc_citizen"] = D_LI -- Citizens are friendly to each other
    }
})</code></pre>
<br/>
### Events That Trigger Relationship Updates
The system automatically updates NPC-player relationships based on specific game events:<br/>
**NPC Creation**: When a new NPC is created, the system initializes its relationships with players based on the players' teams.<br/>
**Player Spawn**: When a player spawns, their team's relationship settings are applied to relevant NPCs in the world.<br/>
**Player Death**: Upon a player's death, the system neutralizes all NPC relationships with the player to prevent hostility during respawn.<br/>
**Player Team Change**: When a player switches teams, their relationships with NPCs are updated based on the new team's `relationships` table.<br/>
<br/>
### Automatic Initialization
When the server starts, the system automatically initializes relationships for all existing NPCs by applying each player's team relationships to them. 
This ensures consistency even if NPCs or players were present before the system was loaded.
<br/>
<br/>
### Dispositions
The system uses `npc:AddEntityRelationship(client, disposition, priority)` to set dispositions, where:
- `disposition` is the NPC's attitude toward the player (e.g., hostile, friendly).
- `priority` is set to `99` to prioritize these relationships.
<br/>
<br/>
### Adding or Modifying Teams
To create a new team with specific relationships, define a new team as shown in the example above, including a `relationships` table.
Changes to relationships are automatically recognized by the system once the team is defined with `impulse.Teams:Register`.
<br/>
<br/>
### Dependencies<br/>
This system depends on the `impulse.Teams` registration system and requires teams to be registered with `impulse.Teams:Register`.
Relationships will be read from each team's `relationships` table, and thus, each team should have its relationships 
defined if specific NPC interactions are desired.
<br/>
<br/>
### Example Workflow<br/>
**Step 1** Define relationships within each team file using the `relationships` table.<br/>
**Step 2** Start or restart the server to load team definitions and apply relationships.<br/>
**Step 3** Relationships between NPCs and players will automatically update based on events (spawns, deaths, team changes).<br/>
<br/>
This system provides flexibility for defining complex NPC interactions based on teams, 
and allows for easy management of these relationships without manual updating during gameplay.
<br/>
<br/>
### Notes
- Use `D_LI` for friendly NPCs, `D_HT` for hostile NPCs, `D_FR` for NPCs that fear the player, and `D_NU` for neutral behavior.<br/>
- Remember to use `impulse.Relationships:ApplyTeamRelationships` and `impulse.Relationships:InitNPCRelationships` if manually creating or updating NPCs outside of the automated hooks provided.<br/>
]]
-- @module impulse.Relationships

impulse.Relationships = impulse.Relationships or {}

--- Applies relationships for a player's team to relevant NPCs.
-- Looks up the player's team configuration to find relationship dispositions 
-- and applies these to matching NPCs in the world.
-- @realm server
-- @param client The player whose team relationships should be applied
function impulse.Relationships:ApplyTeamRelationships(client)
    local teamData = impulse.Teams:FindTeam(client:Team())
    if ( !teamData or !teamData.relationships ) then return end

    for npcClass, disposition in pairs(teamData.relationships) do
        for _, npc in ipairs(ents.FindByClass(npcClass)) do
            npc:AddEntityRelationship(client, disposition, 0)
        end
    end
end

--- Initializes relationships for a newly created NPC.
-- For each player, it checks the player's team configuration and applies 
-- any defined relationships to the NPC if it matches the team's dispositions.
-- @realm server
-- @param npc The NPC entity to initialize relationships for
function impulse.Relationships:InitNPCRelationships(npc)
    for _, client in player.Iterator() do
        local teamData = impulse.Teams:FindTeam(client:Team())
        if ( teamData and teamData.relationships ) then
            local disposition = teamData.relationships[npc:GetClass()]
            if ( disposition ) then
                npc:AddEntityRelationship(client, disposition, 0)
            end
        end
    end
end

--- Retrieves the default disposition for an NPC toward a player.
-- Looks up the player's team configuration to find the default relationship disposition
-- for the NPC class. If no disposition is found, returns `nil`.
-- @realm server
-- @param npc The NPC entity
-- @param client The player entity
function impulse.Relationships:GetTeamDisposition(npc, client)
    local teamData = impulse.Teams:FindTeam(client:Team())
    if ( !teamData or !teamData.relationships ) then return end

    local disposition = teamData.relationships[npc:GetClass()]
    if ( disposition ) then
        return disposition
    end
end

hook.Add("OnEntityCreated", "impulse.Relationships.OnEntityCreated", function(ent)
    if ( ent:IsNPC() ) then
        impulse.Relationships:InitNPCRelationships(ent)
    end
end)

hook.Add("OnPlayerChangedTeam", "impulse.Relationships.OnPlayerChangedTeam", function(client, oldTeam, newTeam)
    impulse.Relationships:ApplyTeamRelationships(client)
end)

hook.Add("PlayerSpawn", "impulse.Relationships.PlayerSpawn", function(client)
    impulse.Relationships:ApplyTeamRelationships(client)
end)

hook.Add("PlayerDeath", "impulse.Relationships.PlayerDeath", function(client)
    for _, npc in ents.Iterator() do
        if ( !IsValid(npc) or !npc:IsNPC() ) then continue end

        npc:AddEntityRelationship(client, D_LI, 0)
    end
end)

hook.Add("PostInitPostEntity", "impulse.Relationships.PostInitPostEntity", function()
    for _, npc in ents.Iterator() do
        if ( !IsValid(npc) or !npc:IsNPC() ) then continue end

        impulse.Relationships:InitNPCRelationships(npc)
    end
end)
