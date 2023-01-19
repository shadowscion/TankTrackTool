
--[[
    NETVAR LIB
]]
local tanktracktool = tanktracktool
local net, hook, util, math, string, table, scripted_ents, Entity, IsValid, istable, isfunction =
      net, hook, util, math, string, table, scripted_ents, Entity, IsValid, istable, isfunction

tanktracktool.netvar = tanktracktool.netvar or {}
local netvar = tanktracktool.netvar


--[[
    networking
]]
local netmsg_netvars_edit = "tanktracktool_edit"
local netmsg_netvars_data = "tanktracktool_sync"
local netmsg_netvars_link = "tanktracktool_link"

if SERVER then

    util.AddNetworkString( netmsg_netvars_edit )
    util.AddNetworkString( netmsg_netvars_data )
    util.AddNetworkString( netmsg_netvars_link )


    --[[
        client sends a table of edits to server
        server checks and sets the edits
        server sends the changes to all clients
    ]]
    net.Receive( netmsg_netvars_edit, function( len, ply )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.canEdit( ent, ply ) or not isfunction( ent.netvar_set ) then return end

        local tbl = net.ReadTable()
        ent:netvar_set( tbl[1], tbl[2], tbl[3], true )

        if tanktracktool.loud( tanktracktool.loud_edit ) then
            tanktracktool.note( string.format( "receiving edit request\nply: %s\nent: %s\n", tostring( ply ), tostring( ent ) ) )
        end
    end )


    --[[
        client needs a full data sync
        server adds client name to list
        server sends data to clients
    ]]
    net.Receive( netmsg_netvars_data, function( len, ply )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.isValid( ent ) then return end

        if not IsValid( ply ) or ent.netvar_syncData == true then return end
        if not ent.netvar_syncData then
            ent.netvar_syncData = {}
        end

        ent.netvar_syncData[ply] = true

        if tanktracktool.loud( tanktracktool.loud_data ) then
            tanktracktool.note( string.format( "receiving data request\nply: %s\nent: %s\n", tostring( ply ), tostring( ent ) ) )
        end
    end )


    --[[
        0
            client needs a link sync
            server adds client name to list
            server sends links to clients

        1
            client wants to edit links
            server checks and sends new links to clients

        2
            client wants to remove all links
            server checks and sends new links to clients

        3
            client wants to copy values from controller A to controller B
            server sends the changes to all clients
            ( this should be in the edit netfunc but oh well )
    ]]
    net.Receive( netmsg_netvars_link, function( len, ply )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.isValid( ent ) then return end

        local type = net.ReadUInt( 2 )

        if type == 0 then
            if not IsValid( ply ) or ent.netvar_syncLink == true then return end
            if not ent.netvar_syncLink then
                ent.netvar_syncLink = {}
            end

            ent.netvar_syncLink[ply] = true

            if tanktracktool.loud( tanktracktool.loud_link ) then
                tanktracktool.note( string.format( "receiving link request\nply: %s\nent: %s\n", tostring( ply ), tostring( ent ) ) )
            end

        elseif type == 1 then
            if not netvar.canEdit( ent, ply ) or not isfunction( ent.netvar_setLinks ) then return end

            ent:netvar_setLinks( net.ReadTable(), ply )

            if tanktracktool.loud( tanktracktool.loud_link ) then
                tanktracktool.note( string.format( "receiving link update\nply: %s\nent: %s\n", tostring( ply ), tostring( ent ) ) )
            end

        elseif type == 2 then
            if not netvar.canEdit( ent, ply ) or not isfunction( ent.netvar_setLinks ) then return end

            ent:netvar_setLinks( nil, ply )

            if tanktracktool.loud( tanktracktool.loud_link ) then
                tanktracktool.note( string.format( "removing links\nply: %s\nent: %s\n", tostring( ply ), tostring( ent ) ) )
            end

        elseif type == 3 then
            netvar.copy( ent, Entity( net.ReadUInt( 16 ) ), ply )
        end
    end )


    --[[
        servercompressees and sends all data to players
    ]]
    function netvar.transmitData( ent, sendTo )
        if not netvar.isValid( ent ) then return end

        local data = util.Compress( util.TableToJSON( ent.netvar.values ) )
        local size = string.len( data )

        net.Start( netmsg_netvars_data )
        net.WriteUInt( ent:EntIndex(), 16 )
        net.WriteUInt( size, 32 )
        net.WriteData( data, size )

        if sendTo == true then net.Broadcast() else net.Send( table.GetKeys( sendTo ) ) end
    end


    --[[
        server sends table of link entIndexes to players
    ]]
    function netvar.transmitLink( ent, sendTo )
        if not netvar.isValid( ent ) then return end

        net.Start( netmsg_netvars_link )
        net.WriteUInt( ent:EntIndex(), 16 )

        local valid = {}
        for k, v in pairs( ent.netvar.entities ) do
            if IsValid( v ) then valid[k] = v:EntIndex() end
        end
        net.WriteTable( valid )

        if sendTo == true then net.Broadcast() else net.Send( table.GetKeys( sendTo ) ) end
    end

