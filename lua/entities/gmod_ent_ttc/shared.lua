--[[
    Tank Track Controller Addon
    by shadowscion
]]--

ENT.Base      = "base_anim"
ENT.PrintName = "TTC: Classic"
ENT.Author    = "shadowscion"
ENT.Category  = "Tank Track Tool"
ENT.Editable  = true
ENT.Spawnable = true
ENT.AdminOnly = false

cleanup.Register("gmod_ent_ttc")

-- Tooltips
if CLIENT then
    -- appearance
    language.Add("ttc_tooltip_Detail",   "Maximum number of segments around the radius of a wheel.")
    language.Add("ttc_tooltip_Color",    "RGB color of the track.")
    language.Add("ttc_tooltip_Material", "Material of the track.")
    language.Add("ttc_tooltip_FlipMaterial", "Flips the track material 180 degrees.")

    -- dimensions
    language.Add("ttc_tooltip_Width",  "Width of the track.")
    language.Add("ttc_tooltip_Height", "Height of the track.")
    language.Add("ttc_tooltip_Radius", "Offset the radius of the sprocket, idler and road wheels.")
    language.Add("ttc_tooltip_RollerRadius", "Offset the radius of the return roller wheels.")
    language.Add("ttc_tooltip_Offset", "Offset the entire track to the left or right of the chassis.")

    -- physics
    language.Add("ttc_tooltip_Sprocket", "Specify which wheel controls the texture scrolling.")
    language.Add("ttc_tooltip_Tension",  "Tension of the top of the track, does nothing if slack is selected.")
    language.Add("ttc_tooltip_Slack",    "If set, track will 'stick' to the wheels.")
end


-- CONTROLLER: Create editable vars
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "TTC_Detail", { KeyName = "ttc_detail", Edit = { category = "Appearance", type = "Int", title = "Detail", min = 3, max = 8, order = 0 } })
    self:NetworkVar("Vector", 0, "TTC_Color", { KeyName = "ttc_color", Edit = { category = "Appearance", type = "VectorColor", title = "Color", order = 1 } })
    self:NetworkVar("String", 1, "TTC_Material",  { KeyName = "tc_mat", Edit = { category = "Appearance", type = "ttc_material", title = "Material", order = 2 } })
    self:NetworkVar("Bool", 2, "TTC_FlipMat", { KeyName = "ttc_flip", Edit = { category = "Appearance", type = "Boolean", title = "Flip Material", order = 3 } })

    self:NetworkVar("Float", 0, "TTC_Width", { KeyName = "ttc_width", Edit = { category = "Dimensions", type = "Float", title = "Width", min = 1, max = 64, order = 4 } })
    self:NetworkVar("Float", 1, "TTC_Height", { KeyName = "ttc_height", Edit = { category = "Dimensions", type = "Float", title = "Height", min = 1, max = 12, order = 5 } })
    self:NetworkVar("Float", 3, "TTC_Radius", { KeyName = "ttc_radius", Edit = { category = "Dimensions", type = "Float", title = "Radius", min = -2, max = 12, order = 6 } })
    self:NetworkVar("Float", 5, "TTC_RollerRadius", { KeyName = "ttc_rollerradius", Edit = { category = "Dimensions", type = "Float", title = "Roller Radius", min = -2, max = 12, order = 7 } })
    self:NetworkVar("Float", 2, "TTC_Offset", { KeyName = "ttc_offset", Edit = { category = "Dimensions", type = "Float", title = "Offset", min = -64, max = 64, order = 8 } })

    self:NetworkVar("Int", 1, "TTC_Sprocket", { KeyName = "ttc_sprocket", Edit = { category = "Physics", type = "Int", title = "Sprocket", min = 1, max = 64, order = 9 } })
    self:NetworkVar("Float", 4, "TTC_Tension", { KeyName = "ttc_tensor", Edit = { category = "Physics", type = "Float", title = "Tension", min = 0, max = 1, order = 10 } })
    self:NetworkVar("Bool", 1, "TTC_Type", { KeyName = "ttc_type", Edit = { category = "Physics", type = "Boolean", title = "Slack", order = 11 } })
end

function ENT:SetupWheelCount()
    local count
    if SERVER then
        count = self.LinkedEntities and (#self.LinkedEntities - 1) or 1
    else
        count = self.ttc_wheels and #self.ttc_wheels or 1
    end
    self:SetupEditing("TTC_Sprocket", "ttc_sprocket", { category = "Physics", type = "Int", title = "Sprocket", min = 1, max = count or 1, order = 8 })
end


-- CONTROLLER: Reset editable vars
function ENT:SetDefaults()
    -- appearance
    self:SetTTC_Detail(4)
    self:SetTTC_Color(Vector(1, 1, 1))
    self:SetTTC_Material("track_generic")
    self:SetTTC_FlipMat(false)

    -- dimensions
    self:SetTTC_Width(12)
    self:SetTTC_Height(3)
    self:SetTTC_Radius(0)
    self:SetTTC_RollerRadius(0)
    self:SetTTC_Offset(0)

    -- physics
    self:SetTTC_Sprocket(1)
    self:SetTTC_Tension(1)
    self:SetTTC_Type(false)
end


-- CONTROLLER: Set allowed contexts
function ENT:CanProperty(ply, property)
    if property == "remover" then return true end
    if property == "ttc_context_edit" then return true end
    return false
end


-- CONTROLLER: Basic spawn function
function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end

    local ent = ents.Create(ClassName)

    ent:SetDefaults()
    ent:SetPos(tr.HitPos)
    ent:Spawn()
    ent:Activate()

    if IsValid(ply) then
        ply:AddCount("gmod_ent_ttc", ent)
        ply:AddCleanup("gmod_ent_ttc", ent)

        if SERVER then
            ent:SetNetworkedInt("ownerid", ply:UserID())
        end
    end

    return ent
end
