--[[
	Tank Track Controller Addon
	by shadowscion
]]--

-- Add workshop
resource.AddWorkshop("737640184")


-- Add client lua
AddCSLuaFile("autorun/client/ttc_init_cl.lua")

AddCSLuaFile("ttc/edit_material.lua")
AddCSLuaFile("ttc/properties.lua")
AddCSLuaFile("ttc/render.lua")


-- Include server/shared
include("ttc/properties.lua")
