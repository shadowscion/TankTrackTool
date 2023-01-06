
--
local gui, cam, util, math, mesh, table, string, render =
      gui, cam, util, math, mesh, table, string, render

local rawset, rawget, Vector, Angle, worldToLocal, LocalToWorld, FrameTime, EffectData =
      rawset, rawget, Vector, Angle, WorldToLocal, LocalToWorld, FrameTime, EffectData

local table_insert = table.insert

local mesh_Begin, mesh_End, mesh_Position, mesh_TexCoord, mesh_Normal, mesh_AdvanceVertex =
      mesh.Begin, mesh.End, mesh.Position, mesh.TexCoord, mesh.Normal, mesh.AdvanceVertex

local render_SetMaterial, render_SetColorModulation =
      render.SetMaterial, render.SetColorModulation

local math_Round, math_atan2, math_abs, math_sin, math_floor, math_ceil, math_max, math_min, math_Clamp =
      math.Round, math.atan2, math.abs, math.sin, math.floor, math.ceil, math.max, math.min, math.Clamp

local math_rad = math.pi / 180
local math_deg = 180 / math.pi

local _mvec = Vector()
local _mvec_set, _mvec_add, _mvec_dot, _mvec_rotate, _mvec_length, _mvec_distance =
      _mvec.Set, _mvec.Add, _mvec.Dot, _mvec.Rotate, _mvec.Length, _mvec.Distance

local _mang = Angle()
local _mang_forward, _mang_right, _mang_up =
      _mang.Forward, _mang.Right, _mang.Up

local _mmat = Matrix()
local _mmat_setTranslation, _mmat_setAngles =
      _mmat.SetTranslation, _mmat.SetAngles

local cv_md = CreateClientConVar( "tanktracktool_detail_max", "8", true, false, "maximum track render quality", 4, 16 )
local cv_ad = CreateClientConVar( "tanktracktool_detail_incr", "1", true, false, "enhance track render quality as speed increases" )

local tttlib = tttlib


--
local trackverts_lines = { 1, 3, 3, 4, 4, 2, 2, 6, 6, 5, 5, 1, 7, 8, 8, 8 }

local function grouser( y, z, side, yedge )
    local dir = Vector( 0, y * 0.5, 0 ) - Vector( 0, y * 0.375, z * 0.125 )
    dir:Normalize()
    dir = dir * ( yedge * y ) * side
    dir = dir + Vector( 0, y * 0.5, 0 )
    return dir
end

local trackverts_model = function( y, z, side, yguide, yedge )
    y = y * side

    local model = {
        -- edge
        Vector( 0, y * 0.5, 0 ),
        Vector( 0, -y * 0.5, 0 ),

        -- top mid
        Vector( 0, y * 0.375, z * 0.5 ),
        Vector( 0, -y * 0.375, z * 0.5 ),

        -- bot mid
        Vector( 0, y * 0.375, -z * 0.5 ),
        Vector( 0, -y * 0.375, -z * 0.5 ),

        -- guide
        Vector( 0, y * yguide * 0.375, z * 0.5 ),
        Vector( 0, y * yguide * 0.375, -z * 1.5 ),
     }

    if yedge ~= 0 then
        table.insert( model, grouser( y, z, side, yedge ) )
    end

    return model
end
local _angle = Angle()

local function bisect_spline( index, spline, tensor, detail, step )
    local p1 = rawget( spline, index )
    local d1 = rawget( spline, index + 1 ) - p1
    for b = 1, detail - 1 do
        table_insert( spline, index + b, p1 + d1 * ( b / detail ) + math_sin( step * b ) * tensor )
    end
    return detail - 1
end

local track_textures = {}
local function createTrackTexture( path )
    local folders = { "tanktracktool/autotracks/" }
    local diffuse

    for k, v in pairs( folders ) do
        local check = v .. path
        if track_textures[check] then
            return track_textures[check]
        end
        if file.Exists( string.format( "materials/%s.vtf", check ), "GAME" ) then
            path = check
            diffuse = string.format( "%s.vtf", check )
            break
        end
    end

    if not diffuse then
        diffuse = "hunter/myplastic"
    end

    local shader = {
        ["$basetexture"]         = diffuse,
        ["$alphatest"]           = "1",
        ["$nocull"]              = "1",
        ["$color2"]              = "[1 1 1]",
        ["$vertexcolor"]         = "1",
        ["$angle"]               = "0",
        ["$translate"]           = "[0.0 0.0 0.0]",
        ["$center"]              = "[0.0 0.0 0.0]",
        ["$newscale"]            = "[1.0 1.0 1.0]",
        ["Proxies"]              = {
            ["TextureTransform"] = {
                ["translateVar"] = "$translate",
                ["scaleVar"]     = "$newscale",
                ["rotateVar"]    = "$angle",
                ["centerVar"]    = "$center",
                ["resultVar"]    = "$basetexturetransform",
             },
         }
     }

    track_textures[path] = CreateMaterial( "ttctracks" .. path .. SysTime(), "VertexLitGeneric", shader )

    return track_textures[path]
