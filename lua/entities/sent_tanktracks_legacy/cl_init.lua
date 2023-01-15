
include( "shared.lua" )

local tanktracktool =  tanktracktool

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
    base ent
]]
local function real_radius( ent )
    if ent:GetHitBoxBounds( 0, 0 ) then
        local min, max = ent:GetHitBoxBounds( 0, 0 )
        local bounds = ( max - min ) * 0.5
        return math.max( bounds.x, bounds.y, bounds.z )
    end
    return ent:GetModelRadius() or 12
end

local function GetAngularVelocity( ent, pos, ang )
    local dir = WorldToLocal( ent:GetForward() + pos, ang, pos, ang )
    local ang = math.deg( math.atan2( dir.z, dir.x ) )

    ent.m_DeltaAngle = ent.m_DeltaAngle or 0

    local ang_vel = ( ang - ent.m_DeltaAngle + 180 ) % 360 - 180

    ent.m_DeltaAngle = ang

    return ang_vel --/ FrameTime()
end

local mode = tanktracktool.render.mode()

function mode:onInit( controller )
    local entities = controller.netvar.entities

    controller.autotracks_chassis = entities[1]
    if not IsValid( controller.autotracks_chassis ) or not table.IsSequential( entities ) then
        return false
    end

    local values = controller.netvar.values

    controller.autotracks_trackvalues = {
        trackColor = values.trackColor,
        trackMaterial = values.trackMaterial,
        trackWidth = values.trackWidth,
        trackHeight = values.trackHeight,
        trackGuideY = values.trackGuideY,
        trackGrouser = values.trackGrouser,
        trackTension = values.trackTension,
        trackRes = values.trackRes,
        trackFlip = values.trackFlip,
    }

    controller.autotracks_rotate = values.systemRotate ~= 0 and Angle( 0, -90, 0 ) or nil
    controller:autotracks_setMatrix()
    local pos, ang = controller:autotracks_getMatrix()

    controller.tanktracktool_modeData.parts = {}
    local parts = controller.tanktracktool_modeData.parts

    for i = 2, #entities do
        local wheel = entities[i]
        if IsValid( wheel ) then
            local part = { { entity = wheel, radius = real_radius( wheel ) } }
            part.index = table.insert( parts, part )
            part[1][1] = WorldToLocal( wheel:GetPos(), wheel:GetAngles(), pos, ang )
        end
    end

    if #parts == 0 then return false end

    local rollercount = 0
    for i = 1, #parts do
        local node_this = parts[i][1]
        local node_next = parts[i == #parts and 1 or i + 1][1]

        local offset = math.Clamp( rollercount > 0 and values.rollerRadius or values.wheelRadius, -node_this.radius * 2, node_this.radius * 2 )
        node_this.radius = node_this.radius + offset -- values.trackHeight * 0.25

        local dir_next = node_next[1] - node_this[1]
        if dir_next.x >= 0 then
            rollercount = rollercount + 1
        end
    end

    controller.autotracks_rollercount = rollercount
    controller.autotracks_trackoffset = parts[1][1][1].y + ( controller.autotracks_trackvalues.trackFlip ~= 0 and -1 or 1 ) * values.trackOffsetY
    controller.autotracks_sprocket = math.Clamp( values.wheelSprocket, 1, #parts )
    controller.autotracks_le_lastpos = controller.autotracks_le_lastpos or Vector()
    controller.autotracks_le_lastvel = controller.autotracks_le_lastvel or 1
    controller.autotracks_le_lastrot = controller.autotracks_le_lastrot or 1

    tanktracktool.autotracks.setup( controller )
    tanktracktool.autotracks.think( controller )

    self:override( controller, true )
end

function mode:updateTracks( controller, pos, ang )
    local parts = controller.tanktracktool_modeData.parts
    if not parts then return end

    local sprocket = controller.autotracks_sprocket

    for i = 1, #parts do
        local wheel = parts[i][1]
        local ent = wheel.entity

        if not IsValid( ent ) then
            controller.tanktracktool_reset = true
            return
        end

        wheel[1] = WorldToLocal( ent:GetPos(), ent:GetAngles(), pos, ang )
        wheel[1].y = controller.autotracks_trackoffset

        if i == sprocket then
            local rot_le = GetAngularVelocity( ent, pos, ang )
            controller.autotracks_le_lastvel = rot_le / ( math.pi * 1.5 ) -- no idea if this is correct nor why it works
        end
    end

    tanktracktool.autotracks.think( controller )

    return controller.autotracks_data_ready
end

function mode:onDraw( controller, eyepos, eyedir, empty )
    if not IsValid( controller ) then
        self:override( controller, false )
        return
    end
    if not IsValid( controller.autotracks_chassis ) then
        self:override( controller, false )
        return
    end

    if controller.autotracks_chassis:IsDormant() then return end

    controller:autotracks_setMatrix()
    local pos, ang = controller:autotracks_getMatrix()

    local dot = eyedir:Dot( pos - eyepos )
    if dot < 0 and math.abs( dot ) > 100 then return end

    if empty and self:updateTracks( controller, pos, ang ) then
        render.SetBlend( 0 )
        empty:SetPos( pos )
        empty:SetAngles( ang )
        empty:SetupBones()
        empty:DrawModel()
        render.SetBlend( 1 )

        tanktracktool.autotracks.render( controller, controller.autotracks_matrix )
    end
end

function ENT:autotracks_setMatrix()
    self.autotracks_matrix = self.autotracks_chassis:GetWorldTransformMatrix()
    if self.autotracks_rotate then
        self.autotracks_matrix:Rotate( self.autotracks_rotate )
    end
end

function ENT:autotracks_getMatrix()
    if not self.autotracks_matrix then
        return self.autotracks_chassis:GetPos(), self.autotracks_chassis:GetAngles()
    end
    return self.autotracks_matrix:GetTranslation(), self.autotracks_matrix:GetAngles()
end

function ENT:Think()
    self.BaseClass.Think( self )

    if self.tanktracktool_reset then
        self.tanktracktool_reset = nil
        mode:init( self )
        return
    end
end

function ENT:Draw()
    self:DrawModel()
end
