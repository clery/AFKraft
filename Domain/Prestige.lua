local _, W = ...
local G = W.Game
local max, floor = math.max, math.floor

function G.PrestigeReward(state)
    return max(0, floor((state.runBest - 1) / 3))
end

function G.Prestige(state)
    if not state.prestigeUnlocked then
        return false, "Defeat a level 8 milestone boss to unlock prestige."
    end
    state.battle, state.rest = nil, 0
    local reward = G.PrestigeReward(state)
    state.legacy = state.legacy + reward
    state.prestiges = state.prestiges + 1
    -- Strength bonuses are earned only by rewarded resets, never empty resets.
    if reward == 0 then
        state.prestiges = state.prestiges - 1
    end
    local retained = {}
    for _, item in ipairs(state.inventory) do
        if item.heirloom then
            retained[#retained + 1] = item
        end
    end
    for _, hero in ipairs(state.heroes) do
        hero.level, hero.xp, hero.rank, hero.health, hero.talents = 1, 0, 0, 1, {}
        for slot, item in pairs(hero.gear) do
            if not item.heirloom then
                hero.gear[slot] = nil
            end
        end
    end
    state.inventory = retained
    state.gold = 0
    state.materials = { timber = 0, hide = 0, ore = 0, relic = 0 }
    state.runBest, state.stage, state.zone, state.safe, state.farming = 1, 1, "elwynn", {}, false
    G.Log(state, "A new chapter begins. Earned " .. reward .. " Legacy. Unspent Essence retained.")
    G.Emit(state, "prestige")
    return true
end
