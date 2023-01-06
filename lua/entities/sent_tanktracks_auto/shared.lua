
DEFINE_BASECLASS( "base_nme" )

ENT.Author = "shadowscion"
ENT.Category = "TankTrackTool"
ENT.Spawnable = true
ENT.AdminOnly = false

local tankTrackVars = NeedMoreEdits.New()

function ENT:SetupNME()
    return tankTrackVars
end

function ENT:DefaultNME( update )
    -- sprocket
    self:SetValueNME( update, "whnSuspension", 1, 0 )
    self:SetValueNME( update, "whnOverride", 1, 1 )
    self:SetValueNME( update, "whnRadius", 1, 10 )
    self:SetValueNME( update, "whnWidth", 1, 20 )
    self:SetValueNME( update, "whnModel", 1, "models/sprops/trans/miscwheels/tank15.mdl" )
    self:SetValueNME( update, "whnBodygroup", 1, "001" )

    -- idler
    self:SetValueNME( update, "whnSuspension", 2, 0 )
    self:SetValueNME( update, "whnOverride", 2, 1 )
    self:SetValueNME( update, "whnRadius", 2, 10 )
    self:SetValueNME( update, "whnWidth", 2, 20 )
    self:SetValueNME( update, "whnModel", 2, "models/sprops/trans/miscwheels/tank15.mdl" )
end


tankTrackVars:Category( "System" )

tankTrackVars:Var( "systemOffsetX", "Float", { min = -1000, max = 1000, def = 0, title = "x offset" } )

tankTrackVars:Var( "systemOffsetY", "Float", { min = -1000, max = 1000, def = 0, title = "y offset" } )

tankTrackVars:Var( "systemOffsetZ", "Float", { min = -1000, max = 1000, def = 0, title = "z offset" } )

tankTrackVars:Var( "systemEffScale", "Float", { min = 0, max = 1, def = 0.5, title = "ground fx scale" } )

tankTrackVars:Var( "systemMirror", "Bool", { def = 1, title = "mirror" } )


tankTrackVars:Category( "Suspension" )

tankTrackVars:Var( "suspensionType", "Combo", { values = { classic = 1, torsion = 2, bogie = 3 }, def = "classic", title = "type" } )

tankTrackVars:Var( "suspensionX", "Float", { min = 0, max = 1000, def = 200, title = "length" } )

tankTrackVars:Var( "suspensionY", "Float", { min = 0, max = 1000, def = 100, title = "width" } )

tankTrackVars:Var( "suspensionZ", "Float", { min = 0, max = 1000, def = 40, title = "height" } )

tankTrackVars:Var( "suspensionInterleave", "Float", { min = -1, max = 1, def = 0, title = "interleave" } )

tankTrackVars:Var( "suspensionPairGap", "Float", { min = -1, max = 1, def = 0, title = "paired spacing" } )


tankTrackVars:SubCategory( "model" )

tankTrackVars:Var( "suspensionColor", "Color", { def = "", title = "color" } )

tankTrackVars:Var( "suspensionMaterial", "String", { def = "", title = "material" } )

tankTrackVars:Var( "suspensionTDamp", "Int", { min = 0, max = 3, def = 0, title = "damper_count" } )

tankTrackVars:Var( "suspensionTDampZ", "Float", { min = 0, max = 1, def = 1, title = "damper_length" } )

tankTrackVars:Var( "suspensionTAngle", "Float", { min = -90, max = 90, def = 45, title = "beam_angle" } )

tankTrackVars:Var( "suspensionTSize", "Float", { min = 0, max = 250, def = 4, title = "beam_thickness" } )

tankTrackVars:Var( "suspensionTBeam", "Float", { min = 0, max = 250, def = 20, title = "beam_length" } )

tankTrackVars:Var( "suspensionTAxle", "Float", { min = 0, max = 250, def = 8, title = "axle_length" } )

tankTrackVars:Var( "suspensionTAxleRad", "Float", { min = 0, max = 1, def = 1, title = "axle_radius" } )

tankTrackVars:Var( "suspensionTConn", "Float", { min = 0, max = 250, def = 9, title = "conn_length" } )

tankTrackVars:Var( "suspensionTConnRad", "Float", { min = 0, max = 1, def = 1, title = "conn_radius" } )


tankTrackVars:Category( "Track" )

tankTrackVars:Var( "trackEnable", "Bool", { def = 1, title = "enabled" } )

tankTrackVars:Var( "trackColor", "Color", { def = "", title = "color" } )

tankTrackVars:Var( "trackMaterial", "Combo", { def = "generic", title = "material" } )

tankTrackVars:Var( "trackRes", "Int", { min = 1, max = 8, def = 2, title = "resolution" } )


tankTrackVars:SubCategory( "shape" )

tankTrackVars:Var( "trackTension", "Float", { min = 0, max = 1, def = 0.5, title = "tension" } )

tankTrackVars:Var( "trackWidth", "Float", { min = 0, max = 250, def = 24, title = "width" } )

