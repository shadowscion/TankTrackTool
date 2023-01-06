
local tttlib = tttlib
local sin, atan, icos = tttlib.sin, tttlib.atan, tttlib.icos

local LocalToWorld, WorldToLocal = LocalToWorld, WorldToLocal
local math = math

--
local mode = tttlib.mode( "torsion" )
mode.csents = { wheel = true, roller = true, arm = true, damper = true }

local render_multiply = "RenderMultiply"

local function damperbones_le( self )
    local csent = self.csent
    csent:EnableMatrix( render_multiply, self.bone0 )
    csent:ManipulateBonePosition( 1, self.bone1pos )
    csent:ManipulateBonePosition( 2, self.bone2pos_le )
    csent:SetupBones()
end

local function damperbones_ri( self )
    local csent = self.csent
    csent:EnableMatrix( render_multiply, self.bone0 )
    csent:ManipulateBonePosition( 1, self.bone1pos )
    csent:ManipulateBonePosition( 2, self.bone2pos_ri )
    csent:SetupBones()
end

local function setup_armbones( self )
    local csent = self.csent
    if self.type == 1 then
        csent:EnableMatrix( render_multiply, self.bone0 )
        csent:ManipulateBoneScale( 1, self.bone1scale )
        csent:ManipulateBoneScale( 2, self.bone2scale )
        csent:ManipulateBoneScale( 4, self.bone4scale )
        csent:ManipulateBoneScale( 5, self.bone5scale )
        csent:ManipulateBonePosition( 2, self.bone2pos )
        csent:ManipulateBonePosition( 3, self.bone3pos )
        csent:ManipulateBonePosition( 5, self.bone5pos )
    elseif self.type == 2 then
        csent:EnableMatrix( render_multiply, self.bone0 )
        csent:ManipulateBonePosition( 1, self.bone1pos )
        csent:ManipulateBonePosition( 2, self.bone2pos )
        csent:ManipulateBonePosition( 3, self.bone3pos )
        csent:ManipulateBonePosition( 4, self.bone4pos )
    end
    csent:SetupBones()
end

