
--[[
]]
local tanktracktool = tanktracktool

local math, util, string, table, render =
      math, util, string, table, render

local next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector =
      next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector

tanktracktool.render = tanktracktool.render or { list = {}, edicts = 0, draws = {} }

if not IsValid( tanktracktool.render.empty ) then
    tanktracktool.render.empty = ClientsideModel( "models/props_c17/oildrum001_explosive.mdl" )
    tanktracktool.render.empty:SetNoDraw( true )
end


--[[
    core
]]
local draws, emptyCSENT = tanktracktool.render.draws, tanktracktool.render.empty
local eyepos, eyedir = Vector(), Vector()
local flashlightMODE

hook.Add( "PostDrawTranslucentRenderables", "tanktracktoolRenderDraw", function()
    flashlightMODE = LocalPlayer():FlashlightIsOn() --or #ents.FindByClass "*projectedtexture*" ~= 0
    eyepos = EyePos()
    eyedir = EyeVector()
    if FrameTime() == 0 or not next( draws ) then return end
    if not IsValid( emptyCSENT ) then
        tanktracktool.render.empty = ClientsideModel( "models/props_c17/oildrum001_explosive.mdl" )
        tanktracktool.render.empty:SetNoDraw( true )
        emptyCSENT = tanktracktool.render.empty
        return
    end
    for controller, mode in pairs( draws ) do
        if IsValid( controller ) then mode:draw( controller ) end
    end
end )

local function callOnRemove( controller )
    local self = controller
    local csents = controller.tanktracktool_modeData_csents
    local loud = tanktracktool.loud( tanktracktool.loud_ents )

    timer.Simple( 0, function()
        if self and IsValid( self ) then return end
        tanktracktool.render.list[self] = nil
        draws[self] = nil
        for k, v in pairs( csents ) do
            if loud then
                tanktracktool.note( string.format( "removing csent\nkey: %s\nent: %s\n", tostring( k ), tostring( self) ) )
            end
            v:Remove()
            tanktracktool.render.edicts = tanktracktool.render.edicts - 1
        end
    end )
end


--[[
    PARTS
]]
local function setlposl( self, pos ) self.le_poslocal = pos end

local function setlposr( self, pos ) self.ri_poslocal = pos end

local function setwposl( self, pos ) self.le_posworld = pos end

local function setwposr( self, pos ) self.ri_posworld = pos end

local function setlangl( self, ang ) self.le_anglocal = ang end

local function setlangr( self, ang ) self.ri_anglocal = ang end

local function setwangl( self, ang ) self.le_angworld = ang end

local function setwangr( self, ang ) self.ri_angworld = ang end

local function setlposangl( self, pos, ang ) self.le_poslocal, self.le_anglocal = pos, ang end

local function setlposangr( self, pos, ang ) self.ri_poslocal, self.ri_anglocal = pos, ang end

local function setwposangl( self, pos, ang ) self.le_posworld, self.le_angworld = pos, ang end

local function setwposangr( self, pos, ang ) self.ri_posworld, self.ri_angworld = pos, ang end

local function setparent( self, lpart, rpart )
    if lpart then self:setwposangl( LocalToWorld( self.le_poslocal, self.le_anglocal, lpart.le_posworld, lpart.le_angworld ) ) end
    if rpart then self:setwposangr( LocalToWorld( self.ri_poslocal, self.ri_anglocal, rpart.ri_posworld, rpart.ri_angworld ) ) end
end

local function setscale( self, scale )
    self.scale_v = Vector( scale )
    self.scale_m = Matrix()
    self.scale_m:SetScale( self.scale_v )
end

local function setscalemv( self, scalem, scalev )
    self.scale_m = Matrix( scalem )
    self.scale_v = Vector( scalev )
end

local function setnodraw( self, l, r )
    self.render_l = not l
    self.render_r = not r
end

local function setcolor( self, color )
    if isstring( color ) then color = string.ToColor( color ) end
    self.color = Color( color.r / 255, color.g / 255, color.b / 255, color.a / 255 )
end

local function setbodygroup( self, str ) self.bodygroup = isstring( str ) and str or nil end

local function setmodel( self, model ) self.model = tanktracktool.util.getModel( model ) end

local function setmaterial( self, material )
    self.material = nil
    self.submaterial = nil
    if isstring( material ) then
        self.material = tanktracktool.util.getMaterial( material )
        return
    end
    if istable( material ) then
        if material.base then
            self.material = tanktracktool.util.getMaterial( material.base )
            return
        end
        local m = {}
        for k, v in pairs( material ) do
            m[k] = tanktracktool.util.getMaterial( v )
        end
        self.submaterial = m
        return
    end
end

