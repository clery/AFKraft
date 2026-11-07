local _, W = ...
local L = W.L
local C = W.Content

-- Authored idle encounters; levels are simulation frontiers, not NPC levels.
-- Original entries remain first so saved encounters and model indices stay valid.
C.encounterAdditions = {
    elwynn = {
        { name = L.FOREST_SPIDER, appearance = "spider", level = 1 },
        { name = L.FARGODEEP_TUNNELER, appearance = "kobold", level = 1 },
        { name = L.STONECAIRN_REVENANT, appearance = "skeleton", level = 1 },
        { name = L.EASTVALE_PACKLEADER, appearance = "wolf", level = 20 },
        { name = L.GOLDTOOTH_S_ENFORCER, appearance = "gnoll", level = 40 },
        { name = L.NORTHSHIRE_FLAMECALLER, appearance = "fire", level = 60 },
    },
    durotar = {
        { name = L.SURF_CRAWLER, appearance = "crab", level = 1 },
        { name = L.ECHO_ISLES_HEXER, appearance = "troll", level = 1 },
        { name = L.THUNDER_RIDGE_ELEMENTAL, appearance = "storm", level = 1 },
        { name = L.SKULL_ROCK_INVOKER, appearance = "warlock", level = 20 },
        { name = L.TIRAGARDE_VETERAN, appearance = "bandit", level = 40 },
        { name = L.BURNING_BLADE_CHAMPION, appearance = "orc", level = 60 },
    },
    westfall = {
        { name = L.SHORE_CRAWLER, appearance = "crab", level = 1 },
        { name = L.MOONBROOK_LOOKOUT, appearance = "bandit", level = 1 },
        { name = L.DAGGER_HILLS_WOLF, appearance = "wolf", level = 1 },
        { name = L.DEAD_ACRE_REAPER, appearance = "harvester", level = 20 },
        { name = L.LONGSHORE_TIDECALLER, appearance = "storm", level = 40 },
        { name = L.DEFIAS_DEMOLITIONIST, appearance = "engineer", level = 60 },
    },
    barrens = {
        { name = L.THORN_HILL_BOAR, appearance = "boar", level = 1 },
        { name = L.OASIS_SNAPJAW, appearance = "crocolisk", level = 1 },
        { name = L.LUSHWATER_STORMCALLER, appearance = "storm", level = 1 },
        { name = L.FORGOTTEN_POOLS_STALKER, appearance = "cat", level = 20 },
        { name = L.RATCHET_SABOTEUR, appearance = "engineer", level = 40 },
        { name = L.RAZORFEN_EMISSARY, appearance = "quilboar", level = 60 },
    },
    redridge = {
        { name = L.LAKE_EVERSTILL_CRAWLER, appearance = "crab", level = 1 },
        { name = L.RENDERS_VALLEY_SPIDER, appearance = "spider", level = 1 },
        { name = L.STONEWATCH_WARLOCK, appearance = "warlock", level = 1 },
        { name = L.ALTHER_S_MILL_REAVER, appearance = "orc", level = 20 },
        { name = L.REDRIDGE_STORMWING, appearance = "whelp", level = 40 },
        { name = L.TOWER_OF_ILGALAR_SHADE, appearance = "wraith", level = 60 },
    },
    ashenvale = {
        { name = L.ZORAM_STRAND_CRAWLER, appearance = "crab", level = 1 },
        { name = L.SATYRNAAR_DECEIVER, appearance = "satyr", level = 1 },
        { name = L.FALLEN_SKY_FIREWALKER, appearance = "fire", level = 1 },
        { name = L.FELFIRE_HILL_SUMMONER, appearance = "warlock", level = 20 },
        { name = L.WARSONG_LUMBERGUARD, appearance = "orc", level = 40 },
        { name = L.BOUGH_SHADOW_DREAMSTALKER, appearance = "dragon", level = 60 },
    },
    duskwood = {
        { name = L.VENOMWEB_SPIDER, appearance = "spider", level = 1 },
        { name = L.RAVEN_HILL_GHOUL, appearance = "ghoul", level = 1 },
        { name = L.TWILIGHT_GROVE_WHELP, appearance = "whelp", level = 1 },
        { name = L.ROTTING_ORCHARD_TERROR, appearance = "abomination", level = 20 },
        { name = L.MANOR_MISTMANTLE_SHADE, appearance = "wraith", level = 40 },
        { name = L.DARKSHIRE_NIGHTSTALKER, appearance = "wolf", level = 60 },
    },
    wetlands = {
        { name = L.BLUEGILL_RAIDER, appearance = "murloc", level = 1 },
        { name = L.WHELGAR_S_RAPTOR, appearance = "raptor", level = 1 },
        { name = L.CRIMSON_FEN_WHELP, appearance = "whelp", level = 1 },
        { name = L.SUNDOWN_MARSH_REVENANT, appearance = "skeleton", level = 20 },
        { name = L.DUN_MODR_GRENADIER, appearance = "engineer", level = 40 },
        { name = L.GRIM_BATOL_OUTRIDER, appearance = "dragon", level = 60 },
    },
    stranglethorn = {
        { name = L.MOSH_OGG_BONECRUSHER, appearance = "ogre", level = 1 },
        { name = L.MISTY_VALE_GORILLA, appearance = "gorilla", level = 1 },
        { name = L.REEF_CRAWLER_2, appearance = "crab", level = 1 },
        { name = L.ZUL_MAMWE_SHADOWHUNTER, appearance = "troll", level = 20 },
        { name = L.CRYSTALVEIN_BASILISK, appearance = "basilisk", level = 40 },
        { name = L.GURUBASHI_SPIRITBINDER, appearance = "wraith", level = 60 },
    },
    desolace = {
        { name = L.KODO_GRAVEYARD_REVENANT, appearance = "skeleton", level = 1 },
        { name = L.SHADOWPREY_CRAWLER, appearance = "crab", level = 1 },
        { name = L.MANNOROC_FELSTALKER, appearance = "felhound", level = 1 },
        { name = L.VALLEY_OF_SPEARS_WARLORD, appearance = "centaur", level = 20 },
        { name = L.THUNDER_AXE_SUMMONER, appearance = "warlock", level = 40 },
        { name = L.GELKIS_EARTHSHAPER, appearance = "earth", level = 60 },
    },
    tanaris = {
        { name = L.DUNEMAUL_HYENA, appearance = "hyena", level = 1 },
        { name = L.NOXIOUS_SAND_ELEMENTAL, appearance = "earth", level = 1 },
        { name = L.SOUTHSEA_GUNNER, appearance = "bandit", level = 1 },
        { name = L.CAVERNS_BRONZE_GUARDIAN, appearance = "dragon", level = 20 },
        { name = L.THISTLESHRUB_ROOTWALKER, appearance = "treant", level = 40 },
        { name = L.ABYSSAL_SANDS_DUNEHUNTER, appearance = "silithid", level = 60 },
    },
    winterspring = {
        { name = L.ICECAP_ELEMENTAL, appearance = "ice", level = 1 },
        { name = L.WINTERSABER_HUNTRESS, appearance = "cat", level = 1 },
        { name = L.FROSTWHISPER_SPIRIT, appearance = "wraith", level = 1 },
        { name = L.DARKWHISPER_FELHOUND, appearance = "felhound", level = 20 },
        { name = L.OWL_WING_SENTINEL, appearance = "owl", level = 40 },
        { name = L.MAZTHORIL_WYRMGUARD, appearance = "dragon", level = 60 },
    },
    dun_morogh = {
        { name = L.ICEFANG_WOLF, appearance = "wolf", level = 1 },
        { name = L.SHIMMER_RIDGE_TROLL, appearance = "troll", level = 1 },
        { name = L.GNOMEREGAN_SALVAGEBOT, appearance = "harvester", level = 1 },
        { name = L.FROSTMANE_ICECALLER, appearance = "ice", level = 20 },
        { name = L.GOL_BOLAR_EARTHSHAPER, appearance = "earth", level = 40 },
        { name = L.COLD_VALLEY_BROODMOTHER, appearance = "spider", level = 60 },
    },
    teldrassil = {
        { name = L.WEBWOOD_LURKER, appearance = "spider", level = 1 },
        { name = L.GNARLPINE_MYSTIC, appearance = "furbolg", level = 1 },
        { name = L.WELLSPRING_ELEMENTAL, appearance = "storm", level = 1 },
        { name = L.BAN_ETHIL_SPIRITKEEPER, appearance = "wraith", level = 20 },
        { name = L.STARBREEZE_NIGHTSTALKER, appearance = "cat", level = 40 },
        { name = L.ORACLE_GLADE_ROOTWARDEN, appearance = "treant", level = 60 },
    },
    mulgore = {
        { name = L.VENTURE_CO_TINKERER, appearance = "engineer", level = 1 },
        { name = L.BRAMBLEBLADE_QUILBOAR, appearance = "quilboar", level = 1 },
        { name = L.THUNDERHORN_ELEMENTAL, appearance = "storm", level = 1 },
        { name = L.RED_ROCKS_EARTHSHAKER, appearance = "earth", level = 20 },
        { name = L.WINDFURY_MATRIARCH, appearance = "harpy", level = 40 },
        { name = L.PALEMANE_PACKLEADER, appearance = "wolf", level = 60 },
    },
    tirisfal = {
        { name = L.VENOMTAIL_SPIDER, appearance = "spider", level = 1 },
        { name = L.AGAMAND_GHOUL, appearance = "ghoul", level = 1 },
        { name = L.SCARLET_WATCHMAN, appearance = "bandit", level = 1 },
        { name = L.SOLLIDEN_REVENANT, appearance = "skeleton", level = 20 },
        { name = L.BALNIR_PLAGUEHOUND, appearance = "felhound", level = 40 },
        { name = L.WHISPERING_SHORE_BANSHEE, appearance = "wraith", level = 60 },
    },
    loch_modan = {
        { name = L.STONESPLINTER_GEOMANCER, appearance = "earth", level = 1 },
        { name = L.LOCH_CROCOLISK, appearance = "crocolisk", level = 1 },
        { name = L.MO_GROSH_BRUTE, appearance = "ogre", level = 1 },
        { name = L.SILVER_STREAM_BURROWER, appearance = "kobold", level = 20 },
        { name = L.IRONBAND_STONEWARDEN, appearance = "earth", level = 40 },
        { name = L.STONEWROUGHT_DEMOLISHER, appearance = "harvester", level = 60 },
    },
    darkshore = {
        { name = L.GREYMIST_TIDEHUNTER, appearance = "murloc", level = 1 },
        { name = L.CLIFFSPRING_BEAR, appearance = "bear", level = 1 },
        { name = L.BASHAL_ARAN_SATYR, appearance = "satyr", level = 1 },
        { name = L.AMETH_ARAN_HAUNTING, appearance = "wraith", level = 20 },
        { name = L.TWILIGHT_SHORE_SNAPPER, appearance = "crab", level = 40 },
        { name = L.MASTER_S_GLAIVE_VOIDCALLER, appearance = "warlock", level = 60 },
    },
    silverpine = {
        { name = L.SKITTERING_DARK_SPIDER, appearance = "spider", level = 1 },
        { name = L.FENRIS_ROTGUARD, appearance = "ghoul", level = 1 },
        { name = L.AMBERMILL_SUMMONER, appearance = "warlock", level = 1 },
        { name = L.DEEP_ELEM_WATER_SPIRIT, appearance = "storm", level = 20 },
        { name = L.PYREWOOD_STALKER, appearance = "wolf", level = 40 },
        { name = L.SEPULCHER_DEATHWATCH, appearance = "wraith", level = 60 },
    },
    stonetalon = {
        { name = L.WINDSHEAR_SHREDDER, appearance = "harvester", level = 1 },
        { name = L.CHARRED_VALE_HARPY, appearance = "harpy", level = 1 },
        { name = L.BOULDERSLIDE_SHAMAN, appearance = "earth", level = 1 },
        { name = L.SISHIR_BROODMOTHER, appearance = "spider", level = 20 },
        { name = L.SUN_ROCK_RAVAGER, appearance = "wyvern", level = 40 },
        { name = L.STONETALON_CORRUPTED_KEEPER, appearance = "treant", level = 60 },
    },
    hillsbrad = {
        { name = L.DUN_GAROK_RIFLEMAN, appearance = "dwarf", level = 1 },
        { name = L.DALARAN_CONJURER, appearance = "warlock", level = 1 },
        { name = L.EASTERN_STRAND_CRAWLER, appearance = "crab", level = 1 },
        { name = L.AZURELODE_EARTHBREAKER, appearance = "earth", level = 20 },
        { name = L.DURNHOLDE_WARDEN, appearance = "orc", level = 40 },
        { name = L.SOUTHPOINT_PLAGUEBEARER, appearance = "ghoul", level = 60 },
    },
    thousand_needles = {
        { name = L.SALT_FLATS_BASILISK, appearance = "basilisk", level = 1 },
        { name = L.HIGHPERCH_WYVERN, appearance = "wyvern", level = 1 },
        { name = L.DARKCLOUD_SHAMAN, appearance = "storm", level = 1 },
        { name = L.ROGUEFEATHER_WINDCALLER, appearance = "harpy", level = 20 },
        { name = L.SPLITHOOF_WARLEADER, appearance = "centaur", level = 40 },
        { name = L.MIRAGE_RACEWAY_SABOTEUR, appearance = "engineer", level = 60 },
    },
    alterac = {
        { name = L.CRUSHRIDGE_OGRE, appearance = "ogre", level = 1 },
        { name = L.MOUNTAIN_LION, appearance = "cat", level = 1 },
        { name = L.DALARAN_WARDER, appearance = "warlock", level = 1 },
        { name = L.GALLOWS_CORNER_HAUNTING, appearance = "wraith", level = 20 },
        { name = L.CHILLWIND_MATRIARCH, appearance = "wyvern", level = 40 },
        { name = L.STRAHNBRAD_FROSTBINDER, appearance = "ice", level = 60 },
    },
    arathi = {
        { name = L.FALDIR_S_COVE_TIDEHUNTER, appearance = "crab", level = 1 },
        { name = L.BURNING_EXILE, appearance = "fire", level = 1 },
        { name = L.CRESTING_EXILE, appearance = "storm", level = 1 },
        { name = L.THUNDERING_EXILE, appearance = "earth", level = 20 },
        { name = L.STROMGARDE_REVENANT, appearance = "skeleton", level = 40 },
        { name = L.BOULDERFIST_HIGH_SHAMAN, appearance = "ogre", level = 60 },
    },
    badlands = {
        { name = L.ROCK_ELEMENTAL, appearance = "earth", level = 1 },
        { name = L.DUSTBELCHER_MYSTIC, appearance = "ogre", level = 1 },
        { name = L.SCALDING_WHELP_2, appearance = "whelp", level = 1 },
        { name = L.AGMOND_S_END_STALKER, appearance = "basilisk", level = 20 },
        { name = L.ULDAMAN_STONEKEEPER, appearance = "earth", level = 40 },
        { name = L.LETHLOR_BROODGUARDIAN, appearance = "dragon", level = 60 },
    },
    swamp_sorrows = {
        { name = L.MISTY_REED_CRAWLER, appearance = "crab", level = 1 },
        { name = L.STONARD_OUTRIDER, appearance = "orc", level = 1 },
        { name = L.LOST_ONE_SEER, appearance = "lostone", level = 1 },
        { name = L.ITHARIUS_DREAMGUARD, appearance = "dragon", level = 20 },
        { name = L.FALLOW_SANCTUARY_HAUNTING, appearance = "wraith", level = 40 },
        { name = L.SORROWMURK_HYDRA, appearance = "hydra", level = 60 },
    },
    dustwallow = {
        { name = L.DARKMIST_SPIDER, appearance = "spider", level = 1 },
        { name = L.DREADMURK_CROCOLISK, appearance = "crocolisk", level = 1 },
        { name = L.BLACKHOOF_RAIDER, appearance = "tauren", level = 1 },
        { name = L.WITCH_HILL_SPIRIT, appearance = "wraith", level = 20 },
        { name = L.DRAGONMURK_FLAMEGUARD, appearance = "dragon", level = 40 },
        { name = L.ALCAZ_TIDEBREAKER, appearance = "ogre", level = 60 },
    },
    feralas = {
        { name = L.RAGE_SCAR_YETI_2, appearance = "yeti", level = 1 },
        { name = L.WOODPAW_MYSTIC, appearance = "furbolg", level = 1 },
        { name = L.GRIMTOTEM_RAIDER, appearance = "tauren", level = 1 },
        { name = L.FRAYFEATHER_MATRIARCH, appearance = "owl", level = 20 },
        { name = L.RUINS_OF_RAVENWIND_SPIRIT, appearance = "wraith", level = 40 },
        { name = L.DREAM_BOUGH_ANCIENT, appearance = "treant", level = 60 },
    },
    hinterlands = {
        { name = L.SKULK_ROCK_SLIME, appearance = "ooze", level = 1 },
        { name = L.JINTHA_ALOR_ZEALOT, appearance = "troll", level = 1 },
        { name = L.QUEL_DANIL_GUARDIAN, appearance = "treant", level = 1 },
        { name = L.SERADANE_DREAMSCALE, appearance = "dragon", level = 20 },
        { name = L.AGOL_WATHA_SHADOWCASTER, appearance = "warlock", level = 40 },
        { name = L.SHAOL_WATHA_SPIRITCALLER, appearance = "wraith", level = 60 },
    },
    azshara = {
        { name = L.HALDARR_TRICKSTER, appearance = "satyr", level = 1 },
        { name = L.BAY_OF_STORMS_ELEMENTAL, appearance = "storm", level = 1 },
        { name = L.LEGASHI_FELHOUND, appearance = "felhound", level = 1 },
        { name = L.BITTER_REACHES_GUARDIAN, appearance = "treant", level = 20 },
        { name = L.RUINS_OF_ELDARATH_SORCERER, appearance = "warlock", level = 40 },
        { name = L.LAKE_MENNAR_APPARITION, appearance = "wraith", level = 60 },
    },
    searing_gorge = {
        { name = L.GREATER_LAVA_SPIDER, appearance = "spider", level = 1 },
        { name = L.CAULDRON_FIREGUARD, appearance = "fire", level = 1 },
        { name = L.DARK_IRON_TASKMASTER, appearance = "darkiron", level = 1 },
        { name = L.FIREWATCH_WAR_GOLEM, appearance = "harvester", level = 20 },
        { name = L.DUSTFIRE_EARTHSHAKER, appearance = "earth", level = 40 },
        { name = L.SLAG_PIT_FLAMEBINDER, appearance = "warlock", level = 60 },
    },
    blasted_lands = {
        { name = L.DREADMAUL_OGRE, appearance = "ogre", level = 1 },
        { name = L.RED_REACHES_FELHOUND, appearance = "felhound", level = 1 },
        { name = L.NETHERGARDE_DESERTER, appearance = "bandit", level = 1 },
        { name = L.TAINTED_SCAR_STALKER, appearance = "satyr", level = 20 },
        { name = L.DARK_PORTAL_DOOMCALLER, appearance = "warlock", level = 40 },
        { name = L.RISE_OF_THE_DEFILER_TERROR, appearance = "abomination", level = 60 },
    },
    felwood = {
        { name = L.JADEFIRE_SATYR, appearance = "satyr", level = 1 },
        { name = L.DEADWOOD_PATHFINDER, appearance = "furbolg", level = 1 },
        { name = L.IRONTREE_ANCIENT, appearance = "treant", level = 1 },
        { name = L.SHATTER_SCAR_INFERNO, appearance = "fire", level = 20 },
        { name = L.JAEDENAR_FELHOUND, appearance = "felhound", level = 40 },
        { name = L.SHADOW_HOLD_TORMENTOR, appearance = "warlock", level = 60 },
    },
    ungoro = {
        { name = L.TAR_PIT_OOZE, appearance = "ooze", level = 1 },
        { name = L.LAKKARI_RAVASAUR, appearance = "raptor", level = 1 },
        { name = L.FIRE_PLUME_ELEMENTAL, appearance = "fire", level = 1 },
        { name = L.FUNGAL_ROCK_GORILLA, appearance = "gorilla", level = 20 },
        { name = L.TERROR_RUN_MATRIARCH, appearance = "trex", level = 40 },
        { name = L.SLITHERING_SCAR_BURROWER, appearance = "silithid", level = 60 },
    },
    burning_steppes = {
        { name = L.FLAMESCALE_HATCHLING, appearance = "whelp", level = 1 },
        { name = L.DREADMAUL_CRUSHER, appearance = "ogre", level = 1 },
        { name = L.FLAME_CREST_LAVAWALKER, appearance = "fire", level = 1 },
        { name = L.RUINS_OF_THAURISSAN_CONSTRUCT, appearance = "harvester", level = 20 },
        { name = L.DREADMAUL_ROCK_WARLORD, appearance = "orc", level = 40 },
        { name = L.BLACKROCK_BROODMARSHAL, appearance = "dragon", level = 60 },
    },
    western_plaguelands = {
        { name = L.FELSTONE_GHOUL, appearance = "ghoul", level = 1 },
        { name = L.DALSON_S_HAUNTING, appearance = "wraith", level = 1 },
        { name = L.NORTHRIDGE_SPIDER, appearance = "spider", level = 1 },
        { name = L.HEARTHGLEN_ZEALOT, appearance = "bandit", level = 20 },
        { name = L.SORROW_HILL_STITCHGUARD, appearance = "abomination", level = 40 },
        { name = L.CAER_DARROW_DEATHWARDEN, appearance = "skeleton", level = 60 },
    },
    deadwind = {
        { name = L.ARIDEN_S_HAUNTING, appearance = "wraith", level = 1 },
        { name = L.SLEEPING_GORGE_SPIDER, appearance = "spider", level = 1 },
        { name = L.DEADMAN_S_CROSSING_SKELETON, appearance = "skeleton", level = 1 },
        { name = L.VICE_DUSKWING, appearance = "owl", level = 20 },
        { name = L.KARAZHAN_GROUNDSKEEPER, appearance = "abomination", level = 40 },
        { name = L.MASTER_S_CELLAR_CONJURER, appearance = "warlock", level = 60 },
    },
    eastern_plaguelands = {
        { name = L.PLAGUEWOOD_SPIDER, appearance = "spider", level = 1 },
        { name = L.CORIN_S_CROSSING_GHOUL, appearance = "ghoul", level = 1 },
        { name = L.TYR_S_HAND_FANATIC, appearance = "bandit", level = 1 },
        { name = L.DARROWSHIRE_SPIRIT, appearance = "wraith", level = 20 },
        { name = L.NOXIOUS_GLADE_PLAGUEWALKER, appearance = "abomination", level = 40 },
        { name = L.STRATHOLME_DREADGUARD, appearance = "skeleton", level = 60 },
    },
    silithus = {
        { name = L.TWILIGHT_GEOLORD, appearance = "warlock", level = 1 },
        { name = L.DUST_STORMER, appearance = "storm", level = 1 },
        { name = L.STONELASH_SANDSTALKER, appearance = "basilisk", level = 1 },
        { name = L.HIVE_ZORA_TUNNELER, appearance = "silithid", level = 20 },
        { name = L.HIVE_REGAL_COLOSSUS, appearance = "silithid", level = 40 },
        { name = L.SCARAB_WALL_GUARDIAN, appearance = "earth", level = 60 },
    },
    moonglade = {
        { name = L.NIGHTMARE_WEBSPINNER, appearance = "spider", level = 1 },
        { name = L.DREAM_CORRUPTED_PROWLER, appearance = "cat", level = 1 },
        { name = L.FRENZIED_GROVEWARDEN, appearance = "treant", level = 1 },
        { name = L.BARROW_SPIRIT, appearance = "wraith", level = 20 },
        { name = L.STORMRAGE_NIGHTMARE, appearance = "dragon", level = 40 },
        { name = L.OMEN_S_DREAMSHADE, appearance = "felhound", level = 60 },
    },
    blackrock_mountain = {
        { name = L.MOLTEN_STONEGUARD, appearance = "earth", level = 1 },
        { name = L.SPIRE_BROODLING, appearance = "whelp", level = 1 },
        { name = L.DARK_IRON_SABOTEUR, appearance = "darkiron", level = 1 },
        { name = L.BLACKHAND_DREADWEAVER, appearance = "warlock", level = 20 },
        { name = L.CORE_FLAMEWALKER, appearance = "fire", level = 40 },
        { name = L.SPIRE_DRAGONMARSHAL, appearance = "dragon", level = 60 },
    },
}

