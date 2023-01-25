
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
    tanktracktool.netvar.addToolLink( ENT, "Chassis", nil, nil )
    tanktracktool.netvar.addToolLink( ENT, "LeftWheel", nil, nil )
    tanktracktool.netvar.addToolLink( ENT, "RightWheel", nil, nil )
end

if SERVER then
    function ENT:netvar_setLinks( tbl, ply )
        if not istable( tbl ) then
            return tanktracktool.netvar.setLinks( self, {}, ply )
        end

        tbl = {
            Chassis = isentity( tbl.Chassis ) and tbl.Chassis or nil,
            LeftWheel = isentity( tbl.LeftWheel ) and tbl.LeftWheel or nil,
            RightWheel = isentity( tbl.RightWheel ) and tbl.RightWheel or nil,
        }

        return tanktracktool.netvar.setLinks( self, tbl, ply )
    end
end


--[[
    netvar setup
]]
local netvar = tanktracktool.netvar.new()

function ENT:netvar_setup()
    return netvar
end

netvar:category( "Setup" )

netvar:var( "scale", "Float", { def = 1, min = 0, max = 50 } )
netvar:var( "xwheel", "Float", { def = 0, min = 0, max = 1000, title = "wheel forward offset" } )
netvar:var( "ywheel", "Float", { def = 0, min = -1, max = 1, title = "wheel width offset" } )

netvar:category( "Swing Arm" )
netvar:var( "zarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot height" } )
netvar:var( "yarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot length" } )

netvar:category( "Shock Absorber" )

netvar:subcategory( "Setup" )
netvar:var( "shocktype", "Combo", { def = "coil_over", values = { coil_over = 1, spring = 2, covered = 3, none = 4 }, sort = SortedPairsByValue, title = "type" } )
netvar:var( "shockscale", "Float", { def = 1, min = 0, max = 50, title = "model scale" } )
netvar:var( "shocklencyl", "Float", { def = 12, min = 0, max = 1000, title = "cylinder length", help = "absolute units" } )
netvar:var( "shocklenret", "Float", { def = 0.75, min = 0, max = 1, title = "retainer offset", help = "% of cylinder length" } )
netvar:var( "shockcoilradius", "Float", { def = 0.25, min = 0, max = 1, title = "coil wire radius", help = "% of model scale" } )
netvar:var( "shockcoilcount", "Int", { def = 12, min = 1, max = 50, title = "coil turn count" } )
netvar:var( "shockoffset1", "Vector", { def = Vector(), min = Vector( -1000, -1000, -1000 ), max = Vector( 1000, 1000, 1000 ), title = "local offset" } )

netvar:subcategory( "Colors" )
netvar:var( "shockrodcolor", "Color", { def = "", title = "piston" } )
netvar:var( "shocktopcolor", "Color", { def = "175 175 175 255", title = "top" } )
netvar:var( "shockbotcolor", "Color", { def = "30 30 30 255", title = "bottom" } )
netvar:var( "shockcylcolor", "Color", { def = "30 30 30 255", title = "cylinder" } )
netvar:var( "shockretcolor", "Color", { def = "175 175 175 255", title = "retainer" } )
netvar:var( "shockwirecolor", "Color", { def = "30 30 30 255", title = "coil/cover" } )

netvar:subcategory( "Materials" )
netvar:var( "shockrodmat", "String", { def = "phoenix_storms/fender_chrome", title = "piston" } )
netvar:var( "shocktopmat", "String", { def = "models/shiny", title = "top" } )
netvar:var( "shockbotmat", "String", { def = "models/shiny", title = "bottom" } )
netvar:var( "shockcylmat", "String", { def = "models/shiny", title = "cylinder" } )
netvar:var( "shockretmat", "String", { def = "models/shiny", title = "retainer" } )
netvar:var( "shockcovermat", "String", { def = "phoenix_storms/concrete0", title = "cover" } )


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
    if not self.netvar.entities and ( self.netvar.entindex.Chassis and self.netvar.entindex.LeftWheel and self.netvar.entindex.RightWheel ) then
        local e0 = Entity( self.netvar.entindex.Chassis )
        local e1 = Entity( self.netvar.entindex.LeftWheel )
        local e2 = Entity( self.netvar.entindex.RightWheel )

        if IsValid( e0 ) and IsValid( e1 ) and IsValid( e2 ) then
            self.netvar.entities = { Chassis = e0, LeftWheel = e1, RightWheel = e2 }
        end
    end

    local e0 = self.netvar.entities and IsValid( self.netvar.entities.Chassis ) and self.netvar.entities.Chassis or nil
    local e1 = self.netvar.entities and IsValid( self.netvar.entities.LeftWheel ) and self.netvar.entities.LeftWheel or nil
    local e2 = self.netvar.entities and IsValid( self.netvar.entities.RightWheel ) and self.netvar.entities.RightWheel or nil

    return e0, e1, e2
