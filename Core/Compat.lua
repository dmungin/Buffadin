local addonName, Buffadin = ...
_G["Buffadin"] = Buffadin

Buffadin.version = "0.1.1"
Buffadin.addonName = addonName
Buffadin.combatQueue = {}

-- Safe print
function Buffadin:Print(msg)
    print("|cffF58CBA[Buffadin]|r " .. tostring(msg))
end

function Buffadin:Debug(msg)
    if Buffadin.db and Buffadin.db.profile and Buffadin.db.profile.debug then
        print("|cffF58CBA[Buffadin-Debug]|r " .. tostring(msg))
    end
end

-- =========================================================================
-- Spell API Compatibility Layer
-- =========================================================================

function Buffadin:GetSpellInfo(spellID)
    if not spellID or spellID == 0 then return nil end

    -- Modern Dragonflight / The War Within / 1.60 C_Spell API
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
        end
    end

    -- Classic / Legacy GetSpellInfo
    if _G.GetSpellInfo then
        return _G.GetSpellInfo(spellID)
    end

    return nil
end

function Buffadin:GetSpellName(spellID)
    if not spellID or spellID == 0 then return "" end

    if C_Spell and C_Spell.GetSpellName then
        local name = C_Spell.GetSpellName(spellID)
        if name and name ~= "" then return name end
    end

    local name = self:GetSpellInfo(spellID)
    if name and name ~= "" then return name end

    -- Fallback to predefined constants table if client API returns nil
    for _, g in pairs(self.GREATER_BLESSINGS or {}) do
        if g.spellId == spellID then return g.name end
    end
    for _, n in pairs(self.NORMAL_BLESSINGS or {}) do
        if n.spellId == spellID then return n.name end
    end
    for _, a in pairs(self.AURAS or {}) do
        if a.spellId == spellID then return a.name end
    end
    if self.RIGHTEOUS_FURY and self.RIGHTEOUS_FURY.spellId == spellID then
        return self.RIGHTEOUS_FURY.name
    end
    for _, s in pairs(self.SEALS or {}) do
        if s.spellId == spellID then return s.name end
    end

    return ""
end

function Buffadin:GetSpellTexture(spellID)
    if not spellID or spellID == 0 then return "" end

    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then return tex end
    end

    local _, _, tex = self:GetSpellInfo(spellID)
    return tex or ""
end

function Buffadin:IsSpellKnown(spellID)
    if not spellID or spellID == 0 then return false end

    -- Mock Harness override: treat all Paladin spells as known when mock mode is active
    if Buffadin.MockHarness and Buffadin.MockHarness.active then
        return true
    end

    if C_Spell and C_Spell.IsSpellKnown then
        if C_Spell.IsSpellKnown(spellID) then return true end
    end

    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end

    if _G.IsSpellKnown and _G.IsSpellKnown(spellID) then
        return true
    end

    -- Fallback: check spellbook if needed
    local name = self:GetSpellName(spellID)
    if name and name ~= "" and GetSpellInfo then
        local known = GetSpellInfo(name)
        if known then return true end
    end

    return false
end

-- =========================================================================
-- Range Checking (Prioritizes nearby targets; defaults to true so it never blocks)
-- =========================================================================

function Buffadin:IsUnitInRange(unit, spellID, spellName)
    -- Mock Harness override: mock units are always considered in range
    if Buffadin.MockHarness and Buffadin.MockHarness.active then
        return true
    end

    if not unit or not UnitExists(unit) or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
        return false
    end
    if UnitIsUnit(unit, "player") then
        return true
    end

    -- Modern Dragonflight / The War Within C_Spell API
    if spellID and C_Spell and C_Spell.IsSpellInRange then
        local ok, inRange = pcall(C_Spell.IsSpellInRange, spellID, unit)
        if ok and inRange ~= nil then
            return (inRange == true or inRange == 1)
        end
    end

    -- Legacy IsSpellInRange
    if spellName and _G.IsSpellInRange then
        local ok, inRange = pcall(_G.IsSpellInRange, spellName, unit)
        if ok and inRange ~= nil then
            return (inRange == true or inRange == 1)
        end
    end

    -- Standard 40y range check fallback
    if UnitInRange then
        local ok, inRange = pcall(UnitInRange, unit)
        if ok and inRange ~= nil then
            return (inRange == true or inRange == 1)
        end
    end

    return true -- Default to true if range APIs are uncertain so buffing is never blocked
