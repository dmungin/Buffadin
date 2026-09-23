local addonName, Buffadin = ...

Buffadin.COMM_PREFIX = "BUFFADIN"
Buffadin.LEGACY_PREFIX = "PLPWR"

-- =========================================================================
-- Classes Configuration
-- =========================================================================
Buffadin.CLASSES = {
    { id = 1,  token = "WARRIOR", name = "Warrior", icon = "Interface\\Icons\\ClassIcon_Warrior" },
    { id = 2,  token = "PALADIN", name = "Paladin", icon = "Interface\\Icons\\ClassIcon_Paladin" },
    { id = 3,  token = "HUNTER",  name = "Hunter",  icon = "Interface\\Icons\\ClassIcon_Hunter" },
    { id = 4,  token = "ROGUE",   name = "Rogue",   icon = "Interface\\Icons\\ClassIcon_Rogue" },
    { id = 5,  token = "PRIEST",  name = "Priest",  icon = "Interface\\Icons\\ClassIcon_Priest" },
    { id = 6,  token = "SHAMAN",  name = "Shaman",  icon = "Interface\\Icons\\ClassIcon_Shaman" },
    { id = 7,  token = "MAGE",    name = "Mage",    icon = "Interface\\Icons\\ClassIcon_Mage" },
    { id = 8,  token = "WARLOCK", name = "Warlock", icon = "Interface\\Icons\\ClassIcon_Warlock" },
    { id = 9,  token = "DRUID",   name = "Druid",   icon = "Interface\\Icons\\ClassIcon_Druid" },
    { id = 10, token = "PET",     name = "Pets",    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat" },
}

Buffadin.CLASS_BY_TOKEN = {}
Buffadin.CLASS_BY_ID = {}
for _, cls in ipairs(Buffadin.CLASSES) do
    Buffadin.CLASS_BY_TOKEN[cls.token] = cls
    Buffadin.CLASS_BY_ID[cls.id] = cls
end

-- =========================================================================
-- Greater Blessings (Group/Raid class buffs)
-- =========================================================================
Buffadin.GREATER_BLESSINGS = {
    [0] = { id = 0, name = "None", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", spellId = 0 },
    [1] = { id = 1, name = "Greater Blessing of Wisdom", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom", spellId = 25894 },
    [2] = { id = 2, name = "Greater Blessing of Might", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", spellId = 25782 },
    [3] = { id = 3, name = "Greater Blessing of Kings", icon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings", spellId = 25898 },
    [4] = { id = 4, name = "Greater Blessing of Salvation", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation", spellId = 25895 },
    [5] = { id = 5, name = "Greater Blessing of Light", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight", spellId = 25890 },
    [6] = { id = 6, name = "Greater Blessing of Sanctuary", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary", spellId = 25899 },
}
Buffadin.MAX_GREATER_BLESSINGS = 6

-- =========================================================================
-- Normal Blessings (Single target buffs / overrides)
-- =========================================================================
Buffadin.NORMAL_BLESSINGS = {
    [0] = { id = 0, name = "None", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", spellId = 0 },
    [1] = { id = 1, name = "Blessing of Wisdom", icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom", spellId = 19742 },
    [2] = { id = 2, name = "Blessing of Might", icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", spellId = 19740 },
    [3] = { id = 3, name = "Blessing of Kings", icon = "Interface\\Icons\\Spell_Magic_MageArmor", spellId = 20217 },
    [4] = { id = 4, name = "Blessing of Salvation", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", spellId = 1038 },
    [5] = { id = 5, name = "Blessing of Light", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", spellId = 19977 },
    [6] = { id = 6, name = "Blessing of Sanctuary", icon = "Interface\\Icons\\Spell_Nature_LightningShield", spellId = 20911 },
    [7] = { id = 7, name = "Blessing of Sacrifice", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", spellId = 6940 },
    [8] = { id = 8, name = "Blessing of Protection", icon = "Interface\\Icons\\Spell_Holy_SealOfProtection", spellId = 1022 },
    [9] = { id = 9, name = "Blessing of Freedom", icon = "Interface\\Icons\\Spell_Holy_SealOfValor", spellId = 1044 },
}
Buffadin.MAX_NORMAL_BLESSINGS = 9

-- Map Greater Blessing Index to Corresponding Normal Blessing Index
Buffadin.GREATER_TO_NORMAL = {
    [0] = 0,
    [1] = 1, -- Wisdom
    [2] = 2, -- Might
    [3] = 3, -- Kings
    [4] = 4, -- Salvation
    [5] = 5, -- Light
    [6] = 6, -- Sanctuary
}

-- =========================================================================
-- Paladin Auras
-- =========================================================================
Buffadin.AURAS = {
    [0] = { id = 0, name = "None", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", spellId = 0 },
    [1] = { id = 1, name = "Devotion Aura", icon = "Interface\\Icons\\Spell_Holy_DevotionAura", spellId = 465 },
    [2] = { id = 2, name = "Retribution Aura", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", spellId = 7294 },
    [3] = { id = 3, name = "Concentration Aura", icon = "Interface\\Icons\\Spell_Holy_MindSooth", spellId = 19746 },
    [4] = { id = 4, name = "Shadow Resistance Aura", icon = "Interface\\Icons\\Spell_Shadow_SealOfKings", spellId = 19876 },
    [5] = { id = 5, name = "Frost Resistance Aura", icon = "Interface\\Icons\\Spell_Frost_WizardMark", spellId = 19888 },
    [6] = { id = 6, name = "Fire Resistance Aura", icon = "Interface\\Icons\\Spell_Fire_SealOfFire", spellId = 19891 },
    [7] = { id = 7, name = "Sanctity Aura", icon = "Interface\\Icons\\Spell_Holy_MindVision", spellId = 20218 },
    [8] = { id = 8, name = "Crusader Aura", icon = "Interface\\Icons\\Spell_Holy_CrusaderAura", spellId = 32223 },
}
Buffadin.MAX_AURAS = 8

-- =========================================================================
-- Seals & Utility Spells
-- =========================================================================
Buffadin.SEALS = {
    [0] = { id = 0, name = "None", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", spellId = 0 },
    [1] = { id = 1, name = "Seal of Righteousness", icon = "Interface\\Icons\\Ability_ThunderBolt", spellId = 21084 },
    [2] = { id = 2, name = "Seal of Command", icon = "Interface\\Icons\\Ability_Warrior_InnerRage", spellId = 20375 },
    [3] = { id = 3, name = "Seal of Justice", icon = "Interface\\Icons\\Spell_Holy_SealOfWrath", spellId = 20164 },
    [4] = { id = 4, name = "Seal of Light", icon = "Interface\\Icons\\Spell_Holy_HealingAura", spellId = 20165 },
    [5] = { id = 5, name = "Seal of Wisdom", icon = "Interface\\Icons\\Spell_Holy_RighteousnessAura", spellId = 20166 },
    [6] = { id = 6, name = "Seal of the Crusader", icon = "Interface\\Icons\\Spell_Holy_HolySmite", spellId = 21082 },
}

Buffadin.RIGHTEOUS_FURY = {
    spellId = 25780,
    name = "Righteous Fury",
    icon = "Interface\\Icons\\Spell_Holy_SealOfFury"
}

-- Buff durations in seconds
Buffadin.DURATION_GREATER = 15 * 60  -- 15 minutes
Buffadin.DURATION_NORMAL  = 5 * 60   -- 5 minutes

-- =========================================================================
-- Default User Configuration
-- =========================================================================
Buffadin.DEFAULT_CONFIG = {
    enabled = true,
    scale = 1.0,
    barScale = 1.0,
    barLocked = false,
    barPoint = "CENTER",
    barX = 0,
    barY = -150,
    showWhenSolo = true,
    showInParty = true,
    showInRaid = true,
    showAuraButton = true,
    showRfButton = true,
    showAutoButton = true,
    showPlayerPopups = true,
    showTimers = true,
    showCounts = true,
    smartBuffs = true,
    freeAssign = false,   -- When false, only Raid Leader/Assist can edit assignments
    reportChannel = "RAID",
    minimap = {
        hide = false,
        angle = 220,
    },
    assignments = {},       -- [pallyName][classId] = greaterBlessingIndex
    normalAssignments = {}, -- [pallyName][classId][unitName] = normalBlessingIndex
    auraAssignments = {},   -- [pallyName] = auraIndex
    presets = {},
}
