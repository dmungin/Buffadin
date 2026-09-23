local addonName, Buffadin = ...

Buffadin.PlayerPopups = Buffadin:CreateBackdropFrame("Frame", "BuffadinPlayerPopups", UIParent)
local Popups = Buffadin.PlayerPopups

Popups.buttons = {}
Popups.currentClassId = nil
Popups.hideTimer = nil

function Popups:Initialize()
    self:SetFrameStrata("FULLSCREEN_DIALOG")
    self:SetFrameLevel(100)
    self:SetClampedToScreen(true)
    self:Hide()

    Buffadin.Theme:ApplyCardBackdrop(self, 0.95, 0.85)

    self:SetScript("OnEnter", function()
        self:CancelHide()
    end)
    self:SetScript("OnLeave", function()
        self:ScheduleHide()
    end)
end

function Popups:GetOrCreateButton(index)
    if self.buttons[index] then
        return self.buttons[index]
    end

    local btn = CreateFrame("Button", "Buffadin_PopupBtn" .. index, self, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(170, 26)
    Buffadin.Theme:ApplyCardBackdrop(btn, 0.80, 0.60)
    btn:RegisterForClicks("AnyUp", "AnyDown")

    -- Buff icon (casts the spell)
    local buffIcon = btn:CreateTexture(nil, "ARTWORK")
    buffIcon:SetSize(20, 20)
    buffIcon:SetPoint("LEFT", 4, 0)
    buffIcon:SetTexture(Buffadin.GREATER_BLESSINGS[0].icon)
    buffIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.buffIcon = buffIcon

    -- Player name
    local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", buffIcon, "RIGHT", 5, 0)
    nameText:SetWidth(75)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    btn.nameText = nameText

    -- Expiration timer
    local timerText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timerText:SetPoint("RIGHT", -26, 0)
    timerText:SetJustifyH("RIGHT")
    btn.timerText = timerText

    -- Dedicated Override Button (cycles individual single-target blessing override)
    local overrideBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
    overrideBtn:SetSize(20, 20)
    overrideBtn:SetPoint("RIGHT", btn, "RIGHT", -3, 0)
    Buffadin.Theme:ApplyCardBackdrop(overrideBtn, 0.90, 0.80)
    overrideBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local overrideIcon = overrideBtn:CreateTexture(nil, "ARTWORK")
    overrideIcon:SetSize(16, 16)
    overrideIcon:SetPoint("CENTER", 0, 0)
    overrideIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    overrideBtn.icon = overrideIcon

    overrideBtn:SetScript("OnClick", function(self, mouseBtn)
        if not self.unitName or not self.classId then return end
        local pallyName = UnitName("player")
        if IsShiftKeyDown() then
            Buffadin.Assignments:SetNormal(pallyName, self.classId, self.unitName, 0)
        else
            local step = (mouseBtn == "RightButton") and -1 or 1
            Buffadin.Assignments:CycleNormal(pallyName, self.classId, self.unitName, step)
        end
        if Popups.currentClassId and Popups.currentAnchor then
            Popups:ShowForClass(Popups.currentClassId, Popups.currentAnchor)
        end
    end)

    overrideBtn:SetScript("OnEnter", function(self)
        Popups:CancelHide()
        if not self.unitName or not self.classId then return end
        local pallyName = UnitName("player")
        local nIndex = Buffadin.Assignments:GetNormal(pallyName, self.classId, self.unitName)
        local nConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
        local gIndex = Buffadin.Assignments:GetGreater(pallyName, self.classId)
        local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.unitName .. " - Blessing Override", 0.95, 0.82, 0.3)
        if nIndex > 0 and nConfig then
            GameTooltip:AddLine("Current Override: |cff00ccff" .. nConfig.name .. "|r", 1, 1, 1)
        else
            GameTooltip:AddLine("Current: |cffaaaaaaDefault (" .. (gConfig and gConfig.name or "None") .. ")|r", 1, 1, 1)
        end
        if self.isTank then
            GameTooltip:AddLine("|cffffaa00[Tank]:|r Override to Might/Sanctuary to avoid Salvation!", 1, 0.8, 0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Cycle Next Override", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Cycle Previous Override", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cff00ff00Shift-Click:|r Reset to Default Class Blessing", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    overrideBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        Popups:ScheduleHide()
    end)

    btn.overrideBtn = overrideBtn

    btn:SetScript("OnEnter", function(self)
        Popups:CancelHide()
        if self.unitInfo then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.unitInfo.name, 1, 1, 1)
            if self.unitInfo.isTank then
                GameTooltip:AddLine("|cff00ccff[Main Tank]|r", 0, 1, 1)
            end
            local uStatus = Buffadin.BuffScanner.unitStatus[self.unitInfo.unitId]
            if uStatus then
                local bName = uStatus.assignedSpellName or "None"
                GameTooltip:AddLine("Assigned Buff: " .. bName, 0.9, 0.8, 0.5)
                if uStatus.hasBuff then
                    GameTooltip:AddLine("Status: |cff00ff00Active|r (" .. Buffadin.Theme:FormatTime(uStatus.expiration) .. ")")
                else
                    GameTooltip:AddLine("Status: |cffff2222Missing|r")
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Left-Click:|r Cast Blessing on " .. self.unitInfo.name, 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffaaaaaaUse the icon on the right to set custom overrides|r", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        Popups:ScheduleHide()
    end)

    self.buttons[index] = btn
    return btn