end

-- =========================================================================
-- Unit Aura Compatibility Layer (Safe pcall & issecretvalue protection)
-- =========================================================================

function Buffadin:GetUnitBuffs(unit)
    local buffs = {}
    if not unit or not UnitExists(unit) then return buffs end

    local isSecret = function(v)
        return issecretvalue and issecretvalue(v)
    end

    -- Modern WoW 10.0+ / 11.0+ / 1.60 C_UnitAuras API
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local index = 1
        while true do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HELPFUL")
            if not ok or not aura or isSecret(aura) then break end

            local sId = aura.spellId
            local expTime = aura.expirationTime
            local dur = aura.duration
            if not isSecret(sId) and not isSecret(expTime) then
                table.insert(buffs, {
                    name = aura.name,
                    icon = aura.icon,
                    count = aura.applications or 1,
                    duration = dur or 0,
                    expirationTime = expTime or 0,
                    spellId = sId,
                    sourceUnit = aura.sourceUnit,
                })
            end
            index = index + 1
        end
        return buffs
    end

    -- Legacy UnitBuff / UnitAura API
    local index = 1
    while true do
        local ok, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId
        if UnitAura then
            ok, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = pcall(UnitAura, unit, index, "HELPFUL")
        elseif UnitBuff then
            ok, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = pcall(UnitBuff, unit, index)
        end
        if not ok or not name or isSecret(name) then break end

        if not isSecret(spellId) and not isSecret(expirationTime) then
            table.insert(buffs, {
                name = name,
                icon = icon,
                count = count or 1,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                spellId = spellId or 0,
                sourceUnit = unitCaster,
            })
        end
        index = index + 1
    end

    return buffs
end

function Buffadin:FindUnitBuff(unit, targetSpellID, targetSpellName)
    -- Mock Harness override: query simulated game world
    if Buffadin.MockHarness and Buffadin.MockHarness.active then
        return Buffadin.MockHarness:GetUnitAura(unit, targetSpellID, targetSpellName)
    end

    if not unit or not UnitExists(unit) then return false, 0, 0 end

    -- Check modern C_UnitAuras.GetPlayerAuraBySpellID if on player
    if unit == "player" and targetSpellID and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(targetSpellID)
        if aura then
            return true, aura.expirationTime or 0, aura.duration or 0
        end
    end

    local buffs = self:GetUnitBuffs(unit)
    for _, buff in ipairs(buffs) do
        if (targetSpellID and buff.spellId == targetSpellID) or
           (targetSpellName and buff.name and buff.name == targetSpellName) then
            return true, buff.expirationTime, buff.duration
        end
    end

    return false, 0, 0
end

-- =========================================================================
-- Addon Messaging Compatibility Layer
-- =========================================================================

