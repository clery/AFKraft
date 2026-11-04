local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function party(level)
    local s = G.New(0)
    for _, zone in ipairs(C.zones) do
        s.professions.components[zone.id] = 1000
    end
    G.AddHero(s, "WARRIOR")
    local hero = s.heroes[1]
    hero.level = level or 60
    assert(G.TalentProgress(hero))
    s.gold, s.essence, s.legacy = 1000000, 1000000, 100
    for _, material in ipairs(C.materialOrder) do
        s.materials[material] = 1000000
    end
    local item = assert(G.CraftItem(hero, 1, false))
    item.uid, item.upgrade = s.nextItem, 2
    s.nextItem = s.nextItem + 1
    hero.gear[1] = item
    assert(G.ValidateProfessions(s))
    return s, hero, item
end

case("Profession unlocks follow lifetime idle records and remain owned after reset", function()
    local s, hero = party(29)
    local owned = G.ProfessionUnlocks(s)
    assert(
        owned.crafting and not owned.enchanting and not owned.titanforging and not owned.research
    )
    hero.level = 30
    assert(G.ProfessionUnlocks(s).enchanting)
    hero.level = 49
    assert(not G.ProfessionUnlocks(s).titanforging)
    hero.level = 50
    assert(G.ProfessionUnlocks(s).titanforging)
    hero.level = 59
    assert(not G.ProfessionUnlocks(s).research)
    hero.level = 60
    assert(G.ProfessionUnlocks(s).research)
    hero.level = 1
    hero.talentProgress.bestLevel = 1
    assert(G.ProfessionUnlocks(s).research and s.professions.bestLevel == 60)
end)

case(
    "Enchanting previews are pure and payment grants one work credit and targeted stats",
    function()
        local s, hero, item = party()
        local preview, cost = G.EnchantQuote(s, 1, 1, "offense")
        assert(preview and cost and item.enchant == nil and s.professions.xp.enchanting == 0)
        assert(preview.upgrade == 2 and preview.uid == item.uid)
        local gold, essence, relic = s.gold, s.essence, s.materials.relic
        assert(G.Enchant(s, 1, 1, "offense"))
        assert(
            s.gold == gold - cost.gold
                and s.essence == essence - cost.essence
                and s.materials.relic == relic - cost.materials.relic
        )
        assert(s.professions.xp.enchanting == 10 and s.professions.ranks.enchanting == 0)
        assert(item.enchant.id == "offense" and item.upgrade == 2 and not item.forge)
        local stats = G.ProfessionStatBonus(item, hero)
        assert(stats.attackPower == 36 and stats.spellPower == 36)
        stats.attackPower = 9999
        assert(item.enchant.stats.attackPower == 36)
        assert(not G.Enchant(s, 1, 1, "offense"))
        assert(s.professions.xp.enchanting == 10)
        assert(G.Enchant(s, 1, 1, "defense"))
        assert(item.enchant.id == "defense" and not item.enchant.stats.attackPower)
        assert(s.professions.ranks.enchanting == 1 and s.professions.xp.enchanting == 0)
    end
)

case("Modification failures preserve all resources, equipment and profession ranks", function()
    local s, _, item = party(29)
    local gold, essence = s.gold, s.essence
    assert(not G.Enchant(s, 1, 1, "offense"))
    assert(not G.Titanforge(s, 1, 1))
    assert(not G.Enchant(s, 99, 1, "offense"))
    assert(not G.Enchant(s, 1, 1, "unknown"))
    assert(
        s.gold == gold
            and s.essence == essence
            and item.enchant == nil
            and s.professions.xp.enchanting == 0
    )
    local rich = party()
    local equipment = rich.heroes[1].gear[1]
    rich.materials.relic = 0
    local before = G.Copy(rich.professions)
    assert(not G.Enchant(rich, 1, 1, "offense"))
    assert(not G.Titanforge(rich, 1, 1))
    assert(
        rich.gold == 1000000
            and rich.essence == 1000000
            and equipment.enchant == nil
            and not equipment.forge
    )
    assert(
        rich.professions.xp.enchanting == before.xp.enchanting
            and rich.professions.xp.titanforging == before.xp.titanforging
    )
    equipment.count = 2
    rich.materials.relic = 1000000
    assert(not G.Enchant(rich, 1, 1, "offense") and not G.Titanforge(rich, 1, 1))
end)

