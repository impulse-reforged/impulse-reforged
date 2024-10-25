--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Entity")

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