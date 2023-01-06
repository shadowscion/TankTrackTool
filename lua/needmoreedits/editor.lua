
--
local PANEL = {}
vgui.Register( "nme_editor", PANEL, "DFrame" )

local ASYNC
hook.Add( "Think", "NMEAsync", function()
    if not ASYNC then return end
    if not IsValid( ASYNC.ent ) then ASYNC = nil end

    local time = SysTime()
    while SysTime() - time < 0.05 do
        local ok, err = coroutine.resume( ASYNC.cor )
        if not ok or err then
            if not ok then
                print( err )
                surface.PlaySound( "ui/hint.wav" )
            end

            if ASYNC.ent.TriggerNME then
                ASYNC.ent:TriggerNME( "editor_open", ASYNC.editor )
            end

            ASYNC = nil
            return
        end
    end
end )


--
local math, draw, surface = math, draw, surface

local font_big = "nmefontbig"
local font_small = "nmefontsmall"

surface.CreateFont( font_big, { font = "Arial Bold", size = 14 } )
surface.CreateFont( font_small, { font = "Arial", size = 14 } )

local bevel = 3

local color_default = Color( 122, 189, 254 )
local color_background =  Color( 245, 245, 245, 255 )
local color_text_light = Color( 255, 255, 255, 255 )
local color_text_dark = Color( 50, 50, 50, 255 )
local color_text_shadow = Color( 50, 50, 50, 50 )
local color_button = Color( 255, 255, 255, 50 )

local color_header, color_header_light, color_header_dark, color_row_highlight, color_row_highlight, color_text_entry

local function mix( a, b, t )
    return Color( a.r + ( b.r - a.r ) * t, a.g + ( b.g - a.g ) * t, a.b + ( b.b - a.b ) * t, a.a + ( b.a - a.a ) * t )
end
local function reskin( r, g, b )
    if not color_header then
        color_header = Color( r, g, b )
    else
        color_header.r = r
        color_header.g = g
        color_header.b = b
    end

    color_header_light = mix( color_header, color_white, 0.1 )
    color_header_dark = mix( color_header, color_black, 0.1 )
    color_row_highlight = Color( color_header.r, color_header.g, color_header.b, 25 )
    color_row_highlight = Color( color_header.r, color_header.g, color_header.b, 50 )
    color_text_entry = Color( color_header_light.r, color_header_light.g, color_header_light.b, 100 )
end

reskin( cookie.GetNumber( "NME.color_r", color_default.r ),
       cookie.GetNumber( "NME.color_g", color_default.g ),
       cookie.GetNumber( "NME.color_b", color_default.b ) )


--
local doHalo = cookie.GetNumber( "NME.halo", 1 ) ~= 0
local halos_n

hook.Add( "PreDrawHalos", "NMEHalo", function()
    if doHalo and halos_n then halo.Add( halos_n, color_header, 1, 1, 1 ) end
end )

local doHud = cookie.GetNumber( "NME.hud", 1 ) ~= 0
hook.Add( "HUDPaint", "NMEHud", function()
    if not doHud then return end
    local ent = NeedMoreEdits.Editor and NeedMoreEdits.Editor.m_Entity
    if ent and ent.OverlayNME then
        ent:OverlayNME( NeedMoreEdits.Editor.hoveredNode )
    end
end )


--
local function PaintCategory( self, w, h )
    local exp = self:GetExpanded()
    if exp then
        draw.RoundedBoxEx( bevel, 0, 0, w, self:GetLineHeight(), color_header_light, true, true, false, false )
    else
        draw.RoundedBox( bevel, 0, 0, w, self:GetLineHeight(), color_header )
        self:GetSkin().tex.Input.ComboBox.Button.Down( w - 18, self:GetLineHeight() * 0.5 - 8, 15, 15 )
    end
end

local function PaintRow( self, w, h )
    if self.highlightRow and self:GetExpanded() then
        surface.SetDrawColor( color_row_highlight )
        surface.DrawRect( 0, 1, w, h - 2 )
    elseif self.Label.Hovered or self:IsChildHovered() then
        NeedMoreEdits.Editor.hoveredNode = self
        surface.SetDrawColor( color_row_highlight )
        surface.DrawRect( 0, 0, w, self:GetLineHeight() )
    end

    return DTree_Node.Paint( self, w, h )
