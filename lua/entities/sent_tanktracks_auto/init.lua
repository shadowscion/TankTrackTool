
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

ENT.tanktracktool_spawnHeight = 40


--[[
    wiremod
]]
function ENT:netvar_wireInputs()
    return { "LeftScroll", "LeftBrake", "RightScroll", "RightBrake", "AxisEntity [ENTITY]" }
end

local inputs = {}
inputs.LeftScroll = function( self, ply, value )
    self:SetNW2Float( "netwire_leftScroll", value )
end
inputs.LeftBrake = function( self, ply, value )
    self:SetNW2Bool( "netwire_leftBrake", tobool( value ) )
end
inputs.RightScroll = function( self, ply, value )
    self:SetNW2Float( "netwire_rightScroll", value )
end
inputs.RightBrake = function( self, ply, value )
    self:SetNW2Bool( "netwire_rightBrake", tobool( value ) )
end
inputs.AxisEntity = function( self, ply, value )
    if ply and not tanktracktool.netvar.canLink( value, ply ) then value = nil end
    self:SetNW2Entity( "netwire_axisEntity", ivalue )
end

function ENT:TriggerInput( name, value )
    if inputs[name] then inputs[name]( self, WireLib and WireLib.GetOwner( self ), value ) end
end


--[[
    legacy... this is for the old variable system
]]
function ENT:netvar_nme( data )
    if istable( data.wheelTable ) then
        local instance = { "whnBodygroup", "whnColor", "whnMaterial", "whnModel", "whnOffsetX", "whnOffsetY", "whnOffsetZ", "whnOverride", "whnRadius", "whnSuspension", "whnTraceZ", "whnWidth" }

        local count = self.netvar.variables:get( "wheelCount" ).data.max
        if tonumber( data.wheelCount ) then
            count = math.min( tonumber( data.wheelCount ), count )
        end

        for k, v in pairs( instance ) do
            if self.netvar.variables:get( v ) then
                data[v] = {}
                for i = 1, count do
                    local value = data.wheelTable[i][v]
                    if value ~= nil then
                        data[v][i] = value
                    end
                end
            end
        end

        data.wheelTable = nil
    end

    if istable( data.rollerTable ) then
        local instance = { "ronBodygroup", "ronColor", "ronMaterial", "ronModel", "ronOffsetX", "ronOffsetY", "ronOffsetZ", "ronOverride", "ronRadius", "ronWidth" }

        local count = self.netvar.variables:get( "rollerCount" ).data.max
        if tonumber( data.rollerCount ) then
            count = math.min( tonumber( data.rollerCount ), count )
        end

        for k, v in pairs( instance ) do
            if self.netvar.variables:get( v ) then
                data[v] = {}
                for i = 1, count do
                    local value = data.rollerTable[i][v]
                    if value ~= nil then
                        data[v][i] = value
                    end
                end
            end
        end

        data.rollerTable = nil
    end

    return data
end


--[[
    legacy... this is for ttc
]]
local function a1z26_toTable( str, int )
    if not str then return end
    local ret = {}
    local key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local len = string.len( key )
    for k, v in string.gmatch( str, "(%a+)(%-?%d+)" ) do
        local idx = 0
        for i = 1, #k do
            local f = string.find( key, string.sub( k, i, i ) )
            idx = idx + f + f * ( len * ( i - 1 ) )
        end
        ret[idx] = tonumber( v ) / int
    end
    return ret
end

