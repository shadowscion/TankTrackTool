--[[
	Tank Track Controller Addon
	by shadowscion
]]--

TOOL.Category   = "Construction"
TOOL.Name       = "#tool.gmod_tool_ttc.listname"
TOOL.Command    = nil
TOOL.ConfigName = ""


---------------------------------------------------------------
-- Server/Shared
local table = table

if SERVER then
	util.AddNetworkString("ttc.tool_hud")

	TOOL.Controller = NULL
	TOOL.Chassis = NULL
	TOOL.CookieJar = {}
end


-- TOOL: Make sure we can use the entity
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
	--if trace.Entity:GetClass() ~= "prop_physics" and trace.Entity:GetClass() ~= "gmod_ent_ttc" then return false end
	if not IsPropOwner(ply, trace.Entity, game.SinglePlayer()) then return false end

	-- local check_parent = true
	-- if IsValid(self.Controller) and trace.Entity == self.Controller then check_parent = false end
	-- if IsValid(self.Chassis) and trace.Entity == self.Chassis then check_parent = false end

	-- if check_parent then
	-- 	if IsValid(trace.Entity:GetParent()) then
	-- 		ply:ChatPrint("Parented wheels are not supported!")
	-- 		return false
	-- 	end
	-- end

	return true
end


-- TOOL: Send hud stuff
function TOOL:UpdateClient()
	net.Start("ttc.tool_hud")
		net.WriteEntity(self.Controller)
		net.WriteEntity(self.Chassis)
	net.Send(self:GetOwner())
end


-- TOOL: Add entity to tool selection
local colors = {
	Color(0, 0, 255, 125),
	Color(0, 255, 0, 125),
}

function TOOL:OnKeyPropRemove(e)
	self.Controller = NULL
	self.Chassis = NULL

	for ent, _ in pairs(self.CookieJar) do
		if ent == e then self.CookieJar[ent] = nil continue end

		if not self.CookieJar[ent] then continue end

		ent:SetColor(self.CookieJar[ent].Color)
		ent:SetRenderMode(self.CookieJar[ent].Mode)
		ent:RemoveCallOnRemove("ttc_tool_select")

		self.CookieJar[ent] = nil
	end
end

function TOOL:SelectEntity(ent, notify)
	if self.CookieJar[ent] then return false end

	self.CookieJar[ent] = {
		-- Order = table.Count(self.CookieJar),
		Color = ent:GetColor(),
		Mode = ent:GetRenderMode(),
	}

	ent:SetColor(colors[table.Count(self.CookieJar)] or Color(255, 255, 0, 125))
	ent:SetRenderMode(RENDERMODE_TRANSALPHA)

	ent:CallOnRemove("ttc_tool_select", function(e)
		if self.Controller == e or self.Chassis == e then
			self:OnKeyPropRemove(e)
			return
		end

		self.CookieJar[e] = nil
	end)

	if notify then self:GetOwner():ChatPrint("Selected " .. tostring(ent)) end

	return true
end


-- TOOL: Remove entity from tool selection
function TOOL:DeselectEntity(ent, notify)
	if not self.CookieJar[ent] then return false end
	if not IsValid(ent) then self.CookieJar[ent] = nil return false end

	ent:SetColor(self.CookieJar[ent].Color)
	ent:SetRenderMode(self.CookieJar[ent].Mode)
	ent:RemoveCallOnRemove("ttc_tool_select")

	if notify then self:GetOwner():ChatPrint("Deselected " .. tostring(ent)) end

	self.CookieJar[ent] = nil

	return true
end


-- TOOL: Remove all entities from tool selection
function TOOL:DeselectAllEntities()
	for ent, _ in pairs(self.CookieJar) do
		self:DeselectEntity(ent)
	end
end


-- TOOL: Left Click - Spawning controller
function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not self:CanManipulate(self:GetOwner(), trace, true) then return false end

	if trace.Entity:GetClass() == "gmod_ent_ttc" then
		if self:GetOwner():KeyDown(IN_SPEED) then
			self.CopySettings = table.Copy(trace.Entity:GetNetworkVars())
		else
			if not self.CopySettings then return false end
			for func, value in pairs(self.CopySettings) do
				if trace.Entity["Set" .. func] then trace.Entity["Set" .. func](trace.Entity, value) end
			end
		end

		return true
	end

	local create_new = ents.Create("gmod_ent_ttc")

	create_new:SetDefaults()
	create_new:SetPos(trace.HitPos)
	create_new:SetAngles(trace.HitNormal:Angle() + Angle(90, 0, 0))
	create_new:Spawn()
	create_new:Activate()

	create_new:SetNetworkedInt("ownerid", self:GetOwner():UserID())

	self:GetOwner():AddCount("gmod_ent_ttc", create_new)
	self:GetOwner():AddCleanup("gmod_ent_ttc", create_new)

	undo.Create("gmod_ent_ttc")
		undo.AddEntity(create_new)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()

	if not trace.Entity:IsWorld() then
		constraint.Weld(create_new, trace.Entity, 0, trace.PhysicsBone, 0, 1, false)
	end

	return true
