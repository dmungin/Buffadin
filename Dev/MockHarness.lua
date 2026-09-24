local addonName, Buffadin = ...

Buffadin.MockHarness = {}
local Mock = Buffadin.MockHarness

Mock.active = false
Mock.currentPreset = "SOLO"
Mock.simulatedCombat = false
Mock.buffStates = {} -- [unitId] = { hasBuff = bool, expires = timestamp, duration = number }
Mock.eventLog = {}   -- array of { timestamp, category, spell, target, details, formatted }
Mock.hasAura = true
Mock.hasRighteousFury = false

-- =========================================================================
-- Synthetic Roster Definitions
-- =========================================================================

local function CreateMockUnit(unitId, name, classToken, isTank)
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
            { name = playerName, isPlayer = true, isLeader = true, isAssist = false },
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
            { name = playerName, isPlayer = true, isLeader = true, isAssist = false },
            { name = "Uther", isPlayer = false, isLeader = false, isAssist = true },
            { name = "Tirion", isPlayer = false, isLeader = false, isAssist = false },
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
            { name = playerName, isPlayer = true, isLeader = true, isAssist = false },
            { name = "Uther", isPlayer = false, isLeader = false, isAssist = true },
            { name = "Tirion", isPlayer = false, isLeader = false, isAssist = false },
            { name = "Turalyon", isPlayer = false, isLeader = false, isAssist = false },
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

    local now = GetTime()
    for _, u in ipairs(rosterData.units) do
        Buffadin.Roster.units[u.unitId] = u
        table.insert(Buffadin.Roster.classes[u.classId], u)

        if not self.buffStates[u.unitId] then
            local pName = UnitName("player") or "Player"
            local nIndex = Buffadin.Assignments:GetNormal(pName, u.classId, u.name)
            local gIndex = Buffadin.Assignments:GetGreater(pName, u.classId)
            local sName = ""
            local sId = 0
            local isGreater = true
            if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
                sName = Buffadin.NORMAL_BLESSINGS[nIndex].name
                sId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId
                isGreater = false
            elseif gIndex and gIndex > 0 and Buffadin.GREATER_BLESSINGS[gIndex] then
                sName = Buffadin.GREATER_BLESSINGS[gIndex].name
                sId = Buffadin.GREATER_BLESSINGS[gIndex].spellId
                isGreater = true
            end
            self.buffStates[u.unitId] = {
                hasBuff = (sName ~= ""),
                spellId = sId,
                spellName = sName,
                isGreater = isGreater,
                expires = now + 900,
                duration = 900,
            }
        end
    end

    for i, p in ipairs(rosterData.paladins) do
        Buffadin.Roster.paladins[p.name] = {
            name = p.name,
            unitId = p.isPlayer and "player" or ("raid" .. i),
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

function Mock:InitializeBuffStates()
    self.buffStates = {}
    local now = GetTime()
    local pName = UnitName("player") or "Player"
    for _, u in pairs(Buffadin.Roster.units) do
        local nIndex = Buffadin.Assignments:GetNormal(pName, u.classId, u.name)
        local gIndex = Buffadin.Assignments:GetGreater(pName, u.classId)
        local sName = ""
        local sId = 0
        local isGreater = true
        if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
            sName = Buffadin.NORMAL_BLESSINGS[nIndex].name
            sId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId
            isGreater = false
        elseif gIndex and gIndex > 0 and Buffadin.GREATER_BLESSINGS[gIndex] then
            sName = Buffadin.GREATER_BLESSINGS[gIndex].name
            sId = Buffadin.GREATER_BLESSINGS[gIndex].spellId
            isGreater = true
        end
        self.buffStates[u.unitId] = {
            hasBuff = (sName ~= ""),
            spellId = sId,
            spellName = sName,
            isGreater = isGreater,
            expires = now + 900,
            duration = 900,
        }
    end
    self.hasAura = true
    self.hasRighteousFury = false
end

function Mock:ScanMockBuffs()
    local playerName = UnitName("player") or "Player"
    local now = GetTime()

    for classId, units in pairs(Buffadin.Roster.classes) do
        local gIndex = Buffadin.Assignments:GetGreater(playerName, classId)
        local gCfg = Buffadin.GREATER_BLESSINGS[gIndex]
        local gSpellName = gCfg and gCfg.name or ""
        local gSpellId = gCfg and gCfg.spellId or 0

        local nEquivIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0
        local nEquivCfg = Buffadin.NORMAL_BLESSINGS[nEquivIndex]
        local nEquivName = nEquivCfg and nEquivCfg.name or ""
        local nEquivId = nEquivCfg and nEquivCfg.spellId or 0

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
            local targetSpellName = ""
            local targetSpellId = 0

            if isSpecial and Buffadin.NORMAL_BLESSINGS[nIndex] then
                targetSpellName = Buffadin.NORMAL_BLESSINGS[nIndex].name
                targetSpellId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0
            elseif gIndex > 0 and gCfg then
                targetSpellName = gSpellName
                targetSpellId = gSpellId
            end

            local state = self.buffStates[unitInfo.unitId]
            local hasBuff = false
            local remaining = 0

            if state and state.hasBuff then
                local matches = false
                if isSpecial then
                    matches = (state.spellName == targetSpellName) or (targetSpellId > 0 and state.spellId == targetSpellId)
                else
                    matches = (state.spellName == gSpellName) or (state.spellName == nEquivName) or
                              (gSpellId > 0 and state.spellId == gSpellId) or
                              (nEquivId > 0 and state.spellId == nEquivId)
                    if not state.spellName and not state.spellId then
                        matches = true
                    end
                end

                if matches then
                    if state.expires and state.expires > now then
                        remaining = math.max(0, state.expires - now)
                        if remaining < minExpiration then
                            minExpiration = remaining
                        end
                        hasBuff = true
                    elseif state.expires and state.expires <= now then
                        hasBuff = false
                        remaining = 0
                    else
                        hasBuff = true
                        remaining = 900
                    end
                else
                    hasBuff = false
                    remaining = 0
                end
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

            Buffadin.BuffScanner.unitStatus[unitInfo.unitId] = {
                hasBuff = hasBuff,
                expiration = remaining,
                assignedGSpellId = (gIndex > 0) and Buffadin.GREATER_BLESSINGS[gIndex].spellId or 0,
                assignedNSpellId = isSpecial and Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0,
                assignedSpellName = targetSpellName,
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
        hasAura = (self.hasAura ~= false),
        auraSpellId = 465,
        hasRighteousFury = (self.hasRighteousFury == true),
        hasSeal = true,
        sealName = "Seal of Righteousness",
    }
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

function Mock:HookPopupButton(btn)
    self:HookButton(btn, function(bSelf, button)
        Mock:CastPlayerPopup(bSelf)
    end)
end

function Mock:HookInteractiveButtons()
    -- 1. Class Buttons
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.buttons then
        for _, btn in pairs(Buffadin.BlessingsBar.buttons) do
            self:HookButton(btn, function(bSelf, button)
                if button == "LeftButton" then
                    Mock:CastClassBlessing(bSelf.classId, true)
                elseif button == "RightButton" then
                    Mock:CastClassBlessing(bSelf.classId, false)
                end
            end)
        end
    end

    -- 2. Auto-Buff Button
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.autoButton then
        self:HookButton(Buffadin.BlessingsBar.autoButton, function(bSelf, button)
            if button == "LeftButton" then
                Mock:CastAutoBuff(true)
            elseif button == "RightButton" then
                Mock:CastAutoBuff(false)
            end
        end)
    end

    -- 3. Aura Button
    if Buffadin.BlessingsBar and Buffadin.BlessingsBar.auraButton then
        self:HookButton(Buffadin.BlessingsBar.auraButton, function(bSelf, button)
            Mock:ToggleMockAura()
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
                self:HookPopupButton(btn)
            end
        end
        if not self.origGetOrCreateButton then
            self.origGetOrCreateButton = Buffadin.PlayerPopups.GetOrCreateButton
            Buffadin.PlayerPopups.GetOrCreateButton = function(pSelf, index)
                local btn = Mock.origGetOrCreateButton(pSelf, index)
                Mock:HookPopupButton(btn)
                return btn
            end
        end
    end
end

-- =========================================================================
-- Simulated Cast Actions
-- =========================================================================

function Mock:CastClassBlessing(classId, isGreater, category, customReason)
    local pName = UnitName("player") or "Player"
    local cls = Buffadin.CLASS_BY_ID[classId]
    local clsName = cls and cls.name or ("Class " .. tostring(classId))
    local gIndex = Buffadin.Assignments:GetGreater(pName, classId)

    if not gIndex or gIndex == 0 then
        self:LogEvent("WARN", "No Assignment", clsName, "No blessing assigned to " .. clsName)
        return
    end

    local now = GetTime()
    local classUnits = Buffadin.Roster.classes[classId] or {}

    if isGreater then
        local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]
        local spellName = gConfig and gConfig.name or "Greater Blessing"

        local buffedPlayers = {}

        for _, u in ipairs(classUnits) do
            self.buffStates[u.unitId] = {
                hasBuff = true,
                spellId = gConfig and gConfig.spellId or 0,
                spellName = spellName,
                isGreater = true,
                expires = now + 900,
                duration = 900,
            }
            table.insert(buffedPlayers, u.name)
        end

        local countStr = string.format("%d player%s", #buffedPlayers, #buffedPlayers == 1 and "" or "s")
        local details = countStr
        if #buffedPlayers > 0 then
            details = details .. ": " .. table.concat(buffedPlayers, ", ")
        end
        if customReason and customReason ~= "" then
            details = details .. " [" .. customReason .. "]"
        end

        self:LogEvent(category or "CLASS", spellName, clsName, details)
    else
        -- Right-click: Normal Blessing on next unit needing a buff (prioritize overrides, then missing class buffs)
        local targetUnit = nil
        local targetSpellName = nil
        local targetSpellId = 0
        local targetReason = "Single Normal Blessing"

        -- 1. Check for unit with normal override that is missing that override
        for _, u in ipairs(classUnits) do
            local nIndex = Buffadin.Assignments:GetNormal(pName, classId, u.name)
            if nIndex and nIndex > 0 then
                local nCfg = Buffadin.NORMAL_BLESSINGS[nIndex]
                local state = self.buffStates[u.unitId]
                if not state or not state.hasBuff or state.spellName ~= (nCfg and nCfg.name) then
                    targetUnit = u
                    targetSpellName = nCfg and nCfg.name
                    targetSpellId = nCfg and nCfg.spellId or 0
                    targetReason = u.isTank and "Tank Override Blessing" or "Player Override Blessing"
                    break
                end
            end
        end

        -- 2. Check for unit missing standard class blessing
        if not targetUnit then
            local gConfig = Buffadin.GREATER_BLESSINGS[gIndex]
            local gSpellName = gConfig and gConfig.name
            local nEquiv = Buffadin.GREATER_TO_NORMAL[gIndex] or 1
            local nEquivCfg = Buffadin.NORMAL_BLESSINGS[nEquiv]
            local nEquivName = nEquivCfg and nEquivCfg.name

            for _, u in ipairs(classUnits) do
                local nIndex = Buffadin.Assignments:GetNormal(pName, classId, u.name)
                if not (nIndex and nIndex > 0) then
                    local state = self.buffStates[u.unitId]
                    if not state or not state.hasBuff or (state.spellName ~= gSpellName and state.spellName ~= nEquivName) then
                        targetUnit = u
                        targetSpellName = nEquivName
                        targetSpellId = nEquivCfg and nEquivCfg.spellId or 0
                        targetReason = "Single Normal Blessing"
                        break
                    end
                end
            end
        end

        -- 3. Check for unit with lowest remaining expiration
        if not targetUnit then
            local lowestExp = 999999
            for _, u in ipairs(classUnits) do
                local state = self.buffStates[u.unitId]
                if state and state.expires and state.expires < lowestExp then
                    lowestExp = state.expires
                    targetUnit = u
                end
            end
        end

        -- Fallback to first unit if none selected
        if not targetUnit and #classUnits > 0 then
            targetUnit = classUnits[1]
        end

        if targetUnit then
            if not targetSpellName then
                local nIndex = Buffadin.Assignments:GetNormal(pName, classId, targetUnit.name)
                if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
                    targetSpellName = Buffadin.NORMAL_BLESSINGS[nIndex].name
                    targetSpellId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId
                    targetReason = targetUnit.isTank and "Tank Override Blessing" or "Player Override Blessing"
                else
                    local nEquiv = Buffadin.GREATER_TO_NORMAL[gIndex] or 1
                    local nEquivCfg = Buffadin.NORMAL_BLESSINGS[nEquiv]
                    targetSpellName = nEquivCfg and nEquivCfg.name or "Normal Blessing"
                    targetSpellId = nEquivCfg and nEquivCfg.spellId or 0
                    targetReason = "Single Normal Blessing"
                end
            end

            self.buffStates[targetUnit.unitId] = {
                hasBuff = true,
                spellId = targetSpellId,
                spellName = targetSpellName,
                isGreater = false,
                expires = now + 900,
                duration = 900,
            }

            local targetDesc = targetUnit.name .. (targetUnit.isTank and " [Tank]" or "")
            self:LogEvent(category or "NORMAL", targetSpellName, targetDesc, customReason or targetReason)
        else
            self:LogEvent("WARN", "Blessing", clsName, "No alive units found")
        end
    end

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.PlayerPopups and Buffadin.PlayerPopups:IsShown() and Buffadin.PlayerPopups.currentClassId == classId then
        Buffadin.PlayerPopups:ShowForClass(classId, Buffadin.BlessingsBar.buttons[classId])
    end
end

function Mock:CastAutoBuff(isGreater)
    local targetUnit, gSpellId, nSpellId, isGreaterAuto, bestClassId, reasonText = Buffadin.BuffScanner:GetNextAutoBuff()

    if not targetUnit then
        self:LogEvent("INFO", "Auto-Buff", "Raid", "All blessings and auras are currently active!")
        return
    end

    local pName = UnitName("player") or "Player"

    -- 1. Self Aura
    if bestClassId == 0 and targetUnit == "player" then
        local auraIndex = Buffadin.Assignments:GetAura(pName)
        local aConfig = Buffadin.AURAS[auraIndex]
        local aName = aConfig and aConfig.name or "Paladin Aura"
        self.hasAura = true
        self:LogEvent("AUTO", aName, "Player", reasonText or "Activated Assigned Aura")
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:RefreshDisplay()
        return
    end

    -- 2. Class Greater Blessing
    if isGreaterAuto and bestClassId and bestClassId > 0 then
        self:CastClassBlessing(bestClassId, isGreater, "AUTO", reasonText)
        return
    end

    -- 3. Single target unit (override, normal blessing, expiring)
    local now = GetTime()
    local uInfo = Buffadin.Roster.units[targetUnit]
    local sId = (nSpellId and nSpellId > 0) and nSpellId or (gSpellId or 0)
    local sName = Buffadin:GetSpellName(sId)
    if not sName or sName == "" then
        local gIndex = Buffadin.Assignments:GetGreater(pName, uInfo and uInfo.classId or 1)
        local nIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 1
        local nCfg = Buffadin.NORMAL_BLESSINGS[nIndex]
        sName = nCfg and nCfg.name or "Blessing"
        sId = nCfg and nCfg.spellId or 0
    end

    self.buffStates[targetUnit] = {
        hasBuff = true,
        spellId = sId,
        spellName = sName,
        isGreater = false,
        expires = now + 900,
        duration = 900,
    }

    local targetDesc = (uInfo and uInfo.name or targetUnit) .. ((uInfo and uInfo.isTank) and " [Tank]" or "")
    self:LogEvent("AUTO", sName, targetDesc, reasonText or "Single Target Blessing")

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.PlayerPopups and Buffadin.PlayerPopups:IsShown() and uInfo and uInfo.classId == Buffadin.PlayerPopups.currentClassId then
        Buffadin.PlayerPopups:ShowForClass(uInfo.classId, Buffadin.PlayerPopups.currentAnchor)
    end
end

function Mock:CastPlayerPopup(btn)
    local u = btn.unitInfo
    if not u then return end

    local pName = UnitName("player") or "Player"
    local now = GetTime()
    local nIndex = Buffadin.Assignments:GetNormal(pName, u.classId, u.name)
    local spellName = ""
    local spellId = 0
    local reason = ""

    if nIndex and nIndex > 0 and Buffadin.NORMAL_BLESSINGS[nIndex] then
        spellName = Buffadin.NORMAL_BLESSINGS[nIndex].name
        spellId = Buffadin.NORMAL_BLESSINGS[nIndex].spellId or 0
        reason = u.isTank and "Tank Override Blessing" or "Player Override Blessing"
    else
        local gIndex = Buffadin.Assignments:GetGreater(pName, u.classId)
        local nEquiv = Buffadin.GREATER_TO_NORMAL[gIndex] or 1
        local nConfig = Buffadin.NORMAL_BLESSINGS[nEquiv]
        spellName = nConfig and nConfig.name or "Blessing"
        spellId = nConfig and nConfig.spellId or 0
        reason = "Direct Player Blessing"
    end

    self.buffStates[u.unitId] = {
        hasBuff = true,
        spellId = spellId,
        spellName = spellName,
        isGreater = false,
        expires = now + 900,
        duration = 900,
    }

    local targetDesc = u.name .. (u.isTank and " [Tank]" or "")
    self:LogEvent("POPUP", spellName, targetDesc, reason)

    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    if Buffadin.PlayerPopups and Buffadin.PlayerPopups:IsShown() and Buffadin.PlayerPopups.currentClassId == u.classId then
        Buffadin.PlayerPopups:ShowForClass(u.classId, Buffadin.PlayerPopups.currentAnchor)
    end
end

function Mock:ToggleMockAura()
    local pName = UnitName("player") or "Player"
    local aIndex = Buffadin.Assignments:GetAura(pName)
    local aConfig = Buffadin.AURAS[aIndex]
    local aName = aConfig and aConfig.name or "Paladin Aura"

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

function Mock:SimulateCast()
    self:CastAutoBuff(true)
end

-- =========================================================================
-- Harness Lifecycle (Enable / Disable / Preset)
-- =========================================================================

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

    -- Hook addon buttons for direct click simulation
    self:HookInteractiveButtons()

    -- Backup real assignments so mock testing never corrupts player's real setup
    if not self.savedAssignments then
        self.savedAssignments = CopyTable(Buffadin.Assignments.data)
        self.savedNormalAssignments = CopyTable(Buffadin.Assignments.normalData)
        self.savedAuraAssignments = CopyTable(Buffadin.Assignments.auraData)
    end

    -- Pre-populate mock assignments if empty
    self:ApplyDefaultAssignments()

    -- Trigger initial state update
    Buffadin.Roster:Update()
    self:InitializeBuffStates()
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:UpdateLayout()
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

    -- Restore original functions
    if self.origRosterUpdate then Buffadin.Roster.Update = self.origRosterUpdate end
    if self.origBuffScannerScan then Buffadin.BuffScanner.Scan = self.origBuffScannerScan end
    if self.origInCombat then Buffadin.InCombat = self.origInCombat end
    if self.origCanEdit then Buffadin.Roster.CanEditAssignments = self.origCanEdit end

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
        Buffadin.Roster:Update()
        self:InitializeBuffStates()
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:UpdateLayout()
        Buffadin.ManagerFrame:UpdateGrid()
        self:LogEvent("SYSTEM", "Preset Changed", preset, string.format("Switched to %s mode (%d units)", preset, Buffadin.Roster.totalCount or 0))
        self:UpdatePanelStatus()
    end
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

        self.buffStates[u.unitId] = {
            hasBuff = true,
            spellId = spellId,
            spellName = spellName,
            isGreater = isGreater,
            expires = now + duration,
            duration = duration,
        }
        count = count + 1
    end
    Buffadin.BuffScanner:Scan()
    Buffadin.BlessingsBar:RefreshDisplay()
    self:LogEvent("SYSTEM", "Buff All", "All Members", string.format("Set 15m duration on %d units", count))
    Buffadin:Print(string.format("Mock: Applied 15-minute buffs to %d members.", count))
end

function Mock:SetRandomMissing()
    local count = 0
    local droppedNames = {}
    for _, u in pairs(Buffadin.Roster.units) do
        if u.classId == 1 or u.classId == 7 or math.random() > 0.65 then
            self.buffStates[u.unitId] = {
                hasBuff = false,
                spellId = 0,
                spellName = "",
                expires = 0,
                duration = 0,
            }
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
            self.buffStates[u.unitId] = {
                hasBuff = true,
                spellId = gCfg and gCfg.spellId or 0,
                spellName = gCfg and gCfg.name or "Greater Blessing",
                isGreater = true,
                expires = now + 45,
                duration = 900,
            }
        elseif u.classId == 3 then -- Hunters expiring in 110s
            local gIndex = Buffadin.Assignments:GetGreater(pName, 3)
            local gCfg = Buffadin.GREATER_BLESSINGS[gIndex]
            self.buffStates[u.unitId] = {
                hasBuff = true,
                spellId = gCfg and gCfg.spellId or 0,
                spellName = gCfg and gCfg.name or "Greater Blessing",
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

function Mock:ToggleTankOverride()
    local pallyName = UnitName("player") or "Player"
    local current = Buffadin.Assignments:GetNormal(pallyName, 1, "Gorok")

    if current == 6 then
        Buffadin.Assignments:SetNormal(pallyName, 1, "Gorok", 0)
        self:LogEvent("SYSTEM", "Tank Override", "Gorok (Warrior)", "Cleared override (reverted to Might)")
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

function Mock:ToggleCombat()
    self.simulatedCombat = not self.simulatedCombat

    if self.simulatedCombat then
        self:LogEvent("WARN", "Combat State", "In Combat", "Simulated COMBAT START")
        Buffadin:Print("Mock: Simulated |cffff4444COMBAT START|r (checking combat lockdown handling).")
        if Buffadin.db and Buffadin.db.profile.hideInCombat then
            Buffadin.BlessingsBar:Hide()
        end
    else
        self:LogEvent("INFO", "Combat State", "Out of Combat", "Simulated COMBAT END")
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
        panel:Show()
        self:UpdatePanelStatus()
    end
end
