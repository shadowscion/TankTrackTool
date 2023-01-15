
local tanktracktool = tanktracktool
local net, hook, util, math, string, table, surface, draw, scripted_ents, Entity, IsValid, istable, isfunction =
      net, hook, util, math, string, table, surface, draw, scripted_ents, Entity, IsValid, istable, isfunction

tanktracktool.linker = tanktracktool.linker or {}
local linker = tanktracktool.linker

function linker.openUI( ent )
    linker.TOOL:Init( ent )
end


--[[
    tool setup
]]
linker.TOOL = {}

linker.TOOL.HookName = "tanktracktoolLinker"

linker.TOOL.Colors = {}
linker.TOOL.Colors.line_link = Color( 236, 240, 241, 50 )
linker.TOOL.Colors.text_link = Color( 236, 240, 241 )
linker.TOOL.Colors.text_send = Color( 125, 255, 125, 255 )
linker.TOOL.Colors.text_keys = Color( 255, 125, 125, 255 )
linker.TOOL.Colors.bbox = Color( 255, 255, 255, 50 )
linker.TOOL.Colors.font_small = "Trebuchet18"
linker.TOOL.Colors.font_large = "Trebuchet24"

linker.TOOL.Sounds = {}
linker.TOOL.Sounds.Enabled = true
linker.TOOL.Sounds.Confirm = "garrysmod/ui_click.wav"
linker.TOOL.Sounds.Cancel = "buttons/button18.wav"
linker.TOOL.Sounds.Link = "garrysmod/ui_return.wav"
linker.TOOL.Sounds.Open = "garrysmod/ui_return.wav"

hook.Remove( "HUDPaint", linker.TOOL.HookName )
hook.Remove( "PlayerBindPress", linker.TOOL.HookName )

local function KeyPress( ply, bind, pressed, code ) return linker.TOOL:KeyPress( bind, code, ply ) end
local function Paint() return linker.TOOL:Paint() end

local function FormatText( self, v )
    if not v.bind then return end
    local text = {}

    table.insert( text, self.Colors.text_link )
    table.insert( text, "Press " )

    for i = 1, #v.bind do
        table.insert( text, self.Colors.text_keys )
        table.insert( text, string.upper( language.GetPhrase( input.GetKeyName( v.bind[i] ) ) ) )

        if i < #v.bind then
            table.insert( text, self.Colors.text_link )
            table.insert( text, " and " )
        end
    end

    table.insert( text, self.Colors.text_link )
    table.insert( text, " to link " )

    table.insert( text, self.Colors.text_send )
    table.insert( text, v.name )

    return text
end

function linker.TOOL:Exit( nosound )
    hook.Remove( "HUDPaint", self.HookName )
    hook.Remove( "PlayerBindPress", self.HookName )
    self.Data = nil
    if not nosound then self:PlaySound( self.Sounds.Cancel ) end
end

function linker.TOOL:Confirm()
    net.Start( "tanktracktool_link" )
    net.WriteUInt( self.Data.Controller:EntIndex(), 16 )
    net.WriteUInt( 1, 2 )
    net.WriteTable( self.Data.Sender_Table )
    net.SendToServer()

    self:PlaySound( self.Sounds.Confirm )
    self:Exit( true )
end

function linker.TOOL:Init( ent )
    self:Exit( true )

    self.Data = {}
    self.Data.Time = SysTime()
    self.Data.Linker = table.Copy( ent.tanktracktool_linkerData )
    self.Data.Sender_Lookup = {}
    self.Data.Sender_Table = {}
    self.Data.Controller = ent
    self.Data.Sender_Display = {
        [self.Data.Controller] = {
            { self.Colors.text_send, "Controller" },
            {
                self.Colors.text_link, "Press ",
                self.Colors.text_keys, string.upper( language.GetPhrase( input.GetKeyName( KEY_R ) ) ),
                self.Colors.text_link, " to cancel",
            }
        }
    }
    self.Data.ConfirmText = {
        self.Colors.text_link, "Press ",
        self.Colors.text_keys, string.upper( language.GetPhrase( input.GetKeyName( KEY_E ) ) ),
        self.Colors.text_link, " to confirm",
    }

    for _, v in pairs( self.Data.Linker ) do
        if v.name then
            v.text = FormatText( self, v )
        else
            for _, v in pairs( v ) do
                v.text = FormatText( self, v )
                self.Data.Sender_Lookup[v.name] = {}
                self.Data.Sender_Table[v.name] = {}
            end
        end
    end

    hook.Add( "HUDPaint", self.HookName, Paint )
    hook.Add( "PlayerBindPress", self.HookName, KeyPress )

    self:PlaySound( self.Sounds.Open )
end

function linker.TOOL:PlaySound( path )
    if self.Sounds.Enabled and path then
        surface.PlaySound( path )
    end
end

function linker.TOOL:CheckDoubleKey()
    local t = SysTime()
    if t - self.Data.Time > 0.25 then
        self.Data.Time = t
        return false
    else
        self.Data.Time = t
        return true
    end
end

