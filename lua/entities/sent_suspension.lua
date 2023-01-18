AddCSLuaFile()

DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category  = "tanktracktool"

local tanktracktool = tanktracktool

tanktracktool.netvar.addLinks( ENT, "Chassis" )
tanktracktool.netvar.addLinks( ENT, "LeftWheel" )
tanktracktool.netvar.addLinks( ENT, "RightWheel" )

function ENT:netvar_setLinks( tbl, ply )
    tbl = {
        Chassis = tbl.Chassis or self.netvar.entities.Chassis,
        LeftWheel = tbl.LeftWheel or self.netvar.entities.LeftWheel,
        RightWheel = tbl.RightWheel or self.netvar.entities.RightWheel,
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
