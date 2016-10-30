
if not E2Lib then return end

E2Lib.RegisterExtension("ttc", true)

local math = math
local isOwner = E2Lib.isOwner

local function isTTC(self, ent)
    if not IsValid(ent) then return false end
    if ent:GetClass() ~= "gmod_ent_ttc" then return false end
    if not validPhysics(ent) then return false end
    if not isOwner(self, ent) then return false end

    return true
end

local function getTTCData(ent, keyvalue)
    return ent:GetEditingData()[keyvalue]
end

local function setTTCData(ent, func, keyvalue, new)
    if not ent["Set" .. func] then return end
    if not ent["Get" .. func] then return end

    local data = getTTCData(ent, keyvalue)
    if not data then return end

    local set = nil

    if data.type == "Float" or data.type == "Int" then
        set = math.Clamp(new, data.min, data.max)
    elseif data.type == "Boolean" then
        set = tobool(new)
    end

    if set == nil then return end
    if set == ent["Get" .. func](ent) then
        return
    else
        ent["Set" .. func](ent, set)
    end
end


__e2setcost(25)

-- misc
e2function void entity:ttcSetDefaults()
    if not isTTC(self, this) then return end
    if not this.SetDefaults then return end

    this:SetDefaults()
end

e2function array entity:ttcGetLinks()
    if not isTTC(self, this) then return {} end
    return this.LinkedEntities or {}
end


-- apperance
e2function void entity:ttcSetDetail(number detail)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Detail" , "ttc_detail", detail)
end

e2function void entity:ttcSetColor(vector color)
    if not isTTC(self, this) then return end
    if not this.SetTTC_Color then return end

    local r = color[1] and math.min(1, math.abs(color[1]/255))
    local g = color[2] and math.min(1, math.abs(color[2]/255))
    local b = color[3] and math.min(1, math.abs(color[3]/255))

    this:SetTTC_Color(Vector(r or 1, g or 1, b or 1))
end

e2function void entity:ttcSetMaterial(string material)
    if not isTTC(self, this) then return end
    if not this.SetTTC_Material then return end

    this:SetTTC_Material(material)
end

e2function void entity:ttcSetFlipMat(number flipmat)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_FlipMat" , "ttc_flip", flipmat)
end


-- dimensions
e2function void entity:ttcSetWidth(number width)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Width" , "ttc_width", width)
end

e2function void entity:ttcSetHeight(number height)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Height" , "ttc_height", height)
end

e2function void entity:ttcSetRadius(number radius)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Radius" , "ttc_radius", radius)
end

e2function void entity:ttcSetRollerRadius(number radius)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_RollerRadius" , "ttc_rollerradius", radius)
end

e2function void entity:ttcSetOffset(number offset)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Offset" , "ttc_offset", offset)
end


-- physics
e2function void entity:ttcSetSprocket(number sprocket)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Sprocket" , "ttc_sprocket", sprocket)
end

e2function void entity:ttcSetTension(number tension)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Tension" , "ttc_tensor", tension)
end

e2function void entity:ttcSetSlack(number type)
    if not isTTC(self, this) then return end
    setTTCData(this, "TTC_Type" , "ttc_type", type)
end
