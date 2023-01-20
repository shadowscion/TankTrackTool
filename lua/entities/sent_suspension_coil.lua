
AddCSLuaFile()

DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category  = "tanktracktool"

local tanktracktool = tanktracktool

--[[
    wiremod & tool_link setup
]]
if CLIENT then
    tanktracktool.netvar.addToolLink( ENT, "Entity1", nil, nil )
    tanktracktool.netvar.addToolLink( ENT, "Entity2", nil, nil )
end

if SERVER then
    function ENT:netvar_setLinks( tbl, ply )
        if not istable( tbl ) then
            return tanktracktool.netvar.setLinks( self, {}, ply )
        end

        tbl = {
            Entity1 = isentity( tbl.Entity1 ) and tbl.Entity1 or nil,
            Entity2 = isentity( tbl.Entity2 ) and tbl.Entity2 or nil,
        }

        return tanktracktool.netvar.setLinks( self, tbl, ply )
    end

    function ENT:netvar_wireInputs()
        return { "Entity1 [ENTITY]", "Entity2 [ENTITY]", "Offset1 [VECTOR]", "Offset2 [VECTOR]" }
    end

    local function isnan( v ) return v.x ~= v.x or v.y ~= v.y or v.z ~= v.z end
    local function clamp( v ) return Vector( math.Clamp( v.x, -16384, 16384 ), math.Clamp( v.y, -16384, 16384 ), math.Clamp( v.z, -16384, 16384 ) ) end

    local inputs = {}
    inputs.Entity1 = function( self, ply, value )
        if ply and not tanktracktool.netvar.canLink( value, ply ) then value = nil end
        self:SetNW2Entity( "netwire_Entity1", value )
    end
    inputs.Entity2 = function( self, ply, value )
        if ply and not tanktracktool.netvar.canLink( value, ply ) then value = nil end
        self:SetNW2Entity( "netwire_Entity2", value )
    end
    inputs.Offset1 = function( self, ply, value )
        if not isvector( value ) or isnan( value ) then value = nil else value = clamp( value ) end
        self:SetNW2Vector( "netwire_Offset1", value )
    end
    inputs.Offset2 = function( self, ply, value )
        if not isvector( value ) or isnan( value ) then value = nil else value = clamp( value ) end
        self:SetNW2Vector( "netwire_Offset2", clamp( value ) )
    end

    function ENT:TriggerInput( name, value )
        if inputs[name] then inputs[name]( self, WireLib and WireLib.GetOwner( self ), value ) end
    end
end


--[[
    netvar setup
]]
local netvar = tanktracktool.netvar.new()

local default = {
}

function ENT:netvar_setup()
    return netvar, default
end


--[[
    CLIENT
]]
if SERVER then return end

local math, util, string, table, render =
      math, util, string, table, render

local next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector =
      next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector

local pi = math.pi


--[[
    editor callbacks
]]


--[[
    netvar hooks
]]
local hooks = {}

hooks.editor_open = function( self, editor )
    for k, cat in pairs( editor.Categories ) do
        cat:SetExpanded( true )
    end
end

hooks.netvar_set = function( self ) self.tanktracktool_reset = true end
hooks.netvar_syncLink = function( self ) self.tanktracktool_reset = true end
hooks.netvar_syncData = function( self ) self.tanktracktool_reset = true end

function ENT:netvar_callback( id, ... )
    if hooks[id] then hooks[id]( self, ... ) end
end

local function GetEntities( self )
    if not self.netvar.entities and ( self.netvar.entindex.Entity1 and self.netvar.entindex.Entity2 ) then
        local e1 = Entity( self.netvar.entindex.Entity1 )
        local e2 = Entity( self.netvar.entindex.Entity2 )

        if IsValid( e1 ) and IsValid( e2 ) then
            self.netvar.entities = { Entity1 = e1, Entity2 = e2 }
        end
    end

    local e1 = self:GetNW2Entity( "netwire_Entity1", nil )
    local e2 = self:GetNW2Entity( "netwire_Entity2", nil )

    if not IsValid( e1 ) then
        e1 = self.netvar.entities and IsValid( self.netvar.entities.Entity1 ) and self.netvar.entities.Entity1 or nil
    end
    if not IsValid( e2 ) then
        e2 = self.netvar.entities and IsValid( self.netvar.entities.Entity2 ) and self.netvar.entities.Entity2 or nil
    end

    return e1, e2
end


--[[
]]
local mode = tanktracktool.render.mode()
mode:addCSent( "dBar", "dUpper", "dCylinder", "dRetainer", "dLower1", "dLower2" )

