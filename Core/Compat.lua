local addonName, Buffadin = ...
_G["Buffadin"] = Buffadin

Buffadin.version = "1.0.0"
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
    return name or ""
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
-- Unit Aura Compatibility Layer
-- =========================================================================

function Buffadin:GetUnitBuffs(unit)
    local buffs = {}
    if not unit or not UnitExists(unit) then return buffs end

    -- Modern WoW 10.0+ / 11.0+ / 1.60 C_UnitAuras API
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local index = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
            if not aura then break end
            table.insert(buffs, {
                name = aura.name,
                icon = aura.icon,
                count = aura.applications or 1,
                duration = aura.duration or 0,
                expirationTime = aura.expirationTime or 0,
                spellId = aura.spellId,
                sourceUnit = aura.sourceUnit,
            })
            index = index + 1
        end
        return buffs
    end

    -- Legacy UnitBuff / UnitAura API
    local index = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId
        if UnitAura then
            name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitAura(unit, index, "HELPFUL")
        elseif UnitBuff then
            name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitBuff(unit, index)
        end
        if not name then break end

        table.insert(buffs, {
            name = name,
            icon = icon,
            count = count or 1,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            spellId = spellId or 0,
            sourceUnit = unitCaster,
        })
        index = index + 1
    end

    return buffs
end

function Buffadin:FindUnitBuff(unit, targetSpellID, targetSpellName)
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
