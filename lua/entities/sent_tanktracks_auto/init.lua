
//
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("modes/classic.lua")
AddCSLuaFile("modes/torsion.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then
		return
	end

	local model = ply:GetInfo("tanktracktool_model")
	if not util.IsValidModel(model) then model = "models/hunter/plates/plate.mdl" end

	local ent = ents.Create(ClassName)
	ent:SetModel(model)
	ent:SetPos(tr.HitPos + tr.HitNormal*40)
	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Wake()
	end

	return ent
end


//
function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	if Wire_CreateInputs then
		self.Inputs = Wire_CreateInputs(self, {"LeftScroll", "LeftBrake", "RightScroll", "RightBrake", "AxisEntity [ENTITY]"})
	end
end

local inputTriggers = {
    LeftScroll = function(self, iname, ivalue, src)
    	self:SetNW2Float("leftScroll", ivalue)
    end,
    LeftBrake = function(self, iname, ivalue, src)
    	self:SetNW2Bool("leftBrake", ivalue)
    end,
    RightScroll = function(self, iname, ivalue, src)
    	self:SetNW2Float("rightScroll", ivalue)
    end,
    RightBrake = function(self, iname, ivalue, src)
    	self:SetNW2Bool("rightBrake", ivalue)
    end,
    AxisEntity = function(self, iname, ivalue, src)
    	self:SetNW2Entity("axisEntity", ivalue)
    end,
}

function ENT:TriggerInput(iname, ivalue, ...)
	if inputTriggers[iname] then
		inputTriggers[iname](self, iname, ivalue)--, self.Inputs[iname].Src)
	end
end


// LEGACY COMPAT
local function a1z26_toTable(str, int)
	if not str then return end
	local ret = {}
	local key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local len = string.len(key)
	for k, v in string.gmatch(str, "(%a+)(%-?%d+)") do
		local idx = 0
		for i = 1, #k do
			local f = string.find(key, string.sub(k, i, i))
			idx = idx + f + f*(len*(i - 1))
		end
		ret[idx] = tonumber(v)/int
	end
	return ret
end

