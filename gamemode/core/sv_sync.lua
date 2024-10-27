--[[--
Physical object in the game world.

Entities are physical representations of objects in the game world. Helix extends the functionality of entities to interface
between Helix's own classes, and to reduce boilerplate code.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Entity) for all other methods that the `Player` class has.
]]
-- @classmod Entity

util.AddNetworkString("impulseSyncUpdate")
util.AddNetworkString("impulseSyncUpdatepdateClient")
util.AddNetworkString("impulseSyncRemove")
util.AddNetworkString("impulseSyncRemoveVar")

local ENTITY = FindMetaTable("Entity")

--- Sync's all SyncVar's on an entity with all clients or a single target if provided.
-- @realm server
-- @param[opt] target Player to sync with
-- @usage ent:Sync() -- syncs all SyncVar's with all players
-- @usage ent:Sync(ply) -- syncs all SyncVar's with a single player
function ENTITY:Sync(target)
	local targetID = self:EntIndex()
	local syncUser = impulse.Sync.Data[targetID]

	for varID, syncData in pairs(syncUser) do
		local value = syncData[1]
		local syncRealm = syncData[2]
		local syncType = impulse.Sync.Vars[varID]
		local syncCondition = impulse.Sync.VarsConditional[varID]

		if target and syncCondition and !syncCondition(target) then return end
		
		if syncRealm == SYNC_TYPE_PUBLIC then
			if target then
				if value == nil then
					net.Start("impulseSyncRemoveVar")
						net.WriteUInt(targetID, 16)
						net.WriteUInt(varID, SYNC_ID_BITS)
					net.Send(target)
				else
					net.Start("impulseSyncUpdate")
						net.WriteUInt(targetID, 16)
						net.WriteUInt(varID, SYNC_ID_BITS)
						impulse.Sync:DoType(syncType, value)
					net.Send(target)
				end
			else
				local recipFilter = RecipientFilter()

				if syncCondition then
					for v, k in player.Iterator() do
						if syncCondition(k) then
							recipFilter:AddPlayer(k)
						end
					end
				else
					recipFilter:AddAllPlayers()
				end

				if value == nil then
					net.Start("impulseSyncRemoveVar")
						net.WriteUInt(targetID, 16)
						net.WriteUInt(varID, SYNC_ID_BITS)
					net.Send(recipFilter)
				else
					net.Start("impulseSyncUpdate")
						net.WriteUInt(targetID, 16)
						net.WriteUInt(varID, SYNC_ID_BITS)
						impulse.Sync:DoType(syncType, value)
					net.Send(recipFilter)
				end
			end
		elseif target and target:IsPlayer() and target:EntIndex() == targetID then
			if value == nil then
				net.Start("impulseSyncRemoveVar")
					net.WriteUInt(targetID, 16)
					net.WriteUInt(varID, SYNC_ID_BITS)
				net.Send(target)
			else
				net.Start("impulseSyncUpdatepdateClient")
					net.WriteUInt(targetID, 8)
					net.WriteUInt(varID, SYNC_ID_BITS)
					impulse.Sync:DoType(syncType, value)
				net.Send(target)
			end
		end
	end
end

