
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
end


--[[
    netvar setup
]]
local netvar = tanktracktool.netvar.new()

local default = {
    cylinderLen = 12,
    retainerPos = 0.75,
    colTop = "175 175 175 255",
    colCylinder = "25 25 25 255",
    colRetainer = "175 175 175 255",
    colPiston = "255 255 255 255",
    colBottom = "25 25 25 255",
    matTop = "models/shiny",
    matCylinder = "models/shiny",
    matRetainer = "models/shiny",
    matPiston = "phoenix_storms/fender_chrome",
    matBottom = "models/shiny",
    coilType = "spring",
    coilColor = "175 175 175 255",
    coilCount = 12,
    coilRadius = 6,
    wireRadius = 1 / 2
}

function ENT:netvar_setup()
    return netvar, default
end

netvar:category( "coil model" )
netvar:var( "coilType", "Combo", { def = 1, values = { spring = 1, cover = 2, none = 3 }, sort = SortedPairsByValue, title = "type" } )
netvar:var( "coilCol", "Color", { def = "", title = "color" } )
netvar:var( "coilMat", "String", { def = "", title = "material" } )
netvar:var( "coilCount", "Int", { def = 12 , min = 0, max = 50, title = "turn count" } )
netvar:var( "coilRadius", "Float", { def = 6, min = 0, max = 50, title = "coil radius" } )
netvar:var( "wireRadius", "Float", { def = 1 / 6, min = 0, max = 50, title = "wire radius" } )

netvar:category( "shock model" )
netvar:var( "shockEnable", "Bool", { def = 1, title = "enabled" } )
netvar:var( "modelScale", "Float", { def = 1, min = 0, max = 50 } )
netvar:var( "cylinderLen", "Float", { def = 24, min = 0, max = 1000, title = "cylinder length" } )
netvar:var( "retainerPos", "Float", { def = 0.5, min = 0, max = 1, title = "coil attachment offset" } )

netvar:subcategory( "upper" )
netvar:var( "colTop", "Color", { def = "", title = "color" } )
netvar:var( "matTop", "String", { def = "", title = "material" } )

netvar:subcategory( "lower" )
netvar:var( "colBottom", "Color", { def = "", title = "color" } )
netvar:var( "matBottom", "String", { def = "", title = "material" } )

netvar:subcategory( "coil attachment" )
netvar:var( "colRetainer", "Color", { def = "", title = "color" } )
netvar:var( "matRetainer", "String", { def = "", title = "material" } )

netvar:subcategory( "cylinder" )
netvar:var( "colCylinder", "Color", { def = "", title = "color" } )
netvar:var( "matCylinder", "String", { def = "", title = "material" } )

netvar:subcategory( "piston rod" )
netvar:var( "colPiston", "Color", { def = "", title = "color" } )
netvar:var( "matPiston", "String", { def = "", title = "material" } )


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
do
    netvar:get( "coilType" ).data.hook = function( inner, val )
        local editor = inner.m_Editor
        editor.Variables.coilCol:SetEnabled( val == "spring" or val == "cover" )
        editor.Variables.coilMat:SetEnabled( val == "cover" )
        editor.Variables.coilCount:SetEnabled( val == "spring" )
        editor.Variables.wireRadius:SetEnabled( val == "spring" )
        editor.Variables.coilRadius:SetEnabled( val == "spring" and not tobool( editor.m_Entity:netvar_get( "shockEnable" ) ) )
    end

    local keys = { "cylinderLen", "retainerPos", "modelScale" }
    local subs = { "upper", "lower", "coil attachment", "cylinder", "piston rod" }
    netvar:get( "shockEnable" ).data.hook = function( inner, val )
        local editor = inner.m_Editor
        local enabled = tobool( val )

        editor.Variables.coilRadius:SetEnabled( not enabled and editor.m_Entity:netvar_get( "coilType" ) == "spring" )

        local cat = editor.Categories["shock model"].Categories
        for k, v in pairs( subs ) do
            if cat[v] then
                cat[v]:SetExpanded( enabled, not enabled )
                cat[v]:SetEnabled( enabled )
            end
        end
        for k, v in pairs( keys ) do
            if editor.Variables[v] then
                editor.Variables[v]:SetEnabled( enabled )
            end
        end
    end