function mode:onInit( controller )
    self:override( controller, true )
    local data = self:getData( controller )

    local size = 1
    local barSize = 0.65 * size
    local cylinderLength = 12 * size
    local retainerPos = 6

    local dUpper = self:addPart( controller, "dUpper" )
    dUpper:setnodraw( false, true )
    dUpper:setmodel( "models/tanktracktool/suspension/dampers/style1_upper.mdl" )
    dUpper:setscale( Vector( size, size, size ) )
    dUpper.scale_m:Rotate( Angle( -90, 0, 0 ) )
    dUpper:setmaterial( "models/shiny" )
    dUpper:setcolor( Color( 255, 0, 0 ) )

    local dCylinder = self:addPart( controller, "dCylinder" )
    dCylinder:setnodraw( false, true )
    dCylinder:setmodel( "models/tanktracktool/suspension/dampers/style1_cylinder.mdl" )
    dCylinder:setscale( Vector( cylinderLength / 6, size, size ) )
    dCylinder.scale_m:Rotate( Angle( -90, 0, 0 ) )
    dCylinder:setlposl( Vector( 2.21 * size, 0, 0 ) )
    dCylinder:setmaterial( "models/shiny" )
    dCylinder:setcolor( Color( 255, 255, 255 ) )

    local dRetainer = self:addPart( controller, "dRetainer" )
    dRetainer:setnodraw( false, true )
    dRetainer:setmodel( "models/tanktracktool/suspension/dampers/style1_retainer.mdl" )
    dRetainer:setscale( Vector( size * 2, size, size ) )
    dRetainer.scale_m:Rotate( Angle( -90, 0, 0 ) )
    dRetainer:setlposl( Vector( retainerPos * size, 0, 0 ) )
    dRetainer:setmaterial( "models/shiny" )
    dRetainer:setcolor( Color( 255, 0, 0 ) )

    local dLower1 = self:addPart( controller, "dLower1" )
    dLower1:setnodraw( false, true )
    dLower1:setmodel( "models/tanktracktool/suspension/dampers/style1_lower1.mdl" )
    dLower1:setscale( Vector( size, size, size ) )
    dLower1.scale_m:Rotate( Angle( -90, 0, 0 ) )
    dLower1:setmaterial( "models/shiny" )
    dLower1:setcolor( Color( 0, 0, 0 ) )

    local dLower2 = self:addPart( controller, "dLower2" )
    dLower2:setnodraw( false, true )
    dLower2:setmodel( "models/tanktracktool/suspension/dampers/style1_lower2.mdl" )
    dLower2:setscale( Vector( size, size, size ) )
    dLower2.scale_m:Rotate( Angle( -90, 0, 0 ) )
    dLower2:setmaterial( "sprops/textures/sprops_chrome" )

    local dBar = self:addPart( controller, "dBar" )
    dBar:setnodraw( false, true )
    dBar:setmodel( "models/tanktracktool/suspension/dampers/style1_bar.mdl" )
    dBar.scale_v = Vector( 1, barSize / 2, barSize / 2 )
    dBar.cylinderLength = cylinderLength + 2.21

    dBar:setlposl( Vector( 2.21 + cylinderLength, 0, 0 ) )
    dBar:setmaterial( "sprops/textures/sprops_chrome" )

    data.damper = {
        dUpper = dUpper,
        dCylinder = dCylinder,
        dRetainer = dRetainer,
        dLower1 = dLower1,
        dLower2 = dLower2,
        dBar = dBar,
    }

    data.helix = tanktracktool.render.createCoil()
    data.helix:setColor( Color( 30, 30, 30 ) )
    data.helix:setCoilCount( 8 )
    data.helix:setDetail( 1 / 4 )
    data.helix:setRadius( size * 1.125 )
    data.helix:setWireRadius( size * ( 1 / 5 ) )
end

function mode:onThink( controller )
    local e1, e2 = GetEntities( controller )
    if not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    self:setnodraw( controller, false )

    local data = self:getData( controller )
    local parts = self:getParts( controller )

    local damper = data.damper

    do
        local pos1 = e1:GetPos()
        local pos2 = e2:GetPos()
        local dir = pos2 - pos1
        local len = dir:Length()
        local ang = dir:Angle()

        damper.dUpper:setwposangl( pos1, ang )
        damper.dCylinder:setparent( damper.dUpper )
        damper.dRetainer:setparent( damper.dUpper )
        damper.dBar:setparent( damper.dUpper )

        damper.dBar.scale_v.x = ( len - damper.dBar.cylinderLength ) / 6

        local scale = Matrix()
        scale:SetScale( damper.dBar.scale_v )
        scale:Rotate( Angle( -90, 0, 0 ) )
        damper.dBar.scale_m = scale

        damper.dLower1:setwposangl( pos2, ang )
        damper.dLower2:setwposangl( pos2, ang )

        data.helix:think( damper.dRetainer.le_posworld, pos2, damper.dRetainer.le_posworld, -0.340184 )
    end
end

