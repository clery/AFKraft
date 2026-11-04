local _, W = ...
local L = W.L
local S = {}
W.CollectionSources = S

-- Stable metadata remains available when a client profile is disabled.
-- Retail candidates remain disabled; Forever mappings use its published item drop tables.
S.profiles = {
    retail120105 = {
        id = "retail120105",
        flavor = "retail",
        interface = 120105,
        enabled = false,
        verified = false,
        chance = 5,
        sources = {
            [4701] = {
                npcID = 423,
                name = L.REDRIDGE_MONGREL,
                familyName = L.GNOLLS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = false,
            },
            [2985] = {
                npcID = 423,
                name = L.REDRIDGE_MONGREL,
                familyName = L.GNOLLS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = false,
            },
            [2986] = {
                npcID = 4464,
                name = L.BLACKROCK_GLADIATOR,
                familyName = L.BLACKROCK_ORCS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = false,
            },
            [2987] = {
                npcID = 4464,
                name = L.BLACKROCK_GLADIATOR,
                familyName = L.BLACKROCK_ORCS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = false,
            },
            [2988] = {
                npcID = 4464,
                name = L.BLACKROCK_GLADIATOR,
                familyName = L.BLACKROCK_ORCS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = false,
            },
        },
    },
    forever16001 = {
        id = "forever16001",
        flavor = "forever",
        interface = 16001,
        enabled = true,
        verified = true,
        chance = 5,
        sources = {
            [4701] = {
                npcID = 423,
                name = L.REDRIDGE_MONGREL,
                familyName = L.GNOLLS,
                zone = L.REDRIDGE_MOUNTAINS,
                verified = true,
            },
            [2985] = {
                npcID = 1183,
                name = L.MO_GROSH_MYSTIC,
                familyName = L.OGRES,
                zone = L.LOCH_MODAN,
                verified = true,
            },
            [2986] = {
                npcID = 1183,
                name = L.MO_GROSH_MYSTIC,
                familyName = L.OGRES,
                zone = L.LOCH_MODAN,
                verified = true,
            },
            [2987] = {
                npcID = 1183,
                name = L.MO_GROSH_MYSTIC,
                familyName = L.OGRES,
                zone = L.LOCH_MODAN,
                verified = true,
            },
            [2988] = {
                npcID = 1183,
                name = L.MO_GROSH_MYSTIC,
                familyName = L.OGRES,
                zone = L.LOCH_MODAN,
                verified = true,
            },
        },
    },
}

S.profiles.foreverDungeon16001 = {
    id = "foreverDungeon16001",
    kind = "dungeon",
    flavor = "forever",
    interface = 16001,
    enabled = true,
    verified = true,
    chance = 20,
    sources = {
        [10399] = {
            npcID = 639,
            name = L.EDWIN_VANCLEEF,
            familyName = L.HUMANS,
            zone = L.THE_DEADMINES,
            verified = true,
        },
        [10400] = {
            npcID = 634,
            name = L.DEFIAS_OVERSEER,
            familyName = L.HUMANS,
            zone = L.THE_DEADMINES,
            verified = true,
        },
        [10401] = {
            npcID = 634,
            name = L.DEFIAS_OVERSEER,
            familyName = L.HUMANS,
            zone = L.THE_DEADMINES,
            verified = true,
        },
        [10402] = {
            npcID = 4416,
            name = L.DEFIAS_STRIP_MINER,
            familyName = L.HUMANS,
            zone = L.THE_DEADMINES,
            verified = true,
        },
        [10403] = {
            npcID = 647,
            name = L.CAPTAIN_GREENSKIN,
            familyName = L.GOBLINS,
            zone = L.THE_DEADMINES,
            verified = true,
        },
    },
}

