local addonName, Buffadin = ...

Buffadin.Assignments = {
    data = {},         -- [pallyName][classId] = greaterIndex (0-6)
    normalData = {},   -- [pallyName][classId][unitName] = normalIndex (0-9)
    auraData = {},     -- [pallyName] = auraIndex (0-8)
}

-- Step through a 0-indexed spell table, skipping retired (nil) indices
local function StepIndex(tbl, maxIndex, current, step)
    local nextVal = current
    for _ = 0, maxIndex do
        nextVal = nextVal + step
        if nextVal > maxIndex then
            nextVal = 0
        elseif nextVal < 0 then
            nextVal = maxIndex
        end
        if tbl[nextVal] then
            return nextVal
        end
    end
    return 0
end

-- Normalize paladin name so the local player always resolves to UnitName("player")
function Buffadin.Assignments:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" then return "" end
    local playerName = UnitName("player")
    if playerName then
        if pallyName == playerName then
            return playerName
        end
        local short = pallyName:match("^(.-)%-")
        if short and short == playerName then
            return playerName
        end
    end
    return pallyName
end

-- Ensure tables exist for a Paladin
function Buffadin.Assignments:EnsurePaladin(pallyName)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" then return end
    if not self.data[pallyName] then
        self.data[pallyName] = {}
        for _, cls in ipairs(Buffadin.CLASSES) do
            self.data[pallyName][cls.id] = 0
        end
    end
    if not self.normalData[pallyName] then
        self.normalData[pallyName] = {}
        for _, cls in ipairs(Buffadin.CLASSES) do
            self.normalData[pallyName][cls.id] = {}
        end
    end
    if self.auraData[pallyName] == nil then
        self.auraData[pallyName] = 0
    end
end

-- Remove saved assignments that point at retired blessings (Salvation, Light)
function Buffadin.Assignments:MigrateRetiredBlessings()
    local changed = false
    for _, classes in pairs(self.data) do
        for classId, gIndex in pairs(classes) do
            if gIndex ~= 0 and not Buffadin.GREATER_BLESSINGS[gIndex] then
                classes[classId] = 0
                changed = true
            end
        end
    end
    for _, classes in pairs(self.normalData) do
        for _, units in pairs(classes) do
            for unitName, nIndex in pairs(units) do
                if nIndex ~= 0 and not Buffadin.NORMAL_BLESSINGS[nIndex] then
                    units[unitName] = 0
                    changed = true
                end
            end
        end
    end
    if changed then
        Buffadin:Debug("Cleared assignments for retired blessings (Salvation, Light).")
    end
end

-- =========================================================================
-- Getters & Setters
-- =========================================================================

function Buffadin.Assignments:GetGreater(pallyName, classId)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" or not classId then return 0 end
    self:EnsurePaladin(pallyName)
    return self.data[pallyName][classId] or 0
end

function Buffadin.Assignments:SetGreater(pallyName, classId, blessingIndex, skipSync)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" or not classId then return end
    self:EnsurePaladin(pallyName)

    if not skipSync and not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    blessingIndex = math.max(0, math.min(Buffadin.MAX_GREATER_BLESSINGS, blessingIndex or 0))
    if not Buffadin.GREATER_BLESSINGS[blessingIndex] then
        -- Retired blessing (Salvation, Light), e.g. sent by an older client
        blessingIndex = 0
    end
    self.data[pallyName][classId] = blessingIndex

    -- Persist to DB
    if Buffadin.db and Buffadin.db.profile then
        Buffadin.db.profile.assignments = self.data
    end

    if not skipSync then
        self:BroadcastAssignment(pallyName, classId, blessingIndex)
    end

    if Buffadin.OnAssignmentsChanged then
        Buffadin:OnAssignmentsChanged()
    end
end

function Buffadin.Assignments:CycleGreater(pallyName, classId, step)
    if not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    step = step or 1
    local current = self:GetGreater(pallyName, classId)
    local nextVal = StepIndex(Buffadin.GREATER_BLESSINGS, Buffadin.MAX_GREATER_BLESSINGS, current, step)

    self:SetGreater(pallyName, classId, nextVal)
end

function Buffadin.Assignments:GetNormal(pallyName, classId, unitName)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" or not classId or not unitName then return 0 end
    self:EnsurePaladin(pallyName)
    if self.normalData[pallyName][classId] then
        return self.normalData[pallyName][classId][unitName] or 0
    end
    return 0
