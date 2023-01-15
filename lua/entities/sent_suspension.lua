AddCSLuaFile()

DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category  = "tanktracktool"

local tanktracktool = tanktracktool

ENT.tanktracktool_linkerData = {
    { name = "Chassis", bind = { KEY_E } },
    { name = "WheelLeft", bind = { KEY_E } },
    { name = "WheelRight", bind = { KEY_E } },
}

function ENT:netvar_setLinks( tbl, ply )
    tbl = {
        Chassis = tbl.Chassis or self.netvar.entities.Chassis,
        WheelLeft = tbl.WheelLeft or self.netvar.entities.WheelLeft,
        WheelRight = tbl.WheelRight or self.netvar.entities.WheelRight,
    }
    return tanktracktool.netvar.setLinks( self, tbl, ply )
end

local netvar = tanktracktool.netvar.new()

local default = {
}

function ENT:netvar_setup()
    return netvar, default
end

if SERVER then
    return
end

local math, util, string, table, render =
      math, util, string, table, render

local next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector =
      next, pairs, FrameTime, Entity, IsValid, EyePos, EyeVector, Vector, Angle, Matrix, WorldToLocal, LocalToWorld, Lerp, LerpVector
