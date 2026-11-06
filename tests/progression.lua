local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Companions are discovered one at a time and recruitment cannot skip milestones", function()
    local s = G.New(1000)
    assert(G.AddHero(s, "WARRIOR"))
    assert(G.CompanionSlots(s) == 1)
    assert(not G.Recruit(s, "PRIEST"))
    for index = 2, 5 do
        local level = C.companionMilestones[index]
        s.best = level
        assert(G.CompanionSlots(s) == index - 1)
        assert(not G.Recruit(s, "MAGE"))
        s.best = level + 1
        assert(G.CompanionSlots(s) == index)
        assert(not G.Recruit(s, "unknown"))
        assert(G.Recruit(s, "MAGE"))
        assert(#s.heroes == index)
        assert(not G.Recruit(s, "MAGE"))
    end
    assert(G.NextCompanionMilestone(s) == nil)
end)

case("Every starting class can reach the first companion by fighting and equipping loot", function()
    for _, class in ipairs(C.classes) do
        local s = G.New(1000)
        G.AddHero(s, class.id)
        for _ = 1, 7200 do
            G.Step(s, 0.25)
            if G.ChestCount(s) > 0 then
                assert(G.OpenChests(s, "all"))
            end
            G.EquipBest(s, 1)
            if s.farming then
                G.Retry(s)
            end
            if G.CompanionSlots(s) == 2 then
                break
            end
        end
        assert(G.CompanionSlots(s) == 2, class.id .. " cannot finish the solo opening")
        assert(s.guide.equipped)
        assert(#s.heroes == 1)
        assert(G.Recruit(s, "PRIEST"))
        assert(#s.heroes == 2)
    end
end)

case("Repeated bosses and offline farming cannot discover extra companions", function()
    local s = G.New(1000)
    G.AddHero(s, "MAGE")
    local boss = (C.companionMilestones[2] - C.zoneByID.elwynn.level + 1) * 5
    s.stage = boss
    G.StartBattle(s)
    for _, enemy in ipairs(s.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(s, 0.25)
    assert(G.CompanionSlots(s) == 2)
    assert(G.Recruit(s, "PRIEST"))
    s.safe.elwynn, s.lastTime = boss, 1000
    local job = assert(G.BeginCatchup(s, 1300))
    while not G.CatchupBatch(job, 1600) do
    end
    G.FinishCatchup(s, job)
    assert(G.CompanionSlots(s) == 2)
    assert(not G.Recruit(s, "MAGE"))
end)

case("Existing parties, guide preferences and discoveries survive loading and chapters", function()
    local s = G.New(1000)
    for _ = 1, 5 do
        G.AddHero(s, "MAGE")
    end
    s.guide = nil -- A save written before the starter guide existed.
    s = assert(G.Load(s, 1000))
    assert(#s.heroes == 5 and G.CompanionSlots(s) == 5)
    assert(s.guide.dismissed)
    s.guide.dismissed = false
    s.guide.talent = true
    s = assert(G.Load(s, 1100))
    assert(not s.guide.dismissed and s.guide.talent)
    s.best, s.runBest, s.prestigeUnlocked = 8, 8, true
    assert(G.Prestige(s))
    assert(#s.heroes == 5 and G.CompanionSlots(s) == 5)
    assert(s.guide.talent)
    -- Discoveries also persist when slots have not yet been filled.
    s.heroes = { s.heroes[1] }
    assert(G.CompanionSlots(s) == 5)
    assert(G.Recruit(s, "PRIEST"))
end)

case("Guide milestones record successful actions without being undone by respecs", function()
    local s = G.New(1000)
    G.AddHero(s, "WARRIOR")
    local item = G.Item(s, 1, 1, 2)
    s.inventory[1] = item
    assert(not G.Equip(s, 2, 1) and not s.guide.equipped)
    assert(G.Equip(s, 1, 1) and s.guide.equipped)
    local talent = G.TalentList(s.heroes[1])[1].id
    assert(G.Talent(s, 1, talent) and s.guide.talent)
    assert(G.Talent(s, 1, talent, true) and s.guide.talent)
    assert(G.Travel(s, "elwynn") and not s.guide.traveled)
    assert(G.Travel(s, "durotar") and s.guide.traveled)
    s.guide.equipped = "bad"
    s = assert(G.Load(s, 1200))
    assert(s.guide.equipped == false)
end)

case("Encounters grow with the company and the first victory always supplies a reward", function()
    local s = G.New(1000)
    for count = 1, 5 do
        G.AddHero(s, "WARRIOR")
        s.stage = 1
        G.StartBattle(s)
        assert(#s.battle.enemies == math.min(3, count))
        s.battle = nil
    end
    s = G.New(1000)
    G.AddHero(s, "WARRIOR")
    G.StartBattle(s)
    for _, enemy in ipairs(s.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(s, 0.25)
    assert(#s.inventory == 0 and G.ChestCount(s) == 1)
    s.salvage.minQuality = 1
    assert(G.OpenChests(s, 1))
    assert(#s.inventory > 0)
    assert(s.stats.victories == 1)
end)

case("Slower discoveries preserve old access and do not expire before recruitment", function()
    local old = G.New(1000)
    assert(G.AddHero(old, "WARRIOR"))
    old.best, old.runBest, old.unlocks = 8, 18, nil
    local loaded = assert(G.Load(old, 1000))
    assert(G.CompanionSlots(loaded) == 5)
    for _, zone in ipairs(C.zones) do
        assert(G.IsUnlocked(loaded, zone))
    end
    loaded.prestigeUnlocked = true
    assert(G.Prestige(loaded))
    assert(G.CompanionSlots(loaded) == 5)
    assert(not G.IsUnlocked(loaded, C.zoneByID.winterspring))
    assert(G.Recruit(loaded, "PRIEST"))
    local fresh = G.New(1000)
    assert(G.AddHero(fresh, "WARRIOR"))
    fresh.best = 8
    assert(G.CompanionSlots(fresh) == 2)
    fresh.best = C.companionMilestones[3] + 1
    assert(G.CompanionSlots(fresh) == 3)
    fresh.prestigeUnlocked, fresh.runBest = true, 9
    assert(G.Prestige(fresh) and G.CompanionSlots(fresh) == 3)
    assert(G.Load(G.Copy(fresh), 100000))
end)

case("Zone discovery uses spaced frontier waves independently of local enemy level", function()
    local s = G.New(1000)
    for _, zone in ipairs(C.zones) do
        assert(zone.unlockLevel >= zone.level)
        assert(zone.level == 1 or zone.unlockLevel > zone.level)
        if zone.unlockLevel > 1 then
            s.runBest = zone.unlockLevel - 1
            assert(not G.IsUnlocked(s, zone))
        end
        s.runBest = zone.unlockLevel
        assert(G.IsUnlocked(s, zone))
    end
end)

case("Unlock receipts reject malformed state rather than granting discoveries", function()
    for _, corrupt in ipairs({
        function(s)
            s.unlocks.companions = 6
        end,
        function(s)
            s.unlocks.companions = 1.5
        end,
        function(s)
            s.unlocks.zones.missing_zone = true
        end,
        function(s)
            s.unlocks.zones.westfall = false
        end,
    }) do
        local s = G.New(1000)
        corrupt(s)
        assert(not G.Load(s, 1000))
    end
end)

case("Hero XP costs retain the opening and grow smoothly beyond level ten", function()
    assert(G.LevelXP(1) == 45 and G.LevelXP(10) == 450)
    assert(G.LevelXP(40) == 5400 and G.LevelXP(60) == 11700)
    local previous = 0
    for level = 1, 59 do
        local cost = G.LevelXP(level)
        assert(cost > previous)
        local h = { level = level, xp = cost - 1 }
        local nextLevel, xp = G.ExperienceResult(h, 1)
        assert(nextLevel == level + 1 and xp == 0)
        previous = cost
    end
    local s = G.New(1000)
    assert(G.AddHero(s, "WARRIOR"))
    s.heroes[1].level, s.heroes[1].xp = 41, 1000
    local loaded = assert(G.Load(s, 1000))
    assert(loaded.heroes[1].level == 41 and loaded.heroes[1].xp == 1000)
end)

case("Four hours in Elwynn cannot bypass its hero level ceiling", function()
    local s = G.New(0)
    assert(G.AddHero(s, "WARRIOR"))
    for _ = 1, 4 * 3600 do
        G.Step(s, 1)
    end
    assert(s.heroes[1].level == 10 and s.heroes[1].xp == 0)
    local level, xp = s.heroes[1].level, s.heroes[1].xp
    assert(G.ActivityReward(s, "quest:curve-test", "quest", "test"))
    assert(s.heroes[1].level == level and s.heroes[1].xp == xp)
    assert(G.Load(G.Copy(s), 4 * 3600))
end)

case("Zone XP ceilings taper, stop overflow and preserve veteran progress", function()
    local zone = C.zoneByID.elwynn
    local level, xp = G.ExperienceResult({ level = 5, xp = 0 }, 100, zone)
    assert(level == 5 and xp == 100)
    level, xp = G.ExperienceResult({ level = 9, xp = 0 }, 100, zone)
    assert(level == 9 and xp == 20)
    level, xp = G.ExperienceResult({ level = 9, xp = 0 }, 1000000, zone)
    assert(level == 10 and xp == 0)
    level, xp = G.ExperienceResult({ level = 41, xp = 1000 }, 1000000, zone)
    assert(level == 41 and xp == 1000)
    for _, destination in ipairs(C.zones) do
        assert(destination.heroLevelCap >= destination.unlockLevel)
    end
    level, xp = G.ExperienceResult(
        { level = 59, xp = G.LevelXP(59) - 1 },
        100,
        C.zoneByID.blackrock_mountain
    )
    assert(level == 60 and xp == 0)
end)

case("Offline farming respects zone ceilings and reports exact nonlinear XP", function()
    local s = G.New(0)
    assert(G.AddHero(s, "WARRIOR"))
    s.heroes[1].level, s.heroes[1].xp = 9, G.LevelXP(9) - 1
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 3600))
    while not G.CatchupBatch(job, 1000) do
    end
    G.FinishCatchup(s, job)
    assert(s.heroes[1].level == 10 and s.heroes[1].xp == 0)
    assert(s.lastOfflineSummary.heroXP == 1)
end)

return cases