end


-- TOOL: Right Click - Selection entities
function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

	if self.CookieJar[trace.Entity] then
		if self.Controller == trace.Entity or self.Chassis == trace.Entity then
			if trace.Entity == self.Controller and IsValid(self.Chassis) then
				-- local tbl = {}
				-- for k, v in SortedPairsByMemberValue(self.CookieJar, "Order") do
				-- 	if v.Order == 0 then continue end
				-- 	table.insert(tbl, k)
				-- end

				local tbl = table.GetKeys(self.CookieJar)

				table.RemoveByValue(tbl, self.Controller)
				table.RemoveByValue(tbl, self.Chassis)

				table.sort(tbl, function(this, that)
					return this:GetPos():Distance(self.Chassis:GetPos() + self.Chassis:GetForward()*10000) < that:GetPos():Distance(self.Chassis:GetPos() + self.Chassis:GetForward()*10000)
				end)

				table.insert(tbl, 1, self.Chassis)

				self.Controller:SetLinkedEntities(tbl)
			end

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
		if trace.Entity:GetClass() ~= "gmod_ent_ttc" then
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


-- TOOL: Reload - Clearing selection or resetting controller
function TOOL:Reload(trace)
	if CLIENT then return true end

	if not trace.Hit then return false end
	if not trace.Entity then return false end

	if trace.Entity:IsWorld() then
		self.CopySettings = nil
		self.Controller = NULL
		self.Chassis = NULL
		self:DeselectAllEntities()
		self:SetStage(0)
		self:UpdateClient()

		return true
	end

	if trace.Entity:GetClass() ~= "gmod_ent_ttc" then return false end
	if IsValid(self.Controller) or IsValid(self.Chassis) then return false end
	if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

	if self:GetOwner():KeyDown(IN_SPEED) then
		trace.Entity:SetDefaults()
	else
		trace.Entity:UnsetLinkedEntities()
	end
end



---------------------------------------------------------------
-- Client
if SERVER then return end


-- TOOL: Language
language.Add("tool.gmod_tool_ttc.listname", "Tank Tracks")
language.Add("tool.gmod_tool_ttc.name",     "Tank Tracks")
language.Add("tool.gmod_tool_ttc.desc",     "Renders animated tank tracks around a group of wheels.")
language.Add("tool.gmod_tool_ttc.0",        "Left Click: Spawn a controller, hold shift to copy configuration, click another controller to apply copied settings. Right Click: Select a controller. Reload: Clear selection or unlink all entities.")
language.Add("tool.gmod_tool_ttc.1",        "Right Click: Select your chassis. Reload: Clear selection.")
language.Add("tool.gmod_tool_ttc.2",        "Right Click: Select your wheels. Select the controller again to finalize. Reload: Clear selection.")

language.Add("Undone_gmod_ent_ttc", "Undone Tank Track Controllers")
language.Add("Cleaned_gmod_ent_ttc", "Cleaned up Tank Track Controllers")
language.Add("Cleanup_gmod_ent_ttc", "Tank Track Controllers")


-- TOOL: Hud
local enable_hud_markers = CreateClientConVar("ttc_hud_markers", "1", true, false)
local enable_hud_helpers = CreateClientConVar("ttc_hud_helpers", "1", true, false)

local Controller = NULL
local Chassis = NULL

local cam = cam
local math = math
local draw = draw
local render = render
local surface = surface
local IsValid = IsValid

net.Receive("ttc.tool_hud", function()
	Controller = net.ReadEntity() or NULL
	Chassis = net.ReadEntity() or NULL
end)