tankTrackVars:Var( "trackHeight", "Float", { min = 0, max = 250, def = 3, title = "height" } )

tankTrackVars:Var( "trackGuideY", "Float", { min = -1, max = 1, def = 0, title = "guide offset" } )

tankTrackVars:Var( "trackGrouser", "Float", { min = 0, max = 1, def = 0, title = "grouser length" } )


tankTrackVars:Category( "Wheels" )

tankTrackVars:Var( "wheelColor", "Color", { def = "", title = "color" } )

tankTrackVars:Var( "wheelMaterial", "Field", { max = 5, title = "material" } )

tankTrackVars:Var( "wheelModel", "String", { def = "models/sprops/trans/miscwheels/tank15.mdl", title = "model" } )

tankTrackVars:Var( "wheelBodygroup", "String", { def = "", title = "bodygroup" } )

tankTrackVars:Var( "wheelRadius", "Float", { min = 0, max = 250, def = 15, title = "radius" } )

tankTrackVars:Var( "wheelWidth", "Float", { min = 0, max = 250, def = 10, title = "width" } )

tankTrackVars:Var( "wheelCount", "Int", { container = "wheelTable", min = 2, max = 18, def = 7 } )


tankTrackVars:Category( nil )

tankTrackVars:Obj( "wheelCount", "whnOffsetX", "Float", { min = -1, max = 1, def = 0, title = "x offset" } )

tankTrackVars:Obj( "wheelCount", "whnOffsetY", "Float", { min = -1, max = 1, def = 0, title = "y offset" } )

tankTrackVars:Obj( "wheelCount", "whnOffsetZ", "Float", { min = -1000, max = 1000, def = 0, title = "z offset" } )


tankTrackVars:Obj( "wheelCount", "whnSuspension", "Bool", { def = 1, title = "suspension", highlight = true } )

tankTrackVars:Category( "whnSuspension" )

tankTrackVars:Obj( "wheelCount", "whnTraceZ", "Float", { min = 0, max = 1, def = 0, title = "height" } )

--tankTrackVars:Obj( "wheelCount", "whnTAngle", "Float", { min = -1, max = 1, def = 0, title = "beam_angle" } )


tankTrackVars:Category( nil )

tankTrackVars:Obj( "wheelCount", "whnOverride", "Bool", { def = 0, title = "visual", highlight = true, inheritmenu = true } )

tankTrackVars:Category( "whnOverride" )

tankTrackVars:Obj( "wheelCount", "whnColor", "Color", { def = "", title = "color", inherit = "wheelColor" } )

tankTrackVars:Obj( "wheelCount", "whnMaterial", "Field", { max = 5, title = "material", inherit = "wheelMaterial" } )

tankTrackVars:Obj( "wheelCount", "whnModel", "String", { def = "", title = "model", inherit = "wheelModel" } )

tankTrackVars:Obj( "wheelCount", "whnBodygroup", "String", { def = "", title = "bodygroup", inherit = "wheelBodygroup" } )

tankTrackVars:Obj( "wheelCount", "whnRadius", "Float", { min = 0, max = 250, def = 0, title = "radius", inherit = "wheelRadius" } )

tankTrackVars:Obj( "wheelCount", "whnWidth", "Float", { min = 0, max = 250, def = 0, title = "width", inherit = "wheelWidth" } )



tankTrackVars:Category( "Rollers" )

tankTrackVars:Var( "rollerColor", "Color", { def = "", title = "color" } )

tankTrackVars:Var( "rollerMaterial", "Field", { max = 5, title = "material" } )

tankTrackVars:Var( "rollerModel", "String", { def = "models/sprops/trans/miscwheels/tank15.mdl", title = "model" } )

tankTrackVars:Var( "rollerBodygroup", "String", { def = "", title = "bodygroup" } )

tankTrackVars:Var( "rollerRadius", "Float", { min = 0, max = 250, def = 7.5, title = "radius" } )

tankTrackVars:Var( "rollerWidth", "Float", { min = 0, max = 250, def = 10, title = "width" } )

tankTrackVars:Var( "rollerOffsetZ", "Float", { min = -1000, max = 1000, def = 0, title = "z offset" } )

tankTrackVars:Var( "rollerLocalZ", "Bool", { def = 0, title = "z local" } )

tankTrackVars:Var( "rollerCount", "Int", { container = "rollerTable", min = 0, max = 18, def = 2 } )


tankTrackVars:Category( nil )

tankTrackVars:Obj( "rollerCount", "ronOffsetX", "Float", { min = -1, max = 1, def = 0, title = "x offset" } )

tankTrackVars:Obj( "rollerCount", "ronOffsetY", "Float", { min = -1, max = 1, def = 0, title = "y offset" } )

tankTrackVars:Obj( "rollerCount", "ronOffsetZ", "Float", { min = -1000, max = 1000, def = 0, title = "z offset" } )

