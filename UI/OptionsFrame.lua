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

    local startY = -20
    local spacing = 26

    local options = {
        { key = "enabled",          text = "Enable Addon" },
        { key = "barLocked",        text = "Lock Buff Bar Position" },
        { key = "showWhenSolo",     text = "Show Buff Bar When Solo" },
        { key = "showInParty",      text = "Show Buff Bar In Party" },
        { key = "showInRaid",       text = "Show Buff Bar In Raid" },
        { key = "showCounts",       text = "Show Missing Buff Count Badge" },
        { key = "showTimers",       text = "Show Expiration Timers" },
        { key = "showAutoButton",   text = "Show Auto-Buff Button" },
        { key = "showAuraButton",   text = "Show Paladin Aura Button" },
        { key = "showRfButton",     text = "Show Righteous Fury Button" },
        { key = "showPlayerPopups", text = "Show Player Popups on Hover" },
        { key = "showPets",         text = "Track Hunter/Warlock Pets" },
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
            local isChecked = self:GetChecked()
            Buffadin.db.profile[self.optKey] = isChecked
            Buffadin.BlessingsBar:UpdateLayout()
        end)

        self.checkboxes[opt.key] = cb
    end

    -- Scale Slider
    local sliderY = startY - (#options * spacing) - 10
    local slider = CreateFrame("Slider", "Buffadin_ScaleSlider", parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, sliderY)
    slider:SetWidth(200)
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
    end)
    self.scaleSlider = slider

    -- Reset Position Button
    local resetBtn = CreateFrame("Button", "Buffadin_ResetPosBtn", parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 24)
    resetBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 18, 12)
    Buffadin.Theme:StyleButton(resetBtn, "Reset Bar Position")
    resetBtn:SetScript("OnClick", function()
        Buffadin.db.profile.barPoint = "CENTER"
        Buffadin.db.profile.barX = 0
        Buffadin.db.profile.barY = -150
        Buffadin.BlessingsBar:ClearAllPoints()
        Buffadin.BlessingsBar:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        Buffadin:Print("Buff Bar position reset to center.")
    end)
    self.resetBtn = resetBtn

    -- Close Button at bottom
    local closeBtn = CreateFrame("Button", "Buffadin_OptionsCloseBtn", parent, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -18, 12)
    Buffadin.Theme:StyleButton(closeBtn, "Close")
    closeBtn:SetScript("OnClick", function()
        Frame:Hide()
    end)
    self.closeBtn = closeBtn

    self:SetScript("OnShow", function()
        self:RefreshValues()
    end)
end

function Frame:RefreshValues()
    local db = Buffadin.db.profile
    for key, cb in pairs(self.checkboxes) do
        cb:SetChecked(db[key] == true)
    end
    if self.scaleSlider then
        self.scaleSlider:SetValue(db.barScale or 1.0)
    end
end