local function renderme( self, empty )
    local csent = self.csent
    if csent and ( self.render_l or self.render_r ) then
        local model = self.model
        if csent.model ~= model then
            csent.model = model
            csent:SetModel( model )
        end

        if self.bodygroup then
            csent:SetBodyGroups( self.bodygroup )
        else
            csent:SetBodyGroups( nil )
        end

        local color = self.color
        if color then
            csent.RenderGroup = color.a ~= 1 and RENDERGROUP_BOTH or RENDERGROUP_OPAQUE
            render.SetBlend( color.a )
            render.SetColorModulation( color.r, color.g, color.b )
        else
            csent.RenderGroup = RENDERGROUP_OPAQUE
            render.SetBlend( 1 )
            render.SetColorModulation( 1, 1, 1 )
        end

        if self.material then
            csent:SetSubMaterial( nil )
            csent:SetMaterial( self.material )
        else
            local submaterial = self.submaterial
            if submaterial then
                for s = 1, #submaterial do
                    csent:SetSubMaterial( s - 1, submaterial[s] )
                end
            else
                csent:SetSubMaterial( nil )
            end
            csent:SetMaterial( nil )
        end

        local doscale = not self.setupscale
        if doscale then
            if self.scale_m then
                csent:EnableMatrix( "RenderMultiply", self.scale_m )
            else
                csent:DisableMatrix( "RenderMultiply" )
            end
        end

        if self.render_l then
            if not doscale then self:setupscale( csent, true, controller ) end
            csent:SetPos( self.le_posworld )
            csent:SetAngles( self.le_angworld )
            csent:SetupBones()
            csent:DrawModel()
        end

        if self.render_r then
            if not doscale then self:setupscale( csent, false, controller ) end
            csent:SetPos( self.ri_posworld )
            csent:SetAngles( self.ri_angworld )
            csent:SetupBones()
            csent:DrawModel()
        end
    end
end

--[[
    metatable
]]
function tanktracktool.render.mode( TYPE_ASSEM, CSENTS )
    local meta = { csents = {}, TYPE_ASSEM = TYPE_ASSEM }

    function meta:override( controller, bDraw )
        draws[controller] = bDraw and self or nil
    end

    function meta:setnodraw( controller, bDraw )
        controller.tanktracktool_modeData_nodraw = bDraw
    end

    function meta:init( controller )
        tanktracktool.render.list[controller] = self
        draws[controller] = nil

        if not controller.tanktracktool_modeData_csents then controller.tanktracktool_modeData_csents = {} end
        local loud = tanktracktool.loud( tanktracktool.loud_ents )

        for k, v in pairs( self.csents ) do
            if not IsValid( controller.tanktracktool_modeData_csents[k] ) then
                local e = ents.CreateClientside( "base_anim" )
                controller.tanktracktool_modeData_csents[k] = e

                e.RenderGroup = RENDERGROUP_OPAQUE
                e:SetRenderMode( RENDERMODE_TRANSCOLOR )
                e:SetLOD( 0 )
                e:DrawShadow( false )
                e:SetNoDraw( true )
                e:SetPos( controller:GetPos() )

                if loud then
                    tanktracktool.note( string.format( "creating csent\nkey: %s\nent: %s\n", tostring( k ), tostring( controller ) ) )
                end

                tanktracktool.render.edicts = tanktracktool.render.edicts + 1
            end
        end

        controller.tanktracktool_modeData_nodraw  = nil
        controller.tanktracktool_modeData_audible = true -- can think
        controller.tanktracktool_modeData_visible = nil  -- can draw
        controller.tanktracktool_modeData = { parts = {}, data = {} }

        controller:CallOnRemove( "tanktracktoolRender", callOnRemove )

        if self:onInit( controller ) == false then return end
        self:think( controller )

        return self
    end

    function meta:draw( controller )
        if controller.tanktracktool_modeData_nodraw or not controller.tanktracktool_modeData_visible then return end
        self:onDraw( controller, eyepos, eyedir, emptyCSENT, flashlightMODE )
    end

    function meta:think( controller )
        if not controller.tanktracktool_modeData_audible then return end
        controller.tanktracktool_modeData_visible = true
        self:onThink( controller, eyepos, eyedir )
    end

    function meta:addCSent( ... )
        for k, name in pairs( { ... } ) do
            self.csents[name] = true
        end
    end

    function meta:getCSents( controller )
        return controller.tanktracktool_modeData_csents
    end

    function meta:getData( controller )
        return controller.tanktracktool_modeData.data
    end

    function meta:getParts( controller )
        return controller.tanktracktool_modeData.parts
    end

    function meta:addPart( controller, csentName, assem )
        if not TYPE_ASSEM then
            assem = nil
        else
            if not istable( assem ) then return end
        end

        local part = {
            type = part,
            csent = controller.tanktracktool_modeData_csents[csentName],
            model = "models/hunter/blocks/cube025x025x025.mdl",

            render_l = true,
            le_poslocal = Vector(),
            le_posworld = Vector(),
            le_anglocal = Angle(),
            le_angworld = Angle(),

            render_r = true,
            ri_poslocal = Vector(),
            ri_posworld = Vector(),
            ri_anglocal = Angle(),
            ri_angworld = Angle(),

            renderme = renderme,
            setlposl = setlposl,
            setlposr = setlposr,
            setwposl = setwposl,
            setwposr = setwposr,
            setlangl = setlangl,
            setlangr = setlangr,
            setwangl = setwangl,
            setwangr = setwangr,
            setlposangl = setlposangl,
            setlposangr = setlposangr,
            setwposangl = setwposangl,
            setwposangr = setwposangr,
            setparent = setparent,
            setbodygroup = setbodygroup,
            setmodel = setmodel,
            setscale = setscale,
            setscalemv = setscalemv,
            setnodraw = setnodraw,
            setmaterial = setmaterial,
            setcolor = setcolor,
        }

        part.index = table.insert( assem or controller.tanktracktool_modeData.parts, part )

        return part
    end

    if TYPE_ASSEM then
        local function addPart( self, controller, csent )
            return meta.addPart( meta, controller, csent, self )
        end

        function meta:addAssembly( controller, i )
            local assem = { index = i, parts = {}, addPart = addPart }
            controller.tanktracktool_modeData.parts[i] = assem
            return assem
        end

        function meta:renderParts( controller, eyepos, eyedir, empty )
            render.SetColorModulation( 1, 1, 1 )
            render.SetBlend( 1 )

            local assem = controller.tanktracktool_modeData.parts
            for i = 1, #assem do
                local parts = assem[i]
                for j = 1, #parts do
                    parts[j]:renderme( eyepos, eyedir, empty )
                end
            end

            render.SetColorModulation( 1, 1, 1 )
            render.SetBlend( 1 )
        end

        function meta:getPart( controller, a, b )
            return controller.tanktracktool_modeData.parts[a][b]
        end
    else
        function meta:renderParts( controller, eyepos, eyedir, empty )
            render.SetColorModulation( 1, 1, 1 )
            render.SetBlend( 1 )

            local parts_n = controller.tanktracktool_modeData.parts

            for i = 1, #parts_n do
                parts_n[i]:renderme( eyepos, eyedir, empty )
            end

            render.SetColorModulation( 1, 1, 1 )
            render.SetBlend( 1 )
        end

        function meta:getPart( controller, a )
            return controller.tanktracktool_modeData.parts[a]
        end
    end

    -- for overriding
    function meta:onInit( controller ) end
    function meta:onThink( controller ) end
    function meta:onDraw( controller, eyepos, eyedir, empty ) end

    return meta
