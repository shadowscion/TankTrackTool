
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
}

function ENT:netvar_setup()
    return netvar, default
end


/*



netvar:category( "Shock Absorber" )

netvar:subcategory( "Setup" )
netvar:var( "shocktype", "Combo", { def = 1, values = { spring = 1, cover = 2, none = 3 }, sort = SortedPairsByValue, title = "type" } )
netvar:var( "shocklencyl", "Float", { def = 24, min = 0, max = 1000, title = "cylinder length" } )
netvar:var( "shocklenret", "Float", { def = 0.5, min = 0, max = 1, title = "retainer offset" } )

netvar:subcategory( "Colors" )
netvar:var( "shockrodcolor", "Color", { def = "", title = "piston" } )
netvar:var( "shocktopcolor", "Color", { def = "", title = "top" } )
netvar:var( "shockbotcolor", "Color", { def = "", title = "bottom" } )
netvar:var( "shockcylcolor", "Color", { def = "", title = "cylinder" } )
netvar:var( "shockretcolor", "Color", { def = "", title = "retainer" } )
netvar:var( "shockwirecolor", "Color", { def = "", title = "coil" } )

netvar:subcategory( "Materials" )
netvar:var( "shockrodmat", "String", { def = "", title = "piston" } )
netvar:var( "shocktopmat", "String", { def = "", title = "top" } )
netvar:var( "shockbotmat", "String", { def = "", title = "bottom" } )
netvar:var( "shockcylmat", "String", { def = "", title = "cylinder" } )
netvar:var( "shockretmat", "String", { def = "", title = "retainer" } )
netvar:var( "shockwiremat", "String", { def = "", title = "coil" } )


--[[

netvar:category( "Setup" )
netvar:var( "modelScale", "Float", { def = 1, min = 0, max = 50 } )
netvar:var( "xwheel", "Float", { def = 0, min = 0, max = 1000, title = "wheel forward offset" } )
netvar:var( "ywheel", "Float", { def = 0, min = -1, max = 1, title = "wheel width offset" } )

netvar:category( "Swing Arm" )
netvar:var( "zarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot height" } )
netvar:var( "yarm", "Float", { def = 0, min = -1000, max = 1000, title = "pivot length" } )
netvar:var( "rarm", "Float", { def = 0, min = 0, max = 1, title = "length ratio" } )




netvar:category( "coil model" )
netvar:var( "coilType", "Combo", { def = 1, values = { spring = 1, cover = 2, none = 3 }, sort = SortedPairsByValue, title = "type" } )
netvar:var( "coilCol", "Color", { def = "", title = "color" } )
netvar:var( "coilMat", "String", { def = "", title = "material" } )
netvar:var( "coilCount", "Int", { def = 12 , min = 0, max = 50, title = "turn count" } )
netvar:var( "coilRadius", "Float", { def = 6, min = 0, max = 50, title = "coil radius" } )
netvar:var( "wireRadius", "Float", { def = 1 / 6, min = 0, max = 50, title = "wire radius" } )

netvar:category( "shock model" )
netvar:var( "shockEnable", "Bool", { def = 1, title = "enabled" } )
netvar:var( "shocklencyl", "Float", { def = 24, min = 0, max = 1000, title = "cylinder length" } )
netvar:var( "shocklenret", "Float", { def = 0.5, min = 0, max = 1, title = "coil attachment offset" } )

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

]]

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

    -- local keys = { "shocklencyl", "shocklenret", "modelScale" }
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
function tanktracktool.render.addshock( mode, controller )
    local self = { info = {} }

    mode:insertCSEnt( controller, "shock_tip", "shock_rod", "shock_bot", "shock_top", "shock_cylinder", "shock_retainer", "shock_cover" )

    self.info.type = "spring"
    self.info.scale = 1
    self.info.shocklencyl = 24
    self.info.shocklenret = 0.5
    self.info.coilCount = 12
    self.info.coilRadius = 2.1
    self.info.wireRadius = 1 / 2
    self.info.rodcolor = HSVToColor( 0, 1, 1 )
    self.info.topcolor = HSVToColor( 30, 1, 1 )
    self.info.botcolor = HSVToColor( 60, 1, 1 )
    self.info.cylcolor = HSVToColor( 90, 1, 1 )
    self.info.retcolor = HSVToColor( 120, 1, 1 )
    self.info.wirecolor = HSVToColor( 150, 1, 1 )

    function self:setnodraw( l, r )
        for k, v in pairs( self.parts ) do v:setnodraw( l, r ) end
    end

    function self:init( l, r )
        self.parts = ( l or r ) and {}
        if not self.parts then return end

        self.parts.tip1 = mode:addPart( controller, "shock_tip" )
        self.parts.tip1:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        self.parts.tip1:setscale( Vector( self.info.scale, self.info.scale, self.info.scale ) )
        self.parts.tip1:setcolor( self.info.rodcolor )

        self.parts.tip2 = mode:addPart( controller, "shock_tip" )
        self.parts.tip2:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        self.parts.tip2.le_anglocal.p = 180
        self.parts.tip2.ri_anglocal.p = 180
        self.parts.tip2:setscale( Vector( self.info.scale, self.info.scale, self.info.scale ) )
        self.parts.tip2:setcolor( self.info.rodcolor )

        if self.info.type == "cover" then
            self.parts.cover = mode:addPart( controller, "shock_cover" )
            self.parts.cover:setmodel( "models/tanktracktool/suspension/shock_cover1.mdl" )
            self.parts.cover.scale_v = Vector( self.info.scale, self.info.scale, self.info.scale )
            self.parts.cover.scale_l = Matrix()
            self.parts.cover.scale_r = Matrix()
            self.parts.cover.setupscale = function( part, csent, left, controller )
                csent:EnableMatrix( "RenderMultiply", left and part.scale_l or part.scale_r )
                csent:SetupBones()
            end
        else
            self.parts.rod = mode:addPart( controller, "shock_rod" )
            self.parts.rod:setmodel( "models/tanktracktool/suspension/shock_piston_rod.mdl" )
            self.parts.rod.le_poslocal.x = 1.5 * self.info.scale
            self.parts.rod.ri_poslocal.x = 1.5 * self.info.scale
            self.parts.rod.scale_v = Vector( self.info.scale, self.info.scale, self.info.scale )
            self.parts.rod.scale_l = Matrix()
            self.parts.rod.scale_r = Matrix()
            self.parts.rod.setupscale = function( part, csent, left, controller )
                csent:EnableMatrix( "RenderMultiply", left and part.scale_l or part.scale_r )
                csent:SetupBones()
            end
            self.parts.rod:setcolor( self.info.rodcolor )

            if self.info.type == "spring" then
                if l then
                    self.helix_l = tanktracktool.render.createCoil()
                    self.helix_l:setCoilCount( self.info.coilCount )
                    self.helix_l:setRadius( self.info.coilRadius * self.info.scale )
                    self.helix_l:setWireRadius( self.info.wireRadius * self.info.scale )
                    self.helix_l:setColor( self.info.wirecolor )
                end
                if r then
                    self.helix_r = tanktracktool.render.createCoil()
                    self.helix_r:setCoilCount( self.info.coilCount )
                    self.helix_r:setRadius( self.info.coilRadius * self.info.scale )
                    self.helix_r:setWireRadius( self.info.wireRadius * self.info.scale )
                    self.helix_r:setColor( self.info.wirecolor )
                end
            end
        end

        self.parts.bot = mode:addPart( controller, "shock_bot" )
        self.parts.bot:setmodel( "models/tanktracktool/suspension/shock_bottom1.mdl" )
        self.parts.bot.le_anglocal.p = 180
        self.parts.bot.ri_anglocal.p = 180
        self.parts.bot.le_poslocal.x = 3 * self.info.scale
        self.parts.bot.ri_poslocal.x = 3 * self.info.scale
        self.parts.bot:setscale( Vector( self.info.scale, self.info.scale, self.info.scale ) )
        self.parts.bot:setcolor( self.info.botcolor )

        self.parts.top = mode:addPart( controller, "shock_top" )
        self.parts.top:setmodel( "models/tanktracktool/suspension/shock_top1.mdl" )
        self.parts.top.le_poslocal.x = 1.25 * self.info.scale
        self.parts.top.ri_poslocal.x = 1.25 * self.info.scale
        self.parts.top:setscale( Vector( self.info.scale, self.info.scale, self.info.scale ) )
        self.parts.top:setcolor( self.info.topcolor )

        self.parts.cylinder = mode:addPart( controller, "shock_cylinder" )
        self.parts.cylinder:setmodel( "models/tanktracktool/suspension/shock_cylinder1.mdl" )
        self.parts.cylinder.le_poslocal.x = 3 * self.info.scale
        self.parts.cylinder.ri_poslocal.x = 3 * self.info.scale
        self.parts.cylinder:setscale( Vector( self.info.shocklencyl / 12, self.info.scale, self.info.scale ) )
        self.parts.cylinder:setcolor( self.info.cylcolor )

        self.parts.retainer = mode:addPart( controller, "shock_retainer" )
        self.parts.retainer:setmodel( "models/tanktracktool/suspension/shock_retainer1.mdl" )
        self.parts.retainer.le_poslocal.x = ( self.info.shocklencyl - ( 0.312768 * self.info.scale + 0.175 * ( self.info.shocklencyl / 12 ) ) ) * self.info.shocklenret
        self.parts.retainer.ri_poslocal.x = ( self.info.shocklencyl - ( 0.312768 * self.info.scale + 0.175 * ( self.info.shocklencyl / 12 ) ) ) * self.info.shocklenret
        self.parts.retainer:setscale( Vector( self.info.scale, self.info.scale, self.info.scale ) )
        self.parts.retainer:setcolor( self.info.retcolor )

        self:setnodraw( not l, not r )
    end

    function self:setcontrolpoints( lp1, lp2, rp1, rp2 )
        local parts = self.parts

        if lp1 and lp2 then
            local dir = lp2 - lp1
            local len = dir:Length()
            local ang = dir:Angle()

            parts.tip1:setwposangl( lp1, ang )

            parts.tip2.le_poslocal.x = len
            parts.tip2:setparent( parts.tip1, nil )

            if parts.rod then
                parts.rod.scale_v.x = ( len - 3 * self.info.scale ) / 24
                parts.rod.scale_l:SetScale( parts.rod.scale_v )
                parts.rod:setparent( parts.tip1, nil )
            end

            parts.bot:setparent( parts.tip1, nil )
            parts.top:setparent( parts.tip2, nil )
            parts.cylinder:setparent( parts.top, nil )
            parts.retainer:setparent( parts.cylinder, nil )

            if parts.cover then
                local len = ( parts.retainer.le_posworld - parts.bot.le_posworld ):Length()
                parts.cover.scale_v.x = len / 12
                parts.cover.scale_l:SetScale( parts.cover.scale_v )
                parts.cover:setparent( parts.retainer, nil )
            end

            if self.helix_l then
               self.helix_l:think( parts.retainer.le_posworld, parts.bot.le_posworld )
            end
        end

        if rp1 and rp2 then
            local dir = rp2 - rp1
            local len = dir:Length()
            local ang = dir:Angle()

            parts.tip1:setwposangr( rp1, ang )

            parts.tip2.ri_poslocal.x = len
            parts.tip2:setparent( nil, parts.tip1 )

            if parts.rod then
                parts.rod.scale_v.x = ( len - 3 * self.info.scale ) / 24
                parts.rod.scale_r:SetScale( parts.rod.scale_v )
                parts.rod:setparent( nil, parts.tip1 )
            end

            parts.bot:setparent( nil, parts.tip1 )
            parts.top:setparent( nil, parts.tip2 )
            parts.cylinder:setparent( nil, parts.top )
            parts.retainer:setparent( nil, parts.cylinder )

            if parts.cover then
                local len = ( parts.retainer.ri_posworld - parts.bot.ri_posworld ):Length()
                parts.cover.scale_v.x = len / 12
                parts.cover.scale_r:SetScale( parts.cover.scale_v )
                parts.cover:setparent( nil, parts.retainer )
            end

            if self.helix_r then
               self.helix_r:think( parts.retainer.ri_posworld, parts.bot.ri_posworld )
            end
        end
    end

    function self:render()
        if self.helix_l then self.helix_l:draw() end
        if self.helix_r then self.helix_r:draw() end
    end

    return self
end


--[[
]]
local mode = tanktracktool.render.mode()

function mode:onInit( controller )
    self:override( controller, true )

    local values = controller.netvar.values
    local data = self:getData( controller )

    local shock = tanktracktool.render.addshock( self, controller )
    data.shock = shock

    shock.info.type = values.shocktype
    -- shock.info.coilCount = 12
    -- shock.info.coilRadius = 2.1
    -- shock.info.wireRadius = 1 / 2

    shock.info.shocklencyl = values.shocklencyl
    shock.info.shocklenret = values.shocklenret
    shock.info.rodcolor = values.shockrodcolor
    shock.info.topcolor = values.shocktopcolor
    shock.info.botcolor = values.shockbotcolor
    shock.info.cylcolor = values.shockcylcolor
    shock.info.retcolor = values.shockretcolor
    shock.info.wirecolor = values.shockwirecolor



    data.shock:init( true, true )
end

function mode:onThink( controller )
    local data = self:getData( controller )

    local e0, e1, e2 = GetEntities( controller )
    if not e0 or not e1 or not e2 then
        self:setnodraw( controller, true )
        return
    end

    data.shock:setcontrolpoints( e1:GetPos(), e2:GetPos() )

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

*/


