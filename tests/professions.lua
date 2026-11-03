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
    G.AddHero(s, "WARRIOR")
    local hero = s.heroes[1]
    hero.level = level or 50
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
    hero.level = 40
    assert(G.ProfessionUnlocks(s).titanforging)
    hero.level = 50
    assert(G.ProfessionUnlocks(s).research)
    hero.level = 1
    hero.talentProgress.bestLevel = 1
    assert(G.ProfessionUnlocks(s).research and s.professions.bestLevel == 50)
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
        assert(stats.attackPower == 30 and stats.spellPower == 30)
        stats.attackPower = 9999
        assert(item.enchant.stats.attackPower == 30)
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
            preview.forge == rank and cost.gold > 0 and cost.essence > 0 and cost.materials.ore > 0
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
    assert(not G.Craft(s, 1, 1, "ore", false) and s.professions.xp.crafting == 10)
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
        assert(G.DifficultyVictory(s, { boss = true, level = 60 }))
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

return cases