else

    --[[
        client recieves a variable edit
    ]]
    net.Receive( netmsg_netvars_edit, function( len )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.isValid( ent ) or not isfunction( ent.netvar_set ) then return end

        local tbl = net.ReadTable()
        ent:netvar_set( tbl[1], tbl[2], tbl[3] )

        if tanktracktool.loud( tanktracktool.loud_edit ) then
            tanktracktool.note( string.format( "receiving edit\nent: %s\n", tostring( ent ) ) )
        end
    end )


    --[[
        client recieves a data sync
    ]]
    net.Receive( netmsg_netvars_data, function( len )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.isValid( ent ) then return end

        local size = net.ReadUInt( 32 )
        local data = net.ReadData( size )

        ent.netvar.values = util.JSONToTable( util.Decompress( data ) )
        ent:netvar_callback( "netvar_syncData", ent.netvar.values )

        if tanktracktool.loud( tanktracktool.loud_data ) then
            tanktracktool.note( string.format( "receiving data\nent: %s\n", tostring( ent ) ) )
        end
    end )


    --[[
        client recieves a link sync
    ]]
    net.Receive( netmsg_netvars_link, function( len )
        local ent = Entity( net.ReadUInt( 16 ) )
        if not netvar.isValid( ent ) then return end

        local t = net.ReadTable()

        ent.netvar.entities = nil
        ent.netvar.entindex = t
        ent:netvar_callback( "netvar_syncLink", ent.netvar.entindex )

        if tanktracktool.loud( tanktracktool.loud_link ) then
            tanktracktool.note( string.format( "receiving link\nent: %s\n", tostring( ent ) ) )
        end
    end )


    --[[
        these hooks ensure a sync check on game join
        handled in ENT:netvar_transmit()
    ]]
    hook.Add( "NotifyShouldTransmit", "tanktracktool_resync", function( ent, bool )
        if bool then
            ent.netvar_syncData = nil
            ent.netvar_syncLink = nil
        end
    end )

    hook.Add( "OnGamemodeLoaded", "tanktracktool_resync", function()
        for k, ent in ipairs( ents.GetAll() ) do
            ent.netvar_syncData = nil
            ent.netvar_syncLink = nil
        end
    end )


    --[[
        client sends an edit request to server
    ]]
    function netvar.transmitEdit( ent, name, index, val )
        if not netvar.isValid( ent ) then return end

        net.Start( netmsg_netvars_edit )
        net.WriteUInt( ent:EntIndex(), 16 )
        net.WriteTable( { name, index, val } )
        net.SendToServer()

        if tanktracktool.loud( tanktracktool.loud_edit ) then
            tanktracktool.note( string.format( "sending edit request\nent: %s\nvar: %s\nidx: %s\nval: %s\n", tostring( ent ), tostring( name ), tostring( index ), tostring( newval ) ) )
        end
    end


    --[[
        client sends an data request to server
    ]]
    function netvar.transmitData( ent )
        if not netvar.isValid( ent ) then return end

        net.Start( netmsg_netvars_data )
        net.WriteUInt( ent:EntIndex(), 16 )
        net.SendToServer()

        if tanktracktool.loud( tanktracktool.loud_data ) then
            tanktracktool.note( string.format( "sending data request\nent: %s\n", tostring( ent ) ) )
        end
    end


    --[[
        client sends an link request to server
    ]]
    function netvar.transmitLink( ent, tbl )
        if not netvar.isValid( ent ) then return end

        net.Start( netmsg_netvars_link )
        net.WriteUInt( ent:EntIndex(), 16 )
        net.WriteUInt( tbl and 1 or 0, 2 )
        if tbl then net.WriteTable( tbl ) end
        net.SendToServer()

        if tanktracktool.loud( tanktracktool.loud_link ) then
            tanktracktool.note( string.format( "sending link request\nent: %s\n", tostring( ent ) ) )
        end
    end

