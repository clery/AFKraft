local _, W = ...
local L = W.L
local G, C = W.Game, W.Content
local LIMIT = 10
local purchases = {
    rebuilding = { name = L["Swift rebuilding"], description = L["+20% hero XP per rank"], max = 5 },
    supplies = {
        name = L["Steady supplies"],
        description = L["+15% gold and zone materials per rank"],
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
        type(difficulty) == "table"
        and type(difficulty.cycleComplete) == "boolean"
        and difficulty.finalBossEncounter == nil
    then
        -- Old level-60 boss readiness does not prove the final boss was defeated.
        difficulty.finalBossEncounter, difficulty.cycleComplete = 0, false
    end
    if
        not whole(state.tier, 0, LIMIT)
        or type(difficulty) ~= "table"
        or type(difficulty.unlocked) ~= "boolean"
        or not whole(difficulty.maxTier, state.tier, LIMIT)
        or type(difficulty.cycleComplete) ~= "boolean"
        or not whole(difficulty.finalBossEncounter, 0, state.encounter)
        or difficulty.cycleComplete ~= (difficulty.finalBossEncounter > 0)
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

function G.DifficultyAffixes(tier)
    local active = {}
    for _, affix in ipairs(C.difficultyAffixes) do
        if tier >= affix.tier then
            active[#active + 1] = affix
        end
    end
    return active
end

function G.DifficultyModifiers(state)
    local tier = state.tier
    local ranks = state.difficulty.purchases
    local attackInterval, regen, regenAfter, bossDamage, enrageAfter = 2.4, 0, 0, 1, 0
    for _, affix in ipairs(C.difficultyAffixes) do
        if tier >= affix.tier then
            attackInterval = affix.attackInterval or attackInterval
            regen, regenAfter = affix.regen or regen, affix.regenAfter or regenAfter
            bossDamage, enrageAfter =
                affix.bossDamage or bossDamage, affix.enrageAfter or enrageAfter
        end
    end
    return {
        enemyAttackInterval = attackInterval,
        enemyRegen = regen,
        regenAfter = regenAfter,
        bossDamage = bossDamage,
        enrageAfter = enrageAfter,
        enemyHealth = 1.27 ^ tier * 1.12 ^ math.max(0, tier - 2),
        enemyDamage = 1.18 ^ tier,
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
    G.ProfessionBossRewards(state, battle)
    record.best = math.max(record.best, battle.level)
    for zone, stage in pairs(state.safe) do
        record.safe[zone] = math.max(record.safe[zone] or 0, stage)
    end
    local finalBoss = C.transcendenceBoss
    if
        state.offline
        or not battle.boss
        or battle.zone ~= finalBoss.zone
        or battle.level < finalBoss.level
        or not whole(battle.stage, finalBoss.stage, 1000000000)
        or battle.stage % 10 ~= 0
    then
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
    difficulty.finalBossEncounter = state.encounter
    difficulty.maxTier = math.max(difficulty.maxTier, math.min(LIMIT, state.tier + 1))
    if first then
        G.Log(
            state,
            L["Transcendence ready. Review a new difficulty and permanent Inheritance rewards."],
            nil,
            "progress"
        )
    end
    return true
end

function G.BuyInheritance(state, id)
    local purchase = purchases[id]
    if not purchase then
        return false, L["Unknown Inheritance purchase."]
    end
    local difficulty = state.difficulty
    if not difficulty.unlocked then
        return false,
            L["Defeat "]
                .. C.transcendenceBoss.name
                .. L[" in Blackrock Mountain with a level 60 hero first."]
    end
    local rank = difficulty.purchases[id] or 0
    if rank >= purchase.max then
        return false, L["This Inheritance purchase is complete."]
    end
    local cost = rank + 1
    if difficulty.currency < cost then
        return false, L["Not enough Inheritance."]
    end
    difficulty.currency = difficulty.currency - cost
    difficulty.purchases[id] = rank + 1
    G.Log(state, purchase.name .. L[" improved permanently."], nil, "progress")
    return true
end

function G.PrestigePlusPreview(state, targetTier)
    local difficulty = state.difficulty
    local eligible, reason = true, L["Ready for a deeper reset."]
    if not difficulty.unlocked or not difficulty.cycleComplete then
        eligible, reason =
            false,
            L["Defeat "]
                .. C.transcendenceBoss.name
                .. L[" in Blackrock Mountain online with a level 60 hero this cycle."]
    elseif not whole(targetTier, 0, difficulty.maxTier) then
        eligible, reason = false, L["Choose an unlocked difficulty tier."]
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
            L["Heroes, talents, earned points and Mastery"],
            L["Adventure rank, partial XP, Essence and Heritage"],
            L["Heirlooms, collection records and permanent purchases"],
            L["Boost ownership, cooldowns, rules, profiles and route templates"],
            L["Profession ownership, learned recipes, specializations and allocations"],
            L["Unlocked tiers, Inheritance and enabled preferences"],
        },
        rebuilt = {
            L["Hero levels, XP, ordinary equipment and inventory"],
            L["Gold, zone materials, Runic fragments and profession cycle ranks/XP"],
            L["Run destinations, safe encounters and route cursor"],
            L["Active boosts end; cooldown deadlines remain"],
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
        L["Transcendence "]
            .. targetTier
            .. L[" begins. +"]
            .. preview.inheritance
            .. L[" Inheritance. Permanent progress retained."],
        nil,
        "progress"
    )
    G.Emit(state, "prestige")
    return true
end
