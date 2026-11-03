local _, W = ...
local C = W.Content

-- Archived simulated rewards, retained only to protect existing earned value.
-- Item identities and artwork reuse the catalog snapshots in Content/ITEMS.md.
C.legacyCollections = {
    {
        id = "westfallOutriders",
        name = "Westfall Outriders",
        description = "A weathered cloak and leather field kit from Westfall's outlaw country.",
        pieces = { 1930, 2985, 2986, 2987, 2988 },
        zones = { westfall = true },
        families = { humanoid = true },
        minLevel = 3,
        chance = 5,
        guarantee = 30,
        source = "Idle Westfall humanoid victories, idle level 3+. Outdoor minigame rewards; no dungeon required.",
        family = "humanoid",
        milestones = {
            basicAttack = { pieces = 2, bonus = 0.02 },
            materials = { pieces = 4, bonus = 0.03 },
        },
        defense = 0.03,
    },
}
-- Collection identities do not enter ordinary item loot or crafting pools.
C.collectionItemByID = {
    [10399] = {
        itemID = 10399,
        name = "Blackened Defias Armor",
        icon = "inv_chest_leather_08",
        slot = 2,
    },
    [10400] = {
        itemID = 10400,
        name = "Blackened Defias Leggings",
        icon = "inv_pants_12",
        slot = 10,
    },
    [10401] = {
        itemID = 10401,
        name = "Blackened Defias Gloves",
        icon = "inv_gauntlets_18",
        slot = 8,
    },
    [10402] = { itemID = 10402, name = "Blackened Defias Boots", icon = "inv_boots_05", slot = 11 },
    [10403] = { itemID = 10403, name = "Blackened Defias Belt", icon = "inv_belt_26", slot = 9 },
}
C.collections = {
    {
        id = "redridgeOutriders",
        kind = "outdoor",
        name = "Redridge Outriders",
        description = "An inscribed leather field kit. Hunt individual pieces outdoors.",
        pieces = { 4701, 2985, 2986, 2987, 2988 },
        milestones = {
            basicAttack = { pieces = 2, bonus = 0.005 },
            materials = { pieces = 4, bonus = 0.005 },
        },
        effect = { basicAttack = 0.04 },
    },
}
C.collections[#C.collections + 1] = {
    id = "defiasLeather",
    kind = "dungeon",
    name = "Defias Leather",
    description = "A dungeon collection from the Deadmines. Hunt Defias families inside the instance.",
    pieces = { 10399, 10400, 10401, 10402, 10403 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "humanoid", damageTaken = 0.96 },
}

C.legacyCollectionByID, C.legacyCollectionByItem = {}, {}
for _, collection in ipairs(C.legacyCollections) do
    C.legacyCollectionByID[collection.id] = collection
    for _, itemID in ipairs(collection.pieces) do
        C.legacyCollectionByItem[itemID] = collection.id
    end
end
C.collectionByID, C.collectionByItem = {}, {}
for _, collection in ipairs(C.collections) do
    C.collectionByID[collection.id] = collection
    for _, itemID in ipairs(collection.pieces) do
        assert(C.itemByID[itemID] or C.collectionItemByID[itemID], "Unknown collection item")
        C.collectionByItem[itemID] = collection.id
    end
end
