
-- NME
if SERVER then AddCSLuaFile() end

DEFINE_BASECLASS( "base_nme" )

ENT.Author = "shadowscion"
ENT.Category = "TankTrackTool"
ENT.Spawnable = true
ENT.AdminOnly = false

local pbc_vars = NeedMoreEdits.New()

function ENT:SetupNME()
    return pbc_vars
end

function ENT:DefaultNME( update )
    self:SetValueNME( update, "pointCount", nil, 7 )
    self:SetValueNME( update, "pointSpread", nil, 4 )
    self:SetValueNME( update, "pointStutter", nil, 0.15 )
    self:SetValueNME( update, "pointDelay", nil, 0 )
    self:SetValueNME( update, "pointSag", nil, 0 )

    self:SetValueNME( update, "sourceEnable", nil, 1 )
    self:SetValueNME( update, "sourceColor1", nil, "255 255 255 255" )
    self:SetValueNME( update, "sourceColor2", nil, "255 0 0 255" )
    self:SetValueNME( update, "sourceSize1", nil, 24 )
    self:SetValueNME( update, "sourceSize2", nil, 64 )

    self:SetValueNME( update, "pointEnable", nil, 1 )
    self:SetValueNME( update, "pointColor1", nil, "255 255 255 255" )
    self:SetValueNME( update, "pointColor2", nil, "38 0 255 255" )
    self:SetValueNME( update, "pointSize1", nil, 8 )
    self:SetValueNME( update, "pointSize2", nil, 24 )

    self:SetValueNME( update, "beamEnable", nil, 1 )
    self:SetValueNME( update, "beamColor1", nil, "255 255 255 255" )
    self:SetValueNME( update, "beamColor2", nil, "242 0 255 255" )
    self:SetValueNME( update, "beamSize1", nil, 16 )
    self:SetValueNME( update, "beamSize2", nil, 48 )

    self:SetValueNME( update, "particleEnable", nil, 1 )
    self:SetValueNME( update, "particleColor", nil, "242 0 255 255" )
    self:SetValueNME( update, "particleSize1", nil, 2 )
    self:SetValueNME( update, "particleSize2", nil, 0 )
end


pbc_vars:Category( "Setup" )
pbc_vars:Var( "pointCount", "Int", { min = 2, max = 20, def = 5, title = "point count" } )
pbc_vars:Var( "pointSpread", "Float", { min = 0, max = 64, def = 1, title = "randomize point spread" } )
pbc_vars:Var( "pointStutter", "Float", { min = 0, max = 1, def = 0, title = "randomize point missfire" } )
pbc_vars:Var( "pointMulti", "Int", { min = 1, max = 4, def = 1, title = "beam count" } )
pbc_vars:Var( "pointDelay", "Float", { min = 0, max = 1, def = 0, title = "beam velocity delay" } )
pbc_vars:Var( "pointSag", "Float", { min = 0, max = 1, def = 0, title = "beam sag percent" } )
pbc_vars:Var( "pointTrace", "Bool", { def = 0, title = "enable beam intersection" } )


pbc_vars:Category( "source" )
pbc_vars:Var( "sourceEnable", "Bool", { def = 1, title = "enabled" } )
pbc_vars:Var( "sourceSize1", "Float", { min = 1, max = 64, def = 12, title = "inner size" } )
pbc_vars:Var( "sourceColor1", "Color", { def = "", title = "inner color" } )
pbc_vars:Var( "sourceSize2", "Float", { min = 1, max = 64, def = 12, title = "outer size" } )
pbc_vars:Var( "sourceColor2", "Color", { def = "", title = "outer color" } )


pbc_vars:Category( "Point" )
pbc_vars:Var( "pointEnable", "Bool", { def = 1, title = "enabled" } )
pbc_vars:Var( "pointSize1", "Float", { min = 1, max = 64, def = 12, title = "inner size" } )
pbc_vars:Var( "pointColor1", "Color", { def = "", title = "inner color" } )
pbc_vars:Var( "pointSize2", "Float", { min = 1, max = 64, def = 12, title = "outer size" } )
pbc_vars:Var( "pointColor2", "Color", { def = "", title = "outer color" } )


