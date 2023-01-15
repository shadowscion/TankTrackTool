
local PANEL = {}

local function ColorToString( col )
    return math.floor( col.r ) .. " " .. math.floor( col.g ) .. " " .. math.floor( col.b ) .. " " .. math.floor( col.a )
end

local grid = Material( "gui/alpha_grid.png", "nocull" )
local gradient = Material( "vgui/gradient-l" )

local function Paint( self, w, h )
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

function PANEL:Setup( editData )
    self:Clear()

    local editor = self:Add( "DColorButton" )
    editor:Dock( FILL )
    editor:DockMargin( 0, 0, 0, 0 )
    editor:SetText( "" )
    editor:SetTooltip( nil )

    local inner = Color( 255, 255, 255, 255 )
    local mixer

    editor.Paint = Paint
    editor.DoClick = function()
        if IsValid( self.m_Editor.ColorMixer ) then
            self.m_Editor.ColorMixer:Remove()
        end

        local color = vgui.Create( "DColorCombo", self.m_Editor )

        color.Mixer:SetAlphaBar( true )
        color.Mixer:SetPalette( false )
        color.Mixer:SetWangs( true )

        color:SetupCloseButton( function() color:Remove() end )
        color.OnValueChanged = function( color, newcol )
            inner = newcol
            editor:SetColor( newcol )
            self:ValueChanged( ColorToString( newcol ), true )
        end

        local x, y = self.m_Editor:GetChildPosition( self:GetRow() )
        color:SetPos( x - color:GetWide() + self:GetRow():GetWide(), y + self:GetRow().Label:GetTall() )

        local col = inner
        color:SetColor( col )

        self.m_Editor.ColorMixer = color
        mixer = color
    end

    editor.DoRightClick = function()
        local menu = DermaMenu()
        menu:AddOption( "copy " .. self:GetRow():GetText(), function()
            self.m_Editor.ColorCopied = editor:GetColor()
        end ):SetImage( "icon16/page_copy.png" )

        if IsColor( self.m_Editor.ColorCopied ) then
            menu:AddOption( "paste color", function()
                inner = self.m_Editor.ColorCopied
                editor:SetColor( self.m_Editor.ColorCopied )
                self:ValueChanged( ColorToString( self.m_Editor.ColorCopied ), true )
            end ):SetImage( "icon16/page_paste.png" )
        end

        menu:AddOption( "cancel", function() end ):SetImage( "icon16/cancel.png" )

        local x, y = editor:LocalToScreen( 0, self:GetRow().Label:GetTall() )
        menu:Open( x, y )
    end

    self.IsEnabled = function( _ )
        return editor:IsEnabled()
    end

    self.SetEnabled = function( _, b )
        editor:SetEnabled( b )
    end

    self.IsEditing = function( _ )
        return IsValid( mixer )
    end

    self.SetValue = function( _, val )
        inner = string.ToColor( val )
        editor:SetColor( inner )
        self:Callback( editData, inner )
    end
end

derma.DefineControl( "tanktracktoolEditor_Color", "", PANEL, "tanktracktoolEditor_Generic" )

