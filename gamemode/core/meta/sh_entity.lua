--[[--
Physical object in the game world.

Entities are physical representations of objects in the game world. impulse extends the functionality of entities to interface
between impulse's own classes, and to reduce boilerplate code.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Entity) for all other methods that the `Player` class has.
]]
-- @classmod Entity

local ENTITY = FindMetaTable("Entity")

local modelCache = {}
function ENTITY:IsFemale(modelov)
    if ( self:IsPlayer() and hook.Run("PlayerIsFemale", self) ) then return true end

    local model = modelov or self:GetModel()
    if ( modelCache[model] ) then
        return modelCache[model]
    end

    local isFemale = string.find(self:GetModel(), "female")
    if ( isFemale ) then
        modelCache[model] = true
        return true
    end

    modelCache[model] = false

    return false
end

local propDoors = {
    ["models/props_doors/doorklab01.mdl"] = true,
    ["models/props_lab/elevatordoor.mdl"] = true,
    ["models/props_combine/combine_door01.mdl"] = true,
    ["models/combine_gate_vehicle.mdl"] = true,
    ["models/combine_gate_citizen.mdl"] = true
}

--- Returns if the entity is a door
-- @realm shared
-- @treturn bool Is door
function ENTITY:IsDoor()
    return self:GetClass():find("door")
end

--- Helper function that can detect if the door is a players prop door
-- @realm shared
-- @treturn bool Is player prop door
function ENTITY:IsPropDoor()
    if not IsValid(self) then return end

    if not self.GetModel or not propDoors[self:GetModel()] then return false end

    if (self:CPPIGetOwner() and IsValid(self:CPPIGetOwner())) and self:CPPIGetOwner():IsPlayer() then return true end

    if (self:CPPIGetOwner() and IsValid(self:CPPIGetOwner())) and self:CPPIGetOwner() == Entity(0) then
        if ( SERVER ) then
            if self:MapCreationID() == -1 then
                return true
            else
                return false
            end
        end

        return true
    end

    return false
end

--- Returns if entity is a button
-- @realm shared
-- @treturn bool Is button
function ENTITY:IsButton()
    return (self:GetClass():find("button") or self:GetClass() == ("class C_BaseEntity"))
end

--- Returns if a door is locked
-- @realm shared
-- @treturn bool Is locked
function ENTITY:IsDoorLocked()
    return self:GetSaveTable().m_bLocked
end

local chairs = {}

for k, v in pairs(list.Get("Vehicles")) do
    if v.Category == "Chairs" then
        chairs[v.Model] = true
    end
end

--- Returns if a entity is a chair
-- @realm shared
-- @treturn bool Is chair
function ENTITY:IsChair()
    return chairs[self.GetModel(self)]
end

--- Returns if a entity can be carried
-- @realm shared
-- @treturn bool Can be carried
function ENTITY:CanBeCarried()
    local phys = self:GetPhysicsObject()

    if not IsValid(phys) then return false end

    if phys:GetMass() > 100 or not phys:IsMoveable() then return false end

    return true
end

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0 and "" or ""

--- Emits queued sounds on an entity one by one
-- @realm shared
-- @param sounds A table of all the sounds
-- @int[opt=0] delay The delay between each sound
-- @int[opt=0.1] spacing The spacing between each sound
-- @int[opt=1] volume The volume of each sound
-- @int[opt=100] pitch The pitch of each sound
-- @treturn int How long it will take to emit all the sounds
function ENTITY:EmitQueuedSounds(sounds, delay, spacing, volume, pitch)
    delay = delay or 0
    spacing = spacing or 0.1

    for k, v in ipairs(sounds) do
        local postSet, preSet = 0, 0

        if (type(v) == "table") then
            postSet, preSet = v[2] or 0, v[3] or 0
            v = v[1]
        end

        local length = SoundDuration(ADJUST_SOUND..v)
        delay = delay + preSet

        timer.Simple(delay, function()
            if (IsValid(self)) then
                self:EmitSound(v, volume, pitch)
            end
        end)

        delay = delay + length + postSet + spacing
    end

    return delay
end

if ( SERVER ) then
    util.AddNetworkString("impulseBudgetSound")
    util.AddNetworkString("impulseBudgetSoundExtra")

    --- Emits a that is only networked to nearby players
    -- @realm server
    -- @string sound Sound path
    -- @int[opt=660] range Radius in Source units to network the sound to
    -- @int[opt=1] level Sound level of the sound
    -- @int[opt=100] pitch Pitch of the sound
    function ENTITY:EmitBudgetSound(sound, range, level, pitch)
        local range = range or 600
        local pos = self:GetPos()
        local entIndex = self:EntIndex()
        local range = range ^ 2

        local recipFilter = RecipientFilter()

        for v, k in player.Iterator() do
            if k:GetPos():DistToSqr(pos) < range then
                recipFilter:AddPlayer(k)
            end
        end

        if level or pitch then
            net.Start("impulseBudgetSoundExtra")
            net.WriteUInt(entIndex, 16)
            net.WriteString(sound)
            net.WriteUInt(level or 0, 8)
            net.WriteUInt(pitch or 0, 8)
        else
            net.Start("impulseBudgetSound")
            net.WriteUInt(entIndex, 16)
            net.WriteString(sound)
        end

        net.Send(recipFilter)
    end
