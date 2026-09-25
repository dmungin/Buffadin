local addonName, Buffadin = ...

Buffadin.MockHarness = {}
local Mock = Buffadin.MockHarness

Mock.active = false
Mock.currentPreset = "SOLO"
Mock.simulatedCombat = false
Mock.mockUnits = {}
Mock.mockUnitList = {}
Mock.buffStates = {} -- [unitId] = { hasBuff = bool, spellId = number, spellName = string, isGreater = bool, expires = number, duration = number, buffs = table }
Mock.eventLog = {}   -- array of { timestamp, category, spell, target, details, formatted }
Mock.hasAura = true
Mock.hasRighteousFury = false

-- =========================================================================
-- Synthetic Unit Generator & Preset Environments
-- =========================================================================

local function CreateMockUnit(unitId, name, classToken, isTank, isLeader, isAssist, isPlayer)
    local clsConfig = Buffadin.CLASS_BY_TOKEN[classToken]
    local cid = clsConfig and clsConfig.id or 1
    return {
        unitId = unitId,
        name = name,
        fullName = name,
        classToken = classToken,
        classId = cid,
        isTank = isTank or false,
        isDead = false,
        isOnline = true,
        isVisible = true,
        isLeader = isLeader or false,
        isAssist = isAssist or false,
        isPlayer = isPlayer or false,
    }
end

