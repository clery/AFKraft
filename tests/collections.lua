local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function state()
    local s = G.New(0)
    s.collectionBook = s.collectionBook
        or { pieces = {}, counters = {}, receipts = {}, receiptOrder = {} }
    return s
end
local function context(serial, tier)
    return {
        receipt = "encounter:" .. serial,
        zone = "westfall",
        level = 3,
        family = "humanoid",
        tier = tier or 0,
    }
end
local function random(values, fn)
    local previous, index = G.Random, 0
    G.Random = function(_, n)
        index = index + 1
        local value = values[index] or n
        assert(value >= 1 and value <= n)
        return value
    end
    local ok, message = pcall(fn)
    G.Random = previous
    assert(ok, message)
end
local setID = "westfallOutriders"
local pieces = C.collectionByID[setID].pieces

case("Collection catalog uses curated outdoor item identities", function()
    for _, itemID in ipairs(pieces) do
        assert(C.itemByID[itemID] and C.collectionByItem[itemID] == setID)
        local found = false
        for _, candidate in ipairs(C.zoneItems.westfall) do
            found = found or candidate == itemID
        end
        assert(found)
    end
end)

case("Collection eligibility excludes other zones, families, low levels, and crafting", function()
    for _, changes in ipairs({
        { zone = "elwynn" },
        { family = "beast" },
        { level = 2 },
        { crafted = true },
    }) do
        local s, c = state(), context(1)
        for key, value in pairs(changes) do
            c[key] = value
        end
        random({ 1, 1 }, function()
            assert(not G.CollectionVictory(s, c))
        end)
        assert(not next(s.collectionBook.pieces) and not next(s.collectionBook.counters))
    end
end)

case("Collection guarantees choose a missing piece and register before salvage", function()
    local s = state()
    G.AddHero(s, "MAGE")
    s.salvage.minQuality = 4
    random({}, function()
        for serial = 1, 29 do
            assert(not G.CollectionVictory(s, context(serial)))
        end
    end)
    assert(G.CollectionProgress(s, setID, 0).counter == 29)
    random({ 2 }, function()
        local item = assert(G.CollectionVictory(s, context(30)))
        assert(item.itemID == pieces[2])
        assert(s.collectionBook.pieces[item.itemID] == 0)
        G.Loot(s, item)
        assert(s.collectionBook.pieces[item.itemID] == 0)
    end)
    local p = G.CollectionProgress(s, setID, 0)
    assert(p.found == 1 and p.counter == 0)
    assert(G.ValidateCollections(s))
end)

case("Normal missing drops reset guarantees while duplicates retain progress", function()
    local s = state()
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(1)))
    end)
    assert(G.CollectionProgress(s, setID, 0).counter == 0)
    random({}, function()
        assert(not G.CollectionVictory(s, context(2)))
    end)
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(3)))
    end)
    assert(G.CollectionProgress(s, setID, 0).counter == 2)
    random({ 1, 2 }, function()
        assert(G.CollectionVictory(s, context(4)))
    end)
    assert(G.CollectionProgress(s, setID, 0).counter == 0)
end)

case("Collection receipts reject replay after bounded cache eviction", function()
    local s = state()
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(1)))
    end)
    local seed, nextItem = s.seed, s.nextItem
    assert(not G.CollectionVictory(s, context(1, 9)))
    assert(s.seed == seed and s.nextItem == nextItem and s.collectionBook.pieces[pieces[1]] == 0)
    random({}, function()
        for serial = 2, 140 do
            local c = context(serial)
            c.zone = "elwynn"
            assert(not G.CollectionVictory(s, c))
        end
    end)
    assert(#s.collectionBook.receiptOrder == 128)
    assert(not s.collectionBook.receipts["encounter:1"])
    assert(not G.CollectionVictory(s, context(1, 9)))
    assert(G.ValidateCollections(s))
end)

case("Higher tiers discover once, satisfy lower gaps, and never downgrade", function()
    local s = state()
    s.collectionBook.counters[setID] = { [0] = 20, [1] = 10, [2] = 5 }
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(1, 2)))
    end)
    assert(s.collectionBook.pieces[pieces[1]] == 2)
    for _, count in pairs(s.collectionBook.counters[setID]) do
        assert(count == 0)
    end
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(2, 0)))
    end)
    assert(s.collectionBook.pieces[pieces[1]] == 2)
    local forged = G.Item(s, 2, 4, 2, false, C.itemByID[pieces[2]])
    assert(not G.RegisterCollectionDrop(s, forged, context(3, 9)))
    assert(not s.collectionBook.pieces[pieces[2]])
end)

case("Mixed-tier completion upgrades only at the lowest piece rank", function()
    local s = state()
    for _, itemID in ipairs(pieces) do
        s.collectionBook.pieces[itemID] = 1
    end
    s.collectionBook.pieces[pieces[1]] = 0
    assert(G.CollectionProgress(s, setID).completedRank == 0)
    local base = G.CollectionBonuses(s, "humanoid")
    assert(base.basicAttack == 1.02 and base.materials == 1.03 and base.damageTaken == 0.97)
    assert(G.CollectionBonuses(s, "beast").damageTaken == 1)
    random({ 1, 1 }, function()
        assert(G.CollectionVictory(s, context(1, 1)))
    end)
    assert(G.CollectionProgress(s, setID).completedRank == 1)
    assert(G.CollectionBonuses(s).basicAttack > base.basicAttack)
    assert(
        G.CollectionRankScale(2) - G.CollectionRankScale(1)
            < G.CollectionRankScale(1) - G.CollectionRankScale(0)
    )
    assert(G.CollectionRankScale(1000000) < 1.2)
end)

case("Collection targeting leaves deterministic rewards unchanged", function()
    local a, b = state(), state()
    assert(G.SetCollectionTarget(a, setID))
    for serial = 1, 90 do
        local x, y =
            G.CollectionVictory(a, context(serial)), G.CollectionVictory(b, context(serial))
        assert((x and x.itemID) == (y and y.itemID))
    end
    assert(a.seed == b.seed)
    assert(G.SetCollectionTarget(a, nil))
    assert(not G.SetCollectionTarget(a, "unknown"))
end)

case("Collection validation rejects malformed ranks counters targets and receipts", function()
    for _, value in ipairs({ -1, math.huge, 0 / 0, "bad" }) do
        local s = state()
        s.collectionBook.pieces[pieces[1]] = value
        assert(not G.ValidateCollections(s))
    end
    local s = state()
    s.collectionBook.counters[setID] = { [0] = 30 }
    assert(not G.ValidateCollections(s))
    s = state()
    s.collectionBook.target = "unknown"
    assert(not G.ValidateCollections(s))
    s = state()
    s.collectionBook.receipts["encounter:1"] = true
    assert(not G.ValidateCollections(s))
end)

case("Collections retain discoveries target and counters through reload and prestige", function()
    local s = state()
    G.AddHero(s, "WARRIOR")
    s.collectionBook.pieces[pieces[1]] = 2
    s.collectionBook.counters[setID] = { [0] = 7, [1] = 3 }
    assert(G.SetCollectionTarget(s, setID))
    s = assert(G.Load(G.Copy(s), 200))
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s))
    assert(s.collectionBook.pieces[pieces[1]] == 2)
    assert(s.collectionBook.counters[setID][0] == 7 and s.collectionBook.target == setID)
end)

return cases
