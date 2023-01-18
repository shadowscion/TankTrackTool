
TOOL.Category = "Construction"
TOOL.Name     = "#tool.tanktracktool.listname"


--[[
    mostly clientside stool base using the rest of the tanktracktool lib
]]
local cam, net, ents, math, util, draw, hook, halo, surface, render, language =
      cam, net, ents, math, util, draw, hook, halo, surface, render, language

local tanktracktool = tanktracktool

if SERVER then
    util.AddNetworkString( "tanktracktool_stool" )
else
    language.Add( "tool.tanktracktool.listname", "Tank Track Tool" )
    language.Add( "tool.tanktracktool.name", "Tank Track Tool" )
    language.Add( "tool.tanktracktool.desc", "Spawn and modify controllers" )
end

function TOOL:LeftClick( tr )
    if not tr.Hit then return false end
    if SERVER then
        net.Start( "tanktracktool_stool" )
        net.WriteUInt( 0, 2 )
        net.Send( self:GetOwner() )
    end
    return true
end

function TOOL:RightClick( tr )
    if not tr.Hit then return false end
    if SERVER then
        net.Start( "tanktracktool_stool" )
        net.WriteUInt( 1, 2 )
        net.Send( self:GetOwner() )
    end
    return true
end

function TOOL:Reload( tr )
    if not tr.Hit then return false end
    if SERVER then
        net.Start( "tanktracktool_stool" )
        net.WriteUInt( 2, 2 )
        net.Send( self:GetOwner() )
    end
    return true
end

if SERVER then return end


--[[
    multitool base
]]
local multitool = { modes = {} }

TOOL.Information = {}
local function AddInformation( name, icon, text, stage, op )
    table.insert( TOOL.Information, { name = name, icon = icon, text = text, stage = stage, op = op } )
    language.Add( string.format( "tool.tanktracktool.%s", name ), text )
end

AddInformation( "reset", "materials/gui/r.png", "Reset the tool at any time" )

function TOOL:SetOperation( i ) self._operation = i end
function TOOL:GetOperation() return self._operation or 0 end
function TOOL:SetStage( i ) self._stage = i end
function TOOL:GetStage() return self._stage or 0 end

function TOOL:DrawHUD()
    multitool:draw( self, LocalPlayer() )
end

function TOOL:Think()
    multitool:update( self, LocalPlayer() )
end

net.Receive( "tanktracktool_stool", function()
    local t = LocalPlayer():GetTool()
    if not t or t.Mode ~= "tanktracktool" then return end

    local k = net.ReadUInt( 2 )

    multitool:keyPress( t, t:GetOwner(), k )
end )

concommand.Add( "tanktracktool_multitool_reset", function()
    if multitool then multitool:reset() end
end )


--[[
    multitool methods
]]
function multitool:reset()
    multitool.mode = nil
end

function multitool:setMode( gmod_tool, ply, mode, ... )
    if not self.modes[mode] then mode = "wait" end
    if self.modes[mode].init then
        gmod_tool:SetStage( 0 )
        gmod_tool:SetOperation( 0 )
        self.modes[mode]:init( gmod_tool, ply, self.mode, ... )
        self.mode = mode
    end
end

function multitool:draw( gmod_tool, ply )
    if not self.modes[self.mode] then
        self:setMode( gmod_tool, ply, "wait" )
        return
    end
    if self.modes[self.mode] and self.modes[self.mode].draw then
        self.modes[self.mode]:draw( gmod_tool, ply )
    end
end

function multitool:update( gmod_tool, ply )
    if not self.modes[self.mode] then
        self:setMode( gmod_tool, ply, "wait" )
        return
    end
    if self.modes[self.mode] and self.modes[self.mode].update then
        self.modes[self.mode]:update( gmod_tool, ply )
    end
end

function multitool:keyPress( gmod_tool, ply, key )
    if not self.modes[self.mode] then
        self:setMode( gmod_tool, ply, "wait" )
        return
    end
    if self.modes[self.mode] and self.modes[self.mode].keyPress then
        self.modes[self.mode]:keyPress( gmod_tool, ply, key )
    end
end

function multitool:getLinkableInfo( ent )
    return table.Copy( ent.tanktracktool_linkData )
end

function multitool:isLinkable( ent )
    return IsValid( ent ) and istable( ent.tanktracktool_linkData )
end