function mode:setup( ent, isdouble )
    tttlib.modes.classic.setup( self, ent, ent.ttdata_isdouble )

    local csents = ent.ttdata_csents
    local values = ent.NMEVals

    local xgap = values.suspensionX / ( values.wheelCount - 1 )
    local xpos = values.systemOffsetX
    local ypos = values.systemOffsetY
    local zpos = values.systemOffsetZ

    local parts = ent.ttdata_parts

    for i = 1, values.wheelCount do
        local part = parts[i == 1 and 1 or i == 2 and values.wheelCount or i - 1]
        local wheel = part[1]

        if not wheel or not wheel.suspension then
            goto CONTINUE
        end

        local specs = values.wheelTable[i]

        local arm = part:addcomponent( csents.arm )

        if values.suspensionType == "torsion" then arm.type = 1 elseif values.suspensionType == "bogie" then arm.type = 2 end
        if parts.numroadwheels % 2 ~= 0 and part.id == parts.lastroadwheel then arm.type = 1 end

        local color = string.ToColor( values.suspensionColor )
        arm.color = { r = color.r / 255, g = color.g / 255, b = color.b / 255, a = color.a / 255 }
        arm.material = tttlib.isValidMaterial( values.suspensionMaterial )

        arm.barangle = values.suspensionTAngle

        arm.barsize = values.suspensionTSize
        arm.barlengthbeam = values.suspensionTBeam
        arm.barlengthaxle = values.suspensionTAxle
        arm.barlengthconn = values.suspensionTConn

        local xmove = 0
        if arm.type == 1 then
            local interleave = values.suspensionInterleave
            local w = values.trackEnable ~= 0 and values.trackWidth or wheel.width

            local addlength = 0
            if interleave > 0 then
                if part.id % 2 == 0 then
                    addlength = interleave * w
                    arm.barlengthconn = arm.barlengthconn - arm.barsize * 0.5
                else
                    addlength = -interleave * w
                end
            elseif interleave < 0 then
                if part.id % 2 ~= 0 then
                    addlength = -interleave * w
                    arm.barlengthconn = arm.barlengthconn - arm.barsize * 0.5
                else
                    addlength = interleave * w
                end
            end

            arm.model = tttlib.isValidModel( "models/tanktracktool/torsionbar1.mdl" )

            arm.bone0 = Matrix()
            arm.bone0:SetScale( Vector( arm.barsize, arm.barsize / 2, arm.barsize ) )
            arm.bone0:SetAngles( Angle( 0, 180, 0 ) )

            local offset = wheel.width * 0.5 - ( wheel.y_offset or 0 ) + arm.barlengthaxle + math.max( 0, addlength + arm.barsize * 0.5 )
            if offset ~= 0 then
                arm.bone0:SetTranslation( Vector( 0, -offset, 0 ) )
            end

            local connrad = ( values.suspensionTConnRad * arm.barsize * 1 ) / arm.barsize
            arm.bone1scale = Vector( 1, connrad, connrad )
            arm.bone2scale = Vector( 1, connrad, connrad )

            arm.bone2pos = Vector( -1 + ( 2 * arm.barlengthconn ) / arm.barsize, 0, 0 )
            arm.bone3pos = Vector( 0, -2 + arm.barlengthbeam / arm.barsize, 0 )

            local axlerad = ( values.suspensionTAxleRad * arm.barsize * 1 ) / arm.barsize
            arm.bone4scale = Vector( 1, axlerad, axlerad )
            arm.bone5scale = Vector( 1, axlerad, axlerad )

            arm.bone5pos = Vector( -( offset * 2 - arm.barsize - wheel.width * 0.75 + addlength ) / arm.barsize, 0, 0 )

            if offset + arm.barlengthconn > values.suspensionY * 0.5 then
                xmove = arm.barsize * values.suspensionTConnRad * 0.25 + 0.125
            end
        else
            arm.csent = csents.bogie
            arm.model = tttlib.isValidModel( "models/tanktracktool/bogie1.mdl" )

            arm.barlengthbeam = math.max( wheel.radius, arm.barlengthbeam )
            if i % 2 ~= 0 then arm.barangle = -arm.barangle end

            local size = arm.barsize * 1.5

            arm.bone0 = Matrix()
            arm.bone0:SetScale( Vector( size, size / 2, size ) )
            arm.bone0:SetAngles( Angle( 0, 180, 0 ) )

            local offset = -( wheel.y_offset or 0 )
            if offset ~= 0 then
                arm.bone0:SetTranslation( Vector( 0, -offset, 0 ) )
            end

            arm.bone1pos = Vector( wheel.width / size, 0, 0 )
            arm.bone2pos = Vector( 0, -2 + arm.barlengthbeam / size, 0 )
            arm.bone3pos = Vector( -wheel.width / size, 0, 0 )
            arm.bone4pos = Vector( 0, -2 + arm.barlengthbeam / size, 0 )
        end

        arm.setupscale = setup_armbones

        --
        local x = xpos + xgap * wheel.spacing + values.suspensionX * 0.5 - xgap * ( part.id - 1 )
        local z = zpos - values.suspensionZ + ( values.suspensionZ - wheel.radius ) * specs.whnTraceZ + wheel.radius

        local normal = Vector( 0, 0, 1 )
        normal:Rotate( Angle( arm.barangle, 0, 0 ) )
        normal:Mul( values.suspensionTBeam )

        --
        arm.le_anglocal = Angle( values.suspensionTAngle + 180, 0, 0 )
        arm.le_poslocal = Vector( x - xmove, ypos + values.suspensionY * 0.5, z )
        arm.le_poslocal:Add( normal )

        arm.le_offsetX = Vector()
        arm.le_offsetK = sin( arm.barangle ) * arm.barlengthbeam
        arm.le_origin = Vector( wheel.le_poslocal )

        wheel.le_poslocal = Vector( 0, 0, arm.barlengthbeam )

        if isdouble then
            arm.ri_anglocal = Angle( -values.suspensionTAngle + 180, 180, 0 )
            arm.ri_poslocal = Vector( x + xmove, ypos - values.suspensionY * 0.5, z )
            arm.ri_poslocal:Add( normal )

            arm.ri_offsetX = Vector()
            arm.ri_offsetK = sin( arm.barangle ) * arm.barlengthbeam
            arm.ri_origin = Vector( wheel.ri_poslocal )

            wheel.ri_poslocal = Vector( 0, 0, arm.barlengthbeam )
            wheel.ri_anglocal.y = 0
        end

        -- dampers
        if values.suspensionTDamp ~= 0 then
            if part.id % values.suspensionTDamp == 0 then
                local damper = part:addcomponent( csents.damper )
                part.damper = damper

                damper.model = tttlib.isValidModel( "models/tanktracktool/spring1.mdl" )
                damper.color = arm.color
                damper.material = arm.material

                damper.bone0 = Matrix()
                damper.bone0:SetScale( Vector( arm.barsize, arm.barsize, arm.barsize ) )
                damper.bone0:SetAngles( Angle( 0, 180, 0 ) )

                if arm.type == 1 then
                    damper.bone0:SetTranslation( arm.bone0:GetTranslation() )
                    damper.bone0:Translate( Vector( 0, 0.25, 0 ) )
                else
                    damper.bone0:SetTranslation( arm.bone0:GetTranslation() )
                    damper.bone0:Translate( Vector( 0, ( wheel.width * 0.5 + arm.barsize ) / arm.barsize - 0.125, 0 ) )
                end

                local length = 0.5 * values.suspensionZ * ( 1 - values.suspensionTDampZ )

                damper.zlength = ( ( values.suspensionZ * values.suspensionTDampZ ) / 4 ) / arm.barsize
                damper.bone1pos = Vector( 0, damper.zlength - 2, 0 )
                damper.bone2pos_le = Vector( 0, 0, 0 )

                damper.setupscale = damperbones_le
                damper.le_poslocal.z = wheel.radius
                damper.le_poslocal:Rotate( Angle( -arm.barangle, 0, 0 ) )
                damper.le_poslocal.z = zpos - length
                damper.le_poslocal.x = damper.le_poslocal.x + arm.le_origin.x
                damper.le_poslocal.y = arm.le_poslocal.y

                if isdouble then
                    damper.bone2pos_ri = Vector( 0, 0, 0 )
                    damper.setupscale_ri = damperbones_ri
                    damper.ri_poslocal.z = wheel.radius
                    damper.ri_poslocal:Rotate( Angle( -arm.barangle, 0, 0 ) )
                    damper.ri_poslocal.z = zpos - length
                    damper.ri_poslocal.x = damper.ri_poslocal.x + arm.ri_origin.x
                    damper.ri_poslocal.y = arm.ri_poslocal.y
                    damper.ri_anglocal.y = 180
                end
            end
        end

        ::CONTINUE::
    end