end


if (SERVER) then
    --- Returns the neighbouring door entity for double doors.
    -- @realm shared
    -- @treturn[1] Entity This door's partner
    -- @treturn[2] nil If the door does not have a partner
    function ENTITY:GetDoorPartner()
        return self.impulsePartner
    end

    --- Returns the entity that is blocking this door from opening.
    -- @realm server
    -- @treturn[1] Entity Entity that is blocking this door
    -- @treturn[2] nil If this entity is not a door, or there is no blocking entity
    function ENTITY:GetBlocker()
        local datatable = self:GetSaveTable()

        return datatable.pBlocker
    end

    --- Blasts a door off its hinges. Internally, this hides the door entity, spawns a physics prop with the same model, and
    -- applies force to the prop.
    -- @realm server
    -- @vector velocity Velocity to apply to the door
    -- @number lifeTime How long to wait in seconds before the door is put back on its hinges
    -- @bool bIgnorePartner Whether or not to ignore the door's partner in the case of double doors
    -- @treturn[1] Entity The physics prop created for the door
    -- @treturn nil If the entity is not a door
    function ENTITY:BlastDoor(velocity, lifeTime, bIgnorePartner)
        if ( !self:IsDoor() ) then return end

        if ( IsValid(self.impulseDummy) ) then
            self.impulseDummy:Remove()
        end

        velocity = velocity or VectorRand() * 128
        lifeTime = lifeTime or 120

        local partner = self:GetDoorPartner()
        if ( IsValid(partner) and !bIgnorePartner ) then
            partner:BlastDoor(velocity, lifeTime, true)
        end

        local color = self:GetColor()

        local dummy = ents.Create("prop_physics")
        dummy:SetModel(self:GetModel())
        dummy:SetPos(self:GetPos())
        dummy:SetAngles(self:GetAngles())
        dummy:Spawn()
        dummy:SetColor(color)
        dummy:SetMaterial(self:GetMaterial())
        dummy:SetSkin(self:GetSkin() or 0)
        dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
        dummy:CallOnRemove("restoreDoor", function()
            if ( IsValid(self) ) then
                self:SetNotSolid(false)
                self:SetNoDraw(false)
                self:DrawShadow(true)
                self.ignoreUse = false
                self.impulseIsMuted = false

                for _, v in ents.Iterator() do
                    if ( v:GetParent() == self ) then
                        v:SetNotSolid(false)
                        v:SetNoDraw(false)

                        if ( v.OnDoorRestored ) then
                            v:OnDoorRestored(self)
                        end
                    end
                end
            end
        end)
        dummy:SetOwner(self)
        dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        self:Fire("unlock")
        self:Fire("open")
        self:SetNotSolid(true)
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self.ignoreUse = true
        self.impulseDummy = dummy
        self.impulseIsMuted = true
        self:DeleteOnRemove(dummy)

        for _, v in ipairs(self:GetBodyGroups() or {}) do
            dummy:SetBodygroup(v.id, self:GetBodygroup(v.id))
        end

        for _, v in ents.Iterator() do
            if ( v:GetParent() == self ) then
                v:SetNotSolid(true)
                v:SetNoDraw(true)

                if ( v.OnDoorBlasted ) then
                    v:OnDoorBlasted(self)
                end
            end
        end

        dummy:GetPhysicsObject():SetVelocity(velocity)

        local uniqueID = "doorRestore"..self:EntIndex()
        local uniqueID2 = "doorOpener"..self:EntIndex()

        timer.Create(uniqueID2, 1, 0, function()
            if ( IsValid(self) and IsValid(self.impulseDummy) ) then
                self:Fire("open")
            else
                timer.Remove(uniqueID2)
            end
        end)

        timer.Create(uniqueID, lifeTime, 1, function()
            if ( IsValid(self) and IsValid(dummy) ) then
                uniqueID = "dummyFade" .. dummy:EntIndex()
                local alpha = 255

                timer.Create(uniqueID, 0.1, 255, function()
                    if ( IsValid(dummy) ) then
                        alpha = alpha - 1
                        dummy:SetColor(ColorAlpha(color, alpha))

                        if ( alpha <= 0 ) then
                            dummy:Remove()
                        end
                    else
                        timer.Remove(uniqueID)
                    end
                end)
            end
        end)

        return dummy
    end

else
    -- Returns the door's slave entity.
    function ENTITY:GetDoorPartner()
        local owner = self:GetOwner() or self.impulseDoorOwner
        if ( IsValid(owner) and owner:IsDoor() ) then
            return owner
        end

        for _, v in ipairs(ents.FindByClass("prop_door_rotating")) do
            if ( v:GetOwner() == self ) then
                self.impulseDoorOwner = v

                return v
            end
        end
    end
end
