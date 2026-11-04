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
                name = L["Redridge Mongrel"],
                familyName = L["Gnolls"],
                zone = L["Redridge Mountains"],
                verified = false,
            },
            [2985] = {
                npcID = 423,
                name = L["Redridge Mongrel"],
                familyName = L["Gnolls"],
                zone = L["Redridge Mountains"],
                verified = false,
            },
            [2986] = {
                npcID = 4464,
                name = L["Blackrock Gladiator"],
                familyName = L["Blackrock orcs"],
                zone = L["Redridge Mountains"],
                verified = false,
            },
            [2987] = {
                npcID = 4464,
                name = L["Blackrock Gladiator"],
                familyName = L["Blackrock orcs"],
                zone = L["Redridge Mountains"],
                verified = false,
            },
            [2988] = {
                npcID = 4464,
                name = L["Blackrock Gladiator"],
                familyName = L["Blackrock orcs"],
                zone = L["Redridge Mountains"],
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
                name = L["Redridge Mongrel"],
                familyName = L["Gnolls"],
                zone = L["Redridge Mountains"],
                verified = true,
            },
            [2985] = {
                npcID = 1183,
                name = L["Mo'grosh Mystic"],
                familyName = L["Ogres"],
                zone = L["Loch Modan"],
                verified = true,
            },
            [2986] = {
                npcID = 1183,
                name = L["Mo'grosh Mystic"],
                familyName = L["Ogres"],
                zone = L["Loch Modan"],
                verified = true,
            },
            [2987] = {
                npcID = 1183,
                name = L["Mo'grosh Mystic"],
                familyName = L["Ogres"],
                zone = L["Loch Modan"],
                verified = true,
            },
            [2988] = {
                npcID = 1183,
                name = L["Mo'grosh Mystic"],
                familyName = L["Ogres"],
                zone = L["Loch Modan"],
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
            name = L["Edwin VanCleef"],
            familyName = L["Humans"],
            zone = L["The Deadmines"],
            verified = true,
        },
        [10400] = {
            npcID = 634,
            name = L["Defias Overseer"],
            familyName = L["Humans"],
            zone = L["The Deadmines"],
            verified = true,
        },
        [10401] = {
            npcID = 634,
            name = L["Defias Overseer"],
            familyName = L["Humans"],
            zone = L["The Deadmines"],
            verified = true,
        },
        [10402] = {
            npcID = 4416,
            name = L["Defias Strip Miner"],
            familyName = L["Humans"],
            zone = L["The Deadmines"],
            verified = true,
        },
        [10403] = {
            npcID = 647,
            name = L["Captain Greenskin"],
            familyName = L["Goblins"],
            zone = L["The Deadmines"],
            verified = true,
        },
    },
}

