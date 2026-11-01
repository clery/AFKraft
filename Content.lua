local _, W = ...
WoWIdle = W
W.Content = {}
local C = W.Content
C.slots = { "Weapon", "Armor", "Head", "Accessory", "Trinket I", "Trinket II" }
C.materials = { timber = "Timber", hide = "Hide", ore = "Ore", relic = "Relic dust" }
C.materialOrder = { "timber", "hide", "ore", "relic" }
C.classes = {
    {
        id = "WARRIOR",
        name = "Warrior",
        icon = "Ability_Warrior_DefensiveStance",
        color = { 0.78, 0.61, 0.43 },
        paths = { "Arms", "Fury", "Protection" },
        attack = "Mortal Strike",
        special = "Whirlwind",
        heal = "Second Wind",
        role = "guard",
    },
    {
        id = "PALADIN",
        name = "Paladin",
        icon = "Spell_Holy_SealOfMight",
        color = { 0.96, 0.55, 0.73 },
        paths = { "Holy", "Protection", "Retribution" },
        attack = "Crusader Strike",
        special = "Consecration",
        heal = "Holy Light",
        role = "hybrid",
    },
    {
        id = "HUNTER",
        name = "Hunter",
        icon = "Ability_Hunter_AimedShot",
        color = { 0.67, 0.83, 0.45 },
        paths = { "Beast Mastery", "Marksmanship", "Survival" },
        attack = "Aimed Shot",
        special = "Multi-Shot",
        heal = "Exhilaration",
        role = "damage",
    },
    {
        id = "ROGUE",
        name = "Rogue",
        icon = "Ability_Rogue_Eviscerate",
        color = { 1, 0.94, 0.40 },
        paths = { "Assassination", "Combat", "Subtlety" },
        attack = "Sinister Strike",
        special = "Blade Flurry",
        heal = "Recuperate",
        role = "damage",
    },
    {
        id = "PRIEST",
        name = "Priest",
        icon = "Spell_Holy_PowerWordShield",
        color = { 0.91, 0.92, 0.94 },
        paths = { "Discipline", "Holy", "Shadow" },
        attack = "Smite",
        special = "Holy Nova",
        heal = "Flash Heal",
        role = "healer",
    },
    {
        id = "SHAMAN",
        name = "Shaman",
        icon = "Spell_Nature_Lightning",
        color = { 0.22, 0.53, 1 },
        paths = { "Elemental", "Enhancement", "Restoration" },
        attack = "Lightning Bolt",
        special = "Chain Lightning",
        heal = "Healing Wave",
        role = "hybrid",
    },
    {
        id = "MAGE",
        name = "Mage",
        icon = "Spell_Frost_FrostBolt02",
        color = { 0.40, 0.80, 0.94 },
        paths = { "Arcane", "Fire", "Frost" },
        attack = "Frostbolt",
        special = "Blizzard",
        heal = "Ice Barrier",
        role = "damage",
    },
    {
        id = "WARLOCK",
        name = "Warlock",
        icon = "Spell_Shadow_ShadowBolt",
        color = { 0.66, 0.53, 0.87 },
        paths = { "Affliction", "Demonology", "Destruction" },
        attack = "Shadow Bolt",
        special = "Rain of Fire",
        heal = "Drain Life",
        role = "damage",
    },
    {
        id = "DRUID",
        name = "Druid",
        icon = "Spell_Nature_StarFall",
        color = { 1, 0.49, 0.12 },
        paths = { "Balance", "Feral", "Restoration" },
        attack = "Wrath",
        special = "Starfall",
        heal = "Rejuvenation",
        role = "hybrid",
    },
}
C.classByID = {}
for _, class in ipairs(C.classes) do
    C.classByID[class.id] = class