end


--[[
    netvar hooks
]]
local hooks = {}

hooks.editor_open = function( self, editor )
    for k, cat in pairs( editor.Categories ) do
        cat:ExpandRecurse( true )
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

    local e1 = self.netvar.entities and IsValid( self.netvar.entities.Entity1 ) and self.netvar.entities.Entity1 or nil
    local e2 = self.netvar.entities and IsValid( self.netvar.entities.Entity2 ) and self.netvar.entities.Entity2 or nil

    return e1, e2
end


--[[
]]
local mode = tanktracktool.render.mode()
mode:addCSent( "shock_piston_tip", "shock_piston_rod", "shock_top", "shock_cylinder", "shock_retainer", "shock_bottom" )

function mode:onInit( controller )
    self:override( controller, true )

    local values = controller.netvar.values
    local data = self:getData( controller )

    local factor = values.modelScale

    if tobool( values.shockEnable ) then
        local shock = {}
        data.shock = shock

        -- any magic numbers below are from
        -- the model dimensions in blender

        shock.scalar = factor
        shock.cylinderLen = values.cylinderLen
        shock.retainerPos = ( shock.cylinderLen - ( 0.312768 * factor + 0.175 * ( shock.cylinderLen / 12 ) ) ) * values.retainerPos

        shock.piston_tip1 = self:addPart( controller, "shock_piston_tip" )
        shock.piston_tip1:setnodraw( false, true )
        shock.piston_tip1:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        shock.piston_tip1:setmaterial( values.matPiston )
        shock.piston_tip1:setcolor( values.colPiston )
        shock.piston_tip1:setscale( Vector( factor, factor, factor ) )

        shock.piston_tip2 = self:addPart( controller, "shock_piston_tip" )
        shock.piston_tip2:setnodraw( false, true )
        shock.piston_tip2:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        shock.piston_tip2:setmaterial( values.matPiston )
        shock.piston_tip2:setcolor( values.colPiston )
        shock.piston_tip2:setscale( Vector( factor, factor, factor ) )
        shock.piston_tip2.le_anglocal.p = 180

        if values.coilType == "cover" then
            shock.piston_cover = self:addPart( controller, "shock_piston_rod" )
            shock.piston_cover:setnodraw( false, true )
            shock.piston_cover:setmodel( "models/tanktracktool/suspension/shock_cover1.mdl" )
            shock.piston_cover:setmaterial( values.coilMat )
            shock.piston_cover:setcolor( values.coilCol )
            shock.piston_cover:setscale( Vector( factor, factor, factor ) )
            shock.piston_cover.le_poslocal.x = 0 * factor
        else
            shock.piston_rod = self:addPart( controller, "shock_piston_rod" )
            shock.piston_rod:setnodraw( false, true )
            shock.piston_rod:setmodel( "models/tanktracktool/suspension/shock_piston_rod.mdl" )
            shock.piston_rod:setmaterial( values.matPiston )
            shock.piston_rod:setcolor( values.colPiston )
            shock.piston_rod:setscale( Vector( factor, factor, factor ) )
            shock.piston_rod.le_poslocal.x = 1.5 * factor

            if values.coilType == "spring" and values.wireRadius > 0 and values.coilRadius > 0 and values.coilCount > 0 then
                data.helix = tanktracktool.render.createCoil()
                data.helix:setColor( string.ToColor( values.coilCol ) )
                data.helix:setCoilCount( values.coilCount )
                data.helix:setDetail( 1 / 4 )
                data.helix:setRadius( 2.1 * factor )
                data.helix:setWireRadius( values.wireRadius * factor )
            end
        end

        shock.top = self:addPart( controller, "shock_top" )
        shock.top:setnodraw( false, true )
        shock.top:setmodel( "models/tanktracktool/suspension/shock_top2.mdl" )
        shock.top:setmaterial( values.matTop )
        shock.top:setcolor( values.colTop )
        shock.top:setscale( Vector( factor, factor, factor ) )
        shock.top.le_poslocal.x = 1.25 * factor

        shock.cylinder = self:addPart( controller, "shock_cylinder" )
        shock.cylinder:setnodraw( false, true )
        shock.cylinder:setmodel( "models/tanktracktool/suspension/shock_cylinder1.mdl" )
        shock.cylinder:setmaterial( values.matCylinder )
        shock.cylinder:setcolor( values.colCylinder )
        shock.cylinder:setscale( Vector( shock.cylinderLen / 12, factor, factor ) )
        shock.cylinder.le_poslocal.x = 3 * factor

        shock.retainer = self:addPart( controller, "shock_retainer" )
        shock.retainer:setnodraw( false, true )
        shock.retainer:setmodel( "models/tanktracktool/suspension/shock_retainer1.mdl" )
        shock.retainer:setmaterial( values.matRetainer )
        shock.retainer:setcolor( values.colRetainer )
        shock.retainer:setscale( Vector( factor, factor, factor ) )
        shock.retainer.le_poslocal.x = shock.retainerPos

        shock.bottom = self:addPart( controller, "shock_bottom" )
        shock.bottom:setnodraw( false, true )
        shock.bottom:setmodel( "models/tanktracktool/suspension/shock_bottom1.mdl" )
        shock.bottom:setmaterial( values.matBottom )
        shock.bottom:setcolor( values.colBottom )
        shock.bottom:setscale( Vector( factor, factor, factor ) )
        shock.bottom.le_poslocal.x = 3 * factor
        shock.bottom.le_anglocal.p = 180

    elseif values.coilType == "spring" and values.wireRadius > 0 and values.coilRadius > 0 and values.coilCount > 0 then

        data.helix = tanktracktool.render.createCoil()
        data.helix:setColor( string.ToColor( values.coilCol ) )
        data.helix:setCoilCount( values.coilCount )
        data.helix:setDetail( 1 / 4 )
        data.helix:setRadius( values.coilRadius )
        data.helix:setWireRadius( values.wireRadius )

    end
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

    local shock = data.shock
    if shock then
        local pos1 = e1:GetPos()
        local pos2 = e2:GetPos()
        local dir = pos2 - pos1
        local len = dir:Length()
        local ang = dir:Angle()

        local scale = shock.scalar

        shock.piston_tip1:setwposangl( pos1, ang )
        shock.piston_tip2.le_poslocal.x = len
        shock.piston_tip2:setparent( shock.piston_tip1 )

        shock.top:setparent( shock.piston_tip1 )
        shock.bottom:setparent( shock.piston_tip2 )
        shock.cylinder:setparent( shock.top )
        shock.retainer:setparent( shock.cylinder )

        if shock.piston_cover then
            shock.piston_cover:setparent( shock.retainer )
            local len = ( shock.retainer.le_posworld - shock.bottom.le_posworld ):Length()
            shock.piston_cover.scale_v.x = len / 12
            shock.piston_cover.scale_m:SetScale( shock.piston_cover.scale_v )
        else
            if shock.piston_rod then
                shock.piston_rod.scale_v.x = ( len - 3 * scale ) / 24
                shock.piston_rod.scale_m:SetScale( shock.piston_rod.scale_v )
                shock.piston_rod:setparent( shock.piston_tip1 )
            end
            if data.helix then
                data.helix:think( shock.retainer.le_posworld, shock.bottom.le_posworld )
            end
        end
    else
        if data.helix then
            local pos1 = e1:GetPos()
            local pos2 = e2:GetPos()

            data.helix:think( pos1, pos2 )
        end
    end
end

function mode:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    local data = self:getData( controller )

    if data.helix then
        data.helix:draw()
    end

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