function multitool:isCopyable( ent1, ent2 )
    if ent2 then
        if ent1 == ent2 then return false end
        if not IsValid( ent1 ) or ent1.netvar == nil then return false end
        if not IsValid( ent2 ) or ent2.netvar == nil then return false end
        if ent1:GetClass() ~= ent2:GetClass() then return false end
        return true
    end
    return IsValid( ent1 ) and ent1.netvar ~= nil
end

function multitool:findEntities( ply, dist, ang, class )
    local e = {}
    local f = ents.FindInCone( ply:EyePos(), ply:GetAimVector(), dist, math.cos( math.rad( ang ) ) )

    for i = 1, #f do
        local v = f[i]
        if v.netvar and ( not class or v:GetClass() == class ) then e[#e + 1] = v end
    end

    return #e > 0 and e or nil
end


--[[
    HUD stuff
]]
local function rgb( color, a )
    return Color( color.r / 255, color.g / 255, color.b / 255, a )
end

multitool.ui = {}

multitool.ui.colors = {}
multitool.ui.colors.text_class = Color( 255, 200, 0 )
multitool.ui.colors.text_keyword = Color( 0, 255, 255 )
multitool.ui.colors.text_input = Color( 0, 255, 0 )
multitool.ui.colors.text_plain = Color( 255, 255, 255 )
multitool.ui.colors.text_box = Color( 0, 0, 0, 100 )
multitool.ui.colors.text_linked = Color( 255, 200, 0, 200 )
multitool.ui.colors.text_linked_box = Color( 0, 0, 0, 100 )

multitool.ui.colors.ents_bbox = Color( 255, 255, 255, 30 )
multitool.ui.colors.ents_possible = rgb( multitool.ui.colors.text_plain, 0.111 )
multitool.ui.colors.ents_selected = rgb( multitool.ui.colors.text_class, 0.333 )
multitool.ui.colors.ents_hovered = rgb( multitool.ui.colors.text_keyword, 0.333 )

multitool.ui.fonts = {}
multitool.ui.fonts.small = "tanktracktool_stool0"
multitool.ui.fonts.large = "tanktracktool_stool1"

surface.CreateFont( multitool.ui.fonts.small, { font = "Comic Sans MS", size = 16, weight = 100, shadow = false } )
surface.CreateFont( multitool.ui.fonts.large, { font = "Comic Sans MS", size = 24, weight = 100, shadow = false } )

function multitool:renderModel( ent, color )
    if not IsValid( ent ) then return end
    if not IsValid( self.csent ) then
        self.csent = ClientsideModel( "models/error.mdl" )
        self.csent:SetNoDraw( true )
        self.csent:SetMaterial( "models/debug/debugwhite" )
    end

    cam.Start3D()

    render.SuppressEngineLighting( true )
    render.SetBlend( color.a )
    render.SetColorModulation( color.r, color.g, color.b )

    self.csent:SetModel( ent:GetModel() )
    self.csent:SetPos( ent:GetPos() )
    self.csent:SetAngles( ent:GetAngles() )
    self.csent:SetupBones()
    self.csent:DrawModel()

    render.SetBlend( 1 )
    render.SetColorModulation( 1, 1, 1 )
    render.SuppressEngineLighting( false )

    local min, max = ent:GetRenderBounds()
    render.DrawWireframeBox( ent:GetPos(), ent:GetAngles(), min, max, multitool.ui.colors.ents_bbox )

    cam.End3D()
end

local function GetTextSize( text, font )
    surface.SetFont( font )
    local w, h = surface.GetTextSize( text )
    return { w = w, h = h }
end

local function DrawOverlay( x, y, overlay )
    local w, h = 0, 0

    for i = 1, #overlay do
        local ui = overlay[i]

        if ui.enabled then
            y = y - ( ui.size.h ) * 2
            w = math.max( w, ui.size.w )
            h = h + ui.size.h
        end
    end

    x = x - w * 0.5
    if overlay.lower then y = y + h * overlay.lower end
    if overlay.raise then y = y - h * overlay.raise end

    draw.RoundedBox( 8, x - 8, y - 8, w + 16, h + 16, overlay.text_box or multitool.ui.colors.text_box )

    for i = 1, #overlay do
        local ui = overlay[i]
        if not overlay[i].enabled then goto CONTINUE end

        surface.SetFont( ui.font )
        surface.SetTextColor( overlay.text_out or color_black )

        for ox = -1, 1 do
            for oy = -1, 1 do
                surface.SetTextPos( x + ox, y + oy )
                surface.DrawText( ui.text )
            end
        end

        surface.SetTextPos( x, y )
        for j = 1, #ui.draw.text do
            surface.SetTextColor( ui.draw.cols[j] )
            surface.DrawText( ui.draw.text[j] )
        end

        y = y + ui.size.h

        ::CONTINUE::
    end
end

local function GetOverlay( overlay, enabled, param )
    for k, v in ipairs( overlay ) do
        v.text = table.concat( v.draw.text, "" )
        v.size = GetTextSize( v.text, v.font )
        v.enabled = enabled
    end
    if param then
        for k, v in pairs( param ) do
            overlay[k] = v
        end
    end
    return overlay
end


--[[
    wait mode
]]
do
    AddInformation( "wait_look", "materials/icon16/eye.png", "Look at a controller to begin", 0, 0 )
    AddInformation( "wait_copy", "materials/gui/lmb.png", "Copy values from this controller", 1, 0 )
    AddInformation( "wait_link", "materials/gui/rmb.png", "Start linking entities to this controller", 1, 0 )

    multitool.modes.wait = {}

    local overlay = GetOverlay( {
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "",
                },
                cols = {
                    multitool.ui.colors.text_class,
                },
            },
        },
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "Left Click ",
                    "to ",
                    "copy values ",
                    "from this controller",
                },
                cols = {
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_keyword,
                    multitool.ui.colors.text_plain,
                },
            },
        },
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "Right Click ",
                    "to start ",
                    "linking entities ",
                    "to this controller",
                },
                cols = {
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_keyword,
                    multitool.ui.colors.text_plain,
                },
            },
        },
    } )

    function multitool.modes.wait:init( gmod_tool, ply, prevmode, ... )
        overlay[1].enabled = false
        overlay[2].enabled = false
        overlay[3].enabled = false
    end

    function multitool.modes.wait:keyPress( gmod_tool, ply, key )
        if key == 2 then return multitool:reset() end

        if IsValid( self.LookAt ) then
            if multitool:isCopyable( self.LookAt ) and key == 0 then
                multitool:setMode( gmod_tool, ply, "copy", self.LookAt )
                return
            end

            if multitool:isLinkable( self.LookAt ) and key == 1 then
                multitool:setMode( gmod_tool, ply, "link", self.LookAt )
                return
            end
        end
    end

    function multitool.modes.wait:update( gmod_tool, ply )
        local tr = ply:GetEyeTrace()

        if tanktracktool.netvar.isValid( tr.Entity ) then
            overlay[1].enabled = true
            overlay[2].enabled = multitool:isCopyable( tr.Entity )
            overlay[3].enabled = multitool:isLinkable( tr.Entity )

            self.LookAt = tr.Entity
            gmod_tool:SetStage( 1 )
        else
            overlay[1].enabled = false
            overlay[2].enabled = false
            overlay[3].enabled = false

            self.LookAt = nil
            gmod_tool:SetStage( 0 )
        end

        self.Ents = multitool:findEntities( ply, 200, 45 )
    end

    function multitool.modes.wait:draw( gmod_tool, ply )
        if self.Ents then
            for i = 1, #self.Ents do
                local v = self.Ents[i]
                if v == self.LookAt then
                    goto CONTINUE
                end

                multitool:renderModel( self.Ents[i], multitool.ui.colors.ents_possible )

                ::CONTINUE::
            end
        end

        if IsValid( self.LookAt ) then
            multitool:renderModel( self.LookAt, multitool.ui.colors.ents_hovered )

            local pos = self.LookAt:GetPos():ToScreen()
            local x = pos.x
            local y = pos.y

            local class = self.LookAt:GetClass()
            overlay[1].text = class
            overlay[1].size = GetTextSize( class, overlay[1].font )
            overlay[1].draw.text[1] = class

            DrawOverlay( x, y, overlay )
        end
    end
