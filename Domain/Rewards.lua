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
    G.Log(state, "+" .. amount .. L.FRAGMENT_ESSENCE .. label, nil, "rewards")
    return true
end

function G.ActivityReward(state, key, kind, label)
    local reward = W.Content.activityRewards[kind]
    if not reward or not claim(state, key) then
        return false
    end
    local result, essence = G.AdventureXP(state, reward.xp, kind, label)
    local now = W.Client and W.Client.Now() or state.lastTime
    G.JournalActivity(state, kind == "skinning" and "gather" or kind, now)
    return result, essence
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

-- Income follows successful encounter time, so faster trivial fights cannot raise its rate.
function G.AccrueEncounterRewards(state, zone, battle, difficulty, materials)
    local seconds = battle.elapsed + 2.25 -- Two seconds of rest and one simulation tick to start.
    local gold = (3 + zone.level * 2) * seconds / 10 * difficulty.gold + state.combatGoldRemainder
    state.combatGoldRemainder = gold % 1
    local pending = state.chestRewardProgress[zone.id] or { gold = 0, relic = 0 }
    state.chestRewardProgress[zone.id] = pending
    pending.gold = pending.gold + (1 + zone.level) * seconds / 10 * difficulty.gold
    pending.relic = pending.relic + (1 + zone.level) * seconds / 40 * materials
    local relic = (1 + zone.level) * seconds / 40 * materials
        + (state.materialRemainders.relic or 0)
    state.materialRemainders.relic = relic % 1
    state.materials.relic = state.materials.relic + math.floor(relic)
    return math.floor(gold)
end

function G.ClaimChestRewards(state, item)
    local pending = state.chestRewardProgress[state.zone]
    item.disenchantGold, item.disenchantRelic = math.floor(pending.gold), math.floor(pending.relic)
    pending.gold, pending.relic = pending.gold % 1, pending.relic % 1
end
