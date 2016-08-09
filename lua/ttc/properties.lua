--[[
    Tank Track Controller Addon
    by shadowscion
]]--


properties.Add("ttc_context_edit", {
    MenuLabel = "Configure Track Settings",
    Order = 0,
    PrependSpacer = false,
    MenuIcon = "icon16/text_columns.png",

    Filter = function(self, ent, ply)
        if (!IsValid(ent)) then return false end
        if (!ent.Editable) then return false end
        if (!gamemode.Call("CanProperty", ply, "ttc_context_edit", ent)) then return false end
        if ent:GetClass() ~= "gmod_ent_ttc" then return false end

        return true
    end,

    Action = function(self, ent)
        local context = g_ContextMenu:Add("DFrame")
            context:SetTitle("")
            context:SetSize(320, 360)
            context:SetPos(12, context:GetTall()/2)
            context:SetSizable(false)
            context:SetDraggable(true)
            context:ShowCloseButton(false)

            context.Paint = function(pnl, w, h)
                draw.RoundedBox(1, 0, 0, w, h, Color(60, 60, 60, 255))
                draw.RoundedBox(1, 1, 1, w - 2, h - 2, Color(90, 90, 90, 255))

                draw.SimpleTextOutlined("Track Controller Configuration", "DermaDefaultBold", 5, 5, Color(225, 225, 225), 0, 0, 1, Color(51, 51, 51))

                surface.SetDrawColor(60, 60, 60, 255)
                surface.DrawLine(0, 24, w, 24)
            end

            -- context.Think = function()
            --     g_ContextMenu.Canvas:SetVisible(false)
            --     g_ContextMenu:InvalidateLayout()
            -- end

        local button = vgui.Create("DButton", context)
            button:SetText("")
            button:SetSize(40, 22)
            button:SetPos(context:GetWide() - 41, 1)

            local btn_color = Color(127, 137, 147, 255)
            local txt_color = Color(225, 225, 225)

            button.Paint = function(btn, w, h)
                draw.RoundedBox(1, 1, 1, w - 2, h - 2, Color(60, 60, 60, 255))
                draw.RoundedBox(1, 2, 2, w - 4, h - 4, btn_color)
                draw.SimpleTextOutlined("Close", "DermaDefaultBold", 5, 3, txt_color, 0, 0, 1, Color(51, 51, 51))
            end

            button.DoClick = function(btn)
                context:Remove()
                CloseDermaMenus()
            end

            button.OnCursorEntered = function(btn)
                btn_color = Color(170, 180, 190)
                txt_color = Color(255, 255, 255)
            end

            button.OnCursorExited = function(btn)
                btn_color = Color(127, 137, 147)
                txt_color = Color(225, 225, 225)
            end

        local ttpanel = context:Add("DLabel")
        ttpanel:Dock(BOTTOM)
        ttpanel:SetText("")

        local epanel = context:Add("DEntityProperties")
            epanel:SetEntity(ent)
            epanel:Dock(FILL)
            epanel:DockMargin(0, 0, 0, 0)

            epanel.Categories["Dimensions"].Expand:SetExpanded(true)
            epanel.Categories["Dimensions"].Expand.DoClick = function() end

            epanel.Categories["Appearance"].Expand:SetExpanded(true)
            epanel.Categories["Appearance"].Expand.DoClick = function() end

            epanel.Categories["Physics"].Expand:SetExpanded(true)
            epanel.Categories["Physics"].Expand.DoClick = function() end

            for _, cat in pairs(epanel.Categories) do
                if _ == "Main" then continue end
                for name, panel in pairs(cat.Rows) do
                    local tooltip = "#ttc_tooltip_" .. string.gsub(name, " ", "")
                    panel.OnCursorEntered = function()
                        ttpanel:SetText("" .. tooltip)
                    end
                end
            end

            epanel.OnEntityLost = function()
                context:Remove()
                CloseDermaMenus()
            end
    end
})