end



--[[
    copy mode
]]
do
    AddInformation( "copy_look", "materials/icon16/eye.png", "Look at another controller to begin", 0, 1 )
    AddInformation( "copy_to", "materials/gui/lmb.png", "+ Shift to paste values to this controller", 1, 1 )

    multitool.modes.copy = {}

    local overlay = GetOverlay( {
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "",
                },
                cols = {
                    multitool.ui.colors.text_class,
                },
            },
        },
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "Left Click ",
                    "and ",
                    "Shift ",
                    "to ",
                    "paste values ",
                    "to this controller",
                },
                cols = {
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_keyword,
                    multitool.ui.colors.text_plain,
                },
            },
        },
    } )

    function multitool.modes.copy:init( gmod_tool, ply, prevmode, ent )
        self.CopyFrom = ent
        if not IsValid( self.CopyFrom ) then
            multitool:reset()
            return
        end

        overlay[1].enabled = true
        overlay[2].enabled = true

        gmod_tool:SetOperation( 1 )
    end

    function multitool.modes.copy:update( gmod_tool, ply )
        if not IsValid( self.CopyFrom ) then
            multitool:reset()
            return
        end

        local tr = ply:GetEyeTrace()

        if not IsValid( tr.Entity ) or not multitool:isCopyable( self.CopyFrom, tr.Entity ) then
            self.LookAt = nil
            gmod_tool:SetStage( 0 )
        else
            self.LookAt = tr.Entity
            gmod_tool:SetStage( 1 )
        end

        self.Ents = multitool:findEntities( ply, 200, 45, self.CopyFrom:GetClass() )
    end

    function multitool.modes.copy:draw( gmod_tool, ply )
        if not IsValid( self.CopyFrom ) then return end

        if self.Ents then
            for i = 1, #self.Ents do
                local v = self.Ents[i]
                if v == self.CopyFrom or v == self.LookAt then
                    goto CONTINUE
                end

                multitool:renderModel( v, multitool.ui.colors.ents_possible )

                ::CONTINUE::
            end
        end

        multitool:renderModel( self.CopyFrom, multitool.ui.colors.ents_selected )

        if IsValid( self.LookAt ) then
            multitool:renderModel( self.LookAt, multitool.ui.colors.ents_hovered )

            local pos = self.LookAt:GetPos():ToScreen()
            local x = pos.x
            local y = pos.y

            local class = self.LookAt:GetClass()
            overlay[1].text = class
            overlay[1].size = GetTextSize( class, overlay[1].font )
            overlay[1].draw.text[1] = class

            DrawOverlay( x, y, overlay )
        end
    end

    function multitool.modes.copy:keyPress( gmod_tool, ply, key )
        if key == 2 then return multitool:reset() end

        if key == 0 and ply:KeyDown( IN_SPEED ) then
            if IsValid( self.CopyFrom ) and IsValid( self.LookAt ) then
                if multitool:isCopyable( self.CopyFrom, self.LookAt ) then
                    net.Start( "tanktracktool_link" )
                    net.WriteUInt( self.LookAt:EntIndex(), 16 )
                    net.WriteUInt( 2, 2 )
                    net.WriteUInt( self.CopyFrom:EntIndex(), 16 )
                    net.SendToServer()
                end

                return multitool:reset()
            end
        end
    end
