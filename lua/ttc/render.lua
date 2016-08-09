--[[
    Tank Track Controller Addon
    by shadowscion
]]--

-- Initialize and localize main table
TTC = TTC or {}
TTC.RenderOverride = TTC.RenderOverride or {}

local TTC = TTC
local RenderOverride = TTC.RenderOverride

-- Create clientside model
if IsValid(TTC.ClientProp) then
    TTC.ClientProp:Remove()
    TTC.ClientProp = nil

    MsgC(Color(255, 125, 125), "TTC: Recreating TTC ClientProp\n")
end

TTC.ClientProp = ClientsideModel("models/hunter/plates/plate025x025.mdl")
TTC.ClientProp:DrawShadow(false)
TTC.ClientProp:SetNoDraw(true)
TTC.ClientProp:Spawn()

local ClientProp = TTC.ClientProp


-- Fallbacks
TTC.Fallback_Model = "models/hunter/plates/plate025x025.mdl"
TTC.Fallback_Material = Material("models/debug/debugwhite")


-- Allowed models
TTC.Models = {
    ["teeth"] = "models/tanktrack_controller/track_segment_teeth.mdl",
    ["no_teeth"] = "models/tanktrack_controller/track_segment.mdl",
}

for k, v in pairs(TTC.Models) do
    if file.Exists(v, "GAME") then
        continue
    end

    MsgC(Color(255, 125, 125), "TTC: Missing model, make sure the addon is installed locally\n")
    TTC.Models[k] = nil
end


-- Allowed materials
TTC.Textures = {
    ["track1"] = { "tanktrack_controller/track1_d", "tanktrack_controller/track1_n" },
    ["track2"] = { "tanktrack_controller/track2_d", "tanktrack_controller/track2_n" },
    ["track3"] = { "tanktrack_controller/track3_d", "tanktrack_controller/track3_n" },
    ["track4"] = { "tanktrack_controller/track4_d", "tanktrack_controller/track4_n" },
    ["track5"] = { "tanktrack_controller/track5_d", "tanktrack_controller/track5_n" },
    ["track6"] = { "tanktrack_controller/track6_d", "tanktrack_controller/track6_n" },
    ["track7"] = { "tanktrack_controller/track7_d", "tanktrack_controller/track7_n" },
}

for k, v in pairs(TTC.Textures) do
    if file.Exists(string.format("materials/%s.vtf", v[1]), "GAME") and
       (v[2] == nil or file.Exists(string.format("materials/%s.vtf", v[2]), "GAME")) then
       continue
    end

    TTC.Textures[k] = nil
end


-- Material shader
TTC.Shader = {
    ["$basetexture"] = "models/debug/debugwhite",
    ["$alphatest"]   = "1",
    ["$nocull"]      = "1",

    ["$phong"]              = "1",
    ["$phongboost"]         = "0.1",
    ["$phongfresnelranges"] = "[0 0.5 0.5]",
    ["$phongexponent"]      = "15",
    ["$phongalbedotint"]    = "1",

    ["$angle"]     = "0",
    ["$translate"] = "[0.0 0.0 0.0]",
    ["$center"]    = "[0.0 0.0 0.0]",
    ["$newscale"]  = "[1.0 1.0 1.0]",

    ["Proxies"] = {
        ["TextureTransform"] = {
            ["translateVar"] = "$translate",
            ["scaleVar"]     = "$newscale",
            ["rotateVar"]    = "$angle",
            ["centerVar"]    = "$center",
            ["resultVar"]    = "$basetexturetransform",
        },
    }
}


-- Returns an allowed imaterial with the given name
function TTC.GetMaterial(name)
    if not TTC.Textures[name] then return false end

    local data = table.Copy(TTC.Shader)

    data["$basetexture"] = TTC.Textures[name][1] or data["$basetexture"]
    data["$bumpmap"] = TTC.Textures[name][2] or data["$bumpmap"]

    local mat = CreateMaterial("ttc_" .. os.time() .. math.random(1, 1000), "VertexLitGeneric", data)
    local res = mat:Width()/mat:Height()

    return true, mat, res, name
end


-- RenderOverride
local block_all = CreateClientConVar("ttc_block_all", "0", true, false)
local block_sky = false

hook.Add("PreDrawSkyBox", "ttc.draw", function() block_sky = true end)
hook.Add("PostDrawSkyBox", "ttc.draw", function() block_sky = false end)

hook.Add("PostDrawOpaqueRenderables", "ttc.draw", function()
    if not IsValid(ClientProp) then
        TTC.ClientProp = ClientsideModel("models/hunter/plates/plate025x025.mdl")
        TTC.ClientProp:SetNoDraw(true)
        TTC.ClientProp:Spawn()

        ClientProp = TTC.ClientProp

        return
    end

    if block_sky or block_all:GetBool() or FrameTime() == 0 then return end

    local eyepos = EyePos()
    local eyedir = EyeVector()

    for self, _ in pairs(RenderOverride) do
        if self.blocked then continue end

        if not self.HandleLOD or not self.DoRenderOverride then
            TTC.RemoveRenderOverride(self)
            continue
        end

        if self:HandleLOD(eyepos, eyedir) then self:DoRenderOverride() end
    end
end)


-- Add/Remove functions
function TTC.AddRenderOverride(ent)
    RenderOverride[ent] = true
end

function TTC.RemoveRenderOverride(ent)
    RenderOverride[ent] = nil
end

function TTC.GetClientProp()
    return TTC.ClientProp
end


-- Client blocking (thanks wiremod)
TTC.Blocked = {}

local function block_client(ply, cmd, args)
    local toblock
    for _, ply in ipairs(player.GetAll()) do
        if ply:Name() == args[1] then
            toblock = ply
            break
        end
    end
    if not toblock then error("Player not found") end

    local id = toblock:UserID()
    if TTC.Blocked[id] then TTC.Blocked[id] = nil else TTC.Blocked[id] = true end

    for _, ent in ipairs(ents.FindByClass("gmod_ent_ttc")) do
        if ent:GetNetworkedInt("ownerid") == id then
            ent.blocked = TTC.Blocked[id]
        end
    end
end

local function auto_complete()
    local names = {}
    for _, ply in ipairs(player.GetAll()) do
        table.insert(names, "ttc_block_client \"" .. ply:Name() .. "\"")
    end
    table.sort(names)
    return names
end

concommand.Add("ttc_block_client", block_client, auto_complete)
