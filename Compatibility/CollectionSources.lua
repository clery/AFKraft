local _, W = ...
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
        guarantee = 30,
        sources = {
            [4701] = {
                npcID = 423,
                name = "Redridge Mongrel",
                familyName = "Gnolls",
                zone = "Redridge Mountains",
                verified = false,
            },
            [2985] = {
                npcID = 423,
                name = "Redridge Mongrel",
                familyName = "Gnolls",
                zone = "Redridge Mountains",
                verified = false,
            },
            [2986] = {
                npcID = 4464,
                name = "Blackrock Gladiator",
                familyName = "Blackrock orcs",
                zone = "Redridge Mountains",
                verified = false,
            },
            [2987] = {
                npcID = 4464,
                name = "Blackrock Gladiator",
                familyName = "Blackrock orcs",
                zone = "Redridge Mountains",
                verified = false,
            },
            [2988] = {
                npcID = 4464,
                name = "Blackrock Gladiator",
                familyName = "Blackrock orcs",
                zone = "Redridge Mountains",
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
        guarantee = 30,
        sources = {
            [4701] = {
                npcID = 423,
                name = "Redridge Mongrel",
                familyName = "Gnolls",
                zone = "Redridge Mountains",
                verified = true,
            },
            [2985] = {
                npcID = 1183,
                name = "Mo'grosh Mystic",
                familyName = "Ogres",
                zone = "Loch Modan",
                verified = true,
            },
            [2986] = {
                npcID = 1183,
                name = "Mo'grosh Mystic",
                familyName = "Ogres",
                zone = "Loch Modan",
                verified = true,
            },
            [2987] = {
                npcID = 1183,
                name = "Mo'grosh Mystic",
                familyName = "Ogres",
                zone = "Loch Modan",
                verified = true,
            },
            [2988] = {
                npcID = 1183,
                name = "Mo'grosh Mystic",
                familyName = "Ogres",
                zone = "Loch Modan",
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
    guarantee = 10,
    sources = {
        [10399] = {
            npcID = 639,
            name = "Edwin VanCleef",
            familyName = "Humans",
            zone = "The Deadmines",
            verified = true,
        },
        [10400] = {
            npcID = 634,
            name = "Defias Overseer",
            familyName = "Humans",
            zone = "The Deadmines",
            verified = true,
        },
        [10401] = {
            npcID = 634,
            name = "Defias Overseer",
            familyName = "Humans",
            zone = "The Deadmines",
            verified = true,
        },
        [10402] = {
            npcID = 4416,
            name = "Defias Strip Miner",
            familyName = "Humans",
            zone = "The Deadmines",
            verified = true,
        },
        [10403] = {
            npcID = 647,
            name = "Captain Greenskin",
            familyName = "Goblins",
            zone = "The Deadmines",
            verified = true,
        },
    },
}

S.profiles.forever16001.sources[3288] = {
    npcID = 12320,
    name = "Burning Blade Crusher",
    familyName = "Burning Blade Crusher",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[3287] = {
    npcID = 2039,
    name = "Ursal the Mauler",
    familyName = "Ursal the Mauler",
    zone = "Teldrassil",
    verified = true,
}
S.profiles.forever16001.sources[3284] = {
    npcID = 2014,
    name = "Gnarlpine Totemic",
    familyName = "Gnarlpine Totemic",
    zone = "Teldrassil",
    verified = true,
}
S.profiles.forever16001.sources[3286] = {
    npcID = 5786,
    name = "Snagglespear",
    familyName = "Snagglespear",
    zone = "Mulgore",
    verified = true,
}
S.profiles.forever16001.sources[4674] = {
    npcID = 3197,
    name = "Burning Blade Fanatic",
    familyName = "Burning Blade Fanatic",
    zone = "Durotar",
    verified = true,
}
S.profiles.forever16001.sources[14167] = {
    npcID = 125,
    name = "Riverpaw Overseer",
    familyName = "Riverpaw Overseer",
    zone = "Westfall",
    verified = true,
}
S.profiles.forever16001.sources[14173] = {
    npcID = 1180,
    name = "Mo'grosh Brute",
    familyName = "Mo'grosh Brute",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[14174] = {
    npcID = 1180,
    name = "Mo'grosh Brute",
    familyName = "Mo'grosh Brute",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[14166] = {
    npcID = 1179,
    name = "Mo'grosh Enforcer",
    familyName = "Mo'grosh Enforcer",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[14168] = {
    npcID = 4064,
    name = "Blackrock Scout",
    familyName = "Blackrock Scout",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[9775] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9777] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9780] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9776] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9781] = {
    npcID = 5932,
    name = "Taskmaster Whipfang",
    familyName = "Taskmaster Whipfang",
    zone = "Stonetalon Mountains",
    verified = true,
}
S.profiles.forever16001.sources[3211] = {
    npcID = 2106,
    name = "Apothecary Berard",
    familyName = "Apothecary Berard",
    zone = "Silverpine Forest",
    verified = true,
}
S.profiles.forever16001.sources[2992] = {
    npcID = 271898,
    name = "Greater Tarantula",
    familyName = "Greater Tarantula",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[2991] = {
    npcID = 4065,
    name = "Blackrock Sentry",
    familyName = "Blackrock Sentry",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[4697] = {
    npcID = 4064,
    name = "Blackrock Scout",
    familyName = "Blackrock Scout",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[2989] = {
    npcID = 4065,
    name = "Blackrock Sentry",
    familyName = "Blackrock Sentry",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[9784] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9787] = {
    npcID = 5835,
    name = "Foreman Grills",
    familyName = "Foreman Grills",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[9789] = {
    npcID = 5830,
    name = "Sister Rathtalon",
    familyName = "Sister Rathtalon",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[9783] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[9788] = {
    npcID = 2186,
    name = "Carnivous the Breaker",
    familyName = "Carnivous the Breaker",
    zone = "Darkshore",
    verified = true,
}
S.profiles.forever16001.sources[2982] = {
    npcID = 1180,
    name = "Mo'grosh Brute",
    familyName = "Mo'grosh Brute",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[2984] = {
    npcID = 1181,
    name = "Mo'grosh Shaman",
    familyName = "Mo'grosh Shaman",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[4699] = {
    npcID = 1179,
    name = "Mo'grosh Enforcer",
    familyName = "Mo'grosh Enforcer",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[2981] = {
    npcID = 4064,
    name = "Blackrock Scout",
    familyName = "Blackrock Scout",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[4698] = {
    npcID = 1039,
    name = "Fen Dweller",
    familyName = "Fen Dweller",
    zone = "Wetlands",
    verified = true,
}
S.profiles.forever16001.sources[6563] = {
    npcID = 14269,
    name = "Seeker Aqualon",
    familyName = "Seeker Aqualon",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[6570] = {
    npcID = 5932,
    name = "Taskmaster Whipfang",
    familyName = "Taskmaster Whipfang",
    zone = "Stonetalon Mountains",
    verified = true,
}
S.profiles.forever16001.sources[6565] = {
    npcID = 5932,
    name = "Taskmaster Whipfang",
    familyName = "Taskmaster Whipfang",
    zone = "Stonetalon Mountains",
    verified = true,
}
S.profiles.forever16001.sources[6562] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[6564] = {
    npcID = 5831,
    name = "Swiftmane",
    familyName = "Swiftmane",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[6575] = {
    npcID = 14269,
    name = "Seeker Aqualon",
    familyName = "Seeker Aqualon",
    zone = "Redridge Mountains",
    verified = true,
}
S.profiles.forever16001.sources[6574] = {
    npcID = 3735,
    name = "Apothecary Falthis",
    familyName = "Apothecary Falthis",
    zone = "Ashenvale",
    verified = true,
}
S.profiles.forever16001.sources[6576] = {
    npcID = 3735,
    name = "Apothecary Falthis",
    familyName = "Apothecary Falthis",
    zone = "Ashenvale",
    verified = true,
}
S.profiles.forever16001.sources[6578] = {
    npcID = 1183,
    name = "Mo'grosh Mystic",
    familyName = "Mo'grosh Mystic",
    zone = "Loch Modan",
    verified = true,
}
S.profiles.forever16001.sources[6573] = {
    npcID = 14425,
    name = "Gnawbone",
    familyName = "Gnawbone",
    zone = "Wetlands",
    verified = true,
}
S.profiles.forever16001.sources[285331] = {
    npcID = 5828,
    name = "Humar the Pridelord",
    familyName = "Humar the Pridelord",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[285330] = {
    npcID = 5831,
    name = "Swiftmane",
    familyName = "Swiftmane",
    zone = "The Barrens",
    verified = true,
}
S.profiles.forever16001.sources[285329] = {
    npcID = 5842,
    name = "Takk the Leaper",
    familyName = "Takk the Leaper",
    zone = "The Barrens",
    verified = true,
}

S.profiles.foreverDungeon16001.sources[271097] = {
    npcID = 261306,
    name = "Faldrim Anvilmar",
    familyName = "Faldrim Anvilmar",
    zone = "The Hall of Thanes",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271096] = {
    npcID = 261306,
    name = "Faldrim Anvilmar",
    familyName = "Faldrim Anvilmar",
    zone = "The Hall of Thanes",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270230] = {
    npcID = 261316,
    name = "Magmatus",
    familyName = "Magmatus",
    zone = "The Hall of Thanes",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270231] = {
    npcID = 261316,
    name = "Magmatus",
    familyName = "Magmatus",
    zone = "The Hall of Thanes",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271098] = {
    npcID = 261311,
    name = "Plunder",
    familyName = "Plunder",
    zone = "The Hall of Thanes",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10412] = {
    npcID = 3671,
    name = "Lady Anacondra",
    familyName = "Lady Anacondra",
    zone = "Wailing Caverns",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10411] = {
    npcID = 3673,
    name = "Lord Serpentis",
    familyName = "Lord Serpentis",
    zone = "Wailing Caverns",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10413] = {
    npcID = 3840,
    name = "Druid of the Fang",
    familyName = "Druid of the Fang",
    zone = "Wailing Caverns",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10410] = {
    npcID = 3669,
    name = "Lord Cobrahn",
    familyName = "Lord Cobrahn",
    zone = "Wailing Caverns",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6473] = {
    npcID = 3670,
    name = "Lord Pythas",
    familyName = "Lord Pythas",
    zone = "Wailing Caverns",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286978] = {
    npcID = 255109,
    name = "Flesh Golem",
    familyName = "Flesh Golem",
    zone = "Ruins of Lordaeron",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286980] = {
    npcID = 250620,
    name = "Shrieking Banshee",
    familyName = "Shrieking Banshee",
    zone = "Ruins of Lordaeron",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271207] = {
    npcID = 250631,
    name = "The Abandoned",
    familyName = "The Abandoned",
    zone = "Ruins of Lordaeron",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271214] = {
    npcID = 250657,
    name = "Rath'mael",
    familyName = "Rath'mael",
    zone = "Ruins of Lordaeron",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286979] = {
    npcID = 250629,
    name = "Stone Watcher",
    familyName = "Stone Watcher",
    zone = "Ruins of Lordaeron",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[5254] = {
    npcID = 3914,
    name = "Rethilgore",
    familyName = "Rethilgore",
    zone = "Shadowfang Keep",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6319] = {
    npcID = 4279,
    name = "Odo the Blindwatcher",
    familyName = "Odo the Blindwatcher",
    zone = "Shadowfang Keep",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6340] = {
    npcID = 4274,
    name = "Fenrus the Devourer",
    familyName = "Fenrus the Devourer",
    zone = "Shadowfang Keep",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[3230] = {
    npcID = 4274,
    name = "Fenrus the Devourer",
    familyName = "Fenrus the Devourer",
    zone = "Shadowfang Keep",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6324] = {
    npcID = 4275,
    name = "Archmage Arugal",
    familyName = "Archmage Arugal",
    zone = "Shadowfang Keep",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6907] = {
    npcID = 4887,
    name = "Ghamoo-ra",
    familyName = "Ghamoo-ra",
    zone = "Blackfathom Deeps",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6908] = {
    npcID = 4887,
    name = "Ghamoo-ra",
    familyName = "Ghamoo-ra",
    zone = "Blackfathom Deeps",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[888] = {
    npcID = 4831,
    name = "Lady Sarevess",
    familyName = "Lady Sarevess",
    zone = "Blackfathom Deeps",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6901] = {
    npcID = 4830,
    name = "Old Serra'kis",
    familyName = "Old Serra'kis",
    zone = "Blackfathom Deeps",
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6902] = {
    npcID = 4830,
    name = "Old Serra'kis",
    familyName = "Old Serra'kis",
    zone = "Blackfathom Deeps",
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