C.creatureFamilies = {
    spider = "beast",
    kobold = "humanoid",
    skeleton = "undead",
    wolf = "beast",
    gnoll = "humanoid",
    fire = "elemental",
    crab = "beast",
    troll = "humanoid",
    storm = "elemental",
    warlock = "humanoid",
    bandit = "humanoid",
    orc = "humanoid",
    harvester = "mechanical",
    engineer = "humanoid",
    cat = "beast",
    quilboar = "humanoid",
    whelp = "dragonkin",
    wraith = "undead",
    satyr = "demon",
    dragon = "dragonkin",
    ghoul = "undead",
    abomination = "undead",
    raptor = "beast",
    ogre = "humanoid",
    gorilla = "beast",
    basilisk = "beast",
    felhound = "demon",
    centaur = "humanoid",
    earth = "elemental",
    hyena = "beast",
    treant = "elemental",
    silithid = "unknown",
    ice = "elemental",
    owl = "beast",
    furbolg = "humanoid",
    bear = "beast",
    crocolisk = "beast",
    wyvern = "beast",
    yeti = "humanoid",
    ooze = "unknown",
    trex = "beast",
    boar = "beast",
    murloc = "humanoid",
    harpy = "humanoid",
    hydra = "unknown",
    lostone = "humanoid",
    darkiron = "humanoid",
    tauren = "humanoid",
    dwarf = "humanoid",
}

