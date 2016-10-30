--[[
    Tank Track Controller Addon
    by shadowscion
]]--

TOOL.Category   = "Construction"
TOOL.Name       = "#tool.gmod_tool_ttc.listname"
TOOL.Command    = nil
TOOL.ConfigName = ""


---------------------------------------------------------------
-- Server/Shared
local table = table

if SERVER then
    util.AddNetworkString("ttc.tool_hud")

    TOOL.Controller = NULL
    TOOL.Chassis = NULL
    TOOL.CookieJar = {}
    TOOL.DOT = 0
end


-- TOOL: Make sure we can use the entity
local function IsPropOwner(ply, ent, singleplayer)
    if singleplayer then return true end
    if CPPI then return ent:CPPIGetOwner() == ply end

    for k, v in pairs(g_SBoxObjects) do
        for b, j in pairs(v) do
            for _, e in pairs(j) do
                if e == ent and k == ply:UniqueID() then return true end
            end
        end
    end

    return false
end

function TOOL:CanManipulate(ply, trace, world)
    if not ply then return false end
    if not trace.Hit then return false end
    if not trace.Entity then return false end

    if trace.Entity:IsWorld() then return world end
    if string.find(trace.Entity:GetClass(), "npc_") or trace.Entity:GetClass() == "player" or trace.Entity:GetClass() == "prop_ragdoll" then return false end
    if not IsPropOwner(ply, trace.Entity, game.SinglePlayer()) then return false end

    return true
end


-- TOOL: Send hud stuff
function TOOL:UpdateClient()
    net.Start("ttc.tool_hud")
        net.WriteEntity(self.Controller)
        net.WriteEntity(self.Chassis)
    net.Send(self:GetOwner())
end


-- TOOL: Add entity to tool selection
local colors = {
    [1] = Color(0, 0, 255, 255), -- controller
    [2] = Color(46, 204, 113, 255), -- chassis
    [true] = Color(241, 196, 15, 255), -- rollers
    [false] = Color(231, 75, 60, 255), -- wheels
}

function TOOL:OnKeyPropRemove(e)
    self.Controller = NULL
    self.Chassis = NULL
    self.DOT = 0
    self:DeselectAllEntities()
    self:SetStage(0)
    self:UpdateClient()
end