end


--
function tttlib.tracks_setup( self )
    local values = self.ttdata_trackvalues

    local color = string.ToColor( values.trackColor )
    self.ttdata_tracks_color = Vector( color.r / 255, color.g / 255, color.b / 255 )

    self.ttdata_tracks_texture = createTrackTexture( values.trackMaterial )
    self.ttdata_tracks_textureres = values.trackRes * values.trackWidth
    self.ttdata_tracks_texturemap = 1 / self.ttdata_tracks_textureres

    self.ttdata_tracks_tension = 1 - values.trackTension
    self.ttdata_tracks_tensor  = Vector( 0, 0, -self.ttdata_tracks_tension * 3 )

    local side = 1
    if values.trackFlip ~= nil then
        if values.trackFlip ~= 0 then side = -1 else side = 1 end
    end

    self.ttdata_tracks_model_le = trackverts_model( values.trackWidth, values.trackHeight, side, values.trackGuideY, values.trackGrouser )
    self.ttdata_tracks_model_ri = trackverts_model( values.trackWidth, values.trackHeight, -side, values.trackGuideY, values.trackGrouser )

    self.ttdata_tracks_modelcount_le = #self.ttdata_tracks_model_le
    self.ttdata_tracks_modelcount_ri = #self.ttdata_tracks_model_ri

    self.ttdata_tracks_height = values.trackHeight

    self.ttdata_tracks_nodes_ri = {}
    self.ttdata_tracks_nodes_le = {}
    self.ttdata_tracks_nodescount_ri = 0
    self.ttdata_tracks_nodescount_le = 0

    self.ttdata_tracks_verts_ri = {}
    self.ttdata_tracks_verts_le = {}
    self.ttdata_tracks_vertscount_ri = 0
    self.ttdata_tracks_vertscount_le = 0

    self.ttdata_tracks_normals_ri = {}
    self.ttdata_tracks_normals_le = {}

    local trackHeight = values.trackHeight * 0.5
    for i = 1, #self.ttdata_parts do
        local part = self.ttdata_parts[i][1]

        local trackRadius = part.radius + trackHeight
        part.trackRadius = trackRadius
        part.trackHeight = trackRadius + trackHeight + 0.1
    end

    self.ttdata_tracks_ready = nil
end


