
--[[
    PROPERTY MENU
]]
local tanktracktool = tanktracktool

local property = {}
property.MenuLabel     = "tanktracktool"
property.EditLabel     = "Open Editor"
property.LinkLabel     = "Open Linker"
property.Order         = 998877
property.PrependSpacer = true
property.MenuIcon      = "tanktracktool/vgui/icon16_property.png"
property.EditIcon      = "tanktracktool/vgui/icon16_edit.png"
property.LinkIcon      = "tanktracktool/vgui/icon16_link.png"

function property.Filter( self, ent, ply )
    return tanktracktool.netvar.canEdit( ent, ply )
end

function property.Action( self, ent )
end

function property.MenuOpen( self, option, ent, tr )
    local submenu = option:AddSubMenu()

    self.MenuEdit( self, option, ent, tr, submenu )
    self.MenuLink( self, option, ent, tr, submenu )
end

function property.MenuEdit( self, option, ent, tr, submenu )
    submenu:AddSpacer()
    submenu:AddOption( self.EditLabel, function() tanktracktool.editor.openUI( ent ) end ):SetIcon( self.EditIcon )
end

function property.MenuLink( self, option, ent, tr, submenu )
    if not ent.tanktracktool_linkerData then return end
    submenu:AddSpacer()
    submenu:AddOption( self.LinkLabel, function() tanktracktool.linker.openUI( ent ) end ):SetIcon( self.LinkIcon )
end

properties.Add( "tanktracktool", property )
