local _, W = ...
local L = W.L
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
    local slots = math.max(1, #state.heroes, state.unlocks and state.unlocks.companions or 1)
    for i = 2, #C.companionMilestones do
        if state.best > C.companionMilestones[i] then
            slots = math.max(slots, i)
        end
    end
    slots = math.min(5, slots)
    if state.unlocks then state.unlocks.companions = slots end
    return slots
end

function G.ValidateUnlocks(state, legacy)
    local unlocked = state.unlocks
    local function whole(value, low, high)
        return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
    end
    if type(unlocked) ~= "table" or type(unlocked.zones) ~= "table"
        or not whole(unlocked.companions, 1, 5)
        or not whole(state.best, 1, 1000000000) or not whole(state.runBest, 1, 1000000000) then
        return false
    end
    for zone, known in pairs(unlocked.zones) do
        if not C.zoneByID[zone] or known ~= true then return false end
    end
    if legacy then
        -- Preserve discoveries earned under the earlier opening curve.
        for index, level in ipairs({ 0, 1, 3, 5, 7 }) do
            if state.best > level then unlocked.companions = math.max(unlocked.companions, index) end
        end
        for _, zone in ipairs(C.zones) do
            if zone.level <= state.runBest then unlocked.zones[zone.id] = true end
        end
        unlocked.zones[state.zone] = true
    end
    G.CompanionSlots(state)
    return true
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
                    and (L.FIND_ANOTHER_COMPANION_BY_DEFEATING_A_LEVEL_PREFIX .. level .. L.MILESTONE_BOSS_SUFFIX)
                or L.YOUR_COMPANY_IS_COMPLETE
    end
    return G.AddHero(state, classID)
end

function G.AddHero(state, classID, identity)
    local class = C.classByID[classID]
    if not class or #state.heroes >= 5 then
        return false, L.THE_PARTY_IS_FULL_OR_THIS_CLASS_IS_UNAVAILABLE
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
        talentRanksVersion = 2,
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
        hero.name
            .. (state.battle and L.JOINS_THE_NEXT_ENCOUNTER_SUFFIX or L.JOINED_THE_ADVENTURE_SUFFIX),
        nil,
        "recruit"
    )
    return true
end

function G.Replace(state, index, identity)
    local hero = state.heroes[index]
    if not hero or not hero.generated or hero.class ~= identity.class then
        return false, L.CHOOSE_A_GENERATED_HERO_OF_THE_SAME_CLASS
    end
    for _, existingHero in ipairs(state.heroes) do
        if existingHero.guid == identity.guid then
            return false, L.THIS_CHARACTER_IS_ALREADY_IN_THE_PARTY
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

-- Shared coefficients keep equipment scoring aligned with class combat scaling.
local function offenseWeights(hero)
    local primary = hero and C.primaryStats[hero.class]
    local caster = primary == "intellect"
    local class = hero and C.classByID[hero.class]
    local hybrid = class and class.role == "hybrid"
    return primary, caster and 0 or 0.325, (caster or hybrid) and 0.65 or 0
end

local function equipmentOutput(stats, hero)
    local primary, attackPower, spellPower = offenseWeights(hero)
    local damage = (stats[primary] or 0)
        + (stats.weaponDPS or 0)
        + (stats.attackPower or 0) * attackPower
        + (stats.spellPower or 0) * spellPower
    local healing = (stats.intellect or 0) * 0.8
        + (stats.spirit or 0) * 0.6
        + (stats.healingPower or 0)
        + (stats.spellPower or 0) * 0.6
    return damage, healing
end

function G.ItemPower(item, hero, extraUpgrade)
    local stats = G.ItemStats(item, hero, extraUpgrade)
    local damage, healing = equipmentOutput(stats, hero)
    local class = hero and C.classByID[hero.class]
    local healingWeight = class and (class.role == "healer" or class.role == "hybrid") and 0.5
        or 0.1
    local power = damage * 1.5
        + healing * healingWeight
        + (stats.stamina or 0) * 0.6
        + (stats.haste or 0) * 0.8
        + (stats.armor or 0) * 0.04
        + (stats.healthRegen or 0)
    return floor(power * 10 + 0.5) / 10
end