end


--[[
    link mode
]]
do
    AddInformation( "link_look", "materials/icon16/eye.png", "Look at another entity to begin", 0, 2 )
    AddInformation( "link_set", "materials/gui/rmb.png", "Link this entity to selected controller", 1, 2 )

    multitool.modes.link = {}

    local overlay = GetOverlay( {
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "",
                },
                cols = {
                    multitool.ui.colors.text_class,
                },
            },
        },
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "Right Click ",
                    "to ",
                    "link this ",
                    "entity as ",
                    "",
                },
                cols = {
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_keyword,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_class,
                },
            },
        },
        {
            font = multitool.ui.fonts.large,
            draw = {
                text = {
                    "Right Click ",
                    "and ",
                    "Shift ",
                    "to ",
                    "link this ",
                    "entity as ",
                    "",
                },
                cols = {
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_input,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_keyword,
                    multitool.ui.colors.text_plain,
                    multitool.ui.colors.text_class,
                },
            },
        },
    } )

    function multitool.modes.link:init( gmod_tool, ply, prevmode, ent )
        self.LinkTo = ent
        if not IsValid( self.LinkTo ) or not multitool:isLinkable( self.LinkTo ) then
            multitool:reset()
            return
        end

        self.Data = {}
        self.Data.Send = {}
        self.Data.Info = multitool:getLinkableInfo( self.LinkTo )
        self.Data.Command = 1

        self:updateOverlay()

        gmod_tool:SetOperation( 2 )
    end

    function multitool.modes.link:update( gmod_tool, ply )
        if not IsValid( self.LinkTo ) then
            multitool:reset()
            return
        end

        local tr = ply:GetEyeTrace()

        if not IsValid( tr.Entity ) or tr.Entity == self.LinkTo then
            self.LookAt = nil
            gmod_tool:SetStage( 0 )
        else
            self.LookAt = tr.Entity
            gmod_tool:SetStage( 1 )
        end

        if self.Ents then
            for ent, disp in pairs( self.Ents ) do
                if not IsValid( ent ) then
                    return multitool:reset()
                end
            end
        end
    end

    function multitool.modes.link:draw( gmod_tool, ply )
        if not IsValid( self.LinkTo ) then return end

        multitool:renderModel( self.LinkTo, multitool.ui.colors.ents_selected )

        if IsValid( self.LookAt ) then
            multitool:renderModel( self.LookAt, multitool.ui.colors.ents_hovered )

            local pos = self.LookAt:GetPos():ToScreen()
            local x = pos.x
            local y = pos.y

            local class = self.LookAt:GetClass()
            overlay[1].text = class
            overlay[1].size = GetTextSize( class, overlay[1].font )
            overlay[1].draw.text[1] = class

            DrawOverlay( x, y, overlay )
        end
        if self.Ents then
            for ent, disp in pairs( self.Ents ) do
                if not IsValid( ent ) then
                    goto CONTINUE
                end

                local pos = ent:GetPos():ToScreen()
                local x = pos.x
                local y = pos.y

                DrawOverlay( x, y, disp, true )

                ::CONTINUE::
            end
        end
    end

    function multitool.modes.link:updateOverlay()
        overlay[1].enabled = true
        overlay[2].enabled = false
        overlay[3].enabled = false

        self.Ents = {}
        for k, v in pairs( self.Data.Send ) do
            if isentity( v ) then
                -- v == ent
                -- k == key

                self.Ents[v] = self.Ents[v] or {}
                table.insert( self.Ents[v], k )
            else
                for i, j in pairs( v ) do
                    -- i == ent
                    -- j == key

                    self.Ents[i] = self.Ents[i] or {}
                    table.insert( self.Ents[i], j )
                end
            end
        end

        for ent, lines in pairs( self.Ents ) do
            local text = {}

            for k, v in ipairs( lines ) do
                text[#text + 1] = {
                    font = multitool.ui.fonts.small,
                    draw = {
                        text = { v },
                        cols = { multitool.ui.colors.text_linked },
                    }
                }
            end

            self.Ents[ent] = GetOverlay( text, true, {
                lower = 3,
                text_out = multitool.ui.colors.text_linked_box,
                text_box = multitool.ui.colors.text_linked_box,
            } )
        end


        local command = self.Data.Info[self.Data.Command]

        if not command then
            return
        end

        if not command.istable then
            overlay[2].draw.text[5] = command.name
            overlay[2].text = table.concat( overlay[2].draw.text, "" )
            overlay[2].size = GetTextSize( overlay[2].text, overlay[2].font )
            overlay[2].enabled = true
        else
            overlay[2].draw.text[5] = command[1].name
            overlay[2].text = table.concat( overlay[2].draw.text, "" )
            overlay[2].size = GetTextSize( overlay[2].text, overlay[2].font )
            overlay[2].enabled = true

            overlay[3].draw.text[7] = command[2].name
            overlay[3].text = table.concat( overlay[3].draw.text, "" )
            overlay[3].size = GetTextSize( overlay[3].text, overlay[3].font )
            overlay[3].enabled = true
        end
    end

    function multitool.modes.link:keyPress( gmod_tool, ply, key )
        if key == 2 then return multitool:reset() end

        local command = self.Data.Info[self.Data.Command]

        if not command then
            return
        end

        if key == 1 and IsValid( self.LookAt ) then
            if not command.istable then
                self.Data.Send[command.name] = self.LookAt
                self.Data.Command = self.Data.Command + 1
            else
                local name = ply:KeyDown( IN_SPEED ) and command[2].name or command[1].name
                if not self.Data.Send[name] then
                    self.Data.Send[name] = {}
                end
                if not self.Data.Send[name][self.LookAt] then
                    self.Data.Send[name][self.LookAt] = name .. ( table.Count( self.Data.Send[name] ) + 1 )
                end
            end
            self:updateOverlay()
        end
    end
end