function Mock:LoadPreset(preset)
    self.mockUnits = {}
    self.mockUnitList = {}
    self.currentPreset = preset or "RAID40"

    local playerName = UnitName("player") or "Player"

    if preset == "PARTY" then
        local list = {
            CreateMockUnit("player", playerName, "PALADIN", false, true, false, true),
            CreateMockUnit("party1", "Gorok", "WARRIOR", true, false, false, false),       -- Tank
            CreateMockUnit("party2", "Pyromaniac", "MAGE", false, false, false, false),
            CreateMockUnit("party3", "Shadowstep", "ROGUE", false, false, false, false),
            CreateMockUnit("party4", "Holyheals", "PRIEST", false, false, false, false),
        }
        for _, u in ipairs(list) do
            self.mockUnits[u.unitId] = u
            table.insert(self.mockUnitList, u.unitId)
        end

    elseif preset == "RAID25" then
        local list = {
            -- Paladins (3)
            CreateMockUnit("player", playerName, "PALADIN", false, true, false, true),
            CreateMockUnit("raid1", "Uther", "PALADIN", false, false, true, false),
            CreateMockUnit("raid2", "Tirion", "PALADIN", false, false, false, false),
            -- Tanks (2)
            CreateMockUnit("raid3", "Gorok", "WARRIOR", true, false, false, false),        -- Main Tank
            CreateMockUnit("raid4", "Ironbark", "DRUID", true, false, false, false),       -- Off Tank
            -- Warriors DPS (3)
            CreateMockUnit("raid5", "Bladestorm", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid6", "Rend", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid7", "Execute", "WARRIOR", false, false, false, false),
            -- Rogues (3)
            CreateMockUnit("raid8", "Shadowstep", "ROGUE", false, false, false, false),
            CreateMockUnit("raid9", "Sneak", "ROGUE", false, false, false, false),
            CreateMockUnit("raid10", "Daggerfall", "ROGUE", false, false, false, false),
            -- Mages (3)
            CreateMockUnit("raid11", "Pyromaniac", "MAGE", false, false, false, false),
            CreateMockUnit("raid12", "Frostbite", "MAGE", false, false, false, false),
            CreateMockUnit("raid13", "Arcanist", "MAGE", false, false, false, false),
            -- Warlocks (3)
            CreateMockUnit("raid14", "Doombringer", "WARLOCK", false, false, false, false),
            CreateMockUnit("raid15", "Chaosbolt", "WARLOCK", false, false, false, false),
            CreateMockUnit("raid16", "Felhound", "WARLOCK", false, false, false, false),
            -- Hunters (3)
            CreateMockUnit("raid17", "Aimshot", "HUNTER", false, false, false, false),
            CreateMockUnit("raid18", "Trueshot", "HUNTER", false, false, false, false),
            CreateMockUnit("raid19", "Beastmaster", "HUNTER", false, false, false, false),
            -- Priests (3)
            CreateMockUnit("raid20", "Holyheals", "PRIEST", false, false, false, false),
            CreateMockUnit("raid21", "Shadowform", "PRIEST", false, false, false, false),
            CreateMockUnit("raid22", "Discipline", "PRIEST", false, false, false, false),
            -- Druids (1)
            CreateMockUnit("raid23", "Moonkin", "DRUID", false, false, false, false),
            -- Shamans (1)
            CreateMockUnit("raid24", "Windfury", "SHAMAN", false, false, false, false),
        }
        for _, u in ipairs(list) do
            self.mockUnits[u.unitId] = u
            table.insert(self.mockUnitList, u.unitId)
        end

    elseif preset == "RAID40" then
        local list = {
            -- Paladins (4)
            CreateMockUnit("player", playerName, "PALADIN", false, true, false, true),
            CreateMockUnit("raid1", "Uther", "PALADIN", false, false, true, false),
            CreateMockUnit("raid2", "Tirion", "PALADIN", false, false, false, false),
            CreateMockUnit("raid3", "Turalyon", "PALADIN", false, false, false, false),
            -- Tanks (3)
            CreateMockUnit("raid4", "Gorok", "WARRIOR", true, false, false, false),        -- Main Tank
            CreateMockUnit("raid5", "Stonecleave", "WARRIOR", true, false, false, false),  -- Off Tank 1
            CreateMockUnit("raid6", "Ironbark", "DRUID", true, false, false, false),       -- Off Tank 2
            -- Warriors DPS (5)
            CreateMockUnit("raid7", "Bladestorm", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid8", "Rend", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid9", "Execute", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid10", "Cleaver", "WARRIOR", false, false, false, false),
            CreateMockUnit("raid11", "Sundered", "WARRIOR", false, false, false, false),
            -- Rogues (5)
            CreateMockUnit("raid12", "Shadowstep", "ROGUE", false, false, false, false),
            CreateMockUnit("raid13", "Sneak", "ROGUE", false, false, false, false),
            CreateMockUnit("raid14", "Daggerfall", "ROGUE", false, false, false, false),
            CreateMockUnit("raid15", "Backstab", "ROGUE", false, false, false, false),
            CreateMockUnit("raid16", "Ambush", "ROGUE", false, false, false, false),
            -- Mages (5)
            CreateMockUnit("raid17", "Pyromaniac", "MAGE", false, false, false, false),
            CreateMockUnit("raid18", "Frostbite", "MAGE", false, false, false, false),
            CreateMockUnit("raid19", "Arcanist", "MAGE", false, false, false, false),
            CreateMockUnit("raid20", "Ignite", "MAGE", false, false, false, false),
            CreateMockUnit("raid21", "Blizzard", "MAGE", false, false, false, false),
            -- Warlocks (4)
            CreateMockUnit("raid22", "Doombringer", "WARLOCK", false, false, false, false),
            CreateMockUnit("raid23", "Chaosbolt", "WARLOCK", false, false, false, false),
            CreateMockUnit("raid24", "Felhound", "WARLOCK", false, false, false, false),
            CreateMockUnit("raid25", "Soulfire", "WARLOCK", false, false, false, false),
            -- Hunters (4)
            CreateMockUnit("raid26", "Aimshot", "HUNTER", false, false, false, false),
            CreateMockUnit("raid27", "Trueshot", "HUNTER", false, false, false, false),
            CreateMockUnit("raid28", "Beastmaster", "HUNTER", false, false, false, false),
            CreateMockUnit("raid29", "MultiShot", "HUNTER", false, false, false, false),
            -- Priests (5)
            CreateMockUnit("raid30", "Holyheals", "PRIEST", false, false, false, false),
            CreateMockUnit("raid31", "Shadowform", "PRIEST", false, false, false, false),
            CreateMockUnit("raid32", "Discipline", "PRIEST", false, false, false, false),
            CreateMockUnit("raid33", "Powerword", "PRIEST", false, false, false, false),
            CreateMockUnit("raid34", "Renew", "PRIEST", false, false, false, false),
            -- Druids (3)
            CreateMockUnit("raid35", "Moonkin", "DRUID", false, false, false, false),
            CreateMockUnit("raid36", "Regrowth", "DRUID", false, false, false, false),
            CreateMockUnit("raid37", "Tranquil", "DRUID", false, false, false, false),
            -- Shamans (2)
            CreateMockUnit("raid38", "Windfury", "SHAMAN", false, false, false, false),
            CreateMockUnit("raid39", "Chainheal", "SHAMAN", false, false, false, false),
        }
        for _, u in ipairs(list) do
            self.mockUnits[u.unitId] = u
            table.insert(self.mockUnitList, u.unitId)
        end

    else -- SOLO
        local u = CreateMockUnit("player", playerName, "PALADIN", false, true, false, true)
        self.mockUnits[u.unitId] = u
        table.insert(self.mockUnitList, u.unitId)
    end
end

-- =========================================================================
-- Adapter Gateway Interface (Called by Core/Compat.lua)
-- =========================================================================

function Mock:GetMockUnitList()
    return self.mockUnitList or {}
end

function Mock:GetMockUnitInfo(unit)
    local u = self.mockUnits and self.mockUnits[unit]
    if not u then
        return false
    end
    return true, u.name, u.fullName or u.name, u.classToken, u.isTank or false, u.isDead or false, u.isOnline ~= false, u.isVisible ~= false, u.isLeader or false, u.isAssist or false
end

function Mock:IsMockUnitPlayer(unit)
    if unit == "player" then return true end
    local u = self.mockUnits and self.mockUnits[unit]
    return u and (u.isPlayer == true)
end

function Mock:GetUnitAura(unit, targetSpellID, targetSpellName)
    -- 1. Self status on player (Aura, Righteous Fury, Seals)
    if unit == "player" then
        if self:IsAuraSpell(targetSpellID, targetSpellName) then
            return (self.hasAura ~= false), 0, 0
        end
        if self:IsRighteousFurySpell(targetSpellID, targetSpellName) then
            return (self.hasRighteousFury == true), 0, 0
        end
        if self:IsSealSpell(targetSpellID, targetSpellName) then
            return true, 0, 0
        end
    end

    local state = self.buffStates and self.buffStates[unit]
    if not state then
        return false, 0, 0
    end

    local now = GetTime()

    -- Support multi-buff container
    if state.buffs then
        for _, b in pairs(state.buffs) do
            if b.hasBuff and (not b.expires or b.expires == 0 or b.expires > now) then
                local idMatch = (targetSpellID and targetSpellID > 0 and b.spellId == targetSpellID)
                local nameMatch = (targetSpellName and targetSpellName ~= "" and b.spellName == targetSpellName)
                if idMatch or nameMatch then
                    return true, b.expires or 0, b.duration or 0
                end
            end
        end
        return false, 0, 0
    end

    -- Single-buff container
    if not state.hasBuff then
        return false, 0, 0
    end
    if state.expires and state.expires > 0 and state.expires <= now then
        return false, 0, 0
    end

    local idMatch = (targetSpellID and targetSpellID > 0 and state.spellId == targetSpellID)
    local nameMatch = (targetSpellName and targetSpellName ~= "" and state.spellName == targetSpellName)
    if idMatch or nameMatch then
        return true, state.expires or 0, state.duration or 0
    end

    if (not targetSpellID or targetSpellID == 0) and (not targetSpellName or targetSpellName == "") then
        return true, state.expires or 0, state.duration or 0
    end

    return false, 0, 0
end

-- =========================================================================
-- Spell & Aura Introspection Helpers
-- =========================================================================

function Mock:IsAuraSpell(spellId, spellName)
    for _, a in pairs(Buffadin.AURAS) do
        if (spellId and spellId > 0 and a.spellId == spellId) or (spellName and spellName ~= "" and a.name == spellName) then
            return true
        end
    end
    return false
end

function Mock:IsRighteousFurySpell(spellId, spellName)
    local rf = Buffadin.RIGHTEOUS_FURY
    if not rf then return false end
    if (spellId and spellId > 0 and rf.spellId == spellId) or (spellName and spellName ~= "" and rf.name == spellName) then
        return true
    end
    return false
end

function Mock:IsSealSpell(spellId, spellName)
    for _, s in pairs(Buffadin.SEALS) do
        if (spellId and spellId > 0 and s.spellId == spellId) or (spellName and spellName ~= "" and s.name == spellName) then
            return true
        end
    end
    return false
end

function Mock:IsGreaterBlessing(spellName)
    if not spellName or spellName == "" then return false end
    if spellName:find("^Greater Blessing") or spellName:find("^Große[rs] Segen") or spellName:find("^Bénédiction supérieure") then
        return true
    end
    for _, g in pairs(Buffadin.GREATER_BLESSINGS) do
        if g.name == spellName then
            return true
        end
    end
    return false
end

function Mock:FindSpellIdByName(spellName)
    if not spellName or spellName == "" then return 0 end
    for _, g in pairs(Buffadin.GREATER_BLESSINGS) do
        if g.name == spellName then return g.spellId end
    end
    for _, n in pairs(Buffadin.NORMAL_BLESSINGS) do
        if n.name == spellName then return n.spellId end
    end
    for _, a in pairs(Buffadin.AURAS) do
        if a.name == spellName then return a.spellId end
    end
    if Buffadin.RIGHTEOUS_FURY and Buffadin.RIGHTEOUS_FURY.name == spellName then
        return Buffadin.RIGHTEOUS_FURY.spellId
    end
    return 0
end

-- =========================================================================
-- Buff State Mutations
-- =========================================================================

function Mock:SetUnitBuff(unitId, spellId, spellName, isGreater, duration)
    duration = duration or (isGreater and 900 or 600)
    local now = GetTime()
    self.buffStates[unitId] = {
        hasBuff = true,
        spellId = spellId or 0,
        spellName = spellName or "",
        isGreater = isGreater or false,
        expires = now + duration,
        duration = duration,
    }
end

function Mock:ClearUnitBuff(unitId)
    self.buffStates[unitId] = {
        hasBuff = false,
        spellId = 0,
        spellName = "",
        expires = 0,
        duration = 0,
    }
end

function Mock:InitializeBuffStates()
    self.buffStates = {}
    local pName = UnitName("player") or "Player"

    for _, u in pairs(Buffadin.Roster.units) do
        local nIndex = Buffadin.Assignments:GetNormal(pName, u.classId, u.name)
        local gIndex = Buffadin.Assignments:GetGreater(pName, u.classId)
        local sName = ""
        local sId = 0
        local isGreater = true

        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            sName = Buffadin.NORMAL_BLESSINGS[nIndex].name
            sId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0
            isGreater = false
        elseif gIndex and gIndex > 0 and Buffadin.GREATER_BLESSINGS[gIndex] then
            sName = Buffadin.GREATER_BLESSINGS[gIndex].name
            sId = Buffadin.GREATER_BLESSINGS[gIndex].spellId or 0
            isGreater = true
        end

        if sName ~= "" then
            self:SetUnitBuff(u.unitId, sId, sName, isGreater, 900)
        else
            self:ClearUnitBuff(u.unitId)
        end
    end

    self.hasAura = true
    self.hasRighteousFury = false
end

-- =========================================================================
-- Event Log System
-- =========================================================================

function Mock:LogEvent(category, spellName, targetText, details)
    local timestamp = date("%H:%M:%S")
    local categoryColors = {
        ["AUTO"]    = "|cff00ff00[AUTO]|r",
        ["CLASS"]   = "|cff00ccff[CLASS]|r",
        ["POPUP"]   = "|cffffaa00[POPUP]|r",
        ["NORMAL"]  = "|cffffee88[NORMAL]|r",
        ["AURA"]    = "|cffF58CBA[AURA]|r",
        ["SELF"]    = "|cffF58CBA[SELF]|r",
        ["SYSTEM"]  = "|cffaaaaaa[SYSTEM]|r",
        ["WARN"]    = "|cffff4444[WARN]|r",
        ["INFO"]    = "|cff88ccff[INFO]|r",
    }
    local catTag = categoryColors[category] or string.format("|cffaaaaaa[%s]|r", category or "LOG")
    local spellTag = spellName and string.format("|cffF58CBA%s|r", spellName) or ""
    local targetTag = targetText and string.format("|cffffffff%s|r", targetText) or ""
    local detailsTag = (details and details ~= "") and string.format(" |cff888888(%s)|r", details) or ""

    local logLine = string.format("|cff888888[%s]|r %s %s -> %s%s",
        timestamp, catTag, spellTag, targetTag, detailsTag)

    table.insert(self.eventLog, {
        timestamp = timestamp,
        category = category,
        spell = spellName,
        target = targetText,
        details = details,
        formatted = logLine,
    })

    if self.logMessageFrame then
        self.logMessageFrame:AddMessage(logLine)
    end
end

function Mock:ClearLog()
    self.eventLog = {}
    if self.logMessageFrame then
        self.logMessageFrame:Clear()
    end
    self:LogEvent("SYSTEM", "Buffadin Test Harness", "Event Log Cleared", "Click buttons to simulate actions")
end

-- =========================================================================
-- Simulated Cast Actions (Real Adapter Execution)
-- =========================================================================

function Mock:PerformSimulatedCast(spellName, unit, category)
    if not spellName or spellName == "" then
        self:LogEvent("WARN", "No Spell", tostring(unit or "Unknown"), "Button has no spell configured")
        return
    end
    if not unit then
        self:LogEvent("WARN", "No Target", spellName, "Button has no target configured")
        return
    end

    -- 1. Check Self Aura
    if self:IsAuraSpell(nil, spellName) then
        self.hasAura = true
        self:LogEvent(category or "AURA", spellName, "Player", "Activated Aura")
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
        return
    end

    -- 2. Check Righteous Fury
    if self:IsRighteousFurySpell(nil, spellName) then
        self.hasRighteousFury = true
        self:LogEvent(category or "SELF", spellName, "Player", "Activated Righteous Fury")
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
        return
    end

    -- 3. Check Target Unit
    local exists, name, fullName, classToken, isTank = Buffadin:GetUnitInfo(unit)
    if not exists then
        self:LogEvent("WARN", spellName, tostring(unit), "Target unit does not exist in roster")
        return
    end

    local isGreater = self:IsGreaterBlessing(spellName)
    local spellId = self:FindSpellIdByName(spellName)

    if isGreater then
        -- Greater Blessing: hits ALL group members of this class in the roster
        local clsConfig = Buffadin.CLASS_BY_TOKEN[classToken]
        local cid = clsConfig and clsConfig.id or 1
        local classUnits = Buffadin.Roster.classes[cid] or {}
        local buffedNames = {}

        for _, u in ipairs(classUnits) do
            self:SetUnitBuff(u.unitId, spellId, spellName, true, 900)
            table.insert(buffedNames, u.name)
        end

        local countStr = string.format("%d player%s", #buffedNames, #buffedNames == 1 and "" or "s")
        local details = countStr
        if #buffedNames > 0 and #buffedNames <= 4 then
            details = details .. " (" .. table.concat(buffedNames, ", ") .. ")"
        elseif #buffedNames > 4 then
            details = details .. string.format(" (%s, +%d more)", buffedNames[1], #buffedNames - 1)
        end

        self:LogEvent(category or "CLASS", spellName, clsConfig and clsConfig.name or classToken, details)
    else
        -- Normal Blessing: hits ONLY this specific unit
        self:SetUnitBuff(unit, spellId, spellName, false, 900)
        local targetDesc = name .. (isTank and " [Tank]" or "")
        self:LogEvent(category or "NORMAL", spellName, targetDesc, "Single Blessing")
    end

    -- Run real production update loop
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.PlayerPopups and Buffadin.PlayerPopups:IsShown() and Buffadin.PlayerPopups.currentClassId then
        Buffadin.PlayerPopups:ShowForClass(Buffadin.PlayerPopups.currentClassId, Buffadin.PlayerPopups.currentAnchor)
    end
end

-- =========================================================================
-- Button Hooking & Click Interception
-- =========================================================================

function Mock:HookButton(btn, handler)
    if not btn or btn._buffadinMockHooked then return end
    btn._buffadinMockHooked = true

    btn:HookScript("PreClick", function(self, button, down)
        if not (Buffadin.MockHarness and Buffadin.MockHarness.active) then
            return
        end
        local useKeyDown = (GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")) or false
        if down ~= nil and down ~= useKeyDown then
            return
        end
        handler(self, button)
    end)
end

function Mock:HookInteractiveButtons()
    -- 1. Class Buttons
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.buttons then
        for _, btn in pairs(Buffadin.BlessingsBar.buttons) do
            self:HookButton(btn, function(bSelf, button)
                if IsShiftKeyDown and IsShiftKeyDown() then return end
                if button == "LeftButton" then
                    local spell = bSelf:GetAttribute("spell1")
                    local unit = bSelf:GetAttribute("unit1")
                    Mock:PerformSimulatedCast(spell, unit, "CLASS")
                elseif button == "RightButton" then
                    local spell = bSelf:GetAttribute("spell2")
                    local unit = bSelf:GetAttribute("unit2")
                    Mock:PerformSimulatedCast(spell, unit, "NORMAL")
                end
            end)
        end
    end

    -- 2. Auto-Buff Button
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.autoButton then
        self:HookButton(Buffadin.BlessingsBar.autoButton, function(bSelf, button)
            if Buffadin:InCombat() then return end
            if button == "LeftButton" then
                local spell = bSelf:GetAttribute("spell1")
                local unit = bSelf:GetAttribute("unit1")
                if spell and unit then
                    Mock:PerformSimulatedCast(spell, unit, "AUTO")
                end
            elseif button == "RightButton" then
                local spell = bSelf:GetAttribute("spell2")
                local unit = bSelf:GetAttribute("unit2")
                if spell and unit then
                    Mock:PerformSimulatedCast(spell, unit, "AUTO")
                end
            end
        end)
    end

    -- 3. Aura Button
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.auraButton then
        self:HookButton(Buffadin.BlessingsBar.auraButton, function(bSelf, button)
            if IsShiftKeyDown and IsShiftKeyDown() then return end
            local spell = bSelf:GetAttribute("spell")
            Mock:ToggleMockAura(spell)
        end)
    end

    -- 4. Righteous Fury Button
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.rfButton then
        self:HookButton(Buffadin.BlessingsBar.rfButton, function(bSelf, button)
            Mock:ToggleMockRighteousFury()
        end)
    end

    -- 5. Player Popup Rows
    if Buffadin.PlayerPopups then
        if Buffadin.PlayerPopups.buttons then
            for _, btn in ipairs(Buffadin.PlayerPopups.buttons) do
                self:HookButton(btn, function(bSelf, button)
                    local spell = bSelf:GetAttribute("spell1")
                    local unit = bSelf:GetAttribute("unit1")
                    Mock:PerformSimulatedCast(spell, unit, "POPUP")
                end)
            end
        end
        if not self.origGetOrCreateButton then
            self.origGetOrCreateButton = Buffadin.PlayerPopups.GetOrCreateButton
            Buffadin.PlayerPopups.GetOrCreateButton = function(pSelf, index)
                local btn = Mock.origGetOrCreateButton(pSelf, index)
                Mock:HookButton(btn, function(bSelf, button)
                    local spell = bSelf:GetAttribute("spell1")
                    local unit = bSelf:GetAttribute("unit1")
                    Mock:PerformSimulatedCast(spell, unit, "POPUP")
                end)
                return btn
            end
        end
    end
end

-- =========================================================================
-- Simulation Actions (Dev Panel Controls)
-- =========================================================================

function Mock:SimulateCast()
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.autoButton then
        local spell = Buffadin.BlessingsBar.autoButton:GetAttribute("spell1")
        local unit = Buffadin.BlessingsBar.autoButton:GetAttribute("unit1")
        if spell and unit then
            self:PerformSimulatedCast(spell, unit, "AUTO")
        else
            self:LogEvent("INFO", "Auto-Buff", "Raid", "No action needed: All blessings active!")
        end
    end
end

function Mock:ToggleMockAura(spellName)
    local pName = UnitName("player") or "Player"
    local aIndex = Buffadin.Assignments:GetAura(pName)
    local aConfig = Buffadin.AURAS[aIndex]
    local aName = spellName or (aConfig and aConfig.name) or "Paladin Aura"

    self.hasAura = not self.hasAura
    Buffadin.BuffScanner.selfStatus.hasAura = self.hasAura
    self:LogEvent("AURA", aName, "Player", self.hasAura and "Aura Activated" or "Aura Deactivated")

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
end

function Mock:ToggleMockRighteousFury()
    self.hasRighteousFury = not self.hasRighteousFury
    Buffadin.BuffScanner.selfStatus.hasRighteousFury = self.hasRighteousFury
    self:LogEvent("SELF", "Righteous Fury", "Player", self.hasRighteousFury and "Activated" or "Cancelled")

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
end

function Mock:ToggleTankOverride()
    local pallyName = UnitName("player") or "Player"
    local current = Buffadin.Assignments:GetNormal(pallyName, 1, "Gorok")

    if current == 6 then
        Buffadin.Assignments:SetNormal(pallyName, 1, "Gorok", 0)
        self:LogEvent("SYSTEM", "Tank Override", "Gorok (Warrior)", "Cleared override (reverted to class default)")
        Buffadin:Print("Mock: Cleared Tank override on Gorok (reset to class default).")
    else
        Buffadin.Assignments:SetNormal(pallyName, 1, "Gorok", 6) -- Sanctuary = 6
        self:LogEvent("SYSTEM", "Tank Override", "Gorok (Warrior)", "Set override to [Blessing of Sanctuary]")
        Buffadin:Print("Mock: Set Gorok (Tank) override to [Blessing of Sanctuary]!")
    end

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.ManagerFrame:IsShown() then
        Buffadin.ManagerFrame:UpdateGrid()
    end
end

function Mock:BuffAll(duration)
    duration = duration or 900
    local pName = UnitName("player") or "Player"
    local count = 0

    for _, u in pairs(Buffadin.Roster.units) do
        local nIndex = Buffadin.Assignments:GetNormal(pName, u.classId, u.name)
        local gIndex = Buffadin.Assignments:GetGreater(pName, u.classId)
        local spellName = ""
        local spellId = 0
        local isGreater = true

        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            spellName = Buffadin.NORMAL_BLESSINGS[nIndex].name
            spellId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0
            isGreater = false
        elseif gIndex and gIndex > 0 and Buffadin.GREATER_BLESSINGS[gIndex] then
            spellName = Buffadin.GREATER_BLESSINGS[gIndex].name
            spellId = Buffadin.GREATER_BLESSINGS[gIndex].spellId or 0
            isGreater = true
        end

        if spellName ~= "" then
            self:SetUnitBuff(u.unitId, spellId, spellName, isGreater, duration)
            count = count + 1
        end
    end

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    self:LogEvent("SYSTEM", "Buff All", "All Members", string.format("Set %dm duration on %d units", math.floor(duration / 60), count))
    Buffadin:Print(string.format("Mock: Applied %d-minute buffs to %d members.", math.floor(duration / 60), count))
end

function Mock:SetRandomMissing()
    local count = 0
    local droppedNames = {}
    for _, u in pairs(Buffadin.Roster.units) do
        if u.classId == 1 or u.classId == 7 or math.random() > 0.65 then
            self:ClearUnitBuff(u.unitId)
            count = count + 1
            if #droppedNames < 6 then
                table.insert(droppedNames, u.name)
            end
        end
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    local detail = string.format("Dropped on %d players (%s...)", count, table.concat(droppedNames, ", "))
    self:LogEvent("WARN", "Random Missing", "Raid", detail)
    Buffadin:Print(string.format("Mock: Dropped buffs on %d players (check red missing counts).", count))
end

function Mock:SetExpiring()
    local now = GetTime()
    local pName = UnitName("player") or "Player"
    for _, u in pairs(Buffadin.Roster.units) do
        if u.classId == 4 then -- Rogues expiring in 45s
            local gIndex = Buffadin.Assignments:GetGreater(pName, 4)
            local gCfg = Buffadin.GREATER_BLESSINGS[gIndex]
            local sName = gCfg and gCfg.name or "Greater Blessing of Might"
            local sId = gCfg and gCfg.spellId or 25782
            self.buffStates[u.unitId] = {
                hasBuff = true,
                spellId = sId,
                spellName = sName,
                isGreater = true,
                expires = now + 45,
                duration = 900,
            }
        elseif u.classId == 3 then -- Hunters expiring in 110s
            local gIndex = Buffadin.Assignments:GetGreater(pName, 3)
            local gCfg = Buffadin.GREATER_BLESSINGS[gIndex]
            local sName = gCfg and gCfg.name or "Greater Blessing of Wisdom"
            local sId = gCfg and gCfg.spellId or 25894
            self.buffStates[u.unitId] = {
                hasBuff = true,
                spellId = sId,
                spellName = sName,
                isGreater = true,
                expires = now + 110,
                duration = 900,
            }
        end
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    self:LogEvent("WARN", "Expiring Buffs", "Rogues & Hunters", "Set Rogues (<45s) and Hunters (<110s)")
    Buffadin:Print("Mock: Set Rogues (45s) and Hunters (110s) as expiring.")
end

function Mock:ToggleCombat()
    self.simulatedCombat = not self.simulatedCombat

    if self.simulatedCombat then
        self:LogEvent("WARN", "Combat State", "In Combat", "Simulated COMBAT START")
        Buffadin:Print("Mock: Simulated |cffff4444COMBAT START|r (checking combat lockdown handling).")
        if Buffadin.db and Buffadin.db.profile.hideInCombat then
            Buffadin.BlessingsBar:Hide()
        end
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
    else
        self:LogEvent("INFO", "Combat State", "Out of Combat", "Simulated COMBAT END")
        Buffadin:Print("Mock: Simulated |cff00ff00COMBAT END|r (processing queued changes).")
        Buffadin:ProcessCombatQueue()
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:UpdateLayout()
        Buffadin.BlessingsBar:RefreshDisplay()
        Buffadin.ManagerFrame:UpdateGrid()
    end

    self:UpdatePanelStatus()
end

function Mock:SimulateDeath(unitId)
    unitId = unitId or "raid5"
    local u = self.mockUnits and self.mockUnits[unitId]
    if u then
        u.isDead = true
        self:ClearUnitBuff(unitId)
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
        self:LogEvent("WARN", "Unit Died", u.name, "Unit marked dead")
        Buffadin:Print("Mock: " .. u.name .. " has died.")
    end
end

function Mock:SimulateBattleRez(unitId)
    unitId = unitId or "raid5"
    local u = self.mockUnits and self.mockUnits[unitId]
    if u then
        u.isDead = false
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
        self:LogEvent("INFO", "Battle Rez", u.name, "Unit resurrected without buffs")
        Buffadin:Print("Mock: " .. u.name .. " was battle-rezzed (alive, missing buff).")
    end
end

-- =========================================================================
-- Harness Lifecycle (Enable / Disable / Preset)
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

function Mock:Enable(preset)
    self.active = true
    self.currentPreset = preset or "RAID40"

    -- 1. Load synthetic units into adapter storage
    self:LoadPreset(self.currentPreset)

    -- 2. Hook interactive buttons for direct click simulation
    self:HookInteractiveButtons()

    -- 3. Backup real assignments so mock testing never corrupts player's real setup
    if not self.savedAssignments then
        self.savedAssignments = CopyTable(Buffadin.Assignments.data)
        self.savedNormalAssignments = CopyTable(Buffadin.Assignments.normalData)
        self.savedAuraAssignments = CopyTable(Buffadin.Assignments.auraData)
    end

    -- 4. Run real production roster update
    Buffadin.Roster:Update()

    -- 5. Pre-populate mock assignments
    self:ApplyDefaultAssignments()

    -- 6. Initialize buff states & run real scanner & layout updates
    self:InitializeBuffStates()
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:UpdateLayout()
    Buffadin.BlessingsBar:RefreshDisplay()
    Buffadin.ManagerFrame:UpdateGrid()

    self:LogEvent("SYSTEM", "Test Harness", self.currentPreset, string.format("Mock environment active (%d units)", Buffadin.Roster.totalCount or 0))
    Buffadin:Print(string.format("Mock Test Harness active: |cff00ff00%s|r mode loaded.", self.currentPreset))
    self:UpdatePanelStatus()
end

function Mock:Disable()
    if not self.active then return end

    self.active = false
    self.currentPreset = "SOLO"
    self.simulatedCombat = false
    self.mockUnits = {}
    self.mockUnitList = {}
    self.buffStates = {}

    -- Restore real saved assignments
    if self.savedAssignments then
        Buffadin.Assignments.data = CopyTable(self.savedAssignments)
        Buffadin.Assignments.normalData = CopyTable(self.savedNormalAssignments or {})
        Buffadin.Assignments.auraData = CopyTable(self.savedAuraAssignments or {})
        self.savedAssignments = nil
        self.savedNormalAssignments = nil
        self.savedAuraAssignments = nil
        if Buffadin.db and Buffadin.db.profile then
            Buffadin.db.profile.assignments = Buffadin.Assignments.data
            Buffadin.db.profile.normalAssignments = Buffadin.Assignments.normalData
            Buffadin.db.profile.auraAssignments = Buffadin.Assignments.auraData
        end
    end

    -- Restore real state and live secure casting attributes
    Buffadin.Roster:Update()
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:UpdateLayout()
    Buffadin.BlessingsBar:RefreshDisplay()
    Buffadin.ManagerFrame:UpdateGrid()

    self:LogEvent("SYSTEM", "Live Mode", "Solo/Real Group", "Restored live secure casting")
    Buffadin:Print("Mock Test Harness |cffff4444disabled|r. Reverted to live game state.")
    self:UpdatePanelStatus()
end

function Mock:SetPreset(preset)
    if not self.active then
        self:Enable(preset)
    else
        self.currentPreset = preset or "RAID40"
        self:LoadPreset(self.currentPreset)
        Buffadin.Roster:Update()
        self:InitializeBuffStates()
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:UpdateLayout()
        Buffadin.BlessingsBar:RefreshDisplay()
        Buffadin.ManagerFrame:UpdateGrid()
        self:LogEvent("SYSTEM", "Preset Changed", preset, string.format("Switched to %s mode (%d units)", preset, Buffadin.Roster.totalCount or 0))
        self:UpdatePanelStatus()
    end
end

-- =========================================================================
-- Floating Dev Control Panel UI
-- =========================================================================

function Mock:CreateControlPanel()
    if self.panel then return self.panel end

    local panel = CreateFrame("Frame", "Buffadin_MockControlPanel", UIParent, "BackdropTemplate")
    panel:SetSize(480, 450)
    panel:SetPoint("CENTER", UIParent, "CENTER", 180, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(110)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)
    panel:Hide()
    tinsert(UISpecialFrames, "Buffadin_MockControlPanel")

    -- Solid background to prevent action bars or world bleeding through
    if not panel.solidBg then
        local bg = panel:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints(panel)
        bg:SetColorTexture(0.06, 0.06, 0.08, 0.98)
        panel.solidBg = bg
    end

    Buffadin.Theme:ApplyCardBackdrop(panel, 0.95, 0.85)

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cffF58CBABuffadin|r Dev Test Harness & Event Log")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- Status Text
    local statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", 14, -34)
    statusText:SetTextColor(0.8, 0.8, 0.8)
    panel.statusText = statusText

    -- Section 1: Presets
    local lblPresets = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblPresets:SetPoint("TOPLEFT", 14, -54)
    lblPresets:SetText("Roster Environments:")

    local btnParty = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnParty:SetSize(80, 22)
    btnParty:SetPoint("TOPLEFT", 14, -72)
    Buffadin.Theme:StyleButton(btnParty, "Party (5)")
    btnParty:SetScript("OnClick", function() Mock:SetPreset("PARTY") end)

    local btnRaid25 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnRaid25:SetSize(80, 22)
    btnRaid25:SetPoint("LEFT", btnParty, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnRaid25, "Raid (25)")
    btnRaid25:SetScript("OnClick", function() Mock:SetPreset("RAID25") end)

    local btnRaid40 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnRaid40:SetSize(80, 22)
    btnRaid40:SetPoint("LEFT", btnRaid25, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnRaid40, "Raid (40)")
    btnRaid40:SetScript("OnClick", function() Mock:SetPreset("RAID40") end)

    local btnLive = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnLive:SetSize(80, 22)
    btnLive:SetPoint("LEFT", btnRaid40, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnLive, "Live Mode")
    btnLive:SetScript("OnClick", function() Mock:Disable() end)

    -- Section 2: Buff States
    local lblBuffs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblBuffs:SetPoint("TOPLEFT", 14, -102)
    lblBuffs:SetText("Buff Simulation:")

    local btnBuffAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnBuffAll:SetSize(110, 22)
    btnBuffAll:SetPoint("TOPLEFT", 14, -120)
    Buffadin.Theme:StyleButton(btnBuffAll, "Buff All (15m)")
    btnBuffAll:SetScript("OnClick", function() Mock:BuffAll(900) end)

    local btnMissing = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnMissing:SetSize(115, 22)
    btnMissing:SetPoint("LEFT", btnBuffAll, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnMissing, "Random Missing")
    btnMissing:SetScript("OnClick", function() Mock:SetRandomMissing() end)

    local btnExpiring = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnExpiring:SetSize(110, 22)
    btnExpiring:SetPoint("LEFT", btnMissing, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnExpiring, "Expiring (<2m)")
    btnExpiring:SetScript("OnClick", function() Mock:SetExpiring() end)

    -- Section 3: Actions & Overrides
    local lblActions = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblActions:SetPoint("TOPLEFT", 14, -150)
    lblActions:SetText("Actions & Controls:")

    local btnTank = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnTank:SetSize(125, 22)
    btnTank:SetPoint("TOPLEFT", 14, -168)
    Buffadin.Theme:StyleButton(btnTank, "Tank Sanc Override")
    btnTank:SetScript("OnClick", function() Mock:ToggleTankOverride() end)

    local btnCast = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnCast:SetSize(100, 22)
    btnCast:SetPoint("LEFT", btnTank, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnCast, "Simulate Cast")
    btnCast:SetScript("OnClick", function() Mock:SimulateCast() end)

    local btnAuraToggle = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnAuraToggle:SetSize(85, 22)
    btnAuraToggle:SetPoint("LEFT", btnCast, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnAuraToggle, "Toggle Aura")
    btnAuraToggle:SetScript("OnClick", function() Mock:ToggleMockAura() end)

    local btnCombat = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnCombat:SetSize(85, 22)
    btnCombat:SetPoint("LEFT", btnAuraToggle, "RIGHT", 6, 0)
    Buffadin.Theme:StyleButton(btnCombat, "Combat")
    btnCombat:SetScript("OnClick", function() Mock:ToggleCombat() end)
    panel.btnCombat = btnCombat

    -- Section 4: Live Event Log
    local lblLog = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblLog:SetPoint("TOPLEFT", 14, -198)
    lblLog:SetText("Cast Event Log (Live):")

    local btnClearLog = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnClearLog:SetSize(72, 18)
    btnClearLog:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -196)
    Buffadin.Theme:StyleButton(btnClearLog, "Clear Log")
    btnClearLog:SetScript("OnClick", function() Mock:ClearLog() end)

    local btnBottom = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnBottom:SetSize(60, 18)
    btnBottom:SetPoint("RIGHT", btnClearLog, "LEFT", -6, 0)
    Buffadin.Theme:StyleButton(btnBottom, "Bottom")
    btnBottom:SetScript("OnClick", function()
        if Mock.logMessageFrame then
            Mock.logMessageFrame:ScrollToBottom()
        end
    end)

    local logContainer = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    logContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -220)
    logContainer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 14)
    Buffadin.Theme:ApplyCardBackdrop(logContainer, 0.98, 0.90)

    local logFrame = CreateFrame("ScrollingMessageFrame", "Buffadin_MockLogFrame", logContainer)
    logFrame:SetPoint("TOPLEFT", logContainer, "TOPLEFT", 8, -6)
    logFrame:SetPoint("BOTTOMRIGHT", logContainer, "BOTTOMRIGHT", -8, 6)
    logFrame:SetFontObject("GameFontHighlightSmall")
    logFrame:SetJustifyH("LEFT")
    logFrame:SetFading(false)
    logFrame:SetMaxLines(300)
    logFrame:EnableMouseWheel(true)
    logFrame:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        else
            self:ScrollDown()
        end
    end)

    self.logMessageFrame = logFrame

    -- Re-populate existing log entries if reopening
    if #self.eventLog > 0 then
        for _, entry in ipairs(self.eventLog) do
            logFrame:AddMessage(entry.formatted)
        end
        logFrame:ScrollToBottom()
    else
        self:LogEvent("SYSTEM", "Buffadin Test Harness", "Event Log Ready", "Click buttons to simulate casts")
    end

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

function Mock:ShowPanel()
    local panel = self:CreateControlPanel()
    panel:Show()
    self:UpdatePanelStatus()
end

function Mock:HidePanel()
    if self.panel then
        self.panel:Hide()
    end
end

function Mock:TogglePanel()
    local panel = self:CreateControlPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        if not self.active then
            self:Enable(self.currentPreset ~= "SOLO" and self.currentPreset or "RAID40")
        end
        panel:Show()
        self:UpdatePanelStatus()
    end
end
