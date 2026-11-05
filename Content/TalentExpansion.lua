local _, W = ...
local L = W.L
local C = W.Content

-- Additional rows use explicit position IDs, leaving all original nodes untouched.
-- Shared foundations are intentional; situational talents supply specialization choices.
C.talentEffects.burningWounds = {
    value = true,
    text = L.OFFENSIVE_ABILITIES_APPLY_MAGICAL_DAMAGE_EQUAL_TO_12_WEAPON,
}

local variedEffects = {
    attackSpeed = { 0.15, L.TALENT_ATTACK_SPEED, L.TALENT_RANK_ATTACK_SPEED },
    cooldownRate = { 0.15, L.TALENT_COOLDOWN_RECOVERY, L.TALENT_RANK_COOLDOWN_RECOVERY },
    criticalChance = { 0.12, L.TALENT_CRITICAL_CHANCE, L.TALENT_RANK_CRITICAL_CHANCE },
    criticalDamage = { 0.5, L.TALENT_CRITICAL_DAMAGE, L.TALENT_RANK_CRITICAL_DAMAGE },
    criticalHealing = { 0.5, L.TALENT_CRITICAL_HEALING, L.TALENT_RANK_CRITICAL_HEALING },
    superCriticalChance = { 0.04, L.TALENT_SUPER_CRITICAL_CHANCE, L.TALENT_RANK_SUPER_CRITICAL_CHANCE },
    superCriticalDamage = { 0.75, L.TALENT_SUPER_CRITICAL_DAMAGE, L.TALENT_RANK_SUPER_CRITICAL_DAMAGE },
    superCriticalHealing = { 0.75, L.TALENT_SUPER_CRITICAL_HEALING, L.TALENT_RANK_SUPER_CRITICAL_HEALING },
    resourceGain = { 0.25, L.TALENT_RESOURCE_GAIN, L.TALENT_RANK_RESOURCE_GAIN },
    abilityEfficiency = { 0.15, L.TALENT_ABILITY_EFFICIENCY, L.TALENT_RANK_ABILITY_EFFICIENCY },
    dotDamage = { 0.25, L.TALENT_DOT_DAMAGE, L.TALENT_RANK_DOT_DAMAGE },
    overhealShield = { 0.2, L.TALENT_OVERHEAL_SHIELD, L.TALENT_RANK_OVERHEAL_SHIELD },
}
for effect, definition in pairs(variedEffects) do
    C.talentEffects[effect] = { value = definition[1], text = definition[2], rankText = definition[3] }
end

