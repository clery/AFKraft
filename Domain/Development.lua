local _, W = ...
local G, C = W.Game, W.Content

local function rankCost(rank)
    return 60 * rank * rank
end
local function whole(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end

function G.ValidateDevelopment(state)
    local development = state.development
    if
        type(development) ~= "table"
        or type(development.ranks) ~= "table"
        or type(development.choices) ~= "table"
        or not whole(development.invested, 0, 69300)
        or not whole(state.essence, 0, 9007199254740991 - development.invested)
    then
        return false
    end
    local invested = 0
    for id in pairs(development.ranks) do
        if not C.developmentByID[id] then
            return false
        end
    end
    for id, choice in pairs(development.choices) do
        local branch, valid = C.developmentByID[id], false
        if not branch then
            return false
        end
        for _, option in ipairs(branch.choices) do
            if choice == option.id then
                valid = true
            end
        end
        if not valid then
            return false
        end
    end
    for _, branch in ipairs(C.development) do
        local rank = development.ranks[branch.id]
        if not whole(rank, 0, C.developmentRankCap) then
            return false
        end
        for level = 1, rank do
            invested = invested + rankCost(level)
        end
    end
    return development.invested == invested
end

local function modifiers(ranks, choices)
    local result = {
        damage = 1,
        healing = 1,
        health = 1,
        recovery = 0,
        damageTaken = 1,
        materials = 1,
        costMultiplier = 1,
        heroXP = 1,
    }
    local might = (ranks.might or 0) / ((ranks.might or 0) + 4)
    local resolve = (ranks.resolve or 0) / ((ranks.resolve or 0) + 4)
    local provision = (ranks.provisioning or 0) / ((ranks.provisioning or 0) + 4)
    result.damage, result.healing = 1 + 0.4 * might, 1 + 0.4 * might
    result.health, result.recovery, result.damageTaken =
        1 + 0.4 * resolve, 0.03 * resolve, 1 - 0.15 * resolve
    result.materials, result.costMultiplier, result.heroXP =
        1 + 0.6 * provision, 1 - 0.25 * provision, 1 + 0.5 * provision
    if ranks.might >= 3 then
        if choices.might == "assault" then
            result.damage = result.damage * 1.05
        elseif choices.might == "restoration" then
            result.healing = result.healing * 1.05
        end
    end
    if ranks.resolve >= 3 then
        if choices.resolve == "bulwark" then
            result.health = result.health * 1.05
        elseif choices.resolve == "renewal" then
            result.recovery = result.recovery + 0.005
        end
    end
    if ranks.provisioning >= 3 then
        if choices.provisioning == "harvest" then
            result.materials = result.materials * 1.1
        elseif choices.provisioning == "rebuild" then
            result.heroXP = result.heroXP * 1.1
        end
    end
    return result
end

function G.DevelopmentModifiers(state)
    local development = state.development
        or { ranks = { might = 0, resolve = 0, provisioning = 0 }, choices = {} }
    return modifiers(development.ranks, development.choices)
end

function G.DevelopmentQuote(state, id)
    local branch = C.developmentByID[id]
    if not branch then
        return nil, "Choose a development branch."
    end
    if not G.ValidateDevelopment(state) then
        return nil, "The saved development board is invalid."
    end
    local development, ranks = state.development, {}
    for key, rank in pairs(development.ranks) do
        ranks[key] = rank
    end
    local rank = ranks[id]
    local maximum = rank >= C.developmentRankCap
    ranks[id] = math.min(C.developmentRankCap, rank + 1)
    return {
        id = id,
        rank = rank,
        nextRank = ranks[id],
        cost = not maximum and rankCost(rank + 1) or nil,
        refund = rank > 0 and rankCost(rank) or 0,
        current = G.DevelopmentModifiers(state),
        next = modifiers(ranks, development.choices),
        choice = development.choices[id],
        choices = branch.choices,
        maximum = maximum,
    }
end

local function refresh(state)
    for index in ipairs(state.heroes) do
        G.RefreshHero(state, index)
    end
end

function G.BuyDevelopment(state, id)
    local quote, reason = G.DevelopmentQuote(state, id)
    if not quote then
        return false, reason
    end
    if quote.maximum then
        return false, "This development branch is complete."
    end
    if state.essence < quote.cost then
        return false, "Not enough Essence for this development rank."
    end
    state.essence = state.essence - quote.cost
    state.development.ranks[id] = quote.nextRank
    state.development.invested = state.development.invested + quote.cost
    refresh(state)
    return true
end

function G.RefundDevelopment(state, id)
    local quote, reason = G.DevelopmentQuote(state, id)
    if not quote then
        return false, reason
    end
    if quote.rank == 0 then
        return false, "This branch has no invested ranks."
    end
    state.development.ranks[id] = quote.rank - 1
    state.development.invested = state.development.invested - quote.refund
    state.essence = state.essence + quote.refund
    refresh(state)
    return true
end

function G.ResetDevelopment(state)
    if not G.ValidateDevelopment(state) then
        return false, "The saved development board is invalid."
    end
    state.essence = state.essence + state.development.invested
    state.development.invested = 0
    for _, branch in ipairs(C.development) do
        state.development.ranks[branch.id] = 0
    end
    refresh(state)
    return true
end

function G.SetDevelopmentChoice(state, id, choice)
    local branch = C.developmentByID[id]
    if not branch then
        return false, "Choose a development branch."
    end
    if not G.ValidateDevelopment(state) then
        return false, "The saved development board is invalid."
    end
    if state.development.ranks[id] < 3 then
        return false, "Reach rank 3 in this branch to choose a milestone."
    end
    local valid = false
    for _, option in ipairs(branch.choices) do
        if choice == option.id then
            valid = true
        end
    end
    if not valid then
        return false, "Choose one of this branch's milestones."
    end
    state.development.choices[id] = choice
    refresh(state)
    return true
end
