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
    return active <= 1 and G.ValidateBoostAutomation(state)
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

function G.ActivateBoost(state, id, quiet)
    local eligible, reason = G.CanActivateBoost(state, id)
    if not eligible then
        return false, reason
    end
    local boost = C.boostByID[id]
    state.boosts.activeUntil[id] = state.clock + boost.duration
    state.boosts.readyAt[id] = state.clock + boost.cooldown
    G.Log(state, boost.name .. " active for five adventure minutes.", quiet)
    return true
end

-- Use only the portion of this simulation step that precedes expiry.
function G.BoostStepFraction(state, id, seconds)
    local untilTime = state.boosts.activeUntil[id] or 0
    return math.min(seconds, max(0, untilTime - state.clock)) / seconds
end

function G.ValidateBoostAutomation(state)
    local automation = state.boosts.automation
    if
        type(automation) ~= "table"
        or type(automation.owned) ~= "table"
        or type(automation.enabled) ~= "boolean"
        or type(automation.abilities) ~= "table"
        or (automation.enabled and not automation.owned.onCooldown)
        or (automation.owned.conditional and not automation.owned.onCooldown)
    then
        return false
    end
    for capability, owned in pairs(automation.owned) do
        if not C.boostAutomation[capability] or owned ~= true then
            return false
        end
    end
    for id in pairs(automation.abilities) do
        if not C.boostByID[id] then
            return false
        end
    end
    for _, boost in ipairs(C.boosts) do
        local config = automation.abilities[boost.id]
        if type(config) ~= "table" then
            return false
        end
        local mode = C.boostAutomationModeByID[config.mode]
        if
            type(config.enabled) ~= "boolean"
            or not mode
            or (mode.capability and not automation.owned[mode.capability])
            or (config.enabled and not automation.owned.onCooldown)
            or ((config.enabled or config.mode ~= "manual") and not state.boosts.owned[boost.id])
            or type(config.healthBelow) ~= "number"
            or config.healthBelow < 10
            or config.healthBelow > 90
            or config.healthBelow ~= math.floor(config.healthBelow)
        then
            return false
        end
    end
    return true
end

function G.BuyBoostAutomation(state, capability)
    local unlock = C.boostAutomation[capability]
    local automation = state.boosts.automation
    if not unlock then
        return false, "Unknown automation capability."
    end
    if automation.owned[capability] then
        return false, "This automation capability is already learned."
    end
    if capability == "conditional" and not automation.owned.onCooldown then
        return false, "Learn on-cooldown automation first."
    end
    if state[unlock.currency] < unlock.cost then
        return false, "Not enough Legacy to learn this automation capability."
    end
    state[unlock.currency] = state[unlock.currency] - unlock.cost
    automation.owned[capability] = true
    G.Log(state, unlock.name .. " boost automation learned permanently. Configure it in Commander.")
    return true
end

function G.SetBoostAutomationEnabled(state, enabled)
    if type(enabled) ~= "boolean" then
        return false, "Choose whether boost automation is enabled."
    end
    local automation = state.boosts.automation
    if enabled and not automation.owned.onCooldown then
        return false, "Learn on-cooldown automation first."
    end
    automation.enabled = enabled
    return true
end

function G.ConfigureBoostAutomation(state, id, key, value)
    local automation = state.boosts.automation
    if not C.boostByID[id] or not state.boosts.owned[id] then
        return false, "Learn this boost first."
    end
    if key == "enabled" then
        if type(value) ~= "boolean" then
            return false, "Choose whether this boost is automated."
        end
        if value and not automation.owned.onCooldown then
            return false, "Learn on-cooldown automation first."
        end
    elseif key == "mode" then
        local mode = C.boostAutomationModeByID[value]
        if not mode then
            return false, "Unknown automation mode."
        end
        if mode.capability and not automation.owned[mode.capability] then
            return false, "Learn the matching automation capability first."
        end
    elseif key == "healthBelow" then
        if type(value) ~= "number" or value < 10 or value > 90 or value ~= math.floor(value) then
            return false, "Choose a whole health threshold from 10 to 90 percent."
        end
    else
        return false, "Unknown automation setting."
    end
    automation.abilities[id][key] = value
    if key == "enabled" and value and automation.abilities[id].mode == "manual" then
        -- A first opt-in gets a useful default; existing conditional choices stay intact.
        automation.abilities[id].mode = "onCooldown"
    end
    return true
end

function G.BoostAutomationStatus(state, id)
    local automation = state.boosts.automation
    local config = automation.abilities[id]
    if not config or not state.boosts.owned[id] then
        return false, "Learn this boost first."
    end
    if not automation.owned.onCooldown then
        return false, "Automation not learned."
    end
    if not automation.enabled then
        return false, "Automation paused."
    end
    if not config.enabled then
        return false, "Disabled for this boost."
    end
    if config.mode == "manual" then
        return false, "Manual mode."
    end
    local ready, reason = G.CanActivateBoost(state, id)
    if not ready then
        return false, reason
    end
    local battle = state.battle
    local livingEnemy = false
    if battle then
        for _, enemy in ipairs(battle.enemies) do
            livingEnemy = livingEnemy or enemy.hp > 0
        end
    end
    if not livingEnemy or (state.rest or 0) > 0 then
        return false, "Waiting for combat."
    end
    if config.mode == "boss" and not battle.boss then
        return false, "Waiting for a boss encounter."
    elseif config.mode == "farming" and not state.farming then
        return false, "Waiting for safe farming."
    elseif config.mode == "pushing" and state.farming then
        return false, "Waiting for frontier pushing."
    elseif config.mode == "lowHealth" then
        local belowThreshold = false
        for _, unit in ipairs(battle.heroes) do
            if
                unit.hp > 0
                and unit.maxHP > 0
                and unit.hp / unit.maxHP * 100 < config.healthBelow
            then
                belowThreshold = true
                break
            end
        end
        if not belowThreshold then
            return false, "Waiting for a living ally below " .. config.healthBelow .. "% health."
        end
    end
    return true, "Ready to activate automatically."
end

function G.AutomateBoost(state)
    local id = state.boosts.equipped
    if id and G.BoostAutomationStatus(state, id) then
        -- Revalidate through the manual command; a prior manual request owns its cooldown.
        -- Routine automated activations stay in the bounded journal, without announcements.
        return G.ActivateBoost(state, id, true)
    end
    return false
end
