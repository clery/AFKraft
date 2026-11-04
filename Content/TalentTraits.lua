local _, W = ...
local L = W.L
local C = W.Content

C.heroLevelCap = 60
C.talentProgression = { levelsPerPoint = 2 }
C.mastery = {
    unlockLevel = 20,
    baseXP = 100,
    xpPerRank = 50,
    softCap = 8,
    xpPerLateRank = 100,
    bossMultiplier = 2,
}

-- Node order follows talentSpecs so existing saved IDs and prerequisites stay intact.
-- Shared foundations gain a situational bonus; signature mechanics already stand alone.
local traits = {
    WARRIOR = {
        { "Ability_Whirlwind", "strike", "group", 12 }, -- Sweeping Strikes
        { "Ability_Warrior_SavageBlow" }, -- Mortal Wounds
        { "Ability_Warrior_BattleShout", "basic", "opening", 20 }, -- Battle Tempo
        { "Ability_MeleeDamage", "strike", "boss", 14 }, -- Weapon Mastery
        { "Ability_Warrior_StrengthOfArms", "defense", "healthy", 8 }, -- Seasoned Soldier
        { "Ability_BackStab", "strike", "bleed", 18 }, -- Deep Wounds
        { "Ability_Warrior_SecondWind", "healing", "wounded", 20 }, -- Second Wind
        { "Ability_Warrior_ColossusSmash", "strike", "armored", 16 }, -- Colossus Smash
        { "Spell_Nature_BloodLust" }, -- Bloodthirst
        { "Ability_Warrior_EndlessRage", "healing", "wounded", 24 }, -- Enraged Recovery
        { "Ability_GhoulFrenzy", "basic", "wounded", 16 }, -- Flurry
        { "Spell_Nature_AncestralGuardian", "strike", "wounded", 18 }, -- Unbridled Wrath
        { "Ability_Warrior_BloodFrenzy", "healing", "late", 20 }, -- Blood Craze
        { "Spell_Shadow_DeathScream", "strike", "group", 16 }, -- Piercing Howl
        { "Ability_CriticalStrike", "strike", "execute", 24 }, -- Recklessness
        { "Ability_Warrior_TitansGrip", "basic", "late", 18 }, -- Titan's Grip
        { "Ability_Warrior_ShieldWall", "defense", "opening", 14 }, -- Shield Wall
        { "Ability_Warrior_Challange" }, -- Retaliation
        { "Spell_Holy_AshesToAshes", "defense", "wounded", 12 }, -- Last Stand
        { "INV_Shield_06", "defense", "boss", 10 }, -- Shield Discipline
        { "Ability_Warrior_Revenge", "basic", "shielded", 22 }, -- Revenge
        { "Ability_Warrior_Warbringer", "strike", "opening", 18 }, -- Warbringer
        { "INV_Misc_Bandage_05", "healing", "shielded", 20 }, -- Field Dressing
        { "Ability_Warrior_ShieldMastery", "defense", "late", 10 }, -- Unbreakable
    },
    PALADIN = {
        { "Spell_Holy_Heal", "healing", "opening", 18 }, -- Divine Favor
        { "Ability_Paladin_BeaconOfLight" }, -- Beacon of Light
        { "Spell_Holy_GreaterHeal", "healing", "shielded", 22 }, -- Illumination
        { "Spell_Holy_BlessedLife", "healing", "wounded", 16 }, -- Blessed Recovery
        { "Spell_Holy_HolyGuidance", "healing", "boss", 20 }, -- Holy Guidance
        { "Spell_Holy_DivineIntervention", "defense", "shielded", 10 }, -- Sacred Duty
        { "Spell_Holy_LightsGrace", "healing", "late", 18 }, -- Light's Grace
        { "Spell_Holy_DivinePurpose", "healing", "group", 16 }, -- Divine Purpose
        { "Spell_Holy_SealOfFury", "defense", "group", 12 }, -- Righteous Fury
        { "Spell_Holy_BlessingOfProtection" }, -- Holy Shield
        { "spell_holy_greaterblessingofsanctuary", "defense", "shielded", 14 }, -- Sanctuary
        { "Spell_Holy_AvengersShield", "strike", "group", 18 }, -- Avenger's Shield
        { "Spell_Holy_BlessingOfStamina", "defense", "healthy", 10 }, -- Redoubt
        { "Spell_Holy_InnerFire", "basic", "group", 14 }, -- Consecrated Ground
        { "Spell_Holy_ArdentDefender", "healing", "critical", 28 }, -- Ardent Defender
        { "Spell_Holy_DivineProtection", "defense", "boss", 14 }, -- Guardian of Kings
        { "Spell_Holy_Crusade", "strike", "late", 16 }, -- Crusade
        { "Spell_Holy_HealingAura" }, -- Judgement of Light
        { "Ability_ThunderClap", "strike", "execute", 28 }, -- Hammer of Wrath
        { "Spell_Holy_SealOfBlood", "basic", "healthy", 16 }, -- Zeal
        { "Spell_Holy_WeaponMastery", "strike", "armored", 20 }, -- Conviction
        { "Ability_Paladin_ArtOfWar", "basic", "opening", 24 }, -- Art of War
        { "Ability_Paladin_SelflessHealer", "healing", "ally", 24 }, -- Selfless Healer
        { "Spell_Holy_AvengineWrath", "strike", "boss", 22 }, -- Avenging Wrath
    },
    HUNTER = {
        { "Ability_Druid_DemoralizingRoar", "healing", "healthy", 16 }, -- Spirit Bond
        { "Ability_Hunter_BestialDiscipline" }, -- Bestial Wrath
        { "Ability_Druid_FerociousBite", "basic", "late", 22 }, -- Frenzy
        { "ability_hunter_beastcall", "basic", "group", 18 }, -- Beast Cleave
        { "Ability_Hunter_MendPet", "healing", "critical", 24 }, -- Mend Companion
        { "INV_Misc_Pelt_Bear_03", "defense", "boss", 12 }, -- Animal Fortitude
        { "ability_hunter_invigeration", "healing", "wounded", 18 }, -- Predator's Thirst
        { "Spell_Nature_ProtectionformNature", "defense", "group", 10 }, -- Aspect of the Wild
        { "Ability_Hunter_FocusedAim" }, -- Careful Aim
        { "Ability_Hunter_Assassinate", "strike", "execute", 20 }, -- Kill Shot
        { "Ability_Hunter_RunningShot", "basic", "opening", 28 }, -- Rapid Fire
        { "Ability_TrueShot", "strike", "healthy", 18 }, -- Trueshot
        { "Spell_Frost_Stun", "basic", "healthy", 20 }, -- Concussive Shot
        { "Ability_Hunter_MasterMarksman", "strike", "boss", 18 }, -- Master Marksman
        { "Ability_Hunter_Camouflage", "defense", "opening", 12 }, -- Camouflage
        { "Ability_Hunter_ImprovedSteadyShot", "strike", "late", 20 }, -- Steady Focus
        { "Ability_Hunter_SurvivalInstincts", "defense", "solo", 14 }, -- Survivalist
        { "Spell_Fire_SelfDestruct" }, -- Explosive Trap
        { "Ability_Hunter_Misdirection", "defense", "group", 14 }, -- Misdirection
        { "Ability_Hunter_OneWithNature", "healing", "wounded", 28 }, -- Exhilaration
        { "INV_WildfireBomb", "strike", "group", 22 }, -- Wildfire
        { "Ability_Hunter_Harpoon", "basic", "opening", 18 }, -- Harpoon
        { "Ability_Hunter_Pathfinding", "basic", "solo", 16 }, -- Trailblazer
        { "INV_Misc_Bandage_08", "healing", "late", 24 }, -- Wilderness Medicine
    },
    ROGUE = {
        { "Ability_Rogue_DualWeild" }, -- Deadly Poison
        { "Ability_Rogue_VenomousWounds", "strike", "bleed", 22 }, -- Venomous Wounds
        { "Spell_Shadow_ChillTouch", "basic", "bleed", 18 }, -- Seal Fate
        { "Ability_Rogue_CutToTheChase", "basic", "late", 14 }, -- Cut to the Chase
        { "INV_ThrowingKnife_04", "strike", "execute", 26 }, -- Dispatch
        { "Spell_Nature_NullifyPoison", "healing", "solo", 20 }, -- Alchemical Recovery
        { "Ability_Creature_Poison_06", "strike", "armored", 18 }, -- Master Poisoner
        { "rogue_leeching_poison", "healing", "bleed", 24 }, -- Leeching Poison
        { "Ability_Warrior_PunishingBlow", "basic", "group", 22 }, -- Blade Flurry
        { "Ability_Parry", "basic", "armored", 18 }, -- Riposte
        { "Ability_Warrior_WeaponMastery" }, -- Combat Potency
        { "Spell_Shadow_ShadowWordDominate", "strike", "late", 24 }, -- Adrenaline Rush
        { "Ability_Rogue_CombatReadiness", "defense", "late", 12 }, -- Combat Readiness
        { "INV_Drink_03", "healing", "wounded", 22 }, -- Iron Stomach
        { "ability_rogue_dismantle", "strike", "boss", 20 }, -- Blade Master
        { "Ability_Rogue_NervesOfSteel", "defense", "solo", 10 }, -- Enduring Brawler
        { "Ability_Rogue_Shadowstep", "strike", "opening", 24 }, -- Shadowstep
        { "Spell_Shadow_Possession" }, -- Premeditation
        { "Ability_Rogue_Recuperate", "healing", "opening", 20 }, -- Recuperate
        { "ability_rogue_deadliness", "defense", "opening", 16 }, -- Elusiveness
        { "Ability_Rogue_ShadowDance", "strike", "healthy", 26 }, -- Shadow Dance
        { "Ability_Rogue_EnvelopingShadows", "healing", "solo", 24 }, -- Soothing Darkness
        { "Ability_Rogue_MasterOfSubtlety", "basic", "solo", 20 }, -- Master of Shadows
        { "Ability_Rogue_CheatDeath", "defense", "critical", 24 }, -- Cheat Death
    },
    PRIEST = {
        { "Ability_Priest_Atonement" }, -- Atonement
        { "Spell_Holy_PowerWordShield", "defense", "shielded", 18 }, -- Power Word Shield
        { "Spell_Holy_BorrowedTime", "basic", "shielded", 18 }, -- Borrowed Time
        { "Ability_Priest_ReflectiveShield", "strike", "shielded", 20 }, -- Reflective Shield
        { "Spell_Holy_HopeAndGrace", "healing", "shielded", 26 }, -- Grace
        { "Spell_Holy_PainSupression", "defense", "critical", 20 }, -- Pain Suppression
        { "Spell_Holy_DivineIllumination", "strike", "healthy", 16 }, -- Evangelism
        { "Spell_Holy_PowerInfusion", "basic", "late", 12 }, -- Power Infusion
        { "Spell_Holy_Renew", "healing", "late", 22 }, -- Renew
        { "Spell_Holy_DivineHymn" }, -- Divine Hymn
        { "Spell_Holy_Fanaticism", "healing", "group", 22 }, -- Holy Concentration
        { "Spell_Holy_SurgeOfLight", "healing", "opening", 24 }, -- Surge of Light
        { "Spell_Holy_BlessedResillience", "defense", "critical", 16 }, -- Blessed Resilience
        { "Spell_Holy_SummonLightwell", "healing", "healthy", 20 }, -- Lightwell
        { "Spell_Holy_Serendipity", "healing", "wounded", 26 }, -- Serendipity
        { "Spell_Holy_GuardianSpirit", "healing", "critical", 32 }, -- Guardian Spirit
        { "Spell_Shadow_MindShear", "strike", "group", 26 }, -- Mind Sear
        { "Spell_Shadow_DemonicFortitude" }, -- Shadow Word Death
        { "Spell_Shadow_PsychicScream", "defense", "group", 16 }, -- Psychic Scream
        { "Spell_Shadow_Twilight", "strike", "late", 18 }, -- Darkness
        { "Spell_Shadow_UnsummonBuilding", "healing", "execute", 24 }, -- Vampiric Embrace
        { "Spell_Shadow_Shadowform", "defense", "healthy", 12 }, -- Shadowform
        { "Spell_Shadow_MindTwisting", "strike", "execute", 22 }, -- Twist of Fate
        { "Spell_Priest_VoidSear", "basic", "boss", 22 }, -- Void Torrent
    },
    SHAMAN = {
        { "Spell_Nature_ChainLightning" }, -- Chain Lightning
        { "Spell_Fire_Volcano", "strike", "boss", 26 }, -- Elemental Fury
        { "Spell_Shaman_LavaSurge", "basic", "late", 24 }, -- Lava Surge
        { "Spell_Shaman_ThunderStorm", "strike", "group", 20 }, -- Thunderstorm
        { "Spell_Nature_SpiritArmor", "defense", "group", 8 }, -- Elemental Warding
        { "Spell_Nature_StormReach", "strike", "late", 22 }, -- Aftershock
        { "Spell_Nature_LightningOverload", "strike", "healthy", 24 }, -- Stormkeeper
        { "Spell_Fire_ElementalDevastation", "basic", "group", 26 }, -- Ascendance
        { "Ability_Shaman_Stormstrike", "strike", "armored", 24 }, -- Stormstrike
        { "Spell_Fire_FlameTounge", "healing", "group", 18 }, -- Flametongue
        { "Spell_Nature_Cyclone" }, -- Windfury
        { "Spell_Nature_LightningShield", "basic", "group", 20 }, -- Lightning Shield
        { "Spell_Shaman_FeralSpirit", "defense", "solo", 16 }, -- Feral Spirit
        { "Spell_Shaman_MaelstromWeapon", "basic", "late", 26 }, -- Maelstrom Weapon
        { "Spell_Nature_ShamanRage", "defense", "critical", 18 }, -- Shamanistic Rage
        { "Spell_Nature_StoneSkinTotem", "defense", "armored", 14 }, -- Earthen Strength
        { "Spell_Nature_Riptide", "healing", "opening", 22 }, -- Riptide
        { "Spell_Shaman_TidalWaves" }, -- Tidal Waves
        { "Spell_Shaman_EarthlivingWeapon", "healing", "late", 26 }, -- Earthliving
        { "spell_nature_healingwavegreater", "healing", "solo", 18 }, -- Healing Stream
        { "Spell_Nature_RavenForm", "healing", "wounded", 18 }, -- Tidal Focus
        { "Spell_Shaman_AncestralAwakening", "healing", "healthy", 22 }, -- Ancestral Vigor
        { "spell_shaman_improvedearthshield", "healing", "critical", 30 }, -- Deep Healing
        { "Spell_Shaman_SpiritLink", "defense", "group", 18 }, -- Spirit Link
    },
    MAGE = {
        { "Spell_Nature_Lightning" }, -- Arcane Power
        { "Spell_Arcane_ArcaneTorrent", "strike", "group", 24 }, -- Arcane Echo
        { "Spell_Nature_EnchantArmor", "strike", "opening", 28 }, -- Presence of Mind
        { "Spell_Arcane_Arcane01", "strike", "healthy", 22 }, -- Nether Precision
        { "spell_arcane_prismaticcloak", "defense", "shielded", 12 }, -- Prismatic Barrier
        { "Spell_Shadow_DetectLesserInvisibility", "defense", "opening", 10 }, -- Mana Shield
        { "Spell_Nature_Sleep", "healing", "late", 16 }, -- Arcane Meditation
        { "Spell_Mage_TemporalShield", "healing", "critical", 26 }, -- Temporal Mending
        { "Spell_Fire_Incinerate" }, -- Ignite
        { "Ability_Mage_HotStreak", "basic", "late", 20 }, -- Hot Streak
        { "Spell_Fire_Rune", "healing", "critical", 22 }, -- Cauterize
        { "Spell_Fire_Immolation", "defense", "bleed", 16 }, -- Molten Armor
        { "Spell_Fire_SealOfFire", "strike", "execute", 30 }, -- Combustion
        { "inv_elemental_mote_fire01", "basic", "healthy", 24 }, -- Flame On
        { "Spell_Fire_Burnout", "healing", "execute", 20 }, -- Phoenix Warmth
        { "Spell_Fire_Fireball02", "strike", "late", 26 }, -- Pyromaniac
        { "Spell_Frost_FrostArmor" }, -- Frostbite
        { "Spell_Ice_Lament", "defense", "healthy", 14 }, -- Ice Barrier
        { "Spell_Frost_FrostShock", "strike", "opening", 20 }, -- Shatter
        { "Spell_Frost_WizardMark", "strike", "late", 14 }, -- Cold Snap
        { "Spell_Frost_IceFloes", "basic", "solo", 18 }, -- Ice Floes
        { "Spell_Frost_ArcticWinds", "healing", "healthy", 24 }, -- Frost Channeling
        { "Spell_Frost_FrostArmor02", "defense", "wounded", 14 }, -- Winter's Resilience
        { "Ability_Mage_GlacialSpike", "strike", "boss", 28 }, -- Glacial Spike
    },
    WARLOCK = {
        { "Spell_Shadow_LifeDrain02" }, -- Drain Life
        { "Spell_Shadow_LifeDrain", "healing", "burning", 28 }, -- Soul Siphon
        { "spell_shadow_spectralsight", "basic", "burning", 24 }, -- Nightfall
        { "Spell_Shadow_Haunting", "strike", "burning", 26 }, -- Haunt
        { "spell_shadow_haunting_grey", "strike", "execute", 32 }, -- Drain Soul
        { "Spell_Shadow_DeathPact", "healing", "late", 28 }, -- Dark Regeneration
        { "Spell_Shadow_Requiem", "healing", "critical", 20 }, -- Siphon Life
        { "Spell_Shadow_UnstableAffliction_3", "strike", "boss", 24 }, -- Unstable Affliction
        { "Spell_Shadow_GatherShadows" }, -- Soul Link
        { "Spell_Shadow_RagingScream", "defense", "healthy", 16 }, -- Demon Armor
        { "spell_shadow_felmending", "defense", "boss", 16 }, -- Fel Vitality
        { "Spell_Shadow_DemonicEmpathy", "basic", "armored", 24 }, -- Demonic Reprisal
        { "Spell_Shadow_DemonicTactics", "basic", "late", 28 }, -- Demonic Frenzy
        { "ability_warlock_inferno", "strike", "group", 28 }, -- Felstorm
        { "spell_shadow_lifedrain02_purple", "healing", "solo", 26 }, -- Health Funnel
        { "Spell_Shadow_DemonicPact", "strike", "late", 28 }, -- Demonic Pact
        { "Spell_Shadow_Shadowfury" }, -- Shadowfury
        { "Ability_Warlock_Backdraft", "basic", "opening", 26 }, -- Backdraft
        { "Spell_Fire_FelFire", "strike", "healthy", 28 }, -- Chaos Bolt
        { "Spell_Shadow_ScourgeBuild", "strike", "execute", 34 }, -- Shadowburn
        { "spell_fire_felflamering", "healing", "execute", 26 }, -- Ember Tap
        { "Spell_Fire_FelImmolation", "basic", "group", 24 }, -- Fire and Brimstone
        { "Spell_Shadow_SoulLeech_3", "healing", "burning", 20 }, -- Soul Leech
        { "Spell_Shadow_SummonInfernal", "strike", "boss", 30 }, -- Infernal Power
    },
    DRUID = {
        { "Ability_Druid_Starfall" }, -- Starfall
        { "Ability_Druid_Eclipse", "strike", "late", 30 }, -- Eclipse
        { "Spell_Nature_NaturesBlessing", "basic", "late", 30 }, -- Nature's Grace
        { "Ability_Druid_Typhoon", "strike", "group", 30 }, -- Typhoon
        { "Spell_Nature_ForceOfNature", "defense", "armored", 12 }, -- Moonkin Form
        { "ability_druid_tigersroar", "basic", "healthy", 22 }, -- Shooting Stars
        { "Spell_Nature_NatureGuardian", "strike", "healthy", 30 }, -- Celestial Alignment
        { "Spell_Nature_AstralRecal", "healing", "opening", 26 }, -- Astral Communion
        { "Ability_Druid_SkinTeeth", "basic", "bleed", 26 }, -- Savage Roar
        { "Ability_Hunter_Pet_Cat" }, -- Predatory Strikes
        { "Spell_Nature_UnyeildingStamina", "healing", "group", 24 }, -- Leader of the Pack
        { "INV_Misc_Pelt_Bear_01", "defense", "wounded", 16 }, -- Thick Hide
        { "Spell_Druid_BristlingFur", "basic", "armored", 26 }, -- Bristling Fur
        { "Spell_Holy_BlessingOfAgility", "defense", "group", 20 }, -- Heart of the Wild
        { "Ability_Mount_JungleTiger", "basic", "wounded", 24 }, -- Tiger's Fury
        { "ability_druid_berserk", "defense", "critical", 22 }, -- Survival Instincts
        { "Spell_Nature_Rejuvenation" }, -- Rejuvenation
        { "INV_Relics_IdolofRejuvenation", "healing", "critical", 34 }, -- Swiftmend
        { "INV_Misc_Herb_Felblossom", "healing", "late", 30 }, -- Lifebloom
        { "Ability_Druid_GiftoftheEarthmother", "healing", "healthy", 26 }, -- Living Seed
        { "Spell_Nature_ResistNature", "healing", "group", 28 }, -- Gift of Nature
        { "Spell_Nature_NaturesWrath", "healing", "opening", 28 }, -- Nature's Swiftness
        { "Spell_Druid_Ironbark", "defense", "bleed", 18 }, -- Ironbark
        { "Ability_Druid_TreeofLife", "healing", "wounded", 30 }, -- Tree of Life
    },
}

