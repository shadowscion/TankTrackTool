
tttlib.track_modes = {}

local render = render
local render_multiply = "RenderMultiply"

local function createcsents( self, ent )
    local csents = { wheel = true }

    for k, v in pairs( ent.ttdata_csents ) do
        if not self.csents[k] and IsValid( v ) then
            --print( "removing", k )
            v:Remove()
        end
    end

    for k, v in pairs( self.csents ) do
        if not IsValid( ent.ttdata_csents[k] ) then
            ent.ttdata_csents[k] = ents.CreateClientside( "base_anim" )
            --print( "creating", k )
        else
            --print( "exists", k )
        end
        ent.ttdata_csents[k].RenderGroup = RENDERGROUP_OPAQUE
        ent.ttdata_csents[k]:SetRenderMode( RENDERMODE_TRANSCOLOR )
        ent.ttdata_csents[k]:SetNoDraw( true )
        ent.ttdata_csents[k]:SetLOD( 0 )
        ent.ttdata_csents[k].model = nil
    end

    ent.ttdata_parts = {}
end

local function rendercomponent( self, ent, component, isdouble )
    local csent = component.csent

    if component.nodraw then
        if component.postrender then
            component:postrender( self, ent, isdouble )
        end

        return
    end

    if csent.model ~= component.model then
        csent.model = component.model
        csent:SetModel( component.model )
    end

    if component.bodygroup then
        csent:SetBodyGroups( component.bodygroup )
    else
        csent:SetBodyGroups( nil )
    end

    if component.setupscale then
        component:setupscale()
    else
        csent:EnableMatrix( render_multiply, component.scale )
    end

    if component.color then
        local c = component.color
        csent.RenderGroup = c.a ~= 255 and RENDERGROUP_BOTH or RENDERGROUP_OPAQUE
        render.SetBlend( c.a )
        render.SetColorModulation( c.r, c.g, c.b )
    else
        csent.RenderGroup = RENDERGROUP_OPAQUE
        render.SetBlend( 1 )
        render.SetColorModulation( 1, 1, 1 )
    end

    if component.material then
        csent:SetMaterial( component.material )
        csent:SetSubMaterial( nil )
    elseif component.submaterials then
        csent:SetMaterial( nil )
        for s = 1, #component.submaterials do
            csent:SetSubMaterial( s - 1, component.submaterials[s] )
        end
    else
        csent:SetMaterial( nil )
        csent:SetSubMaterial( nil )
    end

    csent:SetPos( component.le_posworld )
    csent:SetAngles( component.le_angworld )
    csent:SetupBones()
    csent:DrawModel()

    if isdouble then
        if component.setupscale_ri then
            component:setupscale_ri()
        end

        csent:SetPos( component.ri_posworld )
        csent:SetAngles( component.ri_angworld )
        csent:SetupBones()
        csent:DrawModel()
    end

    if component.postrender then
        component:postrender( self, ent, isdouble )
    end
end

local function rendercsents( self, ent, isdouble )
    if self.prerender then self:prerender( ent ) end

    local parts = ent.ttdata_parts

    for i = 1, #parts do
        local components = parts[i]
        for j = 1, #components do
            rendercomponent( self, ent, components[j], isdouble )
        end
    end

    if self.postrender then self:postrender( ent ) end

    render.SetColorModulation( 1, 1, 1 )
    render.SetBlend( 1 )
end

local function addcomponent( self, csent )
    local component = {
        csent = csent,
        le_poslocal = Vector(),
        le_posworld = Vector(),
        le_anglocal = Angle(),
        le_angworld = Angle(),
        ri_poslocal = Vector(),
        ri_posworld = Vector(),
        ri_anglocal = Angle(),
        ri_angworld = Angle(),
        scale = Matrix(),
     }
    component.id = table.insert( self, component )
    return component
end

local function addpart( self, ent, i )
    local part = { addcomponent = addcomponent, id = i }
    ent.ttdata_parts[i] = part
    return part
end

function tttlib.tracks_addMode( name )
    tttlib.track_modes[name] = { name = name, setup = function() end, think = function() end, addpart = addpart, render = rendercsents, createcsents = createcsents, csents = {} }
    return tttlib.track_modes[name]
end

function tttlib.tracks_renderBounds( self )
    local rendermin, rendermax = Vector( 0, 0, -self.NMEVals.suspensionZ ), Vector( 0, 0, self.NMEVals.suspensionZ )
    local renderpos, renderang = self:ttfunc_getmatrix()

    renderpos, renderang = WorldToLocal( self:GetPos(), self:GetAngles(), renderpos, renderang )
    tttlib.calcbounds( rendermin, rendermax, renderpos )

    for i = 1, #self.ttdata_parts do
        local wheel = self.ttdata_parts[i][1]
        tttlib.calcbounds( rendermin, rendermax, wheel[1] + wheel.maxs )
        if self.ttdata_isdouble then
            tttlib.calcbounds( rendermin, rendermax, wheel[2] + wheel.mins )
        end
    end

    self.rendermin = rendermin
    self.rendermax = rendermax
    self:SetRenderBounds( self.rendermin, self.rendermax )
end
