----------------------------------------------------------------
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


----------------------------------------------------------------
function ENT:Initialize()
	_ENW2V_INSTALL(self)

    self:DrawShadow(false)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        phys:Wake()
    end

    self.Inputs = Wire_CreateInputs(self, {"LeftBrake","RightBrake","WheelYaw", "SuspensionBias", "SuspensionBiasSide", "ForwardFacingEntity [ENTITY]"})

    self:SetNW2Bool("LeftBrake", false)
    self:SetNW2Bool("RightBrake", false)
    self:SetNW2Int("WheelYaw", 0)
    self:SetNW2Int("Hydra", 0)
    self:SetNW2Int("HydraSide", 0)
    self:SetNW2Entity("ForwardEnt", nil)
end


----------------------------------------------------------------
local inputTriggers = {
    WheelYaw = function(self, iname, ivalue)
        self:SetNW2Int("WheelYaw", math.NormalizeAngle(tonumber(ivalue) or 0))
    end,
    ForwardFacingEntity = function(self, iname, ivalue)
        self:SetNW2Entity("ForwardEnt", ivalue)
    end,
    SuspensionBias = function(self, iname, ivalue)
        self:SetNW2Float("Hydra", math.Clamp(tonumber(ivalue) or 0, -1, 1))
    end,
    SuspensionBiasSide = function(self, iname, ivalue)
        self:SetNW2Float("HydraSide", math.Clamp(tonumber(ivalue) or 0, -1, 1))
    end,
    LeftBrake = function(self, iname, ivalue)
        self:SetNW2Bool("LeftBrake", tobool(ivalue))
    end,
    RightBrake = function(self, iname, ivalue)
        self:SetNW2Bool("RightBrake", tobool(ivalue))
    end,
}

function ENT:TriggerInput(iname, ivalue)
    local callback = inputTriggers[iname]
    if callback then
        callback(self, iname, ivalue)
    end
end


----------------------------------------------------------------
function ENT:PostEntityPaste(pl, ent, allents)
    local mods = self.EntityMods and  self.EntityMods._ENW2V_DUPED
    if mods then
        self:_ENW2V_RESTORE(mods)
    end
end
