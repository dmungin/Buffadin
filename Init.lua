local addonName, Buffadin = ...

Buffadin.EventFrame = CreateFrame("Frame", "BuffadinEventFrame")

-- =========================================================================
-- Slash Commands (Strictly /buffadin only)
-- =========================================================================
SLASH_BUFFADIN1 = "/buffadin"
SLASH_BUFFADIN2 = "/bf"

SlashCmdList["BUFFADIN"] = function(msg)
    msg = msg and string.lower(string.trim(msg)) or ""

    if msg == "" then
        if Buffadin.ManagerFrame:IsShown() then
            Buffadin.ManagerFrame:Hide()
        else
            Buffadin.ManagerFrame:Show()
        end
    elseif msg == "bar" then
        if Buffadin.BlessingsBar:IsShown() then
            Buffadin.BlessingsBar:Hide()
        else
            Buffadin.BlessingsBar:Show()
        end
    elseif msg == "opt" or msg == "config" or msg == "options" then
        if Buffadin.OptionsFrame:IsShown() then
            Buffadin.OptionsFrame:Hide()
        else
            Buffadin.OptionsFrame:Show()
        end
    elseif msg == "reset" then
        Buffadin.db.profile.barPoint = "CENTER"
        Buffadin.db.profile.barX = 0
        Buffadin.db.profile.barY = -150
        Buffadin.BlessingsBar:ClearAllPoints()
        Buffadin.BlessingsBar:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        Buffadin:Print("Buff Bar position reset to center.")
    elseif msg == "report" then
        Buffadin.Assignments:Report()
    elseif msg == "auto" or msg == "assign" then
        Buffadin.Assignments:AutoAssign()
    elseif msg == "clear" then
        Buffadin.Assignments:ClearAll()
    elseif msg == "mock" or msg == "test" or msg:find("^mock ") or msg:find("^test ") then
        if Buffadin.MockHarness then
            local _, arg = strsplit(" ", msg, 2)
            arg = arg and string.lower(string.trim(arg)) or ""
            if arg == "party" or arg == "5" then
                Buffadin.MockHarness:SetPreset("PARTY")
                Buffadin.MockHarness:ShowPanel()
            elseif arg == "raid" or arg == "40" or arg == "raid40" then
                Buffadin.MockHarness:SetPreset("RAID40")
                Buffadin.MockHarness:ShowPanel()
            elseif arg == "raid25" or arg == "25" then
                Buffadin.MockHarness:SetPreset("RAID25")
                Buffadin.MockHarness:ShowPanel()
            elseif arg == "off" or arg == "stop" or arg == "live" then
                Buffadin.MockHarness:Disable()
            else
                if not Buffadin.MockHarness.active then
                    Buffadin.MockHarness:Enable("RAID40")
                    Buffadin.MockHarness:ShowPanel()
                else
                    Buffadin.MockHarness:TogglePanel()
                end
            end
        else
            Buffadin:Print("Mock Test Harness is not loaded in this build.")
        end
    else
        Buffadin:Print("Commands:")
        print("  |cff00ff00/buffadin|r (or |cff00ff00/bf|r) - Toggle Blessing Manager window")
        print("  |cff00ff00/buffadin bar|r - Toggle Floating Buff Bar")
        print("  |cff00ff00/buffadin opt|r - Open Settings")
        print("  |cff00ff00/buffadin auto|r - Auto-assign blessings")
        print("  |cff00ff00/buffadin clear|r - Clear all assignments")
        print("  |cff00ff00/buffadin report|r - Broadcast blessings to chat")
        print("  |cff00ff00/buffadin reset|r - Reset bar position to center")
        print("  |cff00ff00/buffadin mock|r - Open In-Game Mock Test Harness")
    end
end

-- =========================================================================
-- Event Handling
-- =========================================================================
Buffadin.EventFrame:RegisterEvent("ADDON_LOADED")
Buffadin.EventFrame:RegisterEvent("PLAYER_LOGIN")
Buffadin.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
Buffadin.EventFrame:RegisterEvent("UNIT_AURA")
Buffadin.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
Buffadin.EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
Buffadin.EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Buffadin.EventFrame:RegisterEvent("SPELLS_CHANGED")

