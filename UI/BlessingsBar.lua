local addonName, Buffadin = ...

Buffadin.BlessingsBar = Buffadin:CreateBackdropFrame("Frame", "BuffadinBlessingsBar", UIParent)
local Bar = Buffadin.BlessingsBar

Bar.buttons = {}
Bar.autoButton = nil
Bar.auraButton = nil
Bar.rfButton = nil
Bar.sealButton = nil

-- =========================================================================
-- Bar Creation & Setup
-- =========================================================================
function Bar:Initialize()
    self:SetSize(400, 48)
    self:SetClampedToScreen(true)
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")

    -- Load saved position
    local db = Buffadin.db.profile
    self:ClearAllPoints()
    self:SetPoint(db.barPoint or "CENTER", UIParent, db.barPoint or "CENTER", db.barX or 0, db.barY or -150)
    self:SetScale(db.barScale or 1.0)

    self:SetScript("OnDragStart", function(self)
        if not Buffadin.db.profile.barLocked then
            self:StartMoving()
        end
    end)

    self:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        Buffadin.db.profile.barPoint = point
        Buffadin.db.profile.barX = x
        Buffadin.db.profile.barY = y
    end)

    -- Bar background (subtle dark container)
    Buffadin.Theme:ApplyCardBackdrop(self, 0.40, 0.30)

    self:CreateUtilityButtons()
    self:CreateClassButtons()
    self:UpdateLayout()
end

-- =========================================================================
-- Utility Buttons (Auto-Buff, Aura, Righteous Fury, Seal)
-- =========================================================================
function Bar:CreateUtilityButtons()
    -- 1. Auto-Buff Button
    local autoBtn = CreateFrame("Button", "Buffadin_AutoBuffBtn", self, "SecureActionButtonTemplate, BackdropTemplate")
    autoBtn:SetSize(40, 40)
    Buffadin.Theme:ApplyCardBackdrop(autoBtn, 0.90, 0.80)
    autoBtn:RegisterForClicks("AnyUp", "AnyDown")

    local autoIcon = autoBtn:CreateTexture(nil, "ARTWORK")
    autoIcon:SetSize(28, 28)
    autoIcon:SetPoint("CENTER", 0, 0)
    autoIcon:SetTexture("Interface\\Icons\\Spell_Holy_GreaterBlessingofKings")
    autoIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    autoBtn.icon = autoIcon

    local autoCount = autoBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoCount:SetPoint("BOTTOMRIGHT", -2, 2)
    autoCount:SetText("")
    autoBtn.count = autoCount

    autoBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:AddLine("Auto-Buff Next Priority", 0.95, 0.82, 0.3)

        local targetUnit, gSpellId, nSpellId, isGreater, bestClassId, reasonText = Buffadin.BuffScanner:GetNextAutoBuff()
        if reasonText then
            GameTooltip:AddLine("Next Target: |cff00ff00" .. reasonText .. "|r", 1, 1, 1)
        else
            GameTooltip:AddLine("Next Target: |cff888888All players buffed|r", 1, 1, 1)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Priority Calculation Order:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" 1. Missing Paladin self-aura", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" 2. Class with the most missing buffs", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" 3. Expiring blessings (< 2 min remaining)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" 4. Individual normal overrides", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Cast Greater Blessing (or Normal if unlearned)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Cast Normal Blessing on next player", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    autoBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.autoButton = autoBtn

    -- 2. Aura Button
    local auraBtn = CreateFrame("Button", "Buffadin_AuraBtn", self, "SecureActionButtonTemplate, BackdropTemplate")
    auraBtn:SetSize(40, 40)
    Buffadin.Theme:ApplyCardBackdrop(auraBtn, 0.90, 0.80)
    auraBtn:RegisterForClicks("AnyUp", "AnyDown")

    local auraIcon = auraBtn:CreateTexture(nil, "ARTWORK")
    auraIcon:SetSize(28, 28)
    auraIcon:SetPoint("CENTER", 0, 0)
    auraIcon:SetTexture("Interface\\Icons\\Spell_Holy_DevotionAura")
    auraIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    auraBtn.icon = auraIcon

    auraBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:AddLine("Assigned Paladin Aura", 0.95, 0.82, 0.3)
        local playerName = UnitName("player")
        local auraIndex = Buffadin.Assignments:GetAura(playerName)
        local aInfo = Buffadin.AURAS[auraIndex]
        GameTooltip:AddLine("Assigned: " .. (aInfo and aInfo.name or "None"), 1, 1, 1)
        GameTooltip:AddLine("Left-Click: Cast Aura", 0, 1, 0)
        GameTooltip:Show()
    end)
    auraBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.auraButton = auraBtn

    -- 3. Righteous Fury Button
    local rfBtn = CreateFrame("Button", "Buffadin_RFBtn", self, "SecureActionButtonTemplate, BackdropTemplate")
    rfBtn:SetSize(40, 40)
    Buffadin.Theme:ApplyCardBackdrop(rfBtn, 0.90, 0.80)
    rfBtn:RegisterForClicks("AnyUp", "AnyDown")

    local rfIcon = rfBtn:CreateTexture(nil, "ARTWORK")
    rfIcon:SetSize(28, 28)
    rfIcon:SetPoint("CENTER", 0, 0)
    rfIcon:SetTexture(Buffadin.RIGHTEOUS_FURY.icon)
    rfIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    rfBtn.icon = rfIcon

    rfBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:AddLine("Righteous Fury", 0.95, 0.82, 0.3)
        GameTooltip:AddLine("Left-Click: Cast Righteous Fury", 0, 1, 0)
        GameTooltip:Show()
    end)
    rfBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.rfButton = rfBtn
