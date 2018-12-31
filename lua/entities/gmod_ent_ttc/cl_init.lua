--[[
    Tank Track Controller Addon
    by shadowscion
]]--

include("shared.lua")


-- TTC: Localize
TTC = TTC or {}
local TTC = TTC or {}


-- LIB: Localize (is this pointless?)
local render = render

local math = math
local math_deg = math.deg
local math_rad = math.rad
local math_abs = math.abs
local math_sin = math.sin
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local math_atan2 = math.atan2
local math_round = math.Round

local IsValid = IsValid
local Matrix = Matrix
local Vector = Vector
local Angle = Angle

local color_white = Color(255, 255, 255, 255)
local vector_zero = Vector()
local angle_zero = Angle()

local acf_support = CreateClientConVar("ttc_render_damage", "0", true, false)


-- Can't use physobj functions on client, have to workaround like this
local function getAngularVelocity(localTo, ent)
    local dir = localTo:WorldToLocal(ent:GetForward() + localTo:GetPos())
    local ang = math_deg(math_atan2(dir.z, dir.x))

    ent.DeltaAngle = ent.DeltaAngle or 0

    local ang_vel = (ang - ent.DeltaAngle + 180) % 360 - 180

    ent.DeltaAngle = ang

    return ang_vel/FrameTime()
end


-- CONTROLLER: Initialize
function ENT:Initialize()
    -- rendering
    TTC.RemoveRenderOverride(self)
    self.blocked = TTC.Blocked[self:GetNetworkedInt("ownerid")] or nil

    -- entities
    self.ttc_chassis = NULL
    self.ttc_sprocket = NULL
    self.ttc_wheels = {}
    self.ttc_rollercount = 0

    self.ttc_acfhealth = 0
    self.ttc_acfpercent = 0
    self.ttc_acfdamage = Matrix()

    -- tables
    self.ttc_nodecount = 0
    self.ttc_nodes = {}
    self.ttc_spline = {}

    -- model vars
    self.ttc_scalem = Matrix()
    self.ttc_scalev = Vector(1, 1, 1)
    self.ttc_tracky = 0
    self.ttc_mdl = TTC.Models["no_teeth"] or nil

    -- material vars
    self.ttc_mat = self.ttc_mat or nil
    self.ttc_mat_name = self.ttc_mat_name or ""
    self.ttc_mat_sca = self.ttc_mat_sca or Vector(1, 1, 1)
    self.ttc_mat_scr = self.ttc_mat_scr or 0
    self.ttc_mat_res = self.ttc_mat_res or 1
    self.ttc_mat_map = self.ttc_mat_map or 1
end


-- CONTROLLER: Draw
function ENT:Draw()
    self:DrawModel()
end


-- CONTROLLER: Think
function ENT:Think()
    self:SyncMaterial()
    self:SetNextClientThink(CurTime() + 0.5)
end


-- CONTROLLER: Sync material variables
function ENT:SyncMaterial()
    if self.ttc_mat then
        if self.ttc_mat_flip ~= self:GetTTC_FlipMat() then
            self.ttc_mat_flip = self:GetTTC_FlipMat()
            if self.ttc_mat_flip then
                self.ttc_mat:SetFloat("$angle", 180)
            else
                self.ttc_mat:SetFloat("$angle", 0)
            end
        end
    end

    if self.ttc_mat_name == self:GetTTC_Material() then return end

    self.ttc_mat_name = self:GetTTC_Material()

    local _, mat, res = TTC.GetMaterial(self.ttc_mat_name)
    if _ then
        self.ttc_mat = mat
        self.ttc_mat_res = res
    else
        self.ttc_mat = nil
    end
end


-- hacky, but for some reason, HitBoxBounds is the only function that returns the correct numbers for models with bodygroups larger than the actual model
local function real_radius(ent)
    if ent:GetHitBoxBounds(0, 0) then
        local min, max = ent:GetHitBoxBounds(0, 0)
        local bounds = (max - min)*0.5
        --local bounds = Vector(math_abs(min.x) + math_abs(max.x), math_abs(min.y) + math_abs(max.y), math_abs(min.z) + math_abs(max.z))*0.5
        return math_max(bounds.x, bounds.y, bounds.z)
    end
    return ent:GetModelRadius() or 12