end

local faded = Color( 255, 255, 255, 200 )
local function PaintExpander( self, w, h )
    if self:GetExpanded() then
        self:GetSkin().tex.TreeMinus( 0, 0, w, h, faded )
        return
    end

    self:GetSkin().tex.TreePlus( 0, 0, w, h, faded )
end

local function GetLineHeight() return 17 end
local function NoShowIcons() return false end
local function DoShowIcons() return true end
local function DoExpand( self )
    self = self:GetParent()

    if not self:HasChildren() then
        self:SetExpanded( false )
        return
    end

    self:SetExpanded( not self:GetExpanded() )

    if self.Icon and self.Icon:IsVisible() then
        self.Icon:SetImageColor( self:GetExpanded() and color_header or color_header_light )
    end
end
local function ResetIconColor( self ) self:SetImageColor( color_header ) end

local AddNode
function AddNode( self, title )
    local Node

    if self.RootNode then
        Node = DTree.AddNode( self, string.upper( title ) )

        Node:DockMargin( 0, 0, 0, 4 )
        Node:SetHideExpander( true )
        Node:SetDrawLines( false )

        Node.ShowIcons = NoShowIcons
        Node.Paint = PaintCategory

        Node.Label:SetExpensiveShadow( 2, color_text_shadow )
        Node.Label:SetTextColor( color_text_light )
        Node.Label:SetFont( font_big )
    else
        self:SetIcon( "icon16/page_white_horizontal.png" )
        self.Label:SetFont( font_big )

        Node = DTree_Node.AddNode( self, string.lower( title ), "icon16/bullet_white.png" )

        Node.ShowIcons = DoShowIcons
        Node.GetLineHeight = GetLineHeight
        Node.Paint = PaintRow

        Node.Icon:SetImageColor( color_header )
        Node.Label:SetTextColor( color_text_dark )
        Node.Label:SetFont( font_small )
        Node.Expander.Paint = PaintExpander

        Node.Icon.ResetColor = ResetIconColor
        table.insert( self:GetRoot().Icons, Node.Icon )
    end

    Node.Expander.DoClick = DoExpand
    Node.Label.DoClick = DoExpand
    Node.AddNode = AddNode

    Node:InvalidateLayout( true )

    return Node
end