end
-- Internal IDs are permanent. Client map IDs and assets belong in Client.lua.
C.zones = {
    {
        id = "elwynn",
        name = "Elwynn Forest",
        subtitle = "BENEATH THE GOLDEN BOUGHS",
        level = 1,
        material = "timber",
        biome = "forest",
        enemies = { "Forest prowler", "Kobold scout", "Riverpaw gnoll" },
        boss = "Hogger",
    },
    {
        id = "durotar",
        name = "Durotar",
        subtitle = "DUST ON THE HORIZON",
        level = 1,
        material = "hide",
        biome = "desert",
        enemies = { "Savannah boar", "Scorpid hunter", "Razormane scout" },
        boss = "The Razorback",
    },
    {
        id = "westfall",
        name = "Westfall",
        subtitle = "WHISPERS OF THE DEFIAS",
        level = 3,
        material = "ore",
        biome = "fields",
        enemies = { "Defias cutpurse", "Harvest watcher", "Dust devil" },
        boss = "The Defias Overseer",
    },
    {
        id = "barrens",
        name = "The Barrens",
        subtitle = "WHERE THE LONG ROAD CALLS",
        level = 3,
        material = "hide",
        biome = "desert",
        enemies = { "Savannah prowler", "Kolkar outrider", "Bristleback geomancer" },
        boss = "The Crossroads Marauder",
    },
    {
        id = "redridge",
        name = "Redridge Mountains",
        subtitle = "FIRE ACROSS THE LAKE",
        level = 5,
        material = "ore",
        biome = "fields",
        enemies = { "Blackrock outrider", "Redridge basher", "Black whelp" },
        boss = "The Blackrock Captain",
    },
    {
        id = "ashenvale",
        name = "Ashenvale",
        subtitle = "ANCIENT ROOTS, RESTLESS SHADOWS",
        level = 5,
        material = "timber",
        biome = "forest",
        enemies = { "Wild nightsaber", "Foulweald warrior", "Fallen keeper" },
        boss = "The Corrupted Ancient",
    },
    {
        id = "duskwood",
        name = "Duskwood",
        subtitle = "A LIGHT AGAINST THE DARK",
        level = 7,
        material = "relic",
        biome = "night",
        enemies = { "Restless skeleton", "Nightbane stalker", "Grave robber" },
        boss = "The Hollow Watcher",
    },
    {
        id = "wetlands",
        name = "Wetlands",
        subtitle = "FOOTSTEPS THROUGH THE MIST",
        level = 7,
        material = "hide",
        biome = "forest",
        enemies = { "Marsh crocolisk", "Dragonmaw scout", "Lost sailor" },
        boss = "The Mirefang",
    },
    {
        id = "stranglethorn",
        name = "Stranglethorn Vale",
        subtitle = "THE HUNT NEVER ENDS",
        level = 10,
        material = "hide",
        biome = "forest",
        enemies = { "Jungle stalker", "Bloodscalp hunter", "Venture Co. foreman" },
        boss = "The Jungle King",
    },
    {
        id = "desolace",
        name = "Desolace",
        subtitle = "BONES OF AN ANCIENT WORLD",
        level = 10,
        material = "relic",
        biome = "desert",
        enemies = { "Magram outrider", "Bone scavenger", "Burning Blade adept" },
        boss = "The Ashen Seer",
    },
    {
        id = "tanaris",
        name = "Tanaris",
        subtitle = "SECRETS UNDER THE SANDS",
        level = 14,
        material = "ore",
        biome = "desert",
        enemies = { "Wastewander bandit", "Sandfury scout", "Dunemaul brute" },
        boss = "The Sandstorm Herald",
    },
    {
        id = "winterspring",
        name = "Winterspring",
        subtitle = "THE WORLD IN SILVER",
        level = 18,
        material = "relic",
        biome = "snow",
        enemies = { "Frostsaber", "Winterfall shaman", "Ice thistle yeti" },
        boss = "The Winterbound",
    },
}
C.zoneByID = {}
for _, zone in ipairs(C.zones) do
    C.zoneByID[zone.id] = zone