local additions = {
    WARRIOR = {
        {
            { L.ARMS_TRAINING, "damage", "ability_warrior_rallyingcry" },
            { L.VETERAN_S_ENDURANCE, "health", "ability_warrior_intervene" },
            { L.TRAUMA, "damage", "ability_warrior_trauma", "strike", "bleed", 16 },
            { L.TACTICAL_ADVANCE, "speed", "ability_warrior_vigilance", "basic", "quick", 14 },
            { L.WARBREAKER, "damage", "ability_warrior_warcry", "strike", "group", 18 },
            {
                L.DUELIST_S_EDGE,
                "mitigation",
                "ability_warrior_focusedrage",
                "defense",
                "solo",
                10,
            },
            {
                L.RELENTLESS_ASSAULT,
                "speed",
                "ability_warrior_unrelentingassault",
                "strike",
                "patient",
                20,
            },
            {
                L.EXECUTIONER_S_PRECISION,
                "damage",
                "ability_warrior_furiousresolve",
                "strike",
                "execute",
                22,
            },
        },
        {
            { L.FURY_TRAINING, "speed", "ability_warrior_intensifyrage" },
            { L.RAGING_VITALITY, "health", "ability_warrior_dragonroar" },
            { L.FRESH_MEAT, "regen", "ability_warrior_bloodbath", "basic", "opening", 18 },
            {
                L.FROTHING_BERSERKER,
                "damage",
                "ability_warrior_innerrage",
                "basic",
                "quick",
                20,
            },
            {
                L.BATTLE_TRANCE,
                "regen",
                "ability_warrior_shatteringthrow",
                "healing",
                "late",
                18,
            },
            { L.MEAT_GRINDER, "damage", "ability_warrior_sunder", "strike", "group", 16 },
            {
                L.DEFIANT_RAGE,
                "mitigation",
                "ability_warrior_defensivestance",
                "defense",
                "outnumbered",
                12,
            },
            { L.RAMPAGE, "damage", "ability_warrior_rampage", "strike", "patient", 24 },
        },
        {
            { L.BULWARK_TRAINING, "mitigation", "ability_warrior_stalwartprotector" },
            { L.STALWART_CONSTITUTION, "health", "ability_warrior_shieldreflection" },
            { L.SHIELD_SLAM, "damage", "ability_warrior_shieldbash", "strike", "healthy", 18 },
            { L.INTO_THE_FRAY, "speed", "ability_warrior_incite", "basic", "outnumbered", 18 },
            { L.INDOMITABLE, "health", "ability_warrior_riposte", "defense", "patient", 12 },
            { L.SAFEGUARD, "healing", "ability_warrior_safeguard", "healing", "protect", 24 },
            {
                L.BASTION_OF_STEEL,
                "mitigation",
                "ability_warrior_shieldguard",
                "defense",
                "quick",
                12,
            },
            {
                L.DEMORALIZING_PRESENCE,
                "regen",
                "ability_warrior_commandingshout",
                "defense",
                "group",
                10,
            },
        },
    },
    PALADIN = {
        {
            { L.LIGHT_S_WISDOM, "healing", "spell_holy_sealofwisdom" },
            { L.DEVOUT_STAMINA, "health", "spell_holy_devotion" },
            {
                L.INFUSION_OF_LIGHT,
                "speed",
                "ability_paladin_infusionoflight",
                "healing",
                "patient",
                20,
            },
            { L.HOLY_PRISM, "damage", "spell_holy_holysmite", "strike", "protect", 18 },
            {
                L.TOWER_OF_RADIANCE,
                "healing",
                "ability_paladin_toweroflight",
                "healing",
                "ally",
                20,
            },
            { L.MERCIFUL_HANDS, "regen", "spell_holy_layonhands", "healing", "rescue", 30 },
            {
                L.SHINING_PROTECTOR,
                "mitigation",
                "ability_paladin_lightoftheprotector",
                "defense",
                "protect",
                12,
            },
            { L.LIGHTBRINGER, "healing", "ability_paladin_lawbringer", "healing", "boss", 22 },
        },
        {
            { L.AEGIS_TRAINING, "mitigation", "spell_holy_devineaegis" },
            { L.TEMPERED_SPIRIT, "health", "spell_holy_prayerofspirit" },
            { L.BLESSED_HAMMER, "damage", "ability_paladin_blessedhands", "basic", "group", 18 },
            { L.GRAND_CRUSADER, "speed", "spell_holy_crusaderaura", "strike", "quick", 20 },
            {
                L.HAND_OF_THE_PROTECTOR,
                "healing",
                "ability_paladin_protectoroftheinnocent",
                "healing",
                "rescue",
                26,
            },
            {
                L.FAITHFUL_DEFENDER,
                "health",
                "spell_holy_lastingdefense",
                "defense",
                "protect",
                14,
            },
            {
                L.INNER_LIGHT,
                "regen",
                "ability_paladin_blindinglight2",
                "defense",
                "unhurt",
                16,
            },
            {
                L.RIGHTEOUS_BULWARK,
                "mitigation",
                "spell_holy_righteousfury",
                "defense",
                "patient",
                14,
            },
        },
        {
            { L.TEMPLAR_TRAINING, "damage", "ability_paladin_shieldofthetemplar" },
            { L.CRUSADER_S_RESOLVE, "health", "spell_holy_crusaderstrike" },
            { L.DIVINE_STORM, "damage", "ability_paladin_divinestorm", "strike", "group", 24 },
            {
                L.BLADE_OF_JUSTICE,
                "speed",
                "ability_paladin_bladeofjustice",
                "basic",
                "quick",
                18,
            },
            {
                L.FIRES_OF_JUSTICE,
                "damage",
                "spell_holy_fistofjustice",
                "strike",
                "burning",
                20,
            },
            { L.HEALING_HANDS, "healing", "spell_holy_healingfocus", "healing", "rescue", 28 },
            {
                L.RETRIBUTION_AURA,
                "mitigation",
                "spell_holy_retributionaura",
                "defense",
                "protect",
                10,
            },
            {
                L.FINAL_RECKONING,
                "damage",
                "ability_paladin_hammer_of_reckoning",
                "strike",
                "patient",
                26,
            },
        },
    },
    HUNTER = {
        {
            { L.PRIMAL_TRAINING, "damage", "ability_hunter_beastmastery" },
            { L.COMPANION_S_FORTITUDE, "health", "ability_hunter_mongoosebite" },
            {
                L.PACK_TACTICS,
                "speed",
                "inv_ability_packleaderhunter_vicioushunt",
                "basic",
                "quick",
                22,
            },
            { L.BARBED_SHOT, "wounds", "ability_hunter_barbedshot", "strike", "bleed", 18 },
            {
                L.KINDRED_MENDING,
                "healing",
                "ability_hunter_rapidregeneration",
                "healing",
                "wounded",
                20,
            },
            {
                L.CALL_OF_THE_PACK,
                "damage",
                "ability_hunter_callofthewild",
                "strike",
                "group",
                20,
            },
            { L.WILD_ENDURANCE, "regen", "ability_hunter_wildquiver", "defense", "late", 12 },
            { L.BLOODSHED, "damage", "ability_hunter_goforthethroat", "basic", "bleed", 24 },
        },
        {
            { L.RANGED_TRAINING, "damage", "ability_hunter_aimedshot" },
            { L.MARKSMAN_S_COMPOSURE, "speed", "ability_hunter_markedshot" },
            {
                L.SNIPER_S_PATIENCE,
                "damage",
                "ability_hunter_snipershot",
                "strike",
                "patient",
                24,
            },
            { L.DOUBLE_TAP, "speed", "ability_marksmanship", "basic", "quick", 24 },
            { L.BULLSEYE, "damage", "ability_hunter_eagleeye", "basic", "execute", 20 },
            { L.LONE_WATCH, "mitigation", "ability_hunter_longevity", "defense", "solo", 12 },
            { L.READINESS, "regen", "ability_hunter_readiness", "healing", "healthy", 18 },
            { L.VOLLEY, "damage", "ability_upgrademoonglaive", "strike", "group", 26 },
        },
        {
            { L.TRACKER_S_TRAINING, "health", "ability_hunter_beasttaming" },
            { L.SURVIVAL_KIT, "regen", "inv_misc_bag_07" },
            {
                L.GUERRILLA_TACTICS,
                "damage",
                "ability_hunter_explosiveshot",
                "strike",
                "burning",
                24,
            },
            { L.VIPER_S_VENOM, "damage", "ability_hunter_potentvenom", "basic", "bleed", 20 },
            { L.STEEL_TRAP, "mitigation", "ability_hunter_steeltrap", "defense", "bleed", 12 },
            {
                L.COORDINATED_PURSUIT,
                "speed",
                "ability_hunter_combatexperience",
                "basic",
                "quick",
                20,
            },
            { L.EMERGENCY_DRESSING, "healing", "inv_misc_bandage_11", "healing", "rescue", 28 },
            { L.SPEARHEAD, "damage", "ability_hunter_spearhead", "strike", "patient", 22 },
        },
    },
    ROGUE = {
        {
            { L.POISONCRAFT, "damage", "ability_rogue_poisonedknife" },
            { L.ASSASSIN_S_VIGOR, "speed", "ability_rogue_vigor" },
            { L.ENVENOM, "damage", "ability_rogue_creepingvenom", "strike", "bleed", 24 },
            { L.POISONED_EDGES, "damage", "ability_rogue_deviouspoisons", "basic", "bleed", 22 },
            { L.VENOM_RUSH, "speed", "ability_creature_poison_04", "basic", "quick", 22 },
            { L.CRIMSON_RECOVERY, "regen", "ability_rogue_crimsonvial", "healing", "bleed", 22 },
            { L.DEATHMARK, "damage", "ability_rogue_deathmark", "strike", "boss", 26 },
            { L.SERRATED_FINISH, "damage", "ability_rogue_eviscerate", "strike", "execute", 28 },
        },
        {
            { L.WEAPON_DRILLS, "damage", "ability_rogue_deadenednerves" },
            { L.BRAWLER_S_STAMINA, "health", "ability_rogue_bladetwisting" },
            { L.OPPORTUNITY, "damage", "ability_rogue_versatility", "strike", "quick", 20 },
            {
                L.RESTLESS_BLADES,
                "speed",
                "ability_rogue_restlessblades",
                "strike",
                "patient",
                22,
            },
            { L.BROADSIDE, "damage", "ability_rogue_pistolshot", "basic", "group", 24 },
            {
                L.DIRTY_TRICKS,
                "mitigation",
                "ability_rogue_tricksofthetrade",
                "defense",
                "outnumbered",
                14,
            },
            {
                L.RUTHLESS_PRECISION,
                "damage",
                "ability_rogue_ruthlessness",
                "strike",
                "healthy",
                20,
            },
            { L.LOADED_DICE, "speed", "ability_rogue_slicedice", "basic", "late", 24 },
        },
        {
            { L.SHADOW_TRAINING, "damage", "ability_rogue_shadowstrikes" },
            { L.SHADOW_FORTITUDE, "health", "ability_rogue_shadowyduel" },
            { L.FIRST_DANCE, "speed", "ability_stealth", "basic", "opening", 30 },
            { L.FIND_WEAKNESS, "damage", "ability_rogue_findweakness", "strike", "armored", 24 },
            {
                L.SHADOW_FOCUS,
                "speed",
                "ability_rogue_slaughterfromtheshadows",
                "strike",
                "patient",
                20,
            },
            { L.DARK_REPRIEVE, "regen", "ability_rogue_preparation", "healing", "solo", 22 },
            {
                L.VEILED_RESILIENCE,
                "mitigation",
                "ability_rogue_imrovedrecuperate",
                "defense",
                "unhurt",
                20,
            },
            {
                L.FINAL_CURTAIN,
                "damage",
                "ability_rogue_thiefsbargain",
                "strike",
                "execute",
                30,
            },
        },
    },
    PRIEST = {
        {
            { L.DISCIPLINED_MIND, "healing", "spell_holy_mindsooth" },
            { L.MENTAL_FORTITUDE, "health", "spell_holy_wordfortitude" },
            { L.CONTRITION, "healing", "spell_holy_penance", "healing", "ally", 18 },
            { L.CASTIGATION, "damage", "spell_holy_aspiration", "basic", "quick", 18 },
            {
                L.SHIELDED_FAITH,
                "mitigation",
                "spell_holy_unyieldingfaith",
                "defense",
                "shielded",
                14,
            },
            { L.SCHISM, "damage", "spell_holy_searinglightpriest", "strike", "patient", 20 },
            {
                L.PROTECTOR_S_PRAYER,
                "healing",
                "spell_holy_prayerofshadowprotection",
                "healing",
                "protect",
                26,
            },
            { L.LENIENCE, "regen", "spell_holy_silence", "defense", "protect", 14 },
        },
        {
            { L.HOLY_STUDIES, "healing", "ability_priest_holywordlife" },
            { L.STEADFAST_FAITH, "health", "spell_holy_testoffaith" },
            { L.TRAIL_OF_LIGHT, "healing", "spell_holy_auraoflight", "healing", "patient", 22 },
            {
                L.BINDING_PRAYER,
                "healing",
                "ability_priest_bindingprayers",
                "healing",
                "ally",
                22,
            },
            {
                L.DESPERATE_PRAYER,
                "regen",
                "spell_holy_prayerofhealing02",
                "healing",
                "rescue",
                34,
            },
            { L.APOTHEOSIS, "speed", "ability_priest_archangel", "healing", "late", 24 },
            {
                L.ANGELIC_BULWARK,
                "mitigation",
                "ability_priest_angelicbulwark",
                "defense",
                "protect",
                16,
            },
            { L.SALVATION, "healing", "spell_holy_sealofsalvation", "healing", "group", 30 },
        },
        {
            { L.SHADOW_STUDIES, "damage", "ability_priest_darkarchangel" },
            { L.UNWAVERING_WILL, "speed", "spell_priest_burningwill" },
            { L.MISERY, "burningWounds", "spell_shadow_misery", "strike", "burning", 22 },
            { L.MINDBENDER, "damage", "spell_shadow_shadowfiend", "basic", "quick", 20 },
            { L.SAN_LAYN, "healing", "spell_shadow_mindflay", "healing", "execute", 28 },
            { L.MENTAL_DECAY, "damage", "spell_shadow_deathanddecay", "strike", "patient", 26 },
            {
                L.INSIDIOUS_PROTECTION,
                "mitigation",
                "spell_shadow_netherprotection",
                "defense",
                "burning",
                14,
            },
            {
                L.HUNGERING_VOID,
                "damage",
                "spell_shadow_summonvoidwalker",
                "strike",
                "execute",
                32,
            },
        },
    },
    SHAMAN = {
        {
            { L.ELEMENTAL_STUDIES, "damage", "spell_nature_elementalshields" },
            { L.ELEMENTAL_SHELTER, "mitigation", "spell_shaman_elementaloath" },
            { L.FLAME_SHOCK, "burningWounds", "spell_fire_flameshock", "strike", "burning", 18 },
            {
                L.MASTER_OF_THE_ELEMENTS,
                "damage",
                "ability_shaman_echooftheelements",
                "strike",
                "patient",
                24,
            },
            { L.ECHOING_THUNDER, "speed", "spell_nature_thunderclap", "basic", "quick", 22 },
            {
                L.EYE_OF_THE_STORM,
                "health",
                "spell_nature_eyeofthestorm",
                "defense",
                "outnumbered",
                16,
            },
            { L.PRIMAL_SURGE, "healing", "spell_shaman_primalstrike", "healing", "protect", 20 },
            { L.LIQUID_MAGMA, "damage", "spell_fire_searingtotem", "strike", "group", 28 },
        },
        {
            { L.WEAPON_IMBUEMENT, "damage", "spell_shaman_unleashweapon_wind" },
            { L.SPIRITUAL_RESILIENCE, "health", "spell_shaman_spiritwalkersgrace" },
            { L.HAILSTORM, "damage", "spell_nature_callstorm", "basic", "group", 22 },
            {
                L.GATHERING_STORMS,
                "speed",
                "spell_shaman_improvedstormstrike",
                "strike",
                "patient",
                22,
            },
            {
                L.HOT_HAND,
                "burningWounds",
                "spell_shaman_unleashweapon_flame",
                "basic",
                "burning",
                24,
            },
            { L.STORMFLURRY, "damage", "spell_shaman_stormearthfire", "basic", "quick", 26 },
            {
                L.ANCESTRAL_GUIDANCE,
                "healing",
                "ability_shaman_ancestralguidance",
                "healing",
                "protect",
                24,
            },
            { L.EARTHGUARD, "mitigation", "spell_shaman_earthquake", "defense", "quick", 14 },
        },
        {
            { L.RESTORATIVE_WATERS, "healing", "ability_shaman_fortifyingwaters" },
            { L.TIDAL_ENDURANCE, "health", "ability_shaman_ascendance" },
            {
                L.CLOUDBURST,
                "healing",
                "ability_shaman_condensationtotem",
                "healing",
                "patient",
                26,
            },
            { L.UNDULATION, "speed", "spell_nature_regeneration_02", "healing", "quick", 20 },
            {
                L.EARTH_SHIELD,
                "mitigation",
                "spell_nature_skinofearth",
                "defense",
                "shielded",
                16,
            },
            { L.WELLSPRING, "healing", "spell_nature_natureblessing", "healing", "group", 26 },
            {
                L.ANCESTRAL_PROTECTION,
                "regen",
                "spell_nature_reincarnation",
                "healing",
                "rescue",
                32,
            },
            { L.HIGH_TIDE, "healing", "spell_shaman_hightide", "healing", "protect", 28 },
        },
    },
    MAGE = {
        {
            { L.ARCANE_STUDIES, "damage", "ability_mage_arcanesurge" },
            { L.ARCANE_FORTITUDE, "health", "spell_mage_arcaneorb" },
            {
                L.RULE_OF_THREES,
                "speed",
                "ability_mage_tormentoftheweak",
                "strike",
                "patient",
                26,
            },
            { L.RESONANCE, "damage", "spell_arcane_arcane04", "strike", "group", 22 },
            {
                L.TOUCH_OF_THE_MAGI,
                "damage",
                "spell_arcane_studentofmagic",
                "strike",
                "boss",
                24,
            },
            { L.CLEARCASTING, "speed", "spell_arcane_arcane03", "basic", "quick", 20 },
            { L.CHRONO_SHIFT, "mitigation", "spell_nature_timestop", "defense", "late", 14 },
            { L.ARCANE_HARMONY, "damage", "spell_arcane_arcanepotency", "strike", "unhurt", 24 },
        },
        {
            { L.FIRE_STUDIES, "damage", "ability_mage_firestarter" },
            { L.FLAME_WARD, "mitigation", "spell_mage_flameorb" },
            { L.PYROCLASM, "damage", "ability_mage_greaterpyroblast", "strike", "burning", 26 },
            { L.KINDLING, "speed", "spell_mage_kindling", "basic", "burning", 22 },
            { L.FIRESTARTER, "damage", "spell_fire_firearmor", "strike", "unhurt", 22 },
            {
                L.BLAZING_RECOVERY,
                "healing",
                "spell_fire_masterofelements",
                "healing",
                "rescue",
                26,
            },
            { L.FLAME_PATCH, "damage", "ability_mage_flamecannon", "basic", "group", 20 },
            {
                L.SUN_KING_S_BLESSING,
                "damage",
                "spell_fire_burningspeed",
                "strike",
                "patient",
                28,
            },
        },
        {
            { L.FROST_STUDIES, "damage", "spell_frost_frostblast" },
            { L.FROZEN_HEART, "health", "spell_frost_frozenorb" },
            { L.WINTER_S_CHILL, "damage", "ability_mage_wintersgrasp", "basic", "quick", 18 },
            { L.SPLITTING_ICE, "damage", "spell_frost_piercing chill", "strike", "group", 24 },
            { L.FROZEN_TOUCH, "speed", "spell_frost_frozencore", "strike", "patient", 22 },
            {
                L.FRIGID_SHELTER,
                "mitigation",
                "spell_frost_chillingarmor",
                "defense",
                "unhurt",
                18,
            },
            { L.ICE_WARD, "regen", "spell_frost_frostward", "defense", "outnumbered", 14 },
            { L.RAY_OF_FROST, "damage", "ability_mage_rayoffrost", "strike", "solo", 28 },
        },
    },
    WARLOCK = {
        {
            { L.AFFLICTION_STUDIES, "damage", "spell_shadow_painfulafflictions" },
            { L.SOUL_RESERVOIR, "health", "spell_shadow_soulleech_2" },
            { L.AGONY, "burningWounds", "spell_shadow_contagion", "strike", "burning", 24 },
            {
                L.CREEPING_CORRUPTION,
                "damage",
                "spell_shadow_creepingplague",
                "basic",
                "burning",
                20,
            },
            { L.INEVITABLE_DEMISE, "healing", "spell_shadow_evileye", "healing", "patient", 28 },
            {
                L.PHANTOM_SINGULARITY,
                "damage",
                "spell_shadow_seedofdestruction",
                "strike",
                "group",
                24,
            },
            { L.MALEFIC_GRASP, "speed", "ability_warlock_soulsiphon", "basic", "quick", 18 },
            {
                L.DEATH_S_EMBRACE,
                "regen",
                "spell_shadow_deathsembrace",
                "healing",
                "rescue",
                30,
            },
        },
        {
            { L.DEMONIC_STUDIES, "damage", "spell_warlock_demonicservitude" },
            { L.DEMONIC_ENDURANCE, "health", "ability_warlock_demonicpower" },
            {
                L.DREAD_CALLING,
                "damage",
                "spell_warlock_calldreadstalkers",
                "strike",
                "patient",
                24,
            },
            {
                L.DEMONIC_MOMENTUM,
                "speed",
                "spell_warlock_demonicempowerment",
                "basic",
                "quick",
                28,
            },
            {
                L.FROM_THE_SHADOWS,
                "burningWounds",
                "spell_warlock_focusshadow",
                "strike",
                "burning",
                20,
            },
            {
                L.SACRIFICIAL_GUARD,
                "mitigation",
                "spell_shadow_sacrificialshield",
                "defense",
                "protect",
                18,
            },
            { L.FEL_COMMUNION, "healing", "spell_shadow_seduction", "healing", "ally", 24 },
            {
                L.DEMONIC_TYRANT,
                "damage",
                "spell_warlock_demonicportal_green",
                "strike",
                "boss",
                28,
            },
        },
        {
            { L.DESTRUCTIVE_STUDIES, "damage", "spell_shadow_destructivesoul" },
            { L.INFERNAL_ENDURANCE, "health", "ability_warlock_infernogreen" },
            { L.ROARING_BLAZE, "damage", "spell_fire_felflamebolt", "strike", "burning", 28 },
            { L.FLASHOVER, "speed", "spell_fire_fire", "basic", "quick", 24 },
            { L.ERADICATION, "damage", "ability_warlock_eradication", "strike", "patient", 30 },
            { L.CATACLYSM, "damage", "ability_deathwing_cataclysm", "strike", "group", 30 },
            {
                L.BURNING_RESOLVE,
                "mitigation",
                "ability_warlock_burningembers",
                "defense",
                "burning",
                18,
            },
            { L.RAIN_OF_CHAOS, "damage", "spell_fire_felrainoffire", "basic", "group", 28 },
        },
    },
    DRUID = {
        {
            { L.ASTRAL_STUDIES, "damage", "spell_druid_astralstorm" },
            { L.ASTRAL_WARDING, "mitigation", "ability_druid_astralstorm" },
            { L.TWIN_MOONS, "damage", "spell_nature_moonglow", "strike", "group", 28 },
            { L.STARLORD, "speed", "ability_druid_improvedmoonkinform", "basic", "quick", 26 },
            { L.SOLSTICE, "damage", "spell_nature_starfall", "strike", "opening", 26 },
            { L.STELLAR_DRIFT, "damage", "ability_druid_stellarflare", "strike", "patient", 28 },
            {
                L.DREAMER_S_SHELTER,
                "regen",
                "ability_druid_dreamstate",
                "defense",
                "unhurt",
                14,
            },
            {
                L.FURY_OF_ELUNE,
                "damage",
                "inv_ability_eluneschosendruid_boundlessmoonlight",
                "strike",
                "boss",
                32,
            },
        },
        {
            { L.PRIMAL_INSTINCTS, "damage", "ability_druid_predatoryinstincts" },
            { L.URSINE_ENDURANCE, "health", "ability_racial_bearform" },
            { L.REND_AND_TEAR, "wounds", "ability_druid_ripandtear", "strike", "bleed", 28 },
            { L.SCENT_OF_BLOOD, "speed", "spell_druid_bloodythrash", "basic", "bleed", 24 },
            { L.PRIMAL_WRATH, "damage", "spell_druid_primaltenacity", "basic", "group", 26 },
            {
                L.GUARDIAN_S_TENACITY,
                "mitigation",
                "spell_druid_malfurionstenacity",
                "defense",
                "outnumbered",
                18,
            },
            {
                L.NURTURING_INSTINCT,
                "healing",
                "ability_druid_healinginstincts",
                "healing",
                "rescue",
                24,
            },
            { L.BERSERK_RESOLVE, "regen", "ability_druid_markofursol", "defense", "quick", 16 },
        },
        {
            { L.RESTORATION_STUDIES, "healing", "spell_nature_preservation" },
            { L.VERDANT_ENDURANCE, "health", "ability_druid_primaltenacity" },
            { L.CULTIVATION, "healing", "spell_nature_healingtouch", "healing", "wounded", 24 },
            { L.OVERGROWTH, "healing", "ability_druid_overgrowth", "healing", "patient", 28 },
            { L.FLOURISH, "speed", "ability_druid_flourish", "healing", "late", 28 },
            {
                L.CENARION_WARD,
                "mitigation",
                "spell_nature_guardianward",
                "defense",
                "protect",
                20,
            },
            { L.TRANQUIL_GROVE, "regen", "spell_nature_tranquility", "healing", "group", 28 },
            { L.GERMINATION, "healing", "spell_druid_germination", "healing", "ally", 26 },
        },
    },
}