--
function tttlib.tracks_think( self )
    local min_detail = 6
    local max_detail = cv_md:GetInt()
    local adaptive_detail = cv_ad:GetBool()

    local tension_det = 2--math_ceil( tracknodesdetail / 2 )
    local tension_rad = ( 180 / tension_det ) * math_rad
    local tension_val = self.ttdata_tracks_tension
    local tension_dir = self.ttdata_tracks_tensor

    local trackroots = self.ttdata_parts
    local trackrootscount = #self.ttdata_parts

    local isdouble = self.ttdata_isdouble and 2 or 1

    if isdouble == 2 then
        self.ttdata_ri_lastrot = self.ttdata_ri_lastrot - self.ttdata_ri_lastvel / self.ttdata_tracks_textureres
    end
    self.ttdata_le_lastrot = self.ttdata_le_lastrot - self.ttdata_le_lastvel / self.ttdata_tracks_textureres

    for i = 1, isdouble do
        local tracknodes, tracknodesdetail

        if i == 2 then
            tracknodes = self.ttdata_tracks_nodes_ri
            tracknodesdetail = adaptive_detail and ( min_detail + math_floor( math_abs( self.ttdata_ri_lastvel ) * 2 ) ) or max_detail
        else
            tracknodes = self.ttdata_tracks_nodes_le
            tracknodesdetail = adaptive_detail and ( min_detail + math_floor( math_abs( self.ttdata_le_lastvel ) * 2 ) ) or max_detail
        end

        if tracknodesdetail > max_detail then
            tracknodesdetail = max_detail
        end

        local tracknodesdetailrad = 1 / ( 45 / tracknodesdetail )
        local tracknodescount = 0
        local switchdir = -1

        for rootid = 1, trackrootscount do
            -- local root0 = rawget( trackroots, rootid - 1 ) or rawget( trackroots, trackrootscount )
            -- local root1 = rawget( trackroots, rootid )
            -- local root2 = rawget( trackroots, rootid + 1 ) or rawget( trackroots, 1 )

            local root0 = rawget( trackroots, rootid == 1 and trackrootscount or rootid - 1 )[1]
            local root1 = rawget( trackroots, rootid )[1]
            local root2 = rawget( trackroots, rootid == trackrootscount and 1 or rootid + 1 )[1]

            local pos1 = root1[i]
            local rad1 = root1.trackRadius

            local dir0 = root0[i] - pos1
            local dir2 = root2[i] - pos1

            local atan0, atan2

            if dir2.x < 0 then
                atan2 = math_atan2( -dir2.x, -dir2.z ) * math_deg
                atan0 = math_atan2( dir0.x, dir0.z ) * math_deg
            else
                atan2 = math_atan2( dir2.x, dir2.z ) * math_deg
                atan0 = math_atan2( -dir0.x, -dir0.z ) * math_deg
                rad1 = -rad1
                switchdir = switchdir + 1
            end

            local count = tracknodesdetail
            if ( dir2.x > 0 ) ~= ( dir0.x > 0 ) then
                count = math_Round( math_abs( atan2 ) - math_abs( atan0 ) ) * tracknodesdetailrad
            end

            if count > 0 then
                for k = 0, count do -- produces odd wrapping on the first wheel...
                    _angle.p = atan0 + ( atan2 - atan0 ) * ( k / count )
                    tracknodescount = tracknodescount + 1
                    rawset( tracknodes, tracknodescount, pos1 + _mang_forward( _angle ) * rad1 )
                end
            else
                _angle.p = atan0 + ( atan2 - atan0 ) * 0.5
                tracknodescount = tracknodescount + 1
                rawset( tracknodes, tracknodescount, pos1 + _mang_forward( _angle ) * rad1 )
            end

            if switchdir > 0 and tension_val > 0 then
                -- there is something wrong with this
                tracknodescount = tracknodescount + bisect_spline( tracknodescount - math_floor( math_max( 0, count ) ) - 1, tracknodes, tension_dir, tension_det, tension_rad )
                -- a year later and i have no idea what
            end
        end

        if switchdir > 0 then
            rawset( tracknodes, tracknodescount + 1, rawget( tracknodes, 1 ) )
            if tension_val > 0 then
                tracknodescount = tracknodescount + bisect_spline( tracknodescount, tracknodes, tension_dir, tension_det, tension_rad )
            end
        else
            local node0 = rawget( tracknodes, tracknodescount )
            local node2 = rawget( tracknodes, 1 )
            local dir = node2 - node0

            local splitcount = trackrootscount
            local splitdroop = tension_val * ( splitcount - 2 ) * 2
            splitcount = splitcount - 1

            local splitcfold = 1 / splitcount
            local splitsteps = 180 * splitcfold

            for n = 1, splitcount - 1 do
                local node1 = node0 + dir * n * splitcfold

                if n < splitcount then
                    local root0 = trackroots[splitcount - n + 1][1]
                    local nextz = node1.z - math_sin( splitsteps * n * math_rad ) * splitdroop
                    local diffz = -( root0[i].z - nextz )
                    local radius = root0.trackRadius

                    if diffz < radius then
                        nextz = nextz + ( radius - diffz )
                    end

                    node1.z = nextz
                end

                tracknodescount = tracknodescount + 1
                rawset( tracknodes, tracknodescount, node1 )
            end

            rawset( tracknodes, tracknodescount + 1, rawget( tracknodes, 1 ) )
        end

        if i == 2 then self.ttdata_tracks_nodescount_ri = tracknodescount else self.ttdata_tracks_nodescount_le = tracknodescount end
    end

    --local trackmodel = self.ttdata_tracks_model
    --local trackmodelcount = self.ttdata_tracks_modelcount
    local trackresolution = self.ttdata_tracks_texturemap

    for i = 1, isdouble do
        local trackmodel, trackmodelcount, tracknodes, tracknodescount, trackverts, tracknormals

        if i == 2 then
            trackmodel = self.ttdata_tracks_model_ri
            trackmodelcount = self.ttdata_tracks_modelcount_ri
            tracknodes = self.ttdata_tracks_nodes_ri
            tracknodescount = self.ttdata_tracks_nodescount_ri
            trackverts = self.ttdata_tracks_verts_ri
            tracknormals = self.ttdata_tracks_normals_ri
        else
            trackmodel = self.ttdata_tracks_model_le
            trackmodelcount = self.ttdata_tracks_modelcount_le
            tracknodes = self.ttdata_tracks_nodes_le
            tracknodescount = self.ttdata_tracks_nodescount_le
            trackverts = self.ttdata_tracks_verts_le
            tracknormals = self.ttdata_tracks_normals_le
        end

        local trackvertscount = 0

        for nodeid = 1, tracknodescount do
            local node0 = rawget( tracknodes, nodeid - 1 ) or rawget( tracknodes, tracknodescount )
            local node1 = rawget( tracknodes, nodeid )
            local node2 = rawget( tracknodes, nodeid + 1 ) or rawget( tracknodes, 1 )

            local dir = node2 - node0

            _angle.p = math_atan2( -dir.z, dir.x ) * math_deg

            local normals = rawget( tracknormals, nodeid )
            if not normals then
                rawset( tracknormals, nodeid, { len = 0, up = Vector( 0, 0, 1 ), dn = Vector( 0, 0, -1 ), ri = Vector( 0, 1, 0 ) } )
                normals = rawget( tracknormals, nodeid )
            end

            normals.len = _mvec_distance( node1, node2 ) * trackresolution

            _mvec_set( normals.up, _mang_up( _angle ) )
            _mvec_set( normals.dn, -_mang_up( _angle ) )
            _mvec_set( normals.ri, _mang_right( _angle ) )

            for vertid = 1, trackmodelcount do
                trackvertscount = trackvertscount + 1

                local vertex = rawget( trackverts, trackvertscount )
                if not vertex then
                    rawset( trackverts, trackvertscount, Vector() )
                    vertex = rawget( trackverts, trackvertscount )
                end

                _mvec_set( vertex, rawget( trackmodel, vertid ) )
                _mvec_rotate( vertex, _angle )
                _mvec_add( vertex, node1 )

                rawset( trackverts, trackvertscount, vertex )
            end
        end

        for wrap = 1, trackmodelcount do
            trackvertscount = trackvertscount + 1

            local vertex = rawget( trackverts, trackvertscount )
            if not vertex then
                rawset( trackverts, trackvertscount, Vector() )
                vertex = rawget( trackverts, trackvertscount )
            end

            _mvec_set( vertex, rawget( trackverts, wrap ) )

            rawset( trackverts, trackvertscount, vertex )
        end

        if i == 2 then self.ttdata_tracks_vertscount_ri = trackvertscount else self.ttdata_tracks_vertscount_le = trackvertscount end
    end

    self.ttdata_tracks_ready = true