function TOOL:SelectEntity(ent, notify)
    if self.CookieJar[ent] then return false end

    local is_roller = self:GetOwner():KeyDown(IN_SPEED)
    self.CookieJar[ent] = {
        Color = ent:GetColor(),
        Mode = ent:GetRenderMode(),
        Roller = is_roller,
    }

    ent:SetColor(colors[table.Count(self.CookieJar)] or colors[is_roller] or ent:GetColor())
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)

    ent:CallOnRemove("ttc_tool_select", function(e)
        if self.Controller == e or self.Chassis == e then
            self:OnKeyPropRemove(e)
            return
        end

        self.CookieJar[e] = nil
    end)

    if IsValid(self.Chassis) and ent ~= self.Chassis then
        self.DOT = self.DOT + (self.Chassis:GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
    end

    if notify then self:GetOwner():ChatPrint("Selected " .. tostring(ent)) end

    return true
end


-- TOOL: Remove entity from tool selection
function TOOL:DeselectEntity(ent, notify)
    if not self.CookieJar[ent] then return false end
    if not IsValid(ent) then self.CookieJar[ent] = nil return false end

    ent:SetColor(self.CookieJar[ent].Color)
    ent:SetRenderMode(self.CookieJar[ent].Mode)
    ent:RemoveCallOnRemove("ttc_tool_select")

    if IsValid(self.Chassis) and ent ~= self.Chassis then
        self.DOT = self.DOT - (self.Chassis:GetRight():Dot((ent:GetPos() - self.Chassis:GetPos()):GetNormal()) > 0 and 1 or -1)
    end

    if notify then self:GetOwner():ChatPrint("Deselected " .. tostring(ent)) end

    self.CookieJar[ent] = nil

    return true
end


-- TOOL: Remove all entities from tool selection
function TOOL:DeselectAllEntities()
    for ent, _ in pairs(self.CookieJar) do
        self:DeselectEntity(ent)
    end
end


-- TOOL: Left Click - Spawning controller
function TOOL:LeftClick(trace)
    if CLIENT then return true end
    if not self:CanManipulate(self:GetOwner(), trace, true) then return false end

    if trace.Entity:GetClass() == "gmod_ent_ttc" then
        if self:GetOwner():KeyDown(IN_SPEED) then
            self.CopySettings = table.Copy(trace.Entity:GetNetworkVars())
        else
            if not self.CopySettings then return false end
            for func, value in pairs(self.CopySettings) do
                if trace.Entity["Set" .. func] then trace.Entity["Set" .. func](trace.Entity, value) end
            end
        end

        return true
    end

    local create_new = ents.Create("gmod_ent_ttc")

    create_new:SetDefaults()
    create_new:SetPos(trace.HitPos)
    create_new:SetAngles(trace.HitNormal:Angle() + Angle(90, 0, 0))
    create_new:Spawn()
    create_new:Activate()

    create_new:SetNetworkedInt("ownerid", self:GetOwner():UserID())

    self:GetOwner():AddCount("gmod_ent_ttc", create_new)
    self:GetOwner():AddCleanup("gmod_ent_ttc", create_new)
    self:GetOwner():ChatPrint("You can edit this controller using the context menu (hold C and right click it).")

    undo.Create("gmod_ent_ttc")
        undo.AddEntity(create_new)
        undo.SetPlayer(self:GetOwner())
    undo.Finish()

    if not trace.Entity:IsWorld() then
        constraint.Weld(create_new, trace.Entity, 0, trace.PhysicsBone, 0, 1, false)
    end

    create_new:SetCollisionGroup(COLLISION_GROUP_NONE)

    return true
end


-- TOOL: Right Click - Selection entities
function TOOL:RightClick(trace)
    if CLIENT then return true end
    if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

    if self.CookieJar[trace.Entity] then
        if self.Controller == trace.Entity or self.Chassis == trace.Entity then
            if trace.Entity == self.Controller and IsValid(self.Chassis) then
                local valid = (math.abs(self.DOT) == table.Count(self.CookieJar) - 2)

                if table.Count(self.CookieJar) <= 3 then
                    self:GetOwner():ChatPrint("You must select more than one wheel!")
                    return false
                elseif not valid then
                    self:GetOwner():ChatPrint("Wheels must be parallel to the green arrow!")
                else
                    local tbl = table.GetKeys(self.CookieJar)

                    table.RemoveByValue(tbl, self.Controller)
                    table.RemoveByValue(tbl, self.Chassis)

                    local sort_pos = self.Chassis:GetPos() + self.Chassis:GetForward()*10000

                    table.sort(tbl, function(a, b)
                        local bool_this = self.CookieJar[a].Roller
                        local bool_that = self.CookieJar[b].Roller

                        if bool_this ~= bool_that then
                            return bool_that and not bool_this
                        end

                        if bool_this then
                            return a:GetPos():Distance(sort_pos) > b:GetPos():Distance(sort_pos)
                        else
                            return a:GetPos():Distance(sort_pos) < b:GetPos():Distance(sort_pos)
                        end
                    end)

                    table.insert(tbl, 1, self.Chassis)
                    self.Controller:SetLinkedEntities(tbl)
                end
            end

            self.DOT = 0
            self.Controller = NULL
            self.Chassis = NULL
            self:DeselectAllEntities()
            self:SetStage(0)

            self:UpdateClient()

            return true
        end

        self:DeselectEntity(trace.Entity, false)
        self:UpdateClient()

        return true
    end

    if self:GetStage() == 0 then
        if trace.Entity:GetClass() ~= "gmod_ent_ttc" then
            self:GetOwner():ChatPrint("Select a controller first!")
            return false
        end

        self:SelectEntity(trace.Entity, false)
        self.Controller = trace.Entity
        self:SetStage(1)
        self:UpdateClient()

        return true
    end

    if self:GetStage() == 1 then
        self:SelectEntity(trace.Entity, false)
        self.Chassis = trace.Entity
        self:SetStage(2)
        self:UpdateClient()

        return true
    end

    self:SelectEntity(trace.Entity, false)

    return true
end


-- TOOL: Reload - Clearing selection or resetting controller
function TOOL:Reload(trace)
    if CLIENT then return true end

    if not trace.Hit then return false end
    if not trace.Entity then return false end

    if trace.Entity:IsWorld() then
        self.DOT = 0
        self.CopySettings = nil
        self.Controller = NULL
        self.Chassis = NULL
        self:DeselectAllEntities()
        self:SetStage(0)
        self:UpdateClient()

        return true
    end

    if trace.Entity:GetClass() ~= "gmod_ent_ttc" then return false end
    if IsValid(self.Controller) or IsValid(self.Chassis) then return false end
    if not self:CanManipulate(self:GetOwner(), trace, false) then return false end

    if self:GetOwner():KeyDown(IN_SPEED) then
        trace.Entity:SetDefaults()
    else
        trace.Entity:UnsetLinkedEntities()
    end
end



---------------------------------------------------------------
-- Client
if SERVER then return end

-- TOOL: Language
language.Add("tool.gmod_tool_ttc.listname", "Tank Tracks")
language.Add("tool.gmod_tool_ttc.name", "Tank Tracks")
language.Add("tool.gmod_tool_ttc.desc", "Renders animated tank tracks around a group of wheels.")
language.Add("Undone_gmod_ent_ttc", "Undone Tank Track Controllers")
language.Add("Cleaned_gmod_ent_ttc", "Cleaned up Tank Track Controllers")
language.Add("Cleanup_gmod_ent_ttc", "Tank Track Controllers")

TOOL.Information = {}

local function ToolInfo(name, desc, stage)
    table.insert(TOOL.Information, { name = name, stage = stage })
    language.Add("tool.gmod_tool_ttc." .. name, desc)
end

-- left click
ToolInfo("left_1", "Spawn a new controller, or hold SHIFT to copy settings, click another controller to apply copied settings", 0)

-- Right click
ToolInfo("right_1", "Select a controller", 0)
ToolInfo("right_2", "Select a chassis", 1)
ToolInfo("right_3a", "Select all wheels, hold SHIFT while selecting return rollers, select the controller again to finalize", 2)
ToolInfo("info_2", "Wheels must be parallel to the green arrow", 2)

-- Reload
ToolInfo("reload_1", "Unlink all entities from controller, or hold SHIFT to reset controller to default settings", 0)
ToolInfo("reload_3a", "Deselect all entities", 1)
ToolInfo("reload_3b", "Deselect all entities", 2)


-- TOOL: Hud
local enable_hud_markers = CreateClientConVar("ttc_hud_markers", "1", true, false)
local enable_hud_helpers = CreateClientConVar("ttc_hud_helpers", "1", true, false)

local Controller = NULL
local Chassis = NULL

local cam = cam
local math = math
local draw = draw
local render = render
local surface = surface
local IsValid = IsValid

local arrow_mat = Material( "widgets/arrow.png", "unlitsmooth" )

net.Receive("ttc.tool_hud", function()
    Controller = net.ReadEntity() or NULL
    Chassis = net.ReadEntity() or NULL
end)


function TOOL:DrawHUD()
    local trace = LocalPlayer():GetEyeTrace()
    if not trace.Hit then return end

    -- always show this, to avoid any confusion of how wheels should be set up
    if IsValid(Chassis) then
        local min, max = Chassis:OBBMins(), Chassis:OBBMaxs()
        cam.Start3D()
            render.SetMaterial(arrow_mat)
            render.DrawBeam(Chassis:LocalToWorld(Vector(min.x, 0, 0)), Chassis:LocalToWorld(Vector(max.x, 0, 0)), 4, 1, 0, HSVToColor(140, 0.77, 1))
            render.DrawBeam(Chassis:LocalToWorld(Vector(min.x, min.y, 0)), Chassis:LocalToWorld(Vector(max.x, min.y, 0)), 4, 1, 0, HSVToColor(5, 0.73, 1))
            render.DrawBeam(Chassis:LocalToWorld(Vector(min.x, max.y, 0)), Chassis:LocalToWorld(Vector(max.x, max.y, 0)), 4, 1, 0, HSVToColor(5, 0.73, 1))
        cam.End3D()
    end

    -- disable if hud helpers are disabled
    if enable_hud_helpers:GetBool() then
        if IsValid(Controller) then
            local pos = Controller:GetPos():ToScreen()
            draw.SimpleTextOutlined("Controller (" .. Controller:EntIndex() .. ")", "Trebuchet24", pos.x, pos.y, Color(255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
        end

        if not trace.Entity or trace.Entity:IsWorld() then return end

        if IsValid(Controller) then
            cam.Start3D()
                local min, max = trace.Entity:GetCollisionBounds()
                render.DrawWireframeBox(trace.Entity:GetPos(), trace.Entity:GetAngles(), min, max, Color(150, 150, 150, 255), true)
            cam.End3D()
        end
    end

    -- disable if hud markers are disabled
    if enable_hud_markers:GetBool() then
        if not trace.Entity or trace.Entity:IsWorld() then return end

        if trace.Entity:GetClass() == "gmod_ent_ttc" and self:GetStage() == 0 then
            if trace.Entity:GetNetworkedInt("ownerid") ~= LocalPlayer():UserID() then return end

            local pos = trace.Entity:GetPos()
            local fade = 1 - math.min(500, pos:Distance(EyePos())) / 500

            if fade == 0 then return end

            pos = pos:ToScreen()

            draw.SimpleTextOutlined("Edit me!", "Trebuchet24", pos.x, pos.y, Color(255, 255, 255, 255*fade), 0, 0, 1, Color(0, 0, 0, 255*fade))

            cam.Start3D()
                local min, max = trace.Entity:GetCollisionBounds()
                render.DrawWireframeBox(trace.Entity:GetPos(), trace.Entity:GetAngles(), min, max, Color(150, 150, 150, 255*fade), true)
            cam.End3D()

            if IsValid(trace.Entity.ttc_chassis) then
                local lpos = trace.Entity.ttc_chassis:GetPos():ToScreen()

                surface.SetDrawColor(46, 204, 113, 255*fade)
                surface.DrawLine(pos.x, pos.y, lpos.x, lpos.y)
                surface.DrawRect(lpos.x - 3, lpos.y - 3, 6, 6)
            end

            for i, wheel in ipairs(trace.Entity.ttc_wheels) do
                if not IsValid(wheel.ent) then continue end

                local lpos = wheel.ent:GetPos():ToScreen()

                local r, g, b
                if wheel.ent == trace.Entity.ttc_sprocket then
                    r, g, b = 52, 152, 219
                    surface.SetDrawColor(r, g, b, 255*fade)
                    surface.DrawLine(pos.x, pos.y, lpos.x, lpos.y)
                else
                    if i > #trace.Entity.ttc_wheels - trace.Entity.ttc_rollercount then
                        r, g, b = 241, 196, 15
                    else
                        r, g, b = 231, 75, 60
                    end
                end

                surface.SetDrawColor(r, g, b, 255*fade)
                surface.DrawRect(lpos.x - 3, lpos.y - 3, 6, 6)
            end

            for i = 1, #trace.Entity.ttc_spline - 1 do
                local p1 = trace.Entity.ttc_spline[i]:ToScreen()
                local p2 = trace.Entity.ttc_spline[i + 1]:ToScreen()

                surface.SetDrawColor(189, 195, 199, 100*fade)
                surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                surface.SetDrawColor(189, 195, 199, 255*fade)
                surface.DrawRect(p1.x - 2, p1.y - 2, 4, 4)
            end
        end
    end
end


-- TOOL: CPanel
function TOOL.BuildCPanel(self)
    self.Paint = function(pnl, w, h)
        draw.RoundedBox(0, 0, 0, w, 20, Color(50, 50, 50, 255))
        draw.RoundedBox(0, 1, 1, w - 2, 18, Color(125, 125, 125, 255))
    end

    self:AddControl("Header", {
        Description = "Use the context menu (hold C and right click the controller) to configure!"
    })

    self:AddControl("Toggle", {
        Label = "Enable HUD Selection Helpers",
        Command = "ttc_hud_helpers",
    })

    self:AddControl("Toggle", {
        Label = "Enable HUD Entity Markers",
        Command = "ttc_hud_markers",
    })

    self:AddControl("Toggle", {
        Label = "Enable Damaged Track Textures",
        Command = "ttc_render_damage",
    })

    self:AddControl("Toggle", {
        Label = "Disable Rendering",
        Command = "ttc_block_all",
    })

    self:AddControl("Button", {
        Label = "Refresh All",
        Command = "ttc_refresh",
    })
end
