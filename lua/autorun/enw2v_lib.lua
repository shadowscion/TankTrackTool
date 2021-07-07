
--[[

	Similar to editable NetworkVars but not limited by DTVar slots
	and actually clamps data when constraints are provided

	api:

	-- SHARED - required, call in entity initialize method
	_ENW2V_INSTALL(EditEnt)


	-- SHARED - required, works like ent:SetupDatatables()
	function EditEnt:_ENW2V_SETUP()
		EditEnt:_ENW2V_REGISTER({type="Float", name="TurnAngle", min=0, max=180}, {title="Turn Angle", property=...})
	end


	-- SERVER/CLIENT - optional, called when a value changes
	function EditEnt:_ENW2V_CHANGED(vname, newvalue, oldvalue)
	end

]]

----------------------------------------------------------------
local net, util, duplicator =
	  net, util, duplicator

local pairs, istable, isstring, isnumber, isvector, isfunction =
	  pairs, istable, isstring, isnumber, isvector, isfunction


if SERVER then
	util.AddNetworkString("_ENW2V_NETWORK")

	net.Receive("_ENW2V_NETWORK", function(len, pl)
		local eid = net.ReadUInt(32)
		local ent = Entity(eid)

		if not ent or not ent:IsValid() or not isfunction(ent._ENW2V_SET) then
			return
		end

		if CPPI and pl ~= ent:CPPIGetOwner() then
			return
		end

		local vname = net.ReadString()
		local value = net.ReadString()

		ent:_ENW2V_SET(vname, value)
	end)

	-- duplicator.RegisterEntityModifier("_ENW2V_DUPED", function(pl, ent, data)
	-- 	if isfunction(ent._ENW2V_RESTORE) then
	-- 		timer.Simple(0, function()
	-- 			ent:_ENW2V_RESTORE(data)
	-- 		end)
	-- 	end
	-- end)
end

----------------------------------------------------------------
local _NOTIFY = {}
hook.Add("EntityNetworkedVarChanged", "_ENW2V_NOTIFY", function(ent, name, old, new)
	if not _NOTIFY[ent] or not ent._ENW2V_NOTIFY[name] or not isfunction(ent._ENW2V_CHANGED) then
		return
	end
	ent._ENW2V_CHANGED(ent, name, old, new)
end)

----------------------------------------------------------------
local sanitize = {}
sanitize.Vector = function(value, var)
	if isvector(value) then
		local min = var.min
		if isvector(min) then
			if value.x < min.x then value.x = min.x end
			if value.y < min.y then value.y = min.y end
			if value.z < min.z then value.z = min.z end
		end
		local max = var.max
		if isvector(max) then
			if value.x > max.x then value.x = max.x end
			if value.y > max.y then value.y = max.y end
			if value.z > max.z then value.z = max.z end
		end
	end
	return value
end
sanitize.Angle = function(value, var) return value end
sanitize.Float = function(value, var)
	if isnumber(value) then
		if isnumber(var.min) and value < var.min then
			value = var.min
		end
		if isnumber(var.max) and value > var.max then
			value = var.max
		end
	end
	return value
end
sanitize.Int = sanitize.Float
sanitize.Bool = function(value, var) return value end
sanitize.String = function(value, var)
	if istable(var.values) and not var.values[value] then
		return nil
	end
	return value
end

