local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function party()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    return s
end
local function win(s)
    G.StartBattle(s)
    for _, enemy in ipairs(s.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(s, 0.25)
end
local function plan(s, destination, trigger)
    s.legacy = 1
    assert(G.BuyRoutes(s))
    local ok, id = G.SaveRoute(s, nil, "Plan", { { destination = destination, trigger = trigger } })
    assert(ok and G.SelectRoute(s, id) and G.SetRoutesEnabled(s, true))
end

case("Resolved route waits farm safely while an unfinished boss trigger keeps advancing", function()
    local s = party()
    plan(s, "removed_destination", { kind = "unlock", zone = "elwynn" })
    win(s)
    assert(s.farming and s.stage == s.safe.elwynn and s.routes.run.cursor == 1)
    s = party()
    plan(s, "westfall", { kind = "level", hero = 1, level = 1 })
    win(s)
    assert(s.farming and s.stage == 1)
    s = party()
    plan(s, "westfall", { kind = "boss", zone = "elwynn", stage = 10 })
    win(s)
    assert(not s.farming and s.stage == 2 and s.routes.run.cursor == 1)
end)

case(
    "Collection ledgers, fractional materials and serials reconcile through interrupted offline work",
    function()
        local s = party()
        local hero = s.heroes[1]
        hero.level, hero.rank = 20, 4
        G.TalentProgress(hero)
        s.zone, s.stage, s.farming, s.safe.westfall = "westfall", 1, true, 1
        local collection = C.collections[1]
        for i = 1, 4 do
            s.collectionBook.pieces[collection.pieces[i]] = 0
        end
        s.collectionBook.counters[collection.id] = { [0] = 29 }
        local job = assert(G.BeginCatchup(s, 120))
        local online = G.Copy(job.state)
        for _ = 1, 240 do
            G.Step(online, 0.25)
        end
        G.CatchupBatch(job, 240)
        G.FinishCatchup(s, job)
        assert(s.gold == online.gold and s.encounter == online.encounter)
        assert(s.materials.ore == online.materials.ore)
        assert(
            math.abs((s.materialRemainders.ore or 0) - (online.materialRemainders.ore or 0))
                < 0.000001
        )
        assert(s.collectionBook.lastEncounter == online.collectionBook.lastEncounter)
        for _, id in ipairs(collection.pieces) do
            assert(s.collectionBook.pieces[id] == online.collectionBook.pieces[id])
        end
        assert(
            s.collectionBook.counters[collection.id][0]
                == online.collectionBook.counters[collection.id][0]
        )
        s = assert(G.Load(G.Copy(s), 120))
        local previous = s.collectionBook.lastEncounter
        job = assert(G.BeginCatchup(s, 120))
        assert(job.seconds == 60)
        while not G.CatchupBatch(job, 200) do
        end
        G.FinishCatchup(s, job)
        assert(
            s.collectionBook.lastEncounter > previous
                and s.encounter >= s.collectionBook.lastEncounter
        )
        local receipt = s.collectionBook.lastEncounter
        s.rest = 0
        win(s)
        assert(s.collectionBook.lastEncounter > receipt)
        assert(s.lastOfflineSummary.boostUses == 0 and not s.offline)
    end
)

case("Offline summaries show partial Mastery XP and resource gains without a claim", function()
    local s = party()
    local hero = s.heroes[1]
    hero.level, hero.rank = 20, 4
    G.TalentProgress(hero)
    hero.mastery.rank, hero.mastery.xp = 0, 90
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 120))
    local earned = job.state
    assert(G.RewardMastery(earned.heroes[1], 20, 25, false) == 25)
    earned.materials.ore = earned.materials.ore + 3
    earned.gold = earned.gold + 7
    earned.stats.salvaged = earned.stats.salvaged + 2
    job.remaining = job.remaining - 240
    G.FinishCatchup(s, job)
    local summary = s.lastOfflineSummary
    assert(summary.masteryRanks == 1 and summary.masteryXP == 25)
    assert(summary.materials.ore == 3 and summary.gold == 7 and summary.salvaged == 2)
    assert(summary.routeTransitions == 0 and not summary.routesWaiting)
    assert(s.lastTime == 60 and s.log[#s.log]:find("1 minutes away", 1, true))
end)

case("Future collection watermarks refuse loading without discarding the account", function()
    local s = party()
    s.collectionBook.lastEncounter = 100
    s.essence = 123
    assert(not G.Load(s, 1) and s.essence == 123)
end)

case("Tier Mastery frontiers migrate base records and retain each harder frontier", function()
    local s = party()
    local hero = s.heroes[1]
    hero.level, hero.rank = 20, 4
    G.TalentProgress(hero)
    hero.mastery = { rank = 0, xp = 0, frontier = 30 }
    assert(G.MasteryProgress(hero).frontiers[0] == 30)
    assert(G.RewardMastery(hero, 3, 10, false, 0) == 0)
    assert(G.RewardMastery(hero, 3, 10, false, 1) == 10)
    assert(G.MasteryFrontier(hero, 0) == 30 and G.MasteryFrontier(hero, 1) == 3)
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s))
    assert(G.RewardMastery(hero, 2, 10, false, 1) == 0)
    assert(G.Load(s, 20))
    assert(G.MasteryFrontier(hero, 0) == 30 and G.MasteryFrontier(hero, 1) == 3)
end)

