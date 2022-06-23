
if SERVER then
	AddCSLuaFile("tanktracktool/util.lua")
	AddCSLuaFile("tanktracktool/tracks.lua")
	AddCSLuaFile("tanktracktool/effects.lua")
end

if CLIENT then
	ttlib = ttlib or {}

	local disable = CreateClientConVar("tanktracktool_disable", 0, true, false)
	ttlib.RenderDisable = disable:GetBool()

	cvars.AddChangeCallback("tanktracktool_disable", function(name, old, new)
		ttlib.RenderDisable = tobool(new)
	end)

	include("tanktracktool/util.lua")
	include("tanktracktool/tracks.lua")
	include("tanktracktool/effects.lua")
end
