E2Lib.RegisterExtension("tanktracktool", true, "Allows E2 chips to create and manipulate tanktracktool entities")

local E2Lib, WireLib, math = E2Lib, WireLib, math

registerCallback("construct", function(self)
	self.data.tanktracks = {}
end)

registerCallback("destruct", function(self)
	for ent, mode in pairs(self.data.tanktracks) do
		if ent then ent:Remove() end
	end
end)

local function makeEntity(self, class, keep, pos, ang, model)
	if not gamemode.Call("PlayerSpawnSENT", self.player, class) then
		return NULL
	end

	local ent = ents.Create(class)
	if not IsValid(ent) then
		return NULL
	end

	if not util.IsValidModel(model) then model = "models/hunter/plates/plate.mdl" end

	ent:SetModel(model)
	ent:SetPos(WireLib.clampPos(pos))
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Wake()
	end

	if not keep then
		self.data.tanktracks[ent] = true

		ent:CallOnRemove("e2_ttrmv", function(e)
			self.data.spawnedProps[e] = nil
		end)

		ent.DoNotDuplicate = true
	else
		undo.Create(class)
			undo.SetPlayer(self.player)
			undo.AddEntity(ent)
		undo.Finish()
	end

	self.player:AddCleanup("sents", ent)
	self.player:AddCount(class, ent)

	return ent
end

__e2setcost(100)

e2function entity tanktracksCreateAuto(number keep, string model, vector pos, angle ang)
	return makeEntity(self, "sent_tanktracks_auto", keep ~= 0, pos, Angle(ang[1], ang[2], ang[3]), model)
end

e2function entity tanktracksCreateLegacy(number keep, string model, vector pos, angle ang)
	return makeEntity(self, "sent_tanktracks_legacy", keep ~= 0, pos, Angle(ang[1], ang[2], ang[3]), model)
end


//
local classes = {
	sent_tanktracks_auto = true,
	sent_tanktracks_legacy = true,
}

local function checkvalid(context, self)
	if not IsValid(self) then return false end
	if not E2Lib.isOwner(context, self) or not classes[self:GetClass()] then
		return false
	end
	return true
end

local function setvalue(context, self, name, instance, value)
	if not checkvalid(context, self) then return end
	return self:SetValueNME(true, name, instance, value)
end

local function getkeys(context, self)
	if not checkvalid(context, self) then return E2Lib.newE2Table() end

	local ret = E2Lib.newE2Table()
	local len = 0

	for k, v in ipairs(self.NMEVars.n) do
		len = len + 1
		ret.n[k] = v.name
		ret.ntypes[k] = "s"
	end

	ret.size = len
	context.prf = context.prf + len*0.333

	return ret
end

local t1 = {bool = "bool",int = "number",float = "number",string = "string",combo = "string",color = "string", field = "array"}
local t2 = {bool = "boolindex",int = "numberindex",float = "numberindex",string = "stringindex",combo = "stringindex",color = "stringindex", field = "arrayindex"}

__e2setcost(5)

e2function string entity:tanktracksGetType(string name)
	if not checkvalid(self, this) then return "" end
	local var = this.NMEVars.n[this.NMEVars.s[name]]
	return var and (var.container and t2 or t1)[var.type] or ""
end

e2function table entity:tanktracksGetKeys()
	return getkeys(self, this)
end

e2function number entity:tanktracksSetValue(string name, ...)
	if select("#", ...) == 0 then return 0 end
	return setvalue(self, this, name, nil, unpack({...})) and 1 or 0
end

e2function number entity:tanktracksSetValueIndex(string name, number index, ...)
	if select("#", ...) == 0 then return 0 end
	return setvalue(self, this, name, index, unpack({...})) and 1 or 0
end

e2function array entity:tanktracksGetLinks()
	if not IsValid(this) or not E2Lib.isOwner(self, this) or this:GetClass() ~= "sent_tanktracks_legacy" then return {} end
	return this.ttdata_links or {}
end

__e2setcost(100)

e2function void entity:tanktracksReset()
	if not checkvalid(self, this) then return end
	this:ResetNME(true)
end

local antispam = {}

e2function void entity:tanktracksSetLinks(entity chassis, array wheels, array rollers)
	if not IsValid(this) or not E2Lib.isOwner(self, this) or this:GetClass() ~= "sent_tanktracks_legacy" then return end

	if not E2Lib.isOwner(self, chassis) then return end

	local time = CurTime()
	if antispam[this] and (antispam[this] == time or time - antispam[this] < 5) then
		return
	end
	antispam[this] = time

	local m = chassis:GetWorldTransformMatrix()
	if this:GetValueNME("systemRotate") ~= 0 then
		m:Rotate(Angle(0, -90, 0))
	end

	local right = m:GetRight()
	local pos = m:GetTranslation()
	local dot = 0

	local tbl = {}

	local safe = 0
	for k, v in ipairs(wheels) do
		if IsValid(v) and type(v) == "Entity" and E2Lib.isOwner(self, v) then
			dot = dot + (right:Dot((v:GetPos() - pos):GetNormal()) > 0 and 1 or -1)
			tbl[#tbl + 1] = v
			v.Roller = nil
			safe = safe + 1
		end
		if safe > 32 then break end
	end

	local safe = 0
	for k, v in ipairs(rollers) do
		if IsValid(v) and type(v) == "Entity" and E2Lib.isOwner(self, v) then
			dot = dot + (right:Dot((v:GetPos() - pos):GetNormal()) > 0 and 1 or -1)
			tbl[#tbl + 1] = v
			v.Roller = true
			safe = safe + 1
		end
		if safe > 32 then break end
	end

	if math.abs(dot) ~= #tbl then
		error("All linked wheels must be parallel to the chassis!")
	end

	local sort_pos = pos + m:GetForward()*10000

    table.sort(tbl, function(a, b)
        local bool_this = a.Roller
        local bool_that = b.Roller

        if bool_this ~= bool_that then
            return bool_that and not bool_this
        end

        if bool_this then
            return a:GetPos():Distance(sort_pos) > b:GetPos():Distance(sort_pos)
        else
            return a:GetPos():Distance(sort_pos) < b:GetPos():Distance(sort_pos)
        end
    end)

	table.insert(tbl, 1, chassis)

	this:SetControllerLinks(tbl)
end