end


--[[
    base_tanktracktool validators and permissions
]]
function netvar.isValid( ent )
    if not IsValid( ent ) then return false end
    if not scripted_ents.IsBasedOn( ent:GetClass(), "base_tanktracktool" ) then
        if ent:GetClass() ~= "base_tanktracktool" then return false end
    end
    return true
end

function netvar.canEdit( ent, ply )
    if not netvar.isValid( ent ) then return false end
    return hook.Run( "CanProperty", ply, "tanktracktool", ent )
end

function netvar.canLink( ent, ply )
    return hook.Run( "CanProperty", ply, "tanktracktool", ent )
end


--[[
    safe variable setters
]]
netvar.sanitizer = {}

function netvar.sanitizer.bool( value, data )
    return tobool( value ) and 1 or 0
end

function netvar.sanitizer.instance( value, data )
    value = math.floor( math.abs( ( tonumber( value or 0 ) or 0 ) + 0.5 ) )
    if value > data.max then value = data.max elseif value < data.min then value = data.min end
    return value
end

function netvar.sanitizer.int( value, data )
    value = math.floor( math.abs( ( tonumber( value or 0 ) or 0 ) + 0.5 ) )
    if ( data.max and value > data.max ) then value = data.max elseif ( data.min and value < data.min ) then value = data.min end
    return value
end

function netvar.sanitizer.float( value, data )
    value = tonumber( value or 0 ) or 0
    if ( data.max and value > data.max ) then value = data.max elseif ( data.min and value < data.min ) then value = data.min end
    return value
end

function netvar.sanitizer.string( value, data )
    if data.numeric then value = tostring( tonumber( value or 0 ) or 0 ) else value = tostring( value or "" ) or "" end
    if string.len( value ) < 255 then return value else return string.sub( value, 1, 255 ) end
end

function netvar.sanitizer.color( value, data )
    local col = string.ToColor( netvar.sanitizer.string( value, data ) )
    return string.format( "%d %d %d %d", col.r, col.g, col.b, col.a )
end

function netvar.sanitizer.combo( value, data )
    value = netvar.sanitizer.string( value, data )
    if istable( data.values ) then
        return data.values[value] and value or data.def or ""
    end
    return value or data.def or ""
end

function netvar.sanitizer.array( value, data )
    if not istable( value ) then value = {} end

    local t = {}

    for i = 1, data.count do
        t[i] = netvar.sanitizer.string( value[i], data ) or ""
    end

    return t
end

function netvar.sanitizer.vector( value, data, angle )
    value = angle and Angle( value ) or Vector( value )

    if data.max then
        if value.x > data.max.x then value.x = data.max.x end
        if value.y > data.max.y then value.y = data.max.y end
        if value.z > data.max.z then value.z = data.max.z end
    end
    if data.min then
        if value.x < data.min.x then value.x = data.min.x end
        if value.y < data.min.y then value.y = data.min.y end
        if value.z < data.min.z then value.z = data.min.z end
    end

    if data.normalize then value:Normalize() end

    return value
end

function netvar.sanitizer.angle( value, data )
    return netvar.sanitizer.vector( value, data, true )
end


