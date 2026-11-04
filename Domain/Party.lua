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
        targetMode = "front",
        resourceThreshold = 0,
        healBelow = 65,
        specialCount = 2,
    }
    G.TalentProgress(hero)
    G.MasteryProgress(hero)
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
    local scale = (1 + ((item.upgrade or 0) + (extraUpgrade or 0)) * 0.1) * G.ForgeMultiplier(item)
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
    for key, value in pairs(G.ProfessionStatBonus(item, hero)) do
        stats[key] = (stats[key] or 0) + value
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

function G.ItemDescription(item, hero, compare)
    if not item then
        return "Empty slot"
    end
    local lines = {}
    local stats = G.ItemStats(item, hero)
    local previous = compare and hero and G.ItemStats(hero.gear[item.slot], hero) or {}
    local lost = {}
    for _, key in ipairs(C.itemStatOrder) do
        local value, old = stats[key] or 0, previous[key] or 0
        local delta = value - old
        if value > 0 then
            local color = compare and delta > 0 and "|cff1eff00"
                or compare and delta < 0 and "|cffff6060"
                or "|cffffffff"
            lines[#lines + 1] = color
                .. string.format("+%.1f %s", value, C.itemStatNames[key])
                .. (compare and delta ~= 0 and string.format(" (%+.1f)", delta) or "")
                .. "|r"
        elseif compare and old > 0 then
            lost[#lost + 1] = string.format("|cffff6060-%.1f %s|r", old, C.itemStatNames[key])
        end
    end
    if #lost > 0 then
        lines[#lines + 1] = "\n|cffffffffLost on equip:|r"
        lines[#lines + 1] = table.concat(lost, "\n")
    end
    local armorType = G.ItemArmorType(item)
    if armorType then
        lines[#lines + 1] = C.armorNames[armorType] or "Unknown armor"
        if hero and not compare then
            local allowed, reason = G.CanWearArmor(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.slot == 1 then
        lines[#lines + 1] = C.weaponNames[G.ItemWeaponType(item)] or "Unknown weapon"
        if hero and not compare then
            local allowed, reason = G.CanUseWeapon(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.heirloom then
        lines[#lines + 1] = "Idle heirloom: stats scale with hero level."
    end
    if (item.upgrade or 0) > 0 then
        lines[#lines + 1] = "Idle enhancement: +" .. item.upgrade * 10 .. "% stats."
    end
    if item.enchant then
        local enchant = C.enchantByID[item.enchant.id]
        lines[#lines + 1] = "Enchantment: " .. (enchant and enchant.name or "Unknown") .. "."
    end
    if (item.forge or 0) > 0 then
        lines[#lines + 1] = "Titanforge "
            .. item.forge
            .. ": +"
            .. math.floor((G.ForgeMultiplier(item) - 1) * 100 + 0.5)
            .. "% base potential."
    end
    local template = C.itemByID[item.itemID]
    if template and template.note then
        lines[#lines + 1] = template.note
    end
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
    local mult = 1 + (state.prestigeStrength or state.prestiges) * 0.04
    local development = G.DevelopmentModifiers(state)
    local stats = G.ApplyTalentStats(hero, {
        attributes = total,
        hp = math.floor(
            (105 + hero.level * 19 + (total.stamina or 0) * 10) * mult * development.health
        ),
        damage = (9 + hero.level * 3 + offense + (total.spellPower or 0) * 0.65)
            * mult
            * development.damage,
        healing = (
            15
            + hero.level * 5
            + (total.intellect or 0) * 0.8
            + (total.spirit or 0) * 0.6
            + (total.healingPower or 0)
            + (total.spellPower or 0) * 0.6
        )
            * (1 + heal)
            * mult
            * development.healing,
        haste = 1 + (total.haste or 0) / 100,
        mitigation = math.min(
            0.6,
            (total.armor or 0) / (500 + hero.level * 50 + (total.armor or 0))
        ),
        regen = (total.healthRegen or 0) / 5,
    })
    stats.mitigation = 1 - (1 - stats.mitigation) * development.damageTaken
    return stats
end

local function positiveInteger(value)
    return type(value) == "number" and value >= 1 and value < math.huge and value == floor(value)
end

-- Personal level records award permanent points. Respecs and repeated levels
-- never advance the record; Mastery grants additional points independently.
function G.TalentProgress(hero)
    local limit, spent = #G.TalentList(hero), 0
    for _ in pairs(hero.talents) do
        spent = spent + 1
    end
    if not positiveInteger(hero.level) or limit == 0 then
        return nil, "The saved hero level or class is invalid. Your adventure has not been reset."
    end
    local progress = hero.talentProgress
    if progress == nil then
        -- Preserve both allocated and unspent points, including older saves
        -- whose heroes exceeded the new character-level cap.
        progress = {
            bestLevel = min(hero.level, C.heroLevelCap),
            earned = min(limit, max(spent, floor((hero.level + 1) / 2))),
        }
    elseif
        type(progress) ~= "table"
        or not positiveInteger(progress.bestLevel)
        or not positiveInteger(progress.earned)
        or progress.earned > limit
    then
        return nil, "The saved talent progression is invalid. Your adventure has not been reset."
    end
    local recordedBest = min(progress.bestLevel, C.heroLevelCap)
    local previous = 1 + floor((recordedBest - 1) / C.talentProgression.levelsPerPoint)
    local levelPoints = progress.levelPoints
    if levelPoints == nil then
        levelPoints = previous
    end
    if
        not positiveInteger(levelPoints)
        or levelPoints ~= previous
        or levelPoints > progress.earned
    then
        return nil, "The saved talent progression is invalid. Your adventure has not been reset."
    end
    local bestLevel = max(min(hero.level, C.heroLevelCap), recordedBest)
    local current = 1 + floor((bestLevel - 1) / C.talentProgression.levelsPerPoint)
    local earned = min(limit, progress.earned + current - levelPoints)
    if spent > earned then
        return nil,
            "The saved talent selections exceed earned points. Your adventure has not been reset."
    end
    progress.bestLevel, progress.earned, progress.levelPoints = bestLevel, earned, current
    hero.talentProgress = progress
    return progress, spent
end

function G.Points(hero)
    local progress, spent = G.TalentProgress(hero)
    return progress and max(0, progress.earned - spent) or 0
end

function G.NextTalentLevel(hero)
    local progress = G.TalentProgress(hero)
    if progress and progress.earned < #G.TalentList(hero) then
        local level = progress.levelPoints * C.talentProgression.levelsPerPoint + 1
        return level <= C.heroLevelCap and level or nil
    end
end

function G.LevelCap(_)
    return C.heroLevelCap
end

function G.TrainingCost(_)
    return { essence = 0, gold = 0 }
end

function G.Train(state, index)
    local hero = state.heroes[index]
    if not hero then
        return false, "Choose a hero."
    end
    return false,
        "Training is retired. Heroes grow naturally to level 60; Mastery unlocks at level 20."
end

function G.PriorityPresets(hero)
    local role = C.classByID[hero.class].role
    return {
        { id = "balanced", name = "Balanced", priority = "heal", healBelow = 65, specialCount = 2 },
        {
            id = "offense",
            name = "Offensive",
            priority = "attack",
            healBelow = 35,
            specialCount = 1,
        },
        {
            id = "support",
            name = role == "healer" and "Healing" or "Defensive",
            priority = "heal",
            healBelow = 85,
            specialCount = 3,
        },
    }
end

function G.ConfigurePreset(state, index, presetID)
    local hero = state.heroes[index]
    if not hero then
        return false, "Choose a hero."
    end
    for _, preset in ipairs(G.PriorityPresets(hero)) do
        if preset.id == presetID then
            hero.priority, hero.healBelow, hero.specialCount =
                preset.priority, preset.healBelow, preset.specialCount
            return true
        end
    end
    return false, "Choose a class priority preset."
end

function G.Configure(state, index, key, value)
    local hero = state.heroes[index]
    if not hero then
        return false
    end
    if key == "resourceThreshold" then
        if type(value) ~= "number" or value < 0 or value > 100 or value ~= math.floor(value) then
            return false
        end
    elseif key == "targetMode" then
        if not C.targetModeByID[value] then
            return false
        end
    elseif key == "priority" then
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
    local progress, spent = G.TalentProgress(hero)
    if not progress then
        return false, spent
    end
    if progress.earned <= spent then
        local level = G.NextTalentLevel(hero)
        return false,
            level and ("Reach idle level " .. level .. " for another permanent talent point.")
                or (
                    progress.earned < #G.TalentList(hero)
                        and "Earn Mastery XP from harder encounters for another permanent talent point."
                    or "All permanent talent points have been earned."
                )
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

function G.Travel(state, zone, automatic)
    local z = C.zoneByID[zone]
    if not z or not G.IsUnlocked(state, z) then
        return false, "Defeat harder encounters to unlock this destination."
    end
    if not automatic and state.routes.enabled and state.routes.selected then
        state.routes.run.paused = true
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
