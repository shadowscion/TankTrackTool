
// BY SHADOWSCION

if SERVER then
	util.AddNetworkString("NMESync")
	util.AddNetworkString("NMEEdit")

	AddCSLuaFile("needmoreedits/editor.lua")
	AddCSLuaFile("needmoreedits/entity.lua")
else
	include("needmoreedits/editor.lua")
end

if not NeedMoreEdits then
	NeedMoreEdits = {Meta = {}}
	NeedMoreEdits.Meta.__index = NeedMoreEdits.Meta
end

include("needmoreedits/entity.lua")


//
NeedMoreEdits.debug = false
local dbg = function(msg)
	MsgC(Color(255, 255, 0), "NME -> ", Color(0, 255, 255), msg .. "\n")
end

local net, util, math, table, string =
	  net, util, math, table, string

local NME = NeedMoreEdits.Meta

function NeedMoreEdits.Install(ent, tbl)
	if not IsValid(ent) or not tbl or getmetatable(tbl) ~= NME then return end
	tbl:Init(ent)
end

function NeedMoreEdits.New()
	return setmetatable({n = {}, s = {}, c = {}}, NME)
end

properties.Add("NME_edit", {
	MenuLabel     = "Edit",
	Order         = 90001,
	PrependSpacer = true,
	MenuIcon      = "icon16/brick.png",

	Filter = function(self, ent, ply)
		if not IsValid(ent) then
			return false
		end
		if not scripted_ents.IsBasedOn(ent:GetClass(), "base_nme") then
			return false
		end
		if not gamemode.Call("CanProperty", ply, "NME_edit", ent) then
			return false
		end
		return true
	end,

	Action = function(self, ent)
		if not NeedMoreEdits.Editor or not IsValid(NeedMoreEdits.Editor) then
			NeedMoreEdits.Editor = g_ContextMenu:Add("nme_editor")

			local h = math.Round(ScrH() / 2)*2
			local w = math.Round(ScrW() / 2)*2

			local tall = math.Round((h*0.8) / 2)*2
			local wide = 380

			NeedMoreEdits.Editor:SetSize(wide + 8, tall + 8)
			NeedMoreEdits.Editor:SetPos(w - wide - 50 - 4, h - 50 - tall - 4)

			local x, y = NeedMoreEdits.Editor:GetPos()
			local w, h = NeedMoreEdits.Editor:GetSize()
			NeedMoreEdits.Editor.Bounds = {x = x, y = y, w = w, h = h}
		end

		NeedMoreEdits.Editor:SetEntity(ent)
		NeedMoreEdits.Editor:InvalidateLayout(true)
	end,

	MenuOpen = function(self, menu, ent, tr)
		menu.m_Image:SetImage(ent.NMEIcon or self.MenuIcon)
		menu:SetText(string.format("%s %s", self.MenuLabel, ent.PrintName ~= "" and ent.PrintName or ent:GetClass()))
	end,
})


//
if CLIENT then
	function NeedMoreEdits.RequestSync(ent)
		if not IsValid(ent) or not istable(ent.NMEVars) or getmetatable(ent.NMEVars) ~= NME then return end

		net.Start("NMESync")
		net.WriteUInt(ent:EntIndex(), 32)
		net.WriteString(ent.NMEUID or "")
		net.SendToServer()
	end

	hook.Add("NotifyShouldTransmit", "NMESync", function(ent, bool)
		if bool then ent.NMESync = nil end
	end)

	net.Receive("NMESync", function(len, ply)
		local ent = Entity(net.ReadUInt(32))
		if not IsValid(ent) or not scripted_ents.IsBasedOn(ent:GetClass(), "base_nme") then
			return
		end

		local len = net.ReadUInt(32)
		local dat = net.ReadData(len)
		local uid = net.ReadString()

		if uid == util.CRC(dat) then
			ent.NMEVals = ent:DecompressNME(dat)
			ent.NMEUID = uid
			ent:TriggerNME("sync")
		end
	end)

	net.Receive("NMEEdit", function(len)
		local ent = Entity(net.ReadUInt(32))
		if not IsValid(ent) or not scripted_ents.IsBasedOn(ent:GetClass(), "base_nme") then
			return
		end

		local len = net.ReadUInt(32)
		local dat = net.ReadData(len)

		ent:RestoreNME(nil, util.JSONToTable(util.Decompress(dat)))

		if net.ReadBool() and IsValid(NeedMoreEdits.Editor) and NeedMoreEdits.Editor.m_Entity == ent then
			NeedMoreEdits.Editor:ResetControls()
		end
	end)

	function NME:Update(ent, name, instance, value)
		ent:TriggerNME("update", name, instance, value)
	end

	function NME:SetHelp(name, help)
		local var = self:GetVar(name)
		if var then var.edit.help = help end
	end

	function NME:SetCallbacks(name, callbacks)
		local var = self:GetVar(name)
		if var and istable(callbacks) then
			var.edit.callbacks = callbacks
		end
	end