local function convert(ent, legacy)
	local update = false--not game.SinglePlayer()

	ent:SetValueNME(update, "suspensionType", nil, "classic")

	// tracks
	if isstring(legacy.TrackMaterial) then
		ent:SetValueNME(update, "trackMaterial", nil, string.gsub(legacy.TrackMaterial, "track_", ""))
	end

	ent:SetValueNME(update, "trackHeight", nil, legacy.TrackHeight)
	ent:SetValueNME(update, "trackWidth", nil, legacy.TrackWidth)
	ent:SetValueNME(update, "trackTension", nil, legacy.TrackTension)
	ent:SetValueNME(update, "trackRes", nil, legacy.TrackResolution)

	// suspension
	ent:SetValueNME(update, "systemOffsetX", nil, legacy.WheelOffsetX)

	ent:SetValueNME(update, "suspensionX", nil, legacy.WheelBase)
	ent:SetValueNME(update, "suspensionY", nil, (legacy.WheelOffsetY or 0)*2)
	ent:SetValueNME(update, "suspensionZ", nil, legacy.WheelOffsetZ)

	if legacy.RoadWType == "interleave" then
		ent:SetValueNME(update, "suspensionInterleave", nil, 0.5)
	end

	// wheels
	local count = (legacy.RoadWCount or 0) + (legacy.DriveWEnabled and 1 or 0) + (legacy.IdlerWEnabled and 1 or 0)
	ent:SetValueNME(update, "wheelCount", nil, count)

	local wheelColor = isvector(legacy.WheelColor) and string.format("%d %d %d 255", legacy.WheelColor.x, legacy.WheelColor.y, legacy.WheelColor.z) or nil

	local wheelMaterial = isstring(legacy.WheelMaterial) and string.Explode(", ", legacy.WheelMaterial)
	if wheelMaterial then
		if #wheelMaterial == 1 then
			wheelMaterial = { wheelMaterial[1] }
		else
			local r = {}
			for i = 1, #wheelMaterial, 2 do
				r[wheelMaterial[i] + 2] = wheelMaterial[i + 1]
			end
			wheelMaterial = r
		end
	end

	// sprocket
	if legacy.DriveWEnabled then
		local z_offset = (legacy.DriveWOffsetZ or 0) + (legacy.DriveWDiameter or 0)*0.5 + (legacy.TrackHeight or 0)

		local index = 1
		ent:SetValueNME(update, "whnSuspension", index, 0)
		ent:SetValueNME(update, "whnOffsetZ", index, z_offset)
		ent:SetValueNME(update, "whnOverride", index, 1)
		ent:SetValueNME(update, "whnRadius", index, (legacy.DriveWDiameter or 0)*0.5)
		ent:SetValueNME(update, "whnWidth", index, legacy.DriveWWidth)
		ent:SetValueNME(update, "whnModel", index, legacy.DriveWModel)
		ent:SetValueNME(update, "whnBodygroup", index, legacy.DriveWBGroup)

		if wheelColor then
			ent:SetValueNME(update, "whnColor", index, wheelColor)
		end
		if wheelMaterial then
			ent:SetValueNME(update, "whnMaterial", index, wheelMaterial)
		end
	end

	// idler
	if legacy.IdlerWEnabled then
		local z_offset = (legacy.IdlerWOffsetZ or 0) + (legacy.IdlerWDiameter or 0)*0.5 + (legacy.TrackHeight or 0)

		local index = 2
		ent:SetValueNME(update, "whnSuspension", index, 0)
		ent:SetValueNME(update, "whnOffsetZ", index, z_offset)
		ent:SetValueNME(update, "whnOverride", index, 1)
		ent:SetValueNME(update, "whnRadius", index, (legacy.IdlerWDiameter or 0)*0.5)
		ent:SetValueNME(update, "whnWidth", index, legacy.IdlerWWidth)
		ent:SetValueNME(update, "whnModel", index, legacy.IdlerWModel)
		ent:SetValueNME(update, "whnBodygroup", index, legacy.IdlerWBGroup)

		if wheelColor then
			ent:SetValueNME(update, "whnColor", index, wheelColor)
		end
		if wheelMaterial then
			ent:SetValueNME(update, "whnMaterial", index, wheelMaterial)
		end
	end

	// road
	ent:SetValueNME(update, "wheelRadius", nil, (legacy.RoadWDiameter or 0)*0.5)
	ent:SetValueNME(update, "wheelWidth", nil, legacy.RoadWWidth)
	ent:SetValueNME(update, "wheelModel", nil, legacy.RoadWModel)
	ent:SetValueNME(update, "wheelBodygroup", nil, legacy.RoadWBGroup)

	local offsets = a1z26_toTable(legacy.RoadWOffsetsX, 99)
	if offsets then
		for i = 1, #offsets do
			ent:SetValueNME(update, "whnOffsetX", i + 2, offsets[i])
		end
	end
	if wheelColor then
		ent:SetValueNME(update, "wheelColor", nil, wheelColor)
	end
	if wheelMaterial then
		ent:SetValueNME(update, "wheelMaterial", nil, wheelMaterial)
	end

	// rollers
	local rollerCount = tonumber(legacy.RollerWCount or 0)
	ent:SetValueNME(update, "rollerCount", nil, rollerCount)

	if rollerCount > 0 then
		ent:SetValueNME(update, "rollerRadius", nil, (legacy.RollerWDiameter or 0)*0.5)
		ent:SetValueNME(update, "rollerWidth", nil, legacy.RollerWWidth)
		ent:SetValueNME(update, "rollerModel", nil, legacy.RollerWModel)
		ent:SetValueNME(update, "rollerBodygroup", nil, legacy.RollerWBGroup)

		local offsets = a1z26_toTable(legacy.RollerWOffsetsX, 99)
		if offsets then
			for i = 1, #offsets do
				ent:SetValueNME(update, "ronOffsetX", i, offsets[i])
			end
		end
		if wheelColor then
			ent:SetValueNME(update, "rollerColor", nil, wheelColor)
		end
		if wheelMaterial then
			ent:SetValueNME(update, "rollerMaterial", nil, wheelMaterial)
		end

		//RollerWOffsetZ
		//RollerWBias
	end
end

duplicator.RegisterEntityClass("gmod_ent_ttc_auto", function(ply, data)
	local ent = ents.Create("sent_tanktracks_auto")

	duplicator.DoGeneric(ent, data)

	ent:Spawn()
	ent:Activate()

	local legacy = data.EntityMods and data.EntityMods._ENW2V_DUPED
	if legacy then
		convert(ent, legacy)
		duplicator.ClearEntityModifier(ent, "_ENW2V_DUPED")
	end

	ply:AddCount("sent_tanktracks_auto", ent)
	ply:AddCleanup("sent_tanktracks_auto", ent)

	return ent
end, "Data")
