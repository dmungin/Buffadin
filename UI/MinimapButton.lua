local addonName, Buffadin = ...

Buffadin.MinimapButton = CreateFrame("Button", "BuffadinMinimapButton", Minimap)
local Btn = Buffadin.MinimapButton

function Btn:Initialize()
    self:SetSize(32, 32)
    self:SetFrameStrata("MEDIUM")
    self:SetFrameLevel(8)
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

    self:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.atan2(cy - my, cx - mx)
            Buffadin.db.profile.minimap.angle = math.deg(angle)
            self:UpdatePosition()
        end)
    end)

    self:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    self:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if Buffadin.ManagerFrame:IsShown() then
                Buffadin.ManagerFrame:Hide()
            else
                Buffadin.ManagerFrame:Show()
            end
        elseif button == "RightButton" then
            if Buffadin.BlessingsBar:IsShown() then
                Buffadin.BlessingsBar:Hide()
            else
                Buffadin.BlessingsBar:Show()
            end
        end
    end)

    self:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Buffadin", 0.95, 0.82, 0.3)
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Blessing Manager", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Toggle Floating Buff Bar", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00Drag:|r Move Minimap Icon", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    self:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self:UpdatePosition()
end

function Btn:UpdatePosition()
    local angle = math.rad(Buffadin.db.profile.minimap.angle or 220)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    self:ClearAllPoints()
    self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
