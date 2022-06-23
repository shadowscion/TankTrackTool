
// Tank Track Tool Addon
// by shadowscion


TOOL.Category   = "Construction"
TOOL.Name       = "#tool.tanktracktool.listname"
TOOL.Command    = nil
TOOL.ConfigName = ""


// Server/Shared
local table = table

if SERVER then
	util.AddNetworkString("tanktracktool_hud")

	TOOL.Controller = NULL
	TOOL.Chassis = NULL
	TOOL.CookieJar = {}
	TOOL.DOT = 0
end


// TOOL: Make sure we can use the entity
local function IsPropOwner(ply, ent, singleplayer)
	if singleplayer then return true end
	if CPPI then return ent:CPPIGetOwner() == ply end

	for k, v in pairs(g_SBoxObjects) do
		for b, j in pairs(v) do
			for _, e in pairs(j) do
				if e == ent and k == ply:UniqueID() then return true end
			end
		end
	end

	return false
end

function TOOL:CanManipulate(ply, trace, world)
	if not ply then return false end
	if not trace.Hit then return false end
	if not trace.Entity then return false end

	if trace.Entity:IsWorld() then return world end
	if string.find(trace.Entity:GetClass(), "npc_") or trace.Entity:GetClass() == "player" or trace.Entity:GetClass() == "prop_ragdoll" then return false end
	if not IsPropOwner(ply, trace.Entity, game.SinglePlayer()) then return false end

	return true
end


// TOOL: Send hud stuff
function TOOL:UpdateClient()
	net.Start("tanktracktool_hud")
		net.WriteEntity(self.Controller)
		net.WriteEntity(self.Chassis)
	net.Send(self:GetOwner())
end


// TOOL: Add entity to tool selection
local colors = {
	[1] = Color(0, 0, 255, 255), // controller
	[2] = Color(46, 204, 113, 255), // chassis
	[true] = Color(241, 196, 15, 255), // rollers
	[false] = Color(231, 75, 60, 255), // wheels
}

function TOOL:OnKeyPropRemove(e)
	self.Controller = NULL
	self.Chassis = NULL
	self.DOT = 0
	self:DeselectAllEntities()
	self:SetStage(0)
	self:UpdateClient()
end

function TOOL:GetMatrix()
	local m = self.Chassis:GetWorldTransformMatrix()

	if self.Controller:GetValueNME("systemRotate") ~= 0 then
		m:Rotate(Angle(0, -90, 0))
	end

	return m
end

