local addonName, Buffadin = ...

Buffadin.MockHarness = {}
local Mock = Buffadin.MockHarness

Mock.active = false
Mock.currentPreset = "SOLO"
Mock.simulatedCombat = false
Mock.buffStates = {} -- [unitId] = { hasBuff = bool, expires = timestamp, duration = number }

-- =========================================================================
-- Synthetic Roster Definitions
-- =========================================================================

local function CreateMockUnit(unitId, name, classToken, isTank)
    local clsConfig = Buffadin.CLASS_BY_TOKEN[classToken]
    local cid = clsConfig and clsConfig.id or 1
    return {
        unitId = unitId,
        name = name,
        fullName = name .. "-MockServer",
        classToken = classToken,
        classId = cid,
        isTank = isTank or false,
        isDead = false,
        isOnline = true,
        isVisible = true,
    }
end

function Mock:GetPartyRoster()
    local playerName = UnitName("player") or "Player"
    return {
        units = {
            CreateMockUnit("player", playerName, "PALADIN", false),
            CreateMockUnit("party1", "Gorok", "WARRIOR", true),       -- Tank
            CreateMockUnit("party2", "Pyromaniac", "MAGE", false),
            CreateMockUnit("party3", "Shadowstep", "ROGUE", false),
            CreateMockUnit("party4", "Holyheals", "PRIEST", false),
        },
        paladins = {
            { name = playerName .. "-MockServer", isPlayer = true, isLeader = true, isAssist = false },
        },
    }
end

function Mock:GetRaid25Roster()
    local playerName = UnitName("player") or "Player"
    return {
        units = {
            -- Paladins (3)
            CreateMockUnit("player", playerName, "PALADIN", false),
            CreateMockUnit("raid1", "Uther", "PALADIN", false),
            CreateMockUnit("raid2", "Tirion", "PALADIN", false),
            -- Tanks (2)
            CreateMockUnit("raid3", "Gorok", "WARRIOR", true),        -- Main Tank
            CreateMockUnit("raid4", "Ironbark", "DRUID", true),       -- Off Tank
            -- Warriors (3)
            CreateMockUnit("raid5", "Bladestorm", "WARRIOR", false),
            CreateMockUnit("raid6", "Rend", "WARRIOR", false),
            CreateMockUnit("raid7", "Execute", "WARRIOR", false),
            -- Rogues (3)
            CreateMockUnit("raid8", "Shadowstep", "ROGUE", false),
            CreateMockUnit("raid9", "Sneak", "ROGUE", false),
            CreateMockUnit("raid10", "Daggerfall", "ROGUE", false),
            -- Mages (3)
            CreateMockUnit("raid11", "Pyromaniac", "MAGE", false),
            CreateMockUnit("raid12", "Frostbite", "MAGE", false),
            CreateMockUnit("raid13", "Arcanist", "MAGE", false),
            -- Warlocks (3)
            CreateMockUnit("raid14", "Doombringer", "WARRIOR", false),
            CreateMockUnit("raid15", "Chaosbolt", "WARLOCK", false),
            CreateMockUnit("raid16", "Felhound", "WARLOCK", false),
            -- Hunters (3)
            CreateMockUnit("raid17", "Aimshot", "HUNTER", false),
            CreateMockUnit("raid18", "Trueshot", "HUNTER", false),
            CreateMockUnit("raid19", "Beastmaster", "HUNTER", false),
            -- Priests (3)
            CreateMockUnit("raid20", "Holyheals", "PRIEST", false),
            CreateMockUnit("raid21", "Shadowform", "PRIEST", false),
            CreateMockUnit("raid22", "Discipline", "PRIEST", false),
            -- Druids (1 DPS/Heal)
            CreateMockUnit("raid23", "Moonkin", "DRUID", false),
            -- Shamans (2)
            CreateMockUnit("raid24", "Windfury", "SHAMAN", false),
            CreateMockUnit("raid25", "Chainheal", "SHAMAN", false),
        },
        paladins = {
            { name = playerName .. "-MockServer", isPlayer = true, isLeader = true, isAssist = false },
            { name = "Uther-MockServer", isPlayer = false, isLeader = false, isAssist = true },
            { name = "Tirion-MockServer", isPlayer = false, isLeader = false, isAssist = false },
        },
    }
