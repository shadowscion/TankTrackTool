
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

function ENT:netvar_nme( data )
    return data
end


--[[
    legacy... this is for ttc
]]
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
        local color = isvector( legacy.TTC_Color ) and legacy.TTC_Color or Vector( 1, 1, 1 )
        ent:netvar_set( "trackColor", nil, string.format( "%d %d %d 255", color.x * 255, color.y * 255, color.z * 255 ) )
        ent:netvar_set( "trackMaterial", nil, GetMaterial( legacy.TTC_Material ) )

        ent:netvar_set( "trackTension", nil, legacy.TTC_Tension )

        ent:netvar_set( "trackWidth", nil, legacy.TTC_Width )
        ent:netvar_set( "trackOffsetY", nil, legacy.TTC_Offset )
        ent:netvar_set( "wheelSprocket", nil, legacy.TTC_Sprocket or 1 )

        ent:netvar_set( "wheelRadius", nil, legacy.TTC_Radius )
        ent:netvar_set( "rollerRadius", nil, legacy.TTC_RollerRadius )

        local height = ( legacy.TTC_Height or 3 ) * 0.5 + 0.5
        ent:netvar_set( "trackHeight", nil, height )

        local offset = legacy.TTC_Radius or 0
        ent:netvar_set( "wheelRadius", nil, offset - height * 0.5 )

        local offset = legacy.TTC_RollerRadius or 0
        ent:netvar_set( "rollerRadius", nil, offset - height * 0.5 )
    end

    ply:AddCount( "sent_tanktracks_legacy", ent )
    ply:AddCleanup( "sent_tanktracks_legacy", ent )

    return ent
end, "Data" )
