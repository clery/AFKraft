local _, W = ...
local L = W.L
local G = W.Game
local max, floor = math.max, math.floor

function G.PrestigeReward(state)
    return max(0, floor((state.runBest - 1) / 3))
end

function G.ResetAdventure(state, deep)
    -- Capture every hero's record before any reset mutates their current level.
    for _, hero in ipairs(state.heroes) do
        local prepared = G.Copy(hero)
        local progress, errorMessage = G.TalentProgress(prepared)
        if not progress then
            return false, errorMessage
        end
        local mastery, masteryError = G.MasteryProgress(prepared)
        if not mastery then
            return false, masteryError
        end
    end
    state.battle, state.rest = nil, 0
    state.boosts.activeUntil = {}
    local retained = {}
    for _, item in ipairs(state.inventory) do
        if item.heirloom then
            retained[#retained + 1] = item
        end
    end
    for _, hero in ipairs(state.heroes) do
        G.TalentProgress(hero)
        G.MasteryProgress(hero)
        hero.level, hero.xp, hero.rank, hero.health = 1, 0, 0, 1
        for slot, item in pairs(hero.gear) do
            if not item.heirloom then
                hero.gear[slot] = nil
            end
        end
    end
    state.inventory = retained
    for _, hero in ipairs(state.heroes) do
        G.ReturnUnusableGear(state, hero)
    end
    state.professions.fragments = 0
    state.gold = 0
    state.materials = { timber = 0, hide = 0, ore = 0, relic = 0 }
    state.materialRemainders = {}
    state.runBest, state.stage, state.zone, state.safe, state.farming = 1, 1, "elwynn", {}, false
    G.ResetRouteRun(state)
    if state.difficulty then
        state.difficulty.cycleComplete = false
        state.difficulty.finalBossEncounter = 0
    end
    if deep and state.professions then
        for _, id in ipairs({ "crafting", "enchanting", "titanforging" }) do
            state.professions.ranks[id], state.professions.xp[id] = 0, 0
        end
    end
    return true
end

function G.Prestige(state)
    if not state.prestigeUnlocked then
        return false, L["Defeat a level 8 milestone boss to unlock prestige."]
    end
    local reward = G.PrestigeReward(state)
    local strength = state.prestigeStrength or state.prestiges
    local ok, reason = G.ResetAdventure(state, false)
    if not ok then
        return false, reason
    end
    state.legacy = state.legacy + reward
    if reward > 0 then
        state.prestiges = state.prestiges + 1
        state.prestigeStrength = strength + reward / 2
    end
    G.Log(
        state,
        L["A new chapter begins. Earned "] .. reward .. L[" Heritage. Unspent Essence retained."],
        nil,
        "progress"
    )
    G.Emit(state, "prestige")
    return true
end