Buffadin.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
                if loadedAddon == addonName or loadedAddon == "Buffadin" or loadedAddon == "buffadin" then
            -- Migrate legacy PallyPowerForeverDB if present
            if PallyPowerForeverDB and not BuffadinDB then
                BuffadinDB = CopyTable(PallyPowerForeverDB)
            end
            -- Initialize SavedVariables
            if not BuffadinDB then
                BuffadinDB = {}
            end
            if not BuffadinDB.profile then
                BuffadinDB.profile = {}
            end

            -- Apply defaults for any missing keys
            for k, v in pairs(Buffadin.DEFAULT_CONFIG) do
                if BuffadinDB.profile[k] == nil then
                    if type(v) == "table" then
                        BuffadinDB.profile[k] = CopyTable(v)
                    else
                        BuffadinDB.profile[k] = v
                    end
                end
            end

            Buffadin.db = BuffadinDB

            -- Restore saved assignments
            if Buffadin.db.profile.assignments then
                Buffadin.Assignments.data = Buffadin.db.profile.assignments
            end
            if Buffadin.db.profile.normalAssignments then
                Buffadin.Assignments.normalData = Buffadin.db.profile.normalAssignments
            end
            if Buffadin.db.profile.auraAssignments then
                Buffadin.Assignments.auraData = Buffadin.db.profile.auraAssignments
            end

            -- Register comm prefixes
            Buffadin:RegisterComm(Buffadin.COMM_PREFIX)
            Buffadin:RegisterComm(Buffadin.LEGACY_PREFIX)
        end

    elseif event == "PLAYER_LOGIN" then
        -- Initialize UI elements
        Buffadin.PlayerPopups:Initialize()
        Buffadin.BlessingsBar:Initialize()
        Buffadin.ManagerFrame:Initialize()
        Buffadin.OptionsFrame:Initialize()
        Buffadin.MinimapButton:Initialize()

        -- Initial scans
        Buffadin.Roster:Update()
        Buffadin.BuffScanner:Scan()
        Buffadin.BlessingsBar:UpdateLayout()

        -- Request sync if in group
        if IsInGroup() or IsInRaid() then
            Buffadin.Assignments:RequestSync()
        end

        -- Periodic refresh timer for timers and missing buffs (every 1s)
        C_Timer.NewTicker(1.0, function()
            Buffadin.BuffScanner:Scan()
            Buffadin.BlessingsBar:RefreshDisplay()
        end)

        Buffadin:Print("v" .. Buffadin.version .. " loaded. Type |cff00ff00/buffadin|r or |cff00ff00/bf|r for manager.")

    elseif event == "GROUP_ROSTER_UPDATE" then
        Buffadin.Roster:Update()
        Buffadin.BuffScanner:Scan()
        Buffadin:RunOutOfCombat(function()
            Buffadin.BlessingsBar:UpdateLayout()
            Buffadin.ManagerFrame:UpdateGrid()
        end)

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit and (unit == "player" or unit:find("party") or unit:find("raid")) then
            Buffadin.BuffScanner:Scan()
            Buffadin.BlessingsBar:RefreshDisplay()
        end

    elseif event == "SPELLS_CHANGED" then
        Buffadin.Roster:Update()
        Buffadin.BuffScanner:Scan()
        Buffadin:RunOutOfCombat(function()
            Buffadin.BlessingsBar:RefreshDisplay()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Exited combat: process deferred secure operations
        Buffadin:ProcessCombatQueue()
        Buffadin.BlessingsBar:UpdateLayout()

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat: ensure popups are closed
        if Buffadin.PlayerPopups then
            Buffadin.PlayerPopups:Hide()
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        Buffadin.Assignments:OnMessageReceived(prefix, message, channel, sender)
    end
end)

-- Callback connectors
function Buffadin:OnRosterUpdated()
    self.BuffScanner:Scan()
    if self.BlessingsBar:IsShown() then
        self.BlessingsBar:UpdateLayout()
    end
    if self.ManagerFrame:IsShown() then
        self.ManagerFrame:UpdateGrid()
    end
end

function Buffadin:OnAssignmentsChanged()
    self.BuffScanner:Scan()
    self.BlessingsBar:RefreshDisplay()
    if self.ManagerFrame:IsShown() then
        self.ManagerFrame:UpdateGrid()
    end
end