end

-- =========================================================================
-- Class Buttons Creation
-- =========================================================================
function Bar:CreateClassButtons()
    for _, cls in ipairs(Buffadin.CLASSES) do
        local btn = CreateFrame("Button", "Buffadin_ClassBtn" .. cls.id, self, "SecureActionButtonTemplate, BackdropTemplate")
        btn:SetSize(56, 40)
        Buffadin.Theme:ApplyCardBackdrop(btn, 0.85, 0.70)
        btn:RegisterForClicks("AnyUp", "AnyDown")

        btn.classId = cls.id
        btn.classToken = cls.token

        -- Class Icon (left side)
        local classIcon = btn:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(22, 22)
        classIcon:SetPoint("LEFT", 4, 0)
        classIcon:SetTexture(cls.icon)
        classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.classIcon = classIcon

        -- Blessing Icon (right side)
        local buffIcon = btn:CreateTexture(nil, "ARTWORK")
        buffIcon:SetSize(22, 22)
        buffIcon:SetPoint("RIGHT", -4, 0)
        buffIcon:SetTexture(Buffadin.GREATER_BLESSINGS[0].icon)
        buffIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.buffIcon = buffIcon

        -- Missing Count Badge (top-right overlay)
        local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countText:SetPoint("TOPRIGHT", -2, -2)
        countText:SetText("")
        btn.countText = countText

        -- Timer (bottom-center)
        local timerText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timerText:SetPoint("BOTTOM", 0, 2)
        timerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        timerText:SetText("")
        btn.timerText = timerText

        -- Tooltip & Flyout trigger
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
            local clsConfig = Buffadin.CLASS_BY_ID[self.classId]
            GameTooltip:AddLine(clsConfig and clsConfig.name or "Class", 0.95, 0.82, 0.3)

            local statusInfo = Buffadin.BuffScanner.classStatus[self.classId]
            local gIndex = statusInfo and statusInfo.assignedGSpell or 0
            local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]
            GameTooltip:AddLine("Assigned: " .. (gConfig and gConfig.name or "None"), 1, 1, 1)

            if statusInfo then
                GameTooltip:AddLine(string.format("Status: %d / %d Buffed (Missing: %d)",
                    statusInfo.totalCount - statusInfo.missingCount, statusInfo.totalCount, statusInfo.missingCount), 0.8, 0.8, 0.8)
                if statusInfo.minExpiration > 0 then
                    GameTooltip:AddLine("Remaining: " .. Buffadin.Theme:FormatTime(statusInfo.minExpiration), 0.4, 0.8, 1)
                end
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Left-Click:|r Cast Greater Blessing (or Normal if unlearned)", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Right-Click:|r Cast Normal Blessing", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Hover:|r View class members flyout", 0.7, 0.7, 0.7)
            GameTooltip:Show()

            if Buffadin.PlayerPopups then
                Buffadin.PlayerPopups:ShowForClass(self.classId, self)
            end
        end)

        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if Buffadin.PlayerPopups and not Buffadin.PlayerPopups:IsMouseOver() then
                Buffadin.PlayerPopups:ScheduleHide()
            end
        end)

        self.buttons[cls.id] = btn
    end
end

