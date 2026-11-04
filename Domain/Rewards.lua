local _, W = ...
local L = W.L
local G = W.Game

local function claim(state, key)
    if state.seenRewards[key] then
        return false
    end
    state.seenRewards[key] = true
    state.rewardOrder[#state.rewardOrder + 1] = key
    if #state.rewardOrder > 512 then
        state.seenRewards[table.remove(state.rewardOrder, 1)] = nil
    end
    return true
end

function G.Reward(state, key, amount, label)
    if not claim(state, key) then
        return false
    end
    state.essence = state.essence + amount
    state.stats.essence = state.stats.essence + amount
    G.Log(state, "+" .. amount .. L[" Essence · "] .. label, nil, "rewards")
    return true
end

function G.ActivityReward(state, key, kind, label)
    local reward = W.Content.activityRewards[kind]
    if not reward or not claim(state, key) then
        return false
    end
    return G.AdventureXP(state, reward.xp, kind, label)
end

-- Base destination output plus a bounded share from explicitly tagged enemies.
function G.EncounterMaterials(zone, battle)
    local base = battle.boss and 5 or 1
    local result = { [zone.material] = base }
    local count = #battle.enemies
    if count == 0 then
        return result
    end
    for _, enemy in ipairs(battle.enemies) do
        local material = W.Content.familyMaterials[enemy.family]
        if material then
            result[material] = (result[material] or 0)
                + base * W.Content.familyMaterialYield / count
        end
    end
    return result
end