local function SuperLegacy( self, dupedata )
    if not istable( dupedata ) then return end

    self:netvar_set( "suspensionType", nil, "classic" )

    -- tracks
    if isstring( dupedata.TrackMaterial ) then
        local k, v = string.gsub( dupedata.TrackMaterial, "track_", "" )
        self:netvar_set( "trackMaterial", nil, k )
    end

    self:netvar_set( "trackHeight", nil, dupedata.TrackHeight )
    self:netvar_set( "trackWidth", nil, dupedata.TrackWidth )
    self:netvar_set( "trackTension", nil, dupedata.TrackTension )
    self:netvar_set( "trackRes", nil, dupedata.TrackResolution )

    -- suspension
    self:netvar_set( "systemOffsetX", nil, dupedata.WheelOffsetX )

    self:netvar_set( "suspensionX", nil, dupedata.WheelBase )
    self:netvar_set( "suspensionY", nil, ( dupedata.WheelOffsetY or 0 ) * 2 )
    self:netvar_set( "suspensionZ", nil, dupedata.WheelOffsetZ )

    if dupedata.RoadWType == "interleave" then
        self:netvar_set( "suspensionInterleave", nil, 0.5 )
    end

    -- wheels
    local count = ( dupedata.RoadWCount or 0 ) + ( dupedata.DriveWEnabled and 1 or 0 ) + ( dupedata.IdlerWEnabled and 1 or 0 )
    self:netvar_set( "wheelCount", nil, count )

    local wheelColor = isvector( dupedata.WheelColor ) and string.format( "%d %d %d 255", dupedata.WheelColor.x, dupedata.WheelColor.y, dupedata.WheelColor.z ) or nil

    local wheelMaterial = isstring( dupedata.WheelMaterial ) and string.Explode( ", ", dupedata.WheelMaterial )
    if wheelMaterial then
        if #wheelMaterial == 1 then
            wheelMaterial = { wheelMaterial[1] }
        else
            local r = {}
            for i = 1, #wheelMaterial, 2 do
                r[wheelMaterial[i] + 2] = wheelMaterial[i + 1]
            end
            wheelMaterial = r
        end
        for i = 1, #wheelMaterial do
            if wheelMaterial[i] == "\"\"" then wheelMaterial[i] = nil end
        end
    end

    -- sprocket
    if dupedata.DriveWEnabled then
        local z_offset = ( dupedata.DriveWOffsetZ or 0 ) + ( dupedata.DriveWDiameter or 0 ) * 0.5 + ( dupedata.TrackHeight or 0 )

        local index = 1
        self:netvar_set( "whnSuspension", index, 0 )
        self:netvar_set( "whnOffsetZ", index, z_offset )
        self:netvar_set( "whnOverride", index, 1 )
        self:netvar_set( "whnRadius", index, ( dupedata.DriveWDiameter or 0 ) * 0.5 )
        self:netvar_set( "whnWidth", index, dupedata.DriveWWidth )
        self:netvar_set( "whnModel", index, dupedata.DriveWModel )
        self:netvar_set( "whnBodygroup", index, dupedata.DriveWBGroup )

        if wheelColor then
            self:netvar_set( "whnColor", index, wheelColor )
        end
        if wheelMaterial then
            self:netvar_set( "whnMaterial", index, wheelMaterial )
        end
    end

    -- idler
    if dupedata.IdlerWEnabled then
        local z_offset = ( dupedata.IdlerWOffsetZ or 0 ) + ( dupedata.IdlerWDiameter or 0 ) * 0.5 + ( dupedata.TrackHeight or 0 )

        local index = 2
        self:netvar_set( "whnSuspension", index, 0 )
        self:netvar_set( "whnOffsetZ", index, z_offset )
        self:netvar_set( "whnOverride", index, 1 )
        self:netvar_set( "whnRadius", index, ( dupedata.IdlerWDiameter or 0 ) * 0.5 )
        self:netvar_set( "whnWidth", index, dupedata.IdlerWWidth )
        self:netvar_set( "whnModel", index, dupedata.IdlerWModel )
        self:netvar_set( "whnBodygroup", index, dupedata.IdlerWBGroup )

        if wheelColor then
            self:netvar_set( "whnColor", index, wheelColor )
        end
        if wheelMaterial then
            self:netvar_set( "whnMaterial", index, wheelMaterial )
        end
    end

    -- road
    self:netvar_set( "wheelRadius", nil, ( dupedata.RoadWDiameter or 0 ) * 0.5 )
    self:netvar_set( "wheelWidth", nil, dupedata.RoadWWidth )
    self:netvar_set( "wheelModel", nil, dupedata.RoadWModel )
    self:netvar_set( "wheelBodygroup", nil, dupedata.RoadWBGroup )

    local offsets = a1z26_toTable( dupedata.RoadWOffsetsX, 99 )
    if offsets then
        for i = 1, #offsets do
            self:netvar_set( "whnOffsetX", i + 2, offsets[i] )
        end
    end
    if wheelColor then
        self:netvar_set( "wheelColor", nil, wheelColor )
    end
    if wheelMaterial then
        self:netvar_set( "wheelMaterial", nil, wheelMaterial )
    end

    -- rollers
    local rollerCount = tonumber( dupedata.RollerWCount or 0 )
    self:netvar_set( "rollerCount", nil, rollerCount )

    if rollerCount > 0 then
        self:netvar_set( "rollerRadius", nil, ( dupedata.RollerWDiameter or 0 ) * 0.5 )
        self:netvar_set( "rollerWidth", nil, dupedata.RollerWWidth )
        self:netvar_set( "rollerModel", nil, dupedata.RollerWModel )
        self:netvar_set( "rollerBodygroup", nil, dupedata.RollerWBGroup )

        local offsets = a1z26_toTable( dupedata.RollerWOffsetsX, 99 )
        if offsets then
            for i = 1, #offsets do
                self:netvar_set( "ronOffsetX", i, offsets[i] )
            end
        end
        if wheelColor then
            self:netvar_set( "rollerColor", nil, wheelColor )
        end
        if wheelMaterial then
            self:netvar_set( "rollerMaterial", nil, wheelMaterial )
        end
    end
end

duplicator.RegisterEntityClass( "gmod_ent_ttc_auto", function( ply, dupedata )
    local ent = ents.Create( "sent_tanktracks_auto" )

    duplicator.DoGeneric( ent, dupedata )

    ent:Spawn()
    ent:Activate()

    pcall( SuperLegacy, ent, dupedata.EntityMods and dupedata.EntityMods._ENW2V_DUPED )
    duplicator.ClearEntityModifier( ent, "_ENW2V_DUPED" )

    ply:AddCount( "sent_tanktracks_auto", ent )
    ply:AddCleanup( "sent_tanktracks_auto", ent )

    return ent
end, "Data" )