function linker.TOOL:KeyPress( bind, code )
    if not IsValid( self.Data.Controller ) or ( input.IsKeyDown( KEY_R ) and not self:CheckDoubleKey() ) then
        self:Exit()
        return true
    end

    local e2 = LocalPlayer():GetEyeTraceNoCursor().Entity
    if e2 == self.Data.Controller and ( input.IsKeyDown( KEY_E ) and not self:CheckDoubleKey() ) then
        self:Confirm()
        return true
    end

    local id, command = next( self.Data.Linker )
    if not id or not command then
        return
    end

    if command.name then
        local isdown = true

        for i, key in pairs( command.bind or {} ) do
            if not input.IsKeyDown( key ) then
                isdown = false
                break
            end
        end

        if isdown then
            self:SetupLink( id, command )
            return true
        end
    else
        for i, subcommand in ipairs( command ) do
            local isdown = true

            for _, key in pairs( subcommand.bind or {} ) do
                if not input.IsKeyDown( key ) then
                    isdown = false
                    break
                end
            end

            if isdown then
                self:SetupLink( id, subcommand, i )
                return true
            end
        end
    end
end

function linker.TOOL:SetupLink( id, command, subid )
    if self:CheckDoubleKey() then return end
    local e2 = LocalPlayer():GetEyeTraceNoCursor().Entity
    if e2 == self.Data.Controller or not IsValid( e2 ) or e2:IsWorld() then return end

    if not subid then
        if self.Data.Sender_Lookup[command.name] then return end
        self.Data.Sender_Lookup[command.name] = true
        self.Data.Sender_Table[command.name] = e2
        table.remove( self.Data.Linker, id )

        if not self.Data.Sender_Display[e2] then
            self.Data.Sender_Display[e2] = {}
        end
        table.insert( self.Data.Sender_Display[e2], { self.Colors.text_send, command.name } )

        self:PlaySound( self.Sounds.Link )

        return
    end

    if self.Data.Sender_Lookup[command.name][e2] then return end
    self.Data.Sender_Lookup[command.name][e2] = true
    table.insert( self.Data.Sender_Table[command.name], e2 )

    if not self.Data.Sender_Display[e2] then
        self.Data.Sender_Display[e2] = {}
    end
    table.insert( self.Data.Sender_Display[e2], { self.Colors.text_send, string.format( "%s %d", command.name, #self.Data.Sender_Table[command.name] ) } )

    if not command.istable or ( #self.Data.Sender_Table[command.name] == command.maxcount ) then
        table.remove( self.Data.Linker[id], subid )
    end

    self:PlaySound( self.Sounds.Link )
end

local function ColoredText( p0, p1, frac, line, font, t )
    local mx, my

    if frac and p1 then
        local dx = p1.x - p0.x
        local dy = p1.y - p0.y

        mx = p0.x + dx * frac
        my = p0.y + dy * frac

        if line then
            local y = draw.GetFontHeight( font ) * 0.5
            surface.SetDrawColor( line )
            surface.DrawLine( p0.x, p0.y, mx, my + y )
        end
    else
        mx = p0.x
        my = p0.y
    end

    surface.SetFont( font )

    local width = 1
    local steps = ( width * 2 ) / 3
    if steps < 1 then steps = 1 end

    surface.SetTextColor( color_black )

    for x = -width, width, steps do
        for y = -width, width, steps do
            surface.SetTextPos( mx + x, my + y )
            for i = 1, #t, 2 do
                surface.DrawText( t[i + 1] )
            end
        end
    end

    surface.SetTextPos( mx, my )
    for i = 1, #t, 2 do
        surface.SetTextColor( t[i] )
        surface.DrawText( t[i + 1] )
    end
end

function linker.TOOL:Paint()
    if not IsValid( self.Data.Controller ) then
        self:Exit()
        return
    end

    local sh = draw.GetFontHeight( self.Colors.font_small )
    local lh = draw.GetFontHeight( self.Colors.font_large )

    local e1 = self.Data.Controller
    local p1 = e1:GetPos():ToScreen()

    for ent, texts in pairs( self.Data.Sender_Display ) do
        if not IsValid( ent ) then
            self:Exit()
            return
        end

        local p2 = ent:GetPos():ToScreen()

        surface.SetDrawColor( self.Colors.line_link )
        surface.DrawLine( p1.x, p1.y, p2.x, p2.y )

        local y = #texts * sh * 0.5

        for i, text in ipairs( texts ) do
            ColoredText( { x = p2.x, y = p2.y + ( i - 1 ) * sh - y }, nil, nil, nil, self.Colors.font_small, text )
        end
    end

    local e2 = LocalPlayer():GetEyeTraceNoCursor().Entity
    if not IsValid( e2 ) or e2:IsWorld() then return end

    local min, max = e2:GetRenderBounds()
    cam.Start3D()
    render.DrawWireframeBox( e2:GetPos(), e2:GetAngles(), min, max, self.Colors.bbox )
    cam.End3D()

    if e2 == e1 then
        ColoredText( { x = p1.x, y = p1.y + sh }, nil, nil, nil, self.Colors.font_large, self.Data.ConfirmText )
        return
    end

    local id, command = next( self.Data.Linker )
    if not id or not command then
        return
    end

    local p2 = e2:GetPos():ToScreen()

    if command.text then
        local y = self.Data.Sender_Display[e2] and #self.Data.Sender_Display[e2] * sh * 0.5 or 0
        ColoredText( { x = p2.x, y = p2.y + y }, nil, nil, nil, self.Colors.font_large, command.text )
    else
        local y = self.Data.Sender_Display[e2] and #self.Data.Sender_Display[e2] * sh * 0.5 or 0
        for i, subcommand in ipairs( command ) do
            ColoredText( { x = p2.x, y = p2.y + ( i * lh ) + y }, nil, nil, nil, self.Colors.font_large, subcommand.text )
        end
    end
end
