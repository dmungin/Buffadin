local addonName, Buffadin = ...

Buffadin.ManagerFrame = CreateFrame("Frame", "BuffadinManagerFrame", UIParent, "ButtonFrameTemplate")
local Frame = Buffadin.ManagerFrame

Frame.cells = {}        -- [pallyIndex][classId] = cellButton
Frame.auraCells = {}    -- [pallyIndex] = auraCellButton
Frame.pallyHeaders = {} -- [pallyIndex] = headerFontString
Frame.classLabels = {}  -- [classId] = labelFontString

-- =========================================================================
-- Initialization & Window Setup
-- =========================================================================
function Frame:Initialize()
    self:SetSize(620, 480)
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    self:SetFrameStrata("HIGH")
    self:SetFrameLevel(20)
    self:SetClampedToScreen(true)
    self:Hide()

    -- Ensure solid opaque background so action bars and world never bleed through
    if not self.solidBg then
        local bg = self:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints(self)
        bg:SetColorTexture(0.06, 0.06, 0.08, 0.98)
        self.solidBg = bg
    end

    -- Apply Blizzard Native Retail styling
    Buffadin.Theme:StyleWindow(self, "Buffadin - Blessing Manager", "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings")

    -- Make frame close on Escape
    tinsert(UISpecialFrames, "BuffadinManagerFrame")

    -- Permission status badge (shows whether player is Leader / Assist / Viewer)
    local permText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    permText:SetPoint("TOPRIGHT", -36, -32)
    permText:SetText("")
    self.permText = permText

    -- Inset area for the grid
    self.scrollFrame = CreateFrame("ScrollFrame", "Buffadin_ManagerScrollFrame", self.Inset or self, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", self.Inset or self, "TOPLEFT", 6, -6)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.Inset or self, "BOTTOMRIGHT", -26, 42)

    self.content = CreateFrame("Frame", "Buffadin_ManagerContent", self.scrollFrame)
    self.content:SetSize(580, 400)
    self.scrollFrame:SetScrollChild(self.content)

    self:CreateClassRowLabels()
    self:CreateBottomBar()
    self:UpdateGrid()
end

-- =========================================================================
-- Class Row Labels (Left Column)
-- =========================================================================
function Frame:CreateClassRowLabels()
    local startY = -40
    local rowHeight = 32

    for i, cls in ipairs(Buffadin.CLASSES) do
        local y = startY - ((i - 1) * rowHeight)

        local rowBtn = CreateFrame("Button", nil, self.content, "BackdropTemplate")
        rowBtn:SetSize(126, 28)
        rowBtn:SetPoint("TOPLEFT", self.content, "TOPLEFT", 6, y)
        Buffadin.Theme:ApplyCardBackdrop(rowBtn, 0.50, 0.40)
        rowBtn.classId = cls.id

        -- Class Icon
        local icon = rowBtn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", 4, 0)
        icon:SetTexture(cls.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Class Name Text
        local text = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        text:SetText(cls.name)
        local r, g, b = Buffadin.Theme:GetClassColor(cls.token)
        text:SetTextColor(r, g, b)

        rowBtn:SetScript("OnClick", function(self)
            Frame:ToggleClassOverridesDrawer(self.classId)
        end)

        rowBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(cls.name .. " Overrides", 0.95, 0.82, 0.3)
            GameTooltip:AddLine("Click to open individual player overrides (e.g. Tank settings).", 1, 1, 1, true)
            GameTooltip:Show()
            self:SetBackdropBorderColor(0.8, 0.7, 0.2, 0.9)
        end)

        rowBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetBackdropBorderColor(0.25, 0.28, 0.35, 0.70)
        end)

        self.classLabels[cls.id] = rowBtn
    end

    -- Aura Row Label
    local auraY = startY - (#Buffadin.CLASSES * rowHeight) - 8
    local auraLabel = self.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    auraLabel:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, auraY - 6)
    auraLabel:SetText("Assigned Aura")
    auraLabel:SetTextColor(0.9, 0.8, 0.4)
    self.auraRowLabel = auraLabel
end

