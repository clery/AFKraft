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
