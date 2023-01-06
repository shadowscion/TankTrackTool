
local ENT = { Type = "anim", Base = "base_anim", Spawnable = false, AdminOnly = true }

function ENT:Initialize()
    if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
    end

    NeedMoreEdits.Install( self, self:SetupNME() )
end

function ENT:Think()
    if not CLIENT then
        return
    end
    if not self.NMESync then
        NeedMoreEdits.RequestSync( self )
        self:TriggerNME( "request_sync" )
        self.NMESync = true
    end
end

if SERVER then
    local precopy

    function ENT:PreEntityCopy()
        duplicator.ClearEntityModifier( self, "nmeDupeInfo" )
        if istable( self.NMEVals ) then
            local data = util.Compress( util.TableToJSON( self.NMEVals ) )
            duplicator.StoreEntityModifier( self, "nmeDupeInfo", { data = data } )
        end
        precopy = self.NMEVals
        self.NMEVals = nil
    end

    function ENT:PostEntityCopy()
        self.NMEVals = precopy
        precopy = nil
    end

    function ENT:OnDuplicated( dupe )
        local info = dupe.EntityMods and dupe.EntityMods.nmeDupeInfo
        if info and info.data then
            self:RestoreNME( false, util.JSONToTable( util.Decompress( info.data ) ) )
        end
        if isfunction( self.PostDuplicatedNME ) then
            self:PostDuplicatedNME( dupe )
        end
    end
end

function ENT:SetupNME()
end

function ENT:TriggerNME( type, ... )
end

scripted_ents.Register( ENT, "base_nme" )