end


--[[
    coil part
]]
function tanktracktool.render.createCoil()
    local wireMaterial = Material( "tanktracktool/cable_white" )
    local wireColor = Color( 255, 255, 255, 255 )
    local wireRadius = 1
    local radius = 8
    local detail = 1 / 4
    local coilCount = 4 * math.pi * 2
    local points = {}
    local pcount = 0

    local self = {}

    function self:setDetail( n )
        detail = math.Clamp( n, 1 / 16, 1 )
    end
    function self:setCoilCount( n )
        coilCount = math.Clamp( n, 1, 64 ) * math.pi * 2
    end
    function self:setRadius( n )
        radius = n
    end
    function self:setWireRadius( n )
        wireRadius = n
    end
    function self:setMaterial( s )
        wireMaterial = Material( s )
    end
    function self:setColor( c )
        wireColor = Color( c.r, c.g, c.b, c.a )
    end

    local noAngle = Angle()
    local arc = math.pi * 1.75

    function self:think( p0, p1, d0, d1 )
        local dir = p1 - p0

        if d0 or d1 then
            if d0 then p0 = p0 + dir:GetNormalized() * d0 end
            if d1 then p1 = p1 + dir:GetNormalized() * d1 end
            dir = p1 - p0
        end

        local len = dir:Length()
        local ang = dir:Angle()

        local c = coilCount
        local p = len / c
        local t = len / p
        local r = radius

        points = {}

        for i = 0, t, detail do
            points[#points + 1] = LocalToWorld( Vector( p * i, r * math.sin( i ), r * math.cos( i ) ), noAngle, p0, ang )
        end

        -- local a = p * t
        -- for i = 0, arc, detail do
        --     local rs = r * ( 1 - i / ( arc * 3 ) )
        --     points[#points + 1] = LocalToWorld( Vector( a, rs * math.sin( i ), rs * math.cos( i ) ), noAngle, p0, ang )
        -- end

        pcount = #points
    end

    function self:draw()
        local color = wireColor
        local radius = wireRadius
        local points = points
        local pcount = pcount

        render.SetMaterial( wireMaterial )
        render.StartBeam( pcount )

        for i = 1, pcount do
            render.AddBeam( rawget( points, i ), radius, i / pcount, color )
        end

        render.EndBeam()
    end

    return self
end
