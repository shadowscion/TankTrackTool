
//
include("shared.lua")

ENT.NMEIcon = "tanktracktool/icons/editor.png"
ENT.NMEWiki = "https://github.com/shadowscion/TankTrackTool"

include("modes/classic.lua")
include("modes/torsion.lua")


local gui, util, math, render, string, table = gui, util, math, render, string, table
local FrameTime = FrameTime

local ttlib = ttlib


//
function ENT:TriggerNME(type, ...)
	if type == "editor_open" or type == "editor_close" then

	else
		self.ttdata_reset = true
	end
end

/*
local _grey = Color(255, 255, 255, 150)
local _red = Color(255, 0, 0, 150)
local _grn = Color(0, 255, 0, 150)
local _blu = Color(0, 0, 255, 150)

function ENT:OverlayNME(hoveredNode)
	local pos, ang = self:ttfunc_getmatrix()

	cam.Start3D()

	render.DrawLine(pos, pos + ang:Right()*6, _red)
	render.DrawLine(pos, pos + ang:Forward()*6, _grn)
	render.DrawLine(pos, pos + ang:Up()*6, _blu)

	cam.End3D()

	if not hoveredNode then return end
	if hoveredNode.instance then
		local i = hoveredNode.instance
		local ID = hoveredNode.instanceID


		if hoveredNode.instanceID == "rollerCount" then
			i = self.NMEVals.wheelCount + (self.NMEVals.rollerCount - i + 1)
		else
			i = (i == 1 and 1 or i == 2 and self.NMEVals.wheelCount or i - 1)
		end

		local part = self.ttdata_parts[i]

		local wheel = part[1]
		local y_offset = (wheel.y_offset or 0) + wheel.width*0.5

		local p1 = (wheel.le_posworld - ang:Right()*y_offset):ToScreen()
		local p2 = (wheel.le_posworld - ang:Right()*(y_offset + (50 - y_offset))):ToScreen()

		local title = self.NMEVars.n[self.NMEVars.s[hoveredNode.instanceID]].edit.getTitle(hoveredNode.instance)

		surface.SetDrawColor(_grey)
		surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
		draw.SimpleText(title, "DermaDefault", p2.x, p2.y - 18, _grey, 1, 1)
	end
end
*/

//
function ENT:OnRemove()
	self.ttdata_reset = true

	local csents = self.ttdata_csents or {}

	timer.Simple(0, function()
		if (self and self:IsValid()) then
			return
		end
		for k, v in pairs(csents) do
			if IsValid(v) then v:Remove() end
		end
	end)
end


//
function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.ttdata_csents = {}
end


//
function ENT:Think()
	self.BaseClass.Think(self)

	if ttlib.RenderDisable then return end

	if self.ttdata_reset then
		self.ttdata_reset = nil
		self:ttfunc_reset()
	end

	if not self.ttdata_visible then return end

	self.ttdata_visible = nil

	if self.ttdata_mode then
		self:ttfunc_setmatrix()
		self.ttdata_mode:think(self, self.ttdata_isdouble)
		if self.ttdata_dotracks then
			ttlib.tracks_think(self)
		end
	end
end


//
function ENT:Draw()
	self:DrawModel()

	if ttlib.RenderDisable then return end

	if self.ttdata_reset or FrameTime() == 0 or gui.IsConsoleVisible() then
		self.ttdata_visible = nil
		return
	end

	self.ttdata_visible = true

	if self.ttdata_mode then
		self.ttdata_mode:render(self, self.ttdata_isdouble)
		if self.ttdata_dotracks then
			ttlib.tracks_render(self)
		end

		-- if LocalPlayer():FlashlightIsOn() then --or #ents.FindByClass("*projectedtexture*") ~= 0 then
		-- 	render.PushFlashlightMode(true)
		-- 	self.ttdata_mode:render(self, self.ttdata_isdouble)
		-- 	if self.ttdata_dotracks then
		-- 		self:ttfunc_render_tracks()
		-- 	end
		-- 	render.PopFlashlightMode()
		-- end
	end
end


//
function ENT:ttfunc_reset()
	self.ttdata_mode = ttlib.modes[self.NMEVals.suspensionType]

	if self.ttdata_mode then
		self:ttfunc_setmatrix()

		self.ttdata_isdouble = self.NMEVals.systemMirror ~= 0
		self.ttdata_dotracks = self.NMEVals.trackEnable ~= 0

		self.ttdata_le_lastpos = self.ttdata_le_lastpos or Vector()
		self.ttdata_le_lastvel = self.ttdata_le_lastvel or 1
		self.ttdata_le_lastrot = self.ttdata_le_lastrot or 1
		self.ttdata_ri_lastpos = self.ttdata_ri_lastpos or Vector()
		self.ttdata_ri_lastvel = self.ttdata_ri_lastvel or 1
		self.ttdata_ri_lastrot = self.ttdata_ri_lastrot or 1

		self.ttdata_mode:createcsents(self)
		self.ttdata_mode:setup(self, self.ttdata_isdouble)
		self.ttdata_mode:think(self, self.ttdata_isdouble)

		if self.ttdata_dotracks then
			local values = self.NMEVals
			self.ttdata_trackvalues = {
				trackColor = values.trackColor,
				trackMaterial = values.trackMaterial,
				trackWidth = values.trackWidth,
				trackHeight = values.trackHeight,
				trackGuideY = values.trackGuideY,
				trackGrouser = values.trackGrouser,
				trackTension = values.trackTension,
				trackRes = values.trackRes,
			}
			ttlib.tracks_setup(self)
			ttlib.tracks_think(self)
		end

		ttlib.renderbounds(self)
	end
end


//
function ENT:ttfunc_setmatrix()
	local parent1 = self:GetParent()
	if parent1 and parent1:IsValid() then
		local parent2 = parent1:GetParent()
		if parent2 and parent2:IsValid() then
			parent1 = parent2
		end
	else
		parent1 = self
	end

	local base = parent1
	local axis = self:GetNW2Entity("axisEntity")

	if base == NULL then base = self end
	if axis == NULL then axis = self end

	local matrix = self.ttdata_matrix
	if not matrix then
		self.ttdata_matrix = Matrix()
		matrix = self.ttdata_matrix
	end

	matrix:SetTranslation(base:GetPos())
	matrix:SetAngles(axis:GetAngles())
end

function ENT:ttfunc_getmatrix()
	if not self.ttdata_matrix then
		return self:GetPos(), self:GetAngles()
	end
	return self.ttdata_matrix:GetTranslation(), self.ttdata_matrix:GetAngles()
end


//
local eff = "tanktracks_dust"

function ENT:ttfunc_playGroundFX(pos, scale)
	local fxdata = EffectData()

	fxdata:SetOrigin(pos)
	fxdata:SetScale(scale)

	util.Effect(eff, fxdata)
end

function ENT:ttfunc_getGroundFX(width)
	local scale = self.NMEVals.systemEffScale
	if scale == 0 then return end

	local max = width*scale

	local scale_le = math.min(max, 2*math.abs(self.ttdata_le_lastvel))
	local scale_ri = math.min(max, 2*math.abs(self.ttdata_ri_lastvel))

	if scale_le == 0 then scale_le = nil end
	if scale_ri == 0 then scale_ri = nil end

	return scale_le, scale_ri
end
