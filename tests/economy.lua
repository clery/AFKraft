local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
local function party(level)
    local state = G.New(0)
    for _, zone in ipairs(C.zones) do
        state.professions.components[zone.id] = 1000
    end
    assert(G.AddHero(state, "WARRIOR"))
    state.heroes[1].level = level or 1
    assert(G.TalentProgress(state.heroes[1]))
    return state, state.heroes[1]
end

case("Routine equipment and heirlooms need no Essence at every production step", function()
    local state, hero = party(60)
    state.gold, state.legacy = 100000, 1
    for _, id in ipairs(C.materialOrder) do
        state.materials[id] = 100000
    end
    assert(state.essence == 0 and G.LevelCap(hero) == 60)
    assert(G.Craft(state, 1, 1, "ore", false))
    assert(hero.gear[1])
    local cost = G.UpgradeCost(hero.gear[1], state)
    assert(cost.essence == 0 and cost.gold > 0 and cost.materials.ore > 0)
    assert(G.Upgrade(state, 1, 1))
    assert(G.EnchantQuote(state, 1, 1, "offense"))
    assert(G.Enchant(state, 1, 1, "offense"))
    assert(G.Titanforge(state, 1, 1))
    state.difficulty.unlocked, state.difficulty.maxTier = true, 4
    assert(G.UnlockRecipe(state, 1))
    assert(G.Craft(state, 1, 1, "timber", true))
    assert(hero.gear[1].heirloom or state.inventory[#state.inventory].heirloom)
    assert(state.essence == 0 and state.gold < 100000 and state.materials.relic < 100000)
end)

case(
    "Equipment investment cannot refund its gold or idle material costs in a closed loop",
    function()
        local state, hero = party(60)
        state.essence, state.gold, state.materials.ore = 100000, 100000, 100000
        state.professions.ranks.crafting = 10
        G.ProfessionUnlocks(state)
        for _ = 1, 3 do
            assert(G.AllocateProfession(state, "crafting", "efficiency"))
        end
        for _ = 1, 10 do
            assert(G.BuyDevelopment(state, "provisioning"))
        end
        local essence, gold, ore = state.essence, state.gold, state.materials.ore
        for _ = 1, 20 do
            assert(G.Craft(state, 1, 1, "ore", false))
            local item = hero.gear[1]
            hero.gear[1] = nil
            state.inventory[#state.inventory + 1] = item
            local cost = G.Cost(state, hero, false)
            assert(cost.gold > 0 and cost.material > item.quality)
            assert(G.Disenchant(state, item))
        end
        assert(state.essence == essence and state.gold < gold and state.materials.ore < ore)
    end
)

case(
    "Development modifies actual combat and fractional rewards without minting Adventure XP",
    function()
        local base, hero = party(4)
        base.essence, base.stage, base.farming = 1000, 100, true
        local developed = G.Copy(base)
        for _, id in ipairs({ "might", "resolve", "provisioning" }) do
            assert(G.BuyDevelopment(developed, id))
        end
        local a, b = G.Stats(base, hero), G.Stats(developed, developed.heroes[1])
        assert(
            b.hp > a.hp
                and b.damage > a.damage
                and b.healing > a.healing
                and b.mitigation > a.mitigation
        )
        local function win(state)
            state.rest = 0
            G.StartBattle(state)
            local unit = state.battle.heroes[1]
            unit.hp = unit.maxHP * 0.3
            for _, enemy in ipairs(state.battle.enemies) do
                enemy.family = "humanoid" -- Keep this fractional-yield fixture independent of the roster.
                enemy.hp = 0
            end
            G.Step(state, 0.25)
        end
        for _ = 1, 5 do
            win(base)
            win(developed)
        end
        assert(developed.heroes[1].xp > base.heroes[1].xp)
        assert(math.abs(base.heroes[1].health - 0.36) < 0.000001)
        assert(math.abs(developed.heroes[1].health - 0.366) < 0.000001)
        assert(base.materials.timber == 31 and developed.materials.timber == 35)
        assert(
            base.heroes[1].mastery.rank == developed.heroes[1].mastery.rank
                and base.heroes[1].mastery.xp == developed.heroes[1].mastery.xp
        )
        assert(base.adventure.totalXP == 0 and developed.adventure.totalXP == 0)
        local wallet = developed.essence
        G.AdventureXP(developed, 100, "test", "Activity")
        assert(developed.essence == wallet + 60)
    end
)

case(
    "Economy migration credits evidenced training and retained investments exactly once",
    function()
        local old, hero = party()
        old.economyVersion = nil
        old.essence, old.gold, hero.rank = 1000, 90, 3
        local item = assert(G.Item(old, 1, 1, 2))
        item.upgrade, item.crafted, item.forge, item.forgePower = 3, true, 2, 0.08
        item.enchant = { id = "offense", level = 1, stats = { attackPower = 3 } }
        hero.gear[1] = item
        local loaded = assert(G.Load(old, 100))
        assert(old.economyVersion == nil and old.essence == 1000 and old.gold == 90)
        assert(loaded.essence == 1774 and loaded.gold == 330 and loaded.economyVersion == 1)
        local report = loaded.economyMigration
        assert(
            report.trainingEssence == 720
                and report.trainingGold == 240
                and report.equipmentEssence == 54
        )
        assert(report.ambiguousItems == 1 and report.fallbackCredit == 0)
        assert(loaded.heroes[1].gear[1].upgrade == 3 and loaded.heroes[1].gear[1].forge == 2)
        assert(loaded.stats.essence == 0 and loaded.adventure.totalXP == 0)
        loaded = assert(G.Load(loaded, 200))
        assert(loaded.essence == 1774 and loaded.gold == 330)
        loaded.prestigeUnlocked, loaded.runBest = true, 9
        assert(G.Prestige(loaded))
        assert(G.Load(loaded, 300).essence == 1774)
    end
)

case("Ambiguous historical spending receives the documented zero fallback", function()
    local old, hero = party()
    old.economyVersion, old.essence, hero.rank = nil, 100, 99
    local item = assert(G.Item(old, 1, 1, 2))
    item.crafted, item.forge, item.forgePower = true, 1, 0.04
    old.inventory[1] = item
    local loaded = assert(G.Load(old, 10))
    assert(loaded.essence == 100 and loaded.gold == 0)
    assert(
        loaded.economyMigration.ambiguousTraining == 1
            and loaded.economyMigration.ambiguousItems == 1
    )
    assert(loaded.economyMigration.fallbackCredit == 0)
end)

case("Invalid old saves cannot mark or partially pay an economy migration", function()
    local old, hero = party()
    old.economyVersion, old.essence, hero.rank = nil, 100, 1
    old.development.invested = 1
    assert(not G.Load(old, 10))
    assert(old.economyVersion == nil and old.essence == 100 and old.gold == 0)
    old.development.invested = 0
    local loaded = assert(G.Load(old, 10))
    assert(loaded.essence == 220 and loaded.gold == 80)
    old.inventory[1] = assert(G.Item(old, 1, 1, 2))
    old.inventory[1].count = "invalid"
    assert(not G.Load(old, 10))
    assert(old.economyVersion == nil and old.essence == 100)
end)

case("Duplicate item references cannot multiply migration credits", function()
    local old, hero = party()
    old.economyVersion = nil
    local item = assert(G.Item(old, 1, 1, 2))
    item.upgrade = 2
    old.inventory[1], hero.gear[1] = item, item
    local loaded = assert(G.Load(old, 10))
    assert(loaded.essence == 21 and loaded.economyMigration.equipmentEssence == 21)
end)

case("New economies never refund synthetic training ranks or future equipment", function()
    local state, hero = party()
    hero.rank = 14
    local item = assert(G.Item(state, 1, 1, 2))
    item.upgrade = 5
    hero.gear[1] = item
    assert(G.Load(state, 10).essence == 0 and state.economyMigration == nil)
    state.economyVersion = 2
    assert(not G.Load(state, 10))
end)

case("Unidentified legacy equipment cannot mint guessed credit or crash migration", function()
    for _, uid in ipairs({ 0, false, 0 / 0, "invalid" }) do
        local old = party()
        old.economyVersion = nil
        local item = assert(G.Item(old, 1, 1, 2))
        item.uid, item.upgrade = uid, 5
        old.inventory[1] = item
        local loaded = assert(G.Load(old, 10))
        assert(loaded.essence == 0 and loaded.economyMigration.ambiguousItems == 1)
    end
    local state = party()
    for _, report in ipairs({ false, {}, { fallbackCredit = 1 } }) do
        state.economyMigration = report
        assert(not G.Load(state, 10))
    end
end)

case("New runic recipes cannot receive retired historical Essence credits", function()
    local state, hero = party(60)
    state.economyVersion = nil
    local item = assert(G.CraftItem(hero, 1, false, state))
    item.uid = 1
    state.nextItem = 2
    item.enchant = { id = "runicFury", level = item.level, stats = { attackPower = 8 } }
    hero.gear[1] = item
    local loaded = assert(G.Load(state, 0))
    assert(loaded.essence == 0 and loaded.economyMigration.equipmentEssence == 0)
    assert(loaded.heroes[1].gear[1].enchant.id == "runicFury")
end)

return cases
