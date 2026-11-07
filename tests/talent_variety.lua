local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
local function setup(class)
    local s = G.New(1000)
    assert(G.AddHero(s, class))
    local h = s.heroes[1]
    h.level = 60
    return s, h
end
local function selectEffect(h, effect)
    for _, node in ipairs(G.TalentList(h)) do
        if node.effect == effect then
            h.talents[node.id] = node.maxRanks
            return node
        end
    end
    error("Missing effect " .. effect)
end
local function battle(s)
    G.StartBattle(s)
    local unit, enemy = s.battle.heroes[1], s.battle.enemies[1]
    unit.x, unit.y, enemy.x, enemy.y = 600, 100, 700, 100
    unit.cd, unit.attackCD, unit.resource = 100, 100, 100
    enemy.hp, enemy.maxHP, enemy.attackCD = 100000, 100000, 100
    return unit, enemy
end
local function withRoll(value, run)
    local original = G.Random
    G.Random = function(s, n)
        if n == 10000 then
            return value
        end
        return original(s, n)
    end
    local ok, reason = pcall(run)
    G.Random = original
    assert(ok, reason)
end
case(
    "Talent trees avoid repeated effect/condition pairs and mix caps independently of stats",
    function()
        local capsByEffect = {}
        for _, class in ipairs(C.classes) do
            local seen = {}
            for _, node in ipairs(C.talentsByClass[class.id]) do
                local trait = node.trait
                local key = node.path
                    .. ":"
                    .. node.effect
                    .. ":"
                    .. (trait and trait.kind or "")
                    .. ":"
                    .. (trait and trait.condition or "")
                assert(not seen[key], node.name .. " repeats " .. (seen[key] or ""))
                seen[key] = node.name
                capsByEffect[node.effect] = capsByEffect[node.effect] or {}
                capsByEffect[node.effect][node.maxRanks] = true
            end
        end
        for _, effect in ipairs({ "attackSpeed", "criticalChance", "abilityEfficiency" }) do
            assert(capsByEffect[effect][2] and capsByEffect[effect][3] and capsByEffect[effect][5])
        end
    end
)
case("Attack speed and ability recovery affect separate live clocks", function()
    local s, h = setup("WARRIOR")
    selectEffect(h, "attackSpeed")
    local unit = battle(s)
    G.Step(s, 0.25)
    assert(math.abs(unit.attackCD - 99.7125) < 0.000001 and unit.cd == 99.75)
    local other, rogue = setup("ROGUE")
    selectEffect(rogue, "cooldownRate")
    unit = battle(other)
    G.Step(other, 0.25)
    assert(math.abs(unit.cd - 99.7125) < 0.000001 and unit.attackCD == 99.75)
end)
case(
    "Critical and super-critical outcomes are exclusive and scale damage independently of heals",
    function()
        local s, h = setup("MAGE")
        selectEffect(h, "criticalChance")
        selectEffect(h, "superCriticalChance")
        withRoll(400, function()
            local amount, kind = G.CriticalResult(s, h, 100, false)
            assert(amount == 300 and kind == "supercritical")
        end)
        withRoll(401, function()
            local amount, kind = G.CriticalResult(s, h, 100, false)
            assert(amount == 150 and kind == "critical")
        end)
        withRoll(1601, function()
            local amount, kind = G.CriticalResult(s, h, 100, false)
            assert(amount == 100 and kind == nil)
        end)
        local power, warrior = setup("WARRIOR")
        selectEffect(warrior, "criticalDamage")
        withRoll(1, function()
            assert(G.CriticalResult(power, warrior, 100, false) == 200)
            local amount, kind = G.CriticalResult(power, warrior, 100, true)
            assert(amount == 100 and kind == nil)
        end)
    end
)
case("Critical effects reach actual combat events without changing unselected fights", function()
    local s, h = setup("WARRIOR")
    selectEffect(h, "criticalChance")
    local unit, enemy = battle(s)
    unit.attackCD = 0
    local hp = enemy.hp
    withRoll(1, function()
        G.Step(s, 0.25)
    end)
    assert(hp - enemy.hp == math.floor(unit.damage * 1.5))
    local found
    for _, event in ipairs(s.events) do
        if event.kind == "hit" and event.enemy then
            found = event.critical
        end
    end
    assert(found == "critical")
    local untouched, plain = setup("WARRIOR")
    local seed = untouched.seed
    assert(G.CriticalResult(untouched, plain, 100, false) == 100 and untouched.seed == seed)
end)
case("Critical and super-critical direct healing use their own power bonuses", function()
    for _, spec in ipairs({
        { "criticalHealing", "critical", 200 },
        { "superCriticalHealing", "supercritical", 375 },
    }) do
        local s, h = setup("PRIEST")
        selectEffect(h, spec[1])
        h.priority, h.healBelow = "heal", 100
        local unit = battle(s)
        unit.hp, unit.healing, unit.cd = 100, 100, 0
        withRoll(1, function()
            G.Step(s, 0.25)
        end)
        assert(unit.hp == 100 + spec[3])
        local found
        for _, event in ipairs(s.events) do
            if event.kind == "heal" then
                found = event.critical
            end
        end
        assert(found == spec[2])
    end
end)
case("Resource talents change actual income and cost while preserving threshold checks", function()
    local s, h = setup("MAGE")
    selectEffect(h, "resourceGain")
    local unit = battle(s)
    unit.resource = 10
    G.Step(s, 0.25)
    assert(math.abs(unit.resource - 11.26) < 0.000001)
    selectEffect(h, "abilityEfficiency")
    local cost = G.HeroAbilityCost(h, "attack")
    assert(cost == 27)
    unit.resource, h.resourceThreshold = cost, 50
    assert(not G.SpendHeroResource(h, unit, "attack") and unit.resource == cost)
    h.resourceThreshold = 0
    assert(G.SpendHeroResource(h, unit, "attack") and unit.resource == 0)
    assert(G.Load(G.Copy(s), 1000))
end)
case(
    "Damage-over-time talents strengthen existing ticks and respond immediately to refunds",
    function()
        local s, h = setup("WARRIOR")
        local node = selectEffect(h, "dotDamage")
        selectEffect(h, "criticalChance")
        local _, enemy = battle(s)
        enemy.dots = { [1] = { damage = 20, remaining = 4, physical = true } }
        local hp = enemy.hp
        withRoll(1, function()
            G.Step(s, 1)
        end)
        assert(hp - enemy.hp == 24)
        h.talents[node.id] = nil
        hp = enemy.hp
        G.Step(s, 1)
        assert(hp - enemy.hp == 20)
    end
)
case("Direct overhealing refreshes a bounded shield instead of stacking it indefinitely", function()
    local s, h = setup("PRIEST")
    selectEffect(h, "overhealShield")
    h.priority, h.healBelow = "heal", 100
    local unit = battle(s)
    unit.hp, unit.healing, unit.cd = unit.maxHP - 10, 100, 0
    G.Step(s, 0.25)
    assert(unit.hp == unit.maxHP and math.abs(unit.shield - 18) < 0.000001)
    unit.hp, unit.healing, unit.cd, unit.resource = unit.maxHP - 1, 1000000, 0, 100
    G.Step(s, 0.25)
    assert(unit.shield == unit.maxHP * 0.2)
    unit.hp, unit.healing, unit.cd, unit.resource = unit.maxHP - 1, 1000000, 0, 100
    G.Step(s, 0.25)
    assert(unit.shield == unit.maxHP * 0.2)
    assert(G.Load(G.Copy(s), 1000))
end)
case("Varied talents preserve deterministic combat across a saved encounter", function()
    local s, h = setup("MAGE")
    selectEffect(h, "criticalChance")
    selectEffect(h, "superCriticalChance")
    selectEffect(h, "cooldownRate")
    s.farming, s.safe.elwynn, s.stage = true, 5, 5
    G.StartBattle(s)
    for _ = 1, 4 do
        G.Step(s, 0.25)
    end
    local loaded = assert(G.Load(G.Copy(s), 1000))
    for _ = 1, 800 do
        G.Step(s, 0.25)
        G.Step(loaded, 0.25)
    end
    assert(s.seed == loaded.seed and s.gold == loaded.gold)
    assert(s.stats.victories == loaded.stats.victories and s.heroes[1].xp == loaded.heroes[1].xp)
end)