--
function PANEL:Init()
    self:DockPadding( 4, 24, 4, 4 )

    self.DTree = vgui.Create( "DTree", self )
    self.DTree:Dock( FILL )

    self.DTree.Paint = nil
    self.DTree:SetLineHeight( 20 )
    self.DTree.AddNode = AddNode
    self.DTree.OnNodeSelected = function( self ) self:SetSelectedItem( nil ) end

    self.DTree.PerformLayoutInternal = function( self )
        local Tall = self.pnlCanvas:GetTall()
        local Wide = self:GetWide()
        local YPos = 0

        self:Rebuild()

        self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
        YPos = self.VBar:GetOffset()

        if self.VBar.Enabled then Wide = Wide - self.VBar:GetWide() - 4 end -- padding this by 4 is the only reason for the override lol

        self.pnlCanvas:SetPos( 0, YPos )
        self.pnlCanvas:SetWide( Wide )

        self:Rebuild()

        if Tall ~= self.pnlCanvas:GetTall() then
            self.VBar:SetScroll( self.VBar:GetScroll() )
        end
    end

    self.DTree.VBar:SetWide( 8 )
    self.DTree.VBar:SetHideButtons( true )
    self.DTree.VBar.SetEnabled = function( self, b )
        DVScrollBar.SetEnabled( self, true )
    end

    self.DTree:DockMargin( 0, 4, 0, 0 )
    self.DTree.RootNode:DockMargin( 0, 0, 0, 0 )

    self.lblTitle:SetTextInset( 4, 0 )
    self.lblTitle:SetFont( font_small )
    self.lblTitle:SetColor( color_text_light )

    self.btnMinim:Remove()
    self.btnMaxim:Remove()
    self.btnClose:Remove()

    self.btnClose = vgui.Create( "DImageButton", self )
    self.btnClose:SetImage( "gui/cross.png" )
    self.btnClose.DoClick = function()
        self:Remove()
    end
    self.btnClose:SetTooltip( "right click for more options" )
    self.btnClose.DoRightClick = function()
        local menu = DermaMenu()
        menu:SetDrawColumn( true )

        local wiki = self.m_Entity and self.m_Entity.NMEWiki
        if wiki then
            menu:AddOption( "open wiki", function()
                gui.OpenURL( wiki )
            end ):SetIcon( "icon16/help.png" )
        end

        menu:AddSpacer()
        menu:AddOption( "set editor color", function()
            local color = vgui.Create( "DColorCombo", self )

            local x, y = self.btnClose:GetPos()
            color:SetPos( x - color:GetWide(), y )
            color:SetColor( color_header )

            color:SetupCloseButton( function() color:Remove() end )
            color.OnValueChanged = function( color, newcol )
                reskin( newcol.r, newcol.g, newcol.b )
                for k, v in pairs( self.DTree.Icons ) do
                    v:ResetColor()
                end
                cookie.Set( "NME.color_r", newcol.r )
                cookie.Set( "NME.color_g", newcol.g )
                cookie.Set( "NME.color_b", newcol.b )
            end
        end ):SetIcon( "icon16/color_swatch.png" )

        menu:AddOption( "reset editor color", function()
            reskin( color_default.r, color_default.g, color_default.b )
            for k, v in pairs( self.DTree.Icons ) do
                v:ResetColor()
            end
            cookie.Set( "NME.color_r", color_default.r )
            cookie.Set( "NME.color_g", color_default.g )
            cookie.Set( "NME.color_b", color_default.b )
        end ):SetIcon( "icon16/color_swatch.png" )

        menu:AddSpacer()
        menu:AddOption( "toggle entity overlay", function()
            doHud = not doHud
            cookie.Set( "NME.hud", doHud and 1 or 0 )
        end ):SetIcon( "icon16/picture.png" )

        menu:AddOption( "toggle entity outline", function()
            doHalo = not doHalo
            cookie.Set( "NME.halo", doHalo and 1 or 0 )
        end ):SetIcon( "icon16/ipod_cast.png" )

        menu:AddSpacer()
        menu:AddOption( "cancel" ):SetIcon( "icon16/cancel.png" )

        menu:Open()
    end
end

function PANEL:PerformLayout()
    self.lblTitle:SetPos( 0, 0 )
    self.lblTitle:SetSize( self:GetWide(), 24 )

    self.btnClose:SetPos( self:GetWide() - 16 - 4, 4 )
    self.btnClose:SetSize( 16, 16 )
end

function PANEL:Paint( w, h )
    draw.RoundedBoxEx( bevel, 0, 0, w, 24 + 5, color_header, true, true, false, false )
    draw.RoundedBoxEx( bevel, 0, 24, w, h - 24, color_background, false, false, true, true )
end

function PANEL:OnRemove()
    halos_n = nil
    if IsValid( self.m_Entity ) then
        self.m_Entity:RemoveCallOnRemove( "NME_remove" )
        if self.m_Entity.TriggerNME then
            self.m_Entity:TriggerNME( "editor_close" )
        end
    end
end

function PANEL:SetEntity( ent )
    if not scripted_ents.IsBasedOn( ent:GetClass(), "base_nme" ) then
        self:Remove()
        return
    end

    if ent == self.m_Entity then
        return
    end

    self.m_Entity = ent
    self:SetTitle( tostring( self.m_Entity ) )

    halos_n = { self.m_Entity }

    if self.m_Entity.TriggerNME then
        self.m_Entity:TriggerNME( "editor_open", self )
    end

    self.m_Entity:CallOnRemove( "NME_remove", function( e )
        self:Remove()
    end )

    self:ResetControls()
end

local cooldown = SysTime()

function PANEL:Think()
    DFrame.Think( self )

    if not IsValid( self.m_Entity ) then
        self:Remove()
        return
    end

    if SysTime() - cooldown < 0.05 then
        return
    end

    cooldown = SysTime()

    if self.updatelist then
        net.Start( "NMEEdit" )
        net.WriteUInt( self.m_Entity:EntIndex(), 32 )
        net.WriteTable( self.updatelist )
        net.SendToServer()

        self.updatelist = nil
    end
