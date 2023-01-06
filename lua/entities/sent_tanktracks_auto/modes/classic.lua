
local tttlib = tttlib

local LocalToWorld, WorldToLocal = LocalToWorld, WorldToLocal
local math = math

local mode = tttlib.tracks_addMode( "classic" )
mode.csents = { wheel = true, roller = true }

function mode:setup( ent, isdouble )
    local csents = ent.ttdata_csents
    local values = ent.NMEVals

    local xgap = values.suspensionX / ( values.wheelCount - 1 )
    local xpos = values.systemOffsetX
    local ypos = values.systemOffsetY
    local zpos = values.systemOffsetZ

    ent.ttdata_parts.numroadwheels = 0
    ent.ttdata_parts.lastroadwheel = 0

    for i = 1, values.wheelCount do
        local part = self:addpart( ent, i == 1 and 1 or i == 2 and values.wheelCount or i - 1 )

        local wheel = part:addcomponent( csents.wheel )
        local specs = values.wheelTable[i]

        wheel.useTable = specs.whnOverride ~= 0

        -- get info from spectable or use globals?
        local model, bodygroup, radius, width, color, material
        if wheel.useTable then
            model, bodygroup, radius, width, color, material =
            specs.whnModel, specs.whnBodygroup, specs.whnRadius, specs.whnWidth, specs.whnColor, specs.whnMaterial
        else
            model, bodygroup, radius, width, color, material =
            values.wheelModel, values.wheelBodygroup, values.wheelRadius, values.wheelWidth, values.wheelColor, values.wheelMaterial
        end

        -- setup wheel info
        wheel.model, wheel.bodygroup, wheel.submaterials, wheel.scale, wheel.scalar, wheel.mins, wheel.maxs =
        tttlib.fixWheel( wheel.csent, model, bodygroup, material, radius, width )

        wheel.width = width
        wheel.radius = radius
        wheel.circumference = math.max( 0.0001, 2 * math.pi * radius )

        color = string.ToColor( color )
        wheel.color = { r = color.r/255, g = color.g/255, b = color.b/255, a = color.a/255 }

        if wheel.submaterials.base then
            wheel.material = wheel.submaterials.base
            wheel.submaterials = nil
        end

        if specs.whnSuspension ~= 0 then
            wheel.suspension = true
        end

        -- interleaving alternately spaces the wheels on the y axis, disabled in bogie mode
        local interleave = 0
        if wheel.suspension and values.suspensionType ~= "bogie" then
            interleave = ( part.id % 2 == 0 and 1 or -1 ) * values.suspensionInterleave
        end

        -- custom y axis spacing
        local clamp = values.trackEnable ~= 0 and values.trackWidth * 0.5 or wheel.width * 0.5
        local y_offset = math.Clamp( ( specs.whnOffsetY + interleave ) * clamp, -clamp, clamp )
        if y_offset ~= 0 then
            wheel.y_offset = y_offset
            wheel.scale:SetTranslation( Vector( 0, y_offset, 0 ) )
        end

        --
        if wheel.suspension then
            ent.ttdata_parts.numroadwheels = ent.ttdata_parts.numroadwheels + 1
            ent.ttdata_parts.lastroadwheel = part.id

            wheel.trace_len = values.suspensionZ - ( values.suspensionZ - radius ) * specs.whnTraceZ

            local maxs = Vector( radius, radius, 0 ) * 0.5
            local mins = -maxs

            wheel.le_trace = { mask = MASK_SOLID_BRUSHONLY, maxs = maxs, mins = mins }
            if isdouble then
                wheel.ri_trace = { mask = MASK_SOLID_BRUSHONLY, maxs = maxs, mins = mins }
            end

            wheel.le_poslocal.z = zpos

            wheel.spacing = specs.whnOffsetX * 0.5
            local pairgap = tttlib.map( values.suspensionPairGap, -1, 1, -0.5, 0.5 )
            wheel.spacing = wheel.spacing + ( part.id % 2 == 0 and -pairgap or pairgap ) * ( 1 - ( wheel.spacing % 1 ) ) * 0.5
        else
            wheel.le_poslocal.z = zpos + math.max( -values.suspensionZ + radius, specs.whnOffsetZ )

            wheel.spacing = specs.whnOffsetX * 0.5
        end

        wheel.le_poslocal.x = xpos + values.suspensionX * 0.5 - xgap * ( part.id - 1 ) + xgap * wheel.spacing
        --wheel.le_poslocal.x = xpos + values.suspensionX * 0.5 - xgap * ( part.id - 1 ) + xgap * specs.whnOffsetX * 0.5
        wheel.le_poslocal.y = ypos + values.suspensionY * 0.5

        wheel[1] = Vector( wheel.le_poslocal )

        if isdouble then
            wheel.ri_poslocal.x = wheel.le_poslocal.x
            wheel.ri_poslocal.y = ypos - values.suspensionY * 0.5
            wheel.ri_poslocal.z = wheel.le_poslocal.z
            wheel.ri_anglocal.y = 180

            wheel[2] = Vector( wheel.ri_poslocal )
        end
    end

    local wheel1 = ent.ttdata_parts[1][1]
    local wheel2 = ent.ttdata_parts[values.wheelCount][1]
    local wheelDiff = ( wheel1.le_poslocal - wheel2.le_poslocal ):Cross( Vector( 0, 1, 0 ) ):GetNormalized()

    for i = 1, values.rollerCount do
        local part = self:addpart( ent, values.wheelCount + ( values.rollerCount - i + 1 ) )

        local roller = part:addcomponent( csents.roller )
        local specs = values.rollerTable[i]

        roller.useTable = specs.ronOverride ~= 0

        -- get info from spectable or use globals?
        local model, bodygroup, radius, width, color, material
        if roller.useTable then
            model, bodygroup, radius, width, color, material =
            specs.ronModel, specs.ronBodygroup, specs.ronRadius, specs.ronWidth, specs.ronColor, specs.ronMaterial
        else
            model, bodygroup, radius, width, color, material =
            values.rollerModel, values.rollerBodygroup, values.rollerRadius, values.rollerWidth, values.rollerColor, values.rollerMaterial
        end

        -- setup roller info
        roller.model, roller.bodygroup, roller.submaterials, roller.scale, roller.scalar, roller.mins, roller.maxs =
        tttlib.fixWheel( roller.csent, model, bodygroup, material, radius, width )

        roller.width = width
        roller.radius = radius
        roller.circumference = math.max( 0.0001, 2 * math.pi * radius )

        color = string.ToColor( color )
        roller.color = { r = color.r / 255, g = color.g / 255, b = color.b / 255, a = color.a / 255 }

        if roller.submaterials.base then
            roller.material = roller.submaterials.base
            roller.submaterials = nil
        end

        -- custom y axis spacing
        local clamp = values.trackEnable ~= 0 and values.trackWidth * 0.5 or roller.width * 0.5
        local y_offset = math.Clamp( specs.ronOffsetY * clamp, -clamp, clamp )
        if y_offset ~= 0 then
            roller.scale:SetTranslation( Vector( 0, y_offset, 0 ) )
        end

        --
        local lerp = LerpVector( ( i - 0.5 - specs.ronOffsetX * 0.5 ) / values.rollerCount, wheel1.le_poslocal, wheel2.le_poslocal )
        roller.le_poslocal.x = lerp.x
        roller.le_poslocal.y = lerp.y

        if values.rollerLocalZ ~= 0 then
            roller.le_poslocal.z = lerp.z
            roller.le_poslocal:Add( wheelDiff * ( specs.ronOffsetZ + values.rollerOffsetZ ) ) -- this needs to be clamped along this axis somehow
        else
            roller.le_poslocal.z = lerp.z + specs.ronOffsetZ + values.rollerOffsetZ
        end

        roller.le_poslocal.z = math.max( roller.le_poslocal.z, zpos - values.suspensionZ + radius )

        roller[1] = Vector( roller.le_poslocal )

        if isdouble then
            roller.ri_poslocal.x = roller.le_poslocal.x
            roller.ri_poslocal.y = ypos - values.suspensionY * 0.5
            roller.ri_poslocal.z = roller.le_poslocal.z
            roller.ri_anglocal.y = 180

            roller[2] = Vector( roller.ri_poslocal )
        end
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
    local wheel_rad, wheel_dir

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

        local enabled = wheel.suspension
        if enabled then
            if trace_len ~= wheel.trace_len then
                trace_len = wheel.trace_len
                trace_dir = -trace_len * up
            end
            if wheel_rad ~= wheel.radius then
                wheel_rad = wheel.radius
                wheel_dir = ( wheel.trackHeight or wheel_rad ) * up
            end
        end

        wheel.le_anglocal.p = wheel.le_anglocal.p - rot_le / wheel.circumference

        if enabled then
            wheel.le_trace.start, wheel.le_angworld = LocalToWorld( wheel.le_poslocal, wheel.le_anglocal, pos, ang )
            wheel.le_trace.endpos = wheel.le_trace.start + trace_dir

            local trace = util.TraceHull( wheel.le_trace )
            if fx_le and trace.Hit then ent:ttfunc_playGroundFX( trace.HitPos, fx_le ) end

            wheel.le_posworld = trace.HitPos + wheel_dir

            -- hacky localized vector used by the track renderer written for the old system, I hate it but I'm not redoing it
            wheel[1], _empty = WorldToLocal( wheel.le_posworld, _mang, pos, ang )
        else
            wheel.le_posworld, wheel.le_angworld = LocalToWorld( wheel.le_poslocal, wheel.le_anglocal, pos, ang )
        end

        if isdouble then
            wheel.ri_anglocal.p = wheel.ri_anglocal.p + rot_ri / wheel.circumference

            if enabled then
                wheel.ri_trace.start, wheel.ri_angworld = LocalToWorld( wheel.ri_poslocal, wheel.ri_anglocal, pos, ang )
                wheel.ri_trace.endpos = wheel.ri_trace.start + trace_dir

                local trace = util.TraceHull( wheel.ri_trace )
                if fx_ri and trace.Hit then ent:ttfunc_playGroundFX( trace.HitPos, fx_ri ) end

                wheel.ri_posworld = trace.HitPos + wheel_dir

                -- hacky localized vector used by the track renderer written for the old system, I hate it but I'm not redoing it
                wheel[2], _empty = WorldToLocal( wheel.ri_posworld, _mang, pos, ang )
            else
                wheel.ri_posworld, wheel.ri_angworld = LocalToWorld( wheel.ri_poslocal, wheel.ri_anglocal, pos, ang )
            end
        end
    end
end