function Buffadin:RegisterComm(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif _G.RegisterAddonMessagePrefix then
        return _G.RegisterAddonMessagePrefix(prefix)
    end
    return false
end

function Buffadin:SendComm(prefix, message, channel, target)
    if not channel then
        if IsInRaid() then
            channel = "RAID"
        elseif IsInGroup() then
            channel = "PARTY"
        else
            return false
        end
    end

    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        return C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
    elseif _G.SendAddonMessage then
        return _G.SendAddonMessage(prefix, message, channel, target)
    end
    return false
end

-- =========================================================================
-- Combat Lockdown Queue Management
-- =========================================================================

function Buffadin:InCombat()
    if self.MockHarness and self.MockHarness.active then
        return self.MockHarness.simulatedCombat == true
    end
    return InCombatLockdown()
end

function Buffadin:RunOutOfCombat(callback, key)
    if not self:InCombat() then
        callback()
        return
    end

    key = key or tostring(callback)
    self.combatQueue[key] = callback
end

function Buffadin:ProcessCombatQueue()
    if self:InCombat() then return end

    local queue = self.combatQueue
    self.combatQueue = {}

    for _, cb in pairs(queue) do
        local success, err = pcall(cb)
        if not success then
            self:Debug("Combat queue callback error: " .. tostring(err))
        end
    end
end

-- =========================================================================
-- Frame Construction Helpers
-- =========================================================================

function Buffadin:CreateBackdropFrame(frameType, name, parent, template)
    template = template or ""
    if BackdropTemplateMixin and not string.find(template, "BackdropTemplate") then
        template = (template == "") and "BackdropTemplate" or (template .. ",BackdropTemplate")
    end
    return CreateFrame(frameType, name, parent, template)
end

-- =========================================================================
-- Roster & Unit Query Compatibility Layer (Adapter Pattern)
-- =========================================================================

function Buffadin:GetGroupMembers()
    if self.MockHarness and self.MockHarness.active then
        return self.MockHarness:GetMockUnitList()
    end

    local unitList = {}
    if IsInRaid() then
        local count = GetNumGroupMembers()
        for i = 1, count do
            table.insert(unitList, "raid" .. i)
        end
    elseif IsInGroup() then
        table.insert(unitList, "player")
        local count = GetNumGroupMembers()
        for i = 1, count - 1 do
            table.insert(unitList, "party" .. i)
        end
    else
        table.insert(unitList, "player")
    end
    return unitList
end

function Buffadin:UnitExists(unit)
    if self.MockHarness and self.MockHarness.active then
        return (self.MockHarness.mockUnits and self.MockHarness.mockUnits[unit] ~= nil) or unit == "player"
    end
    if not unit then return false end
    return UnitExists(unit)
end

function Buffadin:GetUnitInfo(unit)
    if self.MockHarness and self.MockHarness.active then
        return self.MockHarness:GetMockUnitInfo(unit)
    end

    if not self:UnitExists(unit) then
        return false
    end

    local name, realm = UnitName(unit)
    if not name or name == "" then
        return false
    end

    local fullName = realm and (realm ~= "") and (name .. "-" .. realm) or name
    local _, classToken = UnitClass(unit)
    local isTank = false
    if UnitGroupRolesAssigned then
        isTank = (UnitGroupRolesAssigned(unit) == "TANK")
    end
    if not isTank and GetPartyAssignment then
        isTank = (GetPartyAssignment("MAINTANK", unit) == true)
    end

    local isDead = UnitIsDeadOrGhost(unit)
    local isOnline = UnitIsConnected(unit)
    local isVisible = UnitIsVisible(unit)
    local isLeader = UnitIsGroupLeader(unit)
    local isAssist = UnitIsGroupAssistant(unit)

    return true, name, fullName, classToken, isTank, isDead, isOnline, isVisible, isLeader, isAssist
end

function Buffadin:IsUnitPlayer(unit)
    if self.MockHarness and self.MockHarness.active then
        return unit == "player" or (self.MockHarness.IsMockUnitPlayer and self.MockHarness:IsMockUnitPlayer(unit))
    end
    return UnitIsUnit(unit, "player")
end

function Buffadin:IsInRaid()
    if self.MockHarness and self.MockHarness.active then
        return self.MockHarness.currentPreset == "RAID25" or self.MockHarness.currentPreset == "RAID40"
    end
    return IsInRaid()
end

function Buffadin:IsInGroup()
    if self.MockHarness and self.MockHarness.active then
        return self.MockHarness.currentPreset ~= "SOLO"
    end
    return IsInGroup()
end