end

--[[
concommand.Add( "needmoreedits", function( cmd, ply, args )

    local ent, name, value, instance = unpack( args )

    if not ent or not name or not value then return end

    if tonumber( value ) then value = tonumber( value ) end

    local update = {}
    if instance then
        if not tonumber( instance ) then return end
        update[name][instance] = value
    else
        update[name] = value
    end

    net.Start( "NMEEdit" )
    net.WriteUInt( tonumber( ent ), 32 )
    net.WriteTable( update )
    net.SendToServer()

end )
]]

--
function PANEL:SetupCallbacks( variables, vnode, vtable )
    if not istable( vtable.edit.callbacks ) then return end

    for k, v in pairs( vtable.edit.callbacks ) do
        if not self.Callbacks[k] then self.Callbacks[k] = { instance = {}, normal = {} } end

        if variables.n[variables.s[k]].instance and vnode.instance then
            if not self.Callbacks[k].instance[vnode.instance] then
                self.Callbacks[k].instance[vnode.instance] = {}
            end
            self.Callbacks[k].instance[vnode.instance][vnode] = v
        else
            self.Callbacks[k].normal[vnode] = v
        end

        v( vnode, nil, self.m_Entity:GetValueNME( k, vnode.instance ) )
        vnode:InvalidateLayout( true )
    end
end

function PANEL:ValueChanged( vnode, vtable, variables, oldvalue, newvalue )
    if oldvalue == nil or newvalue == oldvalue then
        return
    end

    local callbacks = self.Callbacks[vtable.name]
    if callbacks then
        local instance = callbacks.instance[vnode.instance]
        if instance then
            for node, func in pairs( instance ) do
                func( node, oldvalue, newvalue )
                node:InvalidateLayout( true )
            end
        end
        for node, func in pairs( callbacks.normal ) do
            func( node, oldvalue, newvalue )
            node:InvalidateLayout( true )
        end
    end

    if not self.updatelist then
        self.updatelist = {}
    end

    if vnode.instance then
        table.Merge( self.updatelist, {
            [vtable.name] = {
                [vnode.instance] = newvalue
             }
         } )

        return
    end

    self.updatelist[vtable.name] = newvalue
end


--
local function GetLabelX( self, node )
    node.Label:InvalidateLayout( true, true )

    local lx, ly = node.Label:GetPos()
    local lw, lh = node.Label:GetTextSize()
    local li, lj = node.Label:GetTextInset()

    local x, y = self:ScreenToLocal( self:LocalToScreen( ( lx + lw - li ) * 0.5, 0 ) )
    if self.MaxLabelX < x then
        self.MaxLabelX = x
    end
end

function PANEL:ResetControls()
    local cor = coroutine.create( function()
        self.DTree:SetDisabled( true )
        self.DTree:Clear()
        self.DTree.Icons = {}

        self.MaxLabelX = 0
        self.Callbacks = {}

        local catnodes = {}
        --local subcatnodes = {}

        local vars = self.m_Entity.NMEVars

        for k = 1, #vars.n do
            local vtable = vars.n[k]
            if vtable.instance then goto CONTINUE end

            local category = vtable.edit.category or "generic"
            if not catnodes[category] then
                catnodes[category] = self.DTree:AddNode( category )
                catnodes[category].subcatnodes = {}
            end

            local subcatnodes = catnodes[category].subcatnodes

            local subcategory = vtable.edit.subcategory
            if subcategory and not subcatnodes[subcategory] then
                subcatnodes[subcategory] = catnodes[category]:AddNode( subcategory )
                subcatnodes[subcategory].highlightRow= true
            end

            local vnode = ( subcatnodes[subcategory] or catnodes[category] ):AddNode( vtable.edit.title or vtable.name or k )
            self:SetupControl( vnode, vtable, vars )

            local objects = vtable.objects
            if not objects then goto CONTINUE end

            local parentNodes = {}

            for i = 1, vtable.edit.max do
                local parentNode = vnode:AddNode( vtable.edit.getTitle and vtable.edit.getTitle( i ) or vtable.title or vtable.name or i )
                local objectNodes = {}

                parentNode.instance = i
                parentNode.instanceID = vtable.name

                for j = 1, #objects do
                    local objectVar = vars.n[objects[j]]

                    local objectNode = ( objectNodes[objectVar.edit.category] or parentNode ):AddNode( objectVar.edit.title or objectVar.name )
                    objectNode.instance = i
                    objectNode.instanceID = vtable.name

                    self:SetupControl( objectNode, objectVar, vars )

                    objectNodes[objectVar.name] = objectNode
                end

                table.insert( parentNodes, parentNode )
            end

            self:SetupCallbacks( vars, vnode, { -- fake vtable
                edit = {
                    callbacks = {
                        [vtable.name] = function( node, oldvalue, newvalue )
                            for i = 1, #parentNodes do
                                parentNodes[i]:SetEnabled( i <= newvalue )
                            end
                        end
                     }
                 }
             } )

            ::CONTINUE::
        end

        self.MaxLabelX = self.MaxLabelX + 6
        self.DTree:SetDisabled( false )

        coroutine.yield( true )
    end )

    ASYNC = { editor = self, ent = self.m_Entity, cor = cor }
