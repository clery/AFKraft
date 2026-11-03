local _, W = ...
local C = W.Content

-- Curated idle rewards, not a claim about live creature loot tables.
-- Item identities and artwork reuse the catalog snapshots in Content/ITEMS.md.
C.collections = {
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
C.collectionByID, C.collectionByItem = {}, {}
for _, collection in ipairs(C.collections) do
    C.collectionByID[collection.id] = collection
    for _, itemID in ipairs(collection.pieces) do
        assert(C.itemByID[itemID], "Unknown collection item")
        C.collectionByItem[itemID] = collection.id
    end
end
