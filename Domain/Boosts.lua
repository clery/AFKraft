local _, W = ...
local G, C = W.Game, W.Content
local max = math.max

local function validTime(value)
    return type(value) == "number" and value >= 0 and value < math.huge
end

function G.ValidateBoosts(state)
    local boosts = state.boosts
    if
        not validTime(state.clock)
        or type(boosts.owned) ~= "table"
        or type(boosts.readyAt) ~= "table"
        or type(boosts.activeUntil) ~= "table"
        or (boosts.equipped ~= nil and not C.boostByID[boosts.equipped])
    then
        return false
    end
    for id, owned in pairs(boosts.owned) do
        if not C.boostByID[id] or owned ~= true then
            return false
        end
    end
    if boosts.equipped and not boosts.owned[boosts.equipped] then
        return false
    end
    for _, ledger in ipairs({ boosts.readyAt, boosts.activeUntil }) do
        for id, deadline in pairs(ledger) do
            if not boosts.owned[id] or not validTime(deadline) then
                return false
            end
        end
    end
    local active = 0
    for id, deadline in pairs(boosts.activeUntil) do
        if deadline > (boosts.readyAt[id] or 0) then
            return false
        end
        if deadline > state.clock then
            active = active + 1
        end
    end
    return active <= 1
end

function G.BuyBoost(state, id)
    local boost = C.boostByID[id]
    if not boost then
        return false, "Unknown commander boost."
    end
    if state.boosts.owned[id] then
        return false, "This boost is already learned."
    end
    if state.essence < boost.cost then
        return false, "Not enough Essence to learn this boost."
    end
    state.essence = state.essence - boost.cost
    state.boosts.owned[id] = true
    state.boosts.equipped = state.boosts.equipped or id
    G.Log(state, boost.name .. " learned permanently. Equip it in Commander.")
    return true
end

function G.EquipBoost(state, id)
    if not C.boostByID[id] or not state.boosts.owned[id] then
        return false, "Learn this boost first."
    end
    state.boosts.equipped = id
    return true
end

function G.BoostRemaining(state, id)
    return max(0, (state.boosts.activeUntil[id] or 0) - state.clock),
        max(0, (state.boosts.readyAt[id] or 0) - state.clock)
end

function G.CanActivateBoost(state, id)
    if not C.boostByID[id] or not state.boosts.owned[id] then
        return false, "Learn this boost first."
    end
    if state.boosts.equipped ~= id then
        return false, "Equip this boost first."
    end
    local active, cooldown = G.BoostRemaining(state, id)
    if active > 0 then
        return false, "Already active."
    end
    if cooldown > 0 then
        return false, "Cooling down."
    end
    for activeID in pairs(state.boosts.activeUntil) do
        if G.BoostRemaining(state, activeID) > 0 then
            return false, "Another boost is still active."
        end
    end
    local eligible = false
    if state.battle then
        for _, unit in ipairs(state.battle.heroes) do
            eligible = eligible or unit.hp > 0
        end
    else
        for _, hero in ipairs(state.heroes) do
            eligible = eligible or (hero.health or 1) > 0
        end
    end
    if not eligible then
        return false, "No living party members."
    end
    return true, "Ready."
end

function G.ActivateBoost(state, id)
    local eligible, reason = G.CanActivateBoost(state, id)
    if not eligible then
        return false, reason
    end
    local boost = C.boostByID[id]
    state.boosts.activeUntil[id] = state.clock + boost.duration
    state.boosts.readyAt[id] = state.clock + boost.cooldown
    G.Log(state, boost.name .. " active for five adventure minutes.")
    return true
end

-- Use only the portion of this simulation step that precedes expiry.
function G.BoostStepFraction(state, id, seconds)
    local untilTime = state.boosts.activeUntil[id] or 0
    return math.min(seconds, max(0, untilTime - state.clock)) / seconds
end