end


-- CONTROLS
local SetupNumber, SetupString, SetupBool, SetupField, SetupColor, SetupCombo

local function SetupInheritMenu( self )
    if self.Label:IsChildHovered() then return end

    local m_Entity = NeedMoreEdits.Editor.m_Entity

    local menu = DermaMenu()
    menu:SetDrawColumn( true )

    if self.inheritAll then
        menu:AddOption( "inherit all values", function()
        for k, v in pairs( self:GetChildNodes() ) do
            if v.inheritValue and not v:GetDisabled() and v.SetControl then
                v:SetControl( m_Entity:GetValueNME( v.inheritValue, self.instance ) )
            end
        end
        end ):SetIcon( "icon16/connect.png" )
    elseif self.inheritValue then
        menu:AddOption( "inherit value", function()
            self:SetControl( m_Entity:GetValueNME( self.inheritValue, self.instance ) )
        end ):SetIcon( "icon16/connect.png" )
    end

    menu:AddSpacer()
    menu:AddOption( "cancel" ):SetIcon( "icon16/cancel.png" )

    menu:Open()
end

function PANEL:SetupControl( vnode, vtable, variables )
    GetLabelX( self, vnode )

    if vtable.type == "float" or vtable.type == "int" then
        SetupNumber( self, vnode, vtable, variables )

    elseif vtable.type == "string" then
        SetupString( self, vnode, vtable, variables )

    elseif vtable.type == "bool" then
        SetupBool( self, vnode, vtable, variables )

    elseif vtable.type == "field" then
        SetupField( self, vnode, vtable, variables )

    elseif vtable.type == "combo" then
        SetupCombo( self, vnode, vtable, variables )

    elseif vtable.type == "color" then
        SetupColor( self, vnode, vtable, variables )

    end

    self:SetupCallbacks( variables, vnode, vtable )

    if vtable.edit.highlight then vnode.highlightRow = true end
    if vtable.edit.help then vnode:SetToolTip( vtable.edit.help ) end

    if vtable.edit.inheritmenu then
        vnode.inheritAll = true
        vnode.DoRightClick = SetupInheritMenu
    else
        local inherit = variables.n[variables.s[vtable.edit.inherit]]
        if inherit and vnode.SetControl then
            vnode.inheritValue = vtable.edit.inherit
            vnode.DoRightClick = SetupInheritMenu
        end
    end

    coroutine.yield( false )
end


-- NUMSLIDER CONTROL
local function PaintTextEntry( self, w, h )
    draw.RoundedBox( bevel, 0, 0, w, h, color_text_entry )
    self:DrawTextEntryText( self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor() )
end

local notch_color = table.Copy( color_text_dark )
notch_color.a = 100

local function UpdateNotches( self ) return self.Slider:SetNotches( 8 ) end
local function ApplySchemeSettings( self )
    self.Slider:SetNotchColor( notch_color )
    self.TextArea:SetTextColor( color_text_dark )
end
local function SliderPerformLayout( self, w, h )
    self.Scratch:SetVisible( true )
    self.Label:SetVisible( true )
    self.Slider:StretchToParent( 0, 0, 0, 0 )
    self.Slider:SetSlideX( self.Scratch:GetFraction() )
