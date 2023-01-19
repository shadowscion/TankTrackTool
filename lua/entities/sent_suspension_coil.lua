
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


--[[
]]
local mode = tanktracktool.render.mode()

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

function mode:onInit( controller )
    self:override( controller, true )
    local data = self:getData( controller )

    data.helix = tanktracktool.render.createCoil()
    data.helix:setColor( Color( 255, 125, 0 ) )
    data.helix:setCoilCount( 24 )
    data.helix:setDetail( 1 / 2 )
end

function mode:onThink( controller )
    local e1, e2 = GetEntities( controller )
    if not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    local data = self:getData( controller )
    data.helix:think( e1:GetPos(), e2:GetPos(), e1:GetPos() )

    self:setnodraw( controller, false )
end

function mode:onDraw( controller, eyepos, eyedir, empty )
    local data = self:getData( controller )
    data.helix:draw()
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