function G.ItemDescription(item, hero, compare)
    if not item then
        return L.EMPTY_SLOT
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
        lines[#lines + 1] = L.LOST_ON_EQUIP_SUFFIX
        lines[#lines + 1] = table.concat(lost, "\n")
    end
    local armorType = G.ItemArmorType(item)
    if armorType then
        lines[#lines + 1] = C.armorNames[armorType] or L.UNKNOWN_ARMOR
        if hero and not compare then
            local allowed, reason = G.CanWearArmor(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.slot == 1 then
        lines[#lines + 1] = C.weaponNames[G.ItemWeaponType(item)] or L.UNKNOWN_WEAPON
        if hero and not compare then
            local allowed, reason = G.CanUseWeapon(hero, item)
            if not allowed then
                lines[#lines + 1] = reason
            end
        end
    end
    if item.heirloom then
        lines[#lines + 1] = L.IDLE_HEIRLOOM_STATS_SCALE_WITH_HERO_LEVEL
    end
    if (item.upgrade or 0) > 0 then
        lines[#lines + 1] = L.IDLE_ENHANCEMENT .. item.upgrade * 10 .. L.STATS
    end
    if item.enchant then
        local enchant = C.enchantByID[item.enchant.id]
        lines[#lines + 1] = L.ENCHANTMENT_PREFIX .. (enchant and enchant.name or L.UNKNOWN) .. "."
    end
    if (item.forge or 0) > 0 then
        lines[#lines + 1] = L.TITANFORGE_PREFIX
            .. item.forge
            .. ": +"
            .. math.floor((G.ForgeMultiplier(item) - 1) * 100 + 0.5)
            .. L.BASE_POTENTIAL
    end
    local template = C.itemByID[item.itemID]
    if template and template.note then
        lines[#lines + 1] = C.itemNotes[item.itemID] or template.note
    end
    if item.itemID == 13074 then
        lines[#lines + 1] = L.SOURCE_BONUS_6_DEFENSE_NOT_SIMULATED
    end
    if item.itemID == 13040 then
        lines[#lines + 1] = L.SHADOWBOLT_PROC_IS_NOT_SIMULATED
    end
    if item.itemID == 13009 then
        lines[#lines + 1] = L.RESISTANCES_ARE_INFORMATIONAL_UNTIL_DAMAGE_SCHOOLS_ARE_SUPPORTED
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
        local replacement = byID[id] and id or legacy[id]
        local node = replacement and byID[replacement]
        local rank = learned == true and 1 or learned
        if hero.talentRanksVersion == nil and node and node.value ~= true
            and type(rank) == "number" and rank >= 1 and rank <= 5 and rank == floor(rank) then
            rank = min(rank, node.maxRanks)
        end
        if not node or type(rank) ~= "number" then
            selected[id] = nil
        elseif replacement ~= id then
            local previous = selected[replacement]
            previous = previous == true and 1 or type(previous) == "number" and previous or 0
            selected[id] = nil
            selected[replacement] = max(previous, rank)
        elseif learned ~= rank then
            selected[id] = rank
        end
    end
    if hero.talentRanksVersion == nil then hero.talentRanksVersion = 2 end
    return C.talentsByClass[hero.class] or {}
end

function G.TalentRank(hero, talent)
    local rank = hero.talents[talent.id]
    return rank == true and 1 or rank or 0
end

function G.TalentLimit(hero)
    local total = 0
    for _, node in ipairs(G.TalentList(hero)) do total = total + node.maxRanks end
    return total
end

function G.TalentEffects(hero)
    local effects = {}
    for _, talent in ipairs(G.TalentList(hero)) do
        if hero.talents[talent.id] then
            if talent.value == true then
                effects[talent.effect] = true
            else
                effects[talent.effect] = (effects[talent.effect] or 0) +
                    talent.value * G.TalentRank(hero, talent) / talent.maxRanks
                if talent.effect == "criticalDamage" or talent.effect == "criticalHealing"
                    or talent.effect == "superCriticalDamage" or talent.effect == "superCriticalHealing" then
                    local chance = talent.effect .. "Chance"
                    effects[chance] = (effects[chance] or 0) + G.TalentRank(hero, talent) / 100
                end
            end
        end
    end
    return effects
end

-- Only direct attacks and direct healing can critically strike; no recursive proc rolls.
function G.CriticalResult(state, hero, amount, healing)
    local effects = G.TalentEffects(hero)
    local criticalPower, superPower = effects.criticalDamage or 0, effects.superCriticalDamage or 0
    local criticalMinimum, superMinimum = effects.criticalDamageChance or 0, effects.superCriticalDamageChance or 0
    if healing then
        criticalPower, superPower = effects.criticalHealing or 0, effects.superCriticalHealing or 0
        criticalMinimum, superMinimum = effects.criticalHealingChance or 0, effects.superCriticalHealingChance or 0
    end
    local criticalChance = min(0.75, max(effects.criticalChance or 0, criticalMinimum))
    local superChance = min(0.2, max(effects.superCriticalChance or 0, superMinimum))
    if criticalChance + superChance <= 0 then return amount end
    local roll = G.Random(state, 10000)
    if roll <= floor(superChance * 10000 + 0.5) then return amount * (3 + superPower), "supercritical" end
    if roll <= floor((superChance + criticalChance) * 10000 + 0.5) then return amount * (1.5 + criticalPower), "critical" end
    return amount
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
    local offense, healing = equipmentOutput(total, hero)
    local mult = 1 + (state.prestigeStrength or state.prestiges) * 0.04
    local development = G.DevelopmentModifiers(state)
    local stats = G.ApplyTalentStats(hero, {
        attributes = total,
        hp = math.floor(
            (105 + hero.level * 19 + (total.stamina or 0) * 10) * mult * development.health
        ),
        damage = (9 + hero.level * 3 + offense) * mult * development.damage,
        healing = (15 + hero.level * 5 + healing) * (1 + heal) * mult * development.healing,
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
    local limit, spent, previousLimit = G.TalentLimit(hero), 0, 0
    if hero.talentRanksVersion ~= 2 then
        return nil, L.THE_SAVED_TALENT_PROGRESSION_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    for _, node in ipairs(G.TalentList(hero)) do
        previousLimit = previousLimit + (node.value == true and 1 or 5)
    end
    for id, rank in pairs(hero.talents) do
        local node = C.talentByClassID[hero.class][id]
        if not positiveInteger(rank) or rank > node.maxRanks then
            return nil, L.THE_SAVED_TALENT_PROGRESSION_IS_INVALID_YOUR_ADVENTURE_HAS
        end
        spent = spent + rank
    end
    if not positiveInteger(hero.level) or limit == 0 then
        return nil, L.THE_SAVED_HERO_LEVEL_OR_CLASS_IS_INVALID_YOUR
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
        or progress.earned > max(limit, previousLimit)
    then
        return nil, L.THE_SAVED_TALENT_PROGRESSION_IS_INVALID_YOUR_ADVENTURE_HAS
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
        return nil, L.THE_SAVED_TALENT_PROGRESSION_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    local bestLevel = max(min(hero.level, C.heroLevelCap), recordedBest)
    local current = 1 + floor((bestLevel - 1) / C.talentProgression.levelsPerPoint)
    local earned = max(progress.earned, min(limit, progress.earned + current - levelPoints))
    if spent > earned then
        return nil, L.THE_SAVED_TALENT_SELECTIONS_EXCEED_EARNED_POINTS_YOUR_ADVENTURE
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
    if progress and progress.earned < G.TalentLimit(hero) then
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
        return false, L.CHOOSE_A_HERO
    end
    return false, L.TRAINING_IS_RETIRED_HEROES_GROW_NATURALLY_TO_LEVEL_60
end

function G.PriorityPresets(hero)
    local role = C.classByID[hero.class].role
    return {
        {
            id = "balanced",
            name = L.BALANCED,
            priority = "heal",
            healBelow = 65,
            specialCount = 2,
        },
        {
            id = "offense",
            name = L.OFFENSIVE,
            priority = "attack",
            healBelow = 35,
            specialCount = 1,
        },
        {
            id = "support",
            name = role == "healer" and L.HEALING or L.DEFENSIVE,
            priority = "heal",
            healBelow = 85,
            specialCount = 3,
        },
    }
end

function G.ConfigurePreset(state, index, presetID)
    local hero = state.heroes[index]
    if not hero then
        return false, L.CHOOSE_A_HERO
    end
    for _, preset in ipairs(G.PriorityPresets(hero)) do
        if preset.id == presetID then
            hero.priority, hero.healBelow, hero.specialCount =
                preset.priority, preset.healBelow, preset.specialCount
            return true
        end
    end
    return false, L.CHOOSE_A_CLASS_PRIORITY_PRESET
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

function G.CanTalent(hero, talent, refund)
    G.TalentList(hero)
    local rank, previous, rows = G.TalentRank(hero, talent), 0, {}
    for _, node in ipairs(G.TalentList(hero)) do
        if node.path == talent.path then
            local selected = G.TalentRank(hero, node)
            rows[node.row] = (rows[node.row] or 0) + selected
            if node.row < talent.row then previous = previous + selected end
        end
    end
    if refund then
        if rank == 0 then return false end
        local earlier = 0
        for row = 1, 6 do
            local required = (row - 1) * C.talentProgression.pointsPerRow
            -- Preserve old builds, but do not invalidate an already satisfied requirement.
            if row > talent.row and (rows[row] or 0) > 0
                and earlier >= required and earlier - 1 < required then
                return false, L.REFUND_HIGHER_TALENT_ROWS_FIRST
            end
            earlier = earlier + (rows[row] or 0)
        end
        return true
    end
    if rank >= talent.maxRanks then return false, L.TALENT_MAX_RANK end
    local required = (talent.row - 1) * C.talentProgression.pointsPerRow
    if previous < required then
        return false, string.format(L.SPEND_POINTS_IN_EARLIER_TALENT_ROWS, required)
    end
    local progress, spent = G.TalentProgress(hero)
    if not progress then
        return false, spent
    end
    if progress.earned <= spent then
        local level = G.NextTalentLevel(hero)
        return false, level
            and (L.REACH_IDLE_LEVEL_PREFIX .. level .. L.FOR_ANOTHER_PERMANENT_TALENT_POINT_SUFFIX)
            or (progress.earned < G.TalentLimit(hero)
                and L.EARN_MASTERY_XP_FROM_HARDER_ENCOUNTERS_FOR_ANOTHER_PERMANENT
                or L.ALL_PERMANENT_TALENT_POINTS_HAVE_BEEN_EARNED)
    end
    return true
end

function G.Talent(state, index, id, refund)
    local hero = state.heroes[index]
    if not hero then
        return false
    end
    G.TalentList(hero)
    id = C.legacyTalentIDs[hero.class][id] or id
    if not C.talentByClassID[hero.class][id] then
        return false
    end
    local allowed, reason = G.CanTalent(hero, C.talentByClassID[hero.class][id], refund)
    if not allowed then
        return false, reason
    end
    local rank = G.TalentRank(hero, C.talentByClassID[hero.class][id]) + (refund and -1 or 1)
    hero.talents[id] = rank > 0 and rank or nil
    if refund then
        G.RefreshHero(state, index)
        return true
    end
    state.guide.talent = true
    G.RefreshHero(state, index)
    G.Emit(state, "unlock")
    state.discoveries["talent:" .. hero.class .. ":" .. id] = true
    return true
end

function G.IsUnlocked(state, z)
    return (state.unlocks and state.unlocks.zones[z.id]) == true
        or (z.unlockLevel or z.level) <= state.runBest
end

function G.Travel(state, zone, automatic)
    local z = C.zoneByID[zone]
    if not z or not G.IsUnlocked(state, z) then
        return false, L.DEFEAT_HARDER_ENCOUNTERS_TO_UNLOCK_THIS_DESTINATION
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
    G.Log(state, L.TRAVELING_TO_PREFIX .. z.name .. ".", nil, "travel")
    return true
end

-- Revisit an earned boss checkpoint without advancing or granting a reward.
function G.FarmZoneBoss(state, zone)
    local checkpoint = math.floor((state.safe[zone] or 0) / 5) * 5
    if checkpoint < 5 then
        return false, L.CLEAR_A_BOSS_IN_THIS_ZONE_FIRST
    end
    local ok, reason = G.Travel(state, zone)
    if not ok then
        return false, reason
    end
    if state.battle then
        for _, unit in ipairs(state.battle.heroes) do
            state.heroes[unit.id].health = math.max(0, unit.hp / unit.maxHP)
        end
    end
    state.battle, state.rest, state.stage, state.farming = nil, 0, checkpoint, true
    state.lastDefeat = nil
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

function G.LevelXP(level)
    return floor(level * 45 * (1 + max(0, level - 10) / 15))
end

function G.ExperienceResult(hero, amount, zone)
    local level, xp, cap = hero.level, hero.xp, G.LevelCap(hero)
    if zone then
        cap = math.min(cap, zone.heroLevelCap)
        if level >= cap then return level, xp end
        amount = floor(amount * math.min(1, (cap - level) / 5))
    end
    if level < cap then
        xp = xp + amount
    end
    while level < cap and xp >= G.LevelXP(level) do
        xp, level = xp - G.LevelXP(level), level + 1
    end
    if zone and level >= cap then
        xp = 0
    elseif level >= cap then
        xp = math.min(xp, G.LevelXP(level) - 1)
    end
    return level, xp
end

function G.Retry(state)
    if not state.farming then
        return false, L.YOUR_COMPANY_IS_ALREADY_ADVANCING
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
