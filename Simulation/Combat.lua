local _, W = ...
local C, G, P = W.Content, W.Game, W.CombatPosition
local min, max, floor = math.min, math.max, math.floor

local function living(units)
    local out = {}
    for _, unit in ipairs(units) do
        if unit.hp > 0 then
            out[#out + 1] = unit
        end
    end
    return out
end

local function bleedingOrPoisoned(target)
    for _, dot in pairs(target.dots or {}) do
        if dot.physical then
            return true
        end
    end
    return false
end

-- Build once per step so talent edits take effect immediately without persisting caches.
local function activeTraits(state)
    local result = {}
    for i, hero in ipairs(state.heroes) do
        local traits = {}
        for _, node in ipairs(G.TalentList(hero)) do
            if node.trait and hero.talents[node.id] then
                traits[#traits + 1] = node.trait
            end
        end
        result[i] = traits
    end
    return result
end

local function burning(target)
    for _, dot in pairs(target.dots or {}) do
        if not dot.physical then
            return true
        end
    end
    return false
end

local function traitApplies(condition, battle, unit, target, kind)
    local subject = kind == "healing" and target or unit
    if condition == "opening" then
        return battle.elapsed <= 6
    elseif condition == "late" then
        return battle.elapsed > 12
    elseif condition == "boss" then
        return battle.boss
    elseif condition == "healthy" then
        return subject.hp > subject.maxHP * 0.8
    elseif condition == "wounded" then
        return subject.hp < subject.maxHP * 0.5
    elseif condition == "critical" then
        return subject.hp < subject.maxHP * 0.3
    elseif condition == "shielded" then
        return (subject.shield or 0) > 0
    elseif condition == "ally" then
        return target ~= unit
    elseif condition == "patient" then
        return (unit.casts or 0) >= 3
    elseif condition == "quick" then
        return (unit.swings or 0) >= 3
    elseif condition == "unhurt" then
        return subject.hp == subject.maxHP
    elseif condition == "rescue" then
        return subject.hp < subject.maxHP * 0.2
    elseif condition == "protect" then
        for _, ally in ipairs(battle.heroes) do
            if ally ~= unit and ally.hp > 0 and ally.hp < ally.maxHP * 0.3 then
                return true
            end
        end
        return false
    elseif condition == "armored" then
        return unit.hp / unit.maxHP > target.hp / target.maxHP
    end
    local count = 0
    for _, enemy in ipairs(battle.enemies) do
        if enemy.hp > 0 then
            count = count + 1
            if kind == "healing" then
                if condition == "execute" and enemy.hp < enemy.maxHP * 0.35 then
                    return true
                elseif condition == "bleed" and bleedingOrPoisoned(enemy) then
                    return true
                elseif condition == "burning" and burning(enemy) then
                    return true
                end
            end
        end
    end
    if condition == "group" then
        return count >= 2
    elseif condition == "solo" then
        return count == 1
    elseif condition == "outnumbered" then
        local allies = 0
        for _, ally in ipairs(battle.heroes) do
            if ally.hp > 0 then
                allies = allies + 1
            end
        end
        return count > allies
    elseif kind ~= "healing" and condition == "burning" then
        return burning(target)
    elseif kind ~= "healing" and condition == "execute" then
        return target.hp < target.maxHP * 0.35
    elseif kind ~= "healing" and condition == "bleed" then
        return bleedingOrPoisoned(target)
    end
    return false
end

local function traitMultiplier(traits, kind, battle, unit, target)
    local bonus = 0
    for _, trait in ipairs(traits) do
        if trait.kind == kind and traitApplies(trait.condition, battle, unit, target, kind) then
            bonus = bonus + trait.amount
        end
    end
    -- Defensive bonuses stack additively, with a floor to keep damage meaningful.
    return kind == "defense" and max(0.4, 1 - bonus) or 1 + bonus
end

function G.StartBattle(state)
    if #state.heroes == 0 then
        return
    end
    state.encounter = (state.encounter or 0) + 1
    local zone = C.zoneByID[state.zone]
    local level = zone.level + floor((state.stage - 1) / 5)
    local boss = state.stage % 5 == 0
    local battle =
        { heroes = {}, enemies = {}, elapsed = 0, boss = boss, level = level, stage = state.stage }
    for i, hero in ipairs(state.heroes) do
        local stats = G.Stats(state, hero)
        battle.heroes[i] = {
            id = i,
            name = hero.name,
            hp = max(1, floor(stats.hp * (hero.health or 1))),
            maxHP = stats.hp,
            damage = stats.damage,
            healing = stats.healing,
            haste = stats.haste,
            mitigation = stats.mitigation,
            regen = stats.regen,
            cd = 0,
            attackCD = i * 0.1,
            shield = 0,
        }
    end
    -- The opening adventure is fought alone, before the first discovery.
    local opening = G.CompanionSlots(state) == 1
    local count = boss and 1 or min(3, #state.heroes)
    for i = 1, count do
        local hp = floor(
            (60 + level * 24) * 1.16 ^ (level - 1) * (boss and min(4, #state.heroes + 1) or 1)
        )
        battle.enemies[i] = {
            id = i,
            name = boss and zone.boss or zone.enemies[(state.stage + i - 2) % #zone.enemies + 1],
            hp = hp,
            maxHP = hp,
            damage = (6 + level * 3)
                * 1.12 ^ (level - 1)
                * (boss and (opening and 1.2 or 1.8) or 1),
            attackCD = 1 + i * 0.3,
        }
    end
    P.Ensure(state, battle)
    state.battle = battle
    G.Emit(state, "encounter", { boss = boss })
end

local function hurt(state, target, amount, enemy, source, passive)
    amount = floor(max(1, amount))
    local wasAlive = target.hp > 0
    target.hp = max(0, target.hp - amount)
    G.Emit(
        state,
        "hit",
        { target = target.id, enemy = enemy, amount = amount, source = source, passive = passive }
    )
    if wasAlive and target.hp == 0 then
        G.Emit(state, "death", { target = target.id, enemy = enemy })
    end
end

local function heal(state, target, amount, source)
    amount = floor(min(amount, target.maxHP - target.hp))
    target.hp = min(target.maxHP, target.hp + amount)
    G.Emit(state, "heal", { target = target.id, amount = amount, source = source })
    return amount
end

local function victory(state, battle)
    local z = C.zoneByID[state.zone]
    local xp = 8 + battle.level * 3
    local gold = 3 + battle.level * 2
    local results = {}
    -- Recruitment may extend the party during combat. Only the encounter's
    -- original participants fought; newcomers join when the next battle starts.
    -- Prepare every result before committing progression or shared rewards.
    for _, unit in ipairs(battle.heroes) do
        local hero = state.heroes[unit.id]
        if not hero then
            state.battle = nil
            state.rest = 2
            G.Log(state, "The party regrouped before the next encounter.")
            return
        end
        local health = min(
            1,
            (unit.hp > 0 and unit.hp / unit.maxHP or 0.3)
                + 0.06
                + (G.TalentEffects(hero).renew and 0.08 or 0)
        )
        local level, experience = G.ExperienceResult(hero, xp)
        results[#results + 1] =
            { hero = hero, id = unit.id, health = health, xp = experience, level = level }
    end
    for _, result in ipairs(results) do
        result.hero.health = result.health
        result.hero.xp = result.xp
        local previousLevel = result.hero.level
        result.hero.level = result.level
        if result.level > previousLevel then
            G.Emit(state, "levelup", { target = result.id })
        end
        if previousLevel < G.LevelCap(result.hero) and result.level == G.LevelCap(result.hero) then
            G.Log(
                state,
                result.hero.name
                    .. " reached idle level "
                    .. result.level
                    .. " (maximum). Train to raise the level cap."
            )
        end
    end
    state.gold = state.gold + gold
    state.materials[z.material] = state.materials[z.material] + (battle.boss and 5 or 1)
    state.stats.victories = state.stats.victories + 1
    state.stats.kills = state.stats.kills + #battle.enemies
    if G.Random(state, 100) <= 35 or battle.boss or state.stats.victories == 1 then
        local item = G.ZoneLoot(state, battle.level)
        if item then
            G.Loot(state, item)
        end
    end
    local previousSafe = state.safe[state.zone] or 0
    state.safe[state.zone] = max(state.safe[state.zone] or 0, battle.stage)
    if battle.boss then
        local previousSlots = G.CompanionSlots(state)
        local previousBest = state.runBest
        state.runBest = max(state.runBest, battle.level + 1)
        local unlockedDestination = false
        for _, destination in ipairs(C.zones) do
            if destination.level > previousBest and destination.level <= state.runBest then
                unlockedDestination = true
                break
            end
        end
        state.best = max(state.best, state.runBest)
        local discovered = G.CompanionSlots(state) > previousSlots
        if discovered then
            G.Log(
                state,
                "You found a new companion! Open Party to choose their class and welcome them."
            )
        end
        if discovered or unlockedDestination then
            G.Emit(state, "unlock")
        end
        if battle.level >= 8 then
            state.prestigeUnlocked = true
        end
        G.Log(
            state,
            z.boss
                .. " defeated. "
                .. z.name
                .. " cleared through encounter "
                .. battle.stage
                .. ". New paths open.",
            battle.stage <= previousSafe or state.runBest <= previousBest
        )
    end
    if not state.farming then
        state.stage = state.stage + 1
    end
    G.Emit(state, "victory", { gold = gold, xp = xp, boss = battle.boss })
    state.battle = nil
    state.rest = 2
end

function G.Step(state, seconds)
    if #state.heroes == 0 then
        return
    end
    state.clock = state.clock + seconds
    if state.rest and state.rest > 0 then
        state.rest = max(0, state.rest - seconds)
        return
    end
    if not state.battle then
        G.StartBattle(state)
        return
    end
    local battle = state.battle
    battle.elapsed = battle.elapsed + seconds
    P.Step(state, battle, seconds)
    local traits = activeTraits(state)
    for _, enemy in ipairs(battle.enemies) do
        for source, dot in pairs(enemy.dots or {}) do
            local owner = battle.heroes[source]
            if enemy.hp > 0 and owner and owner.hp > 0 then
                dot.pending = (dot.pending or 0) + dot.damage * min(seconds, dot.remaining)
                local amount = floor(dot.pending)
                if amount > 0 then
                    hurt(state, enemy, amount, true, source, true)
                    dot.pending = dot.pending - amount
                end
            end
            dot.remaining = dot.remaining - seconds
            if dot.remaining <= 0 then
                enemy.dots[source] = nil
            end
        end
    end
    for i, unit in ipairs(battle.heroes) do
        if unit.hp > 0 then
            local hero = state.heroes[i]
            local class = C.classByID[hero.class]
            local talents = G.TalentEffects(hero)
            local enemies = living(battle.enemies)
            if #enemies == 0 then
                break
            end
            unit.hp = min(unit.maxHP, unit.hp + (unit.regen or 0) * seconds)
            if unit.rejuvenation then
                local hot = unit.rejuvenation
                unit.hp = min(unit.maxHP, unit.hp + unit.maxHP * 0.01 * min(seconds, hot))
                unit.rejuvenation = hot > seconds and hot - seconds or nil
            end
            unit.cd = max(0, unit.cd - seconds * (unit.haste or 1))
            unit.attackCD = max(0, unit.attackCD - seconds * (unit.haste or 1))
            local allies = living(battle.heroes)
            local lowest = allies[1]
            for _, a in ipairs(allies) do
                if a.hp / a.maxHP < lowest.hp / lowest.maxHP then
                    lowest = a
                end
            end
            local canHeal = class.role == "healer" or class.role == "hybrid"
            local recovery = canHeal and lowest or unit
            local healNeeded = recovery.hp / recovery.maxHP * 100 < hero.healBelow
            local specialNeeded = #enemies >= hero.specialCount
            if unit.cd == 0 then
                local action = "attack"
                if hero.priority == "heal" and healNeeded then
                    action = "heal"
                elseif hero.priority == "special" and specialNeeded then
                    action = "special"
                elseif hero.priority == "attack" then
                    action = "attack"
                elseif healNeeded then
                    action = "heal"
                elseif specialNeeded then
                    action = "special"
                end
                local acted = false
                if action == "heal" then
                    acted = true
                    local restored = heal(
                        state,
                        recovery,
                        unit.healing
                            * (talents.sustain and 1.6 or 1)
                            * traitMultiplier(traits[i], "healing", battle, unit, recovery),
                        i
                    )
                    if talents.beacon and recovery ~= unit then
                        heal(state, unit, restored * 0.4, i)
                    end
                    if talents.holyShield then
                        recovery.shield = max(recovery.shield or 0, unit.healing * 0.3)
                    end
                    if talents.hymn then
                        for _, ally in ipairs(allies) do
                            if ally ~= recovery then
                                heal(state, ally, unit.healing * 0.25, i)
                            end
                        end
                    end
                    if talents.rejuvenation then
                        recovery.rejuvenation = 6
                    end
                    unit.cd = talents.tides and recovery.hp < recovery.maxHP * 0.5 and 4 or 6
                elseif P.InRange(unit, enemies[1]) then
                    acted = true
                    local targets = (action == "special" or talents.cleave) and enemies
                        or { enemies[1] }
                    for _, target in ipairs(targets) do
                        local amount = unit.damage
                            * (action == "special" and 0.95 or 1.7)
                            * traitMultiplier(traits[i], "strike", battle, unit, target)
                        if talents.aim and target.hp > target.maxHP * 0.8 then
                            amount = amount * 1.45
                        end
                        if talents.opener and not unit.opened then
                            amount = amount * 2
                        end
                        if talents.deathWord and target.hp < target.maxHP * 0.2 then
                            amount = amount * 1.8
                        end
                        if talents.predator and bleedingOrPoisoned(target) then
                            amount = amount * 1.35
                        end
                        if talents.arcane then
                            amount = amount * (1 + min(6, unit.casts or 0) * 0.05)
                        end
                        if talents.starfall and action == "special" then
                            amount = amount * 1.4
                        end
                        if talents.execute and target.hp / target.maxHP < 0.35 then
                            amount = amount * 1.5
                        end
                        if P.InRange(unit, target) then
                            amount = min(target.hp, amount)
                            hurt(state, target, amount, true, i)
                            if
                                talents.wounds
                                or talents.ignite
                                or talents.burningWounds
                                or talents.trap and action == "special"
                            then
                                target.dots = target.dots or {}
                                target.dots[i] = {
                                    damage = talents.wounds and unit.damage * 0.18
                                        or talents.ignite and amount * 0.2
                                        or talents.burningWounds and unit.damage * 0.12
                                        or unit.damage * 0.25,
                                    remaining = talents.wounds and 4
                                        or talents.burningWounds and 6
                                        or 3,
                                    physical = talents.wounds or false,
                                }
                            end
                            if talents.bloodthirst and unit.hp < unit.maxHP * 0.5 then
                                heal(state, unit, unit.maxHP * 0.08, i)
                            end
                            if talents.judgement or talents.atonement then
                                heal(state, lowest, amount * (talents.judgement and 0.2 or 0.15), i)
                            end
                            if talents.drain then
                                heal(
                                    state,
                                    unit,
                                    amount * (unit.hp < unit.maxHP * 0.35 and 0.6 or 0.3),
                                    i
                                )
                            end
                            if talents.shadowfury and action == "special" then
                                target.attackCD = target.attackCD + 2
                            end
                            if talents.leech then
                                heal(state, unit, amount * 0.12, i)
                            end
                            if talents.control then
                                target.attackCD = target.attackCD + 1
                            end
                        end
                    end
                    if talents.chain then
                        for _, target in ipairs(enemies) do
                            if
                                target ~= enemies[1]
                                and target.hp > 0
                                and P.InRange(unit, target)
                            then
                                hurt(state, target, unit.damage * 0.35, true, i)
                            end
                        end
                    end
                    unit.opened = true
                    unit.casts = (unit.casts or 0) + 1
                    unit.cd = talents.starfall and action == "special" and 5
                        or talents.haste and 4.2
                        or 6
                end
                if acted then
                    G.Emit(state, "cast", { source = i, action = action })
                end
            end
            if
                unit.attackCD == 0
                and #living(battle.enemies) > 0
                and P.InRange(unit, living(battle.enemies)[1])
            then
                local targets = talents.cleave and living(battle.enemies)
                    or { living(battle.enemies)[1] }
                unit.swings = (unit.swings or 0) + 1
                for _, target in ipairs(targets) do
                    if P.InRange(unit, target) then
                        local amount = unit.damage
                            * (
                                talents.beast and 1.25
                                or talents.windfury and unit.swings % 3 == 0 and 2
                                or 1
                            )
                        amount = amount * traitMultiplier(traits[i], "basic", battle, unit, target)
                        if talents.atonement then
                            heal(state, lowest, min(target.hp, amount) * 0.15, i)
                        end
                        hurt(state, target, amount, true, i)
                        if talents.poison then
                            target.dots = target.dots or {}
                            target.dots[i] =
                                { damage = unit.damage * 0.12, remaining = 6, physical = true }
                        end
                        if talents.frost then
                            target.attackCD = target.attackCD + 0.3
                        end
                    end
                end
                if talents.potency then
                    unit.cd = max(0, unit.cd - 0.5)
                end
                unit.attackCD = 2
            end
        end
    end
    if #living(battle.enemies) == 0 then
        victory(state, battle)
        return
    end
    for _, enemy in ipairs(battle.enemies) do
        if enemy.hp > 0 then
            enemy.attackCD = max(0, enemy.attackCD - seconds)
            if enemy.attackCD == 0 then
                local allies = living(battle.heroes)
                if #allies == 0 then
                    break
                end
                local target = P.Target(state, battle, true)
                if P.InRange(enemy, target) then
                    local talent = G.TalentEffects(state.heroes[target.id])
                    local amount = enemy.damage
                        * (talent.guard and 0.75 or 1)
                        * (1 - (target.mitigation or 0))
                        * traitMultiplier(traits[target.id], "defense", battle, target, enemy)
                    if talent.guard then
                        G.Emit(state, "defense")
                    end
                    if talent.soulLink and target.hp > target.maxHP * 0.5 then
                        amount = amount * 0.8
                    end
                    local absorbed = min(target.shield or 0, amount)
                    target.shield = (target.shield or 0) - absorbed
                    amount = amount - absorbed
                    if amount > 0 then
                        hurt(state, target, amount, false, enemy.id)
                    end
                    if talent.revenge then
                        target.cd = max(0, target.cd - 1)
                    end
                    if talent.thorns and amount > 0 then
                        hurt(state, enemy, amount * 0.30, true, target.id, true)
                    end
                    enemy.attackCD = 2.4
                end
            end
        end
    end
    if #living(battle.enemies) == 0 then
        victory(state, battle)
        return
    end
    if #living(battle.heroes) == 0 or battle.elapsed >= 180 then
        state.farming = true
        state.stage = max(1, (state.safe[state.zone] or 1))
        state.battle = nil
        state.rest = 4
        for _, hero in ipairs(state.heroes) do
            hero.health = 1
        end
        state.lastDefeat = "The party could not sustain the incoming damage. Farming encounter "
            .. state.stage
            .. "."
        G.Log(state, state.lastDefeat)
        G.Emit(state, "defeat")
    end
end

function G.Advance(state, seconds)
    local steps = floor(seconds / 0.25)
    for _ = 1, steps do
        G.Step(state, 0.25)
    end
end