----------------------------------------------------------------
function _ENW2V_INSTALL(EditEnt)
	_NOTIFY[EditEnt] = true

	local typeids = {}
	local editor = {}
	local order = 0

	EditEnt._ENW2V_LOOKUP = {}
	EditEnt._ENW2V_NOTIFY = {}

	EditEnt._ENW2V_REGISTER = function(_, var, edit)
		if not istable(var) then return end
		local vtype, vname = var.type, var.name
		if not vtype or not vname or not sanitize[vtype] then
			MsgN("ENW2V missing required keys: type, name")
			return
		end

		local vset = EditEnt["SetNW2" .. vtype]
		local vget = EditEnt["GetNW2" .. vtype]
		if not isfunction(vset) or not isfunction(vget) then return end

		if var.notify then EditEnt._ENW2V_NOTIFY[vname] = true end
		if CLIENT and istable(edit) then
			editor[vname] = {var = var, edit = edit, order = order}
			order = order + 1
			EditEnt._ENW2V_EDITOR_ALLOWED = true
		else
			edit = nil
		end

		typeids[vname] = vtype

		EditEnt["Set" .. vname] = function(_, value, nodupe)
			value = sanitize[vtype](value, var)
			if value == nil then
				return
			end

			vset(EditEnt, vname, value)

			EditEnt._ENW2V_LOOKUP[vname] = value

			if SERVER and nodupe == nil then
				duplicator.StoreEntityModifier(EditEnt, "_ENW2V_DUPED", EditEnt._ENW2V_LOOKUP)
			end
		end

		EditEnt["Get" .. vname] = function(_)
			return vget(EditEnt, vname)
		end

		if SERVER then
			if var.default then EditEnt["Set" .. vname](EditEnt, var.default) end
		end
	end

	if SERVER then
		EditEnt._ENW2V_RESTORE = function(_, data)
			if not istable(data) then
				return
			end
			for vname in pairs(typeids) do -- EditEnt._ENW2V_LOOKUP) do
				if data[vname] and EditEnt["Set" .. vname] then
					EditEnt["Set" .. vname](EditEnt, data[vname], true)
				end
			end
			duplicator.StoreEntityModifier(EditEnt, "_ENW2V_DUPED", EditEnt._ENW2V_LOOKUP)
		end
	end

	if CLIENT then
		EditEnt._ENW2V_EDITOR = function(_)
			return editor
		end
	end

	EditEnt._ENW2V_GET = function(_, vname)
		if vname then
			if EditEnt["Get" .. vname] then
				return EditEnt["Get" .. vname](EditEnt, vname)
			end
			return
		end
		local dv = {}
		for vname in pairs(typeids) do -- EditEnt._ENW2V_LOOKUP) do
			if EditEnt["Get" .. vname] then
				dv[vname] = EditEnt["Get" .. vname](EditEnt, vname)
			end
		end
		return dv
	end

	EditEnt._ENW2V_SET = function(_, vname, value)
		if not isstring(vname) or not isstring(value) then
			return
		end
		if CLIENT then
			net.Start("_ENW2V_NETWORK")
				net.WriteUInt(EditEnt:EntIndex(), 32)
				net.WriteString(vname)
				net.WriteString(value)
			net.SendToServer()
		else
			local k = typeids[vname]
			if not isstring(k) then
				return
			end
			local v = util.StringToType(value, k)
			if v == nil then
				return
			end
			if EditEnt["Set" .. vname] then
				EditEnt["Set" .. vname](EditEnt, v)
				return true
			end
		end
	end

	if EditEnt._ENW2V_SETUP then EditEnt:_ENW2V_SETUP() else MsgN(tostring(EditEnt) " has no :_ENW2V_SETUP method!") end
	--if CLIENT and isfunction(EditEnt._ENW2V_CHANGED) then timer.Simple(0, function() EditEnt:_ENW2V_CHANGED() end) end
end

properties.Add("editable_nw2var_editor", {
	MenuLabel = "Edit Properties",
	Order = 90001,
	PrependSpacer = true,
	MenuIcon = "icon16/pencil.png",

	Filter = function(self, ent, pl)
		if not ent or not ent:IsValid() or not ent._ENW2V_EDITOR_ALLOWED then
			return false
		end
		if not gamemode.Call("CanProperty", pl, "enw2v_editor", ent) then
			return false
		end
		return true
	end,

	Action = function(self, ent)
		local window = g_ContextMenu:Add("DFrame")
		local h = math.floor(ScrH() - 90)
		local w = 420

		window:SetPos(ScrW() - w - 30, ScrH() - h - 30)
		window:SetSize(w, h)
		window:SetDraggable(false)
		window:SetTitle(tostring(ent))
		window.btnMaxim:SetVisible(false)
		window.btnMinim:SetVisible(false)

		local control = window:Add("enw2v_editor")
		control:SetEntity(ent)
		control:Dock(FILL)
		control.OnEntityLost = function()
			window:Remove()
		end

		window.Paint = function(_, w, h)
			surface.SetDrawColor(75, 75, 75)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		window.OnRemove = function()
			hook.Run("enw2v_editor", ent, false)
		end
		hook.Run("enw2v_editor", ent, true)
	end
})