--[[
    variable metamethods
]]
function netvar.new()
    local meta = { data = { s = {}, n = {} } }

    function meta:category( name )
        self.data.category = name
        self.data.subcategory = nil
    end

    function meta:subcategory( name )
        self.data.subcategory = name
    end

    function meta:get( name )
        return self.data.n[self.data.s[name]]
    end

    function meta:getparent( name )
        return self:get( name ).parent
    end

    function meta:exists( name )
        return self:get( name ) ~= nil
    end

    function meta:type( name )
        return self:get( name ).type
    end

    function meta:var( name, type, data )
        type = string.lower( type )
        data = data or {}
        data.id = name
        data.type = type

        if CLIENT then
            data.category = self.data.category
            data.subcategory = self.data.subcategory
        else
            data.inherit = nil
            data.title = nil
            data.label = nil
        end

        assert( not self:exists( name ), "pre-existing variable name" )
        assert( netvar.sanitizer[type] ~= nil, "non-existing variable type" )

        local t = table.insert( self.data.n, { name = name, type = type, data = data or {} } )
        self.data.s[name] = t
        return self.data.n[t]
    end

    function meta:subvar( name, parent, type, data )
        type = string.lower( type )
        data = data or {}
        data.id = name
        data.type = type

        if CLIENT then
            data.category = self.data.category
            data.subcategory = self.data.subcategory
        else
            data.inherit = nil
            data.title = nil
            data.label = nil
        end

        assert( not self:exists( name ), "pre-existing variable name" )
        assert( netvar.sanitizer[type] ~= nil, "non-existing variable type" )
        assert( type ~= "instance", "subvars cannot be Instance type" )
        assert( self:exists( parent ), "non-existing parent variable" )
        assert( self:type( parent ) == "instance", "subvar parents must be Instance type" )

        local t = table.insert( self.data.n, { name = name, parent = self:get( parent ), type = type, data = data or {} } )
        self.data.s[name] = t
        return self.data.n[t]
    end

    return meta
end

function netvar.install( ent, install, default, restore )
    if not netvar.isValid( ent ) or not istable( install ) then return end
    if not istable( restore ) then restore = nil end
    if not istable( default ) then default = nil end

    ent.netvar = { entindex = {}, values = {}, variables = install }

    for k, var in ipairs( ent.netvar.variables.data.n ) do
        local def = var.data.def

        if not var.parent then
            local val = def
            if not restore and ( default and default[var.name] ~= nil ) then
                val = default[var.name]
            end
            if restore then val = restore[var.name] end
            ent.netvar.values[var.name] = netvar.sanitizer[var.type]( val, var.data )
        else
            ent.netvar.values[var.name] = {}
            local parent = ent.netvar.variables:getparent( var.name )
            for index = 1, parent.data.max do
                local val = def
                if not restore and ( default and istable( default[var.name] ) and default[var.name][index] ~= nil ) then
                    val = default[var.name][index]
                end
                if restore and istable( restore[var.name] ) then val = restore[var.name][index] end
                ent.netvar.values[var.name][index] = netvar.sanitizer[var.type]( val, var.data )
            end
        end
    end

    if SERVER then
        ent.netvar.entities = {}
        ent.netvar_syncData = true
    end
end

function netvar.setVar( ent, name, index, newval, forceUpdate )
    if not netvar.isValid( ent ) then return end

    local var = ent.netvar.variables:get( name )
    if not var then return end

    local newval = netvar.sanitizer[var.type]( newval, var.data )
    local oldval

    if index then
        if istable( ent.netvar.values[name] ) and ent.netvar.values[name][index] ~= nil then
            oldval = ent.netvar.values[name][index]
            ent.netvar.values[name][index] = newval
        else
            return false
        end
    else
        oldval = ent.netvar.values[name]
        ent.netvar.values[name] = newval
    end

    local diff = oldval ~= newval

    if SERVER and forceUpdate then
        net.Start( netmsg_netvars_edit )
        net.WriteUInt( ent:EntIndex(), 16 )
        net.WriteTable( { name, index, newval } )
        net.Broadcast()
    end

    ent:netvar_callback( "netvar_set", name, index, newval, diff )

    return name, index, newval, diff
end

function netvar.getVar( ent, name, index )
    if not netvar.isValid( ent ) then return end

    local var = ent.netvar.variables:get( name )
    if not var then return end

    if index then
        if istable( ent.netvar.values[name] ) and ent.netvar.values[name][index] ~= nil then
            return ent.netvar.values[name][index]
        end
        return
    end

    return ent.netvar.values[name]