-- =========================================================================
-- Interactive Cells (Blessing Grid)
-- =========================================================================
function Frame:GetOrCreateCell(pallyIdx, classId)
    if not self.cells[pallyIdx] then
        self.cells[pallyIdx] = {}
    end
    if self.cells[pallyIdx][classId] then
        return self.cells[pallyIdx][classId]
    end

    local btn = CreateFrame("Button", nil, self.content, "BackdropTemplate")
    btn:SetSize(52, 28)
    Buffadin.Theme:ApplyCardBackdrop(btn, 0.80, 0.60)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    btn:SetScript("OnClick", function(self, mouseBtn)
        local canEdit = Buffadin.Roster:CanEditAssignments()
        if not canEdit then
            Buffadin:Print("Only the Raid Leader or Raid Assistant can change assignments.")
            return
        end

        local pallyName = self.pallyName
        local cid = self.classId
        if not pallyName or not cid then return end

        local step = (mouseBtn == "RightButton") and -1 or 1
        Buffadin.Assignments:CycleGreater(pallyName, cid, step)
    end)

    btn:EnableMouseWheel(true)
    btn:SetScript("OnMouseWheel", function(self, delta)
        local canEdit = Buffadin.Roster:CanEditAssignments()
        if not canEdit then
            Buffadin:Print("Only the Raid Leader, Raid Assistant, or Tanks can change assignments.")
            return
        end

        local pallyName = self.pallyName
        local cid = self.classId
        if not pallyName or not cid then return end

        local step = (delta > 0) and 1 or -1
        Buffadin.Assignments:CycleGreater(pallyName, cid, step)
    end)

    btn:SetScript("OnEnter", function(self)
        local pallyName = self.pallyName
        local cid = self.classId
        if not pallyName or not cid then return end

        local gIndex = Buffadin.Assignments:GetGreater(pallyName, cid)
        local gInfo = Buffadin.GREATER_BLESSINGS[gIndex]
        local cls = Buffadin.CLASS_BY_ID[cid]

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine((cls and cls.name or "Class") .. " - " .. pallyName, 1, 1, 1)
        GameTooltip:AddLine("Assigned: " .. (gInfo and gInfo.name or "None"), 0.9, 0.8, 0.4)

        if not Buffadin.Roster:CanEditAssignments() then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffff4444[Locked]|r Only Raid Leader/Assist/Tanks can edit.", 1, 0.3, 0.3)
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Left-Click / Scroll Up:|r Next Blessing", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Right-Click / Scroll Down:|r Previous Blessing", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.cells[pallyIdx][classId] = btn
    return btn
end

function Frame:GetOrCreateAuraCell(pallyIdx)
    if self.auraCells[pallyIdx] then
        return self.auraCells[pallyIdx]
    end

    local btn = CreateFrame("Button", nil, self.content, "BackdropTemplate")
    btn:SetSize(52, 28)
    Buffadin.Theme:ApplyCardBackdrop(btn, 0.80, 0.60)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    btn:SetScript("OnClick", function(self, mouseBtn)
        local canEdit = Buffadin.Roster:CanEditAssignments()
        if not canEdit then
            Buffadin:Print("Only the Raid Leader or Raid Assistant can change assignments.")
            return
        end

        local pallyName = self.pallyName
        if not pallyName then return end

        local step = (mouseBtn == "RightButton") and -1 or 1
        Buffadin.Assignments:CycleAura(pallyName, step)
    end)

    btn:EnableMouseWheel(true)
    btn:SetScript("OnMouseWheel", function(self, delta)
        local canEdit = Buffadin.Roster:CanEditAssignments()
        if not canEdit then
            Buffadin:Print("Only the Raid Leader, Raid Assistant, or Tanks can change assignments.")
            return
        end

        local pallyName = self.pallyName
        if not pallyName then return end

        local step = (delta > 0) and 1 or -1
        Buffadin.Assignments:CycleAura(pallyName, step)
    end)

    btn:SetScript("OnEnter", function(self)
        local pallyName = self.pallyName
        if not pallyName then return end

        local auraIndex = Buffadin.Assignments:GetAura(pallyName)
        local aInfo = Buffadin.AURAS[auraIndex]

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Aura - " .. pallyName, 1, 1, 1)
        GameTooltip:AddLine("Assigned: " .. (aInfo and aInfo.name or "None"), 0.9, 0.8, 0.4)

        if not Buffadin.Roster:CanEditAssignments() then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffff4444[Locked]|r Only Raid Leader/Assist/Tanks can edit.", 1, 0.3, 0.3)
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Left-Click / Scroll Up:|r Next Aura", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Right-Click / Scroll Down:|r Previous Aura", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.auraCells[pallyIdx] = btn
    return btn
end

-- =========================================================================
-- Bottom Action Bar
-- =========================================================================
function Frame:CreateBottomBar()
    local parent = self.Inset or self

    -- Auto-Assign Button
    local autoBtn = CreateFrame("Button", "Buffadin_AutoAssignBtn", parent, "UIPanelButtonTemplate")
    autoBtn:SetSize(110, 24)
    autoBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 12, 10)
    Buffadin.Theme:StyleButton(autoBtn, "Auto-Assign")
    autoBtn:SetScript("OnClick", function()
        Buffadin.Assignments:AutoAssign()
    end)
    self.autoAssignBtn = autoBtn

    -- Clear Button
    local clearBtn = CreateFrame("Button", "Buffadin_ClearBtn", parent, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 24)
    clearBtn:SetPoint("LEFT", autoBtn, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(clearBtn, "Clear")
    clearBtn:SetScript("OnClick", function()
        Buffadin.Assignments:ClearAll()
    end)
    self.clearBtn = clearBtn

    -- Report Button
    local reportBtn = CreateFrame("Button", "Buffadin_ReportBtn", parent, "UIPanelButtonTemplate")
    reportBtn:SetSize(90, 24)
    reportBtn:SetPoint("LEFT", clearBtn, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(reportBtn, "Report")
    reportBtn:SetScript("OnClick", function()
        Buffadin.Assignments:Report()
    end)
    self.reportBtn = reportBtn

    -- Free Assign Checkbox
    local freeCheck = CreateFrame("CheckButton", "Buffadin_FreeAssignCheck", parent, "UICheckButtonTemplate")
    freeCheck:SetSize(22, 22)
    freeCheck:SetPoint("LEFT", reportBtn, "RIGHT", 12, 0)
    freeCheck.text = _G[freeCheck:GetName() .. "Text"]
    if freeCheck.text then
        freeCheck.text:SetFontObject(GameFontNormalSmall)
        freeCheck.text:SetText("Free Assign")
    end
    freeCheck:SetScript("OnClick", function(self)
        local canEdit = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or not IsInGroup()
        if not canEdit then
            self:SetChecked(Buffadin.db.profile.freeAssign)
            Buffadin:Print("Only the Raid Leader or Assistant can toggle Free Assign.")
            return
        end
        local isChecked = self:GetChecked()
        Buffadin.db.profile.freeAssign = isChecked
        Buffadin:SendComm(Buffadin.COMM_PREFIX, "FREEASSIGN;" .. (isChecked and "1" or "0"))
        Buffadin.ManagerFrame:UpdateGrid()
        Buffadin:Print("Free Assign mode: " .. (isChecked and "|cff00ff00Enabled|r" or "|cffff4444Disabled|r"))
    end)
    self.freeAssignCheck = freeCheck

    -- Options Button
    local optBtn = CreateFrame("Button", "Buffadin_OptionsBtn", parent, "UIPanelButtonTemplate")
    optBtn:SetSize(80, 24)
    optBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 10)
    Buffadin.Theme:StyleButton(optBtn, "Options")
    optBtn:SetScript("OnClick", function()
        if Buffadin.OptionsFrame:IsShown() then
            Buffadin.OptionsFrame:Hide()
        else
            Buffadin.OptionsFrame:Show()
        end
    end)
    self.optionsBtn = optBtn
end

-- =========================================================================
-- Grid Update & Refresh
-- =========================================================================
function Frame:UpdateGrid()
    local paladins = Buffadin.Roster.sortedPaladins
    local pallyCount = math.max(1, #paladins)

    -- Update permission status badge
    local canEdit = Buffadin.Roster:CanEditAssignments()
    if canEdit then
        if not Buffadin:IsInRaid() then
            self.permText:SetText("|cff00ff00Party Mode|r")
        elseif Buffadin.db.profile.freeAssign then
            self.permText:SetText("|cff00ff00Free Assign Active|r")
        elseif not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            self.permText:SetText("|cff00ccffTank Access|r")
        else
            self.permText:SetText("|cff00ccffLeader/Assist Mode|r")
        end
        self.autoAssignBtn:Enable()
        self.clearBtn:Enable()
    else
        self.permText:SetText("|cffff4444Read-Only Mode|r")
        self.autoAssignBtn:Disable()
        self.clearBtn:Disable()
    end

    if self.freeAssignCheck then
        self.freeAssignCheck:SetChecked(Buffadin.db.profile.freeAssign)
    end

    local startX = 140
    local colWidth = 60
    local startY = -40
    local rowHeight = 32

    -- Hide all existing header text and cells
    for _, h in pairs(self.pallyHeaders) do h:Hide() end

    for pIdx = 1, pallyCount do
        local pallyName = paladins[pIdx] or UnitName("player")
        local colX = startX + ((pIdx - 1) * colWidth)

        -- Paladin Column Header
        local header = self.pallyHeaders[pIdx]
        if not header then
            header = self.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            self.pallyHeaders[pIdx] = header
        end
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", self.content, "TOPLEFT", colX, -16)
        header:SetWidth(colWidth - 4)
        header:SetJustifyH("CENTER")
        header:SetWordWrap(false)
        local shortName = pallyName:gsub("%-.+", "")
        header:SetText(shortName)
        header:SetTextColor(0.95, 0.82, 0.3)
        header:Show()

        -- Blessing Cells per Class
        for _, cls in ipairs(Buffadin.CLASSES) do
            local cell = self:GetOrCreateCell(pIdx, cls.id)
            cell.pallyName = pallyName
            cell.classId = cls.id
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", self.content, "TOPLEFT", colX, startY - ((cls.id - 1) * rowHeight))
            cell:Show()

            local gIndex = Buffadin.Assignments:GetGreater(pallyName, cls.id)
            local gInfo = Buffadin.GREATER_BLESSINGS[gIndex]
            if gInfo and gInfo.spellId > 0 then
                cell.icon:SetTexture(gInfo.icon)
                cell.icon:SetDesaturated(false)
                Buffadin.Theme:SetBorderStatus(cell, "Good")
            else
                cell.icon:SetTexture(Buffadin.GREATER_BLESSINGS[0].icon)
                cell.icon:SetDesaturated(true)
                Buffadin.Theme:SetBorderStatus(cell, "Disabled")
            end
        end

        -- Aura Cell
        local auraCell = self:GetOrCreateAuraCell(pIdx)
        auraCell.pallyName = pallyName
        auraCell:ClearAllPoints()
        local auraY = startY - (#Buffadin.CLASSES * rowHeight) - 8
        auraCell:SetPoint("TOPLEFT", self.content, "TOPLEFT", colX, auraY)
        auraCell:Show()

        local aIndex = Buffadin.Assignments:GetAura(pallyName)
        local aInfo = Buffadin.AURAS[aIndex]
        if aInfo and aInfo.spellId > 0 then
            auraCell.icon:SetTexture(aInfo.icon)
            auraCell.icon:SetDesaturated(false)
            Buffadin.Theme:SetBorderStatus(auraCell, "Good")
        else
            auraCell.icon:SetTexture(Buffadin.AURAS[0].icon)
            auraCell.icon:SetDesaturated(true)
            Buffadin.Theme:SetBorderStatus(auraCell, "Disabled")
        end
    end

    -- Hide cells for columns beyond current Paladin count
    for pIdx = pallyCount + 1, #self.cells do
        for _, cell in pairs(self.cells[pIdx] or {}) do
            cell:Hide()
        end
        if self.auraCells[pIdx] then
            self.auraCells[pIdx]:Hide()
        end
    end

    -- Update content width for scroll frame
    local totalWidth = startX + (pallyCount * colWidth) + 20
    self.content:SetWidth(math.max(580, totalWidth))

    if self.drawer and self.drawer:IsShown() then
        self:UpdateOverridesDrawer()
    end
end

-- Close drawer when main frame closes
Frame:SetScript("OnHide", function(self)
    if self.drawer then
        self.drawer:Hide()
    end
end)

-- =========================================================================
-- Class Overrides Drawer (Side-panel for single-player overrides & tanks)
-- =========================================================================
function Frame:ToggleClassOverridesDrawer(classId)
    if not self.drawer then
        self:CreateOverridesDrawer()
    end

    if self.drawer:IsShown() and self.drawer.currentClassId == classId then
        self.drawer:Hide()
        return
    end

    self.drawer.currentClassId = classId
    self:UpdateOverridesDrawer()
    self.drawer:Show()
end

function Frame:CreateOverridesDrawer()
    local drawer = CreateFrame("Frame", "Buffadin_ManagerOverridesDrawer", self, "ButtonFrameTemplate")
    drawer:SetSize(250, 480)
    drawer:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0)
    drawer:SetClampedToScreen(true)

    Buffadin.Theme:StyleWindow(drawer, "Class Overrides", "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings")

    local parent = drawer.Inset or drawer

    -- Quick Tank Presets Label & Container
    local tankLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tankLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -8)
    tankLabel:SetText("Quick Tank Presets:")
    drawer.tankLabel = tankLabel

    local btnSanc = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnSanc:SetSize(68, 22)
    btnSanc:SetPoint("TOPLEFT", tankLabel, "BOTTOMLEFT", 0, -4)
    Buffadin.Theme:StyleButton(btnSanc, "Sanctuary")
    drawer.btnSanc = btnSanc

    local btnMight = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnMight:SetSize(52, 22)
    btnMight:SetPoint("LEFT", btnSanc, "RIGHT", 4, 0)
    Buffadin.Theme:StyleButton(btnMight, "Might")
    drawer.btnMight = btnMight

    local btnKings = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnKings:SetSize(52, 22)
    btnKings:SetPoint("LEFT", btnMight, "RIGHT", 4, 0)
    Buffadin.Theme:StyleButton(btnKings, "Kings")
    drawer.btnKings = btnKings

    -- Tank Presets Click Handlers
    local function SetAllTanksInClass(nIndex)
        local cid = drawer.currentClassId
        if not cid then return end
        local pallyName = UnitName("player")
        local units = Buffadin.Roster.classes[cid] or {}
        local found = false
        for _, u in ipairs(units) do
            if u.isTank then
                Buffadin.Assignments:SetNormal(pallyName, cid, u.name, nIndex)
                found = true
            end
        end
        if not found and #units > 0 then
            Buffadin.Assignments:SetNormal(pallyName, cid, units[1].name, nIndex)
        end
        Frame:UpdateOverridesDrawer()
    end

    btnSanc:SetScript("OnClick", function() SetAllTanksInClass(6) end) -- Sanctuary = 6
    btnMight:SetScript("OnClick", function() SetAllTanksInClass(2) end) -- Might = 2
    btnKings:SetScript("OnClick", function() SetAllTanksInClass(3) end) -- Kings = 3

    -- Scroll Frame for Player Rows
    local scrollFrame = CreateFrame("ScrollFrame", "Buffadin_DrawerScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -26, 36)
    drawer.scrollFrame = scrollFrame

    local content = CreateFrame("Frame", "Buffadin_DrawerContent", scrollFrame)
    content:SetSize(210, 350)
    scrollFrame:SetScrollChild(content)
    drawer.content = content

    drawer.rows = {}

    -- Clear Overrides Button at bottom
    local clearBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    clearBtn:SetSize(110, 24)
    clearBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 8)
    Buffadin.Theme:StyleButton(clearBtn, "Clear Overrides")
    clearBtn:SetScript("OnClick", function()
        local cid = drawer.currentClassId
        if not cid then return end
        local pallyName = UnitName("player")
        local units = Buffadin.Roster.classes[cid] or {}
        for _, u in ipairs(units) do
            Buffadin.Assignments:SetNormal(pallyName, cid, u.name, 0)
        end
        Frame:UpdateOverridesDrawer()
    end)
    drawer.clearBtn = clearBtn

    self.drawer = drawer
end

function Frame:UpdateOverridesDrawer()
    if not self.drawer or not self.drawer.currentClassId then return end
    local cid = self.drawer.currentClassId
    local cls = Buffadin.CLASS_BY_ID[cid]
    local clsName = cls and cls.name or "Class"

    if self.drawer.TitleText then
        self.drawer.TitleText:SetText(clsName .. " Overrides")
    end

    local pallyName = UnitName("player")
    local units = Buffadin.Roster.classes[cid] or {}

    -- Show/hide tank preset section
    local hasTank = false
    for _, u in ipairs(units) do
        if u.isTank then hasTank = true; break end
    end
    if hasTank or cid == 1 or cid == 2 or cid == 9 then
        self.drawer.tankLabel:Show()
        self.drawer.btnSanc:Show()
        self.drawer.btnMight:Show()
        self.drawer.btnKings:Show()
        self.drawer.scrollFrame:SetPoint("TOPLEFT", self.drawer.Inset or self.drawer, "TOPLEFT", 6, -60)
    else
        self.drawer.tankLabel:Hide()
        self.drawer.btnSanc:Hide()
        self.drawer.btnMight:Hide()
        self.drawer.btnKings:Hide()
        self.drawer.scrollFrame:SetPoint("TOPLEFT", self.drawer.Inset or self.drawer, "TOPLEFT", 6, -10)
    end

    local rowHeight = 30
    local yOffset = -4

    for i, unitInfo in ipairs(units) do
        local row = self.drawer.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, self.drawer.content, "BackdropTemplate")
            row:SetSize(200, 26)
            Buffadin.Theme:ApplyCardBackdrop(row, 0.40, 0.20)

            -- Player name text
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("LEFT", 6, 0)
            nameText:SetWidth(125)
            nameText:SetJustifyH("LEFT")
            nameText:SetWordWrap(false)
            row.nameText = nameText

            -- Override Cell
            local cell = CreateFrame("Button", nil, row, "BackdropTemplate")
            cell:SetSize(24, 24)
            cell:SetPoint("RIGHT", -4, 0)
            Buffadin.Theme:ApplyCardBackdrop(cell, 0.80, 0.60)
            cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            local icon = cell:CreateTexture(nil, "ARTWORK")
            icon:SetSize(18, 18)
            icon:SetPoint("CENTER", 0, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            cell.icon = icon

            cell:SetScript("OnClick", function(self, mouseBtn)
                if not self.unitName or not self.classId then return end
                if IsShiftKeyDown() then
                    Buffadin.Assignments:SetNormal(pallyName, self.classId, self.unitName, 0)
                else
                    local step = (mouseBtn == "RightButton") and -1 or 1
                    Buffadin.Assignments:CycleNormal(pallyName, self.classId, self.unitName, step)
                end
                Frame:UpdateOverridesDrawer()
            end)

            cell:EnableMouseWheel(true)
            cell:SetScript("OnMouseWheel", function(self, delta)
                if not self.unitName or not self.classId then return end
                local canEdit = Buffadin.Roster:CanEditAssignments()
                if not canEdit then return end
                local step = (delta > 0) and 1 or -1
                Buffadin.Assignments:CycleNormal(pallyName, self.classId, self.unitName, step)
                Frame:UpdateOverridesDrawer()
            end)

            cell:SetScript("OnEnter", function(self)
                if not self.unitName or not self.classId then return end
                local nIndex = Buffadin.Assignments:GetNormal(pallyName, self.classId, self.unitName)
                local nConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
                local gIndex = Buffadin.Assignments:GetGreater(pallyName, self.classId)
                local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]

                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(self.unitName .. " - Blessing Override", 0.95, 0.82, 0.3)
                if nIndex > 0 and nConfig then
                    GameTooltip:AddLine("Override: |cff00ccff" .. nConfig.name .. "|r", 1, 1, 1)
                else
                    GameTooltip:AddLine("Default: |cffaaaaaa" .. (gConfig and gConfig.name or "None") .. "|r", 1, 1, 1)
                end
                if self.isTank then
                    GameTooltip:AddLine("|cffffaa00[Tank]:|r Override to Might/Sanctuary to avoid Salvation!", 1, 0.8, 0)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ff00Left-Click / Scroll Up:|r Next Override", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cff00ff00Right-Click / Scroll Down:|r Previous Override", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cff00ff00Shift-Click:|r Reset to Default", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function() GameTooltip:Hide() end)

            row.cell = cell
            self.drawer.rows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.drawer.content, "TOPLEFT", 4, yOffset)
        row:Show()

        local displayName = unitInfo.name
        if unitInfo.isTank then
            displayName = displayName .. " |cff00ccff[Tank]|r"
        end
        row.nameText:SetText(displayName)
        local r, g, b = Buffadin.Theme:GetClassColor(unitInfo.classToken)
        row.nameText:SetTextColor(r, g, b)

        row.cell.classId = cid
        row.cell.unitName = unitInfo.name
        row.cell.isTank = unitInfo.isTank

        local nIndex = Buffadin.Assignments:GetNormal(pallyName, cid, unitInfo.name)
        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            row.cell.icon:SetTexture(Buffadin.NORMAL_BLESSINGS[nIndex].icon)
            row.cell.icon:SetDesaturated(false)
            Buffadin.Theme:SetBorderStatus(row.cell, "Special")
        else
            row.cell.icon:SetTexture(Buffadin.NORMAL_BLESSINGS[0].icon)
            row.cell.icon:SetDesaturated(true)
            Buffadin.Theme:SetBorderStatus(row.cell, "Disabled")
        end

        yOffset = yOffset - rowHeight
    end

    -- Hide extra rows
    for i = #units + 1, #self.drawer.rows do
        self.drawer.rows[i]:Hide()
    end

    self.drawer.content:SetHeight(math.max(100, math.abs(yOffset) + 10))
end
