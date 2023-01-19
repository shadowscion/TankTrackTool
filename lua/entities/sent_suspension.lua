AddCSLuaFile()

DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Category  = "tanktracktool"

local tanktracktool = tanktracktool


--[[
    tool_link setup
]]
if CLIENT then
    tanktracktool.netvar.addToolLink( ENT, "Chassis", nil, nil )
    tanktracktool.netvar.addToolLink( ENT, "LeftWheel", nil, nil )
    tanktracktool.netvar.addToolLink( ENT, "RightWheel", nil, nil )
end

if SERVER then
    function ENT:netvar_setLinks( tbl, ply )
        if not istable( tbl ) then
            return tanktracktool.netvar.setLinks( self, {}, ply )
        end

        tbl = {
            Chassis = tbl.Chassis or self.netvar.entities.Chassis,
            LeftWheel = tbl.LeftWheel or self.netvar.entities.LeftWheel,
            RightWheel = tbl.RightWheel or self.netvar.entities.RightWheel,
        }
        return tanktracktool.netvar.setLinks( self, tbl, ply )
    end
end


--[[
    netvar setup
]]
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
