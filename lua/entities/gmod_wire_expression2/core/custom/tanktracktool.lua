E2Lib.RegisterExtension( "tanktracktool", true, "Allows E2 chips to create and manipulate tanktracktool entities" )

local E2Lib, WireLib, math = E2Lib, WireLib, math

registerCallback( "construct", function( self )
    self.data.tanktracks = {}
end )

registerCallback( "destruct", function( self )
    for ent, mode in pairs( self.data.tanktracks ) do
        if ent then ent:Remove() end
    end
end )

local function makeEntity( self, class, keep, pos, ang, model )
    if not gamemode.Call( "PlayerSpawnSENT", self.player, class ) then
        return NULL
    end

    local ent = ents.Create( class )
    if not IsValid( ent ) then
        return NULL
    end

    if not util.IsValidModel( model ) then model = "models/hunter/plates/plate.mdl" end

    ent:SetModel( model )
    ent:SetPos( WireLib.clampPos( pos ) )
    ent:SetAngles( ang )
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
        phys:Wake()
    end

    if not keep then
        self.data.tanktracks[ent] = true

        ent:CallOnRemove( "tanktracktool_e2_onremove", function( e )
            self.data.spawnedProps[e] = nil
        end )

        ent.DoNotDuplicate = true
    else
        undo.Create( class )
            undo.SetPlayer( self.player )
            undo.AddEntity( ent )
        undo.Finish()
    end

    self.player:AddCleanup( "sents", ent )
    self.player:AddCount( class, ent )

    return ent
end

__e2setcost( 100 )

local validClasses = {
    sent_tanktracks_auto = true,
    sent_tanktracks_legacy = true,
    sent_point_beam = true,
    sent_susp_shock_coil = true,
    sent_susp_macpherson_strut = true,
}

local isOwner = E2Lib.isOwner
local canEdit = tanktracktool.netvar.canEdit
local canLink = tanktracktool.netvar.canLink
local setVar = tanktracktool.netvar.setVar

e2function entity tanktracktoolCreate( number keep, string class, string model, vector pos, angle ang )
    local class = string.lower( class )
    local model = string.lower( model )
    if not validClasses[class] then return end
    return makeEntity( self, class, keep ~= 0, pos, Angle( ang[1], ang[2], ang[3] ), model )
end

__e2setcost( 50 )
e2function void entity:tanktracktoolResetValues()
    if not isOwner( self, this ) then self:throw( "You do not own this entity!", nil ) end
    if not canEdit( this, self.player ) then self:throw( "You cannot edit this entity!", nil ) end

    local entindex = this.netvar.entindex
    local entities = this.netvar.entities

    this:netvar_install()

    this.netvar.entindex = entindex
    this.netvar.entities = entities
end

e2function void entity:tanktracktoolCopyValues( entity other )
    if not isOwner( self, this ) or not isOwner( self, other ) then self:throw( "You do not own this entity!", nil ) end
    if not canEdit( this, self.player ) or not canEdit( other, self.player ) then self:throw( "You cannot edit this entity!", nil ) end
    if this:GetClass() ~= other:GetClass() then self:throw( "Entities must be the same class!", nil ) end
    this:netvar_copy( self.player, other )
end

__e2setcost( 10 )
e2function void entity:tanktracktoolSetValue( string key, ... )
    if not isOwner( self, this ) then self:throw( "You do not own this entity!", nil ) end
    if not canEdit( this, self.player ) then self:throw( "You cannot edit this entity!", nil ) end
    if not this.netvar.variables:get( key ) then self:throw( string.format( "Variable '%s' doesn't exist on entity!", key ), nil ) end

    local count = select( "#", ... )

    if count == 0 then self:throw( "You must provide a value!", nil ) end

    if count == 1 then
        local value = unpack( { ... } )
        setVar( this, key, nil, value, true )
        return
    end

    if count == 2 then
        local index, value = unpack( { ... } )
        if not isnumber( index ) then self:throw( "You must provide an index!", nil ) end
        setVar( this, key, index, value, true )
        return
    end
end

--[[
    hardcoded but easiest
]]
local quicklink = {}