tankTrackVars:Obj( "rollerCount", "ronOverride", "Bool", { def = 0, title = "visual", highlight = true } )


tankTrackVars:Category( "ronOverride" )

tankTrackVars:Obj( "rollerCount", "ronColor", "Color", { def = "", title = "color" } )

tankTrackVars:Obj( "rollerCount", "ronMaterial", "Field", { max = 5, title = "material" } )

tankTrackVars:Obj( "rollerCount", "ronModel", "String", { def = "", title = "model" } )

tankTrackVars:Obj( "rollerCount", "ronBodygroup", "String", { def = "", title = "bodygroup" } )

tankTrackVars:Obj( "rollerCount", "ronRadius", "Float", { min = 0, max = 250, def = 0, title = "radius" } )

tankTrackVars:Obj( "rollerCount", "ronWidth", "Float", { min = 0, max = 250, def = 0, title = "width" } )


if CLIENT then -- editor hacks
    local function submatTitle( i )
        if i == 1 then return "base" else return string.format( "sub [%d]", i ) end
    end

    tankTrackVars:GetVar( "wheelMaterial" ).edit.getTitle = submatTitle
    tankTrackVars:GetVar( "rollerMaterial" ).edit.getTitle = submatTitle
    tankTrackVars:GetVar( "whnMaterial" ).edit.getTitle = submatTitle
    tankTrackVars:GetVar( "ronMaterial" ).edit.getTitle = submatTitle


    tankTrackVars:GetVar( "wheelCount" ).edit.getTitle = function( i )
        if i == 1 then return "wheel [first]" elseif i == 2 then return "wheel [last]" else return string.format( "wheel [%d]", i - 1 ) end
    end
    tankTrackVars:GetVar( "rollerCount" ).edit.getTitle = function( i )
        return string.format( "roller [%d]", i )
    end


    local function SetEnabled( self, oldvalue, newvalue )
        self:SetEnabled( newvalue ~= 0 )
    end
    local function SetDisabled( self, oldvalue, newvalue )
        self:SetEnabled( newvalue == 0 )
    end


    local callbacks = { suspensionType = function( self, oldvalue, newvalue ) self:SetEnabled( newvalue ~= "classic" ) end }
    for k, v in pairs( { "suspensionColor", "suspensionMaterial", "suspensionTSize", "suspensionTBeam",
        "suspensionTAxle", "suspensionTConn", "suspensionTAngle", "suspensionTAxleRad", "suspensionTConnRad", "suspensionTDamp", "suspensionTDampZ" } ) do
        tankTrackVars:GetVar( v ).edit.callbacks = callbacks
    end
    tankTrackVars:GetVar( "suspensionInterleave" ).edit.callbacks = { suspensionType = function( self, oldvalue, newvalue ) self:SetEnabled( newvalue ~= "bogie" ) end }


    local callbacks = { trackEnable = SetEnabled }
    for k, v in pairs( { "trackColor", "trackMaterial", "trackRes", "trackWidth", "trackHeight", "trackTension" } ) do
        tankTrackVars:GetVar( v ).edit.callbacks = callbacks
    end


    tankTrackVars:GetVar( "whnTraceZ" ).edit.callbacks = { whnSuspension = SetEnabled }
    tankTrackVars:GetVar( "whnOffsetZ" ).edit.callbacks = { whnSuspension = SetDisabled }

    -- tankTrackVars:GetVar( "whnTAngle" ).edit.callbacks = {
    --  whnSuspension = function( self, oldvalue, newvalue )
    --      self.b1 = newvalue ~= 0
    --      self:SetEnabled( ( self.b1 and self.b2 ) or false )
    --  end,
    --  suspensionType = function( self, oldvalue, newvalue )
    --      self.b2 = newvalue ~= "classic"
    --      self:SetEnabled( ( self.b1 and self.b2 ) or false )
    --  end,
    -- }


    local callbacks = { whnOverride = SetEnabled }
    for k, v in pairs( { "whnColor", "whnMaterial", "whnModel", "whnBodygroup", "whnRadius", "whnWidth" } ) do
        tankTrackVars:GetVar( v ).edit.callbacks = callbacks
    end

    local callbacks = { ronOverride = SetEnabled }
    for k, v in pairs( { "ronColor", "ronMaterial", "ronModel", "ronBodygroup", "ronRadius", "ronWidth" } ) do
        tankTrackVars:GetVar( v ).edit.callbacks = callbacks
    end

    local edit = tankTrackVars:GetVar( "trackMaterial" ).edit
    edit.values = tttlib.textureList()
    edit.images = "tanktracktool/autotracks/gui/%s"


    tankTrackVars:SetHelp( "suspensionInterleave", "percentage of track width" )
    tankTrackVars:SetHelp( "suspensionTDampZ", "percentage of suspension height" )
    tankTrackVars:SetHelp( "suspensionTAxleRad", "percentage of beam thickness" )
    tankTrackVars:SetHelp( "suspensionTConnRad", "percentage of beam thickness" )

end
