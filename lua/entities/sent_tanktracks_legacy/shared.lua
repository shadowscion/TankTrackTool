
DEFINE_BASECLASS( "base_tanktracktool" )

ENT.Type      = "anim"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category  = "tanktracktool"

local tanktracktool = tanktracktool

tanktracktool.netvar.addLinks( ENT, "Chassis" )
tanktracktool.netvar.addLinks( ENT, "Wheel", "Roller" )

local netvar = tanktracktool.netvar.new()

function ENT:netvar_setup()
    return netvar
end

netvar:category( "System" )
netvar:var( "systemRotate", "Bool", { def = 0, title = "swap chassis axis", help = "rotates the tool arrows by 90 degrees" } )

netvar:category( "Tracks" )
netvar:var( "trackColor", "Color", { def = "", title = "color" } )
netvar:var( "trackMaterial", "Combo", { def = "generic", title = "material" } )
netvar:var( "trackRes", "Int", { min = 1, max = 8, def = 2, title = "resolution" } )
netvar:var( "trackOffsetY", "Float", { min = -250, max = 250, def = 0, title = "y offset" } )
netvar:var( "trackFlip", "Bool", { def = 0, title = "flip mesh", help = "affects y offset, guide offset, and grouser" } )

netvar:subcategory( "Shape" )
netvar:var( "trackTension", "Float", { min = 0, max = 1, def = 0.5, title = "tension" } )
netvar:var( "trackWidth", "Float", { min = 0, max = 250, def = 24, title = "width" } )
netvar:var( "trackHeight", "Float", { min = 0, max = 250, def = 3, title = "height" } )
netvar:var( "trackGuideY", "Float", { min = -1, max = 1, def = 0, title = "guide offset" } )
netvar:var( "trackGrouser", "Float", { min = 0, max = 1, def = 0, title = "grouser length" } )

netvar:category( "Wheels" )
netvar:var( "wheelSprocket", "Int", { min = 1, max = 250, def = 1,  title = "sprocket id", help = "controls which wheel scrolls the tracks" } )
netvar:var( "wheelRadius", "Float", { min = -250, max = 250, def = 0, title = "offset wheel radius" } )
netvar:var( "rollerRadius", "Float", { min = -250, max = 250, def = 0, title = "offset roller radius" } )

if CLIENT then
    netvar:get( "trackMaterial" ).data.values = tanktracktool.autotracks.textureList()
    netvar:get( "trackMaterial" ).data.images = "tanktracktool/autotracks/gui/%s"
end

--[[
    sort wheels based on forward position
    separated by a table of wheels and a table of roller wheels
]]
local function GetSortedWheels( chassis, wheels, rollers, rotate )
    local matrix = chassis:GetWorldTransformMatrix()
    if rotate then matrix:Rotate( rotate ) end
    local pos = matrix:GetTranslation() + matrix:GetForward() * 12345
    local tbl = {}

    for k, ent in pairs( wheels ) do
        if isentity( ent ) and IsValid( ent ) then
            table.insert( tbl, ent )
            ent.rollerTemp = nil
            ent.sortPosTemp = ent:GetPos():Distance( pos )
            if #tbl > 32 then break end
        end
    end

    for k, ent in pairs( rollers ) do
        if isentity( ent ) and IsValid( ent ) then
            table.insert( tbl, ent )
            ent.rollerTemp = true
            ent.sortPosTemp = ent:GetPos():Distance( pos )
            if #tbl > 32 then break end
        end
    end

    table.sort( tbl, function( e1, e2 )
        local this = e1.rollerTemp
        local that = e2.rollerTemp

        if this ~= that then return that and not this end
        if this then return e1.sortPosTemp > e2.sortPosTemp else return e1.sortPosTemp < e2.sortPosTemp end
    end )

    for k, ent in pairs( tbl ) do
        ent.rollerTemp = nil
        ent.sortPosTemp = nil
    end

    table.insert( tbl, 1, chassis )

    return tbl
end

--[[
    check if all ents are to one side of the chassis
    optional filter function
]]
local function Filter( ent )
    if not isentity( ent ) or not IsValid( ent ) or ent:IsPlayer() or ent:IsVehicle() or ent:IsNPC() or ent:IsWorld() then return true end
end

local function CheckParallelism( chassis, tbl, rotate, filter )
    local matrix = chassis:GetWorldTransformMatrix()
    if rotate then matrix:Rotate( rotate ) end
    local pos = matrix:GetTranslation()
    local dir = matrix:GetRight()
    local dot

    for k, ent in pairs( tbl ) do
        if filter and filter( ent ) then return "invalid wheel or chassis entity " .. tostring( ent ) end

        if ent ~= chassis then
            local d = dir:Dot( ( ent:GetPos() - pos ):GetNormalized() ) > 0
            if dot == nil then dot = d end
            if dot ~= d then
                return "wheels must all be on the same side of the chassis"
            end
        end
    end

    return false
end

--[[
    sort wheels before sending the table to netvar linking function
    prop protection is checked there
]]
function ENT:netvar_setLinks( tbl, ply )
    if not istable( tbl ) then return end

    local rotate = tobool( self.netvar.values.systemRotate ) and Angle( 0, -90, 0 )

    if istable( tbl.Wheel ) and istable( tbl.Roller ) and isentity( tbl.Chassis ) then
        tbl = GetSortedWheels( tbl.Chassis, tbl.Wheel, tbl.Roller, rotate )
    end

    if istable( tbl ) and table.IsSequential( tbl ) then
        local isp = CheckParallelism( tbl[1], tbl, rotate, Filter )
        if isp then
            if IsValid( ply ) then ply:ChatPrint( isp ) end
            return
        end

        return tanktracktool.netvar.setLinks( self, tbl, ply )
    end
end
