-- Run from the repository root: lua scripts/balance_builds.lua
-- Synthetic retained-work snapshots; no elapsed acquisition-time estimates.
local W = {}
assert(loadfile("Localization.lua"))("AFKraft", W)
assert(loadfile("Locales/enUS.lua"))("AFKraft", W)
for _, file in ipairs({
    "Content.lua",
    "Content/Encounters.lua",
    "Content/TalentTraits.lua",
    "Content/TalentExpansion.lua",
    "Content/Backdrops.lua",
    "Content/Items.lua",
    "Content/Boosts.lua",
    "Content/Resources.lua",
    "Content/Collections.lua",
    "Content/Professions.lua",
    "Content/Development.lua",
    "Domain/State.lua",
    "Domain/Development.lua",
    "Domain/Economy.lua",
    "Domain/Boosts.lua",
    "Domain/BoostRules.lua",
    "Domain/Party.lua",
    "Domain/Resources.lua",
    "Domain/Mastery.lua",
    "Domain/Inventory.lua",
    "Domain/Chests.lua",
    "Domain/Collections.lua",
    "Domain/Routes.lua",
    "Domain/Profiles.lua",
    "Domain/Professions.lua",
    "Domain/Difficulty.lua",
    "Domain/Prestige.lua",
    "Domain/Adventure.lua",
    "Domain/Rewards.lua",
    "Simulation/Positioning.lua",
    "Simulation/Combat.lua",
    "Simulation/Offline.lua",
}) do
    assert(loadfile(file))("AFKraft", W)
end
local G, C = W.Game, W.Content

local budget = { gold = 1000000, ore = 100000, relic = 100000 }
local compositions = {
    {
        name = "mixed-offense",
        classes = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" },
        path = 1,
        enchant = "offense",
    },
    {
        name = "ranged-control",
        classes = { "WARRIOR", "PRIEST", "HUNTER", "MAGE", "WARLOCK" },
        path = 3,
        enchant = "offense",
    },
    {
        name = "support-survival",
        classes = { "PALADIN", "PRIEST", "DRUID", "WARRIOR", "WARLOCK" },
        path = 2,
        enchant = "defense",
    },
}
local function paid(state, cost, command)
    local before = {
        gold = state.gold,
        essence = state.essence,
        fragments = state.professions.fragments,
        materials = G.Copy(state.materials),
    }
    assert(command())
    assert(state.gold == before.gold - cost.gold and state.essence == before.essence)
    assert(state.professions.fragments == before.fragments - (cost.fragments or 0))
    for material, held in pairs(before.materials) do
        assert(state.materials[material] == held - ((cost.materials or {})[material] or 0))
    end
    assert(state.gold >= 0 and state.materials.ore >= 0 and state.materials.relic >= 0)