end


-- NETWORK: Get entity links from server
function ENT:UpdateLinks(tbl)
    self:Initialize()

    for i, ent in ipairs(tbl) do
        if not IsValid(ent) then
            self:Initialize()
            return
        end

        if i == 1 then self.ttc_chassis = ent continue end
        if i == 2 then self.ttc_tracky = self.ttc_chassis:WorldToLocal(ent:GetPos()).y end

        table.insert(self.ttc_wheels, {
            ent = ent,
            rad = math_round(real_radius(ent), 2),
        })

        self.ttc_acfhealth = self.ttc_acfhealth + 1
    end

    self:SetupWheelCount()

    TTC.AddRenderOverride(self)
end

net.Receive("ttc.send_entity_links", function()
    local self = net.ReadEntity()
    local count = net.ReadUInt(16)

    if not IsValid(self) or not count then return end
    if count < 3 then
        self:Initialize()
        return
    end

    local tbl = {}
    for i = 1, count do
        table.insert(tbl, net.ReadEntity())
    end

    self:UpdateLinks(tbl)
end)

hook.Add("OnEntityCreated", "ttc.refresh_entity_links", function(self)
    if not IsValid(self) or self:GetClass() ~= "gmod_ent_ttc" then return end

    net.Start("ttc.refresh_entity_links")
        net.WriteEntity(self)
    net.SendToServer()
end)

local delay = CurTime()
concommand.Add("ttc_refresh", function(ply, cmd, args)
    if CurTime() - delay > 5 then
        net.Start("ttc.refresh_entity_links")
        net.SendToServer()
        delay = CurTime()
    end
end)


-- TTC: Lod
function ENT:HandleLOD(eyepos, eyedir)
    if not IsValid(self.ttc_chassis) or self.ttc_chassis:IsDormant() then return false end
    if #self.ttc_wheels == 0 then return false end

    local dot = eyedir:Dot(self.ttc_chassis:GetPos() - eyepos)
    if dot < 0 and math_abs(dot) > 100 then return false end

    self.ttc_lod = eyepos:Distance(self.ttc_chassis:GetPos()) > 9000

    return true
end


-- TTC: RenderOverride
function ENT:DoRenderOverride()
    if not self:GenerateNodes() then return end

    self:GenerateSpline()
    self:RenderTrackMesh()
end


