local _, W = ...
local G, C = W.Game, W.Content

local function whole(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end

function G.ProfessionUnlocks(state)
    local p = state.professions
    local best = p.bestLevel
    local function record(level)
        if type(level) == "number" and level >= 1 and level < math.huge then
            best = math.max(best, math.min(C.heroLevelCap, math.floor(level)))
        end
    end
    for _, hero in ipairs(state.heroes) do
        if type(hero) == "table" then
            record(hero.level)
            if type(hero.talentProgress) == "table" then
                record(hero.talentProgress.bestLevel)
            end
        end
    end
    p.bestLevel = best
    for _, profession in ipairs(C.professions) do
        if best >= profession.unlockLevel then
            p.owned[profession.id] = true
        end
    end
    if best >= 50 then
        p.owned.research = true
    end
    return p.owned
end

function G.ValidateProfessions(state)
    local p = state.professions
    if type(p) ~= "table" then
        return false
    end
    if p.fragments == nil then
        p.fragments = 0
    end
    if p.recipes == nil then
        p.recipes = {}
    end
    if p.lastFragmentEncounter == nil then
        p.lastFragmentEncounter = 0
    end
    if
        not whole(p.fragments, 0, C.runicFragmentCap)
        or type(p.recipes) ~= "table"
        or not whole(p.lastFragmentEncounter, 0, state.encounter)
    then
        return false
    end
    for id, known in pairs(p.recipes) do
        local recipe = C.enchantByID[id]
        if not recipe or not recipe.tier or known ~= true then
            return false
        end
    end
    if p.bestLevel == nil then
        p.bestLevel = 1
    end
    if not whole(p.bestLevel, 1, C.heroLevelCap) then
        return false
    end
    for _, key in ipairs({ "owned", "ranks", "xp", "allocations" }) do
        if p[key] == nil then
            p[key] = {}
        end
        if type(p[key]) ~= "table" then
            return false
        end
    end
    for key, value in pairs(p.owned) do
        if (not C.professionByID[key] and key ~= "research") or value ~= true then
            return false
        end
    end
    for _, key in ipairs({ "ranks", "xp", "allocations" }) do
        for id in pairs(p[key]) do
            if not C.professionByID[id] then
                return false
            end
        end
    end
    for _, profession in ipairs(C.professions) do
        local id = profession.id
        if p.ranks[id] == nil then
            p.ranks[id] = 0
        end
        if p.xp[id] == nil then
            p.xp[id] = 0
        end
        if p.allocations[id] == nil then
            p.allocations[id] = {}
        end
        if
            not whole(p.ranks[id], 0, C.professionRankCap)
            or not whole(
                p.xp[id],
                0,
                p.ranks[id] == C.professionRankCap and 0 or (20 + p.ranks[id] * 10 - 1)
            )
            or type(p.allocations[id]) ~= "table"
        then
            return false
        end
        local known = {}
        for _, branch in ipairs(profession.branches) do
            known[branch.id] = true
        end
        for branch, rank in pairs(p.allocations[id]) do
            if not known[branch] or not whole(rank, 0, C.professionBranchCap) then
                return false
            end
        end
    end
    G.ProfessionUnlocks(state)
    return true
end

function G.ProfessionBossRewards(state, battle)
    local p = state.professions
    if
        type(battle) ~= "table"
        or battle.boss ~= true
        or state.tier < 2
        or not whole(battle.level, 20, 1000000)
        or state.encounter <= p.lastFragmentEncounter
    then
        return false
    end
    if state.offline and next(p.recipes) == nil then
        return false
    end
    p.lastFragmentEncounter = state.encounter
    p.fragments = math.min(C.runicFragmentCap, p.fragments + 1)
    if not state.offline then
        for _, recipe in ipairs(C.enchants) do
            if recipe.tier and state.tier >= recipe.tier and not p.recipes[recipe.id] then
                p.recipes[recipe.id] = true
                G.Log(
                    state,
                    recipe.name
                        .. " recipe learned permanently. Runic fragments come from idle tier 2+ level-20+ bosses.",
                    true
                )
                G.Emit(state, "unlock")
            end
        end
    end
    return true
end

local function effective(state, kind)
    local p, result, spent = state.professions, {}, 0
    if not G.ProfessionUnlocks(state).research then
        return result, spent
    end
    for _, branch in ipairs(C.professionByID[kind].branches) do
        local chosen = p.allocations[kind][branch.id] or 0
        local rank = 0
        for level = 1, chosen do
            if spent < p.ranks[kind] and p.ranks[kind] >= 1 + (level - 1) * 3 then
                rank, spent = level, spent + 1
            else
                break
            end
        end
        result[branch.id] = rank
    end
    return result, spent
end

function G.ProfessionActiveAllocations(state, kind)
    if not C.professionByID[kind] then
        return {}
    end
    return effective(state, kind)
end

function G.ProfessionPoints(state, kind)
    if not C.professionByID[kind] then
        return 0, 0
    end
    local _, spent = effective(state, kind)
    local total = G.ProfessionUnlocks(state).research and state.professions.ranks[kind] or 0
    return math.max(0, total - spent), total
end

function G.ProfessionModifiers(state, kind)
    local result = {
        costMultiplier = 1,
        statMultiplier = 1,
        qualityBonus = 0,
        enchantOffense = 1,
        enchantDefense = 1,
        enchantUtility = 1,
        forgeStep = 0.04,
        heirloomDiscount = 1,
    }
    if not C.professionByID[kind] then
        return result
    end
    local ranks = effective(state, kind)
    if kind == "crafting" then
        result.costMultiplier = 1 - (ranks.efficiency or 0) * 0.05
        result.qualityBonus = (ranks.quality or 0) >= 3 and 1 or 0
        result.statMultiplier = 1 + (ranks.precision or 0) * 0.05 + (ranks.quality or 0) * 0.02
    elseif kind == "enchanting" then
        result.enchantOffense = 1 + (ranks.offense or 0) * 0.1
        result.enchantDefense = 1 + (ranks.defense or 0) * 0.1
        result.enchantUtility = 1 + (ranks.utility or 0) * 0.1
    else
        result.costMultiplier = 1 - (ranks.efficiency or 0) * 0.05
        result.forgeStep = 0.04 + (ranks.potential or 0) * 0.005
        result.heirloomDiscount = 1 - (ranks.heirloom or 0) * 0.05
    end
    return result
end

function G.AllocateProfession(state, kind, branchID)
    local profession = C.professionByID[kind]
    if not profession or not G.ProfessionUnlocks(state).research then
        return false, "Reach lifetime idle level 50 to specialize professions."
    end
    local known = false
    for _, branch in ipairs(profession.branches) do
        if branch.id == branchID then
            known = true
        end
    end
    if not known then
        return false, "Choose a profession specialization."
    end
    local p = state.professions
    local nextRank = (p.allocations[kind][branchID] or 0) + 1
    if nextRank > C.professionBranchCap then
        return false, "This specialization is complete."
    end
    local available = G.ProfessionPoints(state, kind)
    local desired = 0
    for _, rank in pairs(p.allocations[kind]) do
        desired = desired + rank
    end
    if available < 1 or desired >= p.ranks[kind] or p.ranks[kind] < 1 + (nextRank - 1) * 3 then
        return false, "Earn a profession point and the required work rank first."
    end
    p.allocations[kind][branchID] = nextRank
    return true
end

function G.ResetProfessionAllocations(state, kind)
    if not C.professionByID[kind] then
        return false, "Choose a profession."
    end
    state.professions.allocations[kind] = {}
    return true
end

function G.ProfessionWork(state, kind)
    if not C.professionByID[kind] or not G.ProfessionUnlocks(state)[kind] then
        return false
    end
    local p = state.professions
    if p.ranks[kind] >= C.professionRankCap then
        return true
    end
    p.xp[kind] = p.xp[kind] + 10
    while p.ranks[kind] < C.professionRankCap and p.xp[kind] >= 20 + p.ranks[kind] * 10 do
        p.xp[kind] = p.xp[kind] - (20 + p.ranks[kind] * 10)
        p.ranks[kind] = p.ranks[kind] + 1
    end
    if p.ranks[kind] == C.professionRankCap then
        p.xp[kind] = 0
    end
    return true
end

local function equipped(state, heroIndex, slot, profession)
    if not G.ProfessionUnlocks(state)[profession] then
        return nil,
            nil,
            "Reach lifetime idle level "
                .. C.professionByID[profession].unlockLevel
                .. " to unlock this profession."
    end
    local hero = state.heroes[heroIndex]
    local item = hero and hero.gear[slot]
    if not item then
        return nil, nil, "Equip an item in this slot first."
    end
    if (item.count or 1) ~= 1 then
        return nil, nil, "Equip a single item before modifying it."
    end
    local allowed, reason = G.CanEquip(hero, item)
    if not allowed then
        return nil, nil, reason
    end
    return item, hero
end

local function costFor(state, kind, item, hero, rank)
    local modifiers = G.ProfessionModifiers(state, kind)
    local discount = modifiers.costMultiplier
        * (item.heirloom and modifiers.heirloomDiscount or 1)
        * G.DevelopmentModifiers(state).costMultiplier
    local level = math.max(1, item.heirloom and hero.level or item.level)
    return {
        gold = math.max(1, math.ceil((40 + level * 12) * rank * discount)),
        essence = 0,
        materials = {
            relic = math.max(1, math.ceil((3 + rank * 2) * discount)),
            ore = kind == "titanforging" and math.max(1, math.ceil((5 + rank * 3) * discount)) or 0,
        },
    }
end

function G.EnchantQuote(state, heroIndex, slot, enchantID)
    local enchant = C.enchantByID[enchantID]
    if not enchant then
        return nil, nil, "Choose an enchantment."
    end
    if enchant.tier and not state.professions.recipes[enchantID] then
        return nil,
            nil,
            "Defeat an idle level-20+ boss at tier "
                .. enchant.tier
                .. "+ while online to learn this recipe."
    end
    local item, hero, reason = equipped(state, heroIndex, slot, "enchanting")
    if not item or not hero then
        return nil, nil, reason
    end
    local modifiers = G.ProfessionModifiers(state, "enchanting")
    local branch = enchant.branch or enchantID
    local bonus = modifiers["enchant" .. branch:sub(1, 1):upper() .. branch:sub(2)]
    local scale = math.max(1, (item.heirloom and hero.level or item.level) / 10) * bonus
    local preview, same = G.Copy(item), item.enchant and item.enchant.id == enchantID
    preview.enchant =
        { id = enchantID, level = item.heirloom and hero.level or item.level, stats = {} }
    for stat, value in pairs(enchant.stats) do
        preview.enchant.stats[stat] = math.floor(value * scale * 10 + 0.5) / 10
        if
            not item.enchant
            or not item.enchant.stats
            or item.enchant.stats[stat] ~= preview.enchant.stats[stat]
        then
            same = false
        end
    end
    if same then
        return nil, nil, "This item already has this enchantment at the current strength."
    end
    local cost = costFor(state, "enchanting", item, hero, 1)
    cost.fragments = enchant.fragments or 0
    return preview, cost
end

function G.ForgeMultiplier(item)
    if not item or not whole(item.forge or 0, 0, C.forgeCap) then
        return 1
    end
    local bonus = item.forgePower or (item.forge or 0) * 0.04
    if type(bonus) ~= "number" or bonus ~= bonus or bonus < 0 or bonus > 0.27500001 then
        return 1
    end
    return 1 + bonus
end

function G.ProfessionStatBonus(item, hero)
    local result = {}
    if
        not item
        or not item.enchant
        or not C.enchantByID[item.enchant.id]
        or type(item.enchant.stats) ~= "table"
    then
        return result
    end
    local scale = 1
    if
        item.heirloom
        and hero
        and type(hero.level) == "number"
        and whole(item.enchant.level, 1, C.heroLevelCap)
    then
        scale = math.max(1, hero.level) / item.enchant.level
    end
    for stat in pairs(C.enchantByID[item.enchant.id].stats) do
        local value = item.enchant.stats[stat]
        if type(value) == "number" and value >= 0 and value <= 1000000 then
            result[stat] = value * scale
        end
    end
    return result
end

function G.ForgeQuote(state, heroIndex, slot)
    local item, hero, reason = equipped(state, heroIndex, slot, "titanforging")
    if not item or not hero then
        return nil, nil, reason
    end
    if not whole(item.forge or 0, 0, C.forgeCap - 1) then
        return nil, nil, "This item has reached its titanforge cap."
    end
    local preview = G.Copy(item)
    preview.forge = (item.forge or 0) + 1
    preview.forgePower = math.min(
        0.275,
        G.ForgeMultiplier(item) - 1 + G.ProfessionModifiers(state, "titanforging").forgeStep
    )
    return preview, costFor(state, "titanforging", item, hero, preview.forge)
end

local function pay(state, cost)
    if state.gold < cost.gold or state.professions.fragments < (cost.fragments or 0) then
        return false
    end
    for material, count in pairs(cost.materials) do
        if state.materials[material] < count then
            return false
        end
    end
    state.gold = state.gold - cost.gold
    state.professions.fragments = state.professions.fragments - (cost.fragments or 0)
    for material, count in pairs(cost.materials) do
        state.materials[material] = state.materials[material] - count
    end
    return true
end

local function modify(state, heroIndex, slot, kind, enchantID)
    local preview, cost, reason
    if kind == "enchanting" then
        preview, cost, reason = G.EnchantQuote(state, heroIndex, slot, enchantID)
    else
        preview, cost, reason = G.ForgeQuote(state, heroIndex, slot)
    end
    if not preview or not cost then
        return false, reason
    end
    if not pay(state, cost) then
        return false,
            (cost.fragments or 0) > 0
                    and "Not enough gold, idle materials or Runic fragments for this modification."
                or "Not enough gold or idle materials for this modification."
    end
    local item = state.heroes[heroIndex].gear[slot]
    if kind == "enchanting" then
        item.enchant = preview.enchant
    else
        item.forge, item.forgePower = preview.forge, preview.forgePower
    end
    G.ProfessionWork(state, kind)
    G.RefreshHero(state, heroIndex)
    return true
end

function G.Enchant(state, heroIndex, slot, enchantID)
    return modify(state, heroIndex, slot, "enchanting", enchantID)
end
function G.Titanforge(state, heroIndex, slot)
    return modify(state, heroIndex, slot, "titanforging")
end