end

if SERVER then
    function netvar.copy( ent1, ent2, ply )
        local check = IsValid( ply ) and netvar.canEdit or netvar.isValid
        if not check( ent1, ply ) or not check( ent2, ply ) then return end

        local vars = ent1.netvar.variables
        local vals = ent1.netvar.values
        local ents = ent1.netvar.entities
        local eidx  = ent1.netvar.entindex

        netvar.install( ent1, vars, vals, ent2.netvar.values )
        ent1.netvar.entities = ents
        ent1.netvar.entindex = eidx
    end

    function netvar.setLinks( ent, tbl, ply )
        if not netvar.isValid( ent ) then return false end
        if not istable( tbl ) then return false end

        local entities = {}
        local entindex = {}

        for k, v in pairs( tbl ) do
            if not isentity( v ) or not IsValid( v ) then return false end
            if ply and not netvar.canLink( v, ply ) then return false end
            entities[k] = v
            entindex[k] = v:EntIndex()
        end

        ent.netvar.entities = entities
        ent.netvar.entindex = entindex

        if SERVER then ent.netvar_syncLink = true end

        return entities
    end


    --[[
        duplicator support
    ]]
    function netvar.getDupe( ent )
        if not netvar.isValid( ent ) then return end

        local links = {}

        for k, v in pairs( ent.netvar.entities ) do
            if not IsValid( v ) then
                links = {}
                break
            end
            links[k] = v:EntIndex()
        end

        return { data = ent.netvar.values, links = links }
    end

    function netvar.applyDupe( ply, ent, entmods, enttbl )
        if not netvar.isValid( ent ) then return end

        local restore, linked

        if entmods.nmeDupeInfo then
            if entmods.nmeDupeInfo.data and isfunction( ent.netvar_nme ) then
                restore = ent:netvar_nme( util.JSONToTable( util.Decompress( entmods.nmeDupeInfo.data ) ) )
            end

            duplicator.ClearEntityModifier( ent, "nmeDupeInfo" )
        end

        if istable( entmods.tanktracktool ) then
            if istable( entmods.tanktracktool.data ) then
                restore = entmods.tanktracktool.data
            end
            if istable( entmods.tanktracktool.links ) then
                linked = {}
                for k, v in pairs( entmods.tanktracktool.links ) do
                    local e = enttbl( v, ent )
                    linked[k] = e
                end
            end
        else
            if istable( entmods.ttc_dupe_info ) and istable( entmods.ttc_dupe_info.link_ents ) then -- this is ancient stuff but you never know
                linked = {}
                for k, v in pairs( entmods.ttc_dupe_info.link_ents ) do
                    local e = enttbl( v, ent )
                    linked[k] = e
                end

                duplicator.ClearEntityModifier( ent, "ttc_dupe_info" )
            end
        end

        if restore and isfunction( ent.netvar_install ) then
            ent:netvar_install( restore )
        end

        if linked and isfunction( ent.netvar_setLinks ) then
            ent:netvar_setLinks( linked )
        end
    end
else
    function netvar.addToolLink( e, n1, f1, h1 )
        if not isstring( n1 ) then return end
        if not e.tanktracktool_linkData then e.tanktracktool_linkData = {} end

        table.insert( e.tanktracktool_linkData, {
            name = n1,
            --tool_bind = "rmb",
            tool_filter = isfunction( f1 ) and f1 or nil,
            tool_hud = isfunction( h1 ) and h1 or nil,
        } )
    end

    function netvar.addToolLinks( e, n1, f1, h1, n2, f2, h2 )
        if not isstring( n1 ) then return end
        if not isstring( n2 ) then return end
        if not e.tanktracktool_linkData then e.tanktracktool_linkData = {} end

        table.insert( e.tanktracktool_linkData, {
            istable = true,
            {
                name = n1,
                tool_filter = isfunction( f1 ) and f1 or nil,
                tool_hud = isfunction( h1 ) and h1 or nil,
            },
            {
                name = n2,
                tool_filter = isfunction( f2 ) and f2 or nil,
                tool_hud = isfunction( h2 ) and h2 or nil,
            },
        } )
    end
end