end
local function SliderOnMousePressed( self, mcode )
    if mcode ~= MOUSE_LEFT then
        return
    end

    DSlider.OnMousePressed( self, mcode )
end

function SetupNumber( self, vnode, vtable, variables )
    local control = vgui.Create( "DNumSlider", vnode.Label )

    vnode.PerformLayout = function( _, w, h )
        DTree_Node.PerformLayout( _, w, h )

        local tall = vnode:GetLineHeight()
        local wide = self:GetWide() * 0.5 - self.MaxLabelX

        control:SetSize( wide - 1, tall - 2 )
        control:SetPos( w - wide, 1 )
    end

    control.PerformLayout = SliderPerformLayout
    control.ApplySchemeSettings = ApplySchemeSettings
    control.UpdateNotches = UpdateNotches
    control:UpdateNotches()
    control.Slider.OnMousePressed = SliderOnMousePressed
    control.Slider.Knob:NoClipping( false )
    control.Scratch:SetImageVisible( true )
    control.Scratch:SetImage( "icon16/link.png" )
    control.Label:SetWide( 15 )
    control.TextArea:SetWide( 50 )
    control.TextArea.Paint = PaintTextEntry

    control:SetMin( vtable.edit.min )
    control:SetMax( vtable.edit.max )
    control:SetDecimals( vtable.type == "int" and 0 or 2 )

    local oldvalue
    control.OnValueChanged = function( _, value )
        if vtable.type == "int" then
            value = math.floor( value )
            control:SetText( value )
        end

        self:ValueChanged( vnode, vtable, variables, oldvalue, value )
        oldvalue = value
    end

    control:SetValue( self.m_Entity:GetValueNME( vtable.name, vnode.instance ) )

    vnode.SetControl = function( self, value )
        control:SetValue( value )
    end
end


-- TEXTENTRY CONTROL
function SetupString( self, vnode, vtable, variables )
    local control = vgui.Create( "DTextEntry", vnode.Label )

    vnode.PerformLayout = function( _, w, h )
        DTree_Node.PerformLayout( _, w, h )

        local tall = vnode:GetLineHeight()
        local wide = self:GetWide() * 0.5 - self.MaxLabelX

        control:SetSize( wide - 1, tall - 2 )
        control:SetPos( w - wide, 1 )
    end

    control.Paint = PaintTextEntry

    if vtable.edit.numeric then
        control:SetNumeric( true )
    end

    local oldvalue
    control.OnValueChange = function( _, value )
        self:ValueChanged( vnode, vtable, variables, oldvalue, value )
        oldvalue = value
    end

    control:SetValue( self.m_Entity:GetValueNME( vtable.name, vnode.instance ) )

    vnode.SetControl = function( self, value )
        control:SetValue( value )
    end
end


-- CHECKBOX CONTROL
function SetupBool( self, vnode, vtable, variables )
    local control = vgui.Create( "DCheckBox", vnode.Label )

    vnode.PerformLayout = function( _, w, h )
        DTree_Node.PerformLayout( _, w, h )

        local tall = vnode:GetLineHeight()
        local wide = self:GetWide() * 0.5 - self.MaxLabelX

        control:SetPos( w - wide + 1, tall - control:GetTall() )
    end

    local oldvalue
    control.OnChange = function( _, value )
        self:ValueChanged( vnode, vtable, variables, oldvalue, value and 1 or 0 )
        oldvalue = value and 1 or 0
    end

    control:SetValue( self.m_Entity:GetValueNME( vtable.name, vnode.instance ) )

    vnode.SetControl = function( self, value )
        control:SetValue( value )
    end
end