end
local function setup(seed, level, tier, composition, professionPlan)
    local s = G.New(0)
    s.seed, s.gold, s.prestigeStrength = seed, budget.gold, 1000
    s.materials.ore, s.materials.relic = budget.ore, budget.relic
    s.tier = tier
    s.difficulty.maxTier, s.difficulty.unlocked = tier, tier > 0
    s.professions.bestLevel = 60
    for _, kind in ipairs({ "crafting", "enchanting", "titanforging" }) do
        s.professions.ranks[kind] = 7
    end
    assert(G.ProfessionUnlocks(s).research)
    if professionPlan == "specialized" then
        for _, choice in ipairs({
            { "crafting", "precision" },
            { "enchanting", composition.enchant },
            { "titanforging", "potential" },
        }) do
            for _ = 1, 3 do
                assert(G.AllocateProfession(s, choice[1], choice[2]))
            end
        end
    end
    for _, class in ipairs(composition.classes) do
        assert(G.AddHero(s, class))
        local index, hero = #s.heroes, s.heroes[#s.heroes]
        hero.level, hero.mastery.rank = level, 8
        local progress = assert(G.TalentProgress(hero))
        progress.earned =
            math.min(G.TalentLimit(hero), progress.earned + math.floor(8 / C.mastery.ranksPerPoint))
        for pass = 0, 2 do
            local path = (composition.path + pass - 1) % 3 + 1
            for _, talent in ipairs(G.TalentList(hero)) do
                if talent.path == path then
                    G.Talent(s, index, talent.id)
                end
            end
        end
        local preset = composition.name == "support-survival" and "support"
            or (class == "PRIEST" and "support" or "offense")
        assert(G.ConfigurePreset(s, index, preset))
        assert(G.Configure(s, index, "resourceThreshold", 0))
        for _, slot in ipairs(C.equipmentSlots) do
            local cost = G.Cost(s, hero, false)
            paid(s, { gold = cost.gold, materials = { ore = cost.material } }, function()
                return G.Craft(s, index, slot, "ore", false)
            end)
            assert(G.Equip(s, index, #s.inventory))
            local _, enchantCost = G.EnchantQuote(s, index, slot, composition.enchant)
            assert(enchantCost)
            paid(s, enchantCost, function()
                return G.Enchant(s, index, slot, composition.enchant)
            end)
            for _ = 1, 2 do
                local _, forgeCost = G.ForgeQuote(s, index, slot)
                assert(forgeCost)
                paid(s, forgeCost, function()
                    return G.Titanforge(s, index, slot)
                end)
            end
        end
    end
    assert(s.essence == 0 and s.legacy == 0 and s.professions.fragments == 0)
    assert(G.ValidateProfessions(s) and G.ValidateCollections(s))
    return s,
        {
            gold = budget.gold - s.gold,
            ore = budget.ore - s.materials.ore,
            relic = budget.relic - s.materials.relic,
        }
end
local function run(seed, level, tier, composition, professionPlan)
    local s, spent = setup(seed, level, tier, composition, professionPlan)
    s.stage = level * 5
    G.StartBattle(s)
    assert(s.battle and s.battle.boss and s.battle.level == level)
    -- Reapplying the requested controls mid-fight cannot heal or restart timers.
    local unit, hero = s.battle.heroes[1], s.heroes[1]
    local originalHP, originalCD, originalAttackCD = unit.hp, unit.cd, unit.attackCD
    unit.hp, unit.cd, unit.attackCD = unit.maxHP * 0.75, 1.25, 1.75
    local hp, cd, attackCD = unit.hp, unit.cd, unit.attackCD
    assert(
        G.ConfigurePreset(s, 1, composition.name == "support-survival" and "support" or "offense")
    )
    assert(G.Configure(s, 1, "resourceThreshold", 0))
    assert(unit.hp == hp and unit.cd == cd and unit.attackCD == attackCD)
    -- Restore the shared full-health starting condition after the isolated settings invariant.
    unit.hp, unit.cd, unit.attackCD = originalHP, originalCD, originalAttackCD
    hero.health = 1
    local gold, materials = s.gold, G.Copy(s.materials)
    local ticks, maximum = 0, 721
    while s.battle and ticks < maximum do
        G.Step(s, 0.25)
        ticks = ticks + 1
        s.events = {}
    end
    assert(not s.battle and ticks <= maximum)
    local wins = s.stats.victories
    local outcome = wins == 1 and "win"
        or (s.lastDefeat and s.lastDefeat:find("timed out", 1, true) and "timeout" or "wipe")
    assert(wins == 0 or wins == 1)
    assert(tier > 2 or wins == 1, "Baseline and early-tier funded builds must remain viable")
    assert(s.stats.boostUses == 0 and s.essence == 0)
    assert(G.ValidateProfessions(s))
    assert(next(s.outdoorCollections.pieces) == nil and next(s.dungeonCollections.pieces) == nil)
    local reward = s.materials.ore
        - materials.ore
        + s.materials.timber
        - materials.timber
        + s.materials.hide
        - materials.hide
        + s.materials.relic
        - materials.relic
    assert(s.gold - gold >= 0 and reward >= 0)
    if wins == 0 then
        assert(s.gold == gold and reward == 0)
    end
    return string.format(
        "%d | %d | %d | %s | %s | %s | %.2f | %d | %.2f | %d | %d | %d",
        seed,
        level,
        tier,
        composition.name,
        professionPlan,
        outcome,
        ticks / 4,
        s.gold - gold,
        reward,
        spent.gold,
        spent.ore,
        spent.relic
    )
end
print(
    "Synthetic equal initial budgets: 1,000,000 gold; 100,000 ore; 100,000 Relic dust. Unspent balances retained; costs reported, not equalized."
)
print(
    "Both levels40/60 assume lifetime profession access60, retained work rank7 per profession, prestige strength1000 and eight Mastery ranks."
)
print(
    "All cases pay real commands: ten crafted/enchant slots per hero, two forge ranks each. No heirlooms, board, collections, boosts or Runic recipes."
)
print(
    "Unallocated profession plan vs precision3, matching enchant branch3 and potential3. Talents fill preferred path then remaining paths legally; resource threshold0."
)
print(
    "Same-level single boss; no later edits/retries. Bounded180.25s. Every row replayed. No fixture acquisition-time or general viability claims."
)
print(
    "Seed | Hero level | Tier | Composition | Profession plan | Outcome | Seconds | Gold reward | Material reward | Gold spent | Ore spent | Relic spent"
)
for _, seed in ipairs({ 1, 42 }) do
    for _, level in ipairs({ 40, 60 }) do
        for _, tier in ipairs({ 0, 2, 5, 8 }) do
            for _, composition in ipairs(compositions) do
                for _, professionPlan in ipairs({ "unallocated", "specialized" }) do
                    local result = run(seed, level, tier, composition, professionPlan)
                    assert(
                        result == run(seed, level, tier, composition, professionPlan),
                        "Build replay must be deterministic"
                    )
                    print(result)
                end
            end
        end
    end
end