case("Titanforging is capped, additive potential separate from enhancement and enchant", function()
    local s, _, item = party()
    assert(G.Enchant(s, 1, 1, "utility"))
    local enchant = item.enchant
    for rank = 1, 5 do
        local preview, cost = G.ForgeQuote(s, 1, 1)
        assert(
            preview.forge == rank and cost.gold > 0 and cost.essence == 0 and cost.materials.ore > 0
        )
        assert(item.forge == (rank > 1 and rank - 1 or nil))
        assert(G.Titanforge(s, 1, 1))
        assert(
            item.forge == rank and math.abs(G.ForgeMultiplier(item) - (1 + rank * 0.04)) < 0.000001
        )
        assert(item.upgrade == 2 and item.enchant == enchant)
    end
    local gold, xp = s.gold, s.professions.xp.titanforging
    assert(not G.Titanforge(s, 1, 1))
    assert(
        s.gold == gold and s.professions.xp.titanforging == xp and G.ForgeMultiplier(item) <= 1.275
    )
end)

case(
    "Profession specializations spend independent points and saved plans reactivate after rebuilding",
    function()
        local s, hero = party()
        local combatPoints = G.Points(hero)
        assert(not G.AllocateProfession(s, "crafting", "precision"))
        for _ = 1, 35 do
            assert(G.ProfessionWork(s, "crafting"))
        end
        assert(s.professions.ranks.crafting >= 7)
        assert(G.AllocateProfession(s, "crafting", "efficiency"))
        assert(G.AllocateProfession(s, "crafting", "precision"))
        assert(G.AllocateProfession(s, "crafting", "precision"))
        assert(G.AllocateProfession(s, "crafting", "precision"))
        assert(not G.AllocateProfession(s, "crafting", "precision"))
        assert(not G.AllocateProfession(s, "crafting", "speed"))
        local mods = G.ProfessionModifiers(s, "crafting")
        assert(
            mods.costMultiplier < 1 and mods.statMultiplier > 1 and G.Points(hero) == combatPoints
        )
        s.professions.ranks.crafting, s.professions.xp.crafting = 0, 0
        assert(G.ValidateProfessions(s))
        mods = G.ProfessionModifiers(s, "crafting")
        assert(mods.costMultiplier == 1 and mods.statMultiplier == 1)
        assert(s.professions.allocations.crafting.precision == 3)
        assert(G.ProfessionWork(s, "crafting"))
        assert(G.ProfessionWork(s, "crafting"))
        assert(G.ProfessionModifiers(s, "crafting").costMultiplier < 1)
        assert(G.ResetProfessionAllocations(s, "crafting"))
        assert(next(s.professions.allocations.crafting) == nil)
    end
)

case("Profession rank caps and invalid saved ledgers are bounded", function()
    local s = party()
    for _ = 1, 1000 do
        G.ProfessionWork(s, "enchanting")
    end
    assert(s.professions.ranks.enchanting == 30 and s.professions.xp.enchanting == 0)
    assert(not G.ProfessionWork(s, "unknown"))
    assert(G.ValidateProfessions(s))
    local invalid = G.Copy(s)
    invalid.professions.allocations.enchanting.offense = 4
    assert(not G.ValidateProfessions(invalid))
    invalid = G.Copy(s)
    invalid.professions.xp.enchanting = 1
    assert(not G.ValidateProfessions(invalid))
    invalid = G.Copy(s)
    invalid.professions.owned.unknown = true
    assert(not G.ValidateProfessions(invalid))
    invalid = G.Copy(s)
    invalid.professions.ranks.crafting = 0 / 0
    assert(not G.ValidateProfessions(invalid))
    local migrated = G.Copy(s)
    migrated.professions = {}
    assert(
        G.ValidateProfessions(migrated)
            and migrated.professions.ranks.crafting == 0
            and migrated.professions.owned.research
    )
end)

case("Heirloom enchant and forge investments survive ordinary prestige", function()
    local s, hero = party()
    local item = assert(G.CraftItem(hero, 1, true))
    item.uid = s.nextItem
    s.nextItem = s.nextItem + 1
    hero.gear[1] = item
    assert(G.Enchant(s, 1, 1, "offense"))
    assert(G.Titanforge(s, 1, 1))
    local investment = item.forgePower
    s.prestigeUnlocked, s.runBest = true, 8
    assert(G.Prestige(s))
    assert(hero.gear[1] == item and item.enchant.id == "offense" and item.forgePower == investment)
    assert(s.professions.owned.research and s.professions.xp.enchanting == 10)
end)

