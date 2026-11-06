local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
local function state()
    local s = G.New(1000)
    G.AddHero(s, "WARRIOR")
    s.heroes[1].level = 60
    return s
end
local function drop(s, count, quality)
    for _ = 1, count do
        local item = G.Item(s, 1, 1, 2, false, C.itemByID[25])
        item.quality = quality or 2
        G.StoreChest(s, item)
    end
end
case(
    "Chest rewards are fixed at earning and partial batches use distinct item identities",
    function()
        local s = state()
        drop(s, 12)
        assert(G.ChestCount(s) == 12 and #s.chests == 1 and #s.inventory == 0)
        assert(s.gold == 0 and s.stats.salvaged == 0)
        local seed, uid, itemID = s.seed, s.chests[1].item.uid, s.chests[1].item.itemID
        s = assert(G.Load(G.Copy(s), 1100))
        s.zone, s.tier = "durotar", 1
        local ok, _, report = G.OpenChests(s, 1)
        assert(ok and report.count == 1 and report.entries[1].item.itemID == itemID)
        assert(G.ChestCount(s) == 11 and s.seed == seed)
        assert(s.inventory[1].uid ~= uid and s.chests[1].item.uid == uid)
        s.tier = 0
        local openedUID = s.inventory[1].uid
        assert(G.Load(G.Copy(s), 1200))
        assert(G.OpenChests(s, 10) and G.ChestCount(s) == 1)
        assert(s.inventory[1].count == 11 and s.inventory[1].uid == openedUID)
        assert(G.OpenChests(s, "all") and G.ChestCount(s) == 0)
        assert(s.inventory[1].count == 12 and s.seed == seed)
        assert(not G.OpenChests(s, 1))
    end
)
case("Chest source filters preserve other zones and highest rarity orders batch results", function()
    local s = state()
    drop(s, 2, 2)
    s.zone = "durotar"
    drop(s, 3, 4)
    assert(G.ChestCount(s, "elwynn") == 2)
    local ok, _, report = G.OpenChests(s, 10, "elwynn")
    assert(ok and report.count == 2 and report.quality == 2)
    assert(G.ChestCount(s) == 3 and s.chests[1].zone == "durotar")
    s.zone = "elwynn"
    drop(s, 1, 1)
    ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.count == 4 and report.quality == 4)
    assert(report.entries[1].item.quality == 4 and report.entries[2].item.quality == 1)
end)
case("Opening uses current loot rules and reports exact salvage and duplicate totals", function()
    local s = state()
    drop(s, 12)
    s.salvage.minQuality, s.salvage.keepUpgrades, s.salvage.keepEffects = 4, false, false
    local ok, _, report = G.OpenChests(s, 10)
    assert(ok and report.count == 10 and report.salvaged == 10 and report.duplicates == 9)
    assert(report.gold == 40 and report.ore == 20 and s.stats.salvaged == 10)
    assert(#s.inventory == 0 and G.ChestCount(s) == 2)
    s.salvage.minQuality = 1
    ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.salvaged == 0 and report.duplicates == 1)
    assert(#s.inventory == 1 and s.inventory[1].count == 2)
    drop(s, 1)
    ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.duplicates == 1 and s.inventory[1].count == 3)
end)
case("Malformed chest saves and invalid opening requests cannot consume rewards", function()
    for _, corrupt in ipairs({
        function(s)
            s.chests = false
        end,
        function(s)
            s.chests[1].count = -1
        end,
        function(s)
            s.chests[1].count = 1.5
        end,
        function(s)
            s.chests[1].count = math.huge
        end,
        function(s)
            s.chests[1].zone = "unknown"
        end,
        function(s)
            s.chests[1].item = false
        end,
        function(s)
            s.chests[1].item.stats.strength = 0 / 0
        end,
        function(s)
            s.chests[1].item.stats.unknown = 1
        end,
        function(s)
            s.chests[1].item.slot = 99
        end,
        function(s)
            s.chests[1].item.uid = s.nextItem
        end,
        function(s)
            s.chests[1].item.count = 3
        end,
        function(s)
            s.chests[2] = G.Copy(s.chests[1])
        end,
        function(s)
            s.chests[3], s.chests[1] = s.chests[1], nil
        end,
    }) do
        local s = state()
        drop(s, 2)
        corrupt(s)
        assert(not G.Load(G.Copy(s), 1100))
    end
    local s = state()
    drop(s, 3)
    for _, amount in ipairs({ 0, -1, 2, 1.5, math.huge, "unknown" }) do
        assert(not G.OpenChests(s, amount))
        assert(G.ChestCount(s) == 3 and #s.inventory == 0 and s.gold == 0)
    end
    assert(not G.OpenChests(s, "all", "missing"))
    local invalid = G.Copy(s)
    invalid.inventory[1] = G.Copy(invalid.chests[1].item)
    assert(not G.Load(invalid, 1100))
end)
case("Identical salvage from different source zones is reported as a duplicate", function()
    local s = state()
    s.salvage.minQuality, s.salvage.keepUpgrades = 4, false
    drop(s, 1)
    s.zone = "durotar"
    drop(s, 1)
    local ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.salvaged == 2 and report.duplicates == 1)
end)
case("Old saves gain empty chest storage and chapter resets discard unopened run loot", function()
    local s = state()
    s.chests = nil
    assert(G.Load(s, 1000) and G.ChestCount(s) == 0)
    drop(s, 2)
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s) and G.ChestCount(s) == 0)
    assert(G.Load(G.Copy(s), 1100))
