-- Run from the repository root: lua scripts/balance_scenarios.lua
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
local preferred = { WARRIOR = 3, PRIEST = 2, MAGE = 1, ROGUE = 2, SHAMAN = 3 }

local function party(level, prestiges, tier, mastery, heirlooms)
    local state = G.New(0)
    state.prestiges, state.tier, state.best = prestiges, tier, 60
    state.prestigeStrength = prestiges
    if tier > 0 then
        state.difficulty.unlocked, state.difficulty.maxTier = true, tier
    end
    state.guide.dismissed = true
    for _, class in ipairs({ "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }) do
        assert(G.AddHero(state, class))
        local hero = state.heroes[#state.heroes]
        hero.level, hero.rank = level, 0
        local progress = assert(G.TalentProgress(hero))
        hero.mastery.rank = mastery
        progress.earned = math.min(#G.TalentList(hero), progress.earned + mastery)
        if heirlooms then
            -- A completed talent budget retained from a capped previous adventure.
            local levelPoints = 1
                + math.floor((C.heroLevelCap - 1) / C.talentProgression.levelsPerPoint)
            progress.bestLevel, progress.levelPoints, progress.earned =
                C.heroLevelCap, levelPoints, #G.TalentList(hero)
            hero.mastery.rank = #G.TalentList(hero) - levelPoints
        end
        for _, slot in ipairs(C.equipmentSlots) do
            hero.gear[slot] = G.CraftItem(hero, slot, heirlooms, state)
                or assert(G.CraftItem(hero, slot, true, state))
        end
        for pass = 1, 3 do
            local path = (preferred[class] + pass - 2) % 3 + 1
            for _, talent in ipairs(G.TalentList(hero)) do
                if talent.path == path and not hero.talents[talent.id] then
                    G.Talent(state, hero.id, talent.id)
                end
            end
        end
        hero.priority = C.classByID[class].role == "healer" and "heal" or "special"
    end
    return state
end

local function encounter(level, prestiges, tier, mastery)
    local state = party(level, prestiges, tier, mastery, false)
    state.stage = level * 5
    G.StartBattle(state)
    local hp, damage = state.battle.enemies[1].hp, state.battle.enemies[1].damage
    local ticks = 0
    while state.battle and ticks < 720 do
        G.Step(state, 0.25)
        ticks = ticks + 1
    end
    local outcome = state.stats.victories > 0 and "win" or ticks >= 720 and "timeout" or "defeat"
    print(
        string.format(
            "%d | %d | %d | %d | %s | %.2f | %d | %.1f",
            level,
            prestiges,
            tier,
            mastery,
            outcome,
            ticks / 4,
            hp,
            damage
        )
    )
end

print(
    "Seed 0; five mixed heroes; same-level crafted gear; preferred legal talent paths; no boosts."
)
print("Level | Prestiges | Tier | Mastery ranks | Outcome | Seconds | Boss HP | Boss damage")
for _, level in ipairs({ 8, 20, 40, 60 }) do
    for _, prestiges in ipairs({ 0, 10, 40 }) do
        for _, tier in ipairs({ 0, 1 }) do
            encounter(level, prestiges, tier, 0)
            if level >= 20 then
                encounter(level, prestiges, tier, 8)
            end
        end
    end
end

print("Affix-tier checks: same level-60 party, 40 prestige strength, eight Mastery ranks.")
for _, tier in ipairs({ 2, 5, 8 }) do
    encounter(60, 40, tier, 8)
end

print(
    "Reset comparison: start level 1; retained full talent budget and heirlooms; natural growth to 60."
)
print("No fixture Essence or training is needed. Runs stop after 6000 simulation seconds.")
print(
    "Prestiges | Goal | Reached | Seconds | Hero level | Legacy | Legacy/min | Strength percentage/min"
)
for _, prestiges in ipairs({ 0, 10, 40 }) do
    for _, goal in ipairs({ 8, 12, 20 }) do
        local state = party(1, prestiges, 0, 47, true)
        local ticks = 0
        while state.runBest < goal and ticks < 24000 do
            G.Step(state, 0.25)
            ticks = ticks + 1
        end
        local seconds = ticks / 4
        local reward = G.PrestigeReward(state)
        print(
            string.format(
                "%d | %d | %d | %.2f | %d | %d | %.3f | %.3f",
                prestiges,
                goal,
                state.runBest,
                seconds,
                state.heroes[1].level,
                reward,
                reward / seconds * 60,
                reward * 2 / seconds * 60
            )
        )
    end
end