case("Critical output follows the weighted curve without multiplying critical tiers", function()
    local s, h = setup("MAGE")
    selectEffect(h, "criticalChance")
    selectEffect(h, "superCriticalChance")
    s.seed = 17
    local total = 0
    for _ = 1, 20000 do
        total = total + G.CriticalResult(s, h, 100, false)
    end
    -- 84% normal + 12% at 1.5x + 4% at 3x = 1.14x expected output.
    assert(math.abs(total / 2000000 - 1.14) < 0.02)
    selectEffect(h, "superCriticalDamage")
    withRoll(1, function()
        assert(G.CriticalResult(s, h, 100, false) == 375)
    end)
end)
case(
    "Offline critical damage and healing use their weighted probabilities without rolls",
    function()
        local s, h = setup("MAGE")
        selectEffect(h, "criticalChance")
        selectEffect(h, "superCriticalChance")
        s.offline = true
        local seed = s.seed
        assert(math.abs(G.CriticalResult(s, h, 100, false) - 114) < 0.000001)
        selectEffect(h, "superCriticalDamage")
        assert(math.abs(G.CriticalResult(s, h, 100, false) - 117) < 0.000001)
        local effects = G.TalentEffects(h)
        local expected = 100 * (1 + effects.criticalChance * 0.5 + effects.superCriticalChance * 2)
        assert(math.abs(G.CriticalResult(s, h, 100, true) - expected) < 0.000001)
        assert(s.seed == seed)
    end
)