end

function Mock:GetRaid40Roster()
    local playerName = UnitName("player") or "Player"
    local list = {
        -- Paladins (4)
        CreateMockUnit("player", playerName, "PALADIN", false),
        CreateMockUnit("raid1", "Uther", "PALADIN", false),
        CreateMockUnit("raid2", "Tirion", "PALADIN", false),
        CreateMockUnit("raid3", "Turalyon", "PALADIN", false),
        -- Tanks (3)
        CreateMockUnit("raid4", "Gorok", "WARRIOR", true),        -- Main Tank
        CreateMockUnit("raid5", "Stonecleave", "WARRIOR", true),  -- Off Tank 1
        CreateMockUnit("raid6", "Ironbark", "DRUID", true),       -- Off Tank 2
        -- Warriors DPS (5)
        CreateMockUnit("raid7", "Bladestorm", "WARRIOR", false),
        CreateMockUnit("raid8", "Rend", "WARRIOR", false),
        CreateMockUnit("raid9", "Execute", "WARRIOR", false),
        CreateMockUnit("raid10", "Cleaver", "WARRIOR", false),
        CreateMockUnit("raid11", "Sundered", "WARRIOR", false),
        -- Rogues (5)
        CreateMockUnit("raid12", "Shadowstep", "ROGUE", false),
        CreateMockUnit("raid13", "Sneak", "ROGUE", false),
        CreateMockUnit("raid14", "Daggerfall", "ROGUE", false),
        CreateMockUnit("raid15", "Backstab", "ROGUE", false),
        CreateMockUnit("raid16", "Ambush", "ROGUE", false),
        -- Mages (5)
        CreateMockUnit("raid17", "Pyromaniac", "MAGE", false),
        CreateMockUnit("raid18", "Frostbite", "MAGE", false),
        CreateMockUnit("raid19", "Arcanist", "MAGE", false),
        CreateMockUnit("raid20", "Ignite", "MAGE", false),
        CreateMockUnit("raid21", "Blizzard", "MAGE", false),
        -- Warlocks (4)
        CreateMockUnit("raid22", "Doombringer", "WARLOCK", false),
        CreateMockUnit("raid23", "Chaosbolt", "WARLOCK", false),
        CreateMockUnit("raid24", "Felhound", "WARLOCK", false),
        CreateMockUnit("raid25", "Soulfire", "WARLOCK", false),
        -- Hunters (4)
        CreateMockUnit("raid26", "Aimshot", "HUNTER", false),
        CreateMockUnit("raid27", "Trueshot", "HUNTER", false),
        CreateMockUnit("raid28", "Beastmaster", "HUNTER", false),
        CreateMockUnit("raid29", "MultiShot", "HUNTER", false),
        -- Priests (5)
        CreateMockUnit("raid30", "Holyheals", "PRIEST", false),
        CreateMockUnit("raid31", "Shadowform", "PRIEST", false),
        CreateMockUnit("raid32", "Discipline", "PRIEST", false),
        CreateMockUnit("raid33", "Powerword", "PRIEST", false),
        CreateMockUnit("raid34", "Renew", "PRIEST", false),
        -- Druids (3)
        CreateMockUnit("raid35", "Moonkin", "DRUID", false),
        CreateMockUnit("raid36", "Regrowth", "DRUID", false),
        CreateMockUnit("raid37", "Tranquil", "DRUID", false),
        -- Shamans (3)
        CreateMockUnit("raid38", "Windfury", "SHAMAN", false),
        CreateMockUnit("raid39", "Chainheal", "SHAMAN", false),
        CreateMockUnit("raid40", "Bloodlust", "SHAMAN", false),
    }

    return {
        units = list,
        paladins = {
            { name = playerName .. "-MockServer", isPlayer = true, isLeader = true, isAssist = false },
            { name = "Uther-MockServer", isPlayer = false, isLeader = false, isAssist = true },
            { name = "Tirion-MockServer", isPlayer = false, isLeader = false, isAssist = false },
            { name = "Turalyon-MockServer", isPlayer = false, isLeader = false, isAssist = false },
        },
    }