for zoneID, entries in pairs(C.encounterAdditions) do
    local zone = C.zoneByID[zoneID]
    zone.enemyLevels = {}
    for index in ipairs(zone.enemies) do
        zone.enemyLevels[index] = 1
    end
    for _, entry in ipairs(entries) do
        zone.enemies[#zone.enemies + 1] = entry.name
        zone.enemyFamilies[#zone.enemyFamilies + 1] = C.creatureFamilies[entry.appearance]
        zone.enemyLevels[#zone.enemyLevels + 1] = entry.level
    end
end

local finalZone = C.zoneByID.blackrock_mountain
local finalRoster = C.encounterAdditions[finalZone.id]
local finalChampion = finalRoster[#finalRoster]
C.transcendenceBoss = {
    zone = finalZone.id,
    name = finalChampion.name,
    level = finalChampion.level,
    stage = math.ceil(((finalChampion.level - finalZone.level) * 5 + 1) / 10) * 10,
}

-- Finish on the boss that opens the next stronger destination tier.
for _, zone in ipairs(C.zones) do
    local finalLevel = C.transcendenceBoss.level
    for _, destination in ipairs(C.zones) do
        if destination.level > zone.level then
            finalLevel = math.min(finalLevel, destination.unlockLevel - 1)
        end
    end
    zone.maxStage = (finalLevel - zone.level + 1) * 5
    if finalLevel == C.transcendenceBoss.level then
        zone.maxStage = math.ceil(zone.maxStage / 10) * 10
    end
end
