
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

local default = {
    -- cylinderLen = 12,
    -- retainerPos = 0.75,
    -- colTop = "175 175 175 255",
    -- colCylinder = "25 25 25 255",
    -- colRetainer = "175 175 175 255",
    -- colPiston = "255 255 255 255",
    -- colBottom = "25 25 25 255",
    -- matTop = "models/shiny",
    -- matCylinder = "models/shiny",
    -- matRetainer = "models/shiny",
    -- matPiston = "phoenix_storms/fender_chrome",
    -- matBottom = "models/shiny",
    -- coilType = "spring",
    -- coilColor = "175 175 175 255",
    -- coilCount = 12,
    -- coilRadius = 6,
    -- wireRadius = 1 / 2
}

function ENT:netvar_setup()
    return netvar, default
end

netvar:category( "Setup" )
netvar:var( "modelScale", "Float", { def = 1, min = 0, max = 50 } )
netvar:var( "xwheel", "Float", { def = 0, min = 0, max = 1000, title = "wheel forward offset" } )
netvar:var( "ywheel", "Float", { def = 0, min = -1, max = 1, title = "wheel width offset" } )

netvar:category( "Swing Arm" )
netvar:var( "zarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot height" } )
netvar:var( "yarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot length" } )
netvar:var( "rarm", "Float", { def = 0, min = 0, max = 1, title = "length ratio" } )




-- netvar:category( "coil model" )
-- netvar:var( "coilType", "Combo", { def = 1, values = { spring = 1, cover = 2, none = 3 }, sort = SortedPairsByValue, title = "type" } )
-- netvar:var( "coilCol", "Color", { def = "", title = "color" } )
-- netvar:var( "coilMat", "String", { def = "", title = "material" } )
-- netvar:var( "coilCount", "Int", { def = 12 , min = 0, max = 50, title = "turn count" } )
-- netvar:var( "coilRadius", "Float", { def = 6, min = 0, max = 50, title = "coil radius" } )
-- netvar:var( "wireRadius", "Float", { def = 1 / 6, min = 0, max = 50, title = "wire radius" } )

-- netvar:category( "shock model" )
-- netvar:var( "shockEnable", "Bool", { def = 1, title = "enabled" } )
-- netvar:var( "modelScale", "Float", { def = 1, min = 0, max = 50 } )
-- netvar:var( "cylinderLen", "Float", { def = 24, min = 0, max = 1000, title = "cylinder length" } )
-- netvar:var( "retainerPos", "Float", { def = 0.5, min = 0, max = 1, title = "coil attachment offset" } )

-- netvar:subcategory( "upper" )
-- netvar:var( "colTop", "Color", { def = "", title = "color" } )
-- netvar:var( "matTop", "String", { def = "", title = "material" } )

-- netvar:subcategory( "lower" )
-- netvar:var( "colBottom", "Color", { def = "", title = "color" } )
-- netvar:var( "matBottom", "String", { def = "", title = "material" } )

-- netvar:subcategory( "coil attachment" )
-- netvar:var( "colRetainer", "Color", { def = "", title = "color" } )
-- netvar:var( "matRetainer", "String", { def = "", title = "material" } )

-- netvar:subcategory( "cylinder" )
-- netvar:var( "colCylinder", "Color", { def = "", title = "color" } )
-- netvar:var( "matCylinder", "String", { def = "", title = "material" } )

-- netvar:subcategory( "piston rod" )
-- netvar:var( "colPiston", "Color", { def = "", title = "color" } )
-- netvar:var( "matPiston", "String", { def = "", title = "material" } )


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
    -- netvar:get( "coilType" ).data.hook = function( inner, val )
    --     local editor = inner.m_Editor
    --     editor.Variables.coilCol:SetEnabled( val == "spring" or val == "cover" )
    --     editor.Variables.coilMat:SetEnabled( val == "cover" )
    --     editor.Variables.coilCount:SetEnabled( val == "spring" )
    --     editor.Variables.wireRadius:SetEnabled( val == "spring" )
    --     editor.Variables.coilRadius:SetEnabled( val == "spring" and not tobool( editor.m_Entity:netvar_get( "shockEnable" ) ) )
    -- end

    -- local keys = { "cylinderLen", "retainerPos", "modelScale" }
    -- local subs = { "upper", "lower", "coil attachment", "cylinder", "piston rod" }
    -- netvar:get( "shockEnable" ).data.hook = function( inner, val )
    --     local editor = inner.m_Editor
    --     local enabled = tobool( val )

    --     editor.Variables.coilRadius:SetEnabled( not enabled and editor.m_Entity:netvar_get( "coilType" ) == "spring" )

    --     local cat = editor.Categories["shock model"].Categories
    --     for k, v in pairs( subs ) do
    --         if cat[v] then
    --             cat[v]:SetExpanded( enabled, not enabled )
    --             cat[v]:SetEnabled( enabled )
    --         end
    --     end
    --     for k, v in pairs( keys ) do
    --         if editor.Variables[v] then
    --             editor.Variables[v]:SetEnabled( enabled )
    --         end
    --     end
    -- end
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