quicklink.sent_tanktracks_legacy = {
    get = function()
        return { "Chassis (entity)", "Wheel (array)", "Roller (array)" }
    end,
    set = function( self, this, E2Table )
        if not E2Table.s.Chassis or not isentity( E2Table.s.Chassis ) then
            self:throw( "Links table must contain an entity with key 'Chassis'!", nil )
            return
        end
        if not E2Table.s.Wheel or E2Table.stypes.Wheel ~= "r" then
            self:throw( "Links table must contain an array with key 'Wheel'!", nil )
            return
        end
        if not E2Table.s.Roller or E2Table.stypes.Roller ~= "r" then
            self:throw( "Links table must contain an array with key 'Roller'!", nil )
            return
        end

        local t = { Chassis = E2Table.s.Chassis, Wheel = {}, Roller = {} }

        for k, v in SortedPairs( E2Table.s.Wheel ) do
            if not isentity( v ) then
                self:throw( "'Wheel' array must contain entities only!", nil )
                return
            else
                table.insert( t.Wheel, v )
            end
        end
        for k, v in SortedPairs( E2Table.s.Roller ) do
            if not isentity( v ) then
                self:throw( "'Roller' array must contain entities only!", nil )
                return
            else
                table.insert( t.Roller, v )
            end
        end

        return this:netvar_setLinks( t, self.player )
    end
}

quicklink.sent_point_beam = {
    get = function()
        return { "Entity1 (entity)", "Entity2 (entity)" }
    end,
    set = function( self, this, E2Table )
        if not E2Table.s.Entity1 or not isentity( E2Table.s.Entity1 ) then
            self:throw( "Links table must contain an entity with key 'Entity1'!", nil )
            return
        end
        if not E2Table.s.Entity2 or not isentity( E2Table.s.Entity2 ) then
            self:throw( "Links table must contain an entity with key 'Entity2'!", nil )
            return
        end
        return this:netvar_setLinks( { Entity1 = E2Table.s.Entity1, Entity2 = E2Table.s.Entity2 }, self.player )
    end
}

quicklink.sent_susp_shock_coil = {
    get = function()
        return { "Entity1 (entity)", "Entity2 (entity)" }
    end,
    set = function( self, this, E2Table )
        if not E2Table.s.Entity1 or not isentity( E2Table.s.Entity1 ) then
            self:throw( "Links table must contain an entity with key 'Entity1'!", nil )
            return
        end
        if not E2Table.s.Entity2 or not isentity( E2Table.s.Entity2 ) then
            self:throw( "Links table must contain an entity with key 'Entity2'!", nil )
            return
        end
        return this:netvar_setLinks( { Entity1 = E2Table.s.Entity1, Entity2 = E2Table.s.Entity2 }, self.player )
    end
}

quicklink.sent_susp_macpherson_strut = {
    get = function()
        return { "Chassis (entity)", "LeftWheel (entity)", "RightWheel (entity)" }
    end,
    set = function( self, this, E2Table )
        if not E2Table.s.Chassis or not isentity( E2Table.s.Chassis ) then
            self:throw( "Links table must contain an entity with key 'Chassis'!", nil )
            return
        end
        if not E2Table.s.LeftWheel or not isentity( E2Table.s.LeftWheel ) then
            self:throw( "Links table must contain an entity with key 'LeftWheel'!", nil )
            return
        end
        if not E2Table.s.RightWheel or not isentity( E2Table.s.RightWheel ) then
            self:throw( "Links table must contain an entity with key 'RightWheel'!", nil )
            return
        end
        return this:netvar_setLinks( { Chassis = E2Table.s.Chassis, LeftWheel = E2Table.s.LeftWheel, RightWheel = E2Table.s.RightWheel }, self.player )
    end
}

__e2setcost( 100 )
e2function void entity:tanktracktoolSetLinks( table links )
    if not isOwner( self, this ) then self:throw( "You do not own this entity!", nil ) end
    if not canEdit( this, self.player ) or not this.netvar_setLinks then self:throw( "You cannot link this entity!", nil ) end
    local class = this:GetClass()
    if not quicklink[class] then self:throw( "You cannot link this entity!", nil ) end
    quicklink[class].set( self, this, links )
end

__e2setcost( 10 )
e2function array entity:tanktracktoolGetLinkNames()
    if not this.netvar_setLinks then self:throw( "You cannot link this entity!", nil ) end
    local class = this:GetClass()
    if not quicklink[class] then self:throw( "You cannot link this entity!", nil ) end
    return quicklink[class].get( this )
end
