local addonName, Buffadin = ...

Buffadin.OptionsFrame = CreateFrame("Frame", "BuffadinOptionsFrame", UIParent, "ButtonFrameTemplate")
local Frame = Buffadin.OptionsFrame

function Frame:Initialize()
    self:SetSize(420, 480)
    self:SetPoint("CENTER", UIParent, "CENTER", 50, -20)
    self:SetFrameStrata("DIALOG")
    self:SetFrameLevel(100)
    self:SetClampedToScreen(true)
    self:Hide()

    -- Ensure solid opaque background so action bars and world never bleed through
    if not self.solidBg then
        local bg = self:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints(self)
        bg:SetColorTexture(0.06, 0.06, 0.08, 0.98)
        self.solidBg = bg
    end

    Buffadin.Theme:StyleWindow(self, "Buffadin - Settings", "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings")
    tinsert(UISpecialFrames, "BuffadinOptionsFrame")

    local parent = self.Inset or self

    local startY = -16
    local spacing = 24

    local options = {
        { key = "enabled",          text = "Enable Addon" },
        { key = "barLocked",        text = "Lock Buff Bar Position" },
        { key = "showWhenSolo",     text = "Show Buff Bar When Solo" },
        { key = "showInParty",      text = "Show Buff Bar In Party" },
        { key = "showInRaid",       text = "Show Buff Bar In Raid" },
        { key = "showAutoButton",   text = "Show Auto-Buff Button" },
        { key = "showAuraButton",   text = "Show Paladin Aura Button" },
        { key = "showRfButton",     text = "Show Righteous Fury Button" },
        { key = "showPlayerPopups", text = "Show Player Popups on Hover" },
        { key = "showPets",         text = "Track Hunter/Warlock Pets" },
        { key = "showMinimap",      text = "Show Minimap Button" },
    }

    self.checkboxes = {}
    for i, opt in ipairs(options) do
        local cb = CreateFrame("CheckButton", "Buffadin_OptCheck_" .. opt.key, parent, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, startY - ((i - 1) * spacing))
        cb.text = _G[cb:GetName() .. "Text"]
        if cb.text then
            cb.text:SetFontObject(GameFontNormalSmall)
            cb.text:SetText(opt.text)
        end
        cb.optKey = opt.key

        cb:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            local isChecked = (checked == true or checked == 1)
            if self.optKey == "showMinimap" then
                Buffadin.db.profile.minimap.hide = not isChecked
                if Buffadin.MinimapButton and Buffadin.MinimapButton.UpdatePosition then
                    Buffadin.MinimapButton:UpdatePosition()
                end
            else
                Buffadin.db.profile[self.optKey] = isChecked
                Buffadin.BlessingsBar:UpdateLayout()
            end
        end)

        self.checkboxes[opt.key] = cb
    end

    -- Scale Slider
    local sliderY = startY - (#options * spacing) - 14
    local slider = CreateFrame("Slider", "Buffadin_ScaleSlider", parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, sliderY)
    slider:SetWidth(180)
    slider:SetMinMaxValues(0.6, 1.6)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)

    local sliderTitle = _G[slider:GetName() .. "Text"]
    if sliderTitle then
        sliderTitle:SetText("Buff Bar Scale")
    end
    local lowText = _G[slider:GetName() .. "Low"]
    if lowText then lowText:SetText("60%") end
    local highText = _G[slider:GetName() .. "High"]
    if highText then highText:SetText("160%") end

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val * 100 + 0.5) / 100
        Buffadin.db.profile.barScale = val
        Buffadin.BlessingsBar:SetScale(val)
        if sliderTitle then
            sliderTitle:SetText(string.format("Buff Bar Scale (%d%%)", math.floor(val * 100 + 0.5)))
        end
    end)
    self.scaleSlider = slider

    -- Bar Orientation (Radio Buttons)
    local orientLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, sliderY - 38)
    orientLabel:SetText("Bar Orientation:")
    self.orientLabel = orientLabel

    local horizRadio = CreateFrame("CheckButton", "Buffadin_Radio_Horizontal", parent, "UIRadioButtonTemplate")
    horizRadio:SetSize(16, 16)
    horizRadio:SetPoint("TOPLEFT", orientLabel, "BOTTOMLEFT", 2, -6)
    horizRadio.text = _G[horizRadio:GetName() .. "Text"]
    if horizRadio.text then
        horizRadio.text:SetFontObject(GameFontNormalSmall)
        horizRadio.text:SetText("Horizontal")
    end

    local vertRadio = CreateFrame("CheckButton", "Buffadin_Radio_Vertical", parent, "UIRadioButtonTemplate")
    vertRadio:SetSize(16, 16)
    vertRadio:SetPoint("LEFT", horizRadio, "RIGHT", 100, 0)
    vertRadio.text = _G[vertRadio:GetName() .. "Text"]
    if vertRadio.text then
        vertRadio.text:SetFontObject(GameFontNormalSmall)
        vertRadio.text:SetText("Vertical")
    end

    horizRadio:SetScript("OnClick", function(self)
        self:SetChecked(true)
        vertRadio:SetChecked(false)
        Buffadin.db.profile.orientation = "HORIZONTAL"
        Buffadin.BlessingsBar:UpdateLayout()
    end)

    vertRadio:SetScript("OnClick", function(self)
        self:SetChecked(true)
        horizRadio:SetChecked(false)
        Buffadin.db.profile.orientation = "VERTICAL"
        Buffadin.BlessingsBar:UpdateLayout()
    end)

    self.horizRadio = horizRadio
    self.vertRadio = vertRadio

    -- Close Button at bottom
    local closeBtn = CreateFrame("Button", "Buffadin_OptionsCloseBtn", self, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -16, 6)
    Buffadin.Theme:StyleButton(closeBtn, "Close")
    closeBtn:SetScript("OnClick", function()
        Frame:Hide()
    end)
    self.closeBtn = closeBtn

    self:SetScript("OnShow", function(self)
        self:Raise()
        self:RefreshValues()
    end)
end

function Frame:RefreshValues()
    local db = Buffadin.db.profile
    for key, cb in pairs(self.checkboxes) do
        if key == "showMinimap" then
            cb:SetChecked(not (db.minimap and db.minimap.hide))
        else
            cb:SetChecked(db[key] == true)
        end
    end
    if self.scaleSlider then
        local scale = db.barScale or 1.0
        self.scaleSlider:SetValue(scale)
        local sliderTitle = _G[self.scaleSlider:GetName() .. "Text"]
        if sliderTitle then
            sliderTitle:SetText(string.format("Buff Bar Scale (%d%%)", math.floor(scale * 100 + 0.5)))
        end
    end
    local orient = db.orientation or "HORIZONTAL"
    if self.horizRadio then
        self.horizRadio:SetChecked(orient == "HORIZONTAL")
    end
    if self.vertRadio then
        self.vertRadio:SetChecked(orient == "VERTICAL")
    end
end