S.profiles.forever16001.sources[3288] = {
    npcID = 12320,
    name = L.BURNING_BLADE_CRUSHER,
    familyName = L.BURNING_BLADE_CRUSHER,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[3287] = {
    npcID = 2039,
    name = L.URSAL_THE_MAULER,
    familyName = L.URSAL_THE_MAULER,
    zone = L.TELDRASSIL,
    verified = true,
}
S.profiles.forever16001.sources[3284] = {
    npcID = 2014,
    name = L.GNARLPINE_TOTEMIC,
    familyName = L.GNARLPINE_TOTEMIC,
    zone = L.TELDRASSIL,
    verified = true,
}
S.profiles.forever16001.sources[3286] = {
    npcID = 5786,
    name = L.SNAGGLESPEAR,
    familyName = L.SNAGGLESPEAR,
    zone = L.MULGORE,
    verified = true,
}
S.profiles.forever16001.sources[4674] = {
    npcID = 3197,
    name = L.BURNING_BLADE_FANATIC,
    familyName = L.BURNING_BLADE_FANATIC,
    zone = L.DUROTAR,
    verified = true,
}
S.profiles.forever16001.sources[14167] = {
    npcID = 125,
    name = L.RIVERPAW_OVERSEER,
    familyName = L.RIVERPAW_OVERSEER,
    zone = L.WESTFALL,
    verified = true,
}
S.profiles.forever16001.sources[14173] = {
    npcID = 1180,
    name = L.MO_GROSH_BRUTE_2,
    familyName = L.MO_GROSH_BRUTE_2,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[14174] = {
    npcID = 1180,
    name = L.MO_GROSH_BRUTE_2,
    familyName = L.MO_GROSH_BRUTE_2,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[14166] = {
    npcID = 1179,
    name = L.MO_GROSH_ENFORCER,
    familyName = L.MO_GROSH_ENFORCER,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[14168] = {
    npcID = 4064,
    name = L.BLACKROCK_SCOUT,
    familyName = L.BLACKROCK_SCOUT,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[9775] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9777] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9780] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9776] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9781] = {
    npcID = 5932,
    name = L.TASKMASTER_WHIPFANG,
    familyName = L.TASKMASTER_WHIPFANG,
    zone = L.STONETALON_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[3211] = {
    npcID = 2106,
    name = L.APOTHECARY_BERARD,
    familyName = L.APOTHECARY_BERARD,
    zone = L.SILVERPINE_FOREST,
    verified = true,
}
S.profiles.forever16001.sources[2992] = {
    npcID = 271898,
    name = L.GREATER_TARANTULA,
    familyName = L.GREATER_TARANTULA,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[2991] = {
    npcID = 4065,
    name = L.BLACKROCK_SENTRY,
    familyName = L.BLACKROCK_SENTRY,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[4697] = {
    npcID = 4064,
    name = L.BLACKROCK_SCOUT,
    familyName = L.BLACKROCK_SCOUT,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[2989] = {
    npcID = 4065,
    name = L.BLACKROCK_SENTRY,
    familyName = L.BLACKROCK_SENTRY,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[9784] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9787] = {
    npcID = 5835,
    name = L.FOREMAN_GRILLS,
    familyName = L.FOREMAN_GRILLS,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[9789] = {
    npcID = 5830,
    name = L.SISTER_RATHTALON,
    familyName = L.SISTER_RATHTALON,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[9783] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[9788] = {
    npcID = 2186,
    name = L.CARNIVOUS_THE_BREAKER,
    familyName = L.CARNIVOUS_THE_BREAKER,
    zone = L.DARKSHORE,
    verified = true,
}
S.profiles.forever16001.sources[2982] = {
    npcID = 1180,
    name = L.MO_GROSH_BRUTE_2,
    familyName = L.MO_GROSH_BRUTE_2,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[2984] = {
    npcID = 1181,
    name = L.MO_GROSH_SHAMAN,
    familyName = L.MO_GROSH_SHAMAN,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[4699] = {
    npcID = 1179,
    name = L.MO_GROSH_ENFORCER,
    familyName = L.MO_GROSH_ENFORCER,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[2981] = {
    npcID = 4064,
    name = L.BLACKROCK_SCOUT,
    familyName = L.BLACKROCK_SCOUT,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[4698] = {
    npcID = 1039,
    name = L.FEN_DWELLER,
    familyName = L.FEN_DWELLER,
    zone = L.WETLANDS,
    verified = true,
}
S.profiles.forever16001.sources[6563] = {
    npcID = 14269,
    name = L.SEEKER_AQUALON,
    familyName = L.SEEKER_AQUALON,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[6570] = {
    npcID = 5932,
    name = L.TASKMASTER_WHIPFANG,
    familyName = L.TASKMASTER_WHIPFANG,
    zone = L.STONETALON_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[6565] = {
    npcID = 5932,
    name = L.TASKMASTER_WHIPFANG,
    familyName = L.TASKMASTER_WHIPFANG,
    zone = L.STONETALON_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[6562] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[6564] = {
    npcID = 5831,
    name = L.SWIFTMANE,
    familyName = L.SWIFTMANE,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[6575] = {
    npcID = 14269,
    name = L.SEEKER_AQUALON,
    familyName = L.SEEKER_AQUALON,
    zone = L.REDRIDGE_MOUNTAINS,
    verified = true,
}
S.profiles.forever16001.sources[6574] = {
    npcID = 3735,
    name = L.APOTHECARY_FALTHIS,
    familyName = L.APOTHECARY_FALTHIS,
    zone = L.ASHENVALE,
    verified = true,
}
S.profiles.forever16001.sources[6576] = {
    npcID = 3735,
    name = L.APOTHECARY_FALTHIS,
    familyName = L.APOTHECARY_FALTHIS,
    zone = L.ASHENVALE,
    verified = true,
}
S.profiles.forever16001.sources[6578] = {
    npcID = 1183,
    name = L.MO_GROSH_MYSTIC,
    familyName = L.MO_GROSH_MYSTIC,
    zone = L.LOCH_MODAN,
    verified = true,
}
S.profiles.forever16001.sources[6573] = {
    npcID = 14425,
    name = L.GNAWBONE,
    familyName = L.GNAWBONE,
    zone = L.WETLANDS,
    verified = true,
}
S.profiles.forever16001.sources[285331] = {
    npcID = 5828,
    name = L.HUMAR_THE_PRIDELORD,
    familyName = L.HUMAR_THE_PRIDELORD,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[285330] = {
    npcID = 5831,
    name = L.SWIFTMANE,
    familyName = L.SWIFTMANE,
    zone = L.THE_BARRENS,
    verified = true,
}
S.profiles.forever16001.sources[285329] = {
    npcID = 5842,
    name = L.TAKK_THE_LEAPER,
    familyName = L.TAKK_THE_LEAPER,
    zone = L.THE_BARRENS,
    verified = true,
}

S.profiles.foreverDungeon16001.sources[271097] = {
    npcID = 261306,
    name = L.FALDRIM_ANVILMAR,
    familyName = L.FALDRIM_ANVILMAR,
    zone = L.THE_HALL_OF_THANES,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271096] = {
    npcID = 261306,
    name = L.FALDRIM_ANVILMAR,
    familyName = L.FALDRIM_ANVILMAR,
    zone = L.THE_HALL_OF_THANES,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270230] = {
    npcID = 261316,
    name = L.MAGMATUS,
    familyName = L.MAGMATUS,
    zone = L.THE_HALL_OF_THANES,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270231] = {
    npcID = 261316,
    name = L.MAGMATUS,
    familyName = L.MAGMATUS,
    zone = L.THE_HALL_OF_THANES,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271098] = {
    npcID = 261311,
    name = L.PLUNDER,
    familyName = L.PLUNDER,
    zone = L.THE_HALL_OF_THANES,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10412] = {
    npcID = 3671,
    name = L.LADY_ANACONDRA,
    familyName = L.LADY_ANACONDRA,
    zone = L.WAILING_CAVERNS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10411] = {
    npcID = 3673,
    name = L.LORD_SERPENTIS,
    familyName = L.LORD_SERPENTIS,
    zone = L.WAILING_CAVERNS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10413] = {
    npcID = 3840,
    name = L.DRUID_OF_THE_FANG,
    familyName = L.DRUID_OF_THE_FANG,
    zone = L.WAILING_CAVERNS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10410] = {
    npcID = 3669,
    name = L.LORD_COBRAHN,
    familyName = L.LORD_COBRAHN,
    zone = L.WAILING_CAVERNS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6473] = {
    npcID = 3670,
    name = L.LORD_PYTHAS,
    familyName = L.LORD_PYTHAS,
    zone = L.WAILING_CAVERNS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286978] = {
    npcID = 255109,
    name = L.FLESH_GOLEM,
    familyName = L.FLESH_GOLEM,
    zone = L.RUINS_OF_LORDAERON,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286980] = {
    npcID = 250620,
    name = L.SHRIEKING_BANSHEE,
    familyName = L.SHRIEKING_BANSHEE,
    zone = L.RUINS_OF_LORDAERON,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271207] = {
    npcID = 250631,
    name = L.THE_ABANDONED,
    familyName = L.THE_ABANDONED,
    zone = L.RUINS_OF_LORDAERON,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271214] = {
    npcID = 250657,
    name = L.RATH_MAEL,
    familyName = L.RATH_MAEL,
    zone = L.RUINS_OF_LORDAERON,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286979] = {
    npcID = 250629,
    name = L.STONE_WATCHER,
    familyName = L.STONE_WATCHER,
    zone = L.RUINS_OF_LORDAERON,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[5254] = {
    npcID = 3914,
    name = L.RETHILGORE,
    familyName = L.RETHILGORE,
    zone = L.SHADOWFANG_KEEP,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6319] = {
    npcID = 4279,
    name = L.ODO_THE_BLINDWATCHER,
    familyName = L.ODO_THE_BLINDWATCHER,
    zone = L.SHADOWFANG_KEEP,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6340] = {
    npcID = 4274,
    name = L.FENRUS_THE_DEVOURER,
    familyName = L.FENRUS_THE_DEVOURER,
    zone = L.SHADOWFANG_KEEP,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[3230] = {
    npcID = 4274,
    name = L.FENRUS_THE_DEVOURER,
    familyName = L.FENRUS_THE_DEVOURER,
    zone = L.SHADOWFANG_KEEP,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6324] = {
    npcID = 4275,
    name = L.ARCHMAGE_ARUGAL,
    familyName = L.ARCHMAGE_ARUGAL,
    zone = L.SHADOWFANG_KEEP,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6907] = {
    npcID = 4887,
    name = L.GHAMOO_RA,
    familyName = L.GHAMOO_RA,
    zone = L.BLACKFATHOM_DEEPS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6908] = {
    npcID = 4887,
    name = L.GHAMOO_RA,
    familyName = L.GHAMOO_RA,
    zone = L.BLACKFATHOM_DEEPS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[888] = {
    npcID = 4831,
    name = L.LADY_SAREVESS,
    familyName = L.LADY_SAREVESS,
    zone = L.BLACKFATHOM_DEEPS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6901] = {
    npcID = 4830,
    name = L.OLD_SERRA_KIS,
    familyName = L.OLD_SERRA_KIS,
    zone = L.BLACKFATHOM_DEEPS,
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6902] = {
    npcID = 4830,
    name = L.OLD_SERRA_KIS,
    familyName = L.OLD_SERRA_KIS,
    zone = L.BLACKFATHOM_DEEPS,
    verified = true,
}

function S.Profile(id)
    return S.profiles[id]
end

function S.Eligible(id, npcID, kind)
    kind = kind or "outdoor"
    local profile = S.Profile(id)
    if
        not profile
        or not profile.enabled
        or not profile.verified
        or (profile.kind or "outdoor") ~= kind
    then
        return nil
    end
    local pieces = {}
    for itemID, source in pairs(profile.sources) do
        if source.verified and source.npcID == npcID then
            pieces[#pieces + 1] = itemID
        end
    end
    table.sort(pieces)
    return pieces, profile
end

function S.ActiveProfile(kind)
    kind = kind or "outdoor"
    if not GetBuildInfo or not W.Client then
        return nil
    end
    local _, _, _, interface = GetBuildInfo()
    if issecretvalue and issecretvalue(interface) then
        return nil
    end
    local selected
    for id, profile in pairs(S.profiles) do
        if
            profile.enabled
            and profile.verified
            and profile.interface == interface
            and profile.flavor == W.Client.flavor
            and (profile.kind or "outdoor") == kind
            and (not selected or id < selected.id)
        then
            selected = profile
        end
    end
    return selected
end

function S.ObserveKill(state, guid)
    if issecretvalue and issecretvalue(guid) then
        return false
    end
    if not IsInInstance or type(guid) ~= "string" or state.offline then
        return false
    end
    local inside, kind = IsInInstance()
    if issecretvalue and (issecretvalue(inside) or issecretvalue(kind)) then
        return false
    end
    local collectionKind
    if inside == false and kind == "none" then
        collectionKind = "outdoor"
    elseif inside == true and kind == "party" then
        collectionKind = "dungeon"
    else
        return false
    end
    local profile = S.ActiveProfile(collectionKind)
    if not profile then
        return false
    end
    local npcID = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$")
    if not npcID then
        return false
    end
    return W.Game.CollectionKill(state, {
        profile = profile.id,
        receipt = "kill:" .. guid,
        npcID = tonumber(npcID),
        kind = collectionKind,
        outdoor = collectionKind == "outdoor",
        dungeon = collectionKind == "dungeon",
        attributed = true,
    })
end