function TOOL:DrawHUD()
	local trace = LocalPlayer():GetEyeTrace()
	if not trace.Hit then return end

	if enable_hud_helpers:GetBool() then
		if IsValid(Controller) then
			local pos = Controller:GetPos():ToScreen()
			draw.SimpleText("Controller (" .. Controller:EntIndex() .. ")", "BudgetLabel", pos.x, pos.y)
		end

		if IsValid(Chassis) then
			local pos = Chassis:GetPos():ToScreen()

			draw.SimpleText("Chassis (" .. Chassis:EntIndex() .. ")", "BudgetLabel", pos.x, pos.y)

			local dir_f = Chassis:LocalToWorld(Vector(12, 0, 0)):ToScreen()
			local dir_r = Chassis:LocalToWorld(Vector(0, 12, 0)):ToScreen()
			local dir_u = Chassis:LocalToWorld(Vector(0, 0, 12)):ToScreen()

			surface.SetDrawColor(0, 255, 0, 200)
			surface.DrawLine(pos.x, pos.y, dir_f.x, dir_f.y)

			surface.SetDrawColor(255, 0, 0, 200)
			surface.DrawLine(pos.x, pos.y, dir_r.x, dir_r.y)

			surface.SetDrawColor(0, 0, 255, 200)
			surface.DrawLine(pos.x, pos.y, dir_u.x, dir_u.y)
		end

		if not trace.Entity or trace.Entity:IsWorld() then return end

		if IsValid(Controller) then
			cam.Start3D()
				local min, max = trace.Entity:GetCollisionBounds()
				render.DrawWireframeBox(trace.Entity:GetPos(), trace.Entity:GetAngles(), min, max, Color(150, 150, 150, 255), true)
			cam.End3D()
		end
	end

	if enable_hud_markers:GetBool() then
		if not trace.Entity or trace.Entity:IsWorld() then return end

		if trace.Entity:GetClass() == "gmod_ent_ttc" and self:GetStage() == 0 then
			if trace.Entity:GetNetworkedInt("ownerid") ~= LocalPlayer():UserID() then return end

			local pos = trace.Entity:GetPos()
			local fade = 1 - math.min(500, pos:Distance(EyePos())) / 500

			if fade == 0 then return end

			pos = pos:ToScreen()

			cam.Start3D()
				local min, max = trace.Entity:GetCollisionBounds()
				render.DrawWireframeBox(trace.Entity:GetPos(), trace.Entity:GetAngles(), min, max, Color(150, 150, 150, 255*fade), true)
			cam.End3D()

			for _, ent in ipairs(trace.Entity.ttc_wheels) do
				if not IsValid(ent) then continue end
				local lpos = ent:GetPos():ToScreen()
				if ent == trace.Entity.ttc_sprocket then surface.SetDrawColor(100, 100, 255, 150*fade) else surface.SetDrawColor(255, 100, 100, 100*fade) end
				surface.DrawLine(pos.x, pos.y, lpos.x, lpos.y)
				surface.DrawRect(lpos.x - 3, lpos.y - 3, 6, 6)
			end

			if IsValid(trace.Entity.ttc_chassis) then
				local lpos = trace.Entity.ttc_chassis:GetPos():ToScreen()
				surface.SetDrawColor(100, 255, 100, 100*fade)
				surface.DrawLine(pos.x, pos.y, lpos.x, lpos.y)
				surface.DrawRect(lpos.x - 3, lpos.y - 3, 6, 6)
			end

			surface.SetDrawColor(255, 255, 255, 100*fade)
			for i = 1, #trace.Entity.ttc_spline - 1 do
				local p1 = trace.Entity.ttc_spline[i]:ToScreen()
				local p2 = trace.Entity.ttc_spline[i + 1]:ToScreen()
				surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
				surface.DrawRect(p1.x - 3, p1.y - 3, 6, 6)
			end
		end
	end
end


-- TOOL: CPanel
function TOOL.BuildCPanel(self)
    self.Paint = function(pnl, w, h)
        draw.RoundedBox(0, 0, 0, w, 20, Color(50, 50, 50, 255))
        draw.RoundedBox(0, 1, 1, w - 2, 18, Color(125, 125, 125, 255))
    end

    self:AddControl("Header", {
        Description = "Use the context menu (hold C and right click the controller) to configure!"
    })

    self:AddControl("Toggle", {
    	Label = "Enable HUD Selection Helpers",
    	Command = "ttc_hud_helpers",
    })

    self:AddControl("Toggle", {
    	Label = "Enable HUD Entity Markers",
    	Command = "ttc_hud_markers",
    })

    self:AddControl("Toggle", {
    	Label = "Disable Rendering",
    	Command = "ttc_block_all",
    })

    self:AddControl("Button", {
    	Label = "Refresh All",
    	Command = "ttc_refresh",
    })
end
