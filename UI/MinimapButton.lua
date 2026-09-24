local addonName, Buffadin = ...

Buffadin.MinimapButton = CreateFrame("Button", "BuffadinMinimapButton", Minimap)
local Btn = Buffadin.MinimapButton

-- Supported minimap shapes for non-circular minimap addons (SexyMap, ElvUI, etc.)
local minimapShapes = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

function Btn:GetDefaultRadius()
    local mw = Minimap and Minimap:GetWidth() or 140
    local mh = Minimap and Minimap:GetHeight() or 140
    if not mw or mw <= 0 then mw = 140 end
    if not mh or mh <= 0 then mh = 140 end
    return math.floor((math.max(mw, mh) / 2) + 10 + 0.5)
end

function Btn:Initialize()
    self:SetSize(32, 32)
    self:SetFrameStrata("MEDIUM")
    self:SetFrameLevel((Minimap and Minimap:GetFrameLevel() or 1) + 8)
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Icon texture
    local icon = self:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Holy_GreaterBlessingofKings")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    self.icon = icon

    -- Circular border overlay
    local border = self:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    self.border = border

    local suppressClickUntil = 0

    self:SetScript("OnDragStart", function(self)
        self.isDragging = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx or not my then return end
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local dx = cx - mx
            local dy = cy - my
            local angle = math.atan2(dy, dx)
            Buffadin.db.profile.minimap.angle = math.deg(angle)

            if IsShiftKeyDown() then
                local dist = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
                dist = math.max(30, math.min(dist, 300))
                Buffadin.db.profile.minimap.radius = dist
            end

            self:UpdatePosition()
        end)
    end)

    self:SetScript("OnDragStop", function(self)
        if self.isDragging then
            suppressClickUntil = GetTime() + 0.15
        end
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    self:SetScript("OnClick", function(self, button)
        if self.isDragging or GetTime() < suppressClickUntil then
            return
        end

        if IsShiftKeyDown() and button == "RightButton" then
            Buffadin.db.profile.minimap.radius = nil
            self:UpdatePosition()
            Buffadin:Print("Minimap button distance reset to rim.")
            return
        end

        if button == "LeftButton" then
            if Buffadin.ManagerFrame:IsShown() then
                Buffadin.ManagerFrame:Hide()
            else
                Buffadin.ManagerFrame:Show()
            end
        elseif button == "RightButton" then
            if Buffadin.OptionsFrame:IsShown() then
                Buffadin.OptionsFrame:Hide()
            else
                Buffadin.OptionsFrame:Show()
            end
        end
    end)

    self:SetScript("OnEnter", function(self)
        if self.isDragging then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Buffadin", 0.95, 0.82, 0.3)
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Blessing Manager", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Toggle Settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Drag:|r Move around Minimap", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Shift-Drag:|r Adjust distance from center", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Shift+Right-Click:|r Reset distance to rim", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    self:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if Minimap and Minimap.HookScript then
        Minimap:HookScript("OnSizeChanged", function()
            self:UpdatePosition()
        end)
    end

    self:UpdatePosition()
end

function Btn:UpdatePosition()
    if not Buffadin.db or not Buffadin.db.profile or not Buffadin.db.profile.minimap then
        return
    end

    local minimapConf = Buffadin.db.profile.minimap
    if minimapConf.hide then
        self:Hide()
        return
    else
        self:Show()
    end

    local angle = math.rad(minimapConf.angle or 220)
    local mw = Minimap and Minimap:GetWidth() or 140
    local mh = Minimap and Minimap:GetHeight() or 140
    if not mw or mw <= 0 then mw = 140 end
    if not mh or mh <= 0 then mh = 140 end

    local baseRadius = self:GetDefaultRadius()
    local radius = minimapConf.radius or baseRadius

    local maxDim = math.max(mw, mh)
    local rx = radius * (mw / maxDim)
    local ry = radius * (mh / maxDim)

    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable = minimapShapes[shape] or minimapShapes["ROUND"]

    local cosA = math.cos(angle)
    local sinA = math.sin(angle)

    local q = 1
    if cosA < 0 then q = q + 1 end
    if sinA > 0 then q = q + 2 end

    local x, y
    if quadTable[q] then
        x = cosA * rx
        y = sinA * ry
    else
        local diagRadius = math.sqrt(rx * rx + ry * ry) - 10
        x = math.max(-rx, math.min(cosA * diagRadius, rx))
        y = math.max(-ry, math.min(sinA * diagRadius, ry))
    end

    self:ClearAllPoints()
    self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
