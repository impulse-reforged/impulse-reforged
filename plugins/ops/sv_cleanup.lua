impulse.Ops = impulse.Ops or {}

function impulse.Ops.CleanupPlayer(ply)
	for v, k in ents.Iterator() do
		local owner = k:CPPIGetOwner()

		if owner == ply then
			if not k.IsBuyable then
				k:Remove()
			end
		end
	end
end

function impulse.Ops.CleanupAll()
	for v, k in ents.Iterator() do
		local owner = k:CPPIGetOwner()

		if owner and !k.IsBuyable then
			k:Remove()
		end
	end
end

function impulse.Ops.ClearDecals()
	for v, k in player.Iterator() do
		k:ConCommand("r_cleardecals")
	end
end