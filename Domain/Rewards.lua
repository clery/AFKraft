local _, W = ...
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
    G.Log(state, "+" .. amount .. " Essence · " .. label)
    return true
end

function G.ActivityReward(state, key, kind, label)
    local reward = W.Content.activityRewards[kind]
    if not reward or not claim(state, key) then
        return false
    end
    return G.AdventureXP(state, reward.xp, kind, label)
end