-- FIELD CONTROL
function SetupField( self, vnode, vtable, variables )
    local ftable = table.Copy( self.m_Entity:GetValueNME( vtable.name, vnode.instance ) )
    local controls = {}

    for i = 1, vtable.edit.max do
        local node = vnode:AddNode( vtable.edit.getTitle and vtable.edit.getTitle( i ) or vtable.title or vtable.name or i )

        GetLabelX( self, node )

        local control = vgui.Create( "DTextEntry", node.Label )

        node.PerformLayout = function( _, w, h )
            DTree_Node.PerformLayout( _, w, h )

            local tall = vnode:GetLineHeight()
            local wide = self:GetWide() * 0.5 - self.MaxLabelX

            control:SetSize( wide - 1, tall - 2 )
            control:SetPos( w - wide, 1 )
        end

        control.Paint = PaintTextEntry

        if vtable.numeric then
            control:SetNumeric( true )
        end

        local oldvalue
        control.OnValueChange = function( _, value )
            if oldvalue == value then return elseif value == "" then value = nil end
            if ftable[i] == value then return end
            ftable[i] = value
            self:ValueChanged( vnode, vtable, variables, true, ftable )
            oldvalue = value
        end

        if ftable[i] then
            control:SetValue( ftable[i] )
        end

        controls[i] = control
    end

    vnode.SetControl = function( self, value )
        if not istable( value ) then return end
        for k, v in pairs( value ) do
            if controls[k] then
                controls[k]:SetValue( v )
            end
        end
    end

    vnode.highlightRow = true
end


-- COLORBUTTON CONTROL
local grid = Material( "gui/alpha_grid.png", "nocull" )
local gradient = Material( "vgui/gradient-l" )

local function PaintColorButton( self, w, h )
    local color = self:GetColor()

    if color.a < 255 then
        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.SetMaterial( grid )

        local size = 192
        for i = 0, math.ceil( h / size ) do
            surface.DrawTexturedRect( w / 2 - size / 2, i * size, size, size )
        end

        surface.SetDrawColor( color )
        surface.SetMaterial( gradient )
        surface.DrawTexturedRect( 0, 0, w, h )
        surface.DrawTexturedRect( 0, 0, w, h )

        surface.SetDrawColor( 0, 0, 0, 200 )
        surface.DrawOutlinedRect( 0, 0, w, h )

        return true
    end

    surface.SetDrawColor( color )
    surface.DrawRect( 0, 0, w, h )

    surface.SetDrawColor( 0, 0, 0, 200 )
    surface.DrawOutlinedRect( 0, 0, w, h )

    return true
end

local function ColorMixer( self, callback, panel )
    if not IsValid( self.ColorMixer ) then
        self.ColorMixer = vgui.Create( "DColorCombo", self.DTree )
        self.ColorMixer.Mixer:SetPalette( false )
        self.ColorMixer.Mixer:SetAlphaBar( true )
        self.ColorMixer.Mixer:SetWangs( true )

        self.ColorMixer.OnValueChanged = function( self, value )
            if self.callback then self.callback( value ) end
        end
        self.ColorMixer:SetupCloseButton( function() self.ColorMixer:SetVisible( false ) end )
    end

    self.ColorMixer.callback = callback
    self.ColorMixer:SetVisible( true )

    local x, y = self.DTree:GetChildPosition( panel )
    self.ColorMixer:SetPos( x - self.ColorMixer:GetWide() + panel:GetWide() - 15, y + panel:GetTall() )
end

local function CopyColorMenu( self, control )
    local menu = DermaMenu()
    menu:SetMaxHeight( self:GetTall() * 0.5 )
    menu:SetDrawColumn( true )

    menu:AddOption( "copy color", function()
        self.ColorButtonCopy = control:GetColor()
    end ):SetIcon( "icon16/page_copy.png" )

    if self.ColorButtonCopy then
        menu:AddOption( "paste color", function()
            control.SetValueInternal( self.ColorButtonCopy )
            --control:DoClick()
        end ):SetIcon( "icon16/page_paste.png" )
    end

    menu:AddSpacer()
    menu:AddOption( "cancel" ):SetIcon( "icon16/cancel.png" )

    menu:Open( control:LocalToScreen( 0, control:GetTall() ) )
end