function mode:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    local data = self:getData( controller )
    data.helix:draw()

    self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )

    if flashlightMODE then
        render.PushFlashlightMode( true )
        self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
        render.PopFlashlightMode()
    end
end

function ENT:Think()
    self.BaseClass.Think( self )

    if self.tanktracktool_reset then
        self.tanktracktool_reset = nil
        mode:init( self )
        return
    end

    mode:think( self )
end

function ENT:Draw()
    self:DrawModel()
end

--[[

local render_multiply = "RenderMultiply"

local function setupscale_damper_bar( self, csent, left, controller )
    csent:EnableMatrix( render_multiply, self.scale_m )
    csent:ManipulateBonePosition( 1, left and self.bonepos_1l or self.bonepos_1r )
    csent:ManipulateBonePosition( 2, left and self.bonepos_2l or self.bonepos_2r )
    csent:SetupBones()
end
local function setupscale_damper_lower( self, csent, left, controller )
    csent:EnableMatrix( render_multiply, self.scale_m )
    csent:ManipulateBonePosition( 1, left and self.bonepos_1l or self.bonepos_1r )
    csent:ManipulateBonePosition( 2, left and self.bonepos_2l or self.bonepos_2r )
    csent:SetupBones()
end

function mode:onInit( controller )
    self:override( controller, true )
    local data = self:getData( controller )

    data.helix = tanktracktool.render.createCoil()
    data.helix:setColor( Color( 255, 125, 0 ) )
    data.helix:setCoilCount( 10 )
    data.helix:setDetail( 1 / 4 )
    data.helix:setRadius( 3 )
    data.helix:setWireRadius( 2/3 )



    local damper_bar = self:addPart( controller, "damper_bar" )
    damper_bar:setmodel( "models/tanktracktool/suspension/damper_bar.mdl" )
    damper_bar:setnodraw( false, true )
    damper_bar:setmaterial( "sprops/textures/sprops_chrome" )

    local size = 1
    damper_bar:setscale( Vector( size, size, size ) )
    damper_bar.setupscale = setupscale_damper_bar



    local damper_upper = self:addPart( controller, "damper_upper" )
    damper_upper:setmodel( "models/tanktracktool/suspension/damper_style2_upper.mdl" )
    damper_upper:setnodraw( false, true )
    damper_upper:setcolor( Color( 0, 0, 255 ) )
    damper_upper:setmaterial( "models/shiny" )

    local size = 10
    damper_upper:setscale( Vector( size, size, size ) )
    damper_upper.setupscale = setupscale_damper_lower


    local damper_lower = self:addPart( controller, "damper_lower" )
    damper_lower:setmodel( "models/tanktracktool/suspension/damper_style2_lower.mdl" )
    damper_lower:setnodraw( false, true )
    damper_lower:setcolor( Color( 43, 43, 43 ) )
    damper_lower:setmaterial( "sprops/textures/gear_metal" )

    local size = 10
    damper_lower:setscale( Vector( size, size, size ) )
    damper_lower.setupscale = setupscale_damper_lower
end

function mode:onThink( controller )
    local e1, e2 = GetEntities( controller )
    if not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    self:setnodraw( controller, false )

    local data = self:getData( controller )
    local parts = self:getParts( controller )

    local dir = e2:GetPos() - e1:GetPos()
    local ang = dir:Angle()
    local len = dir:Length()
    ang:RotateAroundAxis( ang:Right(), -90 )

    local n1 = dir:GetNormalized()
    local p1 = e1:GetPos() + n1 * 4
    data.helix:think( p1, e2:GetPos() - n1 * 5.5, p1 )

    parts[1]:setwposl( e1:GetPos() )
    parts[1]:setwangl( ang )
    parts[1].bonepos_1l = Vector( 0, 100, 0 ) --len / 1 - 1.5, 0 )
    parts[1].bonepos_2l = Vector( 0, 1.5, 0 )

    parts[2]:setwposl( e2:GetPos() )
    parts[2]:setwangl( ang )
    parts[2].bonepos_1l = Vector( 0, -1, 0 )
    parts[2].bonepos_2l = Vector( 0, 0, 0 )

    parts[3]:setwposl( e1:GetPos() )
    parts[3]:setwangl( ang )
    parts[3].bonepos_1l = Vector( 0, len / 10 - 3.59971, 0 )
    parts[3].bonepos_2l = Vector( 0, 0, 0 )
end

function mode:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    local data = self:getData( controller )
    data.helix:draw()

    self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )

    if flashlightMODE then
        render.PushFlashlightMode( true )
        self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
        render.PopFlashlightMode()
    end
end

function ENT:Think()
    self.BaseClass.Think( self )

    if self.tanktracktool_reset then
        self.tanktracktool_reset = nil
        mode:init( self )
        return
    end

    mode:think( self )
end

function ENT:Draw()
    self:DrawModel()
end
]]
