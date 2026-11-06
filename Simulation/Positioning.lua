local _, W = ...
local P = { speed = 320, meleeRange = 190, rangedRange = 620 }
W.CombatPosition = P
local meleeClasses = { WARRIOR = true, PALADIN = true, ROGUE = true }

local function coordinate(value, fallback, lower, upper)
    if type(value) ~= "number" or value ~= value or value < lower or value > upper then
        return fallback
    end
    return value
end

-- Positions belong to the encounter, never to persistent hero progression.
-- Missing coordinates in older active saves receive the same safe spawn defaults.
function P.Ensure(state, battle)
    for i, unit in ipairs(battle.heroes) do
        local hero = state.heroes[i]
        unit.melee = hero and meleeClasses[hero.class] or false
        unit.homeX, unit.homeY = 40 + (i - 1) * 112, 96 + (i - 1) * 9
        unit.x = coordinate(unit.x, unit.homeX, 0, 1800)
        unit.y = coordinate(unit.y, unit.homeY, 88, 132)
    end
    for i, unit in ipairs(battle.enemies) do
        unit.melee = true
        unit.homeX, unit.homeY = 1320 + (i - 1) * 145, 100 + (i - 1) * 15
        unit.x = coordinate(unit.x, unit.homeX, 0, 1800)
        unit.y = coordinate(unit.y, unit.homeY, 88, 132)
    end
end

function P.Target(state, battle, enemy, heroIndex)
    local units = enemy and battle.heroes or battle.enemies
    local first
    local configuredHero = heroIndex and state.heroes[heroIndex]
    local mode = configuredHero and configuredHero.targetMode or "front"
    for _, unit in ipairs(units) do
        if unit.hp > 0 then
            if not enemy then
                if
                    not first
                    or (mode == "weakest" and unit.hp / unit.maxHP < first.hp / first.maxHP)
                    or (mode == "strongest" and unit.hp / unit.maxHP > first.hp / first.maxHP)
                then
                    first = unit
                end
                if mode == "front" then
                    return first
                end
            else
                first = first or unit
                local hero = state.heroes[unit.id]
                local talents = hero
                    and (W.Game.TalentEffects and W.Game.TalentEffects(hero) or hero.talents)
                if talents and (talents.guard or talents.soulLink) then
                    return unit
                end
                if unit.x > first.x then
                    first = unit
                end
            end
        end
    end
    return first
end

function P.InRange(unit, target)
    if not target then
        return false
    end
    local dx, dy = target.x - unit.x, target.y - unit.y
    local range = unit.melee and P.meleeRange or P.rangedRange
    return dx * dx + dy * dy <= range * range
end

local function destination(unit, target, enemy)
    unit.targetID = target and target.id or nil
    unit.targetEnemy = not enemy
    unit.destinationY = unit.homeY
    if not target or unit.hp <= 0 then
        unit.destinationX, unit.destinationY = unit.x, unit.y
    elseif enemy then
        local contact = 100 + (unit.id - 1) * 40
        unit.destinationX = math.min(unit.x, (unit.x + target.x + contact) / 2)
    elseif unit.melee then
        -- Keep the company left of its opponents, with room around the front unit.
        local contact = 110 + (unit.id - 1) * 14
        unit.destinationX = math.max(unit.x, math.min(640, (unit.x + target.x - contact) / 2))
    else
        -- Close into range even when enemies are held at the melee front.
        unit.destinationX = math.max(unit.homeX, target.x - P.rangedRange + 20)
    end
end

local function move(unit, seconds)
    local dx, dy = unit.destinationX - unit.x, unit.destinationY - unit.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local step = distance > 0.5 and math.min(1, seconds * P.speed / distance) or 1
    unit.x, unit.y = unit.x + dx * step, unit.y + dy * step
    unit.moving = step < 1 and unit.hp > 0
end

function P.Step(state, battle, seconds)
    P.Ensure(state, battle)
    local hero = P.Target(state, battle, true)
    -- Resolve every destination before moving any unit, so array order does not
    -- let later combatants pursue coordinates from a different simulation tick.
    for index, unit in ipairs(battle.heroes) do
        destination(unit, P.Target(state, battle, false, index), false)
    end
    for _, unit in ipairs(battle.enemies) do
        destination(unit, hero, true)
    end
    for _, unit in ipairs(battle.heroes) do
        move(unit, seconds)
    end
    for _, unit in ipairs(battle.enemies) do
        move(unit, seconds)
    end
end
