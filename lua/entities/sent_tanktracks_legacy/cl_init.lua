
//
include("shared.lua")

ENT.NMEIcon = "tanktracktool/icons/editor.png"
ENT.NMEWiki = "https://github.com/shadowscion/TankTrackTool"

local disable = GetConVar("tanktracktool_disable")


//
net.Receive("tanktracktool_legacy_sync", function(len)
	local ent = Entity(net.ReadUInt(32))
	if not IsValid(ent) or ent:GetClass() ~= "sent_tanktracks_legacy" then return end

	ent:TriggerNME("sync_links", net.ReadTable())
end)

function ENT:TriggerNME(type, ...)
	if type == "editor_open" or type == "editor_close" then
		local editor = select(1, ...)
		if IsValid(editor) then
			editor.DTree.RootNode:ExpandRecurse(true)
		end
	elseif type == "request_sync" then
		net.Start("tanktracktool_legacy_sync")
		net.WriteUInt(self:EntIndex(), 32)
		net.SendToServer()
	elseif type == "sync_links" then
		self.ttdata_links = select(1, ...)
		self.ttdata_reset = true
	else
		self.ttdata_reset = true
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ttlib.RenderDisable then return end

	if self.ttdata_reset then
		self.ttdata_reset = nil
		self:ttfunc_reset()
	end
end


//
ttlib_RenderOverride = ttlib_RenderOverride or {}
local RenderOverride = ttlib_RenderOverride

local function real_radius(ent)
    if ent:GetHitBoxBounds(0, 0) then
        local min, max = ent:GetHitBoxBounds(0, 0)
        local bounds = (max - min)*0.5
        return math.max(bounds.x, bounds.y, bounds.z)
    end
    return ent:GetModelRadius() or 12
end

local function GetAngularVelocity(ent, pos, ang)
    local dir = WorldToLocal(ent:GetForward() + pos, ang, pos, ang)
    local ang = math.deg(math.atan2(dir.z, dir.x))

    ent.m_DeltaAngle = ent.m_DeltaAngle or 0

    local ang_vel = (ang - ent.m_DeltaAngle + 180) % 360 - 180

    ent.m_DeltaAngle = ang

    return ang_vel--/FrameTime()
end

local function UpdateTracks(self, pos, ang)
	local parts = self.ttdata_parts
	if not parts then return end

    local sprocket = self.ttdata_sprocket
    local groundfx = self.ttdata_dogroundfx

	for i = 1, #parts do
		local wheel = parts[i][1]
		local ent = wheel.entity

		if not IsValid(ent) then
			self.ttdata_reset = true
			return
		end

		wheel[1] = WorldToLocal(ent:GetPos(), ent:GetAngles(), pos, ang)
		wheel[1].y = self.ttdata_trackoffset

		if i == sprocket then
			local rot_le = GetAngularVelocity(ent, pos, ang)
			self.ttdata_le_lastvel = rot_le / (math.pi * 1.5) // no idea if this is correct nor why it works
		end
	end

	ttlib.tracks_think(self)

	return true
end

local function RenderTracks(self, ply, eyepos, eyedir)
	if not IsValid(self) then
		RenderOverride[self] = nil
		return
	end

	local chassis = self.ttdata_chassis

	if not IsValid(chassis) then
		RenderOverride[self] = nil
		return
	end

	if chassis:IsDormant() then return end

	self.ttdata_matrix = self.ttdata_chassis:GetWorldTransformMatrix()
	if self.ttdata_rotate then
		self.ttdata_matrix:Rotate(self.ttdata_rotate)
	end

	local pos, ang = self.ttdata_matrix:GetTranslation(), self.ttdata_matrix:GetAngles()

    local dot = eyedir:Dot(pos - eyepos)
    if dot < 0 and math.abs(dot) > 100 then return end

    if UpdateTracks(self, pos, ang) then
    	ttlib.tracks_render(self)
   	end
end

--local skybox
--hook.Add("PreDrawSkyBox", "tanktracks_legacy", function() skybox = true end)

hook.Add("PreDrawOpaqueRenderables", "tanktracks_legacy", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	if ttlib.RenderDisable then return end

	if FrameTime() == 0 or gui.IsConsoleVisible() or next(RenderOverride) == nil then
		return
	end

	local ply = LocalPlayer()
	local eyepos = EyePos()
	local eyedir = EyeVector()

	for controller in pairs(RenderOverride) do
		RenderTracks(controller, ply, eyepos, eyedir)
	end
end)



function ENT:ttfunc_reset()
	if not self.ttdata_links then return end

	RenderOverride[self] = nil

	self.ttdata_chassis = self.ttdata_links[1]
	if not IsValid(self.ttdata_chassis) then
		self.ttdata_parts = nil
		return
	end

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
		trackFlip = values.trackFlip,
	}

	self.ttdata_matrix = self.ttdata_chassis:GetWorldTransformMatrix()
	if values.systemRotate ~= 0 then
		self.ttdata_rotate = Angle(0, -90, 0)
		self.ttdata_matrix:Rotate(self.ttdata_rotate)
	else
		self.ttdata_rotate = nil
	end

	local pos, ang = self.ttdata_matrix:GetTranslation(), self.ttdata_matrix:GetAngles()

	self.ttdata_parts = {}
	for i = 2, #self.ttdata_links do
		local ent = self.ttdata_links[i]

		if IsValid(ent) then // worldspawn[0] == invalid
			local part = { {entity = ent, radius = real_radius(ent)} }
			part.id = table.insert(self.ttdata_parts, part)
			part[1][1] = WorldToLocal(ent:GetPos(), ent:GetAngles(), pos, ang)
		end
	end

	if #self.ttdata_parts == 0 then return end

	--if values.rollderRadius ~= 0 or values.wheelRadius ~= 0 then
		local rollercount = 0
		for i = 1, #self.ttdata_parts do
			local node_this = self.ttdata_parts[i][1]
			local node_next = self.ttdata_parts[i == #self.ttdata_parts and 1 or i + 1][1]

			node_this.radius = node_this.radius + (rollercount > 0 and values.rollerRadius or values.wheelRadius) - values.trackHeight*0.5

			local dir_next = node_next[1] - node_this[1]
			if dir_next.x >= 0 then
				rollercount = rollercount + 1
			end
		end
		self.ttdata_rollercount = rollercount
	--end

	self.ttdata_dogroundfx = values.systemEffScale ~= 0 and values.systemEffScale
	self.ttdata_trackoffset = self.ttdata_parts[1][1][1].y + (self.ttdata_trackvalues.trackFlip ~= 0 and -1 or 1)*values.trackOffsetY

	self.ttdata_sprocket = math.Clamp(values.wheelSprocket, 1, #self.ttdata_parts)

	self.ttdata_le_lastpos = self.ttdata_le_lastpos or Vector()
	self.ttdata_le_lastvel = self.ttdata_le_lastvel or 1
	self.ttdata_le_lastrot = self.ttdata_le_lastrot or 1

	ttlib.tracks_setup(self)
	ttlib.tracks_think(self)

	RenderOverride[self] = true
end
