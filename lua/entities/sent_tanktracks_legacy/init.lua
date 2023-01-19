
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

function ENT:netvar_nme( data )
    return data
end


--[[
    sort wheels based on forward position
    separated by a table of wheels and a table of roller wheels
]]
local function GetSortedWheels( chassis, wheels, rollers, rotate )
    local matrix = chassis:GetWorldTransformMatrix()
    if rotate then matrix:Rotate( rotate ) end
    local pos = matrix:GetTranslation() + matrix:GetForward() * 12345
    local tbl = {}

    for k, ent in pairs( wheels ) do
        if not isentity( ent ) then ent = k end
        if isentity( ent ) and IsValid( ent ) then
            table.insert( tbl, ent )
            ent.rollerTemp = nil
            ent.sortPosTemp = ent:GetPos():Distance( pos )
            if #tbl > 32 then break end
        end
    end

    for k, ent in pairs( rollers ) do
        if not isentity( ent ) then ent = k end
        if isentity( ent ) and IsValid( ent ) then
            table.insert( tbl, ent )
            ent.rollerTemp = true
            ent.sortPosTemp = ent:GetPos():Distance( pos )
            if #tbl > 32 then break end
        end
    end

    table.sort( tbl, function( e1, e2 )
        local this = e1.rollerTemp
        local that = e2.rollerTemp

        if this ~= that then return that and not this end
        if this then return e1.sortPosTemp > e2.sortPosTemp else return e1.sortPosTemp < e2.sortPosTemp end
    end )

    for k, ent in pairs( tbl ) do
        ent.rollerTemp = nil
        ent.sortPosTemp = nil
    end

    table.insert( tbl, 1, chassis )

    return tbl
end


--[[
    check if all ents are to one side of the chassis
    optional filter function
]]
local function Filter( ent )
    if not isentity( ent ) or not IsValid( ent ) or ent:IsPlayer() or ent:IsVehicle() or ent:IsNPC() or ent:IsWorld() then return true end
end

local function CheckParallelism( chassis, tbl, rotate, filter )
    local matrix = chassis:GetWorldTransformMatrix()
    if rotate then matrix:Rotate( rotate ) end
    local pos = matrix:GetTranslation()
    local dir = matrix:GetRight()
    local dot

    for k, ent in pairs( tbl ) do
        if filter and filter( ent ) then return "invalid wheel or chassis entity " .. tostring( ent ) end

        if ent ~= chassis then
            local d = dir:Dot( ( ent:GetPos() - pos ):GetNormalized() ) > 0
            if dot == nil then dot = d end
            if dot ~= d then
                return "wheels must all be on the same side of the chassis"
            end
        end
    end

    return false
end


--[[
    sort wheels before sending the table to netvar linking function
    prop protection is checked there
]]
function ENT:netvar_setLinks( tbl, ply )
    if not istable( tbl ) then
        return tanktracktool.netvar.setLinks( self, {}, ply )
    end

    local rotate = tobool( self.netvar.values.systemRotate ) and Angle( 0, -90, 0 )

    --if istable( tbl.Wheel ) and istable( tbl.Roller ) and isentity( tbl.Chassis ) then
    if isentity( tbl.Chassis ) then
        tbl.Wheel = tbl.Wheel or {}
        tbl.Roller = tbl.Roller or {}
        tbl = GetSortedWheels( tbl.Chassis, tbl.Wheel, tbl.Roller, rotate )
    end

    if istable( tbl ) and table.IsSequential( tbl ) then
        local isp = CheckParallelism( tbl[1], tbl, rotate, Filter )
        if isp then
            if IsValid( ply ) then ply:ChatPrint( isp ) end
            return
        end

        return tanktracktool.netvar.setLinks( self, tbl, ply )
    end
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
