
AddCSLuaFile()

DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = false
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
            Entity1 = tbl.Entity1 or self.netvar.entities.Entity1,
            Entity2 = tbl.Entity2 or self.netvar.entities.Entity2,
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

local function GetEntity( self, entID, netID )
    if netID then
        netID = self:GetNW2Entity( netID, nil )
        if IsValid( netID ) then
            return netID
        end
    end

    if not self.netvar.entindex[entID] then
        return nil
    end

    local e = Entity( self.netvar.entindex[entID] )
    return IsValid( e ) and e or nil
end

function mode:onInit( controller )
    self:override( controller, true )
end

function mode:onThink( controller )
    local e1 = GetEntity( controller, "Entity1", "netwire_Entity1" )
    local e2 = GetEntity( controller, "Entity2", "netwire_Entity2" )

    if not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    self:setnodraw( controller, false )
    local data = self:getData( controller )
end

function mode:onDraw( controller, eyepos, eyedir, empty )
    local data = self:getData( controller )
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