end

-- =========================================================================
-- State Management & Interception Hooks
-- =========================================================================

function Mock:InjectMockRoster(rosterData)
    Buffadin.Roster.units = {}
    Buffadin.Roster.paladins = {}
    Buffadin.Roster.sortedPaladins = {}
    Buffadin.Roster.totalCount = #rosterData.units
    Buffadin.Roster.paladinCount = #rosterData.paladins

    for _, cls in ipairs(Buffadin.CLASSES) do
        Buffadin.Roster.classes[cls.id] = {}
    end

    for _, u in ipairs(rosterData.units) do
        Buffadin.Roster.units[u.unitId] = u
        table.insert(Buffadin.Roster.classes[u.classId], u)

        -- Initialize mock buff state if not present
        if not self.buffStates[u.unitId] then
            self.buffStates[u.unitId] = {
                hasBuff = true,
                expires = GetTime() + 900,
                duration = 900,
            }
        end
    end

    for _, p in ipairs(rosterData.paladins) do
        Buffadin.Roster.paladins[p.name] = {
            name = p.name,
            unitId = p.isPlayer and "player" or "raid1",
            isPlayer = p.isPlayer,
            isLeader = p.isLeader,
            isAssist = p.isAssist,
            spells = {},
            hasKings = true,
            hasSanctuary = true,
            hasSalvation = true,
            hasLight = true,
            hasMight = true,
            hasWisdom = true,
        }
        table.insert(Buffadin.Roster.sortedPaladins, p.name)
        Buffadin.Assignments:EnsurePaladin(p.name)
    end
end

function Mock:ScanMockBuffs()
    local playerName = UnitName("player") or "Player"
    local now = GetTime()

    for classId, units in pairs(Buffadin.Roster.classes) do
        local gIndex = Buffadin.Assignments:GetGreater(playerName, classId)
        local nEquivIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0

        local totalAlive = 0
        local missingCount = 0
        local classMissingCount = 0
        local specialMissingCount = 0
        local minExpiration = 99999
        local hasSpecialMissing = false

        for _, unitInfo in ipairs(units) do
            totalAlive = totalAlive + 1

            local nIndex = Buffadin.Assignments:GetNormal(playerName, classId, unitInfo.name)
            local isSpecial = (nIndex and nIndex > 0)
            local state = self.buffStates[unitInfo.unitId] or { hasBuff = true, expires = now + 900, duration = 900 }

            local hasBuff = state.hasBuff
            local remaining = 0

            if hasBuff and state.expires and state.expires > now then
                remaining = math.max(0, state.expires - now)
                if remaining < minExpiration then
                    minExpiration = remaining
                end
            elseif hasBuff then
                remaining = 900
            else
                hasBuff = false
                remaining = 0
            end

            if not hasBuff then
                missingCount = missingCount + 1
                if isSpecial then
                    hasSpecialMissing = true
                    specialMissingCount = specialMissingCount + 1
                else
                    classMissingCount = classMissingCount + 1
                end
            end

            local assignedSpell = ""
            if isSpecial and Buffadin.NORMAL_BLESSINGS[nIndex] then
                assignedSpell = Buffadin.NORMAL_BLESSINGS[nIndex].name
            elseif gIndex > 0 and Buffadin.GREATER_BLESSINGS[gIndex] then
                assignedSpell = Buffadin.GREATER_BLESSINGS[gIndex].name
            end

            Buffadin.BuffScanner.unitStatus[unitInfo.unitId] = {
                hasBuff = hasBuff,
                expiration = remaining,
                assignedGSpellId = (gIndex > 0) and Buffadin.GREATER_BLESSINGS[gIndex].spellId or 0,
                assignedNSpellId = isSpecial and Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0,
                assignedSpellName = assignedSpell,
                isSpecial = isSpecial,
            }
        end

        local status = "Disabled"
        if gIndex == 0 and missingCount == 0 then
            status = "Disabled"
        elseif totalAlive == 0 then
            status = "Disabled"
        elseif missingCount == 0 then
            status = "Good"
        elseif classMissingCount == 0 and specialMissingCount > 0 then
            status = "Special"
        elseif missingCount == totalAlive then
            status = "All"
        elseif hasSpecialMissing then
            status = "Special"
        else
            status = "Some"
        end

        Buffadin.BuffScanner.classStatus[classId] = {
            status = status,
            missingCount = missingCount,
            classMissingCount = classMissingCount,
            specialMissingCount = specialMissingCount,
            totalCount = totalAlive,
            minExpiration = (minExpiration < 99999) and minExpiration or 0,
            assignedGSpell = gIndex,
            assignedNSpell = nEquivIndex,
        }
    end

    Buffadin.BuffScanner.selfStatus = {
        hasAura = true,
        auraSpellId = 465,
        hasRighteousFury = false,
        hasSeal = true,
        sealName = "Seal of Righteousness",
    }
