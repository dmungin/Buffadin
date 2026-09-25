local addonName, Buffadin = ...

Buffadin.BuffScanner = {
    classStatus = {}, -- [classId] = { status, missingCount, totalCount, minExpiration, assignedGSpell, assignedNSpell }
    unitStatus = {},  -- [unitId] = { hasBuff, expiration, assignedSpellId }
    selfStatus = {
        hasAura = false,
        auraSpellId = 0,
        hasRighteousFury = false,
        rfAbsExpiration = 0,
        hasSeal = false,
        sealName = "",
    }
}

-- Initialize status table
for _, cls in ipairs(Buffadin.CLASSES) do
    Buffadin.BuffScanner.classStatus[cls.id] = {
        status = "Disabled",
        missingCount = 0,
        totalCount = 0,
        minExpiration = 0,
        assignedGSpell = 0,
        assignedNSpell = 0,
    }
end

function Buffadin.BuffScanner:Scan()
    local playerName = UnitName("player")
    local currentTime = GetTime()

    -- Modern WoW engines (like WoW: Forever) restrict or block querying unit auras (C_UnitAuras / UnitAura) during combat.
    if Buffadin:InCombat() then
        self:UpdateInCombat(playerName, currentTime)
        return
    end

    -- 1. Scan Class & Unit Blessings
    for classId, units in pairs(Buffadin.Roster.classes) do
        local gIndex = Buffadin.Assignments:GetGreater(playerName, classId)
        local gSpellConfig = Buffadin.GREATER_BLESSINGS[gIndex]
        local gSpellId = gSpellConfig and gSpellConfig.spellId or 0
        local gSpellName = (gSpellId > 0) and Buffadin:GetSpellName(gSpellId) or ""

        local nEquivIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0
        local nEquivConfig = Buffadin.NORMAL_BLESSINGS[nEquivIndex]
        local nEquivId = nEquivConfig and nEquivConfig.spellId or 0
        local nEquivName = (nEquivId > 0) and Buffadin:GetSpellName(nEquivId) or ""

        local totalAlive = 0
        local missingCount = 0
        local classMissingCount = 0
        local specialMissingCount = 0
        local minExpiration = 99999
        local hasSpecialMissing = false

        for _, unitInfo in ipairs(units) do
            local unit = unitInfo.unitId
            local isDead = Buffadin:IsUnitDead(unit)
            local isOnline = Buffadin:IsUnitConnected(unit)

            -- Check if this specific unit has a Normal Blessing override assigned
            local nIndex = Buffadin.Assignments:GetNormal(playerName, classId, unitInfo.name)
            local targetGSpellId = gSpellId
            local targetGSpellName = gSpellName
            local targetNSpellId = nEquivId
            local targetNSpellName = nEquivName
            local isSpecial = false

            if nIndex and nIndex > 0 then
                local nSpellConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
                targetNSpellId = nSpellConfig and nSpellConfig.spellId or 0
                targetNSpellName = (targetNSpellId > 0) and Buffadin:GetSpellName(targetNSpellId) or ""
                targetGSpellId = 0
                targetGSpellName = ""
                isSpecial = true
            end

            if Buffadin:UnitExists(unit) and not isDead and isOnline then
                totalAlive = totalAlive + 1

                local hasBuff = false
                local expTime = 0
                local duration = 0

                -- 1. Check for Greater Blessing
                if targetGSpellId > 0 or targetGSpellName ~= "" then
                    hasBuff, expTime, duration = Buffadin:FindUnitBuff(unit, targetGSpellId, targetGSpellName)
                end

                -- 2. If no Greater Blessing, check for Normal Blessing equivalent or override
                if not hasBuff and (targetNSpellId > 0 or targetNSpellName ~= "") then
                    hasBuff, expTime, duration = Buffadin:FindUnitBuff(unit, targetNSpellId, targetNSpellName)
                end

                local remaining = 0
                local absExp = 0
                if hasBuff and expTime and expTime > 0 then
                    remaining = math.max(0, expTime - currentTime)
                    absExp = expTime
                    if remaining < minExpiration then
                        minExpiration = remaining
                    end
                elseif hasBuff then
                    -- Buff exists without expiration or long duration
                    remaining = duration or 900
                    absExp = currentTime + remaining
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

                self.unitStatus[unit] = {
                    hasBuff = hasBuff,
                    expiration = remaining,
                    absExpiration = absExp,
                    assignedGSpellId = targetGSpellId,
                    assignedNSpellId = targetNSpellId,
                    assignedSpellName = (targetGSpellName ~= "") and targetGSpellName or targetNSpellName,
                    isSpecial = isSpecial,
                    diedInCombat = false,
                }
            elseif Buffadin:UnitExists(unit) then
                -- Dead or offline unit: populate assignments but marked as unbuffed
                self.unitStatus[unit] = {
                    hasBuff = false,
                    expiration = 0,
                    absExpiration = 0,
                    assignedGSpellId = targetGSpellId,
                    assignedNSpellId = targetNSpellId,
                    assignedSpellName = (targetGSpellName ~= "") and targetGSpellName or targetNSpellName,
                    isSpecial = isSpecial,
                    diedInCombat = isDead,
                }
            end
        end

        -- Determine class overall status
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

        self.classStatus[classId] = {
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

    -- 2. Scan Paladin Self Auras, Righteous Fury, and Seals
    local assignedAuraIndex = Buffadin.Assignments:GetAura(playerName)
    local assignedAuraConfig = Buffadin.AURAS[assignedAuraIndex]
    local targetAuraSpellId = assignedAuraConfig and assignedAuraConfig.spellId or 0
    local targetAuraName = (targetAuraSpellId > 0) and Buffadin:GetSpellName(targetAuraSpellId) or ""

    if targetAuraSpellId > 0 or targetAuraName ~= "" then
        self.selfStatus.hasAura = Buffadin:FindUnitBuff("player", targetAuraSpellId, targetAuraName)
    else
        self.selfStatus.hasAura = true
    end
    self.selfStatus.auraSpellId = targetAuraSpellId

    -- Righteous Fury
    local rfSpellId = Buffadin.RIGHTEOUS_FURY.spellId
    local rfName = Buffadin:GetSpellName(rfSpellId)
    local hasRF, rfExp, rfDur = Buffadin:FindUnitBuff("player", rfSpellId, rfName)
    self.selfStatus.hasRighteousFury = hasRF
    self.selfStatus.rfAbsExpiration = (hasRF and rfExp and rfExp > 0) and rfExp or ((hasRF and rfDur) and (currentTime + rfDur) or (hasRF and (currentTime + 1800) or 0))

    -- Seals
    local hasSeal = false
    local sealName = ""
    for _, seal in pairs(Buffadin.SEALS) do
        if seal.spellId > 0 then
            local sName = Buffadin:GetSpellName(seal.spellId)
            local found = Buffadin:FindUnitBuff("player", seal.spellId, sName)
            if found then
                hasSeal = true
                sealName = sName
                break
            end
        end
    end
    self.selfStatus.hasSeal = hasSeal
    self.selfStatus.sealName = sealName

    if Buffadin.OnBuffsScanned then
        Buffadin:OnBuffsScanned()
    end
end

-- =========================================================================
-- Combat Aura State Maintenance (Countdown timers & death tracking without API queries)
-- =========================================================================
function Buffadin.BuffScanner:UpdateInCombat(playerName, currentTime)
    -- 1. Update Class & Unit Blessings using cached status & countdown timers
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
            local unit = unitInfo.unitId
            local isDead = Buffadin:IsUnitDead(unit)
            local isOnline = Buffadin:IsUnitConnected(unit)
            local uStatus = self.unitStatus[unit]

            if isDead then
                -- Unit is dead: death strips all blessings and buffs
                if uStatus then
                    uStatus.hasBuff = false
                    uStatus.expiration = 0
                    uStatus.absExpiration = 0
                    uStatus.diedInCombat = true
                end
                -- Dead units are excluded from totalAlive and missingCount
            elseif Buffadin:UnitExists(unit) and isOnline then
                -- Unit is alive and online
                totalAlive = totalAlive + 1

                if uStatus then
                    -- If unit died in combat and was battle rezzed, death stripped all buffs!
                    -- They remain missing (hasBuff = false) until rebuffed or combat ends.
                    if uStatus.diedInCombat then
                        uStatus.hasBuff = false
                        uStatus.expiration = 0
                        uStatus.absExpiration = 0
                    elseif uStatus.hasBuff then
                        if uStatus.absExpiration and uStatus.absExpiration > 0 then
                            local remaining = uStatus.absExpiration - currentTime
                            if remaining <= 0 then
                                uStatus.hasBuff = false
                                uStatus.expiration = 0
                            else
                                uStatus.expiration = remaining
                                if remaining < minExpiration then
                                    minExpiration = remaining
                                end
                            end
                        else
                            if uStatus.expiration and uStatus.expiration > 0 and uStatus.expiration < minExpiration then
                                minExpiration = uStatus.expiration
                            end
                        end
                    end

                    if not uStatus.hasBuff then
                        missingCount = missingCount + 1
                        if uStatus.isSpecial then
                            hasSpecialMissing = true
                            specialMissingCount = specialMissingCount + 1
                        else
                            classMissingCount = classMissingCount + 1
                        end
                    end
                else
                    missingCount = missingCount + 1
                    classMissingCount = classMissingCount + 1
                end
            end
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

        self.classStatus[classId] = {
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

    -- 2. Maintain Paladin Self Auras & Righteous Fury
    if Buffadin:IsUnitDead("player") then
        self.selfStatus.hasAura = false
        self.selfStatus.hasRighteousFury = false
        self.selfStatus.rfAbsExpiration = 0
        self.selfStatus.hasSeal = false
        self.selfStatus.sealName = ""
    else
        -- If paladin is alive, count down Righteous Fury timer
        if self.selfStatus.hasRighteousFury and self.selfStatus.rfAbsExpiration and self.selfStatus.rfAbsExpiration > 0 then
            if currentTime >= self.selfStatus.rfAbsExpiration then
                self.selfStatus.hasRighteousFury = false
            end
        end
    end

    if Buffadin.OnBuffsScanned then
        Buffadin:OnBuffsScanned()
    end
end

-- Find next best target/spell to buff (used by Auto-Buff button)
-- Returns: targetUnit, gSpellId, nSpellId, isGreater, classId, reasonText
function Buffadin.BuffScanner:GetNextAutoBuff()
    local playerName = UnitName("player")

    -- 1. Check self aura if missing
    local assignedAuraIndex = Buffadin.Assignments:GetAura(playerName)
    if assignedAuraIndex > 0 and not self.selfStatus.hasAura then
        local auraConfig = Buffadin.AURAS[assignedAuraIndex]
        if auraConfig and auraConfig.spellId > 0 then
            local aName = Buffadin:GetSpellName(auraConfig.spellId)
            return "player", auraConfig.spellId, auraConfig.spellId, false, 0, "Self Aura: " .. aName
        end
    end

    -- 2. Check classes needing Greater / Normal Blessings (Prioritize class with highest missing count)
    local bestClassId = nil
    local maxMissing = 0
    local targetUnit = nil

    for classId, statusInfo in pairs(self.classStatus) do
        local classNeed = statusInfo.classMissingCount or statusInfo.missingCount
        if statusInfo.assignedGSpell > 0 and classNeed > 0 then
            if classNeed > maxMissing then
                -- Find first reachable/visible alive unit of this class missing the buff (prefer in-range, then any unbuffed)
                local inRangeUnit = nil
                local fallbackUnit = nil
                local gCfg = Buffadin.GREATER_BLESSINGS[statusInfo.assignedGSpell]
                local sId = gCfg and gCfg.spellId or 0
                for _, u in ipairs(Buffadin.Roster.classes[classId]) do
                    local uStatus = self.unitStatus[u.unitId]
                    if uStatus and not uStatus.hasBuff and not uStatus.isSpecial and not u.isDead and u.isOnline and u.isVisible then
                        if not fallbackUnit then fallbackUnit = u.unitId end
                        if Buffadin:IsUnitInRange(u.unitId, sId) then
                            inRangeUnit = u.unitId
                            break
                        end
                    end
                end
                local chosen = inRangeUnit or fallbackUnit
                if chosen then
                    maxMissing = classNeed
                    bestClassId = classId
                    targetUnit = chosen
                end
            end
        end
    end

    if bestClassId and targetUnit then
        local gIndex = self.classStatus[bestClassId].assignedGSpell
        local gSpellConfig = Buffadin.GREATER_BLESSINGS[gIndex]
        local gSpellId = gSpellConfig and gSpellConfig.spellId or 0

        local nIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0
        local nSpellConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
        local nSpellId = nSpellConfig and nSpellConfig.spellId or 0

        local cls = Buffadin.CLASS_BY_ID[bestClassId]
        local clsName = cls and cls.name or "Class"
        local reason = string.format("%s (%d missing)", clsName, maxMissing)

        return targetUnit, gSpellId, nSpellId, true, bestClassId, reason
    end

    -- 3. Check individual Normal Blessing overrides (e.g. Tank needing Sanctuary/Might)
    for classId, units in pairs(Buffadin.Roster.classes) do
        for _, u in ipairs(units) do
            local nIndex = Buffadin.Assignments:GetNormal(playerName, classId, u.name)
            if nIndex and nIndex > 0 then
                local uStatus = self.unitStatus[u.unitId]
                if uStatus and not uStatus.hasBuff and not u.isDead and u.isOnline and u.isVisible then
                    local nSpellConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
                    if nSpellConfig and nSpellConfig.spellId > 0 then
                        local reason = string.format("%s (Override: %s)", u.name, nSpellConfig.name)
                        return u.unitId, nSpellConfig.spellId, nSpellConfig.spellId, false, classId, reason
                    end
                end
            end
        end
    end

    -- 4. Check expiring blessings (< 2 minutes remaining)
    local expiringClassId = nil
    local lowestTime = 120 -- 2 minutes threshold
    local expiringTarget = nil

    for classId, statusInfo in pairs(self.classStatus) do
        if statusInfo.assignedGSpell > 0 and statusInfo.minExpiration > 0 and statusInfo.minExpiration < lowestTime then
            local inRangeTarget = nil
            local fallbackTarget = nil
            local gCfg = Buffadin.GREATER_BLESSINGS[statusInfo.assignedGSpell]
            local sId = gCfg and gCfg.spellId or 0
            for _, u in ipairs(Buffadin.Roster.classes[classId]) do
                if not u.isDead and u.isOnline and u.isVisible then
                    if not fallbackTarget then fallbackTarget = u.unitId end
                    if Buffadin:IsUnitInRange(u.unitId, sId) then
                        inRangeTarget = u.unitId
                        break
                    end
                end
            end
            local chosen = inRangeTarget or fallbackTarget
            if chosen then
                lowestTime = statusInfo.minExpiration
                expiringClassId = classId
                expiringTarget = chosen
            end
        end
    end

    if expiringClassId and expiringTarget then
        local gIndex = self.classStatus[expiringClassId].assignedGSpell
        local gSpellConfig = Buffadin.GREATER_BLESSINGS[gIndex]
        local gSpellId = gSpellConfig and gSpellConfig.spellId or 0

        local nIndex = Buffadin.GREATER_TO_NORMAL[gIndex] or 0
        local nSpellConfig = Buffadin.NORMAL_BLESSINGS[nIndex]
        local nSpellId = nSpellConfig and nSpellConfig.spellId or 0

        local cls = Buffadin.CLASS_BY_ID[expiringClassId]
        local clsName = cls and cls.name or "Class"
        local reason = string.format("%s (expiring in %ds)", clsName, math.floor(lowestTime))

        return expiringTarget, gSpellId, nSpellId, true, expiringClassId, reason
    end

    return nil, nil, nil, nil, nil, nil
end