end
C.biomes = {
    forest = {
        sky = { 0.12, 0.24, 0.25 },
        haze = { 0.22, 0.38, 0.33 },
        hills = { 0.10, 0.22, 0.20 },
        ground = { 0.08, 0.15, 0.14 },
        accent = { 0.75, 0.84, 0.50 },
    },
    fields = {
        sky = { 0.34, 0.32, 0.24 },
        haze = { 0.54, 0.47, 0.30 },
        hills = { 0.30, 0.33, 0.22 },
        ground = { 0.18, 0.22, 0.16 },
        accent = { 0.95, 0.77, 0.40 },
    },
    desert = {
        sky = { 0.38, 0.24, 0.21 },
        haze = { 0.64, 0.40, 0.27 },
        hills = { 0.37, 0.25, 0.20 },
        ground = { 0.24, 0.18, 0.16 },
        accent = { 1, 0.73, 0.43 },
    },
    night = {
        sky = { 0.08, 0.10, 0.19 },
        haze = { 0.17, 0.19, 0.29 },
        hills = { 0.10, 0.14, 0.22 },
        ground = { 0.07, 0.10, 0.16 },
        accent = { 0.62, 0.70, 0.95 },
    },
    snow = {
        sky = { 0.21, 0.31, 0.40 },
        haze = { 0.47, 0.60, 0.66 },
        hills = { 0.25, 0.39, 0.45 },
        ground = { 0.19, 0.29, 0.35 },
        accent = { 0.72, 0.91, 1 },
    },
}
C.names = {
    "Alden",
    "Briar",
    "Caelis",
    "Dara",
    "Elian",
    "Fen",
    "Galen",
    "Hesta",
    "Iris",
    "Joren",
    "Kaela",
    "Lorne",
    "Mira",
    "Neris",
    "Orin",
    "Perrin",
    "Rhea",
    "Sylas",
    "Tessa",
    "Varen",
}
C.appearances = {
    WARRIOR = {
        "human_male",
        "human_female",
        "orc_male",
        "dwarf_female",
        "nightelf_male",
        "undead_female",
        "tauren_male",
    },
    PALADIN = { "human_male", "human_female", "dwarf_male", "dwarf_female" },
    HUNTER = { "orc_male", "orc_female", "dwarf_male", "nightelf_female", "tauren_female" },
    ROGUE = { "human_female", "orc_female", "dwarf_male", "nightelf_male", "undead_male" },
    PRIEST = { "human_male", "dwarf_female", "nightelf_female", "undead_male" },
    SHAMAN = { "orc_male", "orc_female", "tauren_male", "tauren_female" },
    MAGE = { "human_male", "human_female", "undead_male", "undead_female" },
    WARLOCK = { "human_male", "human_female", "orc_female", "undead_male" },
    DRUID = { "nightelf_male", "nightelf_female", "tauren_male", "tauren_female" },
}
-- Idle talents are class-owned content, independent of client spell IDs.
-- Add a node to a specialization below; its effect is handled by the shared simulator.
C.talentEffects = {
    cleave = { value = true, text = "Basic attacks and strikes hit every enemy." },
    execute = { value = true, text = "Strikes deal 50% more damage below 35% enemy health." },
    haste = {
        value = true,
        text = "Offensive abilities have a 4.2 second base cooldown instead of 6 seconds.",
    },
    sustain = { value = true, text = "Healing abilities restore 60% more health." },
    renew = { value = true, text = "Restore an additional 8% health after victory." },
    leech = { value = true, text = "Offensive abilities restore 12% of their damage as health." },
    guard = { value = true, text = "Draw enemy attention and take 25% less damage." },
    thorns = { value = true, text = "Reflect 30% of received damage." },
    control = {
        value = true,
        text = "Offensive abilities delay each target's next attack by 1 second.",
    },
    damage = { value = 0.12, text = "Deal 12% more damage." },
    healing = { value = 0.2, text = "Healing power increased by 20%." },
    health = { value = 0.15, text = "Maximum health increased by 15%." },
    speed = { value = 0.1, text = "Basic attacks and ability cooldowns progress 10% faster." },
    mitigation = {
        value = 0.08,
        text = "Reduce incoming damage by an additional 8%, up to 75% total armor reduction.",
    },
    regen = { value = 0.005, text = "Regenerate 0.5% of maximum health per second." },
}
C.talentEffectIcons = {
    cleave = "Ability_Whirlwind",
    execute = "INV_Sword_48",
    haste = "Ability_Rogue_SliceDice",
    sustain = "Spell_Holy_Renew",
    renew = "Spell_Nature_Rejuvenation",
    leech = "Spell_Shadow_LifeDrain02",
    guard = "Ability_Defend",
    thorns = "Ability_Warrior_Riposte",
    control = "Spell_Frost_FrostNova",
}
C.talentSpecs = {
    WARRIOR = {
        {
            "Sweeping Strikes/cleave",
            "Mortal Wounds/execute",
            "Battle Tempo/haste",
            "Weapon Mastery/damage",
            "Seasoned Soldier/health",
            "Deep Wounds/damage",
            "Second Wind/renew",
            "Colossus Smash/damage",
        },
        {
            "Bloodthirst/leech",
            "Enraged Recovery/sustain",
            "Flurry/speed",
            "Unbridled Wrath/damage",
            "Blood Craze/regen",
            "Piercing Howl/control",
            "Recklessness/execute",
            "Titan's Grip/damage",
        },
        {
            "Shield Wall/guard",
            "Retaliation/thorns",
            "Last Stand/health",
            "Shield Discipline/mitigation",
            "Revenge/damage",
            "Warbringer/control",
            "Field Dressing/sustain",
            "Unbreakable/health",
        },
    },
    PALADIN = {
        {
            "Divine Favor/sustain",
            "Beacon of Light/healing",
            "Illumination/haste",
            "Blessed Recovery/renew",
            "Holy Guidance/healing",
            "Sacred Duty/health",
            "Light's Grace/speed",
            "Divine Purpose/healing",
        },
        {
            "Righteous Fury/guard",
            "Holy Shield/thorns",
            "Sanctuary/mitigation",
            "Avenger's Shield/control",
            "Redoubt/health",
            "Consecrated Ground/cleave",
            "Ardent Defender/regen",
            "Guardian of Kings/mitigation",
        },
        {
            "Crusade/damage",
            "Judgement of Light/leech",
            "Hammer of Wrath/execute",
            "Zeal/speed",
            "Conviction/damage",
            "Art of War/haste",
            "Selfless Healer/healing",
            "Avenging Wrath/damage",
        },
    },
    HUNTER = {
        {
            "Spirit Bond/regen",
            "Bestial Wrath/damage",
            "Frenzy/speed",
            "Beast Cleave/cleave",
            "Mend Companion/sustain",
            "Thick Hide/mitigation",
            "Predator's Thirst/leech",
            "Aspect of the Wild/health",
        },
        {
            "Careful Aim/damage",
            "Kill Shot/execute",
            "Rapid Fire/haste",
            "Trueshot/speed",
            "Concussive Shot/control",
            "Master Marksman/damage",
            "Camouflage/renew",
            "Steady Focus/damage",
        },
        {
            "Survivalist/health",
            "Explosive Trap/thorns",
            "Misdirection/guard",
            "Exhilaration/healing",
            "Wildfire/damage",
            "Harpoon/control",
            "Trailblazer/speed",
            "Wilderness Medicine/renew",
        },
    },
    ROGUE = {
        {
            "Deadly Poison/damage",
            "Venomous Wounds/leech",
            "Seal Fate/haste",
            "Cut to the Chase/speed",
            "Dispatch/execute",
            "Alchemical Recovery/sustain",
            "Master Poisoner/damage",
            "Leeching Poison/regen",
        },
        {
            "Blade Flurry/cleave",
            "Riposte/thorns",
            "Combat Potency/speed",
            "Adrenaline Rush/haste",
            "Combat Readiness/guard",
            "Iron Stomach/health",
            "Blade Master/damage",
            "Enduring Brawler/mitigation",
        },
        {
            "Shadowstep/control",
            "Premeditation/damage",
            "Recuperate/renew",
            "Elusiveness/mitigation",
            "Shadow Dance/execute",
            "Soothing Darkness/healing",
            "Master of Shadows/speed",
            "Cheat Death/health",
        },
    },
    PRIEST = {
        {
            "Atonement/leech",
            "Power Word Shield/guard",
            "Borrowed Time/haste",
            "Reflective Shield/thorns",
            "Grace/healing",
            "Pain Suppression/mitigation",
            "Evangelism/damage",
            "Power Infusion/speed",
        },
        {
            "Renew/renew",
            "Divine Hymn/sustain",
            "Holy Concentration/healing",
            "Surge of Light/speed",
            "Blessed Resilience/health",
            "Lightwell/regen",
            "Serendipity/haste",
            "Guardian Spirit/healing",
        },
        {
            "Mind Sear/cleave",
            "Shadow Word Death/execute",
            "Psychic Scream/control",
            "Darkness/damage",
            "Vampiric Embrace/leech",
            "Shadowform/mitigation",
            "Twist of Fate/damage",
            "Void Torrent/speed",
        },
    },
    SHAMAN = {
        {
            "Chain Lightning/cleave",
            "Elemental Fury/damage",
            "Lava Surge/haste",
            "Thunderstorm/control",
            "Elemental Warding/mitigation",
            "Aftershock/speed",
            "Stormkeeper/execute",
            "Ascendance/damage",
        },
        {
            "Stormstrike/damage",
            "Flametongue/leech",
            "Windfury/speed",
            "Lightning Shield/thorns",
            "Feral Spirit/guard",
            "Maelstrom Weapon/haste",
            "Shamanistic Rage/health",
            "Earthen Strength/mitigation",
        },
        {
            "Riptide/renew",
            "Tidal Waves/sustain",
            "Earthliving/healing",
            "Healing Stream/regen",
            "Nature's Swiftness/speed",
            "Ancestral Vigor/health",
            "Deep Healing/healing",
            "Spirit Link/mitigation",
        },
    },
    MAGE = {
        {
            "Arcane Power/damage",
            "Arcane Echo/cleave",
            "Presence of Mind/haste",
            "Nether Precision/execute",
            "Prismatic Barrier/guard",
            "Mana Shield/health",
            "Arcane Meditation/renew",
            "Temporal Mending/sustain",
        },
        {
            "Ignite/damage",
            "Hot Streak/speed",
            "Cauterize/regen",
            "Molten Armor/thorns",
            "Combustion/execute",
            "Flame On/haste",
            "Phoenix Warmth/healing",
            "Pyromaniac/damage",
        },
        {
            "Frostbite/control",
            "Ice Barrier/mitigation",
            "Shatter/damage",
            "Cold Snap/haste",
            "Ice Floes/speed",
            "Frost Channeling/leech",
            "Winter's Resilience/health",
            "Glacial Spike/damage",
        },
    },
    WARLOCK = {
        {
            "Drain Life/leech",
            "Soul Siphon/sustain",
            "Nightfall/haste",
            "Haunt/damage",
            "Drain Soul/execute",
            "Dark Regeneration/renew",
            "Siphon Life/regen",
            "Unstable Affliction/damage",
        },
        {
            "Soul Link/guard",
            "Demon Armor/mitigation",
            "Fel Vitality/health",
            "Demonic Reprisal/thorns",
            "Demonic Frenzy/speed",
            "Felstorm/cleave",
            "Health Funnel/healing",
            "Demonic Pact/damage",
        },
        {
            "Shadowfury/control",
            "Backdraft/speed",
            "Chaos Bolt/damage",
            "Shadowburn/execute",
            "Ember Tap/healing",
            "Fire and Brimstone/cleave",
            "Soul Leech/leech",
            "Infernal Power/damage",
        },
    },
    DRUID = {
        {
            "Starfall/cleave",
            "Eclipse/damage",
            "Nature's Grace/speed",
            "Typhoon/control",
            "Moonkin Form/mitigation",
            "Shooting Stars/haste",
            "Celestial Alignment/execute",
            "Astral Communion/renew",
        },
        {
            "Savage Roar/damage",
            "Predatory Strikes/leech",
            "Leader of the Pack/regen",
            "Thick Hide/guard",
            "Bristling Fur/thorns",
            "Heart of the Wild/health",
            "Tiger's Fury/speed",
            "Survival Instincts/mitigation",
        },
        {
            "Rejuvenation/renew",
            "Swiftmend/sustain",
            "Lifebloom/healing",
            "Living Seed/regen",
            "Gift of Nature/healing",
            "Nature's Swiftness/haste",
            "Ironbark/mitigation",
            "Tree of Life/health",
        },
    },
}
C.talentsByClass, C.talentByClassID, C.legacyTalentIDs = {}, {}, {}
for _, class in ipairs(C.classes) do
    local talents, byID, legacy = {}, {}, {}
    for path, entries in ipairs(C.talentSpecs[class.id]) do
        for position, entry in ipairs(entries) do
            local name, effect = entry:match("^(.-)/(.+)$")
            -- Repeated motifs add power rather than creating a second boolean unlock.
            if legacy[effect] then
                local upgrades = {
                    cleave = "damage",
                    execute = "damage",
                    haste = "speed",
                    sustain = "healing",
                    renew = "regen",
                    leech = "regen",
                    guard = "mitigation",
                    thorns = "mitigation",
                    control = "speed",
                }
                effect = upgrades[effect] or effect
            end
            local definition = C.talentEffects[effect]
            local id = class.id:lower() .. "_" .. path .. "_" .. position
            -- Effect IDs retain saved choices and existing combat integrations per class.
            if definition.value == true and not legacy[effect] then
                id = effect
            end
            local talent = {
                id = id,
                name = name,
                effect = effect,
                value = definition.value,
                text = definition.text,
                icon = C.talentEffectIcons[effect] or class.icon,
                path = path,
                row = math.floor((position - 1) / 2) + 1,
                column = (position - 1) % 2 + 2,
            }
            talents[#talents + 1], byID[id] = talent, talent
            if definition.value == true and not legacy[effect] then
                legacy[effect] = id
            end
        end
    end
    C.talentsByClass[class.id], C.talentByClassID[class.id], C.legacyTalentIDs[class.id] =
        talents, byID, legacy
end
-- Historical alias for Warrior content; consumers should use talentsByClass.
C.talents = C.talentsByClass.WARRIOR
C.priorityModes = { "heal", "special", "attack" }
C.priorityNames = { heal = "Recovery first", special = "Special first", attack = "Strike first" }
C.qualityNames = { "Common", "Uncommon", "Rare", "Epic" }
C.qualityColors =
    { { 0.75, 0.76, 0.77 }, { 0.34, 0.85, 0.48 }, { 0.36, 0.64, 1 }, { 0.76, 0.46, 1 } }
C.itemNames = { "Wayfarer's", "Pathfinder's", "Runeworn", "Dawnforged" }
C.version = 2
C.adventure = { xpPerRank = 100, essencePerRank = 60 }
C.activityOrder = { "kill", "gather", "skinning", "quest", "boss", "dungeon", "level" }
C.activityRewards = {
    kill = { xp = 1, name = "Eligible creature kill" },
    gather = { xp = 4, name = "Herb or ore node" },
    skinning = { xp = 0.25, name = "Skinning" },
    quest = { xp = 20, name = "Quest completed" },
    boss = { xp = 25, name = "Boss within your XP range" },
    dungeon = { xp = 40, name = "Confirmed dungeon completion bonus" },
    level = { xp = 5, name = "WoW character level gained" },
}