end

function Mock:Enable(preset)
    if not self.origRosterUpdate then
        self.origRosterUpdate = Buffadin.Roster.Update
        self.origBuffScannerScan = Buffadin.BuffScanner.Scan
        self.origInCombat = Buffadin.InCombat
        self.origCanEdit = Buffadin.Roster.CanEditAssignments
    end

    self.active = true
    self.currentPreset = preset or "RAID40"

    -- Override Roster update
    Buffadin.Roster.Update = function(rosterSelf)
        if not Mock.active then
            return Mock.origRosterUpdate(rosterSelf)
        end
        local data
        if Mock.currentPreset == "PARTY" then
            data = Mock:GetPartyRoster()
        elseif Mock.currentPreset == "RAID25" then
            data = Mock:GetRaid25Roster()
        else
            data = Mock:GetRaid40Roster()
        end
        Mock:InjectMockRoster(data)
    end

    -- Override BuffScanner
    Buffadin.BuffScanner.Scan = function(scannerSelf)
        if not Mock.active then
            return Mock.origBuffScannerScan(scannerSelf)
        end
        Mock:ScanMockBuffs()
    end

    -- Override InCombat
    Buffadin.InCombat = function(bSelf)
        if Mock.active then
            return Mock.simulatedCombat
        end
        return Mock.origInCombat(bSelf)
    end

    -- Always allow editing in mock mode
    Buffadin.Roster.CanEditAssignments = function(rSelf)
        if Mock.active then return true end
        return Mock.origCanEdit(rSelf)
    end

    -- Pre-populate mock assignments if empty
    self:ApplyDefaultAssignments()

    -- Trigger update
    Buffadin.Roster:Update()
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:UpdateLayout()
    Buffadin.ManagerFrame:UpdateGrid()

    Buffadin:Print(string.format("Mock Test Harness active: |cff00ff00%s|r mode loaded.", self.currentPreset))
    self:UpdatePanelStatus()
end

function Mock:Disable()
    if not self.active then return end

    self.active = false
    self.currentPreset = "SOLO"
    self.simulatedCombat = false

    -- Restore original functions
    if self.origRosterUpdate then Buffadin.Roster.Update = self.origRosterUpdate end
    if self.origBuffScannerScan then Buffadin.BuffScanner.Scan = self.origBuffScannerScan end
    if self.origInCombat then Buffadin.InCombat = self.origInCombat end
    if self.origCanEdit then Buffadin.Roster.CanEditAssignments = self.origCanEdit end

    -- Restore real state
    Buffadin.Roster:Update()
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:UpdateLayout()
    Buffadin.ManagerFrame:UpdateGrid()

    Buffadin:Print("Mock Test Harness |cffff4444disabled|r. Reverted to live game state.")
    self:UpdatePanelStatus()
