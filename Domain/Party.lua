local _, W = ...
local C, G = W.Content, W.Game
local min, max, floor = math.min, math.max, math.floor

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

function G.ItemPower(item, hero)
    if not item then
        return 0
    end
    if item.heirloom then
        return 3 + hero.level * 2 + (item.upgrade or 0) * 2
    end
    return item.power + (item.upgrade or 0) * 2
end

function G.Stats(state, hero)
    local power, armor, heal = 0, 0, 0
    for slot, item in pairs(hero.gear) do
        local p = G.ItemPower(item, hero)
        if slot == 2 or slot == 3 then
            armor = armor + p
        else
            power = power + p
        end
        if item.effect == "renewal" then
            heal = heal + 0.06
        end
    end
    local mult = 1 + state.prestiges * 0.04
    return {
        hp = floor((105 + hero.level * 19 + armor * 6) * mult),
        damage = (9 + hero.level * 3 + power * 0.65) * mult,
        healing = (15 + hero.level * 5 + power * 0.6) * (1 + heal) * mult,
    }
end

function G.Points(hero)
    local count = 0
    for _, v in pairs(hero.talents) do
        if v then
            count = count + 1
        end
    end
    return max(0, min(9, floor((hero.level + 1) / 2)) - count)
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

function G.Talent(state, index, id)
    local hero = state.heroes[index]
    if not hero then
        return false
    end
    local valid = false
    for _, t in ipairs(C.talents) do
        if t.id == id then
            valid = true
        end
    end
    if not valid then
        return false
    end
    if hero.talents[id] then
        hero.talents[id] = nil
        return true
    end
    if G.Points(hero) < 1 then
        return false, "Gain more idle levels to earn talent points."
    end
    hero.talents[id] = true
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