local function setupscale_arm( self, csent, left, controller )
    csent:EnableMatrix( "RenderMultiply", self.scale_m )

    if left then
        csent:ManipulateBonePosition( 1, self.bone_1_length_l )
        csent:ManipulateBonePosition( 3, self.bone_3_length_l )
        csent:ManipulateBonePosition( 5, self.bone_5_length_l )
    else
        csent:ManipulateBonePosition( 1, self.bone_1_length_r )
        csent:ManipulateBonePosition( 3, self.bone_3_length_r )
        csent:ManipulateBonePosition( 5, self.bone_5_length_r )
    end

    csent:SetupBones()
end

function mode:onInit( controller )
    self:override( controller, true )

    local values = controller.netvar.values
    local data = self:getData( controller )

    data.scale = values.modelScale
    data.xwheel = values.xwheel
    data.ywheel = values.ywheel

    data.yarm = values.yarm
    data.zarm = values.zarm
    data.rarm = values.rarm
    data.arm_l1 = data.rarm
    data.arm_l2 = 1 - data.rarm

    data.spindle = self:addPart( controller, "spindle" )
    data.spindle:setmodel( "models/tanktracktool/suspension/linkage_spindle1.mdl" )
    data.spindle:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.spindle.my = -4 * data.scale
    data.spindle.mz = -3.33601 * data.scale
    data.spindle.le_anglocal.y = 90
    data.spindle.ri_anglocal.y = -90

    data.ujoint = self:addPart( controller, "ujoint" )
    data.ujoint:setmodel( "models/tanktracktool/suspension/linkage_ujoint.mdl" )
    data.ujoint:setscale( Vector( data.scale, data.scale, data.scale ) )

    data.arm = self:addPart( controller, "arm" )
    data.arm:setmodel( "models/tanktracktool/suspension/linkage_arm1.mdl" )
    data.arm:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.arm.le_anglocal = Angle( 0, -90, 180 )
    data.arm.ri_anglocal = Angle( 0, -90, 0 )

    data.arm.setupscale = setupscale_arm
    data.arm.bone_1_length_l = Vector()
    data.arm.bone_3_length_l = Vector()
    data.arm.bone_5_length_l = Vector()
    data.arm.bone_1_length_r = Vector()
    data.arm.bone_3_length_r = Vector()
    data.arm.bone_5_length_r = Vector()
end


function mode:onThink( controller )
    local e0, e1, e2 = GetEntities( controller )
    if not e0 or not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

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

    --local yaw = math.acos( e1:GetRight():Dot( m:GetForward() ) ) * ( 180 / math.pi ) - 90

    local offset = Vector( data.xwheel, pos_wheel_l.y + data.lwheel_width * data.ywheel + data.spindle.my, pos_wheel_l.z + data.spindle.mz )
    data.spindle:setwposangl( LocalToWorld( offset, data.spindle.le_anglocal, pos_chassis, ang_chassis ) )

    local offset = Vector( data.xwheel, pos_wheel_r.y - data.rwheel_width * data.ywheel - data.spindle.my, pos_wheel_r.z + data.spindle.mz )
    data.spindle:setwposangr( LocalToWorld( offset, data.spindle.ri_anglocal, pos_chassis, ang_chassis ) )

    data.ujoint:setparent( data.spindle, data.spindle )
    data.arm:setwposl( data.ujoint.le_posworld )
    data.arm:setwposr( data.ujoint.ri_posworld )


    local target = LocalToWorld( Vector( data.xwheel, math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.le_posworld )
    local offset = target - ( data.arm.le_posworld + normal:GetNormalized():Cross( fw_chassis ) )

    data.arm.le_anglocal.p = ( math.atan2( normal.z, normal.y ) - math.atan( data.scale / offset:Length() ) ) * ( 180 / math.pi )
    data.arm:setwangl( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.le_anglocal ) )

    local l = normal:Length()
    data.arm.bone_1_length_l.z = ( l * data.arm_l1 ) / data.scale - 4
    data.arm.bone_3_length_l.z = ( l * data.arm_l2 ) / data.scale - 4
    data.arm.bone_5_length_l.z = ( l * data.arm_l2 ) / data.scale - 4


    local target = LocalToWorld( Vector( data.xwheel, -math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm  ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.ri_posworld )
    local offset = target - ( data.arm.ri_posworld + normal:GetNormalized():Cross( fw_chassis ) )

    data.arm.ri_anglocal.p = ( math.atan2( normal.z, normal.y ) + math.atan( data.scale / offset:Length() ) ) * ( 180 / math.pi )
    data.arm:setwangr( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.ri_anglocal ) )

    local l = normal:Length()
    data.arm.bone_1_length_r.z = ( l * data.arm_l1 ) / data.scale - 4
    data.arm.bone_3_length_r.z = ( l * data.arm_l2 ) / data.scale - 4
    data.arm.bone_5_length_r.z = ( l * data.arm_l2 ) / data.scale - 4
end


local mat = Material( "cable/cable2" )
function mode:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    local data = self:getData( controller )


    -- render.DrawLine( data.matrix:GetTranslation(), data.matrix:GetTranslation() + data.matrix:GetForward() * 50, Color( 0, 255, 0, 150 ) )
    -- render.DrawLine( data.matrix:GetTranslation(), data.matrix:GetTranslation() + data.matrix:GetRight() * 50, Color( 255, 0, 0, 150 ) )
    -- render.DrawLine( data.matrix:GetTranslation(), data.matrix:GetTranslation() + data.matrix:GetUp() * 50, Color( 0, 0, 255, 150 ) )


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