end

function Mock:SetPreset(preset)
    self:Enable(preset)
end

-- =========================================================================
-- Simulation Actions (Buff states, overrides, combat)
-- =========================================================================

function Mock:ApplyDefaultAssignments()
    local pallys = Buffadin.Roster.sortedPaladins
    local p1 = pallys[1]
    local p2 = pallys[2]
    local p3 = pallys[3]
    local p4 = pallys[4]

    -- P1 (Player): Might on melee, Kings on druid, Wisdom on hunter
    if p1 then
        Buffadin.Assignments:SetGreater(p1, 1, 2, true) -- Warrior = Might
        Buffadin.Assignments:SetGreater(p1, 4, 2, true) -- Rogue = Might
        Buffadin.Assignments:SetGreater(p1, 3, 1, true) -- Hunter = Wisdom
        Buffadin.Assignments:SetGreater(p1, 9, 3, true) -- Druid = Kings
        Buffadin.Assignments:SetAura(p1, 1, true)       -- Devotion Aura
    end

    -- P2 (Uther): Salvation on casters & ranged
    if p2 then
        Buffadin.Assignments:SetGreater(p2, 1, 4, true) -- Warrior = Salvation (DPS)
        Buffadin.Assignments:SetGreater(p2, 7, 4, true) -- Mage = Salvation
        Buffadin.Assignments:SetGreater(p2, 8, 4, true) -- Warlock = Salvation
        Buffadin.Assignments:SetGreater(p2, 5, 4, true) -- Priest = Salvation
        Buffadin.Assignments:SetAura(p2, 2, true)       -- Retribution Aura
    end

    -- P3 (Tirion): Kings & Sanctuary
    if p3 then
        Buffadin.Assignments:SetGreater(p3, 7, 1, true) -- Mage = Wisdom
        Buffadin.Assignments:SetGreater(p3, 8, 1, true) -- Warlock = Wisdom
        Buffadin.Assignments:SetGreater(p3, 5, 1, true) -- Priest = Wisdom
        Buffadin.Assignments:SetAura(p3, 3, true)       -- Concentration Aura
    end

    -- P4 (Turalyon): Light
    if p4 then
        Buffadin.Assignments:SetGreater(p4, 2, 5, true) -- Paladin = Light
        Buffadin.Assignments:SetAura(p4, 5, true)       -- Fire Resistance Aura
    end
end

function Mock:BuffAll(duration)
    duration = duration or 900
    local now = GetTime()
    for _, u in pairs(Buffadin.Roster.units) do
        self.buffStates[u.unitId] = {
            hasBuff = true,
            expires = now + duration,
            duration = duration,
        }
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    Buffadin:Print("Mock: Applied 15-minute buffs to all members.")
end

function Mock:SetRandomMissing()
    local count = 0
    for _, u in pairs(Buffadin.Roster.units) do
        if u.classId == 1 or u.classId == 7 or math.random() > 0.65 then
            self.buffStates[u.unitId] = {
                hasBuff = false,
                expires = 0,
                duration = 0,
            }
            count = count + 1
        end
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    Buffadin:Print(string.format("Mock: Dropped buffs on %d players (check red missing counts).", count))
end

function Mock:SetExpiring()
    local now = GetTime()
    for _, u in pairs(Buffadin.Roster.units) do
        if u.classId == 4 then -- Rogues expiring in 45s
            self.buffStates[u.unitId] = {
                hasBuff = true,
                expires = now + 45,
                duration = 900,
            }
        elseif u.classId == 3 then -- Hunters expiring in 110s
            self.buffStates[u.unitId] = {
                hasBuff = true,
                expires = now + 110,
                duration = 900,
            }
        end
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    Buffadin:Print("Mock: Set Rogues (45s) and Hunters (110s) as expiring.")
end

