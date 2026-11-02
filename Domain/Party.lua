local _, W = ...
local C, G = W.Content, W.Game
local min, max, floor = math.min, math.max, math.floor

-- Cosmetic identity never advances the simulation's combat/loot random stream.
function G.AppearanceSeed(hero)
    local seed = hero.appearanceSeed
    if type(seed) == "number" and seed > 0 and seed < 2147483647 and seed == floor(seed) then
        return seed
    end
    seed = 1
    local identity = tostring(hero.id or "")
        .. ":"
        .. tostring(hero.name or "")
        .. ":"
        .. tostring(hero.appearance or "")
    for i = 1, #identity do
        seed = (seed * 131 + identity:byte(i)) % 2147483647
    end
    hero.appearanceSeed = math.max(1, seed)
    return hero.appearanceSeed
end

function G.CompanionSlots(state)
    local slots = math.max(1, #state.heroes)
    for i = 2, #C.companionMilestones do
        if state.best > C.companionMilestones[i] then
            slots = math.max(slots, i)
        end
    end
    return math.min(5, slots)
end

function G.NextCompanionMilestone(state)
    return C.companionMilestones[G.CompanionSlots(state) + 1]
end

-- Player recruitment enforces discoveries; AddHero constructs the starting
-- hero and is also used to assemble simulation fixtures.
function G.Recruit(state, classID)
    if #state.heroes >= G.CompanionSlots(state) then
        local level = G.NextCompanionMilestone(state)
        return false,
            level
                    and ("Find another companion by defeating a level " .. level .. " milestone boss.")
                or "Your company is complete."
    end
    return G.AddHero(state, classID)
end

function G.AddHero(state, classID, identity)
    local class = C.classByID[classID]
    if not class or #state.heroes >= 5 then
        return false, "The party is full or this class is unavailable."
    end
    local appearances = C.appearances[classID]
    local hero = {
        id = #state.heroes + 1,
        class = classID,
        name = identity and identity.name or C.names[G.Random(state, #C.names)],
        generated = not identity,
        guid = identity and identity.guid,
        appearance = appearances[G.Random(state, #appearances)],
        level = 1,
        xp = 0,
        rank = 0,
        health = 1,
        gear = {},
        talents = {},
        priority = "heal",
        healBelow = 65,
        specialCount = 2,
    }
    state.heroes[#state.heroes + 1] = hero
    hero.appearanceSeed = state.seed
    G.Emit(state, "recruit")
    G.Log(
        state,
        hero.name .. (state.battle and " joins the next encounter." or " joined the adventure.")
    )
    return true
end

function G.Replace(state, index, identity)
    local hero = state.heroes[index]
    if not hero or not hero.generated or hero.class ~= identity.class then
        return false, "Choose a generated hero of the same class."
    end
    for _, existingHero in ipairs(state.heroes) do
        if existingHero.guid == identity.guid then
            return false, "This character is already in the party."
        end
    end
    hero.name, hero.guid, hero.generated = identity.name, identity.guid, false
    G.RefreshHero(state, index)
    return true
end

function G.ItemStats(item, hero, extraUpgrade)
    local stats = {}
    if not item then
        return stats
    end
    local scale = 1 + ((item.upgrade or 0) + (extraUpgrade or 0)) * 0.1
    if item.heirloom then
        local template = C.itemByID[item.itemID]
        scale = scale * (hero and hero.level or 1) / (template and template.level or 1)
    end
    for _, key in ipairs(C.itemStatOrder) do
        local value = item.stats and item.stats[key]
        if type(value) == "number" and value >= 0 and value < math.huge then
            stats[key] = value * scale
        end
    end
    return stats
end

local itemWeights = {
    stamina = 0.6,
    spirit = 0.4,
    haste = 0.8,
    armor = 0.04,
    weaponDPS = 1.5,
    attackPower = 0.5,
    spellPower = 0.8,
    healingPower = 0.5,
    healthRegen = 1,
    arcaneResistance = 0,
    fireResistance = 0,
    frostResistance = 0,
    natureResistance = 0,
    shadowResistance = 0,
}

function G.ItemPower(item, hero, extraUpgrade)
    local stats = G.ItemStats(item, hero, extraUpgrade)
    local primary = hero and C.primaryStats[hero.class]
    local power = 0

    for key, value in pairs(stats) do
        power = power + value * (itemWeights[key] or (key == primary and 1 or 0))
    end
    return floor(power * 10 + 0.5) / 10
end

function G.ItemDescription(item, hero)
    if not item then
        return "Empty slot"
    end
    local lines = {}
    local stats = G.ItemStats(item, hero)
    for _, key in ipairs(C.itemStatOrder) do
        if stats[key] and stats[key] > 0 then
            lines[#lines + 1] = string.format("+%.1f %s", stats[key], C.itemStatNames[key])
        end
    end
    local armorType = G.ItemArmorType(item)
    if armorType then
        lines[#lines + 1] = C.armorNames[armorType] or "Unknown armor"
        if hero then
            local allowed, reason = G.CanWearArmor(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.slot == 1 then
        lines[#lines + 1] = C.weaponNames[G.ItemWeaponType(item)] or "Unknown weapon"
        if hero then
            local allowed, reason = G.CanUseWeapon(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.itemID then
        lines[#lines + 1] = "Classic item #"
            .. item.itemID
            .. " · WoW level "
            .. item.requiredLevel
    end
    if item.heirloom then
        lines[#lines + 1] = "Idle heirloom: stats scale with hero level."
    end
    if (item.upgrade or 0) > 0 then
        lines[#lines + 1] = "Idle enhancement: +" .. item.upgrade * 10 .. "% stats."
    end
    lines[#lines + 1] = "Power is an idle class-weighted estimate."
    if item.itemID == 13074 then
        lines[#lines + 1] = "Source bonus: +6 Defense (not simulated)."
    end
    if item.itemID == 13040 then
        lines[#lines + 1] = "Shadowbolt proc is not simulated."
    end
    if item.itemID == 13009 then
        lines[#lines + 1] = "Resistances are informational until damage schools are supported."
    end
    return table.concat(lines, "\n")
end

-- Resolve old shared IDs to class-owned nodes, refunding unknown saved selections.
function G.TalentList(hero)
    local byID = C.talentByClassID[hero.class] or {}
    local legacy = C.legacyTalentIDs[hero.class] or {}
    if type(hero.talents) ~= "table" then
        hero.talents = {}
    end
    local selected = hero.talents
    for id, learned in pairs(selected) do
        if not byID[id] or learned ~= true then
            selected[id] = nil
            local replacement = legacy[id]
            if learned == true and replacement then
                selected[replacement] = true
            end
        end
    end
    return C.talentsByClass[hero.class] or {}
end

function G.TalentEffects(hero)
    local effects = {}
    for _, talent in ipairs(G.TalentList(hero)) do
        if hero.talents[talent.id] then
            if talent.value == true then
                effects[talent.effect] = true
            else
                effects[talent.effect] = (effects[talent.effect] or 0) + talent.value
            end
        end
    end
    return effects
end

-- Apply talent modifiers after base equipment stats so both stat models stay compatible.
function G.ApplyTalentStats(hero, stats)
    local talents = G.TalentEffects(hero)
    stats.hp = floor(stats.hp * (1 + (talents.health or 0)))
    stats.damage = stats.damage * (1 + (talents.damage or 0))
    stats.healing = stats.healing * (1 + (talents.healing or 0))
    stats.haste = (stats.haste or 1) * (1 + (talents.speed or 0))
    stats.mitigation = min(0.75, (stats.mitigation or 0) + (talents.mitigation or 0))
    stats.regen = (stats.regen or 0) + stats.hp * (talents.regen or 0)
    return stats
end

function G.Stats(state, hero)
    local total, heal = {}, 0
    for _, item in pairs(hero.gear) do
        for key, value in pairs(G.ItemStats(item, hero)) do
            total[key] = (total[key] or 0) + value
        end
        if item.effect == "renewal" then
            heal = heal + 0.06
        end
    end
    local primary = total[C.primaryStats[hero.class]] or 0
    local offense = primary * 0.65 + (total.weaponDPS or 0) + (total.attackPower or 0) * 0.325
    local mult = 1 + state.prestiges * 0.04
    return G.ApplyTalentStats(hero, {
        attributes = total,
        hp = math.floor((105 + hero.level * 19 + (total.stamina or 0) * 10) * mult),
        damage = (9 + hero.level * 3 + offense + (total.spellPower or 0) * 0.65) * mult,
        healing = (
            15
            + hero.level * 5
            + (total.intellect or 0) * 0.8
            + (total.spirit or 0) * 0.6
            + (total.healingPower or 0)
            + (total.spellPower or 0) * 0.6
        )
            * (1 + heal)
            * mult,
        haste = 1 + (total.haste or 0) / 100,
        mitigation = math.min(
            0.6,
            (total.armor or 0) / (500 + hero.level * 50 + (total.armor or 0))
        ),
        regen = (total.healthRegen or 0) / 5,
    })
end

function G.Points(hero)
    local count = 0
    local talents = G.TalentList(hero)
    for _, v in pairs(hero.talents) do
        if v then
            count = count + 1
        end
    end
    return max(0, min(#talents, floor((hero.level + 1) / 2)) - count)
end

function G.LevelCap(hero)
    return 4 + (hero.rank or 0) * 4
end

function G.TrainingCost(hero)
    return { essence = 120 + 120 * (hero.rank or 0), gold = 80 }
end

function G.Train(state, index)
    local hero = state.heroes[index]
    if not hero then
        return false, "Choose a hero."
    end
    local cost = G.TrainingCost(hero)
    if state.essence < cost.essence or state.gold < cost.gold then
        return false, "Training costs " .. cost.essence .. " Essence and " .. cost.gold .. " gold."
    end
    state.essence = state.essence - cost.essence
    state.gold = state.gold - cost.gold
    hero.rank = (hero.rank or 0) + 1
    G.Emit(state, "train")
    G.Log(state, hero.name .. " can now reach idle level " .. G.LevelCap(hero) .. ".")
    return true
end

function G.Configure(state, index, key, value)
    local hero = state.heroes[index]
    if not hero then
        return false
    end
    if key == "priority" then
        local valid = false
        for _, id in ipairs(C.priorityModes) do
            if id == value then
                valid = true
            end
        end
        if not valid then
            return false
        end
    elseif key == "healBelow" then
        if type(value) ~= "number" or value < 1 or value > 100 then
            return false
        end
    elseif key == "specialCount" then
        if type(value) ~= "number" or value < 1 or value > 3 then
            return false
        end
    else
        return false
    end
    hero[key] = value
    return true
end

function G.CanTalent(hero, talent)
    local previous, peers, nextRow = false, 0, false
    for _, node in ipairs(G.TalentList(hero)) do
        if node.path == talent.path and hero.talents[node.id] then
            if node.row == talent.row - 1 then
                previous = true
            elseif node.row == talent.row then
                peers = peers + 1
            elseif node.row == talent.row + 1 then
                nextRow = true
            end
        end
    end
    if hero.talents[talent.id] then
        if peers == 1 and nextRow then
            return false, "Unlearn talents in the next row first."
        end
        return true
    end
    if talent.row > 1 and not previous then
        return false, "Spend at least one point in the previous row of this specialization first."
    end
    if G.Points(hero) < 1 then
        return false, "Gain more idle levels to earn talent points."
    end
    return true
end

function G.Talent(state, index, id)
    local hero = state.heroes[index]
    if not hero then
        return false
    end
    G.TalentList(hero)
    id = C.legacyTalentIDs[hero.class][id] or id
    if not C.talentByClassID[hero.class][id] then
        return false
    end
    local allowed, reason = G.CanTalent(hero, C.talentByClassID[hero.class][id])
    if not allowed then
        return false, reason
    end
    if hero.talents[id] then
        hero.talents[id] = nil
        G.RefreshHero(state, index)
        return true
    end
    hero.talents[id] = true
    state.guide.talent = true
    G.RefreshHero(state, index)
    G.Emit(state, "unlock")
    state.discoveries["talent:" .. hero.class .. ":" .. id] = true
    return true
end

function G.IsUnlocked(state, z)
    return z.level <= state.runBest
end

function G.Travel(state, zone)
    local z = C.zoneByID[zone]
    if not z or not G.IsUnlocked(state, z) then
        return false, "Defeat harder encounters to unlock this destination."
    end
    if state.zone == zone then
        return true
    end
    if state.battle then
        for _, unit in ipairs(state.battle.heroes) do
            state.heroes[unit.id].health = math.max(0, unit.hp / unit.maxHP)
        end
    end
    state.battle, state.rest = nil, 0
    state.zone, state.stage = zone, (state.safe[zone] or 0) + 1
    state.guide.traveled = true
    G.Emit(state, "travel")
    state.farming = false
    G.Log(state, "Traveling to " .. z.name .. ".")
    return true
end

-- Preserve current health proportion and cooldowns when a build changes mid-fight.
function G.RefreshHero(state, index)
    local hero = state.heroes[index]
    local unit = state.battle and state.battle.heroes[index]
    if not hero or not unit then
        return
    end
    local stats, health = G.Stats(state, hero), unit.hp / unit.maxHP
    unit.name, unit.maxHP = hero.name, stats.hp
    unit.hp = math.min(stats.hp, math.max(0, health * stats.hp))
    unit.damage, unit.healing = stats.damage, stats.healing
    unit.haste, unit.mitigation, unit.regen = stats.haste, stats.mitigation, stats.regen
end

function G.ExperienceResult(hero, amount)
    local level, xp, cap = hero.level, hero.xp, G.LevelCap(hero)
    if level < cap then
        xp = xp + amount
    end
    while level < cap and xp >= level * 45 do
        xp, level = xp - level * 45, level + 1
    end
    if level >= cap then
        xp = math.min(xp, level * 45 - 1)
    end
    return level, xp
end

function G.Retry(state)
    if not state.farming then
        return false, "Your company is already advancing."
    end
    if state.battle then
        for _, unit in ipairs(state.battle.heroes) do
            state.heroes[unit.id].health = math.max(0, unit.hp / unit.maxHP)
        end
    end
    state.battle, state.rest = nil, 0
    state.stage = (state.safe[state.zone] or 0) + 1
    state.farming, state.lastDefeat = false, nil
    return true
end
