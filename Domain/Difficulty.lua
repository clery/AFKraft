local _, W = ...
local G, C = W.Game, W.Content
local LIMIT = 10
local purchases = {
    rebuilding = { name = "Swift rebuilding", description = "+20% hero XP per rank", max = 5 },
    supplies = {
        name = "Steady supplies",
        description = "+15% gold and zone materials per rank",
        max = 5,
    },
}
G.InheritancePurchases = purchases

local function whole(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end

function G.ValidateDifficulty(state)
    local difficulty = state.difficulty
    if
        not whole(state.tier, 0, LIMIT)
        or type(difficulty) ~= "table"
        or type(difficulty.unlocked) ~= "boolean"
        or not whole(difficulty.maxTier, state.tier, LIMIT)
        or type(difficulty.cycleComplete) ~= "boolean"
        or not whole(difficulty.ascensions, 0, 1000000000)
        or not whole(difficulty.currency, 0, 1000000000)
        or type(difficulty.purchases) ~= "table"
        or type(difficulty.records) ~= "table"
        or (
            (difficulty.maxTier > 0 or difficulty.cycleComplete or difficulty.ascensions > 0)
            and not difficulty.unlocked
        )
    then
        return false
    end
    for id, rank in pairs(difficulty.purchases) do
        if
            not purchases[id]
            or not whole(rank, 0, purchases[id].max)
            or (rank > 0 and not difficulty.unlocked)
        then
            return false
        end
    end
    if difficulty.currency > 0 and not difficulty.unlocked then
        return false
    end
    for tier, record in pairs(difficulty.records) do
        if
            not whole(tier, 0, difficulty.maxTier)
            or type(record) ~= "table"
            or not whole(record.best, 0, 1000000000)
            or type(record.safe) ~= "table"
            or (record.rewarded ~= nil and type(record.rewarded) ~= "boolean")
            or (record.lastEncounter ~= nil and not whole(record.lastEncounter, 0, state.encounter))
        then
            return false
        end
        for zone, stage in pairs(record.safe) do
            if type(zone) ~= "string" or not whole(stage, 0, 1000000000) then
                return false
            end
        end
    end
    return true
end

function G.DifficultyModifiers(state)
    local tier = state.tier
    local ranks = state.difficulty.purchases
    return {
        enemyHealth = 1.6 ^ tier,
        enemyDamage = 1.25 ^ tier,
        basicDamageTaken = 1 - math.min(0.3, tier * 0.025),
        heroXP = (1 + tier * 0.25) * (1 + (ranks.rebuilding or 0) * 0.2),
        masteryXP = 1 + tier * 0.2,
        gold = (1 + tier * 0.2) * (1 + (ranks.supplies or 0) * 0.15),
        materials = (1 + tier * 0.2) * (1 + (ranks.supplies or 0) * 0.15),
        loot = 1 + tier * 0.1,
    }
end

function G.DifficultyVictory(state, battle)
    local difficulty = state.difficulty
    local record = difficulty.records[state.tier]
    if not record then
        record = { best = 0, safe = {} }
        difficulty.records[state.tier] = record
    end
    if record.lastEncounter == state.encounter then
        return false
    end
    record.lastEncounter = state.encounter
    record.best = math.max(record.best, battle.level)
    for zone, stage in pairs(state.safe) do
        record.safe[zone] = math.max(record.safe[zone] or 0, stage)
    end
    if state.offline or not battle.boss or battle.level < C.heroLevelCap then
        return false
    end
    local qualified = false
    for _, hero in ipairs(state.heroes) do
        qualified = qualified or hero.level >= C.heroLevelCap
    end
    if not qualified then
        return false
    end
    local first = not difficulty.cycleComplete
    difficulty.unlocked, difficulty.cycleComplete = true, true
    difficulty.maxTier = math.max(difficulty.maxTier, math.min(LIMIT, state.tier + 1))
    if first then
        G.Log(state, "Prestige+ ready. Review a new difficulty and permanent Inheritance rewards.")
    end
    return true
end

function G.BuyInheritance(state, id)
    local purchase = purchases[id]
    if not purchase then
        return false, "Unknown Inheritance purchase."
    end
    local difficulty = state.difficulty
    if not difficulty.unlocked then
        return false, "Complete a level 60 boss with a level 60 hero first."
    end
    local rank = difficulty.purchases[id] or 0
    if rank >= purchase.max then
        return false, "This Inheritance purchase is complete."
    end
    local cost = rank + 1
    if difficulty.currency < cost then
        return false, "Not enough Inheritance."
    end
    difficulty.currency = difficulty.currency - cost
    difficulty.purchases[id] = rank + 1
    G.Log(state, purchase.name .. " improved permanently.")
    return true
end

function G.PrestigePlusPreview(state, targetTier)
    local difficulty = state.difficulty
    local eligible, reason = true, "Ready for a deeper reset."
    if not difficulty.unlocked or not difficulty.cycleComplete then
        eligible, reason =
            false, "Complete a level 60 boss with a current level 60 hero this cycle."
    elseif not whole(targetTier, 0, difficulty.maxTier) then
        eligible, reason = false, "Choose an unlocked difficulty tier."
    end
    local record = difficulty.records[state.tier]
    local gain = difficulty.cycleComplete and not (record and record.rewarded) and state.tier + 1
        or 0
    return {
        eligible = eligible,
        reason = reason,
        targetTier = targetTier,
        inheritance = gain,
        retained = {
            "Heroes, talents, earned points and Mastery",
            "Adventure rank, partial XP, Essence and Legacy",
            "Heirlooms, collection records and permanent purchases",
            "Boost ownership, cooldowns, rules, profiles and route templates",
            "Profession ownership, recipes, specializations and allocations",
            "Unlocked tiers, Inheritance and enabled preferences",
        },
        rebuilt = {
            "Hero levels, XP, training, ordinary equipment and inventory",
            "Gold, zone materials and profession cycle ranks/XP",
            "Run destinations, safe encounters and route cursor",
            "Active boosts end; cooldown deadlines remain",
        },
    }
end

function G.PrestigePlus(state, targetTier)
    local preview = G.PrestigePlusPreview(state, targetTier)
    if not preview.eligible then
        return false, preview.reason
    end
    -- ResetAdventure validates hero progression before changing any run state.
    local completedTier = state.tier
    local ok, reason = G.ResetAdventure(state, true)
    if not ok then
        return false, reason
    end
    local difficulty = state.difficulty
    local record = difficulty.records[completedTier]
    if not record then
        record = { best = 0, safe = {} }
        difficulty.records[completedTier] = record
    end
    record.rewarded = true
    difficulty.currency = difficulty.currency + preview.inheritance
    difficulty.ascensions = difficulty.ascensions + 1
    difficulty.cycleComplete = false
    state.tier = targetTier
    G.Log(
        state,
        "Prestige+ "
            .. targetTier
            .. " begins. +"
            .. preview.inheritance
            .. " Inheritance. Permanent progress retained."
    )
    G.Emit(state, "prestige")
    return true
end