end

function Buffadin.Assignments:SetNormal(pallyName, classId, unitName, blessingIndex, skipSync)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" or not classId or not unitName then return end
    self:EnsurePaladin(pallyName)

    if not skipSync and not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    blessingIndex = math.max(0, math.min(Buffadin.MAX_NORMAL_BLESSINGS, blessingIndex or 0))
    if not Buffadin.NORMAL_BLESSINGS[blessingIndex] then
        blessingIndex = 0
    end
    self.normalData[pallyName][classId][unitName] = blessingIndex

    if Buffadin.db and Buffadin.db.profile then
        Buffadin.db.profile.normalAssignments = self.normalData
    end

    if not skipSync then
        self:BroadcastNormal(pallyName, classId, unitName, blessingIndex)
    end

    if Buffadin.OnAssignmentsChanged then
        Buffadin:OnAssignmentsChanged()
    end
end

function Buffadin.Assignments:CycleNormal(pallyName, classId, unitName, step)
    pallyName = self:NormalizePaladinName(pallyName)
    if not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    step = step or 1
    local current = self:GetNormal(pallyName, classId, unitName)
    local nextVal = StepIndex(Buffadin.NORMAL_BLESSINGS, Buffadin.MAX_NORMAL_BLESSINGS, current, step)

    self:SetNormal(pallyName, classId, unitName, nextVal)
end

function Buffadin.Assignments:GetAura(pallyName)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" then return 0 end
    self:EnsurePaladin(pallyName)
    return self.auraData[pallyName] or 0
end

function Buffadin.Assignments:SetAura(pallyName, auraIndex, skipSync)
    pallyName = self:NormalizePaladinName(pallyName)
    if not pallyName or pallyName == "" then return end
    self:EnsurePaladin(pallyName)

    if not skipSync and not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    auraIndex = math.max(0, math.min(Buffadin.MAX_AURAS, auraIndex or 0))
    self.auraData[pallyName] = auraIndex

    if Buffadin.db and Buffadin.db.profile then
        Buffadin.db.profile.auraAssignments = self.auraData
    end

    if not skipSync then
        self:BroadcastAura(pallyName, auraIndex)
    end

    if Buffadin.OnAssignmentsChanged then
        Buffadin:OnAssignmentsChanged()
    end
end

function Buffadin.Assignments:CycleAura(pallyName, step)
    pallyName = self:NormalizePaladinName(pallyName)
    if not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can modify assignments.")
        return
    end

    step = step or 1
    local current = self:GetAura(pallyName)
    local nextVal = current + step

    if nextVal > Buffadin.MAX_AURAS then
        nextVal = 0
    elseif nextVal < 0 then
        nextVal = Buffadin.MAX_AURAS
    end

    self:SetAura(pallyName, nextVal)
end

function Buffadin.Assignments:ClearAll()
    if not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can clear assignments.")
        return
    end

    for pallyName in pairs(self.data) do
        for _, cls in ipairs(Buffadin.CLASSES) do
            self.data[pallyName][cls.id] = 0
        end
    end
    for pallyName in pairs(self.normalData) do
        for _, cls in ipairs(Buffadin.CLASSES) do
            self.normalData[pallyName][cls.id] = {}
        end
    end
    for pallyName in pairs(self.auraData) do
        self.auraData[pallyName] = 0
    end

    if Buffadin.db and Buffadin.db.profile then
        Buffadin.db.profile.assignments = self.data
        Buffadin.db.profile.normalAssignments = self.normalData
        Buffadin.db.profile.auraAssignments = self.auraData
    end

    self:BroadcastFullSync()

    if Buffadin.OnAssignmentsChanged then
        Buffadin:OnAssignmentsChanged()
    end
    Buffadin:Print("All blessing assignments cleared.")
end

-- =========================================================================
-- Intelligent Auto-Assign Algorithm
-- =========================================================================

