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
    local count = boss and 1 or 3
    for i = 1, count do
        local hp = floor((60 + level * 24) * 1.16 ^ (level - 1) * (boss and 4 or 1))
        battle.enemies[i] = {
            id = i,
            name = boss and zone.boss or zone.enemies[(state.stage + i - 2) % #zone.enemies + 1],
            hp = hp,
            maxHP = hp,
            damage = (6 + level * 3) * 1.12 ^ (level - 1) * (boss and 1.8 or 1),
            attackCD = 1 + i * 0.3,
        }
    end
    P.Ensure(state, battle)
    state.battle = battle
    G.Emit(state, "encounter", { boss = boss })
end

local function hurt(state, target, amount, enemy, source)
    amount = floor(max(1, amount))
    local wasAlive = target.hp > 0
    target.hp = max(0, target.hp - amount)
    G.Emit(state, "hit", { target = target.id, enemy = enemy, amount = amount, source = source })
    if wasAlive and target.hp == 0 then
        G.Emit(state, "death", { target = target.id, enemy = enemy })
    end
end

local function heal(state, target, amount, source)
    amount = floor(min(amount, target.maxHP - target.hp))
    target.hp = min(target.maxHP, target.hp + amount)
    G.Emit(state, "heal", { target = target.id, amount = amount, source = source })
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
                + (hero.talents.renew and 0.08 or 0)
        )
        local level, experience = G.ExperienceResult(hero, xp)
        results[#results + 1] = { hero = hero, health = health, xp = experience, level = level }
    end
    for _, result in ipairs(results) do
        result.hero.health = result.health
        result.hero.xp = result.xp
        local previousLevel = result.hero.level
        result.hero.level = result.level
        if result.level > previousLevel then
            G.Emit(state, "levelup")
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
    if G.Random(state, 100) <= 35 or battle.boss then
        local item = G.ZoneLoot(state, battle.level)
        if item then
            G.Loot(state, item)
        end
    end
    local previousSafe = state.safe[state.zone] or 0
    state.safe[state.zone] = max(state.safe[state.zone] or 0, battle.stage)
    if battle.boss then
        local previousBest = state.runBest
        state.runBest = max(state.runBest, battle.level + 1)
        for _, destination in ipairs(C.zones) do
            if destination.level > previousBest and destination.level <= state.runBest then
                G.Emit(state, "unlock")
                break
            end
        end
        state.best = max(state.best, state.runBest)
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
    for i, unit in ipairs(battle.heroes) do
        if unit.hp > 0 then
            local hero = state.heroes[i]
            local class = C.classByID[hero.class]
            local enemies = living(battle.enemies)
            if #enemies == 0 then
                break
            end
            unit.hp = min(unit.maxHP, unit.hp + (unit.regen or 0) * seconds)
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
                    heal(state, recovery, unit.healing * (hero.talents.sustain and 1.6 or 1), i)
                    unit.cd = 6
                elseif P.InRange(unit, enemies[1]) then
                    acted = true
                    local targets = (action == "special" or hero.talents.cleave) and enemies
                        or { enemies[1] }
                    for _, target in ipairs(targets) do
                        local amount = unit.damage * (action == "special" and 0.95 or 1.7)
                        if hero.talents.execute and target.hp / target.maxHP < 0.35 then
                            amount = amount * 1.5
                        end
                        if P.InRange(unit, target) then
                            hurt(state, target, amount, true, i)
                            if hero.talents.leech then
                                heal(state, unit, amount * 0.12, i)
                            end
                            if hero.talents.control then
                                target.attackCD = target.attackCD + 1
                            end
                        end
                    end
                    unit.cd = hero.talents.haste and 4.2 or 6
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
                local targets = hero.talents.cleave and living(battle.enemies)
                    or { living(battle.enemies)[1] }
                for _, target in ipairs(targets) do
                    if P.InRange(unit, target) then
                        hurt(state, target, unit.damage, true, i)
                    end
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
                    local talent = state.heroes[target.id].talents
                    local amount = enemy.damage
                        * (talent.guard and 0.75 or 1)
                        * (1 - (target.mitigation or 0))
                    if talent.guard then
                        G.Emit(state, "defense")
                    end
                    hurt(state, target, amount, false, enemy.id)
                    if talent.thorns then
                        hurt(state, enemy, amount * 0.30, true, target.id)
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
