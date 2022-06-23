
//
local ENT = {Type = "anim", Base = "base_anim", Spawnable = false, AdminOnly = true}

-- function ENT:SpawnFunction(ply, tr, ClassName)
-- 	if not tr.Hit then
-- 		return
-- 	end

-- 	local ent = ents.Create(ClassName)
-- 	ent:SetModel("models/hunter/plates/plate.mdl")
-- 	ent:SetPos(tr.HitPos + tr.HitNormal*40)
-- 	ent:Spawn()
-- 	ent:Activate()

-- 	return ent
-- end

function ENT:Initialize()
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	NeedMoreEdits.Install(self, self:SetupNME())
end

function ENT:Think()
	if not CLIENT then
		return
	end
	if not self.NMESync then
		NeedMoreEdits.RequestSync(self)
		self:TriggerNME("request_sync")
		self.NMESync = true
	end
end

if SERVER then
	local precopy

	function ENT:PreEntityCopy()
		duplicator.ClearEntityModifier(self, "nmeDupeInfo")
		if istable(self.NMEVals) then
			local data = util.Compress(util.TableToJSON(self.NMEVals))
			duplicator.StoreEntityModifier(self, "nmeDupeInfo", {data = data})
		end
		precopy = self.NMEVals
		self.NMEVals = nil
	end

	function ENT:PostEntityCopy()
		self.NMEVals = precopy
		precopy = nil
	end

	function ENT:OnDuplicated()
		local dupe = self.EntityMods and self.EntityMods.nmeDupeInfo
		if dupe and dupe.data then
			self:RestoreNME(true, util.JSONToTable(util.Decompress(dupe.data)))
		end
		if isfunction(self.PostDuplicatedNME) then
			self:PostDuplicatedNME()
		end
	end
end

function ENT:SetupNME()
end

function ENT:TriggerNME(type, ...)
end

scripted_ents.Register(ENT, "base_nme")
