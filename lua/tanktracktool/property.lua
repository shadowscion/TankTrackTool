
--[[
    PROPERTY MENU
]]
local tanktracktool = tanktracktool

if CLIENT then
    language.Add( "tanktacktool.property.title", "TankTrackTool" )
    language.Add( "tanktacktool.property.edit", "Open editor" )
    language.Add( "tanktacktool.property.copy", "Copy values" )
    language.Add( "tanktacktool.property.link", "Link entities" )
end

local property = {}
property.MenuLabel     = "#tanktacktool.property.title"
property.EditLabel     = "#tanktacktool.property.edit"
property.CopyLabel     = "#tanktacktool.property.copy"
property.LinkLabel     = "#tanktacktool.property.link"
property.Order         = 998877
property.PrependSpacer = true
property.MenuIcon      = "tanktracktool/vgui/icon16_property.png"
property.EditIcon      = "tanktracktool/vgui/icon16_edit.png"
property.CopyIcon      = "tanktracktool/vgui/icon16_copy.png"
property.LinkIcon      = "tanktracktool/vgui/icon16_link.png"

function property.Filter( self, ent, ply )
    return tanktracktool.netvar.canEdit( ent, ply )
end

function property.Action( self, ent )
end

function property.MenuOpen( self, option, ent, tr )
    local submenu = option:AddSubMenu()
    submenu:SetDrawColumn( true )

    self.MenuEdit( self, option, ent, tr, submenu )
    submenu:AddSpacer()
    self.MenuCopy( self, option, ent, tr, submenu )
    self.MenuLink( self, option, ent, tr, submenu )
end

function property.MenuEdit( self, option, ent, tr, submenu )
    submenu:AddOption( self.EditLabel, function() tanktracktool.editor.openUI( ent ) end ):SetIcon( self.EditIcon )
end

function property.MenuLink( self, option, ent, tr, submenu )
    if not ent.tanktracktool_linkData then return end
    submenu:AddOption( self.LinkLabel, function()
        RunConsoleCommand( "tanktracktool_multitool", "mode", "link", ent:EntIndex() )
    end ):SetIcon( self.LinkIcon )
end

function property.MenuCopy( self, option, ent, tr, submenu )
    if not ent.netvar then return end
    submenu:AddOption( self.CopyLabel, function()
        RunConsoleCommand( "tanktracktool_multitool", "mode", "copy", ent:EntIndex() )
    end ):SetIcon( self.CopyIcon )
end

properties.Add( "tanktracktool", property )