end

local _mvec = Vector()
local _mang = Angle()

local pos_le, vel_le, rot_le
local pos_ri, vel_ri, rot_ri
local _empty

function mode:think( ent, isdouble )
    local pos, ang = ent:ttfunc_getmatrix()
    local up, ri, fo = ang:Up(), ang:Right(), ang:Forward()

    local trace_len, trace_dir

    local values = ent.NMEVals

    pos_le = pos - ri * values.suspensionY

    if ent:GetNW2Bool( "leftBrake", false ) then
        rot_le = 0
        vel_le = 0
    else
        local override = ent:GetNW2Float( "leftScroll", 0 )
        vel_le = override ~= 0 and -override or fo:Dot( ent.ttdata_le_lastpos - pos_le )
        rot_le = vel_le * 360
    end

    ent.ttdata_le_lastpos = pos_le
    ent.ttdata_le_lastvel = vel_le

    if isdouble then
        pos_ri = pos + ri * values.suspensionY

        if ent:GetNW2Bool( "rightBrake", false ) then
            rot_le = 0
            vel_le = 0
        else
            local override = ent:GetNW2Float( "rightScroll", 0 )
            vel_ri = override ~= 0 and -override or fo:Dot( ent.ttdata_ri_lastpos - pos_ri )
            rot_ri = vel_ri * 360
        end

        ent.ttdata_ri_lastpos = pos_ri
        ent.ttdata_ri_lastvel = vel_ri
    end

    local fx_le, fx_ri = ent:ttfunc_getGroundFX( values.trackEnable and values.trackWidth or values.wheelWidth )
    local parts = ent.ttdata_parts

    for i = 1, #parts do
        local parts = parts[i]
        local wheel = parts[1]

        if not wheel.suspension then
            wheel.le_anglocal.p = wheel.le_anglocal.p - rot_le / wheel.circumference
            wheel.le_posworld, wheel.le_angworld = LocalToWorld( wheel.le_poslocal, wheel.le_anglocal, pos, ang )

            if isdouble then
                wheel.ri_anglocal.p = wheel.ri_anglocal.p + rot_ri / wheel.circumference
                wheel.ri_posworld, wheel.ri_angworld = LocalToWorld( wheel.ri_poslocal, wheel.ri_anglocal, pos, ang )

            end

            goto GOTS_NO_ARMS
        end

        --[[

            everything below is a complete disaster and should probably be all be redone to
            use local coordinates or matrices or something

        ]]

        local arm = parts[2]

        if trace_len ~= wheel.trace_len then
            trace_len = wheel.trace_len
            trace_dir = trace_len * up
        end

        local arm_length = arm.barlengthbeam
        local wheel_radius = values.trackEnable and wheel.trackHeight or wheel.radius


        -- LEFT SIDE
        -- trace from arm origin to ground
        local wheel_trace = wheel.le_trace
        wheel_trace.start = LocalToWorld( arm.le_origin - arm.le_offsetX, _mang, pos, ang )
        wheel_trace.endpos = wheel_trace.start - trace_dir

        local trace = util.TraceHull( wheel_trace )
        if fx_le and trace.Hit then ent:ttfunc_playGroundFX( trace.HitPos, fx_le ) end

        -- update the arm's world position
        arm.le_posworld = LocalToWorld( arm.le_poslocal, _mang, pos, ang )

        local arm_pos_w = arm.le_posworld
        local arm_ang_l = arm.le_anglocal

        -- inverse kinematics to solve the arm angle
        local diff = trace.HitPos - arm_pos_w
        local dist = math.min( diff:Length(), arm_length + wheel_radius )
        local axis = WorldToLocal( diff + pos, _mang, pos, ang )

        arm_ang_l.p = atan( axis.x, axis.z ) + icos( dist, arm_length, wheel_radius ) * ( arm.le_offsetK > 0 and 1 or -1 )

        -- protect against divide by zero
        if arm_ang_l.p ~= arm_ang_l.p then arm_ang_l.p = 0 end

        -- update the arm's world angle
        _empty, arm.le_angworld = LocalToWorld( _mvec, arm_ang_l, pos, ang )

        -- forward kinematics to adjust the trace position in the next tick
        arm.le_offsetX.x = -sin( arm_ang_l.p ) * arm_length - arm.le_offsetK

        -- position wheel at the end of the arm
        local wheel_ang_l = wheel.le_anglocal

        wheel_ang_l.p = wheel_ang_l.p - rot_le / wheel.circumference
        wheel.le_posworld, wheel.le_angworld = LocalToWorld( wheel.le_poslocal, wheel_ang_l, arm_pos_w, arm.le_angworld )

        -- hacky localized vector used by the track renderer written for the old system, I hate it but I'm not redoing it
        wheel[1], _ = WorldToLocal( wheel.le_posworld, _mang, pos, ang )

        -- damper
        local damper = parts.damper
        if damper then
            damper.le_posworld = LocalToWorld( damper.le_poslocal, _mang, pos, ang )

            local diff = wheel.le_posworld - damper.le_posworld
            local axis = WorldToLocal( diff + pos, _mang, pos, ang )

            damper.le_anglocal.p = atan( axis.x, axis.z )
            _empty, damper.le_angworld = LocalToWorld( _mvec, damper.le_anglocal, pos, ang )
            damper.bone2pos_le.y = ( diff:Length() ) / arm.barsize - damper.zlength - 1
        end


        -- RIGHT SIDE
        if isdouble then
            -- trace from arm origin to ground
            local wheel_trace = wheel.ri_trace
            wheel_trace.start, _empty = LocalToWorld( arm.ri_origin + arm.ri_offsetX, _mang, pos, ang )
            wheel_trace.endpos = wheel_trace.start - trace_dir

            local trace = util.TraceHull( wheel_trace )
            if fx_ri and trace.Hit then ent:ttfunc_playGroundFX( trace.HitPos, fx_ri ) end

            -- update the arm's world position
            arm.ri_posworld = LocalToWorld( arm.ri_poslocal, _mang, pos, ang )

            local arm_pos_w = arm.ri_posworld
            local arm_ang_l = arm.ri_anglocal

            -- inverse kinematics to solve the arm angle
            local diff = trace.HitPos - arm_pos_w
            local dist = math.min( diff:Length(), arm_length + wheel_radius )
            local axis = WorldToLocal( diff + pos, _mang, pos, ang )

            arm_ang_l.p = atan( -axis.x, axis.z ) - icos( dist, arm_length, wheel_radius ) * ( arm.ri_offsetK > 0 and 1 or -1 )

            -- protect against divide by zero
            if arm_ang_l.p ~= arm_ang_l.p then arm_ang_l.p = 0 end

            -- update the arm's world angle
            _empty, arm.ri_angworld = LocalToWorld( _mvec, arm_ang_l, pos, ang )

            -- forward kinematics to adjust the trace position in the next tick
            arm.ri_offsetX.x = -sin( arm_ang_l.p ) * arm_length + arm.ri_offsetK

            -- position wheel at the end of the arm
            local wheel_ang_l = wheel.ri_anglocal

            wheel_ang_l.p = wheel_ang_l.p + rot_ri / wheel.circumference
            wheel.ri_posworld, wheel.ri_angworld = LocalToWorld( wheel.ri_poslocal, wheel_ang_l, arm_pos_w, arm.ri_angworld )

            -- hacky localized vector used by the track renderer written for the old system, I hate it but I'm not redoing it
            wheel[2], _ = WorldToLocal( wheel.ri_posworld, _mang, pos, ang )

            if damper then
                damper.ri_posworld = LocalToWorld( damper.ri_poslocal, _mang, pos, ang )

                local diff = wheel.ri_posworld - damper.ri_posworld
                local axis = WorldToLocal( diff + pos, _mang, pos, ang )

                damper.ri_anglocal.p = atan( -axis.x, axis.z )
                _empty, damper.ri_angworld = LocalToWorld( _mvec, damper.ri_anglocal, pos, ang )
                damper.bone2pos_ri.y = ( diff:Length() ) / arm.barsize - damper.zlength - 1
            end
        end

        ::GOTS_NO_ARMS::
    end
end


--
local mode = tttlib.mode( "bogie" )
mode.csents = { wheel = true, roller = true, arm = true, damper = true, bogie = true }

function mode:setup( ent, isdouble )
    return tttlib.modes.torsion.setup( self, ent, isdouble )
end
function mode:think( ent, isdouble )
    return tttlib.modes.torsion.think( self, ent, isdouble )
end