local conditions = {
    group = "while at least two enemies are alive",
    solo = "while only one enemy is alive",
    boss = "during boss encounters",
    opening = "during the first 6 seconds of combat",
    late = "after 12 seconds of combat",
    healthy = "while above 80% health",
    wounded = "while below half health",
    critical = "while below 30% health",
    execute = "against enemies below 35% health",
    bleed = "while the target is bleeding or poisoned",
    armored = "while your health percentage exceeds the enemy's",
    shielded = "while protected by an absorb shield",
    ally = "when healing another hero",
    patient = "after you have used three offensive abilities this encounter",
    quick = "from your third basic attack onward this encounter",
    unhurt = "while at full health",
    burning = "while the target has a magical damage-over-time effect",
    rescue = "while the recipient is below 20% health",
    protect = "while another living ally is below 30% health",
    outnumbered = "while living enemies outnumber living heroes",
}

function C.ApplyTalentTrait(node, entry)
    node.icon = entry[1]
    if entry[2] then
        node.trait = { kind = entry[2], condition = entry[3], amount = entry[4] / 100 }
        local subject = entry[2] == "healing" and "Direct healing restores"
            or entry[2] == "basic" and "Basic attacks deal"
            or entry[2] == "strike" and "Offensive abilities deal"
            or "Take"
        local change = entry[2] == "defense" and "% less damage "
            or entry[2] == "healing" and "% more health "
            or "% more damage "
        local condition = conditions[entry[3]]
        if entry[2] == "healing" then
            if entry[3] == "healthy" or entry[3] == "wounded" or entry[3] == "critical" then
                condition = condition:gsub("while ", "while the recipient is ")
            elseif entry[3] == "shielded" then
                condition = "while the recipient has an absorb shield"
            elseif entry[3] == "execute" then
                condition = "while a living enemy is below 35% health"
            elseif entry[3] == "bleed" then
                condition = "while a living enemy is bleeding or poisoned"
            elseif entry[3] == "burning" then
                condition = "while a living enemy has a magical damage-over-time effect"
            elseif entry[3] == "unhurt" then
                condition = "while the recipient is at full health"
            end
        elseif entry[2] == "defense" and entry[3] == "bleed" then
            condition = "while the attacker is bleeding or poisoned"
        elseif entry[2] == "defense" and entry[3] == "burning" then
            condition = "while the attacker has a magical damage-over-time effect"
        end
        node.text = node.text
            .. "\n"
            .. string.format(
                L[subject .. " %d" .. change:gsub("%%", "%%%%") .. condition:gsub("%%", "%%%%") .. "."],
                entry[4]
            )
        if entry[2] == "defense" then
            node.text = node.text .. L[" Situational damage reduction is capped at 60%."]
        end
    end
end

for classID, entries in pairs(traits) do
    for index, entry in ipairs(entries) do
        C.ApplyTalentTrait(C.talentsByClass[classID][index], entry)
    end
end