function TOOL:SelectEntity(ent, notify)
	if self.CookieJar[ent] then return false end

	local is_roller = self:GetOwner():KeyDown(IN_SPEED)
	self.CookieJar[ent] = {
		Color = ent:GetColor(),
		Mode = ent:GetRenderMode(),
		Roller = is_roller,
	}

	ent:SetColor(colors[table.Count(self.CookieJar)] or colors[is_roller] or ent:GetColor())
	ent:SetRenderMode(RENDERMODE_TRANSALPHA)

	ent:CallOnRemove("tanktracktool_select", function(e)
		if self.Controller == e or self.Chassis == e then
			self:OnKeyPropRemove(e)
			return
		end

		self.CookieJar[e] = nil
	end)

	if IsValid(self.Chassis) and ent ~= self.Chassis then
		self.DOT = self.DOT + (self:GetMatrix():GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
		--self.DOT = self.DOT + (self.Chassis:GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
	end

	if notify then self:GetOwner():ChatPrint("Selected " .. tostring(ent)) end

	return true
end


// TOOL: Remove entity from tool selection
function TOOL:DeselectEntity(ent, notify)
	if not self.CookieJar[ent] then return false end
	if not IsValid(ent) then self.CookieJar[ent] = nil return false end

	ent:SetColor(self.CookieJar[ent].Color)
	ent:SetRenderMode(self.CookieJar[ent].Mode)
	ent:RemoveCallOnRemove("tanktracktool_select")

	if IsValid(self.Chassis) and ent ~= self.Chassis then
		self.DOT = self.DOT - (self:GetMatrix():GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
		--self.DOT = self.DOT - (self.Chassis:GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
	end

	if notify then self:GetOwner():ChatPrint("Deselected " .. tostring(ent)) end

	self.CookieJar[ent] = nil

	return true
end


// TOOL: Remove all entities from tool selection
function TOOL:DeselectAllEntities()
	for ent, _ in pairs(self.CookieJar) do
		self:DeselectEntity(ent)
	end
end


// TOOL: Left Click - Spawning controller
function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not self:CanManipulate(self:GetOwner(), trace, true) then return false end

	if trace.Entity:GetClass() == "sent_tanktracks_legacy" then
		if self:GetOwner():KeyDown(IN_SPEED) then
			self.CopySettings = {}
			for k, v in pairs(trace.Entity.NMEVars.n) do
				self.CopySettings[v.name] = trace.Entity:GetValueNME(v.name)
			end
		else
			if not self.CopySettings then return false end
			trace.Entity.ResetEditorNME = true
			for k, v in pairs(self.CopySettings) do
				trace.Entity:SetValueNME(true, k, nil, v)
			end
		end

		return true
	end

	local create_new = ents.Create("sent_tanktracks_legacy")

	local model = self:GetOwner():GetInfo("tanktracktool_model")
	if not util.IsValidModel(model) then model = "models/hunter/plates/plate.mdl" end

	create_new:SetModel(model)
	create_new:SetPos(trace.HitPos)
	create_new:SetAngles(trace.HitNormal:Angle() + Angle(90, 0, 0))
	create_new:Spawn()
	create_new:Activate()

	local phys = create_new:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Wake()
	end

	self:GetOwner():AddCount("sent_tanktracks_legacy", create_new)
	self:GetOwner():AddCleanup("sent_tanktracks_legacy", create_new)
	self:GetOwner():ChatPrint("You can edit this controller using the context menu (hold C and right click it).")

	undo.Create("sent_tanktracks_legacy")
		undo.AddEntity(create_new)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()

	if not trace.Entity:IsWorld() then
		constraint.Weld(create_new, trace.Entity, 0, trace.PhysicsBone, 0, 1, false)
	end

	create_new:SetCollisionGroup(COLLISION_GROUP_NONE)

	return true
end


// TOOL: Right Click - Selection entities
function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

	if self.CookieJar[trace.Entity] then
		if self.Controller == trace.Entity or self.Chassis == trace.Entity then
			if trace.Entity == self.Controller and IsValid(self.Chassis) then
				local valid = (math.abs(self.DOT) == table.Count(self.CookieJar) - 2)

				if table.Count(self.CookieJar) <= 3 then
					self:GetOwner():ChatPrint("You must select more than one wheel!")
					return false
				elseif not valid then
					self:GetOwner():ChatPrint("Wheels must be parallel to the green arrow!")
				else
					local tbl = table.GetKeys(self.CookieJar)

					table.RemoveByValue(tbl, self.Controller)
					table.RemoveByValue(tbl, self.Chassis)

					--local sort_pos = self.Chassis:GetPos() + self.Chassis:GetForward()*10000
					local sort_pos = self.Chassis:GetPos() + self:GetMatrix():GetForward()*10000

					table.sort(tbl, function(a, b)
						local bool_this = self.CookieJar[a].Roller
						local bool_that = self.CookieJar[b].Roller

						if bool_this ~= bool_that then
							return bool_that and not bool_this
						end

						if bool_this then
							return a:GetPos():Distance(sort_pos) > b:GetPos():Distance(sort_pos)
						else
							return a:GetPos():Distance(sort_pos) < b:GetPos():Distance(sort_pos)
						end
					end)

					table.insert(tbl, 1, self.Chassis)

					self.Controller:SetControllerLinks(tbl)
				end
			end

			self.DOT = 0
			self.Controller = NULL
			self.Chassis = NULL
			self:DeselectAllEntities()
			self:SetStage(0)

			self:UpdateClient()

			return true
		end

		self:DeselectEntity(trace.Entity, false)
		self:UpdateClient()

		return true
	end

	if self:GetStage() == 0 then
		if trace.Entity:GetClass() ~= "sent_tanktracks_legacy" then
			self:GetOwner():ChatPrint("Select a controller first!")
			return false
		end

		self:SelectEntity(trace.Entity, false)
		self.Controller = trace.Entity
		self:SetStage(1)
		self:UpdateClient()

		return true
	end

	if self:GetStage() == 1 then
		self:SelectEntity(trace.Entity, false)
		self.Chassis = trace.Entity
		self:SetStage(2)
		self:UpdateClient()

		return true
	end

	self:SelectEntity(trace.Entity, false)

	return true
end


// TOOL: Reload - Clearing selection or resetting controller
function TOOL:Reload(trace)
	if CLIENT then return true end

	if not trace.Hit then return false end
	if not trace.Entity then return false end

	if trace.Entity:IsWorld() then
		self.DOT = 0
		self.CopySettings = nil
		self.Controller = NULL
		self.Chassis = NULL
		self:DeselectAllEntities()
		self:SetStage(0)
		self:UpdateClient()

		return true
	end

	if trace.Entity:GetClass() ~= "sent_tanktracks_legacy" then return false end
	if IsValid(self.Controller) or IsValid(self.Chassis) then return false end
	if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

	if self:GetOwner():KeyDown(IN_SPEED) then
		trace.Entity.ResetEditorNME = true
		trace.Entity:ResetNME(true)
	else
		trace.Entity:SetControllerLinks()
	end
end


// Client
if SERVER then return end

// TOOL: Language
language.Add("tool.tanktracktool.listname", "Tank Tracks")
language.Add("tool.tanktracktool.name", "Tank Tracks")
language.Add("tool.tanktracktool.desc", "Renders animated tank tracks around a group of wheels.")

TOOL.ClientConVar = {
	["markers"] = 1,
	["model"] = "models/hunter/plates/plate.mdl",
}

TOOL.Information = {}

local function AddToolInfo(name, stage, desc, icon)
	table.insert(TOOL.Information, {name = name, stage = stage, icon = icon})
	language.Add("tool.tanktracktool." .. name, desc)
end

AddToolInfo("left_0a", 0, "Spawn a new controller")
AddToolInfo("left_0b", 0, "Hold [SHIFT] to copy a controller's settings (left click another to apply them)")
AddToolInfo("right_0a", 0, "Select a controller")
AddToolInfo("reload_0a", 0, "Unset chassis and wheels", "gui/r.png")
AddToolInfo("reload_0b", 0, "Hold [SHIFT] to reset controller settings", "gui/r.png")

AddToolInfo("right_1a", 1, "Select a chassis")
AddToolInfo("reload_1a", 1, "Deselect all entities", "gui/r.png")

AddToolInfo("right_2a", 2, "Select wheels")
AddToolInfo("right_2b", 2, "Hold [SHIFT] while selecting return rollers")
AddToolInfo("right_2c", 2, "Select the controller again to finalize")
AddToolInfo("reload_2a", 2, "Deselect all entities", "gui/r.png")


// TOOL: Hud
local Controller = NULL
local Chassis = NULL

local cam = cam
local math = math
local draw = draw
local render = render
local surface = surface
local IsValid = IsValid

local arrow_mat = Material( "widgets/arrow.png", "unlitsmooth" )

net.Receive("tanktracktool_hud", function()
	Controller = net.ReadEntity() or NULL
	Chassis = net.ReadEntity() or NULL
end)

function TOOL:DrawHUD()

	local trace = LocalPlayer():GetEyeTrace()
	if not trace.Hit or LocalPlayer():InVehicle() then return end

	local traceEnt = trace.Entity

	// always show this, to avoid any confusion of how wheels should be set up
	if IsValid(Chassis) and IsValid(Controller) then

		local xlen
		local ylen

		local m = Chassis:GetWorldTransformMatrix()

		if Controller:GetValueNME("systemRotate") ~= 0 then
			m:Rotate(Angle(0, -90, 0))

			local min, max = Chassis:GetModelBounds()

			xlen = (math.abs(max.y) + math.abs(min.y))*0.5
			ylen = (math.abs(max.x) + math.abs(min.x))*0.5
		else
			local min, max = Chassis:GetModelBounds()

			xlen = (math.abs(max.x) + math.abs(min.x))*0.5
			ylen = (math.abs(max.y) + math.abs(min.y))*0.5
		end

		local center = Chassis:OBBCenter()
		center:Rotate(-m:GetAngles())

		m:Translate(center)

		cam.Start3D()
			render.SetMaterial(arrow_mat)

			local pos = m:GetTranslation()
			local fo = m:GetForward()
			local ri = m:GetRight()

			render.DrawBeam(pos - fo*xlen, pos + fo*xlen, 4, 1, 0, HSVToColor(140, 0.77, 1))
			render.DrawBeam(pos - fo*xlen + ri*ylen, pos + fo*xlen + ri*ylen, 4, 1, 0, HSVToColor(5, 0.73, 1))
			render.DrawBeam(pos - fo*xlen - ri*ylen, pos + fo*xlen - ri*ylen, 4, 1, 0, HSVToColor(5, 0.73, 1))

		cam.End3D()
	end

	// disable if hud helpers are disabled
	if self:GetClientInfo("markers") ~= 0 then
		if IsValid(Controller) then
			local pos = Controller:GetPos():ToScreen()
			draw.SimpleTextOutlined("Controller (" .. Controller:EntIndex() .. ")", "Trebuchet18", pos.x, pos.y, Color(255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
		else
			cam.Start3D()
			for k, v in pairs(ents.FindInSphere(EyePos(), 200)) do
				if v:GetClass() == "sent_tanktracks_legacy" and v ~= traceEnt then
					local mins, maxs = v:GetModelBounds()
					render.DrawWireframeBox(v:GetPos(), v:GetAngles(), mins, maxs, color_white)
				end
			end
			cam.End3D()
		end

		if not traceEnt or traceEnt:IsWorld() then return end

		if IsValid(Controller) then
			cam.Start3D()
				local min, max = traceEnt:GetCollisionBounds()
				render.DrawWireframeBox(traceEnt:GetPos(), traceEnt:GetAngles(), min, max, Color(150, 150, 150, 255), true)
			cam.End3D()
		end

		if not traceEnt or traceEnt:IsWorld() then return end

		if traceEnt:GetClass() == "sent_tanktracks_legacy" and self:GetStage() == 0 then
			local pos = traceEnt:GetPos()
			local fade = 1 - math.min(500, pos:Distance(EyePos())) / 500

			if fade == 0 then return end

			pos = pos:ToScreen()

			draw.SimpleTextOutlined("Edit me!", "Trebuchet18", pos.x, pos.y, Color(255, 255, 255, 255*fade), 0, 0, 1, Color(0, 0, 0, 255*fade))

			cam.Start3D()
				local min, max = traceEnt:GetCollisionBounds()
				render.DrawWireframeBox(traceEnt:GetPos(), traceEnt:GetAngles(), min, max, Color(150, 150, 150, 255*fade), true)
			cam.End3D()

			if IsValid(traceEnt.ttdata_chassis) then
				local lpos = traceEnt.ttdata_chassis:GetPos():ToScreen()

				surface.SetDrawColor(46, 204, 113, 255*fade)
				surface.DrawLine(pos.x, pos.y, lpos.x, lpos.y)
				surface.DrawRect(lpos.x - 3, lpos.y - 3, 6, 6)
			end

			local parts = traceEnt.ttdata_parts
			if parts then
				local r, g, b
				local pos = traceEnt:GetPos():ToScreen()

				for i = 1, #parts do
					local part1 = parts[i][1]
					local p1 = part1.entity:GetPos():ToScreen()

					if i == traceEnt.ttdata_sprocket then
						r, g, b = 52, 152, 219
						surface.SetDrawColor(r, g, b, 255*fade)
						surface.DrawLine(p1.x, p1.y, pos.x, pos.y)
					else
						if i > #parts - (traceEnt.ttdata_rollercount or 0) then
							r, g, b = 241, 196, 15
						else
							r, g, b = 231, 75, 60
						end
					end

					surface.SetDrawColor(r, g, b, 255*fade)
					surface.DrawRect(p1.x - 3, p1.y - 3, 6, 6)
				end
			end
		end
	end
end


// TOOL: CPanel
function TOOL.BuildCPanel(self)

	local cooldown = SysTime()

	local pnl = vgui.Create("DForm")
	pnl:SetName("Entity")

	local btn = vgui.Create("DButton", pnl)
	btn:SetText("resync")

	btn.DoClick = function()
		if SysTime() - cooldown < 1 then return else cooldown = SysTime() end

		for k, v in pairs(ents.FindByClass("sent_tanktracks*")) do
			v.NMESync = nil
		end
	end
	pnl:AddItem(btn)

	pnl:CheckBox("Disable Rendering", "tanktracktool_disable")

	local cbox = pnl:CheckBox("Adaptive Detail", "tanktracktool_detail_incr")
	cbox:SetToolTip("Track vertex detail increases as movement speed increases")

	pnl:NumSlider("Maximum Detail", "tanktracktool_detail_max", 4, 16, 0)

	local text = pnl:TextEntry("Entity model:", "tanktracktool_model")

	local mlist = vgui.Create("DPanel", pnl)
	mlist:SetTall(72)
	mlist:Dock(TOP)
	mlist:DockPadding(0, 0, 0, 8)

	local btn1 = vgui.Create("DImageButton", mlist)
	btn1:SetImage("vgui/entities/sent_tanktracks_legacy")
	btn1:SetSize(64, 64)
	btn1.DoClick = function()
		RunConsoleCommand("gm_spawnsent", "sent_tanktracks_legacy")
		surface.PlaySound("ui/buttonclickrelease.wav")
	end

	local btn2 = vgui.Create("DImageButton", mlist)
	btn2:SetImage("vgui/entities/sent_tanktracks_auto")
	btn2:SetSize(64, 64)
	btn2.DoClick = function()
		RunConsoleCommand("gm_spawnsent", "sent_tanktracks_auto")
		surface.PlaySound("ui/buttonclickrelease.wav")
	end

	mlist.PerformLayout = function(_, w, h)
		local wdiff = w*0.5 - 64
		local hdiff = h*0.5 - 32

		btn1:SetPos(wdiff - hdiff*0.5, hdiff)
		btn2:SetPos(wdiff + 64 + hdiff*0.5, hdiff)
	end
	mlist.Paint = nil

	pnl:AddItem(mlist)

	local help = pnl:ControlHelp("Use the context menu (hold C and right click the controller) to configure. These entities can also be spawned from the Q menu.")

	self:AddPanel(pnl)


	local pnl = vgui.Create("DForm")
	pnl:SetName("Tool")

	pnl:CheckBox("Enable HUD Selection Helpers", "tanktracktool_markers")

	self:AddPanel(pnl)

end