/*
mode:addCSent( "spindle", "ujoint", "arm", "wheel", "shock_piston_tip", "shock_piston_rod", "shock_top", "shock_cylinder", "shock_retainer", "shock_bottom" )

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

local function setupscale_arm2( self, csent, left, controller )
    csent:EnableMatrix( "RenderMultiply", self.scale_m )

    if left then
        csent:ManipulateBonePosition( 1, self.bone_1_length_l )
        csent:ManipulateBonePosition( 2, self.bone_2_length_l )
        csent:ManipulateBonePosition( 3, self.bone_3_length_l )
    else
        csent:ManipulateBonePosition( 1, self.bone_1_length_r )
        csent:ManipulateBonePosition( 2, self.bone_2_length_r )
        csent:ManipulateBonePosition( 3, self.bone_3_length_r )
    end

    csent:SetupBones()
end

local function randomColor()
    return HSVToColor( math.random( 0, 360 ), 0.75, 1 )
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
    data.spindle:setcolor( randomColor() )
    data.spindle.my = -4 * data.scale
    data.spindle.mz = -3.33601 * data.scale
    data.spindle.le_anglocal.y = 90
    data.spindle.ri_anglocal.y = -90

    data.ujoint = self:addPart( controller, "ujoint" )
    data.ujoint:setmodel( "models/tanktracktool/suspension/linkage_ujoint.mdl" )
    data.ujoint:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.ujoint:setcolor( randomColor() )

    data.arm = self:addPart( controller, "arm" )
    data.arm:setmodel( "models/tanktracktool/suspension/linkage_arm2.mdl" )
    data.arm:setscale( Vector( data.scale, data.scale, data.scale ) )
    data.arm.le_anglocal = Angle( 0, -90, 180 )
    data.arm.ri_anglocal = Angle( 0, -90, 0 )
    data.arm:setcolor( randomColor() )

    data.arm.setupscale = setupscale_arm2
    data.arm.bone_1_length_l = Vector()
    data.arm.bone_2_length_l = Vector()
    data.arm.bone_3_length_l = Vector()
    data.arm.bone_1_length_r = Vector()
    data.arm.bone_2_length_r = Vector()
    data.arm.bone_3_length_r = Vector()

--[[
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
]]


   --  data.wheel = self:addPart( controller, "wheel" )
   -- -- data.wheel:setscale( Vector( 1.5, 1.5, 1.5 ) )
   -- -- data.wheel:setcolor( Color( 255, 255, 255, 200 ) )
   --  data.wheel.le_poslocal = Vector( -data.spindle.my, 0, -data.spindle.mz )
   --  data.wheel.le_anglocal = Angle( 0, -90, 0 )
   --  data.wheel.ri_poslocal = Vector( -data.spindle.my, 0, -data.spindle.mz )
   --  data.wheel.ri_anglocal = Angle( 0, -90, 0 )

    values.colTop = randomColor()
    values.colCylinder = randomColor()
    values.colRetainer = randomColor()
    values.colPiston = randomColor()
    values.colBottom = randomColor()
    values.matTop = ""
    values.matCylinder = ""
    values.matRetainer = ""
    values.matPiston = ""
    values.matBottom = ""
    values.coilColor = randomColor()

    local factor = data.scale * 0.5
    if tobool( values.shockEnable ) then
        local shock = {}
        data.shock = shock
        shock.zpos = values.shocklencyl * 3

        -- any magic numbers below are from
        -- the model dimensions in blender

        shock.scalar = factor
        shock.shocklencyl = values.shocklencyl
        shock.shocklenret = ( shock.shocklencyl - ( 0.312768 * factor + 0.175 * ( shock.shocklencyl / 12 ) ) ) * values.shocklenret

        shock.piston_tip1 = self:addPart( controller, "shock_piston_tip" )
        shock.piston_tip1:setnodraw( false, false )
        shock.piston_tip1:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        shock.piston_tip1:setmaterial( values.matPiston )
        shock.piston_tip1:setcolor( values.colPiston )
        shock.piston_tip1:setscale( Vector( factor, factor, factor ) )

        shock.piston_tip2 = self:addPart( controller, "shock_piston_tip" )
        shock.piston_tip2:setnodraw( false, false )
        shock.piston_tip2:setmodel( "models/tanktracktool/suspension/shock_piston_tip1.mdl" )
        shock.piston_tip2:setmaterial( values.matPiston )
        shock.piston_tip2:setcolor( values.colPiston )
        shock.piston_tip2:setscale( Vector( factor, factor, factor ) )
        shock.piston_tip2.le_anglocal.p = 180
        shock.piston_tip2.ri_anglocal.p = 180

        if values.coilType == "cover" then
            shock.piston_cover = self:addPart( controller, "shock_piston_rod" )
            shock.piston_cover:setnodraw( false, false )
            shock.piston_cover:setmodel( "models/tanktracktool/suspension/shock_cover1.mdl" )
            shock.piston_cover:setmaterial( values.coilMat )
            shock.piston_cover:setcolor( values.coilCol )
            shock.piston_cover:setscale( Vector( factor, factor, factor ) )
            shock.piston_cover.le_poslocal.x = 0 * factor
            shock.piston_cover.ri_poslocal.x = 0 * factor
        else
            shock.piston_rod = self:addPart( controller, "shock_piston_rod" )
            shock.piston_rod:setnodraw( false, false )
            shock.piston_rod:setmodel( "models/tanktracktool/suspension/shock_piston_rod.mdl" )
            shock.piston_rod:setmaterial( values.matPiston )
            shock.piston_rod:setcolor( values.colPiston )
            shock.piston_rod:setscale( Vector( factor, factor, factor ) )
            shock.piston_rod.le_poslocal.x = 1.5 * factor
            shock.piston_rod.ri_poslocal.x = 1.5 * factor

            if values.coilType == "spring" and values.wireRadius > 0 and values.coilRadius > 0 and values.coilCount > 0 then
                data.helix = tanktracktool.render.createCoil()
                data.helix:setColor( randomColor() )--string.ToColor( values.coilCol ) )
                data.helix:setCoilCount( values.coilCount )
                data.helix:setDetail( 1 / 4 )
                data.helix:setRadius( 2.1 * factor )
                data.helix:setWireRadius( values.wireRadius * factor )
            end
        end

        shock.top = self:addPart( controller, "shock_top" )
        shock.top:setnodraw( false, false )
        shock.top:setmodel( "models/tanktracktool/suspension/shock_top2.mdl" )
        shock.top:setmaterial( values.matTop )
        shock.top:setcolor( values.colTop )
        shock.top:setscale( Vector( factor, factor, factor ) )
        shock.top.le_poslocal.x = 1.25 * factor
        shock.top.ri_poslocal.x = 1.25 * factor

        shock.cylinder = self:addPart( controller, "shock_cylinder" )
        shock.cylinder:setnodraw( false, false )
        shock.cylinder:setmodel( "models/tanktracktool/suspension/shock_cylinder1.mdl" )
        shock.cylinder:setmaterial( values.matCylinder )
        shock.cylinder:setcolor( values.colCylinder )
        shock.cylinder:setscale( Vector( shock.shocklencyl / 12, factor, factor ) )
        shock.cylinder.le_poslocal.x = 3 * factor
        shock.cylinder.ri_poslocal.x = 3 * factor

        shock.retainer = self:addPart( controller, "shock_retainer" )
        shock.retainer:setnodraw( false, false )
        shock.retainer:setmodel( "models/tanktracktool/suspension/shock_retainer1.mdl" )
        shock.retainer:setmaterial( values.matRetainer )
        shock.retainer:setcolor( values.colRetainer )
        shock.retainer:setscale( Vector( factor, factor, factor ) )
        shock.retainer.le_poslocal.x = shock.shocklenret
        shock.retainer.ri_poslocal.x = shock.shocklenret

        shock.bottom = self:addPart( controller, "shock_bottom" )
        shock.bottom:setnodraw( false, false )
        shock.bottom:setmodel( "models/tanktracktool/suspension/shock_bottom1.mdl" )
        shock.bottom:setmaterial( values.matBottom )
        shock.bottom:setcolor( values.colBottom )
        shock.bottom:setscale( Vector( factor, factor, factor ) )
        shock.bottom.le_poslocal.x = 3 * factor
        shock.bottom.le_anglocal.p = 180
        shock.bottom.ri_poslocal.x = 3 * factor
        shock.bottom.ri_anglocal.p = 180


    elseif values.coilType == "spring" and values.wireRadius > 0 and values.coilRadius > 0 and values.coilCount > 0 then

        -- data.helix = tanktracktool.render.createCoil()
        -- data.helix:setColor( string.ToColor( values.coilCol ) )
        -- data.helix:setCoilCount( values.coilCount )
        -- data.helix:setDetail( 1 / 4 )
        -- data.helix:setRadius( values.coilRadius )
        -- data.helix:setWireRadius( values.wireRadius )

    end








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


    data.spindle.le_anglocal.y = -math.acos( e1:GetRight():Dot( fw_chassis ) ) * ( 180 / math.pi ) + 180
    data.spindle.ri_anglocal.y = math.acos( e2:GetRight():Dot( fw_chassis ) ) * ( 180 / math.pi ) + 180

    local offset = Vector( data.xwheel, pos_wheel_l.y + data.lwheel_width * data.ywheel + data.spindle.my, pos_wheel_l.z + data.spindle.mz )
    data.spindle:setwposangl( LocalToWorld( offset, data.spindle.le_anglocal, pos_chassis, ang_chassis ) )

    local offset = Vector( data.xwheel, pos_wheel_r.y - data.rwheel_width * data.ywheel - data.spindle.my, pos_wheel_r.z + data.spindle.mz )
    data.spindle:setwposangr( LocalToWorld( offset, data.spindle.ri_anglocal, pos_chassis, ang_chassis ) )

    data.ujoint:setparent( data.spindle, data.spindle )
    data.arm:setwposl( data.ujoint.le_posworld )
    data.arm:setwposr( data.ujoint.ri_posworld )


    local target = LocalToWorld( Vector( data.xwheel, math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.le_posworld )

    data.arm.le_anglocal.p = math.atan2( normal.z, normal.y )* ( 180 / math.pi )
    data.arm:setwangl( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.le_anglocal ) )

    local l = normal:Length()
    data.arm.bone_1_length_l.z = -( l * data.arm_l1 ) / data.scale + 5.65
    data.arm.bone_2_length_l.z = -( l * data.arm_l2 ) / data.scale + 2.35
    data.arm.bone_3_length_l.z = -( l * data.arm_l2 ) / data.scale + 2.35


    local target = LocalToWorld( Vector( data.xwheel, -math.Clamp( data.yarm, pos_wheel_r.y, pos_wheel_l.y ), data.zarm ), Angle(), pos_chassis, ang_chassis )
    local normal = tanktracktool.util.toLocalAxis( pos_chassis, ang_chassis, target - data.arm.ri_posworld )

    data.arm.ri_anglocal.p = math.atan2( normal.z, normal.y )* ( 180 / math.pi )
    data.arm:setwangr( tanktracktool.util.toWorldAng( pos_chassis, ang_chassis, data.arm.ri_anglocal ) )

    local l = normal:Length()
    data.arm.bone_1_length_r.z = -( l * data.arm_l1 ) / data.scale + 5.65
    data.arm.bone_2_length_r.z = -( l * data.arm_l2 ) / data.scale + 2.35
    data.arm.bone_3_length_r.z = -( l * data.arm_l2 ) / data.scale + 2.35

    --[[
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
    ]]


    -- data.wheel.le_angworld = e1:GetAngles()
    -- data.wheel.ri_angworld = e2:GetAngles()
    -- data.wheel.le_posworld = LocalToWorld( data.wheel.le_poslocal, data.wheel.le_anglocal, data.spindle.le_posworld, data.spindle.le_angworld )
    -- data.wheel.ri_posworld = LocalToWorld( data.wheel.ri_poslocal, data.wheel.ri_anglocal, data.spindle.ri_posworld, data.spindle.ri_angworld )
    -- data.wheel.model = e1:GetModel()





    local shock = data.shock
    if shock then
        local offset = Vector( data.xwheel, math.Clamp( data.yarm * 1.25, pos_wheel_r.y, pos_wheel_l.y ), shock.zpos )
        local pos1 = LocalToWorld( offset, Angle(), pos_chassis, ang_chassis )

        local pos2 = LocalToWorld( Vector( -0.5 * data.scale, 0, 5.95796 * data.scale ), Angle(), data.spindle.le_posworld, data.spindle.le_angworld )
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
        -- if data.helix then
        --     local pos1 = e1:GetPos()
        --     local pos2 = e2:GetPos()

        --     data.helix:think( pos1, pos2 )
        -- end
    end







end


local mat = Material( "cable/cable2" )
function mode:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    local data = self:getData( controller )
    if data.helix then
        data.helix:draw()
    end
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
*/
