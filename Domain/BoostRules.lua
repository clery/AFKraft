local _, W = ...
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
        return false, "Learn this boost first."
    end
    if not state.boosts.automation.owned.conditional then
        return false, "Learn conditional automation first."
    end
    if not G.ValidateBoostRules(rules) then
        return false, "Use up to four valid ordered activation rules."
    end
    state.boosts.automation.abilities[id].rules = G.Copy(rules or {})
    return true
end

function G.EvaluateBoostRules(state, id)
    local config = state.boosts.automation.abilities[id]
    local rules = config and config.rules
    if not G.ValidateBoostRules(rules) or not rules or #rules == 0 then
        return false, "Waiting: no ordered rules."
    end
    local battle = state.battle
    if not battle or (state.rest or 0) > 0 then
        return false, "Waiting: combat."
    end
    local livingEnemy, livingAlly = false, false
    for _, enemy in ipairs(battle.enemies) do
        livingEnemy = livingEnemy or enemy.hp > 0
    end
    for _, ally in ipairs(battle.heroes) do
        livingAlly = livingAlly or ally.hp > 0
    end
    if not livingEnemy or not livingAlly then
        return false, "Waiting: living combatants."
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
            return true, "Rule " .. index .. ": ready.", index
        end
    end
    return false, "Waiting: no rule matches."
end