case(
    "Crafting specialization previews match transactions and cannot return their Essence costs",
    function()
        local s = party()
        local hero = s.heroes[1]
        hero.level, hero.rank = 50, 12
        G.TalentProgress(hero)
        G.ProfessionUnlocks(s)
        s.professions.ranks.crafting = 10
        assert(G.AllocateProfession(s, "crafting", "efficiency"))
        assert(G.AllocateProfession(s, "crafting", "precision"))
        s.gold, s.essence, s.materials.ore = 100000, 100000, 100000
        local preview = assert(G.CraftItem(hero, 1, false, s))
        local quote, before = G.Cost(s, hero, false), s.essence
        local xp = s.professions.xp.crafting
        assert(G.Craft(s, 1, 1, "ore", false))
        local actual = s.inventory[#s.inventory]
        assert(G.ItemPower(actual, hero) == G.ItemPower(preview, hero))
        assert(s.essence == before - quote.essence and s.professions.xp.crafting == xp + 10)
        assert(G.Disenchant(s, actual, 1))
        assert(s.essence == before - quote.essence)
    end
)

case(
    "Alternative boost purchases share ownership and damage/healing boosts preserve cooldowns",
    function()
        local s = party()
        s.legacy = 2
        assert(G.BuyBoost(s, "focusedAssault", "legacy"))
        s.essence = 60
        assert(not G.BuyBoost(s, "focusedAssault"))
        assert(s.essence == 60 and s.legacy == 1)
        G.StartBattle(s)
        local unit, enemy = s.battle.heroes[1], s.battle.enemies[1]
        unit.damage, unit.cd, unit.attackCD, unit.regen = 100, 3, 0, 0
        enemy.hp, enemy.maxHP, enemy.attackCD = 10000, 10000, 10
        enemy.x, enemy.y = unit.x, unit.y
        local ordinary = G.Copy(s)
        assert(G.ActivateBoost(s, "focusedAssault"))
        G.Step(s, 0.25)
        G.Step(ordinary, 0.25)
        assert(10000 - enemy.hp > 10000 - ordinary.battle.enemies[1].hp)
        assert(unit.cd == ordinary.battle.heroes[1].cd)
        local healing = party()
        G.AddHero(healing, "PRIEST")
        G.AddHero(healing, "MAGE")
        healing.essence = 60
        assert(G.BuyBoost(healing, "restorativeFocus"))
        G.StartBattle(healing)
        for _, actor in ipairs(healing.battle.heroes) do
            actor.cd, actor.attackCD, actor.regen = 10, 10, 0
        end
        healing.battle.heroes[1].hp, healing.battle.heroes[1].maxHP = 1, 1000
        healing.battle.heroes[2].cd, healing.battle.heroes[2].healing = 0, 100
        healing.battle.heroes[3].hp = 0
        for _, actor in ipairs(healing.battle.enemies) do
            actor.attackCD = 10
        end
        ordinary = G.Copy(healing)
        assert(G.ActivateBoost(healing, "restorativeFocus"))
        G.Step(healing, 0.25)
        G.Step(ordinary, 0.25)
        assert(healing.battle.heroes[1].hp > ordinary.battle.heroes[1].hp)
        assert(healing.battle.heroes[3].hp == 0)
    end
)

case(
    "Detailed loot policies keep matching class slot and stats without bypassing protection",
    function()
        local s = party()
        s.salvage.minQuality, s.salvage.keepUpgrades, s.salvage.keepEffects = 4, false, false
        assert(G.SetLootPolicy(s, "class", "WARRIOR"))
        assert(G.SetLootPolicy(s, "slot", 1))
        assert(G.SetLootPolicy(s, "stat", "strength"))
        assert(not G.SetLootPolicy(s, "class", "unknown"))
        local item = G.Item(s, 1, 1, 1, false, C.itemByID[25])
        item.stats.strength = 5
        G.Loot(s, item)
        assert(s.inventory[1] == item)
        item = G.Item(s, 1, 1, 1, false, C.itemByID[25])
        G.Loot(s, item)
        assert(#s.inventory == 1 and s.stats.salvaged == 1)
        item = G.Item(s, 1, 1, 1, false, C.itemByID[25])
        item.protected = true
        G.Loot(s, item)
        assert(#s.inventory == 2)
        assert(G.Load(G.Copy(s), 10))
    end
)

case("Class presets remain free and preserve a live encounter and progress", function()
    local s = party()
    G.StartBattle(s)
    local battle, unit = s.battle, s.battle.heroes[1]
    unit.hp, unit.cd, unit.attackCD = 1, 2, 1
    assert(G.ConfigurePreset(s, 1, "offense"))
    assert(s.heroes[1].priority == "attack" and s.heroes[1].specialCount == 1)
    assert(s.battle == battle and unit.hp == 1 and unit.cd == 2 and unit.attackCD == 1)
    assert(not G.ConfigurePreset(s, 1, "unknown"))
    assert(s.essence == 0 and s.gold == 0)
end)

case("Invalid saved item investments refuse loading without resetting currencies", function()
    local s = party()
    local item = G.Item(s, 1, 1, 1)
    s.heroes[1].gear[1] = item
    s.essence = 99
    item.forge, item.forgePower = 1, 0 / 0
    assert(not G.Load(G.Copy(s), 0) and s.essence == 99)
    item.forgePower = 0.04
    item.enchant = { id = "offense", stats = { weaponDPS = 100 } }
    assert(not G.Load(G.Copy(s), 0))
end)

return cases