pbc_vars:Category( "Beam" )
pbc_vars:Var( "beamEnable", "Bool", { def = 1, title = "enabled" } )
pbc_vars:Var( "beamSize1", "Float", { min = 1, max = 64, def = 12, title = "inner size" } )
pbc_vars:Var( "beamColor1", "Color", { def = "", title = "inner color" } )
pbc_vars:Var( "beamSize2", "Float", { min = 1, max = 64, def = 12, title = "outer size" } )
pbc_vars:Var( "beamColor2", "Color", { def = "", title = "outer color" } )
pbc_vars:Var( "beamMaterial", "Combo", { def = "tripmine_laser", title = "material" } )


local edit = pbc_vars:GetVar( "beamMaterial" ).edit
edit.values = {
    ["tripmine_laser"] = 1,
    ["trails/electric"] = 2,
    ["trails/physbeam"] = 3,
    ["trails/plasma"] = 4,
    ["cable/cable2"] = 5,
}


pbc_vars:Category( "particle" )
pbc_vars:Var( "particleEnable", "Bool", { def = 1, title = "enabled" } )
pbc_vars:Var( "particleSize1", "Float", { min = 0, max = 64, def = 12, title = "start size" } )
pbc_vars:Var( "particleSize2", "Float", { min = 0, max = 64, def = 12, title = "end size" } )
pbc_vars:Var( "particleColor", "Color", { def = "", title = "color" } )
pbc_vars:Var( "particleMaterial", "Combo", { def = "effects/spark", title = "material" } )

local edit = pbc_vars:GetVar( "particleMaterial" ).edit
edit.values = {
    ["effects/spark"] = 1,
}


