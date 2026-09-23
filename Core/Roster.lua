local addonName, Buffadin = ...

Buffadin.Roster = {
    units = {},            -- [unitId] = unitInfo
    classes = {},          -- [classId] = list of units
    paladins = {},         -- [pallyName] = pallyInfo
    sortedPaladins = {},   -- array of pallyNames
    totalCount = 0,
    paladinCount = 0,
}

for _, cls in ipairs(Buffadin.CLASSES) do
    Buffadin.Roster.classes[cls.id] = {}
end

-- =========================================================================
-- Permission Check
-- =========================================================================
function Buffadin.Roster:CanEditAssignments()
    -- Solo or in a 5-man party: always allow free assignment
    if not IsInRaid() then
        return true
    end

    -- In a raid: Free Assign mode allows all Paladins to edit
    if Buffadin.db and Buffadin.db.profile and Buffadin.db.profile.freeAssign then
        return true
    end

    -- In a raid without Free Assign: allow Raid Leader or Raid Assistant
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        return true
    end

    -- Tanks (Main Tank / Off Tank or Tank role) are also permitted to configure assignments
    if UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" then
        return true
    end
    if GetPartyAssignment and GetPartyAssignment("MAINTANK", "player") == true then
        return true
    end

    return false
end

-- =========================================================================
-- Roster Scan & Update
-- =========================================================================
function Buffadin.Roster:Update()
    local oldPaladins = self.paladins
    self.units = {}
    self.paladins = {}
    self.sortedPaladins = {}
    self.totalCount = 0
    self.paladinCount = 0

    for _, cls in ipairs(Buffadin.CLASSES) do
        self.classes[cls.id] = {}
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

    for _, unit in ipairs(unitList) do
        if UnitExists(unit) then
            local name, realm = UnitName(unit)
            if name and name ~= "" then
                local fullName = realm and (realm ~= "") and (name .. "-" .. realm) or name
                local _, classToken, classId = UnitClass(unit)
                local clsConfig = Buffadin.CLASS_BY_TOKEN[classToken]
                local cid = clsConfig and clsConfig.id or 1

                -- Tank detection
                local isTank = false
                if UnitGroupRolesAssigned then
                    isTank = (UnitGroupRolesAssigned(unit) == "TANK")
                end
                if not isTank and GetPartyAssignment then
                    isTank = (GetPartyAssignment("MAINTANK", unit) == true)
                end

                local unitInfo = {
                    unitId = unit,
                    name = name,
                    fullName = fullName,
                    classToken = classToken,
                    classId = cid,
                    isTank = isTank,
                    isDead = UnitIsDeadOrGhost(unit),
                    isOnline = UnitIsConnected(unit),
                    isVisible = UnitIsVisible(unit),
                }

                self.units[unit] = unitInfo
                table.insert(self.classes[cid], unitInfo)
                self.totalCount = self.totalCount + 1

                -- Track Paladins
                if classToken == "PALADIN" then
                    self.paladinCount = self.paladinCount + 1
                    local pallyInfo = {
                        name = fullName,
                        unitId = unit,
                        isPlayer = UnitIsUnit(unit, "player"),
                        isLeader = UnitIsGroupLeader(unit),
                        isAssist = UnitIsGroupAssistant(unit),
                        spells = {},
                    }

                    -- Scan known spells for player Paladin
                    if pallyInfo.isPlayer then
                        pallyInfo.hasKings = Buffadin:IsSpellKnown(20217) or Buffadin:IsSpellKnown(25898)
                        pallyInfo.hasSanctuary = Buffadin:IsSpellKnown(20911) or Buffadin:IsSpellKnown(25899)
                        pallyInfo.hasSalvation = Buffadin:IsSpellKnown(1038) or Buffadin:IsSpellKnown(25895)
                        pallyInfo.hasLight = Buffadin:IsSpellKnown(19977) or Buffadin:IsSpellKnown(25890)
                        pallyInfo.hasMight = Buffadin:IsSpellKnown(19740) or Buffadin:IsSpellKnown(25782)
                        pallyInfo.hasWisdom = Buffadin:IsSpellKnown(19742) or Buffadin:IsSpellKnown(25894)
                    else
                        -- Preserve previously known remote spells if available
                        local prev = oldPaladins[fullName]
                        if prev then
                            pallyInfo.hasKings = prev.hasKings
                            pallyInfo.hasSanctuary = prev.hasSanctuary
                            pallyInfo.hasSalvation = prev.hasSalvation
                            pallyInfo.hasLight = prev.hasLight
                            pallyInfo.hasMight = prev.hasMight
                            pallyInfo.hasWisdom = prev.hasWisdom
                        else
                            pallyInfo.hasKings = true
                            pallyInfo.hasSanctuary = true
                            pallyInfo.hasSalvation = true
                            pallyInfo.hasLight = true
                            pallyInfo.hasMight = true
                            pallyInfo.hasWisdom = true
                        end
                    end

                    self.paladins[fullName] = pallyInfo
                    table.insert(self.sortedPaladins, fullName)
                end

                -- Track pet if enabled
                if Buffadin.db and Buffadin.db.profile and Buffadin.db.profile.showPets then
                    local petUnit = (unit == "player") and "pet" or (unit:gsub("raid", "raidpet"):gsub("party", "partypet"))
                    if UnitExists(petUnit) then
                        local petName = UnitName(petUnit) or "Pet"
                        local petInfo = {
                            unitId = petUnit,
                            name = petName,
                            fullName = petName,
                            classToken = "PET",
                            classId = 10,
                            isTank = false,
                            isDead = UnitIsDeadOrGhost(petUnit),
                            isOnline = true,
                            isVisible = UnitIsVisible(petUnit),
                        }
                        table.insert(self.classes[10], petInfo)
                    end
                end
            end
        end
    end

    -- Sort Paladins: local player first, then alphabetical
    local playerName = UnitName("player")
    table.sort(self.sortedPaladins, function(a, b)
        if a == playerName or a:find("^" .. playerName) then return true end
        if b == playerName or b:find("^" .. playerName) then return false end
        return a < b
    end)

    if Buffadin.OnRosterUpdated then
        Buffadin:OnRosterUpdated()
    end
end