function Buffadin.Assignments:AutoAssign()
    if not Buffadin.Roster:CanEditAssignments() then
        Buffadin:Print("Only the Raid Leader or Raid Assistant can run Auto-Assign.")
        return
    end

    local paladins = Buffadin.Roster.sortedPaladins
    if #paladins == 0 then
        Buffadin:Print("No Paladins in group to assign.")
        return
    end

    -- Roles used to pick blessings per class:
    --   Physical (Warrior, Rogue, Pets): Might
    --   Mana (Priest, Mage, Warlock): Wisdom
    --   Hybrid (Paladin, Hunter, Shaman, Druid): both Might and Wisdom when enough Paladins
    --   Tank classes (Warrior, Paladin, Druid): Sanctuary when a Paladin is free for it
    local physicalClasses = { [1] = true, [3] = true, [4] = true, [10] = true }
    local hybridClasses   = { [2] = true, [3] = true, [6] = true, [9] = true }
    local tankClasses     = { [1] = true, [2] = true, [9] = true }

    local function PrimaryBlessing(classId)
        return physicalClasses[classId] and 2 or 1 -- Might or Wisdom
    end
    local function SecondaryBlessing(classId)
        -- The other of Might/Wisdom, for hybrids only
        if not hybridClasses[classId] then return 0 end
        return physicalClasses[classId] and 1 or 2
    end

    -- Assign Auras to each Paladin
    -- Pally 1: Devotion (1)
    -- Pally 2: Retribution (2)
    -- Pally 3: Concentration (3)
    -- Pally 4: Shadow Res (4)
    -- Pally 5: Frost Res (5)
    -- Pally 6: Fire Res (6)
    -- Pally 7: Sanctity (7)
    -- Pally 8: Crusader (8)
    for i, pallyName in ipairs(paladins) do
        local auraId = math.min(i, Buffadin.MAX_AURAS)
        self:SetAura(pallyName, auraId, true)
    end

    -- Blessing slots in priority order, one per Paladin:
    --   1 Paladin:  Might/Wisdom
    --   2 Paladins: Kings, Might/Wisdom
    --   3 Paladins: Kings, Might/Wisdom, Sanctuary (tank classes)
    --   4 Paladins: Kings, Might/Wisdom, Sanctuary (tank classes), Wisdom/Might (hybrids)
    --   5+:         left unassigned
    local slots
    if #paladins == 1 then
        slots = { PrimaryBlessing }
    else
        slots = {
            function() return 3 end, -- Kings
            PrimaryBlessing,
            function(classId) return tankClasses[classId] and 6 or 0 end, -- Sanctuary
            SecondaryBlessing,
        }
    end

    for i, pallyName in ipairs(paladins) do
        local slot = slots[i]
        for _, cls in ipairs(Buffadin.CLASSES) do
            self:SetGreater(pallyName, cls.id, slot and slot(cls.id) or 0, true)
        end
    end

    self:BroadcastFullSync()

    if Buffadin.OnAssignmentsChanged then
        Buffadin:OnAssignmentsChanged()
    end
    Buffadin:Print("Auto-assign complete for " .. #paladins .. " Paladin(s).")
end

-- =========================================================================
-- Blessings Report to Chat
-- =========================================================================

function Buffadin.Assignments:Report(channel)
    channel = channel or (Buffadin.db and Buffadin.db.profile and Buffadin.db.profile.reportChannel) or "RAID"
    if not Buffadin:IsInGroup() and not Buffadin:IsInRaid() then
        channel = "SAY"
    elseif not Buffadin:IsInRaid() and channel == "RAID" then
        channel = "PARTY"
    end

    SendChatMessage("[Buffadin] Blessing Assignments:", channel)

    for _, pallyName in ipairs(Buffadin.Roster.sortedPaladins) do
        local parts = {}
        for _, cls in ipairs(Buffadin.CLASSES) do
            local gIndex = self:GetGreater(pallyName, cls.id)
            if gIndex > 0 then
                local bName = Buffadin.GREATER_BLESSINGS[gIndex] and Buffadin.GREATER_BLESSINGS[gIndex].name:gsub("Greater Blessing of ", "") or "Buff"
                local clsAbbr = cls.name:sub(1, 3):upper()
                table.insert(parts, clsAbbr .. ": " .. bName)
            end
        end

        local auraIndex = self:GetAura(pallyName)
        local auraText = ""
        if auraIndex > 0 and Buffadin.AURAS[auraIndex] then
            auraText = " [Aura: " .. Buffadin.AURAS[auraIndex].name:gsub(" Aura", "") .. "]"
        end

        local reportLine = " - " .. pallyName .. auraText .. ": " .. ((#parts > 0) and table.concat(parts, ", ") or "No blessings")
        SendChatMessage(reportLine, channel)
    end
end

-- =========================================================================
-- Addon Messaging & Synchronization
-- =========================================================================

function Buffadin.Assignments:BroadcastAssignment(pallyName, classId, blessingIndex)
    local msg = string.format("ASSIGN;%s;%d;%d", pallyName, classId, blessingIndex)
    Buffadin:SendComm(Buffadin.COMM_PREFIX, msg)
end

function Buffadin.Assignments:BroadcastNormal(pallyName, classId, unitName, blessingIndex)
    local msg = string.format("NORMAL;%s;%d;%s;%d", pallyName, classId, unitName, blessingIndex)
    Buffadin:SendComm(Buffadin.COMM_PREFIX, msg)
end

function Buffadin.Assignments:BroadcastAura(pallyName, auraIndex)
    local msg = string.format("AURA;%s;%d", pallyName, auraIndex)
    Buffadin:SendComm(Buffadin.COMM_PREFIX, msg)
end

function Buffadin.Assignments:BroadcastFullSync()
    for _, pallyName in ipairs(Buffadin.Roster.sortedPaladins) do
        local assignments = {}
        for _, cls in ipairs(Buffadin.CLASSES) do
            local gIndex = self:GetGreater(pallyName, cls.id)
            table.insert(assignments, string.format("%d=%d", cls.id, gIndex))
        end
        local auraIndex = self:GetAura(pallyName)
        local msg = string.format("SYNC;%s;%s;%d", pallyName, table.concat(assignments, ","), auraIndex)
        Buffadin:SendComm(Buffadin.COMM_PREFIX, msg)
    end
end

function Buffadin.Assignments:RequestSync()
    Buffadin:SendComm(Buffadin.COMM_PREFIX, "REQ")
end

-- Handle incoming messages from party/raid
function Buffadin.Assignments:OnMessageReceived(prefix, message, channel, sender)
    if not message or message == "" then return end

    if prefix == Buffadin.COMM_PREFIX then
        local parts = { strsplit(";", message) }
        local cmd = parts[1]

        if cmd == "REQ" then
            -- Only leader/assist responds to full sync request
            if Buffadin.Roster:CanEditAssignments() then
                self:BroadcastFullSync()
            end
        elseif cmd == "ASSIGN" then
            local pallyName = parts[2]
            local classId = tonumber(parts[3])
            local blessingIndex = tonumber(parts[4])
            if pallyName and classId and blessingIndex then
                self:SetGreater(pallyName, classId, blessingIndex, true)
            end
        elseif cmd == "NORMAL" then
            local pallyName = parts[2]
            local classId = tonumber(parts[3])
            local unitName = parts[4]
            local blessingIndex = tonumber(parts[5])
            if pallyName and classId and unitName and blessingIndex then
                self:SetNormal(pallyName, classId, unitName, blessingIndex, true)
            end
        elseif cmd == "AURA" then
            local pallyName = parts[2]
            local auraIndex = tonumber(parts[3])
            if pallyName and auraIndex then
                self:SetAura(pallyName, auraIndex, true)
            end
        elseif cmd == "SYNC" then
            local pallyName = parts[2]
            local assignString = parts[3]
            local auraIndex = tonumber(parts[4])

            if pallyName and assignString then
                self:EnsurePaladin(pallyName)
                for pair in string.gmatch(assignString, "([^,]+)") do
                    local cid, bidx = strsplit("=", pair)
                    cid = tonumber(cid)
                    bidx = tonumber(bidx)
                    if cid and bidx then
                        self:SetGreater(pallyName, cid, bidx, true)
                    end
                end
                if auraIndex then
                    self:SetAura(pallyName, auraIndex, true)
                end
            end
        -- SALV / SALVSYNC / NOSALV (Salvation, removed from the game) from older clients are ignored
        elseif cmd == "FREEASSIGN" then
            local val = tonumber(parts[2]) == 1
            if Buffadin.db and Buffadin.db.profile then
                Buffadin.db.profile.freeAssign = val
            end
            if Buffadin.OnAssignmentsChanged then
                Buffadin:OnAssignmentsChanged()
            end
        end
    end
end
