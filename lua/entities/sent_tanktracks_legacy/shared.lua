
DEFINE_BASECLASS( "base_nme" )

ENT.Author = "shadowscion"
ENT.Category = "TankTrackTool"
ENT.Spawnable = true
ENT.AdminOnly = false


local tankTrackVars = NeedMoreEdits.New()

function ENT:SetupNME()
    return tankTrackVars
end


tankTrackVars:Category( "System" )

tankTrackVars:Var( "systemRotate", "Bool", { def = 0, title = "swap chassis axis", help = "rotates the tool arrows by 90 degrees" } )


tankTrackVars:Category( "Track" )

tankTrackVars:Var( "trackColor", "Color", { def = "", title = "color" } )

tankTrackVars:Var( "trackMaterial", "Combo", { def = "generic", title = "material" } )

tankTrackVars:Var( "trackRes", "Int", { min = 1, max = 8, def = 2, title = "resolution" } )

tankTrackVars:Var( "trackOffsetY", "Float", { min = -250, max = 250, def = 0, title = "y offset" } )

tankTrackVars:Var( "trackFlip", "Bool", { def = 0, title = "flip mesh", help = "affects y offset, guide offset, and grouser" } )


tankTrackVars:SubCategory( "shape" )

tankTrackVars:Var( "trackTension", "Float", { min = 0, max = 1, def = 0.5, title = "tension" } )

tankTrackVars:Var( "trackWidth", "Float", { min = 0, max = 250, def = 24, title = "width" } )

tankTrackVars:Var( "trackHeight", "Float", { min = 0, max = 250, def = 3, title = "height" } )

tankTrackVars:Var( "trackGuideY", "Float", { min = -1, max = 1, def = 0, title = "guide offset" } )

tankTrackVars:Var( "trackGrouser", "Float", { min = 0, max = 1, def = 0, title = "grouser length" } )


tankTrackVars:Category( "Wheels" )

tankTrackVars:Var( "wheelSprocket", "Int", { min = 1, max = 250, def = 1,  title = "sprocket id", help = "controls which wheel scrolls the tracks" } )

tankTrackVars:Var( "wheelRadius", "Float", { min = -250, max = 250, def = 0, title = "offset wheel radius" } )

tankTrackVars:Var( "rollerRadius", "Float", { min = -250, max = 250, def = 0, title = "offset roller radius" } )


if CLIENT then
    local edit = tankTrackVars:GetVar( "trackMaterial" ).edit
    edit.values = tttlib.textureList()
    edit.images = "tanktracktool/autotracks/gui/%s"
end