function SetupColor( self, vnode, vtable, variables )
    local control = vgui.Create( "DColorButton", vnode.Label )
    control.Paint = PaintColorButton
    control:SetTooltip( nil )

    vnode.PerformLayout = function( _, w, h )
        DTree_Node.PerformLayout( _, w, h )

        local tall = vnode:GetLineHeight()
        local wide = self:GetWide() * 0.5 - self.MaxLabelX

        control:SetSize( wide, tall - 2 )
        control:SetPos( w - wide, 1 )
    end

    local oldvalue
    local function SetValue( value )
        control:SetColor( value, true )
        value = string.format( "%d %d %d %d", value.r, value.g, value.b, value.a )
        self:ValueChanged( vnode, vtable, variables, oldvalue, value )
        oldvalue = value
    end

    SetValue( string.ToColor( self.m_Entity:GetValueNME( vtable.name, vnode.instance ) ) )
    control.SetValueInternal = SetValue

    control.DoClick = function()
        ColorMixer( self, SetValue, control )
        self.ColorMixer:SetColor( control:GetColor() )
    end

    control.DoRightClick = function()
        CopyColorMenu( self, control )
    end

    vnode.SetControl = function( self, value )
        if isstring( value ) then value = string.ToColor( value ) end
        SetValue( value )
    end
end


-- COMBOBOX CONTROL
function SetupCombo( self, vnode, vtable, variables )
    local control = vgui.Create( "DComboBox", vnode.Label )
    control:SetSortItems( false )
    control:SetTextInset( 8, -1 )

    vnode.PerformLayout = function( _, w, h )
        DTree_Node.PerformLayout( _, w, h )

        local tall = vnode:GetLineHeight()
        local wide = self:GetWide() * 0.5 - self.MaxLabelX

        control:SetSize( wide, tall - 2 )
        control:SetPos( w - wide, 1 )
    end

    local imagePanel
    if isstring( vtable.edit.images ) then
        imagePanel = vgui.Create( "DImage", self )
        imagePanel.SetImage = function( self, value )
            if not vtable.edit.values[value] then
                self:SetVisible( false )
                return
            end

            DImage.SetImage( self, string.format( vtable.edit.images, value ) )
            self:SetVisible( true )
        end
        imagePanel.Paint = function( self, w, h )
            local ret = DImage.Paint( self, w, h )
            surface.SetDrawColor( color_white )
            surface.DrawOutlinedRect( 0, 0, w, h )
            return ret
        end
        imagePanel:SetVisible( false )
    end

    local optionID = {}
    local optionIcons = vtable.edit.icons

    for k, v in SortedPairsByValue( vtable.edit.values ) do
        local ID = control:AddChoice( k, nil, false, optionIcons and optionIcons[k] or "icon16/bullet_white.png" )
        optionID[k] = ID

        control:AddSpacer()
    end

    local OnCursorEntered
    if imagePanel then
        OnCursorEntered = function( self )
            imagePanel:SetImage( self:GetText() )

            if self.ParentMenu then
                self.ParentMenu:OpenSubMenu( self, self.SubMenu )
                return
            end

            self:GetParent():OpenSubMenu( self, self.SubMenu )
        end
    end

    control.OnMenuOpened = function( _, menu )
        menu:SetPos( control:LocalToScreen( 0, control:GetTall() ) )
        menu:SetMaxHeight( self:GetTall() * 0.5 )
        menu:SetDrawColumn( true )

        menu.VBar:SetWide( 9 )
        menu.VBar:SetHideButtons( true )

        for i = 1, menu:ChildCount() do
            local opt = menu:GetChild( i )
            if opt.SetFont then
                if OnCursorEntered then
                    opt.OnCursorEntered = OnCursorEntered
                end
            end
        end

        if imagePanel then
            local x, y = self:ScreenToLocal( menu:GetPos() )
            local h = 0
            for k, pnl in pairs( menu:GetCanvas():GetChildren() ) do
                h = h + pnl:GetTall()
            end

            imagePanel:SetImage( control:GetValue() )
            imagePanel:SetPos( x - menu:GetWide(), y )
            imagePanel:SetSize( menu:GetWide(), math.min( h, menu:GetMaxHeight() ) )

            imagePanel.Think = function( _ )
                if not IsValid( menu ) then
                    imagePanel:SetVisible( false )
                end
            end
        end
    end

    local oldvalue
    control.OnSelect = function( _, index, value, data )
        self:ValueChanged( vnode, vtable, variables, oldvalue, value )
        oldvalue = value
    end

    control:ChooseOptionID( optionID[self.m_Entity:GetValueNME( vtable.name, vnode.instance )] )

    vnode.SetControl = function( self, value )
        if optionID[value] then control:ChooseOptionID( optionID[value] ) end
    end
end
