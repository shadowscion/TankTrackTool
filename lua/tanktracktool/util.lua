
tttlib.modes = {}

local math, file, string, render, tonumber, Vector, Angle =
      math, file, string, render, tonumber, Vector, Angle

local pi = math.pi
local deg2rad = pi / 180
local rad2deg = 180 / pi


--  MATH
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

function tttlib.renderbounds( self )
    local rendermin, rendermax = Vector( 0, 0, -self.NMEVals.suspensionZ ), Vector( 0, 0, self.NMEVals.suspensionZ )
    local renderpos, renderang = self:ttfunc_getmatrix()

    renderpos, renderang = WorldToLocal( self:GetPos(), self:GetAngles(), renderpos, renderang )
    tttlib.calcbounds( rendermin, rendermax, renderpos )

    for i = 1, #self.ttdata_parts do
        local wheel = self.ttdata_parts[i][1]
        tttlib.calcbounds( rendermin, rendermax, wheel[1] + wheel.maxs )
        if self.ttdata_isdouble then
            tttlib.calcbounds( rendermin, rendermax, wheel[2] + wheel.mins )
        end
    end

    self.rendermin = rendermin
    self.rendermax = rendermax
    self:SetRenderBounds( self.rendermin, self.rendermax )
end


--  PARTS AND COMPONENTS
local render_multiply = "RenderMultiply"

local function createcsents( self, ent )
    local csents = { wheel = true }

    for k, v in pairs( ent.ttdata_csents ) do
        if not self.csents[k] and IsValid( v ) then
            --print( "removing", k )
            v:Remove()
        end
    end

    for k, v in pairs( self.csents ) do
        if not IsValid( ent.ttdata_csents[k] ) then
            ent.ttdata_csents[k] = ents.CreateClientside( "base_anim" )
            --print( "creating", k )
        else
            --print( "exists", k )
        end
        ent.ttdata_csents[k].RenderGroup = RENDERGROUP_OPAQUE
        ent.ttdata_csents[k]:SetRenderMode( RENDERMODE_TRANSCOLOR )
        ent.ttdata_csents[k]:SetNoDraw( true )
        ent.ttdata_csents[k]:SetLOD( 0 )
        ent.ttdata_csents[k].model = nil
    end

    ent.ttdata_parts = {}
end

local function rendercomponent( self, ent, component, isdouble )
    local csent = component.csent

    if component.nodraw then
        if component.postrender then
            component:postrender( self, ent, isdouble )
        end

        return
    end

    if csent.model ~= component.model then
        csent.model = component.model
        csent:SetModel( component.model )
    end

    if component.bodygroup then
        csent:SetBodyGroups( component.bodygroup )
    else
        csent:SetBodyGroups( nil )
    end

    if component.setupscale then
        component:setupscale()
    else
        csent:EnableMatrix( render_multiply, component.scale )
    end

    if component.color then
        local c = component.color
        csent.RenderGroup = c.a ~= 255 and RENDERGROUP_BOTH or RENDERGROUP_OPAQUE
        render.SetBlend( c.a )
        render.SetColorModulation( c.r, c.g, c.b )
    else
        csent.RenderGroup = RENDERGROUP_OPAQUE
        render.SetBlend( 1 )
        render.SetColorModulation( 1, 1, 1 )
    end

    if component.material then
        csent:SetMaterial( component.material )
        csent:SetSubMaterial( nil )
    elseif component.submaterials then
        csent:SetMaterial( nil )
        for s = 1, #component.submaterials do
            csent:SetSubMaterial( s - 1, component.submaterials[s] )
        end
    else
        csent:SetMaterial( nil )
        csent:SetSubMaterial( nil )
    end

    csent:SetPos( component.le_posworld )
    csent:SetAngles( component.le_angworld )
    csent:SetupBones()
    csent:DrawModel()

    if isdouble then
        if component.setupscale_ri then
            component:setupscale_ri()
        end

        csent:SetPos( component.ri_posworld )
        csent:SetAngles( component.ri_angworld )
        csent:SetupBones()
        csent:DrawModel()
    end

    if component.postrender then
        component:postrender( self, ent, isdouble )
    end
end
tttlib.rendercomponent = rendercomponent

local function rendercsents( self, ent, isdouble )
    if self.prerender then self:prerender( ent ) end

    local parts = ent.ttdata_parts

    for i = 1, #parts do
        local components = parts[i]
        for j = 1, #components do
            rendercomponent( self, ent, components[j], isdouble )
        end
    end

    if self.postrender then self:postrender( ent ) end

    render.SetColorModulation( 1, 1, 1 )
    render.SetBlend( 1 )
end

local function addcomponent( self, csent )
    local component = {
        csent = csent,
        le_poslocal = Vector(),
        le_posworld = Vector(),
        le_anglocal = Angle(),
        le_angworld = Angle(),
        ri_poslocal = Vector(),
        ri_posworld = Vector(),
        ri_anglocal = Angle(),
        ri_angworld = Angle(),
        scale = Matrix(),
     }
    component.id = table.insert( self, component )
    return component
end

local function addpart( self, ent, i )
    local part = { addcomponent = addcomponent, id = i }
    ent.ttdata_parts[i] = part
    return part
end

function tttlib.mode( name )
    tttlib.modes[name] = { name = name, setup = function() end, think = function() end, addpart = addpart, render = rendercsents, createcsents = createcsents, csents = {} }
    return tttlib.modes[name]
end


--  MODEL AND MATERIAL CHECKS
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


--  SCALE FIXER
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

function tttlib.textureList()
    local ret = {}
    for k, v in SortedPairs( file.Find( string.format( "materials/%s/*.vtf", "tanktracktool/autotracks/" ), "GAME" ) ) do
        local name = string.StripExtension( string.GetFileFromFilename( v ) )
        ret[name] = k
    end
    return ret
end