-- Final choices reinforce each specialization without changing saved node IDs.
local finalChoices = {
    WARRIOR = {
        {
            { L.BLOODLETTING, "damage", "ability_skeer_bloodletting", "strike", "bleed", 24 },
            { L.JUGGERNAUT, "health", "ability_warrior_bullrush", "defense", "boss", 12 },
        },
        {
            { L.SLAUGHTERHOUSE, "speed", "ability_warrior_bladestorm", "basic", "execute", 24 },
            {
                L.UNQUENCHABLE_THIRST,
                "regen",
                "spell_nzinsanity_bloodthirst",
                "healing",
                "wounded",
                28,
            },
        },
        {
            {
                L.SHIELD_FORTRESS,
                "mitigation",
                "ability_warrior_shieldbreak",
                "defense",
                "group",
                12,
            },
            { L.VENGEFUL_BULWARK, "damage", "inv_shield_32", "strike", "wounded", 26 },
        },
    },
    PALADIN = {
        {
            { L.VENERATION, "damage", "ability_paladin_veneration", "strike", "protect", 24 },
            { L.OVERFLOWING_LIGHT, "healing", "spell_holy_holybolt", "healing", "rescue", 32 },
        },
        {
            {
                L.SANCTIFIED_GROUND,
                "mitigation",
                "ability_paladin_sanctifiedwrath",
                "defense",
                "group",
                12,
            },
            {
                L.BULWARK_OF_FAITH,
                "health",
                "ability_paladin_barrieroffaith",
                "healing",
                "shielded",
                26,
            },
        },
        {
            {
                L.EXECUTION_SENTENCE,
                "damage",
                "spell_paladin_executionsentence",
                "strike",
                "execute",
                30,
            },
            { L.CRUSADING_STRIKES, "speed", "spell_holy_sealofvengeance", "basic", "boss", 24 },
        },
    },
    HUNTER = {
        {
            { L.DIRE_FRENZY, "speed", "ability_hunter_beastwithin", "basic", "quick", 24 },
            {
                L.PREDATOR_S_INSTINCT,
                "damage",
                "ability_hunter_ferociousinspiration",
                "strike",
                "bleed",
                26,
            },
        },
        {
            {
                L.PATIENT_MARKSMAN,
                "damage",
                "artifactability_marksmanhunter_legacyofthewindrunners",
                "strike",
                "healthy",
                26,
            },
            { L.KILLING_ZONE, "damage", "ability_hunter_rapidkilling", "strike", "execute", 28 },
        },
        {
            {
                L.WILDFIRE_INFUSION,
                "damage",
                "inv_wildfirebomb_shrapnel",
                "strike",
                "burning",
                28,
            },
            {
                L.SURVIVAL_OF_THE_FITTEST,
                "mitigation",
                "artifactability_survivalhunter_eaglesbite",
                "defense",
                "wounded",
                16,
            },
        },
    },
    ROGUE = {
        {
            {
                L.SANGUINE_BLADES,
                "damage",
                "ability_ironmaidens_sanguinestrikes",
                "basic",
                "bleed",
                26,
            },
            { L.VENOMOUS_INTENT, "speed", "ability_rogue_deadlybrew", "strike", "execute", 28 },
        },
        {
            { L.BLADE_RUSH, "damage", "ability_ironmaidens_bladerush", "strike", "group", 28 },
            { L.DEFT_MANEUVERS, "mitigation", "ability_rogue_feint", "defense", "quick", 14 },
        },
        {
            { L.SHADOWED_FINISH, "speed", "ability_rogue_ambush", "strike", "execute", 30 },
            { L.LINGERING_SHADOW, "speed", "rogue_shadow_reflection", "basic", "late", 26 },
        },
    },
    PRIEST = {
        {
            {
                L.HARSH_DISCIPLINE,
                "damage",
                "ability_priest_clarityofwill",
                "strike",
                "shielded",
                26,
            },
            {
                L.PROTECTIVE_LIGHT,
                "healing",
                "spell_holy_divineshield",
                "healing",
                "protect",
                30,
            },
        },
        {
            {
                L.ANSWERED_PRAYERS,
                "speed",
                "spell_holy_prayerofmendingtga",
                "healing",
                "rescue",
                30,
            },
            { L.DIVINE_IMAGE, "healing", "spell_holy_divineprovidence", "healing", "ally", 28 },
        },
        {
            { L.VOID_ERUPTION, "damage", "ability_priest_voidentropy", "strike", "group", 28 },
            {
                L.DEVOURING_DARKNESS,
                "damage",
                "ability_priest_surgeofdarkness",
                "basic",
                "burning",
                26,
            },
        },
    },
    SHAMAN = {
        {
            { L.SEARING_ECHOES, "damage", "spell_shaman_lavaburst", "strike", "burning", 28 },
            {
                L.STORM_ASCENDANT,
                "speed",
                "ability_thunderking_balllightning",
                "basic",
                "boss",
                24,
            },
        },
        {
            { L.ASHEN_CATALYST, "damage", "ability_shaman_lavalash", "basic", "burning", 28 },
            { L.CRASHING_THUNDER, "speed", "ability_thunderbolt", "strike", "group", 26 },
        },
        {
            { L.DELUGE, "healing", "ability_shaman_healingtide", "healing", "wounded", 28 },
            { L.TIDEBRINGER, "speed", "spell_nature_healingway", "healing", "ally", 24 },
        },
    },
    MAGE = {
        {
            {
                L.ARCANE_BOMBARDMENT,
                "damage",
                "ability_mage_arcanebarrage",
                "strike",
                "execute",
                30,
            },
            { L.SUSTAINED_POWER, "speed", "spell_arcane_arcanetactics", "basic", "patient", 24 },
        },
        {
            { L.SEARING_TOUCH, "speed", "spell_fire_soulburn", "strike", "execute", 30 },
            {
                L.WILDFIRE_CASCADE,
                "speed",
                "ability_mage_worldinflames",
                "basic",
                "burning",
                24,
            },
        },
        {
            { L.COMET_STORM, "damage", "spell_mage_cometstorm", "strike", "group", 28 },
            {
                L.GLACIAL_SHELTER,
                "mitigation",
                "spell_frost_frostnova",
                "defense",
                "patient",
                14,
            },
        },
    },
    WARLOCK = {
        {
            { L.WITHERING_BOLT, "damage", "spell_shadow_shadowbolt", "strike", "burning", 28 },
            {
                L.SOUL_HARVESTER,
                "healing",
                "inv_ability_soulharvesterwarlock_demonicsoul",
                "healing",
                "execute",
                30,
            },
        },
        {
            { L.FEL_DOMINION, "damage", "spell_shadow_felarmour", "basic", "late", 26 },
            {
                L.DEMONIC_AEGIS,
                "mitigation",
                "ability_warlock_improveddemonictactics",
                "defense",
                "boss",
                14,
            },
        },
        {
            { L.RUIN, "damage", "ability_xavius_darkruination", "strike", "armored", 30 },
            {
                L.INFERNAL_COMBUSTION,
                "burningWounds",
                "spell_fire_firebolt02",
                "basic",
                "burning",
                24,
            },
        },
    },
    DRUID = {
        {
            { L.ASTRAL_SMOLDER, "damage", "ability_druid_lunarguidance", "strike", "late", 28 },
            { L.LUNAR_SHRAPNEL, "speed", "spell_druid_lunarinspiration", "basic", "group", 24 },
        },
        {
            { L.BLOODTALONS, "damage", "ability_druid_rake", "strike", "bleed", 30 },
            { L.URSINE_VIGOR, "health", "ability_druid_enrage", "defense", "wounded", 16 },
        },
        {
            {
                L.SPRING_BLOSSOMS,
                "regen",
                "inv_misc_herb_talandrasrose",
                "healing",
                "group",
                24,
            },
            { L.PHOTOSYNTHESIS, "speed", "ability_druid_replenish", "healing", "late", 26 },
        },
    },
}
for classID, paths in pairs(finalChoices) do
    for path, entries in ipairs(paths) do
        local target = additions[classID][path]
        for _, entry in ipairs(entries) do
            target[#target + 1] = entry
        end
    end
end

for classID, paths in pairs(additions) do
    local list, byID = C.talentsByClass[classID], C.talentByClassID[classID]
    for path, entries in ipairs(paths) do
        local spec = C.talentSpecs[classID][path]
        for index, entry in ipairs(entries) do
            local position = 8 + index
            local effect = C.talentEffects[entry[2]]
            local id = classID:lower() .. "_" .. path .. "_" .. position
            local node = {
                id = id,
                name = entry[1],
                effect = entry[2],
                value = effect.value,
                text = effect.text,
                path = path,
                row = math.floor((position - 1) / 2) + 1,
                column = (position - 1) % 2 + 2,
            }
            C.ApplyTalentTrait(node, { entry[3], entry[4], entry[5], entry[6] })
            spec[#spec + 1] = entry[1] .. "/" .. entry[2]
            list[#list + 1], byID[id] = node, node
        end
    end
end

-- Ranks and mechanics are authored per node, independently of the stat category.
local variedTalents = {
    WARRIOR = {
        { "1_9",  "criticalChance", 3 }, { "1_10", "resourceGain", 2 },
        { "1_11", "criticalDamage", 2 }, { "1_17", "dotDamage", 3 },
        { "2_9",  "attackSpeed",  5 }, { "2_10", "abilityEfficiency", 3 },
        { "2_13", "cooldownRate", 2 }, { "3_9", "abilityEfficiency", 2 },
        { "3_10", "resourceGain", 3 }, { "1_5", false, 2 }, { "2_5", false, 3 }, { "3_4", false, 2 },
    },
    PALADIN = {
        { "1_9",  "criticalHealing",      3 }, { "1_10", "overhealShield", 2 },
        { "1_16", "superCriticalHealing", 2 }, { "1_17", "criticalDamage", 3 },
        { "2_9", "resourceGain", 5 }, { "2_10", "abilityEfficiency", 2 },
        { "3_9", "attackSpeed",  3 }, { "3_10", "criticalChance", 5 },
        { "2_3", false, 3 }, { "3_7", false, 2 },
    },
    HUNTER = {
        { "1_9",  "attackSpeed",    2 }, { "1_10", "resourceGain", 3 },
        { "1_17", "criticalChance", 2 }, { "2_9", "criticalDamage", 5 },
        { "2_10", "superCriticalChance", 3 }, { "3_9", "abilityEfficiency", 5 },
        { "3_10", "cooldownRate",        2 }, { "3_17", "dotDamage", 3 },
        { "1_6", false, 2 }, { "2_4", false, 3 },
    },
    ROGUE = {
        { "1_9",  "criticalChance", 5 }, { "1_10", "abilityEfficiency", 2 },
        { "1_14", "resourceGain",   3 }, { "1_17", "dotDamage", 2 },
        { "2_9", "attackSpeed",         3 }, { "2_10", "criticalDamage", 2 },
        { "3_9", "superCriticalChance", 2 }, { "3_10", "cooldownRate", 5 },
        { "2_6", false, 3 }, { "3_7", false, 2 },
    },
    PRIEST = {
        { "1_9",  "criticalHealing",   2 }, { "1_10", "overhealShield", 3 },
        { "1_18", "abilityEfficiency", 3 }, { "2_9", "cooldownRate", 3 },
        { "2_10", "resourceGain",         5 }, { "2_16", "criticalChance", 2 },
        { "2_18", "superCriticalHealing", 3 }, { "3_9", "criticalDamage", 3 },
        { "3_10", "superCriticalChance", 5 }, { "3_16", "dotDamage", 2 },
        { "1_5",  false,                 2 }, { "2_7", false, 3 },
    },
    SHAMAN = {
        { "1_9", "criticalChance", 3 }, { "1_10", "abilityEfficiency", 5 },
        { "2_9", "attackSpeed",    2 }, { "2_10", "resourceGain", 3 },
        { "3_9", "criticalHealing", 5 }, { "3_10", "overhealShield", 2 },
        { "1_5", false,             2 }, { "2_7", false, 3 }, { "3_6", false, 3 },
    },
    MAGE = {
        { "1_9", "resourceGain",   2 }, { "1_10", "abilityEfficiency", 3 },
        { "2_9", "criticalChance", 3 }, { "2_10", "criticalDamage", 5 },
        { "2_18", "dotDamage",           3 }, { "3_9", "cooldownRate", 5 },
        { "3_10", "superCriticalChance", 2 }, { "3_17", "superCriticalDamage", 3 },
        { "1_6", false, 3 }, { "3_7", false, 2 },
    },
    WARLOCK = {
        { "1_9",  "abilityEfficiency", 3 }, { "1_10", "resourceGain", 5 },
        { "1_17", "dotDamage",         5 }, { "2_9", "attackSpeed", 3 },
        { "2_10", "criticalChance",      2 }, { "3_9", "criticalDamage", 2 },
        { "3_10", "superCriticalChance", 3 }, { "3_16", "superCriticalDamage", 2 },
        { "1_7", false, 2 }, { "2_2", false, 3 },
    },
    DRUID = {
        { "1_9",  "criticalChance",      5 }, { "1_10", "cooldownRate", 3 },
        { "1_17", "superCriticalDamage", 2 }, { "2_9", "attackSpeed", 5 },
        { "2_10", "abilityEfficiency", 2 }, { "3_9", "criticalHealing", 2 },
        { "3_10", "overhealShield",    5 }, { "3_17", "resourceGain", 3 },
        { "3_18", "superCriticalHealing", 2 }, { "1_5", false, 3 }, { "2_3", false, 2 },
    },
}
for classID, entries in pairs(variedTalents) do
    for _, entry in ipairs(entries) do
        local node = assert(C.talentByClassID[classID][classID:lower() .. "_" .. entry[1]])
        node.maxRanks = entry[3]
        if entry[2] then
            local definition = C.talentEffects[entry[2]]
            node.effect, node.value, node.text = entry[2], definition.value, definition.text
            if node.trait then
                C.ApplyTalentTrait(node, {
                    node.icon, node.trait.kind, node.trait.condition, node.trait.amount * 100,
                })
            end
        end
    end
end

-- Each row needs a passive investment alongside its one-point signature choices.
for _, class in ipairs(C.classes) do
    for path = 1, 3 do
        local nodes = {}
        for _, node in ipairs(C.talentsByClass[class.id]) do
            node.maxRanks = node.maxRanks or (node.value == true and 1 or 5)
            if node.path == path then nodes[#nodes + 1] = node end
        end
        for _, node in ipairs(nodes) do
            if node.value ~= true then
                local units = node.effect == "regen" and 1000 or 100
                local perRank = math.max(1, math.floor(node.value * units / node.maxRanks + 0.5))
                node.value = node.effect == "abilityEfficiency" and node.maxRanks or perRank * node.maxRanks / units
                if node.trait then
                    local amount = math.max(1, math.floor(node.trait.amount * 100 / node.maxRanks + 0.5))
                    node.trait.amount = amount * node.maxRanks / 100
                end
                node.text = C.TalentRankText(node, node.maxRanks)
            end
        end
        for index = 1, #nodes, 3 do
            local capacity = nodes[index].maxRanks + nodes[index + 1].maxRanks + nodes[index + 2].maxRanks
            if capacity < C.talentProgression.pointsPerRow then
                local smallest, strongest = index, index + 3
                for choice = index + 1, index + 2 do
                    if nodes[choice].maxRanks <= nodes[smallest].maxRanks then smallest = choice end
                end
                for later = index + 3, #nodes do
                    if nodes[later].maxRanks > nodes[strongest].maxRanks then strongest = later end
                end
                assert(nodes[strongest], "Talent rows need enough investment capacity")
                nodes[smallest], nodes[strongest] = nodes[strongest], nodes[smallest]
            end
        end
        for index, node in ipairs(nodes) do
            node.row = math.floor((index - 1) / 3) + 1
            node.column = (index - 1) % 3 + 1
        end
    end
end