end

function Popups:ShowForClass(classId, anchorFrame)
    if not Buffadin.db.profile.showPlayerPopups then return end

    self:CancelHide()
    self.currentClassId = classId
    self.currentAnchor = anchorFrame

    local units = Buffadin.Roster.classes[classId] or {}
    if #units == 0 then
        self:Hide()
        return
    end

    local playerName = UnitName("player")
    local inCombat = Buffadin:InCombat()

    local btnHeight = 28
    local padding = 6
    local totalHeight = (#units * btnHeight) + (padding * 2)
    self:SetSize(182, totalHeight)

    -- Anchor popup above the class button
    self:ClearAllPoints()
    self:SetPoint("BOTTOM", anchorFrame, "TOP", 0, 6)

    local yOffset = -padding
    for i, unitInfo in ipairs(units) do
        local btn = self:GetOrCreateButton(i)
        btn.unitInfo = unitInfo
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self, "TOPLEFT", padding, yOffset)
        btn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -padding, yOffset)
        btn:Show()

        -- Set Name & Color
        btn.nameText:SetText(unitInfo.name)
        local r, g, b = Buffadin.Theme:GetClassColor(unitInfo.classToken)
        btn.nameText:SetTextColor(r, g, b)

        -- Get Status
        local uStatus = Buffadin.BuffScanner.unitStatus[unitInfo.unitId] or {}
        local hasBuff = uStatus.hasBuff
        local remaining = uStatus.expiration or 0

        -- Set Main Buff Icon & Row Border
        local nIndex = Buffadin.Assignments:GetNormal(playerName, classId, unitInfo.name)
        local icon = Buffadin.GREATER_BLESSINGS[0].icon
        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            icon = Buffadin.NORMAL_BLESSINGS[nIndex].icon
            Buffadin.Theme:SetBorderStatus(btn, hasBuff and "Good" or "Special")
        else
            local gIndex = Buffadin.Assignments:GetGreater(playerName, classId)
            if Buffadin.GREATER_BLESSINGS[gIndex] and Buffadin.GREATER_BLESSINGS[gIndex].spellId > 0 then
                icon = Buffadin.GREATER_BLESSINGS[gIndex].icon
            end
            Buffadin.Theme:SetBorderStatus(btn, hasBuff and "Good" or "All")
        end
        btn.buffIcon:SetTexture(icon)

        -- Configure the Override Button on the right
        btn.overrideBtn.classId = classId
        btn.overrideBtn.unitName = unitInfo.name
        btn.overrideBtn.isTank = unitInfo.isTank
        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            btn.overrideBtn.icon:SetTexture(Buffadin.NORMAL_BLESSINGS[nIndex].icon)
            btn.overrideBtn.icon:SetDesaturated(false)
            Buffadin.Theme:SetBorderStatus(btn.overrideBtn, "Special")
        else
            btn.overrideBtn.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            btn.overrideBtn.icon:SetDesaturated(true)
            Buffadin.Theme:SetBorderStatus(btn.overrideBtn, "Disabled")
        end
        btn.buffIcon:SetTexture(icon)

        -- Timer
        if hasBuff and remaining > 0 then
            btn.timerText:SetText(Buffadin.Theme:FormatTime(remaining))
            btn.timerText:SetTextColor(0.4, 0.9, 0.4)
        else
            btn.timerText:SetText(unitInfo.isDead and "|cffff2222Dead|r" or "")
        end

        -- Configure Click Casting (Only out of combat)
        if not inCombat then
            local spellName = uStatus.assignedSpellName or ""
            if spellName ~= "" and not unitInfo.isDead then
                btn:SetAttribute("type1", "spell")
                btn:SetAttribute("spell1", spellName)
                btn:SetAttribute("unit1", unitInfo.unitId)
            else
                btn:SetAttribute("type1", nil)
            end
        end

        yOffset = yOffset - btnHeight
    end

    -- Hide unused buttons
    for i = #units + 1, #self.buttons do
        self.buttons[i]:Hide()
    end

    self:Show()
end

function Popups:ScheduleHide()
    self:CancelHide()
    self.hideTimer = C_Timer.NewTimer(0.4, function()
        if not self:IsMouseOver() then
            self:Hide()
        end
    end)
end

function Popups:CancelHide()
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
end