-- TTC: Generate nodes from wheels
function ENT:GenerateNodes()
    self.ttc_nodes = {}
    self.ttc_nodecount = 0

    if #self.ttc_wheels <= 1 then return false end

    local offset = self.ttc_tracky + self:GetTTC_Offset()

    local ply = LocalPlayer()
    local can_see = false

    for i = 1, #self.ttc_wheels do
        local wheel = self.ttc_wheels[i]

        if not wheel or not IsValid(wheel.ent) then
            table.remove(self.ttc_wheels, i)
            self:SetupWheelCount()

            if #self.ttc_wheels <= 1 then return false else continue end
        end

        if not can_see then
            if ply:IsLineOfSightClear(wheel.ent) then can_see = true end
        end

        local pos = self.ttc_chassis:WorldToLocal(wheel.ent:GetPos())
        pos.y = offset

        self.ttc_nodes[#self.ttc_nodes + 1] = self.ttc_chassis:LocalToWorld(pos)
    end

    self.ttc_nodecount = #self.ttc_nodes

    return can_see
end


-- TTC: lerps between two points on a spline an inserts the new points
local function bisect_spline(spline, split, tensor, maxdetail)
    local index = #spline - split - 1

    local point1 = spline[index]
    local point2 = spline[index + 1]

    --local dist = math_min(maxdetail or 4, math_ceil(point1:Distance(point2) / 100) + 1) -- make dependent on detail var
    local dist = maxdetail or 2
    local step = 180/dist

    for b = 1, dist - 1 do
        table.insert(spline, index + b, point1 + (point2 - point1)*(b/dist) + math_sin(math_rad(step*b))*tensor)
    end
end


-- TTC: Generate spline between nodes
function ENT:GenerateSpline()
    self.ttc_spline = {}

    local cache_chassis_up = self.ttc_chassis:GetUp()
    local cache_chassis_pos = self.ttc_chassis:GetPos()

    local detail = self:GetTTC_Detail()
    local wrap = self:GetTTC_Type()

    self.ttc_rollercount = wrap and -1000 or -1

    for i = 1, self.ttc_nodecount do
        local node_this = self.ttc_nodes[i]
        local node_next = i == self.ttc_nodecount and (wrap and i - 1 or 1) or i + 1
        local node_prev = i == 1 and (wrap and i + 1 or self.ttc_nodecount) or i - 1

        local dir_next = self.ttc_chassis:WorldToLocal(self.ttc_nodes[node_next] - node_this + cache_chassis_pos)
        local dir_prev = self.ttc_chassis:WorldToLocal(self.ttc_nodes[node_prev] - node_this + cache_chassis_pos)
        local dir_switch = (dir_next.x > 0) == (dir_prev.x > 0)

        local atan_next, atan_prev
        local radius = self.ttc_wheels[i].rad + (self.ttc_rollercount >= 0 and self:GetTTC_RollerRadius() or self:GetTTC_Radius()) --(dir_switch and self:GetTTC_Radius() or 0) --+ self:GetTTC_Height()*0.25

        if dir_next.x < 0 then
            atan_next = math_deg(math_atan2(-dir_next.x, -dir_next.z))
            atan_prev = math_deg(math_atan2(dir_prev.x, dir_prev.z))
        else
            atan_next = math_deg(math_atan2(dir_next.x, dir_next.z))
            atan_prev = math_deg(math_atan2(-dir_prev.x, -dir_prev.z))
            radius = -radius
            self.ttc_rollercount = self.ttc_rollercount + 1
        end

        local num_split = detail
        if not dir_switch then
            num_split = math_round((math_abs(atan_next) - math_abs(atan_prev))/(180/detail))
        end
        if radius == 0 then num_split = 0 end -- fixes a weird glitch with some props and the matrix setting to 0 0 0 scale

        if num_split > 0 then
            for n = 0, num_split do
                self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Angle((atan_prev + (atan_next - atan_prev)*(n/num_split)), 0, 0):Forward()*radius) + node_this - cache_chassis_pos
            end
        else
            self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Angle(atan_prev + (atan_next - atan_prev)*0.5, 0, 0):Forward()*radius) + node_this - cache_chassis_pos
        end

        if self.ttc_rollercount > 0 then
            if self:GetTTC_Tension() < 1 then
                bisect_spline(self.ttc_spline, math_max(0, num_split), -cache_chassis_up*(1 - self:GetTTC_Tension())*2, detail - 1)
            end
        end
    end

    if self.ttc_rollercount > 0 then
        self.ttc_spline[#self.ttc_spline + 1] = self.ttc_spline[1]
        if self:GetTTC_Tension() < 1 then
            bisect_spline(self.ttc_spline, 0, -cache_chassis_up*(1 - self:GetTTC_Tension())*2, detail - 1)
        end
    else
        if wrap then
            for i = self.ttc_nodecount - 1, 2, -1 do
                local radius = -self.ttc_wheels[i].rad

                local node_this = self.ttc_nodes[i]

                local dir_next = self.ttc_chassis:WorldToLocal(self.ttc_nodes[i + 1] - node_this + cache_chassis_pos)
                local dir_prev = self.ttc_chassis:WorldToLocal(self.ttc_nodes[i - 1] - node_this + cache_chassis_pos)

                local atan_next = math_deg(math_atan2(-dir_next.x, -dir_next.z))
                local atan_prev = math_deg(math_atan2(dir_prev.x, dir_prev.z))

                local num_split = math_round((math_abs(atan_next) - math_abs(atan_prev))/(180/detail))
                if num_split > 0 then
                    for n = 0, num_split do
                        self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Angle((atan_prev + (atan_next - atan_prev)*(n/num_split)), 0, 0):Forward()*radius) + node_this - cache_chassis_pos
                    end
                else
                    self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Vector(0, 0, -radius)) + node_this - cache_chassis_pos
                end
            end

            self.ttc_spline[#self.ttc_spline + 1] = self.ttc_spline[1]
        else
            local p1 = self.ttc_spline[#self.ttc_spline]
            local p2 = self.ttc_spline[1]

            local cache_chassis_vz = -self.ttc_chassis:GetVelocity().z*0.01 + math_sin(math_rad(self.ttc_mat_scr*100))*0.5

            local tensor = (1 - self:GetTTC_Tension())*(self.ttc_nodecount - 2)*2
            local num_split = self.ttc_nodecount - 1
            local num_steps = 180/num_split

            for n = 1, num_split do
                local direct_point = p1 + (p2 - p1)*(n/num_split)
                if n < num_split then
                    local invert = num_split - n + 1
                    local radius = self.ttc_wheels[invert].rad

                    direct_point = direct_point + cache_chassis_up*(-math_sin(math_rad(num_steps*n))*tensor + cache_chassis_vz)

                    local distance = -(self.ttc_nodes[invert] - direct_point):Dot(cache_chassis_up)
                    if distance < radius then
                        direct_point = direct_point + cache_chassis_up*(radius - distance)
                    end
                end
                self.ttc_spline[#self.ttc_spline + 1] = direct_point
            end
        end
    end
end


-- TTC: ACF Damage Textures
function ENT:RenderACFDamage()
    if not self.ttc_mat then return false end
    
    if not acf_support:GetBool() or not TTC.Shader["$detail"] then
        self.ttc_mat:SetFloat("$detailblendfactor", 0)
        return false
    end

    local health = 0
    for i = 1, self.ttc_acfhealth do
        if self.ttc_wheels[i] then
            health = health + (self.ttc_wheels[i].ent.ACF_HelathPercent or 1)
        end
    end
    self.ttc_acfpercent = 1 - health/self.ttc_acfhealth

    if self.ttc_acfpercent < 1 and self.ttc_acfpercent > 0 then
        self.ttc_mat:SetFloat("$detailblendfactor", math_min(self.ttc_acfpercent*2, 1))
        self.ttc_acfdamage:SetTranslation(Vector(0, self.ttc_mat_scr, 0))
    else
        self.ttc_mat:SetFloat("$detailblendfactor", 0)
    end

    return true
end


-- TTC: Rendering
function ENT:RenderTrackMesh()
    local ClientProp = TTC.ClientProp

    ClientProp:SetModel(self.ttc_mdl or TTC.Fallback_Model)

    self.ttc_scalev.y = self:GetTTC_Width()/12
    self.ttc_scalev.z = self:GetTTC_Height()/3

    if not self.ttc_lod and self.ttc_mat then
        local index = math_max(1, math_min(#self.ttc_wheels - self.ttc_rollercount, self:GetTTC_Sprocket()))
        self.ttc_sprocket = self.ttc_wheels[index] and self.ttc_wheels[index].ent

        if IsValid(self.ttc_sprocket) then
            self.ttc_mat_map = self.ttc_mat_res*(self.ttc_scalev.y*12*16)*4 -- 128x256
            --self.ttc_mat_map = self.ttc_mat_res*(self.ttc_scalev.y*12*16) -- 256x256

            local radius = self.ttc_wheels[index].rad + self:GetTTC_Radius() + self:GetTTC_Height()*0.5
            local scroll = getAngularVelocity(self.ttc_chassis, self.ttc_sprocket)/(self.ttc_mat_map/(radius/4)) -- 128x256
            --local scroll = getAngularVelocity(self.ttc_chassis, self.ttc_sprocket)/(self.ttc_mat_map/(radius/8)) -- 256x256

            if self:GetTTC_FlipMat() then scroll = -scroll end

            self.ttc_mat_scr = self.ttc_mat_scr + scroll*FrameTime()
            self.ttc_mat:SetVector("$translate", Vector(0, self.ttc_mat_scr, 0))
        end
    end

    local color = self:GetTTC_Color()

    render.SetColorModulation(color.r, color.g, color.b)
    render.ModelMaterialOverride(self.ttc_mat or TTC.Fallback_Material)

    local damage = self:RenderACFDamage()

    for i = 1, #self.ttc_spline - 1 do
        local p1 = self.ttc_spline[i + 1]
        local p2 = self.ttc_spline[i]
        local di = self.ttc_chassis:WorldToLocal(p1 - p2 + self.ttc_chassis:GetPos())

        self.ttc_scalev.x = math_min(1000, di:Length())/12
        self.ttc_scalem:SetScale(self.ttc_scalev)

        if not self.ttc_lod and self.ttc_mat then
            self.ttc_mat_sca.y = di:Length()*16/self.ttc_mat_map -- 128x256
            self.ttc_mat:SetVector("$newscale", self.ttc_mat_sca)
        end

        if damage then
            if self.ttc_acfpercent < 1 and self.ttc_acfpercent > 0 then
                self.ttc_acfdamage:SetScale(self.ttc_mat_sca)
                self.ttc_mat:SetMatrix("$detailtexturetransform", self.ttc_acfdamage)
            end
        end

        ClientProp:SetRenderOrigin((p1 + p2)*0.5)
        ClientProp:SetRenderAngles(self.ttc_chassis:LocalToWorldAngles(Angle(math_deg(math_atan2(-di.z, di.x)), 0, 0)))
        ClientProp:EnableMatrix("RenderMultiply", self.ttc_scalem)
        ClientProp:SetupBones()
        ClientProp:DrawModel()
    end

    render.ModelMaterialOverride()
    render.SetColorModulation(1, 1, 1)
end


/* OLD
-- NETWORK: Get entity links from server
function ENT:UpdateLinks(tbl)
    self:Initialize()

    for i, ent in ipairs(tbl) do
        if not IsValid(ent) then
            self:Initialize()
            return
        end

        if i == 1 then self.ttc_chassis = ent continue end

        table.insert(self.ttc_wheels, ent)
    end

    self.ttc_sprocket = self.ttc_wheels[self:GetTTC_Sprocket()] or self.ttc_wheels[1]
    self.ttc_tracky = self.ttc_chassis:WorldToLocal(self.ttc_wheels[1]:GetPos()).y
    self:SetupWheelCount()

    TTC.AddRenderOverride(self)
end
*/

/* OLD
-- TTC: Track spline nodes
function ENT:GenerateNodes()
    self.ttc_nodes = {}

    if #self.ttc_wheels <= 1 then
        self.ttc_nodes = {}
        self.ttc_spline = {}

        return false
    end

    local offset = self.ttc_tracky + self:GetTTC_Offset()

    local ply = LocalPlayer()
    local can_see = false

    for i = 1, #self.ttc_wheels do
        if not IsValid(self.ttc_wheels[i]) then
            table.remove(self.ttc_wheels, i)
            self:SetupWheelCount()

            if #self.ttc_wheels <= 1 then
                self.ttc_nodes = {}
                self.ttc_spline = {}

                return false
            end

            continue
        end

        if not can_see then
            if ply:IsLineOfSightClear(self.ttc_wheels[i]) then can_see = true end
        end

        local pos = self.ttc_chassis:WorldToLocal(self.ttc_wheels[i]:GetPos())
        pos.y = offset

        self.ttc_nodes[#self.ttc_nodes + 1] = self.ttc_chassis:LocalToWorld(pos)
    end

    self.ttc_nodecount = #self.ttc_nodes

    return can_see
end
*/

/* OLD
-- TTC: Track spline points
function ENT:GenerateSpline()
    self.ttc_spline = {}

    local cache_chassis_pos = self.ttc_chassis:GetPos()
    local wrap = self:GetTTC_Type()

    local detail = self.ttc_lod and 3 or self:GetTTC_Detail()

    for i = 1, self.ttc_nodecount do
        local radius = math_abs(self.ttc_wheels[i]:GetHitBoxBounds(0, 0).z)
        if i == 1 or i == self.ttc_nodecount then radius = radius + self:GetTTC_Radius() end

        local node_this = self.ttc_nodes[i]
        local node_next = i == self.ttc_nodecount and (wrap and i - 1 or 1) or i + 1
        local node_prev = i == 1 and (wrap and 2 or self.ttc_nodecount) or i - 1

        local dir_next = self.ttc_chassis:WorldToLocal(self.ttc_nodes[node_next] - node_this + cache_chassis_pos)
        local dir_prev = self.ttc_chassis:WorldToLocal(self.ttc_nodes[node_prev] - node_this + cache_chassis_pos)

        local num_split = detail
        if i == self.ttc_nodecount then
            local atan_next = math_deg(math_atan2(dir_next.x, dir_next.z))
            local atan_prev = math_deg(math_atan2(-dir_prev.x, -dir_prev.z))

            for n = 0, num_split do
                self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(-Angle((atan_prev + (atan_next - atan_prev)*(n/num_split)), 0, 0):Forward()*radius) + node_this - cache_chassis_pos
            end
        else
            local atan_next = math_deg(math_atan2(-dir_next.x, -dir_next.z))
            local atan_prev = math_deg(math_atan2(dir_prev.x, dir_prev.z))

            if i ~= 1 then num_split = math_round((math_abs(atan_next) - math_abs(atan_prev))/(180/detail)) end
            if num_split > 0 then
                for n = 0, num_split do
                    self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Angle((atan_prev + (atan_next - atan_prev)*(n/num_split)), 0, 0):Forward()*radius) + node_this - cache_chassis_pos
                end
            else
                self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Vector(0, 0, -radius)) + node_this - cache_chassis_pos
            end
        end
    end

    if wrap then
        for i = self.ttc_nodecount - 1, 2, -1 do
            local radius = -math_abs(self.ttc_wheels[i]:GetHitBoxBounds(0, 0).z)

            local node_this = self.ttc_nodes[i]

            local dir_next = self.ttc_chassis:WorldToLocal(self.ttc_nodes[i + 1] - node_this + cache_chassis_pos)
            local dir_prev = self.ttc_chassis:WorldToLocal(self.ttc_nodes[i - 1] - node_this + cache_chassis_pos)

            local atan_next = math_deg(math_atan2(-dir_next.x, -dir_next.z))
            local atan_prev = math_deg(math_atan2(dir_prev.x, dir_prev.z))

            local num_split = math_round((math_abs(atan_next) - math_abs(atan_prev))/(180/detail))
            if num_split > 0 then
                for n = 0, num_split do
                    self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Angle((atan_prev + (atan_next - atan_prev)*(n/num_split)), 0, 0):Forward()*radius) + node_this - cache_chassis_pos
                end
            else
                self.ttc_spline[#self.ttc_spline + 1] = self.ttc_chassis:LocalToWorld(Vector(0, 0, -radius)) + node_this - cache_chassis_pos
            end
        end

        self.ttc_spline[#self.ttc_spline + 1] = self.ttc_spline[1]
    else
        local p1 = self.ttc_spline[#self.ttc_spline]
        local p2 = self.ttc_spline[1]

        local cache_chassis_up = self.ttc_chassis:GetUp()
        local cache_chassis_vz = -self.ttc_chassis:GetVelocity().z*0.01 + math_sin(math_rad(self.ttc_mat_scr*100))*0.5

        local tensor = (1 - self:GetTTC_Tension())*(self.ttc_nodecount - 2)*2
        local num_split = self.ttc_nodecount - 1
        local num_steps = 180/num_split

        for n = 1, num_split do
            local direct_point = p1 + (p2 - p1)*(n/num_split)
            if n < num_split then
                local invert = num_split - n + 1
                local radius = math_abs(self.ttc_wheels[invert]:GetHitBoxBounds(0, 0).z)

                direct_point = direct_point + cache_chassis_up*(-math_sin(math_rad(num_steps*n))*tensor + cache_chassis_vz)

                local distance = -(self.ttc_nodes[invert] - direct_point):Dot(cache_chassis_up)
                if distance < radius then
                    direct_point = direct_point + cache_chassis_up*(radius - distance)
                end
            end
            self.ttc_spline[#self.ttc_spline + 1] = direct_point
        end
    end
end
*/