end)
case("Offline catch-up banks the same predetermined chests across batch sizes", function()
    local initial = state()
    initial.safe.elwynn, initial.lastTime = 1, 1000
    drop(initial, 2)
    local a, b = G.Copy(initial), G.Copy(initial)
    for index, s in ipairs({ a, b }) do
        local job = assert(G.BeginCatchup(s, 1300))
        while not G.CatchupBatch(job, index == 1 and 1 or 1200) do
        end
        local earned = G.ChestCount(job.state) - 2
        assert(G.FinishCatchup(s, job))
        assert(not G.FinishCatchup(s, job))
        assert(s.lastOfflineSummary.chests == earned and earned > 0)
        assert(#s.inventory == 0 and s.stats.salvaged == 0)
        assert(G.Load(G.Copy(s), 1300))
    end
    assert(G.ChestCount(a) == G.ChestCount(b) and #a.chests == #b.chests)
    for index, chest in ipairs(a.chests) do
        local other = b.chests[index]
        assert(chest.count == other.count and G.SameItem(chest.item, other.item))
    end
    assert(G.OpenChests(a, "all") and G.OpenChests(b, "all"))
    assert(a.gold == b.gold and a.stats.salvaged == b.stats.salvaged)
end)
local function cloak(s, stats)
    for _, template in ipairs(C.items) do
        if template.slot == 4 then
            local item = G.Item(s, 4, 1, 2, false, template)
            item.stats, item.quality = stats, 2
            return item
        end
    end
end
case(
    "Chest auto equip maximizes the party total instead of greedily serving the first hero",
    function()
        local s = state()
        G.AddHero(s, "MAGE")
        s.heroes[2].level = 60
        s.settings.chestAutoEquip = true
        s.salvage.minQuality, s.salvage.keepUpgrades = 4, false
        local flexible = cloak(s, { strength = 10, intellect = 12 })
        local warrior = cloak(s, { strength = 9 })
        G.StoreChest(s, flexible)
        G.StoreChest(s, warrior)
        G.StoreChest(s, cloak(s, { stamina = 0.1 }))
        local expected = G.ItemPower(warrior, s.heroes[1]) + G.ItemPower(flexible, s.heroes[2])
        local ok, _, report = G.OpenChests(s, "all")
        assert(ok and report.equipped == 2 and report.disenchanted == 1)
        assert(s.heroes[1].gear[4].stats.strength == 9)
        assert(s.heroes[2].gear[4].stats.intellect == 12)
        assert(math.abs(report.powerGain - expected) < 0.00001)
        assert(#s.inventory == 0 and report.relic == 1 and report.gold == 2)
        assert(G.Load(G.Copy(s), 1100))
    end
)
case(
    "Chest auto equip respects stack supply and preserves existing inventory and displaced gear",
    function()
        local s = state()
        s.settings.chestAutoEquip = true
        local old = cloak(s, { strength = 1 })
        old.protected = true
        s.heroes[1].gear[4] = old
        local bag = cloak(s, { strength = 50 })
        bag.count = 7
        s.inventory[1] = bag
        for _ = 1, 3 do
            G.StoreChest(s, cloak(s, { strength = 10 }))
        end
        G.StartBattle(s)
        local unit = s.battle.heroes[1]
        unit.hp = unit.maxHP * 0.4
        local attack = unit.attackAt
        local ok, _, report = G.OpenChests(s, "all")
        assert(ok and report.equipped == 1 and report.disenchanted == 2)
        assert(s.heroes[1].gear[4].stats.strength == 10)
        assert(#s.inventory == 2 and s.inventory[1] == bag and bag.count == 7)
        assert(s.inventory[2] == old and old.protected)
        assert(math.abs(unit.hp / unit.maxHP - 0.4) < 0.00001 and unit.attackAt == attack)
        assert(G.Load(G.Copy(s), 1100))
    end
)
case("Chest auto equip shares duplicate stacks, retains ties and is opt-in", function()
    local s = state()
    G.AddHero(s, "WARRIOR")
    G.AddHero(s, "WARRIOR")
    for _, hero in ipairs(s.heroes) do
        hero.level = 60
    end
    s.settings.chestAutoEquip = true
    for _ = 1, 5 do
        G.StoreChest(s, cloak(s, { strength = 10 }))
    end
    local ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.equipped == 3 and report.disenchanted == 2)
    local previous = {}
    for index, hero in ipairs(s.heroes) do
        previous[index] = hero.gear[4]
        assert(previous[index].count == nil)
    end
    assert(previous[1].uid ~= previous[2].uid and previous[2].uid ~= previous[3].uid)
    G.StoreChest(s, cloak(s, { strength = 10 }))
    ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.equipped == 0 and report.disenchanted == 1 and report.powerGain == 0)
    for index, hero in ipairs(s.heroes) do
        assert(hero.gear[4] == previous[index])
    end
    local fresh = state()
    G.StoreChest(fresh, cloak(fresh, { strength = 10 }))
    assert(G.OpenChests(fresh, "all"))
    assert(fresh.heroes[1].gear[4] == nil and #fresh.inventory == 1)
    assert(G.Load(G.Copy(s), 1100))
end)
case("Chest auto equip can transfer existing gear to improve the whole party", function()
    local s = state()
    G.AddHero(s, "MAGE")
    s.heroes[2].level = 60
    local flexible = cloak(s, { strength = 10, intellect = 12 })
    s.heroes[1].gear[4] = flexible
    s.settings.chestAutoEquip = true
    G.StoreChest(s, cloak(s, { strength = 9 }))
    local ok, _, report = G.OpenChests(s, "all")
    assert(ok and report.equipped == 2 and report.disenchanted == 0)
    assert(s.heroes[2].gear[4] == flexible and s.heroes[1].gear[4].stats.strength == 9)
    assert(#s.inventory == 0)
end)
return cases
