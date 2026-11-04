-- Run from the repository root: lua scripts/balance_automation.lua
-- Equal synthetic starting snapshots compare execution policies, not acquisition time.
local W = {}
assert(loadfile("Localization.lua"))("WoWIdle", W)
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
    assert(loadfile(file))("WoWIdle", W)
end
local G, C = W.Game, W.Content

local boostID, stepSeconds = "battleOrders", 0.25
local function snapshot(seed)
    local state = G.New(0)
    state.professions.bestLevel = 60 -- Established automation on a low-level rebuild.
    state.seed = seed
    state.gold, state.legacy = 100000, 4
    state.materials.ore = 10000
    state.best, state.stage = 20, 80
    for _, class in ipairs({ "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }) do
        assert(G.AddHero(state, class))
        local index = #state.heroes
        local hero = state.heroes[index]
        hero.level = 20
        assert(G.TalentProgress(hero))
        for _, talent in ipairs(G.TalentList(hero)) do
            if talent.path == 1 then
                G.Talent(state, index, talent.id)
            end
        end
        for _, slot in ipairs(C.equipmentSlots) do
            local cost = G.Cost(state, hero, false)
            local gold, ore = state.gold, state.materials.ore
            assert(G.Craft(state, index, slot, "ore", false))
            assert(state.gold == gold - cost.gold and state.materials.ore == ore - cost.material)
            assert(G.Equip(state, index, #state.inventory))
        end
        assert(G.ConfigurePreset(state, index, class == "PRIEST" and "support" or "offense"))
    end
    assert(G.BuyBoost(state, boostID, "legacy"))
    assert(G.BuyBoostAutomation(state, "onCooldown"))
    assert(G.BuyBoostAutomation(state, "conditional"))
    assert(state.legacy == 0 and state.essence == 0)
    assert(not G.BuyBoost(state, boostID, "legacy"))
    assert(not G.BuyBoostAutomation(state, "conditional"))
    assert(state.legacy == 0 and G.ValidateBoosts(state))
    return state
end

local function simulate(initial, policy, seconds)
    local state = G.Copy(initial)
    local automatic = policy == "on-cooldown" or policy == "conditional-boss"
    assert(G.ConfigureBoostAutomation(state, boostID, "enabled", automatic))
    assert(G.SetBoostAutomationEnabled(state, automatic))
    if policy == "conditional-boss" then
        assert(G.SetBoostRules(state, boostID, { { condition = "boss", action = "activate" } }))
    end
    local metrics = {
        uses = 0,
        attempts = 0,
        bossEntries = 0,
        defeats = 0,
        active = 0,
        combatActive = 0,
        combat = 0,
    }
    local activate, modifiers, emit = G.ActivateBoost, G.BoostModifiers, G.Emit
    local lastActivation, seenBattle = nil, nil
    local essence, legacy = state.essence, state.legacy
    G.ActivateBoost = function(s, id, quiet)
        local before = s.clock
        local ok, reason = activate(s, id, quiet)
        if ok then
            assert(s == state and id == boostID)
            assert(not lastActivation or before - lastActivation >= C.boostByID[id].cooldown)
            assert(s.boosts.readyAt[id] == before + C.boostByID[id].cooldown)
            assert(s.boosts.activeUntil[id] == before + C.boostByID[id].duration)
            if policy == "manual-boss-entry" or policy == "conditional-boss" then
                assert(s.battle and s.battle.boss)
            end
            lastActivation = before
            metrics.uses = metrics.uses + 1
        end
        return ok, reason
    end
    G.BoostModifiers = function(s, duration)
        local active = G.BoostStepFraction(s, boostID, duration) * duration
        metrics.active = metrics.active + active
        if s.battle and (s.rest or 0) <= 0 then
            metrics.combat = metrics.combat + duration
            metrics.combatActive = metrics.combatActive + active
        end
        return modifiers(s, duration)
    end
    G.Emit = function(s, kind, data)
        if kind == "defeat" then
            metrics.defeats = metrics.defeats + 1
        end
        return emit(s, kind, data)
    end
    local ok, problem = pcall(function()
        for _ = 1, seconds / stepSeconds do
            if state.battle and state.battle ~= seenBattle then
                seenBattle = state.battle
                if state.battle.boss then
                    metrics.bossEntries = metrics.bossEntries + 1
                    if policy == "manual-boss-entry" then
                        -- One attempt on boss entry, even when cooling down; no per-tick clicking.
                        metrics.attempts = metrics.attempts + 1
                        G.ActivateBoost(state, boostID)
                    end
                end
            end
            G.Step(state, stepSeconds)
            state.events = {}
        end
    end)
    G.ActivateBoost, G.BoostModifiers, G.Emit = activate, modifiers, emit
    assert(ok, problem)
    assert(state.clock == initial.clock + seconds)
    assert(state.essence == essence and state.legacy == legacy)
    assert(state.stats.boostUses - initial.stats.boostUses == metrics.uses)
    assert(metrics.combatActive <= metrics.active and metrics.active <= seconds)
    assert(metrics.combatActive <= metrics.combat and metrics.combat <= seconds)
    assert(policy ~= "no-boost" or (metrics.uses == 0 and metrics.active == 0))
    assert(G.ValidateBoosts(state) and G.ValidateCollections(state))
    metrics.wins = state.stats.victories - initial.stats.victories
    metrics.frontier, metrics.level = state.runBest, state.heroes[1].level
    metrics.gold = state.gold - initial.gold
    metrics.encounter = state.encounter - initial.encounter
    assert(metrics.encounter == metrics.wins + metrics.defeats + (state.battle and 1 or 0))
    return string.format(
        "%s | %d | %d | %.2f | %.2f | %.2f | %d | %d | %d | %d | %d | %d",
        policy,
        metrics.uses,
        metrics.attempts,
        metrics.active,
        metrics.combatActive,
        metrics.combat,
        metrics.wins,
        metrics.defeats,
        metrics.frontier,
        metrics.level,
        metrics.gold,
        metrics.bossEntries
    )
end

print(
    "Synthetic level-20 mixed party; paid same-level gear; identical ownership and 4-Legacy purchases in every policy."
)
print(
    "Three fixed seeds; natural frontier progression, no later gear/talent edits, retries, resets or route travel."
)
print(
    "Manual policy attempts once per boss entry, with perfect encounter observation; this is not measured player attention."
)
print(
    "Active/combat-active seconds integrate real per-step boost fractions, including automatic activations and expiry."
)
print(
    "No-boost keeps identical paid capabilities disabled. All policies pay no activation or recurring automation fees."
)
print(
    "Seed | Seconds | Policy | Uses | Manual attempts | Active seconds | Combat active seconds | Combat seconds | Wins | Defeats | Frontier | Warrior level | Gold gained | Boss entries"
)
for _, seed in ipairs({ 1, 42, 2026 }) do
    local initial = snapshot(seed)
    for _, seconds in ipairs({ 900, 3600 }) do
        for _, policy in ipairs({
            "no-boost",
            "manual-boss-entry",
            "on-cooldown",
            "conditional-boss",
        }) do
            local result = simulate(initial, policy, seconds)
            assert(
                result == simulate(initial, policy, seconds),
                "Policy replay must be deterministic"
            )
            print(string.format("%d | %d | %s", seed, seconds, result))
        end
    end
end
