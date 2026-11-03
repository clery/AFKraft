-- Run from the repository root: lua scripts/balance_rebuild.lua
-- Fixed-seed feasibility checks, not a substitute for supported-client playtests.
local W = {}
for _, file in ipairs({
    "Content.lua",
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
    "Domain/Collections.lua",
    "Domain/HuntSession.lua",
    "Compatibility/CollectionSources.lua",
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
    assert(loadfile(file))("WoWIdle", W)
end
local G, C = W.Game, W.Content
local horizon = 7200
local classes = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }
local modes = { "Ordinary tier0", "Deep tier0 control", "Deep tier1 challenge" }

local function equal(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if not equal(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

local function heirlooms(state)
    local result = {}
    for _, hero in ipairs(state.heroes) do
        for _, item in pairs(hero.gear) do
            if item.heirloom then
                result[item.uid] = G.Copy(item)
            end
        end
    end
    for _, item in ipairs(state.inventory) do
        if item.heirloom then
            result[item.uid] = G.Copy(item)
        end
    end
    return result
end

local function established(seed)
    local state = G.New(0)
    state.seed, state.best, state.runBest = seed, 60, 60
    -- Declared prior-account fixture, not a claim about resources earned en route.
    state.gold, state.legacy, state.essence = 100000, 20, 180
    for _, material in ipairs(C.materialOrder) do
        state.materials[material] = 2000
    end
    for _, branch in ipairs(C.development) do
        assert(G.BuyDevelopment(state, branch.id))
    end
    for _, slot in ipairs(C.equipmentSlots) do
        assert(G.UnlockRecipe(state, slot))
    end
    for index, class in ipairs(classes) do
        assert(G.AddHero(state, class))
        local hero = state.heroes[index]
        hero.level = 60
        assert(G.TalentProgress(hero))
        for _, talent in ipairs(G.TalentList(hero)) do
            G.Talent(state, index, talent.id)
        end
        hero.priority = C.classByID[class].role == "healer" and "heal" or "special"
        for _, slot in ipairs(C.equipmentSlots) do
            assert(G.Craft(state, index, slot, "ore", true))
            assert(G.Equip(state, index, #state.inventory))
        end
        assert(G.Enchant(state, index, 1, "offense"))
        assert(G.Titanforge(state, index, 1))
    end
    assert(G.AllocateProfession(state, "crafting", "efficiency"))
    assert(G.AllocateProfession(state, "enchanting", "offense"))
    assert(G.AllocateProfession(state, "titanforging", "potential"))
    assert(G.Craft(state, 1, 1, "ore", false)) -- Ordinary investment must be lost.
    state.prestigeUnlocked, state.stage, state.safe.elwynn = true, 300, 300
    state.encounter = state.encounter + 1
    assert(G.DifficultyVictory(state, { boss = true, level = 60 }))
    assert(G.Load(G.Copy(state), 0))
    return state
end

local function reset(state, mode)
    local prior = G.Copy(state)
    local kept = heirlooms(state)
    local reward
    if mode == 1 then
        reward = G.PrestigeReward(state)
        assert(G.Prestige(state))
        assert(state.legacy == prior.legacy + reward and state.tier == 0)
    else
        local preview = G.PrestigePlusPreview(state, mode == 2 and 0 or 1)
        assert(preview.eligible and preview.inheritance == 1)
        reward = preview.inheritance
        assert(G.PrestigePlus(state, preview.targetTier))
        assert(state.difficulty.currency == prior.difficulty.currency + reward)
        assert(state.legacy == prior.legacy and state.tier == preview.targetTier)
    end
    assert(equal(kept, heirlooms(state)), "Reset lost or changed heirloom investment")
    for _, key in ipairs({
        "development",
        "adventure",
        "recipes",
        "outdoorCollections",
        "dungeonCollections",
        "boostProfiles",
    }) do
        assert(equal(state[key], prior[key]), "Reset changed permanent " .. key)
    end
    assert(equal(state.professions.owned, prior.professions.owned))
    assert(equal(state.professions.allocations, prior.professions.allocations))
    assert(equal(state.professions.recipes, prior.professions.recipes))
    assert(equal(state.routes.templates, prior.routes.templates))
    assert(equal(state.boosts.owned, prior.boosts.owned))
    assert(state.gold == 0 and state.professions.fragments == 0 and state.runBest == 1)
    for _, material in ipairs(C.materialOrder) do
        assert(state.materials[material] == 0)
    end
    for _, item in ipairs(state.inventory) do
        assert(item.heirloom)
    end
    for index, hero in ipairs(state.heroes) do
        assert(hero.level == 1 and hero.xp == 0 and hero.name == prior.heroes[index].name)
        assert(equal(hero.talents, prior.heroes[index].talents))
    end
    for _, profession in ipairs(C.professions) do
        local id = profession.id
        assert(state.professions.ranks[id] == (mode == 1 and prior.professions.ranks[id] or 0))
        assert(state.professions.xp[id] == (mode == 1 and prior.professions.xp[id] or 0))
    end
    return reward
end

local function affordable(state, cost)
    if state.gold < cost.gold then
        return false
    end
    for material, count in pairs(cost.materials or {}) do
        if state.materials[material] < count then
            return false
        end
    end
    return true
end

local function equip(state, index, metrics)
    local before = G.Copy(state.heroes[index].gear)
    G.EquipBest(state, index)
    if not equal(before, state.heroes[index].gear) then
        metrics.commands = metrics.commands + 1
    end
end

local function checkin(state, metrics)
    metrics.checkins = metrics.checkins + 1
    for index, hero in ipairs(state.heroes) do
        -- Successful state-changing commands count; this is not measured UI clicks.
        equip(state, index, metrics)
        local opportunity = G.CraftingOpportunity(state, index)
        if opportunity then
            local cost = G.Cost(state, hero, opportunity.heirloom)
            assert(
                G.Craft(state, index, opportunity.slot, opportunity.material, opportunity.heirloom)
            )
            metrics.crafts, metrics.commands = metrics.crafts + 1, metrics.commands + 1
            metrics.goldSpent = metrics.goldSpent + cost.gold
            metrics.spent[opportunity.material] = metrics.spent[opportunity.material]
                + cost.material
            equip(state, index, metrics)
        end
        -- One meaningful weapon modification per check-in, no deliberate work-XP churn.
        local item = hero.gear[1]
        if item then
            local preview, cost
            local kind
            if not item.enchant then
                preview, cost = G.EnchantQuote(state, index, 1, "offense")
                kind = "enchants"
            elseif (item.forge or 0) < C.forgeCap then
                preview, cost = G.ForgeQuote(state, index, 1)
                kind = "forges"
            end
            if preview and cost then
                if affordable(state, cost) then
                    assert(
                        kind == "enchants" and G.Enchant(state, index, 1, "offense")
                            or kind == "forges" and G.Titanforge(state, index, 1)
                    )
                    metrics[kind], metrics.commands = metrics[kind] + 1, metrics.commands + 1
                    metrics.goldSpent = metrics.goldSpent + cost.gold
                    for material, count in pairs(cost.materials) do
                        metrics.spent[material] = metrics.spent[material] + count
                    end
                else
                    metrics.unaffordable = metrics.unaffordable + 1
                end
            end
        end
    end
    if state.farming and G.Retry(state) then
        metrics.commands = metrics.commands + 1
    end
end

local function run(seed, mode)
    local state = established(seed)
    local startingRanks = G.Copy(state.professions.ranks)
    local reward = reset(state, mode)
    local metrics = {
        checkins = 0,
        commands = 1,
        crafts = 0,
        enchants = 0,
        forges = 0,
        unaffordable = 0,
        goldSpent = 0,
        spent = { timber = 0, hide = 0, ore = 0, relic = 0 },
        reached = {},
        defeats = 0,
        ranksBefore = startingRanks,
    }
    for second = 1, horizon do
        G.Advance(state, 1)
        for _, event in ipairs(state.events) do
            if event.kind == "defeat" then
                metrics.defeats = metrics.defeats + 1
            end
        end
        state.events = {}
        for _, goal in ipairs({ 20, 40, 60 }) do
            if state.runBest >= goal then
                metrics.reached[goal] = metrics.reached[goal] or second
            end
        end
        if second % 900 == 0 then
            checkin(state, metrics)
        end
    end
    assert(state.adventure.totalXP == 0 and state.essence == 0)
    assert(state.gold >= 0)
    for _, material in ipairs(C.materialOrder) do
        assert(state.materials[material] >= 0)
    end
    assert(G.Load(G.Copy(state), horizon))
    metrics.frontier, metrics.gold = state.runBest, state.gold
    metrics.ranks = G.Copy(state.professions.ranks)
    metrics.balances = G.Copy(state.materials)
    metrics.victories = state.stats.victories
    metrics.reward = reward
    metrics.rewardUnit = mode == 1 and "Legacy" or "Inheritance"
    return metrics
end

local function time(value)
    return value and string.format("%.2f", value / 60) or ">120"
end
local function ranks(values)
    return string.format("%d/%d/%d", values.crafting, values.enchanting, values.titanforging)
end
print(
    "Actual resets; declared five level-60 heroes, legal retained level talents, no Mastery/collections/boosts."
)
print(
    "Prior fixture: 100000 gold, 2000 of each material, 20 Legacy, 180 Essence; paid board rank1 each, ten heirloom recipes, 50 crafts, five weapon enchants/forges and one ordinary craft."
)
print(
    "Setup budget is not earned-progression evidence; reset discards remaining gold/materials/ordinary gear. No post-reset funding or real activity."
)
print(
    "Seeds17/91; two hours online simulation, 15-minute check-ins. Same policy; ordinary earns Legacy strength, deep0 holds tier0, deep1 adds tier1 challenge/rewards. These are not equivalent permanent-power states."
)
print(
    "Commands count successful state changes, not observed UI clicks; unaffordable counts quotes deferred without payment. Repeated runs must match exactly."
)
print(
    "Mode | Seed | Frontier20/40/60 minutes | Frontier | Reward | Checkins/commands | Craft/enchant/forge | Deferred | Gold spent/held | Materials spent T/H/O/R | Held T/H/O/R | Ranks before -> after C/E/F | Wins/defeats"
)
for _, seed in ipairs({ 17, 91 }) do
    for mode, label in ipairs(modes) do
        local result = run(seed, mode)
        assert(equal(result, run(seed, mode)), "Nondeterministic rebuild metrics")
        print(
            string.format(
                "%s | %d | %s/%s/%s | %d | %s | %d/%d | %d/%d/%d | %d | %d/%d | %d/%d/%d/%d | %d/%d/%d/%d | %s -> %s | %d/%d",
                label,
                seed,
                time(result.reached[20]),
                time(result.reached[40]),
                time(result.reached[60]),
                result.frontier,
                result.reward .. " " .. result.rewardUnit,
                result.checkins,
                result.commands,
                result.crafts,
                result.enchants,
                result.forges,
                result.unaffordable,
                result.goldSpent,
                result.gold,
                result.spent.timber,
                result.spent.hide,
                result.spent.ore,
                result.spent.relic,
                result.balances.timber,
                result.balances.hide,
                result.balances.ore,
                result.balances.relic,
                ranks(result.ranksBefore),
                ranks(result.ranks),
                result.victories,
                result.defeats
            )
        )
    end
end
print(
    "PASS deterministic replay, paid transactions, reset losses and permanent/heirloom/plan retention."
)