if CLIENT then


    local pairs, math, util, cam, render, IsValid, LerpVector, VectorRand =
          pairs, math, util, cam, render, IsValid, LerpVector, VectorRand

    local pi = math.pi

    pbc_controllers = pbc_controllers or {}

    local matbeam = Material( "tripmine_laser" )
    local matpoint = Material( "sprites/gmdm_pickups/light" )

    hook.Add( "PostDrawTranslucentRenderables", "pbc_renderer", function()
        if not next( pbc_controllers ) then return end

        for k, v in pairs( pbc_controllers ) do
            if v and IsValid( k ) then
                k:pbc_render()
            end
        end
    end )


    function ENT:TriggerNME(type, ...)
        if type == "editor_open" or type == "editor_close" then
            local editor = select( 1, ... )
            if IsValid( editor ) then
                editor.DTree.RootNode:ExpandRecurse( true )
            end
        else
            self.pbc_reset = true
        end
    end


    do
        local _grey = Color(255, 255, 255, 150)
        local _red = Color(255, 0, 0, 150)
        local _grn = Color(0, 255, 0, 150)
        local _blu = Color(0, 0, 255, 150)

        function ENT:OverlayNME( hoveredNode )
            local e1 = self:GetNW2Entity( "beamEntity1", self )
            local e2 = self:GetNW2Entity( "beamEntity2", self )

            if not IsValid( e1 ) then e1 = self end
            if not IsValid( e2 ) then e2 = self end

            local pos = e1:GetPos()
            local off = e1:LocalToWorld( self:GetNW2Vector( "beamOffset1" ), Vector() )

            cam.Start3D()
                render.DrawLine( pos, pos + e1:GetRight(), _red )
                render.DrawLine( pos, pos + e1:GetForward() * 6, _grn )
                render.DrawLine( pos, pos + e1:GetUp() * 6, _blu )
                render.DrawLine( pos, off, _grey )
            cam.End3D()

            pos = pos:ToScreen()
            draw.SimpleText( "Entity1", "DermaDefault", pos.x, pos.y, _grey, 1, 1 )
            off = off:ToScreen()
            draw.SimpleText( "Offset1", "DermaDefault", off.x, off.y, _grey, 1, 1 )

            local pos = e2:GetPos()
            local off = e2:LocalToWorld( self:GetNW2Vector( "beamOffset2" ), Vector() )

            cam.Start3D()
                render.DrawLine( pos, pos + e2:GetRight(), _red )
                render.DrawLine( pos, pos + e2:GetForward() * 6, _grn )
                render.DrawLine( pos, pos + e2:GetUp() * 6, _blu )
                render.DrawLine( pos, off, _grey )
            cam.End3D()

            pos = pos:ToScreen()
            draw.SimpleText( "Entity2", "DermaDefault", pos.x, pos.y, _grey, 1, 1 )
            off = off:ToScreen()
            draw.SimpleText( "Offset2", "DermaDefault", off.x, off.y, _grey, 1, 1 )
        end
    end


    function ENT:Initialize()
        self.BaseClass.Initialize( self )
    end


    function ENT:Draw()
        self:DrawModel()
    end


    function ENT:Think()
        if self.pbc_reset then
            self.pbc_reset = nil
            self:pbc_update()
        end

        self:pbc_think()
    end


    function ENT:OnRemove()
        self.pbc_reset = true

        timer.Simple( 0, function()
            if ( self and self:IsValid() ) then
                return
            end

            pbc_controllers[self] = nil
        end )
    end


    function ENT:pbc_visible()
        if FrameTime() == 0 or self:GetNW2Bool( "beamDisable", false ) then return false end -- gui.IsConsoleVisible()

        return true
    end


    function ENT:pbc_render()
        if not self.pbc_ready then
            return
        end

        for i = 1, #self.pbc_beams do
            local beam = self.pbc_beams[i]
            local data = beam.data

            local points = beam.points
            local count = #points

            if data.sourceEnable then
                render.SetMaterial( matpoint )

                render.DrawSprite( points[1], data.sourceSize1, data.sourceSize1, data.sourceColor1 )
                render.DrawSprite( points[1], data.sourceSize2, data.sourceSize2, data.sourceColor2 )

                if not data.split then
                    render.DrawSprite( points[count], data.sourceSize1, data.sourceSize1, data.sourceColor1 )
                    render.DrawSprite( points[count], data.sourceSize2, data.sourceSize2, data.sourceColor2 )
                end
            end

            if data.pointEnable then
                render.SetMaterial( matpoint )

                for j = 1, count do
                    render.DrawSprite( points[j], data.pointSize1, data.pointSize1, data.pointColor1 )
                    render.DrawSprite( points[j], data.pointSize2, data.pointSize2, data.pointColor2 )
                end
            end

            if data.beamEnable then
                render.SetMaterial( data.beamMaterial or matbeam )

                local v1 = points[1]
                local v2 = points[2]

                for i = 1, count - 1 do
                    render.DrawBeam( v1, v2, data.beamSize1, 0, 1, data.beamColor1 )
                    render.DrawBeam( v1, v2, data.beamSize2, 0, 1, data.beamColor2 )

                    v1 = points[i + 1]
                    v2 = points[i + 2]
                end
            end
        end

    end


    local emitter = ParticleEmitter( Vector() )
    local gravity = Vector()

    local function CreateBeam( self, ent1, ent2, pos1, pos2, data, fx )
        local beam = { this = self, ent1 = ent1, ent2 = ent2, points = {}, data = data }

        local min_length
        if data.pointSag then
            min_length = -pos1:Distance( pos2 ) * data.pointSag * 0.5
        end

        for i = 1, data.pointCount do
            local t = ( i - 1 ) / ( data.pointCount - 1 )
            local r = math.sin( t * pi )

            local pos = LerpVector( t, pos1, pos2 )

            if data.pointSpread then
                pos:Add( VectorRand( -r * data.pointSpread, r * data.pointSpread ) )
            end

            if data.pointDelay then
                pos:Add( data.velocity * r )
            end

            if min_length then
                gravity.z = min_length * r
                pos:Add( gravity )
            end

            beam.points[i] = pos
        end

        if fx then
            fx:SetOrigin( pos2 )
            fx:SetNormal( pos1 - pos2 )

            util.Effect( "AR2Impact", fx )
        end

        if data.particleEnable and emitter and math.random( 0, 100 ) > 50 then
            local index = math.random( 1, data.pointCount )
            local particle = emitter:Add( data.particleMaterial, beam.points[index] )

            if particle then
                particle:SetDieTime( 0.5 )
                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 0 )
                particle:SetStartSize( math.Rand( data.particleSize1 * 0.5, data.particleSize1 ) )
                particle:SetEndSize( data.particleSize2 )
                particle:SetColor( data.particleColor.r, data.particleColor.g, data.particleColor.b )

                gravity.z = -( 25 + 250 * math.sin( ( index / data.pointCount ) * pi ) )

                particle:SetGravity( gravity )
            end
        end

        self.pbc_beams[#self.pbc_beams + 1] = beam
    end


    function ENT:pbc_think()
        if not pbc_controllers[self] then
            self.pbc_reset = true
            return
        end

        self.pbc_ready = nil

        if not self:pbc_visible() or ( not self.pbc_data.sourceEnable and not self.pbc_data.pointEnable and not self.pbc_data.beamEnable ) then return end
        if self.pbc_data.randomDisable and math.random( 0, 100 ) >  self.pbc_data.randomDisable then return end

        local ent1 = self:GetNW2Entity( "beamEntity1", self )
        local ent2 = self:GetNW2Entity( "beamEntity2", self )

        if not IsValid( ent1 ) then ent1 = self end
        if not IsValid( ent2 ) then ent2 = self end

        local pos1 = ent1:LocalToWorld( self:GetNW2Vector( "beamOffset1" ), Vector() )
        local pos2 = ent2:LocalToWorld( self:GetNW2Vector( "beamOffset2" ), Vector() )

        if self.pbc_data.pointDelay then
            self.pbc_data.velocity = Lerp( self.pbc_data.pointDelay, self.pbc_data.velocity or Vector(), ( ent1:GetVelocity() + ent2:GetVelocity() ) * -0.01 )
        end

        self.pbc_beams = {}
        self.pbc_data.split = nil

        if self.pbc_data.pointTrace then
            local hit1 = util.TraceLine( { start = pos1, endpos = pos2, filter = { self, ent1, ent2 } } )
            local hit2 = util.TraceLine( { start = pos2, endpos = pos1, filter = { self, ent1, ent2 } } )

            local multi = self.pbc_data.pointMulti

            if IsValid( hit1.Entity ) then
                local fx = EffectData()

                if hit1.Entity:IsPlayer() then
                    for i = 1, multi do CreateBeam( self, ent1, ent2, pos1, hit1.HitPos, self.pbc_data, fx ) end
                else
                    for i = 1, multi do CreateBeam( self, ent1, ent2, pos1, hit1.Entity:NearestPoint( pos1 ), self.pbc_data, fx ) end
                end

                self.pbc_data.split = true
            end

            if IsValid( hit2.Entity ) then
                local fx = EffectData()

                if hit2.Entity:IsPlayer() then
                    for i = 1, multi do CreateBeam( self, ent1, ent2, pos2, hit2.HitPos, self.pbc_data, fx ) end
                else
                    for i = 1, multi do CreateBeam( self, ent1, ent2, pos2, hit2.Entity:NearestPoint( pos2 ), self.pbc_data, fx ) end
                end

                self.pbc_data.split = true
            end

            if not self.pbc_data.split then
                for i = 1, multi do CreateBeam( self, ent1, ent2, pos1, pos2, self.pbc_data ) end
            end
        else
            for i = 1, self.pbc_data.pointMulti do CreateBeam( self, ent1, ent2, pos1, pos2, self.pbc_data ) end
        end

        self.pbc_ready = true
    end


    function ENT:pbc_update()
        local info = self.NMEVals
        local data = {}

        data.pointCount = math.abs( info.pointCount or 10 )
        data.pointMulti = math.Clamp( info.pointMulti or 1, 1, 4 )
        data.pointTrace = tobool( info.pointTrace )

        local randomDisable = tonumber( info.pointStutter )
        if randomDisable > 0 and randomDisable < 1 then
            data.randomDisable = 100 - randomDisable * 100
        else
            data.randomDisable = nil
        end

        data.pointDelay = tonumber( info.pointDelay )
        if data.pointDelay > 0 then
            data.pointVelocity = Vector()
            data.pointDelay = data.pointDelay
        else
            data.pointDelay = nil
        end

        data.pointSpread = tonumber( info.pointSpread )
        if data.pointSpread == 0 then
            data.pointSpread = nil
        end

        data.pointSag = tonumber( info.pointSag )
        if data.pointSag == 0 then
            data.pointSag = nil
        end

        data.pointEnable = tobool( info.pointEnable )
        if data.pointEnable then
            data.pointSize1 = math.abs( info.pointSize1 or 16 )
            data.pointSize2 = math.abs( info.pointSize2 or 16 )
            data.pointColor1 = string.ToColor( info.pointColor1 or "" )
            data.pointColor2 = string.ToColor( info.pointColor2 or "" )
        end

        data.beamEnable = tobool( info.beamEnable )
        if data.beamEnable then
            data.beamSize1 = math.abs( info.beamSize1 or 16 )
            data.beamSize2 = math.abs( info.beamSize2 or 16 )
            data.beamColor1 = string.ToColor( info.beamColor1 or "" )
            data.beamColor2 = string.ToColor( info.beamColor2 or "" )
            data.beamMaterial = Material( info.beamMaterial )
        end

        data.sourceEnable = tobool( info.sourceEnable )
        if data.sourceEnable then
            data.sourceSize1 = math.abs( info.sourceSize1 or 16 )
            data.sourceSize2 = math.abs( info.sourceSize2 or 16 )
            data.sourceColor1 = string.ToColor( info.sourceColor1 or "" )
            data.sourceColor2 = string.ToColor( info.sourceColor2 or "" )
        end

        data.particleEnable = tobool( info.particleEnable )
        if data.particleEnable then
            data.particleSize1 = math.abs( info.particleSize1 or 16 )
            data.particleSize2 = math.abs( info.particleSize2 or 16 )
            data.particleColor = string.ToColor( info.particleColor or "" )
            data.particleMaterial = info.particleMaterial or "effects/spark"
        end

        self.pbc_data = data

        pbc_controllers[self] = true
    end


    function ENT:pbc_remove()
        pbc_controllers[self] = nil
    end


end


if SERVER then


    function ENT:SpawnFunction( ply, tr, Class )
        if not tr.Hit then return end

        local ent = ents.Create( ClassName )
        ent:SetModel( "models/hunter/plates/plate.mdl" )
        ent:SetPos( tr.HitPos + tr.HitNormal * 40 )
        ent:Spawn()
        ent:Activate()

        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableMotion( false )
            phys:Wake()
        end

        return ent
    end


    function ENT:Initialize()
        self.BaseClass.Initialize( self )

        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        if Wire_CreateInputs then
            self.Inputs = Wire_CreateInputs( self, { "Disable", "Entity1 [ENTITY]", "Entity2 [ENTITY]", "Offset1 [VECTOR]", "Offset2 [VECTOR]" } )
        end
    end


    -- Wiremod Stuff
    local inputTriggers = {
        Disable = function( self, iname, ivalue, src )
            self:SetNW2Bool( "beamDisable", ivalue )
        end,
        Entity1 = function( self, iname, ivalue, src )
            self:SetNW2Entity( "beamEntity1", ivalue )
        end,
        Entity2 = function( self, iname, ivalue, src )
            self:SetNW2Entity( "beamEntity2", ivalue )
        end,
        Offset1 = function( self, iname, ivalue, src )
            self:SetNW2Vector( "beamOffset1", ivalue )
        end,
        Offset2 = function( self, iname, ivalue, src )
            self:SetNW2Vector( "beamOffset2", ivalue )
        end,
    }


    function ENT:TriggerInput( iname, ivalue, ... )
        if inputTriggers[iname] then
            inputTriggers[iname]( self, iname, ivalue )
        end
    end


    function ENT:OnRemove()
        if WireLib then WireLib.Remove( self ) end
    end


    function ENT:OnRestore()
        if WireLib then WireLib.Restored( self)  end
    end


    function ENT:BuildDupeInfo()
        return WireLib and WireLib.BuildDupeInfo( self )
    end


    function ENT:ApplyDupeInfo( ply, ent, info, GetEntByID )
        if WireLib then WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID ) end
    end


    function ENT:PreEntityCopy()
        self.BaseClass.PreEntityCopy( self )

        duplicator.ClearEntityModifier( self, "WireDupeInfo" )

        local DupeInfo = self:BuildDupeInfo()
        if DupeInfo then
            duplicator.StoreEntityModifier( self, "WireDupeInfo", DupeInfo )
        end
    end


    function ENT:OnEntityCopyTableFinish( dupedata )
        dupedata.OverlayData = nil
        dupedata.lastWireOverlayUpdate = nil
        dupedata.WireDebugName = nil
    end


    local function EntityLookup( CreatedEntities )
        return function( id, default )
            if id == nil then return default end
            if id == 0 then return game.GetWorld() end
            local ent = CreatedEntities[id]
            if IsValid( ent ) then return ent else return default end
        end
    end


    function ENT:OnDuplicated( dupe )
        self.BaseClass.OnDuplicated( self, dupe )
        self.DuplicationInProgress = true
    end


    function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
        if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
            Ent:ApplyDupeInfo( Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup( CreatedEntities ) )
        end
        self.DuplicationInProgress = nil
    end


end
