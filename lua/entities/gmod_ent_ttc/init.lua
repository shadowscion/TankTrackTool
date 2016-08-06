--[[
	Tank Track Controller Addon
	by shadowscion
]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


-- NETWORK: Add strings
util.AddNetworkString("ttc.send_entity_links")
util.AddNetworkString("ttc.refresh_entity_links")


-- CONTROLLER: Initialize
function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate.mdl")
	self:SetMaterial("models/debug/debugwhite")
	self:DrawShadow(false)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        phys:Wake()
    end

    self.LinkedEntities = {}
end


-- CONTROLLER: Set entity links from sorted table
function ENT:SetLinkedEntities(tbl)
	self.LinkedEntities = {}
	for _, ent in ipairs(tbl) do
		if not IsValid(ent) or ent:IsWorld() then
			-- self.LinkedEntities = {}
			-- return
			continue
		end

		ent:CallOnRemove("ttc_ent_removed", function(e)
			if not IsValid(self) then return end
			table.RemoveByValue(self.LinkedEntities, ent)
		end)

		table.insert(self.LinkedEntities, ent)
	end

	self:UpdateLinks()
end


-- CONTROLLER: Reset all entity links
function ENT:UnsetLinkedEntities()
	for _, ent in ipairs(self.LinkedEntities) do
		ent:RemoveCallOnRemove("ttc_ent_removed")
	end

	duplicator.ClearEntityModifier(self, "ttc_dupe_info")
	self.LinkedEntities = {}
	self:UpdateLinks()
end


-- NETWORK: Send enity links to clients
function ENT:UpdateLinks(ply)
	net.Start("ttc.send_entity_links")

	net.WriteEntity(self)
	net.WriteTable(self.LinkedEntities)

	self:SetupWheelCount()

	if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

local RefreshQueue = {}

net.Receive("ttc.refresh_entity_links", function(len, ply)
	local single = net.ReadEntity()
	if IsValid(single) then
		table.insert(RefreshQueue, { ply, single })
		return
	end

	for _, ent in pairs(ents.FindByClass("gmod_ent_ttc")) do
		table.insert(RefreshQueue, { ply, ent })
	end
end)

hook.Add("Think", "ttc.refresh_entity_links", function()
	if #RefreshQueue > 0 then
		local ply = RefreshQueue[1][1]
		local ent = RefreshQueue[1][2]

		if IsValid(ply) and IsValid(ent) then
			if ent:GetClass() == "gmod_ent_ttc" then
				ent:UpdateLinks(ply)
			end
		end

		table.remove(RefreshQueue, 1)
	end
end)


-- CONTROLLER: Dupe support
function ENT:PreEntityCopy()
	local dupe_info = {}
	local link_ents = {}

	for _, ent in ipairs(self.LinkedEntities) do
		--if not IsValid(ent) then link_ents = {} break end
		if not IsValid(ent) then continue end
		table.insert(link_ents, ent:EntIndex())
	end

	dupe_info.link_ents = link_ents

	duplicator.ClearEntityModifier(self, "ttc_dupe_info")
	duplicator.StoreEntityModifier(self, "ttc_dupe_info", dupe_info)
end

function ENT:PostEntityPaste(ply, ent, createdEntities)
	if IsValid(ply) then
		ent:SetNetworkedInt("ownerid", ply:UserID())
		ply:AddCount("gmod_ent_ttc", ent)
		ply:AddCleanup("gmod_ent_ttc", ent)
	end

	timer.Simple(1, function()
		if not IsValid(ply) or not IsValid(ent) then return end

		if not ent.EntityMods then return end
		if not ent.EntityMods.ttc_dupe_info then return end
		if not ent.EntityMods.ttc_dupe_info.link_ents then return end

		local link_ents = {}
		for _, id in ipairs(ent.EntityMods.ttc_dupe_info.link_ents) do
			if not IsValid(createdEntities[id]) then
				--link_ents = {}
				--break
				continue
			end

			table.insert(link_ents, createdEntities[id])
		end

		ent:SetLinkedEntities(link_ents)
	end)
end
