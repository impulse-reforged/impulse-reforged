--[[--
  Data management functions for impulse.
  @module impulse.Data
]]

impulse.Data = impulse.Data or {}

--- Returns all custom data stored in a player.
-- @realm server
-- @treturn table The player's data
function meta:GetData()
	return self.impulseData or {}
end

--- Saves any possible modifications to the player's data.
-- @realm server
-- @usage ply:SaveData()
function meta:SaveData()
	hook.Run("PrePlayerSaveData", self)

	local query = mysql:Update("impulse_players")
	query:Update("data", util.TableToJSON(self.impulseData))
	query:Where("steamid", self:SteamID())
	query:Execute()

	hook.Run("PostPlayerSaveData", self)
end

--- Sets a key in the player's data table, which can be used to store custom data like Combine Taglines or something similar.
-- @realm server
-- @string key The key to set
-- @param value The value to set
-- @bool[opt=false] bAutoSave Whether to automatically save the player's data after setting the key
-- @usage ply:SetData("combine_tagline", "GRID")
function meta:SetData(key, value, bAutoSave)
	self.impulseData = self.impulseData or {}
	self.impulseData[key] = value

	if ( bAutoSave ) then
		self:SaveData()
	end
end

--- Completely wipes the key from the player's data table.
-- @realm server
-- @string key The key to remove
-- @bool[opt=false] bAutoSave Whether to automatically save the player's data after removing the key
-- @usage ply:RemoveData("combine_tagline")
function meta:RemoveData(key, bAutoSave)
	self.impulseData = self.impulseData or {}
	self.impulseData[key] = nil

	if ( bAutoSave ) then
		self:SaveData()
	end
end

--- Writes data to the impulse_data table, which can be used to store arbitrary data such as global money or other persistent data.
-- @realm server
-- @string name The name of the data to write
-- @param data The data to write
-- @usage impulse.Data:Write("combine_stockpile", {ammo = 100, weapons = 5})
function impulse.Data:Write(name, data)
	hook.Run("PreDataWrite", name, data)

	local query = mysql:Select("impulse_data")
	query:Select("id")
	query:Where("name", name)
	query:Callback(function(result) -- somewhat annoying that we cant do a conditional query or smthing but whatever
		if ( type(result) == "table" and #result > 0 ) then
			local followUp = mysql:Update("impulse_data")
			followUp:Update("data", pon.encode(data))
			followUp:Where("name", name)
			followUp:Execute()
		else
			local followUp = mysql:Insert("impulse_data")
			followUp:Insert("name", name)
			followUp:Insert("data", pon.encode(data))
			followUp:Execute()
		end

		hook.Run("PostDataWrite", name, data)
	end)

	query:Execute()
end

--- Removes data from the impulse_data table.
-- @realm server
-- @string name The name of the data to remove
-- @int[opt] limit The maximum number of rows to remove
-- @usage impulse.Data:Remove("combine_stockpile")
function impulse.Data:Remove(name, limit)
	hook.Run("PreDataRemove", name, limit)

	local query = mysql:Delete("impulse_data")
	query:Where("name", name)

	if ( limit ) then
		query:Limit(limit)
	end

	query:Execute()

	hook.Run("PostDataRemove", name, limit)
end

--- Reads data from the impulse_data table.
-- @realm server
-- @string name The name of the data to read
-- @func onDone The function to call when the data has been read
-- @func[opt] fallback The function to call if the data does not exist
-- @usage print(impulse.Data:Read("combine_stockpile"))
-- > {ammo = 100, weapons = 5}
function impulse.Data:Read(name, onDone, fallback)
	local query = mysql:Select("impulse_data")
	query:Select("data")
	query:Where("name", name)
	query:Callback(function(result)
		if ( type(result) == "table" and #result > 0 ) then
			onDone(pon.decode(result[1].data))
		elseif ( fallback ) then
			fallback()
		end
	end)

	query:Execute()
end