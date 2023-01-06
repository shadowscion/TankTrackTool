
local math, file, string, render, tonumber, Vector, Angle =
      math, file, string, render, tonumber, Vector, Angle

local pi = math.pi
local deg2rad = pi / 180
local rad2deg = 180 / pi

function tttlib.toLocalAng( pos, ang, l )
    local p, a = WorldToLocal( _zvec, l, pos, ang )
    return a
end

function tttlib.toWorldAng( pos, ang, l )
    local p, a = LocalToWorld( _zvec, l, pos, ang )
    return a
end

function tttlib.toLocalAxis( pos, ang, axis )
    local p, a = WorldToLocal( axis + pos, _zang, pos, ang )
    return p
end

function tttlib.toWorldAxis( pos, ang, axis )
    local p, a = LocalToWorld( axis, _zang, pos, ang )
    p:Add( pos )
    return p
end

function tttlib.bearing( pos, ang, tar )
    local p = WorldToLocal( tar, _zang, pos, ang )
    return math.deg( -math.atan2( p.y, p.x ) )
end

function tttlib.getNetEntity( key, self )
    local e = self:GetNW2Entity( key, self )
    return IsValid( e ) and e or self
end

function tttlib.getRGBM( c )
    if type( c ) == string then c = string.ToColor( c ) end
    return { r = c.r / 255, g = c.g / 255, b = c.b / 255, a = c.a / 255 }
end

function tttlib.sin( a )
    return math.sin( a * deg2rad )
end

function tttlib.atan( a, b )
    return math.atan2( a, b ) * rad2deg
end

function tttlib.acos( a )
    return math.acos( a ) * rad2deg
end

local acos = tttlib.acos

function tttlib.icos( a, b, c )
    return acos( ( a^2 + b^2 - c^2 )  /  ( 2 * a * b ) )
end

function tttlib.lerp( a, b, t )
    return a + ( b - a ) * t
end

function tttlib.map( x, in_min, in_max, out_min, out_max )
    return ( x - in_min ) * ( out_max - out_min ) / ( in_max - in_min ) + out_min
end

function tttlib.calcbounds( min, max, pos )
    if pos.x < min.x then min.x = pos.x elseif pos.x > max.x then max.x = pos.x end
    if pos.y < min.y then min.y = pos.y elseif pos.y > max.y then max.y = pos.y end
    if pos.z < min.z then min.z = pos.z elseif pos.z > max.z then max.z = pos.z end
end


local modelcheck = {}
local modelblacklist = {
    ["models/lubprops/seat/raceseat2.mdl"] = true,
    ["models/lubprops/seat/raceseat.mdl"] = true,
 }
local modeldummy = "models/hunter/blocks/cube025x025x025.mdl"

local materialcheck = {}
local materialblacklist = {
    ["engine/writez"] = true,
    ["pp/copy"] = true,
    ["effects/ar2_altfire1"] = true
 }

local submaterialscheck = {}

local function IsValidMaterial( material )
    -- already checked, is bad, return nothing
    if material == nil or materialcheck[material] == false then
        return

    -- not checked yet
    elseif materialcheck[material] == nil then
        if material == "" then
            materialcheck[material] = true
            return material
        end

        -- check if blacklisted
        if materialblacklist[material] then
            materialcheck[material] = false
            return nil
        end

        -- check for errors
        local m = Material( material )
        if m:IsError() then
            materialcheck[material] = false
            return nil
        end

        -- all good
        materialcheck[material] = true

    end

    return material
end
tttlib.isValidMaterial = IsValidMaterial

local function IsValidModel( model )
    -- already checked, is bad, return nothing
    if model == nil or modelcheck[model] == false then
        return modeldummy

    -- not checked yet
    elseif modelcheck[model] == nil then

        -- check if blacklisted
        if modelblacklist[model] or IsUselessModel( model ) then
            modelcheck[model] = false
            return modeldummy
        end

        -- check for errors
        if not file.Exists( model, "GAME" ) then
            modelcheck[model] = false
            return modeldummy
        end

        -- all good
        modelcheck[model] = true

    end

    return model
end
tttlib.isValidModel = IsValidModel

function tttlib.fixWheel( csent, model, bodygroups, materials, radius, width )
    model = IsValidModel( model )

    csent:SetModel( model )
    csent:DisableMatrix( "RenderMultiply" )
    csent:SetupBones()

    local submaterials = {}
    if next( materials ) == nil or materials[1] then
        submaterials.base = IsValidMaterial( materials[1] ) or ""
    else
        if not submaterialscheck[model] then
            submaterialscheck[model] = csent:GetMaterials()
        end
        for id in pairs( submaterialscheck[model] ) do
            submaterials[id] = IsValidMaterial( materials[id + 1] ) or ""
        end
    end

    -- HitBoxBounds is the only function I could find that returns the correct min, max
    -- of models that have bodygroups that extend past the model's obb bounding box
    -- but it also gives ( incorrectly ) rotated vectors on some models
    local hmin, hmax, hbb = csent:GetHitBoxBounds( 0, 0 )
    if hmin and hmax then
        hbb = hmax -  hmin
    end
    local obb = csent:OBBMaxs() - csent:OBBMins()
    local scale, rotate

    -- scale vector has to have the length of hbb but component order of obb
    -- hack below should cover all cases
    if obb.y < obb.x and obb.y < obb.z then
        if hbb then
            if hbb.y < hbb.x and hbb.y < hbb.z then
            else
                obb.x = hbb.y
                obb.y = hbb.x
                obb.z = hbb.z
            end
        end
        scale = Vector( radius * 2 / obb.x, width / obb.y, radius * 2 / obb.z )
    elseif obb.x < obb.y and obb.x < obb.z then
        if hbb then
            obb.x = hbb.y
            obb.y = hbb.x
            obb.z = hbb.z
        end
        scale = Vector( width / obb.x, radius * 2 / obb.y, radius * 2 / obb.z )
        rotate = Angle( 0, 90, 0 )
    else
        scale = Vector( radius * 2 / obb.x, width / obb.y, radius * 2 / obb.z )
    end

    local m = Matrix()
    if rotate then
        m:Rotate( rotate )
    end
    m:SetScale( scale )

    local bodygroup = string.rep( "0", csent:GetNumBodyGroups() )
    for char = 1, #bodygroup do
        local isnum = tonumber( bodygroups[char] )
        if isnum then
            bodygroup = string.format( "%s%s%s", string.sub( bodygroup, 1, char - 1 ), isnum, string.sub( bodygroup, char + 1 ) )
        end
    end

    return model, bodygroup, submaterials, m, scale, Vector( -radius, -width * 0.5, -radius ), Vector( radius, width * 0.5, radius )
end