function Mock:ToggleTankOverride()
    local pallyName = UnitName("player") or "Player"
    local current = Buffadin.Assignments:GetNormal(pallyName, 1, "Gorok")

    if current == 6 then
        Buffadin.Assignments:SetNormal(pallyName, 1, "Gorok", 0)
        Buffadin:Print("Mock: Cleared Tank override on Gorok (reset to class default).")
    else
        Buffadin.Assignments:SetNormal(pallyName, 1, "Gorok", 6) -- Sanctuary = 6
        Buffadin:Print("Mock: Set Gorok (Tank) override to [Blessing of Sanctuary]!")
    end

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.ManagerFrame:IsShown() then
        Buffadin.ManagerFrame:UpdateGrid()
    end
end

function Mock:SimulateCast()
    local targetUnit, gSpellId, nSpellId, isGreater, classId, reason = Buffadin.BuffScanner:GetNextAutoBuff()

    if not targetUnit then
        Buffadin:Print("Mock: All buffs are active! No auto-buff target needed.")
        return
    end

    local now = GetTime()
    if isGreater and classId then
        -- Refresh all units of this class
        local units = Buffadin.Roster.classes[classId] or {}
        for _, u in ipairs(units) do
            local uStatus = Buffadin.BuffScanner.unitStatus[u.unitId]
            if not uStatus or not uStatus.isSpecial then
                self.buffStates[u.unitId] = {
                    hasBuff = true,
                    expires = now + 900,
                    duration = 900,
                }
            end
        end
        local cls = Buffadin.CLASS_BY_ID[classId]
        Buffadin:Print(string.format("Mock: Simulated Greater Blessing cast on %s class! (Reason: %s)", cls and cls.name or "Class", reason or ""))
    else
        -- Single target override
        self.buffStates[targetUnit] = {
            hasBuff = true,
            expires = now + 900,
            duration = 900,
        }
        local uInfo = Buffadin.Roster.units[targetUnit]
        Buffadin:Print(string.format("Mock: Simulated single-target Blessing on %s! (Reason: %s)", uInfo and uInfo.name or targetUnit, reason or ""))
    end

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
end

function Mock:ToggleCombat()
    self.simulatedCombat = not self.simulatedCombat

    if self.simulatedCombat then
        Buffadin:Print("Mock: Simulated |cffff4444COMBAT START|r (checking combat lockdown handling).")
        if Buffadin.db and Buffadin.db.profile.hideInCombat then
            Buffadin.BlessingsBar:Hide()
        end
    else
        Buffadin:Print("Mock: Simulated |cff00ff00COMBAT END|r (processing queued changes).")
        Buffadin:ProcessCombatQueue()
        Buffadin.BlessingsBar:UpdateLayout()
        Buffadin.ManagerFrame:UpdateGrid()
    end

    self:UpdatePanelStatus()
end

-- =========================================================================
-- Floating Dev Control Panel UI
-- =========================================================================