end


--[[

]]
local mode = tanktracktool.render.mode()
mode:addCSent( "spindle", "ujoint", "arm" )

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

function mode:onInit( controller )
    self:override( controller, true )

    local values = controller.netvar.values
    local data = self:getData( controller )

    data.scale = values.scale + 1
    data.xwheel = values.xwheel
    data.ywheel = values.ywheel

    data.yarm = values.yarm
    data.zarm = values.zarm

    data.spindle = self:addPart( controller, "spindle" )
    data.spindle:setmodel( "models/tanktracktool/suspension/linkage_spindle1.mdl" )
    data.spindle:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.spindle.my = -4 * data.scale
    data.spindle.mz = -3.33601 * data.scale
    data.spindle.le_anglocal.y = 90
    data.spindle.ri_anglocal.y = -90

    data.ujoint = self:addPart( controller, "ujoint" )
    data.ujoint:setmodel( "models/tanktracktool/suspension/linkage_ujoint.mdl" )
    data.ujoint:setscale( Vector( data.scale, data.scale, data.scale ) * 0.75 )
    data.ujoint.le_poslocal.z = 0.5 * data.scale
    data.ujoint.ri_poslocal.z = 0.5 * data.scale

    data.arm = self:addPart( controller, "arm" )
    data.arm:setmodel( "models/tanktracktool/suspension/linkage_arm1.mdl" )
    data.arm:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.arm.le_anglocal = Angle( 0, -90, 180 )
    data.arm.ri_anglocal = Angle( 0, -90, 0 )
    data.arm.le_poslocal.z = -0.75 * data.scale
    data.arm.ri_poslocal.z = -0.75 * data.scale

    data.arm.bone_2_length_l = Vector()
    data.arm.bone_2_length_r = Vector()

    data.arm.setupscale = function( self, csent, left, controller )
        csent:EnableMatrix( "RenderMultiply", self.scale_m )
        if left then
            csent:ManipulateBonePosition( 2, self.bone_2_length_l )
        else
            csent:ManipulateBonePosition( 2, self.bone_2_length_r )
        end
        csent:SetupBones()
    end

    local shock = tanktracktool.render.addshock( self, controller )
    data.shock = shock

    shock.info.type = values.shocktype
    shock.info.scale = values.scale * values.shockscale
    shock.info.coilcount = values.shockcoilcount
    shock.info.wireradius = values.shockcoilradius
    shock.info.shocklencyl = values.shocklencyl
    shock.info.shocklenret = values.shocklenret
    shock.info.rodcolor = values.shockrodcolor
    shock.info.topcolor = values.shocktopcolor
    shock.info.botcolor = values.shockbotcolor
    shock.info.cylcolor = values.shockcylcolor
    shock.info.retcolor = values.shockretcolor
    shock.info.wirecolor = color_white --values.shockwirecolor

    shock.info.rodmat = values.shockrodmat
    shock.info.topmat = values.shocktopmat
    shock.info.botmat = values.shockbotmat
    shock.info.cylmat = values.shockcylmat
    shock.info.retmat = values.shockretmat
    shock.info.covermat = values.shockcovermat

    data.shockoffset_l1 = Vector( -0.5, 0, 6 ) * data.scale
    data.shockoffset_r1 = Vector( -0.5, 0, 6 ) * data.scale
    data.shockoffset_l2 = Vector( data.xwheel + values.shockoffset1.x, values.shockoffset1.y, values.shockoffset1.z )
    data.shockoffset_r2 = Vector( data.xwheel + values.shockoffset1.x, -values.shockoffset1.y, values.shockoffset1.z )

    data.shock:init( true, true )

    for k, v in pairs( self:getParts( controller ) ) do
        v:setcolor( HSVToColor( ( 360 / #self:getParts( controller ) ) * k, 1, 1 ) )
        v:setmaterial( "" )
    end

end

local _ang = Angle()

function mode:onThink( controller )
    local e0, e1, e2 = GetEntities( controller )
    if not e0 or not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    self:setnodraw( controller, false )

    local data = self:getData( controller )
    local parts = self:getParts( controller )

    local m = e0:GetWorldTransformMatrix()
    m:SetForward( ( e1:GetPos() - e2:GetPos() ):Cross( m:GetUp() ):GetNormalized() )
    m:SetRight( m:GetForward():Cross( m:GetUp() ) )
    data.matrix = m

    local fw_chassis = m:GetForward()
    local rg_chassis = m:GetRight()
    local up_chassis = m:GetUp()

    local pos_chassis, ang_chassis = m:GetTranslation(), m:GetAngles()
    local pos_wheel_l, ang_wheel_l = WorldToLocal( e1:GetPos(), e1:GetAngles(), pos_chassis, ang_chassis )
    local pos_wheel_r, ang_wheel_r = WorldToLocal( e2:GetPos(), e2:GetAngles(), pos_chassis, ang_chassis )

    if not data.lwheel_width then
        data.lwheel_width = ( e1:OBBMaxs() - e1:OBBMins() ):Length()
    end
    if not data.rwheel_width then
        data.rwheel_width = ( e2:OBBMaxs() - e2:OBBMins() ):Length()
    end

    data.spindle.le_anglocal.y = -math.acos( 1 * e1:GetRight():Dot( fw_chassis ) ) * ( 180 / math.pi ) + 180
    data.spindle.ri_anglocal.y = math.acos( 1 * e2:GetRight():Dot( fw_chassis ) ) * ( 180 / math.pi ) + 180

    local offset = Vector( data.xwheel, pos_wheel_l.y + data.lwheel_width * data.ywheel + data.spindle.my, pos_wheel_l.z + data.spindle.mz )
    data.spindle:setwposangl( LocalToWorld( offset, data.spindle.le_anglocal, pos_chassis, ang_chassis ) )

    local offset = Vector( data.xwheel, pos_wheel_r.y - data.rwheel_width * data.ywheel - data.spindle.my, pos_wheel_r.z + data.spindle.mz )
    data.spindle:setwposangr( LocalToWorld( offset, data.spindle.ri_anglocal, pos_chassis, ang_chassis ) )

    data.ujoint:setparent( data.spindle, data.spindle )
    data.arm:setparent( data.ujoint, data.ujoint )

    local target = LocalToWorld( Vector( data.xwheel, math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.le_posworld )

    data.arm.le_anglocal.p = math.atan2( normal.z, normal.y ) * ( 180 / math.pi )
    data.arm:setwangl( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.le_anglocal ) )
    data.arm.bone_2_length_l.z = -normal:Length() / data.scale + 3.746 + 3.254

    local target = LocalToWorld( Vector( data.xwheel, -math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.ri_posworld )

    data.arm.ri_anglocal.p = math.atan2( normal.z, normal.y ) * ( 180 / math.pi )
    data.arm:setwangr( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.ri_anglocal ) )
    data.arm.bone_2_length_r.z = -normal:Length() / data.scale + 3.746 + 3.254

    local sp0 = LocalToWorld( data.shockoffset_l1, _ang, data.spindle.le_posworld, data.spindle.le_angworld )
    local sp1 = LocalToWorld( data.shockoffset_l2, _ang, pos_chassis, ang_chassis )
    local sp2 = LocalToWorld( data.shockoffset_r1, _ang, data.spindle.ri_posworld, data.spindle.ri_angworld )
    local sp3 = LocalToWorld( data.shockoffset_r2, _ang, pos_chassis, ang_chassis )

    data.shock:setcontrolpoints( sp0, sp1, sp2, sp3 )
end

function mode:onDraw( controller, eyepos, eyedir, empty, flashlight )
    local data = self:getData( controller )

    data.shock:render()
    self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )

    if flashlightMODE then
        render.PushFlashlightMode( true )
        self:renderParts( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
        render.PopFlashlightMode()
    end
end