end


--
local matfallback = Material( "editor/wireframe" )
local flip1 = Vector( -1, -1, 1 )
local flip2 = Vector( 1, -1, 1 )

function tttlib.tracks_render( self )
    if not self.ttdata_tracks_ready then return end

    cam.PushModelMatrix( self.ttdata_matrix or self:GetWorldTransformMatrix() )

    local texture = self.ttdata_tracks_texture
    if texture and self.ttdata_tracks_color then
        texture:SetVector( "$color2", self.ttdata_tracks_color )
    end

    for i = 1, self.ttdata_isdouble and 2 or 1 do
        local tracknodes, tracknodescount, trackverts, trackvertscount, tracknormals, trackscroll
        local trackmodelcount

        if i == 2 then
            tracknodes = self.ttdata_tracks_nodes_ri
            tracknodescount = self.ttdata_tracks_nodescount_ri
            trackverts = self.ttdata_tracks_verts_ri
            trackvertscount = self.ttdata_tracks_vertscount_ri
            tracknormals = self.ttdata_tracks_normals_ri
            trackscroll = self.ttdata_ri_lastrot

            trackmodelcount = self.ttdata_tracks_modelcount_ri
        else
            tracknodes = self.ttdata_tracks_nodes_le
            tracknodescount = self.ttdata_tracks_nodescount_le
            trackverts = self.ttdata_tracks_verts_le
            trackvertscount = self.ttdata_tracks_vertscount_le
            tracknormals = self.ttdata_tracks_normals_le
            trackscroll = self.ttdata_le_lastrot

            trackmodelcount = self.ttdata_tracks_modelcount_le
        end

        local modelvertexoffset = trackmodelcount - 1
        local dogrouser = modelvertexoffset == 8

        -- if texture then
        --  texture:SetVector( "$newscale", i == 1 and flip1 or flip1 )
        -- end

        render_SetMaterial( texture or matfallback )

        mesh_Begin( MATERIAL_QUADS, tracknodescount * modelvertexoffset + modelvertexoffset )

        local ytrans = trackscroll or 0
        local yshift = 0

        for nodeid = 1, tracknodescount do
            local vertid = nodeid + ( nodeid - 1 ) * modelvertexoffset
            local normals = rawget( tracknormals, nodeid )

            if not normals or vertid + ( modelvertexoffset * 2 + 1 ) > trackvertscount then
                print( "skipping", nodeid, vertid, "this should not happen" )
                goto SKIP_NODE
            end


            local normal_up = normals.up or _mvec
            local normal_dn = normals.dn or _mvec
            local normal_ri = normals.ri or _mvec

            local yscale = normals.len or 0
            yshift = yshift - yscale

            local yfinal1 = ytrans + yshift
            local yfinal2 = yscale + yfinal1


            -- UPPER LEFT
            mesh_Position( trackverts[vertid + 2 + trackmodelcount] )
            mesh_TexCoord( 0, 0.143, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 2] )
            mesh_TexCoord( 0, 0.143, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid] )
            mesh_TexCoord( 0, 0, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + trackmodelcount] )
            mesh_TexCoord( 0, 0, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()


            -- UPPER RIGHT
            mesh_Position( trackverts[vertid + 1 + trackmodelcount] )
            mesh_TexCoord( 0, 1, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 1] )
            mesh_TexCoord( 0, 1, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 3] )
            mesh_TexCoord( 0, 0.857, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 3 + trackmodelcount] )
            mesh_TexCoord( 0, 0.857, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()


            -- UPPER MIDDLE
            mesh_Position( trackverts[vertid + 3 + trackmodelcount] )
            mesh_TexCoord( 0, 0.857, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 3] )
            mesh_TexCoord( 0, 0.857, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 2] )
            mesh_TexCoord( 0, 0.143, yfinal2 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 2 + trackmodelcount] )
            mesh_TexCoord( 0, 0.143, yfinal1 )
            mesh_Normal( normal_up )
            mesh_AdvanceVertex()


            -- LOWER LEFT
            mesh_Position( trackverts[vertid + trackmodelcount] )
            mesh_TexCoord( 0, 0, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid] )
            mesh_TexCoord( 0, 0, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 4] )
            mesh_TexCoord( 0, 0.143, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 4 + trackmodelcount] )
            mesh_TexCoord( 0, 0.143, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()


            -- LOWER RIGHT
            mesh_Position( trackverts[vertid + 5 + trackmodelcount] )
            mesh_TexCoord( 0, 0.857, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 5] )
            mesh_TexCoord( 0, 0.857, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 1] )
            mesh_TexCoord( 0, 1, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 1 + trackmodelcount] )
            mesh_TexCoord( 0, 1, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()


            -- LOWER MIDDLE
            mesh_Position( trackverts[vertid + 4 + trackmodelcount] )
            mesh_TexCoord( 0, 0.143, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 4] )
            mesh_TexCoord( 0, 0.143, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 5] )
            mesh_TexCoord( 0, 0.857, yfinal2 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 5 + trackmodelcount] )
            mesh_TexCoord( 0, 0.857, yfinal1 )
            mesh_Normal( normal_dn )
            mesh_AdvanceVertex()


            -- GUIDE
            mesh_Position( trackverts[vertid + 6 + trackmodelcount] )
            mesh_TexCoord( 0, 0.143, yfinal1 )
            mesh_Normal( normal_ri )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 6] )
            mesh_TexCoord( 0, 0.143, yfinal2 )
            mesh_Normal( normal_ri )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 7] )
            mesh_TexCoord( 0, 0, yfinal2 )
            mesh_Normal( normal_ri )
            mesh_AdvanceVertex()

            mesh_Position( trackverts[vertid + 7 + trackmodelcount] )
            mesh_TexCoord( 0, 0, yfinal1 )
            mesh_Normal( normal_ri )
            mesh_AdvanceVertex()


            -- GROUSER
            if dogrouser then
                mesh_Position( trackverts[vertid + trackmodelcount] )
                mesh_TexCoord( 0, 0.041, yfinal1 )
                mesh_Normal( normal_up )
                mesh_AdvanceVertex()

                mesh_Position( trackverts[vertid] )
                mesh_TexCoord( 0, 0.041, yfinal2 )
                mesh_Normal( normal_up )
                mesh_AdvanceVertex()

                mesh_Position( trackverts[vertid + 8] )
                mesh_TexCoord( 0, 0, yfinal2 )
                mesh_Normal( normal_up )
                mesh_AdvanceVertex()

                mesh_Position( trackverts[vertid + 8 + trackmodelcount] )
                mesh_TexCoord( 0, 0, yfinal1 )
                mesh_Normal( normal_up )
                mesh_AdvanceVertex()
            end

            ::SKIP_NODE::
        end

        mesh_End()
    end

    render_SetColorModulation( 1, 1, 1 )
    cam.PopModelMatrix()
end
