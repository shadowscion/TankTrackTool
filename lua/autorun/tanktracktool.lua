
tttlib = tttlib or {}

if SERVER then
    AddCSLuaFile( "tanktracktool/util.lua" )
    AddCSLuaFile( "tanktracktool/tracks_mode.lua" )
    AddCSLuaFile( "tanktracktool/tracks_mesh.lua" )
    AddCSLuaFile( "tanktracktool/effects.lua" )
end

if CLIENT then
    local disable = CreateClientConVar( "tanktracktool_disable", 0, true, false )
    tttlib.RenderDisable = disable:GetBool()

    cvars.AddChangeCallback( "tanktracktool_disable", function( name, old, new )
        tttlib.RenderDisable = tobool( new )
    end )

    include( "tanktracktool/util.lua" )
    include( "tanktracktool/tracks_mode.lua" )
    include( "tanktracktool/tracks_mesh.lua" )
    include( "tanktracktool/effects.lua" )

    tte_controllers = tte_controllers or {}
    local tte_controllers = tte_controllers

    hook.Add( "PostDrawTranslucentRenderables", "tanktracktool_tte_renderer", function()
        if not next( tte_controllers ) then return end

        for k, v in pairs( tte_controllers ) do
            if v and IsValid( k ) then
                k:tte_render()
            end
        end
    end )
end