function Mock:CreateControlPanel()
    if self.panel then return self.panel end

    local panel = CreateFrame("Frame", "Buffadin_MockControlPanel", UIParent, "BackdropTemplate")
    panel:SetSize(340, 240)
    panel:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)

    Buffadin.Theme:ApplyCardBackdrop(panel, 0.95, 0.85)

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cffF58CBABuffadin|r Dev Test Harness")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- Status Text
    local statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", 14, -36)
    statusText:SetTextColor(0.8, 0.8, 0.8)
    panel.statusText = statusText

    -- Section 1: Presets
    local lblPresets = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblPresets:SetPoint("TOPLEFT", 14, -58)
    lblPresets:SetText("Roster Environments:")

    local btnParty = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnParty:SetSize(72, 22)
    btnParty:SetPoint("TOPLEFT", 14, -76)
    Buffadin.Theme:StyleButton(btnParty, "Party (5)")
    btnParty:SetScript("OnClick", function() Mock:SetPreset("PARTY") end)

    local btnRaid25 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnRaid25:SetSize(72, 22)
    btnRaid25:SetPoint("LEFT", btnParty, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnRaid25, "Raid (25)")
    btnRaid25:SetScript("OnClick", function() Mock:SetPreset("RAID25") end)

    local btnRaid40 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnRaid40:SetSize(72, 22)
    btnRaid40:SetPoint("LEFT", btnRaid25, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnRaid40, "Raid (40)")
    btnRaid40:SetScript("OnClick", function() Mock:SetPreset("RAID40") end)

    local btnLive = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnLive:SetSize(72, 22)
    btnLive:SetPoint("LEFT", btnRaid40, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnLive, "Live Mode")
    btnLive:SetScript("OnClick", function() Mock:Disable() end)

    -- Section 2: Buff States
    local lblBuffs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblBuffs:SetPoint("TOPLEFT", 14, -108)
    lblBuffs:SetText("Buff Simulation:")

    local btnBuffAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnBuffAll:SetSize(95, 22)
    btnBuffAll:SetPoint("TOPLEFT", 14, -126)
    Buffadin.Theme:StyleButton(btnBuffAll, "Buff All (15m)")
    btnBuffAll:SetScript("OnClick", function() Mock:BuffAll(900) end)

    local btnMissing = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnMissing:SetSize(100, 22)
    btnMissing:SetPoint("LEFT", btnBuffAll, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnMissing, "Random Missing")
    btnMissing:SetScript("OnClick", function() Mock:SetRandomMissing() end)

    local btnExpiring = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnExpiring:SetSize(100, 22)
    btnExpiring:SetPoint("LEFT", btnMissing, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnExpiring, "Expiring (<2m)")
    btnExpiring:SetScript("OnClick", function() Mock:SetExpiring() end)

    -- Section 3: Tank Overrides & Cast Actions
    local lblActions = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblActions:SetPoint("TOPLEFT", 14, -158)
    lblActions:SetText("Actions & Overrides:")

    local btnTank = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnTank:SetSize(115, 22)
    btnTank:SetPoint("TOPLEFT", 14, -176)
    Buffadin.Theme:StyleButton(btnTank, "Tank Sanc Override")
    btnTank:SetScript("OnClick", function() Mock:ToggleTankOverride() end)

    local btnCast = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnCast:SetSize(105, 22)
    btnCast:SetPoint("LEFT", btnTank, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnCast, "Simulate Cast")
    btnCast:SetScript("OnClick", function() Mock:SimulateCast() end)

    local btnCombat = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnCombat:SetSize(80, 22)
    btnCombat:SetPoint("LEFT", btnCast, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnCombat, "Combat")
    btnCombat:SetScript("OnClick", function() Mock:ToggleCombat() end)
    panel.btnCombat = btnCombat

    self.panel = panel
    self:UpdatePanelStatus()
    return panel
end

function Mock:UpdatePanelStatus()
    if not self.panel then return end

    local status
    if self.active then
        status = string.format("Status: |cff00ff00MOCK ACTIVE|r (%s) | %d Members | %s",
            self.currentPreset, Buffadin.Roster.totalCount or 0,
            self.simulatedCombat and "|cffff4444In Combat|r" or "|cff88ff88Out of Combat|r")
    else
        status = "Status: |cffaaaaaaLive Mode (Solo / Real Group)|r"
    end

    self.panel.statusText:SetText(status)
    if self.panel.btnCombat then
        self.panel.btnCombat:SetText(self.simulatedCombat and "Leave Combat" or "Enter Combat")
    end
end

function Mock:TogglePanel()
    local panel = self:CreateControlPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
        self:UpdatePanelStatus()
    end
end