S.profiles.forever16001.sources[3288] = {
    npcID = 12320,
    name = L["Burning Blade Crusher"],
    familyName = L["Burning Blade Crusher"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[3287] = {
    npcID = 2039,
    name = L["Ursal the Mauler"],
    familyName = L["Ursal the Mauler"],
    zone = L["Teldrassil"],
    verified = true,
}
S.profiles.forever16001.sources[3284] = {
    npcID = 2014,
    name = L["Gnarlpine Totemic"],
    familyName = L["Gnarlpine Totemic"],
    zone = L["Teldrassil"],
    verified = true,
}
S.profiles.forever16001.sources[3286] = {
    npcID = 5786,
    name = L["Snagglespear"],
    familyName = L["Snagglespear"],
    zone = L["Mulgore"],
    verified = true,
}
S.profiles.forever16001.sources[4674] = {
    npcID = 3197,
    name = L["Burning Blade Fanatic"],
    familyName = L["Burning Blade Fanatic"],
    zone = L["Durotar"],
    verified = true,
}
S.profiles.forever16001.sources[14167] = {
    npcID = 125,
    name = L["Riverpaw Overseer"],
    familyName = L["Riverpaw Overseer"],
    zone = L["Westfall"],
    verified = true,
}
S.profiles.forever16001.sources[14173] = {
    npcID = 1180,
    name = L["Mo'grosh Brute"],
    familyName = L["Mo'grosh Brute"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[14174] = {
    npcID = 1180,
    name = L["Mo'grosh Brute"],
    familyName = L["Mo'grosh Brute"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[14166] = {
    npcID = 1179,
    name = L["Mo'grosh Enforcer"],
    familyName = L["Mo'grosh Enforcer"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[14168] = {
    npcID = 4064,
    name = L["Blackrock Scout"],
    familyName = L["Blackrock Scout"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[9775] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9777] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9780] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9776] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9781] = {
    npcID = 5932,
    name = L["Taskmaster Whipfang"],
    familyName = L["Taskmaster Whipfang"],
    zone = L["Stonetalon Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[3211] = {
    npcID = 2106,
    name = L["Apothecary Berard"],
    familyName = L["Apothecary Berard"],
    zone = L["Silverpine Forest"],
    verified = true,
}
S.profiles.forever16001.sources[2992] = {
    npcID = 271898,
    name = L["Greater Tarantula"],
    familyName = L["Greater Tarantula"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[2991] = {
    npcID = 4065,
    name = L["Blackrock Sentry"],
    familyName = L["Blackrock Sentry"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[4697] = {
    npcID = 4064,
    name = L["Blackrock Scout"],
    familyName = L["Blackrock Scout"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[2989] = {
    npcID = 4065,
    name = L["Blackrock Sentry"],
    familyName = L["Blackrock Sentry"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[9784] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9787] = {
    npcID = 5835,
    name = L["Foreman Grills"],
    familyName = L["Foreman Grills"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[9789] = {
    npcID = 5830,
    name = L["Sister Rathtalon"],
    familyName = L["Sister Rathtalon"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[9783] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[9788] = {
    npcID = 2186,
    name = L["Carnivous the Breaker"],
    familyName = L["Carnivous the Breaker"],
    zone = L["Darkshore"],
    verified = true,
}
S.profiles.forever16001.sources[2982] = {
    npcID = 1180,
    name = L["Mo'grosh Brute"],
    familyName = L["Mo'grosh Brute"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[2984] = {
    npcID = 1181,
    name = L["Mo'grosh Shaman"],
    familyName = L["Mo'grosh Shaman"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[4699] = {
    npcID = 1179,
    name = L["Mo'grosh Enforcer"],
    familyName = L["Mo'grosh Enforcer"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[2981] = {
    npcID = 4064,
    name = L["Blackrock Scout"],
    familyName = L["Blackrock Scout"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[4698] = {
    npcID = 1039,
    name = L["Fen Dweller"],
    familyName = L["Fen Dweller"],
    zone = L["Wetlands"],
    verified = true,
}
S.profiles.forever16001.sources[6563] = {
    npcID = 14269,
    name = L["Seeker Aqualon"],
    familyName = L["Seeker Aqualon"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[6570] = {
    npcID = 5932,
    name = L["Taskmaster Whipfang"],
    familyName = L["Taskmaster Whipfang"],
    zone = L["Stonetalon Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[6565] = {
    npcID = 5932,
    name = L["Taskmaster Whipfang"],
    familyName = L["Taskmaster Whipfang"],
    zone = L["Stonetalon Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[6562] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[6564] = {
    npcID = 5831,
    name = L["Swiftmane"],
    familyName = L["Swiftmane"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[6575] = {
    npcID = 14269,
    name = L["Seeker Aqualon"],
    familyName = L["Seeker Aqualon"],
    zone = L["Redridge Mountains"],
    verified = true,
}
S.profiles.forever16001.sources[6574] = {
    npcID = 3735,
    name = L["Apothecary Falthis"],
    familyName = L["Apothecary Falthis"],
    zone = L["Ashenvale"],
    verified = true,
}
S.profiles.forever16001.sources[6576] = {
    npcID = 3735,
    name = L["Apothecary Falthis"],
    familyName = L["Apothecary Falthis"],
    zone = L["Ashenvale"],
    verified = true,
}
S.profiles.forever16001.sources[6578] = {
    npcID = 1183,
    name = L["Mo'grosh Mystic"],
    familyName = L["Mo'grosh Mystic"],
    zone = L["Loch Modan"],
    verified = true,
}
S.profiles.forever16001.sources[6573] = {
    npcID = 14425,
    name = L["Gnawbone"],
    familyName = L["Gnawbone"],
    zone = L["Wetlands"],
    verified = true,
}
S.profiles.forever16001.sources[285331] = {
    npcID = 5828,
    name = L["Humar the Pridelord"],
    familyName = L["Humar the Pridelord"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[285330] = {
    npcID = 5831,
    name = L["Swiftmane"],
    familyName = L["Swiftmane"],
    zone = L["The Barrens"],
    verified = true,
}
S.profiles.forever16001.sources[285329] = {
    npcID = 5842,
    name = L["Takk the Leaper"],
    familyName = L["Takk the Leaper"],
    zone = L["The Barrens"],
    verified = true,
}

S.profiles.foreverDungeon16001.sources[271097] = {
    npcID = 261306,
    name = L["Faldrim Anvilmar"],
    familyName = L["Faldrim Anvilmar"],
    zone = L["The Hall of Thanes"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271096] = {
    npcID = 261306,
    name = L["Faldrim Anvilmar"],
    familyName = L["Faldrim Anvilmar"],
    zone = L["The Hall of Thanes"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270230] = {
    npcID = 261316,
    name = L["Magmatus"],
    familyName = L["Magmatus"],
    zone = L["The Hall of Thanes"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[270231] = {
    npcID = 261316,
    name = L["Magmatus"],
    familyName = L["Magmatus"],
    zone = L["The Hall of Thanes"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271098] = {
    npcID = 261311,
    name = L["Plunder"],
    familyName = L["Plunder"],
    zone = L["The Hall of Thanes"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10412] = {
    npcID = 3671,
    name = L["Lady Anacondra"],
    familyName = L["Lady Anacondra"],
    zone = L["Wailing Caverns"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10411] = {
    npcID = 3673,
    name = L["Lord Serpentis"],
    familyName = L["Lord Serpentis"],
    zone = L["Wailing Caverns"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10413] = {
    npcID = 3840,
    name = L["Druid of the Fang"],
    familyName = L["Druid of the Fang"],
    zone = L["Wailing Caverns"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[10410] = {
    npcID = 3669,
    name = L["Lord Cobrahn"],
    familyName = L["Lord Cobrahn"],
    zone = L["Wailing Caverns"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6473] = {
    npcID = 3670,
    name = L["Lord Pythas"],
    familyName = L["Lord Pythas"],
    zone = L["Wailing Caverns"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286978] = {
    npcID = 255109,
    name = L["Flesh Golem"],
    familyName = L["Flesh Golem"],
    zone = L["Ruins of Lordaeron"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286980] = {
    npcID = 250620,
    name = L["Shrieking Banshee"],
    familyName = L["Shrieking Banshee"],
    zone = L["Ruins of Lordaeron"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271207] = {
    npcID = 250631,
    name = L["The Abandoned"],
    familyName = L["The Abandoned"],
    zone = L["Ruins of Lordaeron"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[271214] = {
    npcID = 250657,
    name = L["Rath'mael"],
    familyName = L["Rath'mael"],
    zone = L["Ruins of Lordaeron"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[286979] = {
    npcID = 250629,
    name = L["Stone Watcher"],
    familyName = L["Stone Watcher"],
    zone = L["Ruins of Lordaeron"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[5254] = {
    npcID = 3914,
    name = L["Rethilgore"],
    familyName = L["Rethilgore"],
    zone = L["Shadowfang Keep"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6319] = {
    npcID = 4279,
    name = L["Odo the Blindwatcher"],
    familyName = L["Odo the Blindwatcher"],
    zone = L["Shadowfang Keep"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6340] = {
    npcID = 4274,
    name = L["Fenrus the Devourer"],
    familyName = L["Fenrus the Devourer"],
    zone = L["Shadowfang Keep"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[3230] = {
    npcID = 4274,
    name = L["Fenrus the Devourer"],
    familyName = L["Fenrus the Devourer"],
    zone = L["Shadowfang Keep"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6324] = {
    npcID = 4275,
    name = L["Archmage Arugal"],
    familyName = L["Archmage Arugal"],
    zone = L["Shadowfang Keep"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6907] = {
    npcID = 4887,
    name = L["Ghamoo-ra"],
    familyName = L["Ghamoo-ra"],
    zone = L["Blackfathom Deeps"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6908] = {
    npcID = 4887,
    name = L["Ghamoo-ra"],
    familyName = L["Ghamoo-ra"],
    zone = L["Blackfathom Deeps"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[888] = {
    npcID = 4831,
    name = L["Lady Sarevess"],
    familyName = L["Lady Sarevess"],
    zone = L["Blackfathom Deeps"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6901] = {
    npcID = 4830,
    name = L["Old Serra'kis"],
    familyName = L["Old Serra'kis"],
    zone = L["Blackfathom Deeps"],
    verified = true,
}
S.profiles.foreverDungeon16001.sources[6902] = {
    npcID = 4830,
    name = L["Old Serra'kis"],
    familyName = L["Old Serra'kis"],
    zone = L["Blackfathom Deeps"],
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
