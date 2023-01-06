
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

util.AddNetworkString( "tanktracktool_legacy_sync" )

function ENT:SpawnFunction( ply, tr, ClassName )
    if not tr.Hit then
        return
    end

    local model = ply:GetInfo( "tanktracktool_model" )
    if not util.IsValidModel( model ) then model = "models/hunter/plates/plate.mdl" end

    local ent = ents.Create( ClassName )
    ent:SetModel( model )
    ent:SetPos( tr.HitPos + tr.HitNormal * 40 )
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
        phys:Wake()
    end

    return ent
end

function ENT:Initialize()
    self.BaseClass.Initialize( self )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
end

function ENT:SetControllerLinks( tbl )
    if not istable( tbl ) then tbl = {} end

    self.ttdata_links = tbl
    self.SyncLinks = true

    local links = {}
    for k, v in pairs( tbl ) do
        if IsValid( v ) then table.insert( links, v:EntIndex() ) end
    end

    duplicator.StoreEntityModifier( self, "tanktracktool", { links = links } )
end

function ENT:PostEntityPaste( ply, ent, other )
    local dupe = ent.EntityMods
    if not dupe then
        ent:SetControllerLinks()
        return
    end

    local links

    if dupe.tanktracktool then
        links = dupe.tanktracktool.links
    elseif dupe.ttc_dupe_info then
        links = dupe.ttc_dupe_info.link_ents
        duplicator.ClearEntityModifier( self, "ttc_dupe_info" )
    end

    if not links then
        ent:SetControllerLinks()
    else
        local ret = {}
        for i, id in pairs( links ) do
            ret[i] = other[id]
        end
        ent:SetControllerLinks( ret )
    end
end

function ENT:Think()
    self.BaseClass.Think( self )
    if self.SyncLinks then
        if self.ttdata_links then
            net.Start( "tanktracktool_legacy_sync" )
            net.WriteUInt( self:EntIndex(), 32 )
            net.WriteTable( self.ttdata_links )
            if istable( self.SyncLinks ) then net.Send( self.SyncLinks ) else net.Broadcast() end
        end
        self.SyncLinks = nil
    end
end

net.Receive( "tanktracktool_legacy_sync", function( len, ply )
    if not IsValid( ply ) then return end

    local ent = Entity( net.ReadUInt( 32 ) )
    if not IsValid( ent ) or ent:GetClass() ~= "sent_tanktracks_legacy" then return end

    if not ent.SyncLinks then ent.SyncLinks = {} end
    if istable( ent.SyncLinks ) then
        table.insert( ent.SyncLinks, ply )
    end
end )


-- LEGACY COMPAT
local files_legacy = {
    track_sheridan = true,
    track_kingtiger = true,
    track_kv = true,
    track_t80 = true,
    track_generic = true,
    track_t64 = true,
    track_t90 = true,
    track_tiger = true,
    track_panzer4 = true,
    track_t62 = true,
    track_m1 = true,
    track_m60a1 = true,
    track_bmp = true,
    track_panther = true,
    track_leopard1 = true,
    track_t55 = true,
    track_m4a1 = true,
    track_m4 = true,
    track_m4a3e8 = true,
    track_t54 = true,
    track_t34 = true,
    track_t30 = true,
    track_maus = true,
    track_amx30 = true,
    track_chieftain = true,
    track_leopard2 = true,
    track_t72 = true,
    track_type90 = true,
    track_amx13 = true,
    track_m2bradley = true,
}

local files_legacy_uber = {
    track1 = "legacy_track1",
    track3 = "legacy_track3",
    track4 = "legacy_track4",
    track5 = "legacy_track5",
    track7 = "legacy_track7",
    bmp3_track = "bmp",
    t30_track = "t30",
    t62_track = "t62",
    t80_track = "t90",
    chieftain_track = "chieftain",
    elcamx_track = "amx_elc",
    kv_track = "kv",
    m1a1_track = "m1a1",
    track_m1a1 = "m1a1",
    m4a3_track = "m4a3e8",
    panzer4_track = "panzer4",
    sheridan_track = "sheridan",
}

local function GetMaterial( name )
    if not isstring( name ) then return "generic" end

    name = string.lower( name )

    if files_legacy[name] then
        return string.gsub( name, "track_", "" )
    end

    return files_legacy_uber[name] or "generic"
end

duplicator.RegisterEntityClass( "gmod_ent_ttc", function( ply, data )
    local ent = ents.Create( "sent_tanktracks_legacy" )

    duplicator.DoGeneric( ent, data )

    ent:Spawn()
    ent:Activate()

    local legacy = data.DT
    if legacy then
        local update = false --not game.SinglePlayer()

        local color = isvector( legacy.TTC_Color ) and legacy.TTC_Color or Vector( 1, 1, 1 )
        ent:SetValueNME( update, "trackColor", nil, string.format( "%d %d %d 255", color.x * 255, color.y * 255, color.z * 255 ) )
        ent:SetValueNME( update, "trackMaterial", nil, GetMaterial( legacy.TTC_Material ) )

        ent:SetValueNME( update, "trackTension", nil, legacy.TTC_Tension )

        ent:SetValueNME( update, "trackWidth", nil, legacy.TTC_Width )
        ent:SetValueNME( update, "trackOffsetY", nil, legacy.TTC_Offset )
        ent:SetValueNME( update, "wheelSprocket", nil, legacy.TTC_Sprocket or 1 )

        ent:SetValueNME( update, "wheelRadius", nil, legacy.TTC_Radius )
        ent:SetValueNME( update, "rollerRadius", nil, legacy.TTC_RollerRadius )

        local height = ( legacy.TTC_Height or 3 ) * 0.5 + 0.5
        ent:SetValueNME( update, "trackHeight", nil, height )

        local offset = legacy.TTC_Radius or 0
        ent:SetValueNME( update, "wheelRadius", nil, offset - height * 0.5 )

        local offset = legacy.TTC_RollerRadius or 0
        ent:SetValueNME( update, "rollerRadius", nil, offset - height * 0.5 )
    end

    ply:AddCount( "sent_tanktracks_legacy", ent )
    ply:AddCleanup( "sent_tanktracks_legacy", ent )

    return ent
end, "Data" )
