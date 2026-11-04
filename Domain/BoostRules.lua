local _, W = ...
local L = W.L
local G, C = W.Game, W.Content
local conditions =
    { always = true, boss = true, lowHealth = true, farming = true, pushing = true, tier = true }

local function whole(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end

function G.ValidateBoostRules(rules)
    if rules == nil then
        return true
    end
    if type(rules) ~= "table" or #rules > 4 then
        return false
    end
    local count = 0
    for index, rule in pairs(rules) do
        if
            not whole(index, 1, #rules)
            or type(rule) ~= "table"
            or not conditions[rule.condition]
            or rule.action ~= "activate"
        then
            return false
        end
        count = count + 1
        for key in pairs(rule) do
            if key ~= "condition" and key ~= "threshold" and key ~= "action" then
                return false
            end
        end
        if rule.condition == "lowHealth" then
            if not whole(rule.threshold, 10, 90) then
                return false
            end
        elseif rule.condition == "tier" then
            if not whole(rule.threshold, 0, 10) then
                return false
            end
        elseif rule.threshold ~= nil then
            return false
        end
    end
    return count == #rules
end

function G.SetBoostRules(state, id, rules)
    if not C.boostByID[id] or not state.boosts.owned[id] then
        return false, L.LEARN_THIS_BOOST_FIRST
    end
    if not state.boosts.automation.owned.conditional then
        return false, L.LEARN_CONDITIONAL_AUTOMATION_FIRST
    end
    if not G.ValidateBoostRules(rules) then
        return false, L.USE_UP_TO_FOUR_VALID_ORDERED_ACTIVATION_RULES
    end
    state.boosts.automation.abilities[id].rules = G.Copy(rules or {})
    return true
end

function G.EvaluateBoostRules(state, id)
    local config = state.boosts.automation.abilities[id]
    local rules = config and config.rules
    if not G.ValidateBoostRules(rules) or not rules or #rules == 0 then
        return false, L.WAITING_NO_ORDERED_RULES
    end
    local battle = state.battle
    if not battle or (state.rest or 0) > 0 then
        return false, L.WAITING_COMBAT
    end
    local livingEnemy, livingAlly = false, false
    for _, enemy in ipairs(battle.enemies) do
        livingEnemy = livingEnemy or enemy.hp > 0
    end
    for _, ally in ipairs(battle.heroes) do
        livingAlly = livingAlly or ally.hp > 0
    end
    if not livingEnemy or not livingAlly then
        return false, L.WAITING_LIVING_COMBATANTS
    end
    for index, rule in ipairs(rules) do
        local matches = rule.condition == "always"
            or (rule.condition == "boss" and battle.boss == true)
            or (rule.condition == "farming" and state.farming == true)
            or (rule.condition == "pushing" and not state.farming)
            or (rule.condition == "tier" and (state.tier or 0) >= rule.threshold)
        if rule.condition == "lowHealth" then
            for _, ally in ipairs(battle.heroes) do
                if
                    ally.hp > 0
                    and ally.maxHP > 0
                    and ally.hp / ally.maxHP * 100 < rule.threshold
                then
                    matches = true
                    break
                end
            end
        end
        if matches then
            return true, L.RULE_PREFIX .. index .. L.READY_2, index
        end
    end
    return false, L.WAITING_NO_RULE_MATCHES
end
