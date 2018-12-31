--[[
    Tank Track Controller Addon
    by shadowscion
]]--

local TTC = TTC

DEFINE_BASECLASS("DProperty_Generic")

local MaterialProperty = {}

function MaterialProperty:Init()
end

function MaterialProperty:ValueChanged(newval, bForce)
    if not TTC.Textures[newval] then return end

    BaseClass.ValueChanged(self, newval, bForce)
    self.StringValue = tostring(newval)
    self.Material = Material("tanktrack_controller_new/" .. newval)
end

function MaterialProperty:Setup(vars)
    vars = vars or {}

    BaseClass.Setup(self, vars)

    local __SetValue = self.SetValue

    local btn = self:Add("DButton")
    btn:Dock(LEFT)
    btn:DockMargin(0, 2, 4, 2)
    btn:SetWide(20 - 4)
    btn:SetText("")

    btn.Paint = function(btn, w, h)
        if self.Material then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(self.Material)
            surface.DrawTexturedRect(2, 2, w - 4, h - 4)
        end

        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    btn.DoClick = function()
        if not TTC or not TTC.Textures then return end

        local mat_menu = vgui.Create("DFrame", self)

        mat_menu:SetTitle("")
        mat_menu:SetSize(256, 162)
        mat_menu:Center()
        mat_menu:ShowCloseButton(false)

        mat_menu.Paint = function(pnl, w, h)
            draw.RoundedBox(1, 0, 0, w, h, Color(60, 60, 60, 255))
            draw.RoundedBox(1, 1, 1, w - 2, h - 2, Color(120, 120, 120, 255))

            draw.SimpleTextOutlined("Select A Material", "DermaDefaultBold", 5, 5, Color(225, 225, 225), 0, 0, 1, Color(51, 51, 51))

            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawLine(0, 24, w, 24)
        end

        local menu = DermaMenu()
        menu:AddPanel(mat_menu)
        menu:SetPaintBackground(false)
        menu:Open(gui.MouseX() + 8, gui.MouseY() + 10)

        local button = vgui.Create("DButton", mat_menu)
            button:SetText("")
            button:SetSize(40, 22)
            button:SetPos(mat_menu:GetWide() - 41, 1)

            local btn_color = Color(127, 137, 147, 255)
            local txt_color = Color(225, 225, 225)

            button.Paint = function(btn, w, h)
                draw.RoundedBox(1, 1, 1, w - 2, h - 2, Color(60, 60, 60, 255))
                draw.RoundedBox(1, 2, 2, w - 4, h - 4, btn_color)
                draw.SimpleTextOutlined("Close", "DermaDefaultBold", 5, 3, txt_color, 0, 0, 1, Color(51, 51, 51))
            end

            button.DoClick = function(btn)
                mat_menu:Remove()
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

        local mat_select = vgui.Create("MatSelect")
            mat_select:SetPos(0, 24)
            mat_select:SetWidth(mat_menu:GetWide() - 4)
            mat_select:SetItemWidth(32)
            mat_select:SetItemHeight(64)

        for name, v in pairs(TTC.Textures) do
            if v.legacy then continue end

            local mat = vgui.Create("DImageButton", mat_select)
                mat:SetOnViewMaterial("tanktrack_controller_new/" .. name, "models/wireframe")
                mat.AutoSize = false
                mat.Value = name
                mat:SetSize(mat_select.ItemWidth, mat_select.ItemHeight)
                mat:SetTooltip(name)

            mat.DoClick = function(button)
                self:ValueChanged(mat.Value, true)
                mat_select:FindAndSelectMaterial(mat.Value)
            end

            mat_select.List:AddItem(mat)
            table.insert(mat_select.Controls, mat)

            mat_select:InvalidateLayout()
        end

        mat_menu:Add(mat_select)
    end

    self.SetValue = function(self, val)
        __SetValue(self, val)
        self.StringValue = val
        self.Material = Material("tanktrack_controller_new/" .. val)
    end
end

derma.DefineControl("DProperty_ttc_material", "", MaterialProperty, "DProperty_Generic")