case(
    "Forge and enchanting specializations change quoted output without changing existing investment",
    function()
        local s, _, item = party()
        s.professions.ranks.enchanting, s.professions.ranks.titanforging = 10, 10
        assert(G.AllocateProfession(s, "enchanting", "offense"))
        local preview = G.EnchantQuote(s, 1, 1, "offense")
        assert(preview.enchant.stats.attackPower > 30)
        assert(G.AllocateProfession(s, "titanforging", "potential"))
        assert(G.Titanforge(s, 1, 1))
        local multiplier = G.ForgeMultiplier(item)
        assert(multiplier > 1.04)
        assert(G.ResetProfessionAllocations(s, "titanforging"))
        assert(G.ForgeMultiplier(item) == multiplier)
        local base = G.ForgeQuote(s, 1, 1)
        assert(base.forgePower > item.forgePower)
    end
)

case("Craft specialization previews match paid output and credit work only once", function()
    local s, hero = party()
    s.professions.ranks.crafting = 10
    assert(G.AllocateProfession(s, "crafting", "efficiency"))
    assert(G.AllocateProfession(s, "crafting", "quality"))
    assert(G.AllocateProfession(s, "crafting", "quality"))
    assert(G.AllocateProfession(s, "crafting", "quality"))
    local preview = assert(G.CraftItem(hero, 1, false, s))
    local cost = G.Cost(s, hero, false)
    local gold, essence, material = s.gold, s.essence, s.materials.ore
    assert(cost.gold < hero.level * 8)
    assert(G.Craft(s, 1, 1, "ore", false))
    local item = s.inventory[#s.inventory]
    assert(
        G.ItemPower(item, hero) == G.ItemPower(preview, hero) and item.quality == preview.quality
    )
    assert(s.professions.xp.crafting == 10)
    assert(
        s.gold == gold - cost.gold
            and s.essence == essence - cost.essence
            and s.materials.ore == material - cost.material
    )
    s.essence = 0
    assert(G.Craft(s, 1, 1, "ore", false) and s.professions.xp.crafting == 20)
    s.materials.ore = 0
    assert(not G.Craft(s, 1, 1, "ore", false) and s.professions.xp.crafting == 20)
end)

case(
    "Prestige+ retains profession ownership, saved allocations and heirloom modifications",
    function()
        local s, hero = party(60)
        local item = assert(G.CraftItem(hero, 1, true, s))
        item.uid = s.nextItem
        s.nextItem = s.nextItem + 1
        hero.gear[1] = item
        s.professions.ranks.enchanting = 7
        assert(G.AllocateProfession(s, "enchanting", "offense"))
        assert(G.Enchant(s, 1, 1, "offense"))
        assert(G.Titanforge(s, 1, 1))
        local invested, flat = item.forgePower, item.enchant.stats.attackPower
        s.encounter = s.encounter + 1
        assert(G.DifficultyVictory(s, { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }))
        assert(G.PrestigePlus(s, 1))
        assert(s.professions.ranks.enchanting == 0 and s.professions.xp.enchanting == 0)
        assert(s.professions.allocations.enchanting.offense == 1 and s.professions.owned.enchanting)
        assert(G.ProfessionModifiers(s, "enchanting").enchantOffense == 1)
        assert(
            hero.gear[1] == item
                and item.forgePower == invested
                and item.enchant.stats.attackPower == flat
        )
        assert(math.abs(G.ProfessionStatBonus(item, hero).attackPower - flat / 60) < 0.000001)
        assert(G.Load(G.Copy(s), 10))
    end
)

case("Tier bosses unlock permanent runic recipes and count each encounter once", function()
    local s = party()
    s.tier, s.difficulty.maxTier, s.difficulty.unlocked = 2, 2, true
    assert(not G.EnchantQuote(s, 1, 1, "runicFury"))
    s.encounter = 1
    G.DifficultyVictory(s, { boss = true, level = 20 })
    assert(s.professions.fragments == 1 and s.professions.recipes.runicFury)
    G.DifficultyVictory(s, { boss = true, level = 20 })
    assert(s.professions.fragments == 1)
    s.tier, s.difficulty.maxTier, s.encounter = 8, 8, 2
    G.DifficultyVictory(s, { boss = true, level = 20 })
    assert(s.professions.recipes.runicFortitude and s.professions.recipes.runicClarity)
    s.professions.fragments = C.runicFragmentCap
    s.encounter = 3
    assert(G.ProfessionBossRewards(s, { boss = true, level = 20 }))
    assert(s.professions.fragments == C.runicFragmentCap)
    assert(G.Load(G.Copy(s), 0))
    for _, bad in ipairs({ -1, 0.5, C.runicFragmentCap + 1 }) do
        local invalid = G.Copy(s)
        invalid.professions.fragments = bad
        assert(not G.ValidateProfessions(invalid))
    end
end)

case(
    "Runic enchantment payment is atomic and cannot charge identical modifications twice",
    function()
        local s, _, item = party()
        s.professions.recipes.runicFury = true
        local preview, cost = G.EnchantQuote(s, 1, 1, "runicFury")
        assert(preview and cost.fragments == 3 and cost.essence == 0)
        local base = assert(G.EnchantQuote(s, 1, 1, "offense"))
        assert(preview.enchant.stats.attackPower > base.enchant.stats.attackPower)
        local gold, relic, essence = s.gold, s.materials.relic, s.essence
        s.professions.fragments = 2
        assert(not G.Enchant(s, 1, 1, "runicFury"))
        assert(s.gold == gold and s.materials.relic == relic and item.enchant == nil)
        s.professions.fragments = 3
        assert(G.Enchant(s, 1, 1, "runicFury"))
        assert(s.professions.fragments == 0 and s.essence == essence)
        gold, relic = s.gold, s.materials.relic
        assert(not G.Enchant(s, 1, 1, "runicFury"))
        assert(s.gold == gold and s.materials.relic == relic)
    end
)

case("Offline bosses supply known runic work but cannot discover new recipes", function()
    local s = party()
    s.tier, s.encounter, s.offline = 8, 1, true
    assert(not G.ProfessionBossRewards(s, { boss = true, level = 20 }))
    assert(s.professions.fragments == 0 and next(s.professions.recipes) == nil)
    s.professions.recipes.runicFury = true
    s.encounter = 2
    assert(G.ProfessionBossRewards(s, { boss = true, level = 20 }))
    assert(s.professions.fragments == 1 and not s.professions.recipes.runicClarity)
    s.encounter = 3
    assert(not G.ProfessionBossRewards(s, { boss = true, level = 19 }))
    assert(not G.ProfessionBossRewards(s, { boss = false, level = 60 }))
    s.tier = 1
    assert(not G.ProfessionBossRewards(s, { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }))
end)

case("Runic resources reset while recipe ownership and receipt history survive", function()
    local s = party()
    s.professions.recipes.runicFury, s.professions.fragments = true, 9
    s.encounter, s.professions.lastFragmentEncounter = 8, 8
    assert(G.ResetAdventure(s, false))
    assert(s.professions.fragments == 0 and s.professions.recipes.runicFury)
    assert(s.professions.lastFragmentEncounter == 8)
    s.professions.fragments = 3
    assert(G.ResetAdventure(s, true))
    assert(s.professions.fragments == 0 and s.professions.recipes.runicFury)
    local old = G.Copy(s)
    old.professions.fragments, old.professions.recipes, old.professions.lastFragmentEncounter =
        nil, nil, nil
    local loaded = assert(G.Load(old, 0))
    assert(loaded.professions.fragments == 0 and next(loaded.professions.recipes) == nil)
    assert(old.professions.fragments == nil)
end)

case("Runic offline boss rewards reconcile once into return totals", function()
    local s = party(60)
    s.tier, s.difficulty.maxTier, s.difficulty.unlocked = 2, 2, true
    s.professions.recipes.runicFury = true
    s.safe.elwynn, s.stage = 100, 100
    local job = assert(G.BeginCatchup(s, 60))
    G.StartBattle(job.state)
    for _, enemy in ipairs(job.state.battle.enemies) do
        enemy.hp = 0
    end
    G.CatchupBatch(job, 1)
    assert(job.state.professions.fragments == 1)
    assert(G.FinishCatchup(s, job))
    assert(s.professions.fragments == 1 and s.lastOfflineSummary.fragments == 1)
    assert(not G.FinishCatchup(s, job) and s.professions.fragments == 1)
    assert(not s.professions.recipes.runicFortitude)
    assert(G.Load(G.Copy(s), 60))
end)

case("Runic enchantments use their matching profession specialization", function()
    local s = party()
    s.professions.recipes.runicFury = true
    local base = assert(G.EnchantQuote(s, 1, 1, "runicFury"))
    s.professions.ranks.enchanting = 7
    s.professions.allocations.enchanting.defense = 3
    local unrelated = assert(G.EnchantQuote(s, 1, 1, "runicFury"))
    assert(unrelated.enchant.stats.attackPower == base.enchant.stats.attackPower)
    s.professions.allocations.enchanting = { offense = 3 }
    local specialized, cost = G.EnchantQuote(s, 1, 1, "runicFury")
    assert(
        math.abs(specialized.enchant.stats.attackPower - base.enchant.stats.attackPower * 1.3)
            < 0.00001
    )
    assert(cost.fragments == 3 and G.ValidateProfessions(s))
end)

case("Every zone trophy has a reachable specific forge recipe", function()
    local required = {}
    for rank = 1, C.forgeCap do
        for _, slot in ipairs(C.equipmentSlots) do
            for zone, count in pairs(G.ComponentCost("titanforging", slot, rank)) do
                assert(C.zoneByID[zone] and count == rank)
                required[zone] = true
            end
        end
    end
    for _, zone in ipairs(C.zones) do assert(required[zone.id]) end
    for _, enchant in ipairs(C.enchants) do
        local zone, count = next(G.ComponentCost("enchanting", 1, 1, enchant.id))
        assert(C.zoneComponents[zone] and count == 1)
    end
end)

case("Boss trophies are zone-specific, bounded and awarded once per encounter", function()
    local s = G.New(0)
    assert(G.AddHero(s, "WARRIOR"))
    s.encounter = 1
    G.DifficultyVictory(s, { boss = false, level = 1, zone = "westfall" })
    assert(not next(s.professions.components))
    s.encounter = 2
    local boss = { boss = true, level = 3, zone = "westfall" }
    G.DifficultyVictory(s, boss)
    G.DifficultyVictory(s, boss)
    assert(s.professions.components.westfall == 1 and not s.professions.components.elwynn)
    s.professions.components.westfall = C.componentCap
    s.encounter = 3
    G.DifficultyVictory(s, boss)
    assert(s.professions.components.westfall == C.componentCap)
    assert(G.Load(G.Copy(s), 0))
end)

case("Components are previewed, paid atomically and never returned by disenchanting", function()
    local s, _, item = party()
    local preview, cost = G.EnchantQuote(s, 1, 1, "offense")
    assert(preview and cost.components.westfall == 1)
    s.professions.components.westfall = 0
    local gold, relic, essence = s.gold, s.materials.relic, s.essence
    assert(not G.Enchant(s, 1, 1, "offense"))
    assert(s.gold == gold and s.materials.relic == relic and s.essence == essence and not item.enchant)
    s.professions.components.westfall = 1
    assert(G.Enchant(s, 1, 1, "offense"))
    assert(s.professions.components.westfall == 0)
    s.heroes[1].gear[1] = nil
    s.inventory[#s.inventory + 1] = item
    assert(G.Disenchant(s, item))
    assert(s.professions.components.westfall == 0)
end)

case("Component saves migrate empty, retain stock across both resets and reject malformed ledgers", function()
    local s = party()
    s.professions.components, s.professions.lastComponentEncounter = nil, nil
    s = assert(G.Load(G.Copy(s), 0))
    assert(not next(s.professions.components))
    s.professions.components.elwynn = 3
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s) and s.professions.components.elwynn == 3)
    assert(G.ResetAdventure(s, true) and s.professions.components.elwynn == 3)
    for _, value in ipairs({ -1, 0.5, math.huge, C.componentCap + 1, "1" }) do
        local bad = G.Copy(s)
        bad.professions.components.elwynn = value
        assert(not G.Load(bad, 0))
    end
    s.professions.components.missing_zone = 1
    assert(not G.Load(s, 0))
end)

case("Manual boss farming preserves earned checkpoints and reconciles interrupted offline trophies once", function()
    local s = party()
    s.runBest, s.safe.westfall, s.stage = 20, 17, 17
    assert(not G.FarmZoneBoss(s, "missing_zone"))
    assert(not G.FarmZoneBoss(s, "durotar"))
    s.lastDefeat = "Prior defeat"
    assert(G.FarmZoneBoss(s, "westfall"))
    assert(s.lastDefeat == nil)
    assert(s.farming and s.stage == 15 and s.safe.westfall == 17)
    local before = s.professions.components.westfall
    local job = assert(G.BeginCatchup(s, 600))
    assert(job.state.stage == 15)
    G.CatchupBatch(job, 1000)
    assert(G.FinishCatchup(s, job))
    assert(s.professions.components.westfall > before)
    assert(s.lastOfflineSummary.components.westfall == s.professions.components.westfall - before)
    local count = s.professions.components.westfall
    assert(not G.FinishCatchup(s, job) and s.professions.components.westfall == count)
    assert(G.Load(G.Copy(s), 600))
end)

return cases