-- =========================================================================
-- Layout & Attributes Update
-- =========================================================================
function Bar:UpdateLayout()
    local db = Buffadin.db.profile
    if not db.enabled then
        self:Hide()
        return
    end

    -- Visibility based on group type
    local inRaid = Buffadin:IsInRaid()
    local inGroup = Buffadin:IsInGroup()
    if inRaid and not db.showInRaid then
        self:Hide()
        return
    elseif not inRaid and inGroup and not db.showInParty then
        self:Hide()
        return
    elseif not inGroup and not db.showWhenSolo then
        self:Hide()
        return
    end

    self:Show()

    local offsetX = 4
    local btnSpacing = 4

    -- 1. Position Auto-Buff Button
    if db.showAutoButton and self.autoButton then
        self.autoButton:ClearAllPoints()
        self.autoButton:SetPoint("LEFT", self, "LEFT", offsetX, 0)
        self.autoButton:Show()
        offsetX = offsetX + 40 + btnSpacing
    elseif self.autoButton then
        self.autoButton:Hide()
    end

    -- 2. Position Aura Button
    if db.showAuraButton and self.auraButton then
        self.auraButton:ClearAllPoints()
        self.auraButton:SetPoint("LEFT", self, "LEFT", offsetX, 0)
        self.auraButton:Show()
        offsetX = offsetX + 40 + btnSpacing
    elseif self.auraButton then
        self.auraButton:Hide()
    end

    -- 3. Position Righteous Fury Button
    if db.showRfButton and self.rfButton then
        self.rfButton:ClearAllPoints()
        self.rfButton:SetPoint("LEFT", self, "LEFT", offsetX, 0)
        self.rfButton:Show()
        offsetX = offsetX + 40 + btnSpacing
    elseif self.rfButton then
        self.rfButton:Hide()
    end

    -- 4. Position Class Buttons
    local visibleClassCount = 0
    for _, cls in ipairs(Buffadin.CLASSES) do
        local btn = self.buttons[cls.id]
        local classUnits = Buffadin.Roster.classes[cls.id]
        local hasMembers = classUnits and (#classUnits > 0)
        local playerName = UnitName("player")
        local gIndex = Buffadin.Assignments:GetGreater(playerName, cls.id)

        -- Show button only if class has members present in the group
        if hasMembers then
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", self, "LEFT", offsetX, 0)
            btn:Show()
            offsetX = offsetX + 56 + btnSpacing
            visibleClassCount = visibleClassCount + 1
        else
            btn:Hide()
        end
    end

    local totalWidth = math.max(120, offsetX + 2)
    self:SetWidth(totalWidth)

    self:RefreshDisplay()
end

-- =========================================================================
-- Refresh Display & Secure Attributes
-- =========================================================================
function Bar:RefreshDisplay()
    local playerName = UnitName("player")
    local inCombat = Buffadin:InCombat()

    -- 1. Update Class Buttons Visuals & Attributes
    for _, cls in ipairs(Buffadin.CLASSES) do
        local btn = self.buttons[cls.id]
        if btn and btn:IsShown() then
            local statusInfo = Buffadin.BuffScanner.classStatus[cls.id] or {}
            local gIndex = Buffadin.Assignments:GetGreater(playerName, cls.id)
            local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]

            -- Update Icons
            if gConfig and gConfig.spellId > 0 then
                btn.buffIcon:SetTexture(gConfig.icon)
                btn.buffIcon:SetDesaturated(false)
            else
                btn.buffIcon:SetTexture(Buffadin.GREATER_BLESSINGS[0].icon)
                btn.buffIcon:SetDesaturated(true)
            end

            -- Update Status Border
            Buffadin.Theme:SetBorderStatus(btn, statusInfo.status or "Disabled")

            -- Update Missing Count Text
            if Buffadin.db.profile.showCounts and statusInfo.missingCount and statusInfo.missingCount > 0 then
                btn.countText:SetText(tostring(statusInfo.missingCount))
                btn.countText:SetTextColor(1, 0.3, 0.3)
            else
                btn.countText:SetText("")
            end

            -- Update Timer
            if Buffadin.db.profile.showTimers and statusInfo.minExpiration and statusInfo.minExpiration > 0 then
                btn.timerText:SetText(Buffadin.Theme:FormatTime(statusInfo.minExpiration))
                if statusInfo.minExpiration < 60 then
                    btn.timerText:SetTextColor(1, 0.2, 0.2)
                elseif statusInfo.minExpiration < 180 then
                    btn.timerText:SetTextColor(1, 0.8, 0.2)
                else
                    btn.timerText:SetTextColor(0.3, 1, 0.3)
                end
            else
                btn.timerText:SetText("")
            end

            -- Configure Secure Attributes (Only when out of combat!)
            if not inCombat then
                local isMock = Buffadin.MockHarness and Buffadin.MockHarness.active
                local gKnown = (gConfig and gConfig.spellId > 0) and Buffadin:IsSpellKnown(gConfig.spellId)
                local gSpellName = (gConfig and gConfig.spellId > 0) and Buffadin:GetSpellName(gConfig.spellId) or ""
                local classUnits = Buffadin.Roster.classes[cls.id] or {}

                -- Determine Right Click target & spell (Single target buffing: prioritize missing overrides, then missing class buffs)
                local rightTarget = nil
                local rightSpellName = ""
                local inRangeSpecial = nil
                local anySpecial = nil
                local inRangeMissing = nil
                local anyMissing = nil
                local lowestExpUnit = nil
                local lowestExp = 999999

                for _, u in ipairs(classUnits) do
                    if not u.isDead and u.isOnline and u.isVisible then
                        local uStatus = Buffadin.BuffScanner.unitStatus[u.unitId]
                        local hasBuff = uStatus and uStatus.hasBuff
                        local isSpecial = uStatus and uStatus.isSpecial

                        if not hasBuff then
                            if isSpecial then
                                if not anySpecial then anySpecial = u end
                                local nIndex = Buffadin.Assignments:GetNormal(playerName, cls.id, u.name)
                                local sId = (nIndex and Buffadin.NORMAL_BLESSINGS[nIndex]) and Buffadin.NORMAL_BLESSINGS[nIndex].spellId
                                if Buffadin:IsUnitInRange(u.unitId, sId) then
                                    inRangeSpecial = u
                                    break
                                end
                            else
                                if not anyMissing then anyMissing = u end
                                if Buffadin:IsUnitInRange(u.unitId, gConfig and gConfig.spellId) then
                                    inRangeMissing = u
                                end
                            end
                        elseif uStatus and uStatus.expiration and uStatus.expiration < lowestExp then
                            lowestExp = uStatus.expiration
                            lowestExpUnit = u
                        end
                    end
                end

                local chosenRightUnit = inRangeSpecial or anySpecial or inRangeMissing or anyMissing or lowestExpUnit or classUnits[1]
                if chosenRightUnit then
                    rightTarget = chosenRightUnit.unitId
                    local nOverride = Buffadin.Assignments:GetNormal(playerName, cls.id, chosenRightUnit.name)
                    if nOverride and nOverride > 0 and Buffadin.NORMAL_BLESSINGS[nOverride] then
                        local oConfig = Buffadin.NORMAL_BLESSINGS[nOverride]
                        rightSpellName = (oConfig.spellId > 0) and Buffadin:GetSpellName(oConfig.spellId) or ""
                    else
                        local nIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0
                        local nConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
                        rightSpellName = (nConfig and nConfig.spellId > 0) and Buffadin:GetSpellName(nConfig.spellId) or ""
                    end
                end

                -- Determine Left Click target & spell
                local leftTarget = nil
                local leftSpellName = ""

                if gKnown and gSpellName ~= "" then
                    leftSpellName = gSpellName
                    for _, u in ipairs(classUnits) do
                        if not u.isDead and u.isOnline and u.isVisible then
                            if Buffadin:IsUnitInRange(u.unitId, gConfig and gConfig.spellId, leftSpellName) then
                                leftTarget = u.unitId
                                break
                            end
                            if not leftTarget then leftTarget = u.unitId end
                        end
                    end
                    if not leftTarget and #classUnits > 0 then
                        leftTarget = classUnits[1].unitId
                    end
                else
                    -- Fallback to single normal blessing if Greater Blessing not learned
                    leftSpellName = rightSpellName
                    leftTarget = rightTarget
                end

                -- Configure Left Click
                if leftSpellName ~= "" and leftTarget then
                    btn:SetAttribute("type1", isMock and nil or "spell")
                    btn:SetAttribute("spell1", leftSpellName)
                    btn:SetAttribute("unit1", leftTarget)
                else
                    btn:SetAttribute("type1", nil)
                    btn:SetAttribute("spell1", nil)
                    btn:SetAttribute("unit1", nil)
                end

                -- Configure Right Click: Single Normal Blessing (or Override)
                if rightSpellName ~= "" and rightTarget then
                    btn:SetAttribute("type2", isMock and nil or "spell")
                    btn:SetAttribute("spell2", rightSpellName)
                    btn:SetAttribute("unit2", rightTarget)
                else
                    btn:SetAttribute("type2", nil)
                    btn:SetAttribute("spell2", nil)
                    btn:SetAttribute("unit2", nil)
                end
            end
        end
    end

    -- 2. Update Utility Buttons Visuals & Attributes
    -- Auto-Buff Button
    if self.autoButton and self.autoButton:IsShown() then
        local targetUnit, gSpellId, nSpellId, isGreater, bestClassId, reasonText = Buffadin.BuffScanner:GetNextAutoBuff()
        local activeSpellId = (gSpellId and gSpellId > 0) and gSpellId or (nSpellId or 0)

        if activeSpellId > 0 and targetUnit then
            local spellTex = Buffadin:GetSpellTexture(activeSpellId)
            if spellTex and spellTex ~= "" then
                self.autoButton.icon:SetTexture(spellTex)
            end
            Buffadin.Theme:SetBorderStatus(self.autoButton, "Some")

            if not inCombat then
                local isMock = Buffadin.MockHarness and Buffadin.MockHarness.active
                local gKnown = (gSpellId and gSpellId > 0) and Buffadin:IsSpellKnown(gSpellId)
                local leftSpellName = (gKnown and gSpellId > 0) and Buffadin:GetSpellName(gSpellId) or ((nSpellId and nSpellId > 0) and Buffadin:GetSpellName(nSpellId) or "")
                local rightSpellName = (nSpellId and nSpellId > 0) and Buffadin:GetSpellName(nSpellId) or leftSpellName

                -- Left Click: Greater (or Normal if unlearned)
                if leftSpellName ~= "" then
                    self.autoButton:SetAttribute("type1", isMock and nil or "spell")
                    self.autoButton:SetAttribute("spell1", leftSpellName)
                    self.autoButton:SetAttribute("unit1", targetUnit)
                else
                    self.autoButton:SetAttribute("type1", nil)
                    self.autoButton:SetAttribute("spell1", nil)
                    self.autoButton:SetAttribute("unit1", nil)
                end

                -- Right Click: Always Normal Blessing
                if rightSpellName ~= "" then
                    self.autoButton:SetAttribute("type2", isMock and nil or "spell")
                    self.autoButton:SetAttribute("spell2", rightSpellName)
                    self.autoButton:SetAttribute("unit2", targetUnit)
                else
                    self.autoButton:SetAttribute("type2", nil)
                    self.autoButton:SetAttribute("spell2", nil)
                    self.autoButton:SetAttribute("unit2", nil)
                end
            end
        else
            self.autoButton.icon:SetTexture("Interface\\Icons\\Spell_Holy_GreaterBlessingofKings")
            Buffadin.Theme:SetBorderStatus(self.autoButton, "Good")
            if not inCombat then
                self.autoButton:SetAttribute("type1", nil)
                self.autoButton:SetAttribute("spell1", nil)
                self.autoButton:SetAttribute("unit1", nil)
                self.autoButton:SetAttribute("type2", nil)
                self.autoButton:SetAttribute("spell2", nil)
                self.autoButton:SetAttribute("unit2", nil)
            end
        end
    end

    -- Aura Button
    if self.auraButton and self.auraButton:IsShown() then
        local auraIndex = Buffadin.Assignments:GetAura(playerName)
        local aInfo = Buffadin.AURAS[auraIndex]
        if aInfo and aInfo.spellId > 0 then
            self.auraButton.icon:SetTexture(aInfo.icon)
            local hasAura = Buffadin.BuffScanner.selfStatus.hasAura
            Buffadin.Theme:SetBorderStatus(self.auraButton, hasAura and "Good" or "All")
            if not inCombat then
                local isMock = Buffadin.MockHarness and Buffadin.MockHarness.active
                local aName = Buffadin:GetSpellName(aInfo.spellId)
                self.auraButton:SetAttribute("type", isMock and nil or "spell")
                self.auraButton:SetAttribute("spell", aName)
                self.auraButton:SetAttribute("unit", "player")
            end
        else
            self.auraButton.icon:SetTexture(Buffadin.AURAS[0].icon)
            Buffadin.Theme:SetBorderStatus(self.auraButton, "Disabled")
            if not inCombat then
                self.auraButton:SetAttribute("type", nil)
                self.auraButton:SetAttribute("spell", nil)
                self.auraButton:SetAttribute("unit", nil)
            end
        end
    end

    -- Righteous Fury Button
    if self.rfButton and self.rfButton:IsShown() then
        local hasRF = Buffadin.BuffScanner.selfStatus.hasRighteousFury
        Buffadin.Theme:SetBorderStatus(self.rfButton, hasRF and "Good" or "Disabled")
        if not inCombat then
            local isMock = Buffadin.MockHarness and Buffadin.MockHarness.active
            local rfName = Buffadin:GetSpellName(Buffadin.RIGHTEOUS_FURY.spellId)
            self.rfButton:SetAttribute("type", isMock and nil or "spell")
            self.rfButton:SetAttribute("spell", rfName)
            self.rfButton:SetAttribute("unit", "player")
        end
    end
end