--- Sync's a single SyncVar on an entity with all clients or a single target if provided.
-- @realm server
-- @int varID Sync variable
-- @param[opt] target Player to sync with
-- @usage ent:SyncSingle(SYNC_MONEY) -- syncs the money SyncVar with all players
-- @usage ent:SyncSingle(SYNC_MONEY, ply) -- syncs the money SyncVar with a single player
function ENTITY:SyncSingle(varID, target)
	local targetID = self:EntIndex()
	local syncUser = impulse.Sync.Data[targetID]
	local syncData = syncUser[varID]
	local value = syncData[1]
	local syncRealm = syncData[2]
	local syncType = impulse.Sync.Vars[varID]
	local syncCondition = impulse.Sync.VarsConditional[varID]

	if target and syncCondition and !syncCondition(target) then return end

	if syncRealm == SYNC_TYPE_PUBLIC then
		if target then
			if value == nil then
				net.Start("impulseSyncRemoveVar")
					net.WriteUInt(targetID, 16)
					net.WriteUInt(varID, SYNC_ID_BITS)
				net.Send(target)
			else
				net.Start("impulseSyncUpdate")
					net.WriteUInt(targetID, 16)
					net.WriteUInt(varID, SYNC_ID_BITS)
					impulse.Sync:DoType(syncType, value)
				net.Send(target)
			end
		else
			local recipFilter = RecipientFilter()

			if syncCondition then
				for v, k in player.Iterator() do
					if syncCondition(k) then
						recipFilter:AddPlayer(k)
					end
				end
			else
				recipFilter:AddAllPlayers()
			end

			if value == nil then
				net.Start("impulseSyncRemoveVar")
					net.WriteUInt(targetID, 16)
					net.WriteUInt(varID, SYNC_ID_BITS)
				net.Send(recipFilter)
			else
				net.Start("impulseSyncUpdate")
					net.WriteUInt(targetID, 16)
					net.WriteUInt(varID, SYNC_ID_BITS)
					impulse.Sync:DoType(syncType, value)
				net.Send(recipFilter)
			end
		end
	elseif target and target:IsPlayer() and target:EntIndex() == targetID then
		if value == nil then
			net.Start("impulseSyncRemoveVar")
				net.WriteUInt(targetID, 16)
				net.WriteUInt(varID, SYNC_ID_BITS)
			net.Send(target)
		else
			net.Start("impulseSyncUpdatepdateClient")
				net.WriteUInt(targetID, 8)
				net.WriteUInt(varID, SYNC_ID_BITS)
				impulse.Sync:DoType(syncType, value)
			net.Send(target)
		end
	end
end

--- Removes all SyncVar's from an entity and update all players
-- @realm server
-- @usage ent:SyncRemove() -- removes all SyncVar's from the entity and updates all players
function ENTITY:SyncRemove()
	local targetID = self:EntIndex()

	impulse.Sync.Data[targetID] = nil

	net.Start("impulseSyncRemove")
		net.WriteUInt(targetID, 16)
	net.Broadcast()	
end

--- Removes a specific SyncVar from an entity and update all players
-- @realm server
-- @int varID Sync variable
function ENTITY:SyncRemoveVar(varID)
	local targetID = self:EntIndex()

	impulse.Sync.Data[targetID][varID] = nil

	net.Start("impulseSyncRemoveVar")
		net.WriteUInt(targetID, 16)
		net.WriteUInt(varID, SYNC_ID_BITS)
	net.Broadcast()	
end

--- Sets a Sync var on an entity
-- @realm server
-- @int varID Sync variable (EG: SYNC_MONEY)
-- @param newValue Value to set
-- @bool[opt=false] instantSync If we should network this to all players
-- @usage ply:SetSyncVar(SYNC_XP, 60, true) -- sets money to 60 and networks the new value to all players
function ENTITY:SetSyncVar(varID, newValue, instantSync)
	local targetID = self:EntIndex()
	local targetData = impulse.Sync.Data[targetID]

	if not targetData then
		impulse.Sync.Data[targetID] = {}
		targetData = impulse.Sync.Data[targetID]
	elseif targetData[varID] and (type(newValue) != "table" and targetData[varID][1] == newValue) then return end

	targetData[varID] = {newValue, SYNC_TYPE_PUBLIC}

	if instantSync then
		self:SyncSingle(varID)
	end
end

--- Gets the Sync variable on an entity
-- @realm shared
-- @int varID Sync variable (EG: SYNC_MONEY)
-- @param fallback If we don't know the value we will fallback to this value
-- @return value
-- @usage print(ply:GetSyncVar(SYNC_XP, 0)) -- Print the player's XP, fallback to 0 if it's nil
-- > 75
function ENTITY:GetSyncVar(varID, fallback)
	local targetData = impulse.Sync.Data[self.EntIndex(self)]

	if targetData != nil then
		if targetData[varID] != nil then
			return targetData[varID][1]
		end
	end
	return fallback
end

local ENTITY = FindMetaTable("Player")

-- @classmod Player

--- Sets a local Sync var on a player
-- @realm server
-- @int varID Sync variable (EG: SYNC_MONEY)
-- @param newValue Value to set
-- @usage ply:SetLocalSyncVar(SYNC_BANKMONEY, 600)
function ENTITY:SetLocalSyncVar(varID, newValue)
	local targetID = self:EntIndex()
	local targetData = impulse.Sync.Data[targetID]
	targetData[varID] = {newValue, SYNC_TYPE_PRIVATE}

	self:SyncSingle(varID, self)
end