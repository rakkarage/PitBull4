-- http://luacheck.readthedocs.io/en/stable/warnings.html

std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	".luacheckrc",
	".release",
	"**/Libs",
	"Babelfish.lua",
	"Localization/_export.lua",
}
ignore = {
	"11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
	"11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
	"113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"211", -- Unused local variable
	"211/L", -- Unused local variable "L"
	"211/CL", -- Unused local variable "CL"
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
	"314", -- Value of a field in a table literal is unused
	"42.", -- Shadowing a local variable, an argument, a loop variable.
	"43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
	"542", -- An empty if branch
}
files["Modules/Phase**"].globals = {
	"UnitInPhase", -- classic compat
}
files["Modules/Runes_Classic/*"].globals = {
	"GetRuneType", -- classic compat
}
globals = {
	-- Third-party
	"LibStub",
	"PitBull4",
	"oRA3",

	-- FrameXML
	"BasicMessageDialog",
	"ChatFontNormal",
	"CombatFeedbackText",
	"CooldownFrame_Set",
	"CopyTable",
	"DEFAULT_CHAT_FRAME",
	"GameTooltip",
	"GameTooltip_SetDefaultAnchor",
	"SpellIsSelfBuff",
	"StaticPopup_Show",
	"StaticPopupDialogs",
	"StatusTrackingBarManager",
	"SOUNDKIT",
	"TooltipUtil",
	"UIErrorsFrame",
	"UIParent",
	"tContains",
	"tInvert",
	"ipairs_reverse",

	"Enum",

	-- Classic
	"WOW_PROJECT_ID",
	"WOW_PROJECT_CATACLYSM_CLASSIC",

	-- Functions
	"C_AddOns",
	"C_AzeriteItem",
	"C_CreatureInfo",
	"C_GossipInfo",
	"C_IncomingSummon",
	"C_Item",
	"C_MajorFactions",
	"C_PvP",
	"C_Reputation",
	"C_Spell",
	"C_Timer",
	"C_TooltipInfo",
	"C_UnitAuras",
	"CancelItemTempEnchantment",
	"CancelUnitBuff",
	"CheckInteractDistance",
	"CreateFrame",
	"DestroyTotem",
	"GetBattlefieldStatus",
	"GetCVarBool",
	"GetComboPoints",
	"GetBuildInfo",
	"GetFriendshipReputation",
	"GetInventoryItemLink",
	"GetLocale",
	"GetManagedEnvironment",
	"GetMaxPlayerLevel",
	"GetMouseFocus",
	"GetNumClasses",
	"GetNumGroupMembers",
	"GetPowerRegenForPowerType",
	"GetPVPTimer",
	"GetPartyAssignment",
	"GetPetExperience",
	"GetQuestDifficultyColor",
	"GetRaidRosterInfo",
	"GetRaidTargetIndex",
	"GetReadyCheckStatus",
	"GetRuneCooldown",
	"GetScreenHeight",
	"GetScreenWidth",
	"GetShapeshiftFormID",
	"GetSpecialization",
	"GetTalentInfoBySpecialization",
	"GetThreatStatusColor",
	"GetTime",
	"GetUnitPowerBarInfo",
	"GetWatchedFactionInfo",
	"GetWeaponEnchantInfo",
	"GetXPExhaustion",
	"InCombatLockdown",
	"IsInGroup",
	"IsInRaid",
	"IsPlayerInWorld",
	"IsPlayerSpell",
	"IsPVPTimerRunning",
	"IsResting",
	"IsShiftKeyDown",
	"IsSpellKnown",
	"PartyUtil",
	"PlaySound",
	"PlaySoundFile",
	"RegisterAttributeDriver",
	"RegisterUnitWatch",
	"SecureHandlerExecute",
	"SecureHandlerSetFrameRef",
	"SetPortraitTexture",
	"ShowBossFrameWhenUninteractable",
	"SpellGetVisibilityInfo",
	"UnitAffectingCombat",
	"UnitBattlePetLevel",
	"UnitBattlePetType",
	"UnitCanAttack",
	"UnitCastingInfo",
	"UnitChannelInfo",
	"UnitClass",
	"UnitClassBase",
	"UnitClassification",
	"UnitCreatureFamily",
	"UnitCreatureType",
	"UnitDetailedThreatSituation",
	"UnitExists",
	"UnitFactionGroup",
	"UnitGUID",
	"UnitGetIncomingHeals",
	"UnitGetTotalAbsorbs",
	"UnitGroupRolesAssigned",
	"UnitHasIncomingResurrection",
	"UnitHasVehiclePlayerFrameUI",
	"UnitHasVehicleUI",
	"UnitHealth",
	"UnitHealthMax",
	"UnitHonorLevel",
	"UnitInParty",
	"UnitInRaid",
	"UnitInRange",
	"UnitIsAFK",
	"UnitIsBattlePetCompanion",
	"UnitIsConnected",
	"UnitIsDND",
	"UnitIsDead",
	"UnitIsDeadOrGhost",
	"UnitIsEnemy",
	"UnitIsFeignDeath",
	"UnitIsFriend",
	"UnitIsGhost",
	"UnitIsGroupLeader",
	"UnitIsMercenary",
	"UnitIsOtherPlayersPet",
	"UnitIsPVP",
	"UnitIsPVPFreeForAll",
	"UnitIsPlayer",
	"UnitIsQuestBoss",
	"UnitIsTapDenied",
	"UnitIsUnit",
	"UnitIsVisible",
	"UnitIsWildBattlePet",
	"UnitLevel",
	"UnitName",
	"UnitPartialPower",
	"UnitPlayerControlled",
	"UnitPlayerOrPetInRaid",
	"UnitPower",
	"UnitPowerDisplayMod",
	"UnitPowerMax",
	"UnitPowerType",
	"UnitPhaseReason",
	"UnitRace",
	"UnitReaction",
	"UnitSelectionColor",
	"UnitThreatSituation",
	"UnitXP",
	"UnitXPMax",
	"UnregisterAttributeDriver",
	"UnregisterUnitWatch",
	"abs",
	"bit",
	"ceil",
	"date",
	"debugstack",
	"floor",
	"format",
	"geterrorhandler",
	"hooksecurefunc",
	"math",
	"max",
	"min",
	"string",
	"strjoin",
	"strsplit",
	"strtrim",
	"table",
	"tostringall",
	"wipe",

	-- Strings
	"ALTERNATE_POWER_INDEX",
	"CANCEL",
	"CAT_FORM",
	"CLASS",
	"CLASS_SORT_ORDER",
	"DAMAGER",
	"DAY_ONELETTER_ABBR",
	"DAYS_ABBR",
	"DECIMAL_SEPERATOR",
	"FIRST_NUMBER_CAP_NO_SPACE",
	"FULL_PLAYER_NAME",
	"HEALER",
	"HOUR_ONELETTER_ABBR",
	"HOURS_ABBR",
	"LARGE_NUMBER_SEPERATOR",
	"LOCALIZED_CLASS_NAMES_MALE",
	"MAX_PARTY_MEMBERS",
	"MAX_RAID_MEMBERS",
	"MINUTE_ONELETTER_ABBR",
	"MINUTES_ABBR",
	"NONE",
	"NUM_BAG_SLOTS",
	"PET_TYPE_SUFFIX",
	"RAID_CLASS_COLORS",
	"RAID_TARGET_1",
	"RAID_TARGET_2",
	"RAID_TARGET_3",
	"RAID_TARGET_4",
	"RAID_TARGET_5",
	"RAID_TARGET_6",
	"RAID_TARGET_7",
	"RAID_TARGET_8",
	"RELOADUI",
	"SECOND_NUMBER_CAP_NO_SPACE",
	"SECOND_ONELETTER_ABBR",
	"SECONDS_ABBR",
	"TANK",
	"TOOLTIP_BATTLE_PET",
	"UNKNOWN",
}