case("Damage-linked healing uses actual critical damage without a second critical roll", function()
    local s, h = setup("PRIEST")
    selectEffect(h, "criticalChance")
    selectEffect(h, "criticalHealing")
    selectEffect(h, "atonement")
    local unit, enemy = battle(s)
    unit.hp, unit.attackCD = 1, 0
    local hp = enemy.hp
    withRoll(1, function()
        G.Step(s, 0.25)
    end)
    local dealt = hp - enemy.hp
    assert(unit.hp == 1 + math.floor(dealt * 0.15))
    for _, event in ipairs(s.events) do
        if event.kind == "heal" then
            assert(event.critical == nil)
        end
    end
end)

case("A ten-percent five-rank talent grants two percent per invested point", function()
    local s, h = setup("WARRIOR")
    local node = C.talentByClassID.WARRIOR.warrior_1_4
    local original = node.value
    node.value = 0.1
    local ok, reason = pcall(function()
        local base = G.Stats(s, h).damage
        for rank = 1, 5 do
            h.talents[node.id] = rank
            assert(math.abs(G.Stats(s, h).damage / base - (1 + rank * 0.02)) < 0.000001)
            assert(C.TalentRankText(node, rank):find("Deal " .. rank * 2 .. "%% more damage."))
        end
    end)
    node.value = original
    assert(ok, reason)
end)
case(
    "Every numeric talent and situational bonus supports partial ranks without rounding them away",
    function()
        for _, class in ipairs(C.classes) do
            local _, h = setup(class.id)
            for _, node in ipairs(G.TalentList(h)) do
                if node.value ~= true then
                    for rank = 1, node.maxRanks do
                        h.talents = { [node.id] = rank }
                        local expected = node.value * rank / node.maxRanks
                        assert(math.abs(G.TalentEffects(h)[node.effect] - expected) < 0.000001)
                        assert(type(C.TalentRankText(node, rank)) == "string")
                    end
                end
            end
        end
    end
)
case("The minimum critical chance supplied by a power talent also scales per rank", function()
    local s, h = setup("WARRIOR")
    local node = selectEffect(h, "criticalDamage")
    assert(node.maxRanks == 2)
    h.talents[node.id] = 1
    withRoll(100, function()
        assert(G.CriticalResult(s, h, 100, false) == 175)
    end)
    withRoll(101, function()
        assert(G.CriticalResult(s, h, 100, false) == 100)
    end)
    assert(C.TalentRankText(node, 1):find("1%% critical hit chance"))
end)

case(
    "Legacy talent migration restarts cached fights without paying rewards or altering the input save",
    function()
        local s, h = setup("WARRIOR")
        local unit = battle(s)
        unit.hp = unit.maxHP / 2
        h.talentRanksVersion = nil
        local victories, gold, seed = s.stats.victories, s.gold, s.seed
        local loaded = assert(G.Load(s, 1000))
        assert(loaded ~= s and loaded.battle == nil)
        assert(s.battle and s.battle.heroes[1] == unit and h.talentRanksVersion == nil)
        assert(loaded.stats.victories == victories and loaded.gold == gold and loaded.seed == seed)
        assert(loaded.heroes[1].talentRanksVersion == 2)
    end
)

case("Whole ability costs give every efficiency rank one resource unit", function()
    local _, h = setup("SHAMAN")
    local node = selectEffect(h, "abilityEfficiency")
    local profile = G.HeroResource(h)
    local previous = profile.costs.attack
    assert(node.maxRanks == 5)
    for rank = 1, 5 do
        h.talents[node.id] = rank
        local cost = G.HeroAbilityCost(h, "attack")
        assert(cost == profile.costs.attack - rank)
        assert(cost < previous)
        local unit = { resource = cost }
        assert(G.SpendHeroResource(h, unit, "attack") and unit.resource == 0)
        previous = cost
    end
end)

case("All talent ranks display whole-number bonuses that match their actual values", function()
    for _, class in ipairs(C.classes) do
        for _, node in ipairs(C.talentsByClass[class.id]) do
            for rank = 1, node.maxRanks do
                local description = C.TalentRankText(node, rank)
                assert(not description:match("%d[.,]%d"), node.name .. ": " .. description)
                if node.value ~= true then
                    local units = node.effect == "regen" and 1000
                        or node.effect == "abilityEfficiency" and 1
                        or 100
                    local value = node.value * units * rank / node.maxRanks
                    assert(math.abs(value - math.floor(value + 0.5)) < 0.000001)
                    if node.trait then
                        local amount = node.trait.amount * 100 * rank / node.maxRanks
                        assert(math.abs(amount - math.floor(amount + 0.5)) < 0.000001)
                    end
                end
            end
        end
    end
end)

return cases