else
	local sync_queue
	local function HandleSync()
		if not sync_queue then return end

		local ent, queue = next(sync_queue)

		if not ent or not queue then
			sync_queue = nil
			return
		end

		if not IsValid(ent) then
			sync_queue[ent] = nil
			return
		end

		local dat = ent:CompressNME()
		local uid = util.CRC(dat)

		ent.NMEUID = uid

		local filter = {}
		for k, v in pairs(queue) do
			if IsValid(k) and v ~= uid then
				table.insert(filter, k)
			else
				if NeedMoreEdits.debug then dbg(string.format("[%s] already synced with [%s]", tostring(k), uid)) end
			end
		end

		if next(filter) then
			local len = string.len(dat)

			net.Start("NMESync")
			net.WriteUInt(ent:EntIndex(), 32)
			net.WriteUInt(len, 32)
			net.WriteData(dat)
			net.WriteString(uid)
			net.Send(filter)

			if NeedMoreEdits.debug then dbg(string.format("syncing [%s][%.3f KiB] with [%d] players", uid, len*0.0009765625, #filter)) end
		end

		sync_queue[ent] = nil
	end

	local update_queue
	function NME:Update(ent, name, instance, value)
		if not update_queue then update_queue = {} end
		if not update_queue[ent] then update_queue[ent] = {} end

		if instance then
			if not update_queue[ent][name] then update_queue[ent][name] = {} end
			update_queue[ent][name][instance] = value
			return
		end

		update_queue[ent][name] = value
	end

	local function HandleUpdate()
		if not update_queue then return end

		local ent, queue = next(update_queue)

		if not ent or not queue then
			update_queue = nil
			return
		end

		if not IsValid(ent) then
			update_queue[ent] = nil
			return
		end

		local dat = util.Compress(util.TableToJSON(queue))
		local len = string.len(dat)

		net.Start("NMEEdit")
		net.WriteUInt(ent:EntIndex(), 32)
		net.WriteUInt(len, 32)
		net.WriteData(dat)
		net.WriteBool(ent.ResetEditorNME or false)
		net.Broadcast()

		ent.ResetEditorNME = nil

		update_queue[ent] = nil

		if NeedMoreEdits.debug then dbg(string.format("updating [%s] with [%sb] of data", tostring(ent), len)) end
	end

	hook.Add("Think", "NMEThink", function()
		HandleSync()
		HandleUpdate()
	end)

	net.Receive("NMESync", function(len, ply)
		if not IsValid(ply) then return end

		local ent = Entity(net.ReadUInt(32))
		if not IsValid(ent) or not scripted_ents.IsBasedOn(ent:GetClass(), "base_nme") then
			return
		end

		if not sync_queue then sync_queue = {} end
		if not sync_queue[ent] then sync_queue[ent] = {} end

		sync_queue[ent][ply] = net.ReadString() or ""
	end)

	net.Receive("NMEEdit", function(len, ply)
		if not IsValid(ply) then return end

		local ent = Entity(net.ReadUInt(32))
		if not IsValid(ent) or not scripted_ents.IsBasedOn(ent:GetClass(), "base_nme") then
			return
		end

		ent:RestoreNME(true, net.ReadTable())
	end)
end


//
local getters = {}
getters.float = function(self, value)
	if not value or not tonumber(value) then return self.edit.def end
	if value < self.edit.min then return self.edit.min elseif value > self.edit.max then return self.edit.max end
	return math.Round(value, 2)
end
getters.int = function(self, value)
	return math.floor(getters.float(self, value))
end
getters.string = function(self, value)
	if not value or not tostring(value) then return self.edit.def end
	return value
end
getters.color = function(self, value)
	return getters.string(self, value)
end
getters.bool = function(self, value)
	if value == nil then return self.edit.def end
	return tobool(value) and 1 or 0
end
getters.field = function(self, value)
	if not istable(value) then return {} end
	local ret = {}
	for i = 1, self.edit.max do
		local s = value[i]
		if s then ret[i] = (self.edit.numeric and tonumber or tostring)(s) end
	end
	return ret
end
getters.combo = function(self, value)
	if self.edit.values and self.edit.values[value] == nil then
		return self.edit.def
	end
	return value or self.edit.def
end


//
local category, subcategory
function NME:Category(name)
	if CLIENT then
		category = name
		subcategory = nil
	end
end

function NME:SubCategory(name)
	if CLIENT then subcategory = name end
end

function NME:Var(name, type, edit, getter)
	type = string.lower(type)

	local var = {
		name = name,
		edit = edit,
		type = type,
		getter = getter or getters[type]
	}

	var.edit.category = var.edit.category or category
	var.edit.subcategory = var.edit.subcategory or subcategory

	var.id  = table.insert(self.n, var)
	self.s[name] = var.id

	if var.edit.container and not self.c[var.edit.container] then
		self.c[var.edit.container] = true
	end

	return var
end

function NME:Obj(instance, name, type, edit, getter)
	local ivar = self:GetVar(instance)
	if not ivar or not ivar.edit.container then return end

	local var = self:Var(name, type, edit, getter)
	var.instance = instance
	var.container = ivar.edit.container

	if not ivar.objects then
		ivar.objects = {}
	end

	table.insert(ivar.objects, var.id)

	return var
end

function NME:SetVar(ent, update, name, instance, value)
	local var = self.n[self.s[name]]
	if not var then return end

	if var.instance then
		if not instance or not var.container then return end

		value = var:getter(value)

		if ent.NMEVals[var.container][instance][var.name] ~= value then
			ent.NMEVals[var.container][instance][var.name] = value

			if update or CLIENT then
				self:Update(ent, name, instance, value)
			end
		end

		return value
	end

	value = var:getter(value)

	if ent.NMEVals[var.name] ~= value then
		ent.NMEVals[var.name] = value

		if update or CLIENT then
			self:Update(ent, name, nil, value)
		end
	end

	return value
end

function NME:GetVar(name)
	return self.n[self.s[name]]
end

local function RestoreContainer(self, ent, update, tbl)
	for instance, values in pairs(tbl) do
		for name, value in pairs(values) do
			self:SetVar(ent, update, name, instance, value)
		end
	end
end

function NME:Restore(ent, update, tbl)
	if not istable(tbl) then return end

	if CLIENT then update = true end

	for k, v in pairs(tbl) do
		local var = self.n[self.s[k]]
		if not var then
			if self.c[k] then
				RestoreContainer(self, ent, update, v)
			end
			goto CONTINUE
		end

		if var.instance then
			for instance, value in pairs(v) do
				local value = var:getter(value)
				ent.NMEVals[var.container][instance][var.name] = value

				if update then
					self:Update(ent, var.name, instance, value)
				end
			end
			goto CONTINUE
		end

		local value = var:getter(v)
		ent.NMEVals[var.name] = value

		if update then
			self:Update(ent, var.name, nil, value)
		end

		::CONTINUE::
	end
end

function NME:Init(ent)
	ent.NMEVars = self
	ent.NMEVals = {}

	ent.GetValueNME = function(e, name, instance)
		local var = self:GetVar(name)
		if not var then return end

		if var.instance then
			local ret = ent.NMEVals[var.container]
			return ret and ret[instance] and ret[instance][name]
		end

		return ent.NMEVals[name]
	end
	ent.SetValueNME = function(e, update, name, instance, value)
		return self:SetVar(e, update, name, instance, value)
	end
	ent.CompressNME = function(e)
		return self:Compress(e)
	end
	ent.DecompressNME = function(e, tbl)
		return self:Decompress(tbl)
	end
	ent.RestoreNME = function(e, update, tbl)
		self:Restore(e, update, tbl)
	end
	ent.ResetNME = function(e, update)
		for k, v in ipairs(self.n) do
			if not v.getter or v.instance then
				goto CONTINUE
			end

			if v.objects and v.edit.container then
				for i = 1, v.edit.max do
					for j = 1, #v.objects do
						local objectVar = self.n[v.objects[j]]
						if objectVar then
							self:SetVar(e, update, objectVar.name, i, objectVar:getter())
						end
					end
				end
			end

			self:SetVar(e, update, v.name, nil, v:getter())

			::CONTINUE::
		end

		if e.DefaultNME then
			e:DefaultNME(update)
		end

		if update then e.ResetEditorNME = true end
	end

	for k, v in ipairs(self.n) do
		if not v.getter or v.instance then
			goto CONTINUE
		end

		if v.objects and v.edit.container then
			local t = {}

			for i = 1, v.edit.max do
				local object = {}
				for j = 1, #v.objects do
					local objectVar = self.n[v.objects[j]]

					if objectVar then
						object[objectVar.name] = objectVar:getter()
					end
				end
				t[i] = object
			end

			ent.NMEVals[v.edit.container] = t
		end

		ent.NMEVals[v.name] = v:getter()

		::CONTINUE::
	end

	if ent.DefaultNME then ent:DefaultNME() end
end

// for networking only!!
function NME:Compress(ent)
	/*
	local ret = {}

	for k, v in pairs(ent.NMEVals) do

		local var = self:GetVar(k)

		if not var then

			if self.c[k] then

				ret[k] = {}

				for instance, values in pairs(v) do

					ret[k][instance] = {}

					for i, j in pairs(values) do

						local var = self:GetVar(i)

						if var then

							ret[k][instance][var.id] = j

						end

					end


				end

			end

		else
			ret[var.id] = v
		end

	end

	-- using indices instead of keys here does reduce the size but probably not worth it

	print(string.len(util.Compress(util.TableToJSON(ret))))
	print(string.len(util.Compress(util.TableToJSON(ent.NMEVals))))
	*/

	return util.Compress(util.TableToJSON(ent.NMEVals))
end

function NME:Decompress(dat)
	return util.JSONToTable(util.Decompress(dat))
end
