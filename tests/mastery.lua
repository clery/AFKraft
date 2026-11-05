local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
local function hero(level)
    local state = G.New(1000)
    assert(G.AddHero(state, "WARRIOR"))
    local h = state.heroes[1]
    h.level, h.rank = level or 1, 14
    return state, h
end

case(
    "Character levels stop at 60 while level records and talent points remain permanent",
    function()
        local state, h = hero()
        assert(G.Points(h) == 1 and not G.MasteryUnlocked(h))
        h.level = 19
        assert(G.Points(h) == 10 and not G.MasteryUnlocked(h))
        h.level = 20
        assert(G.Points(h) == 10 and G.MasteryUnlocked(h))
        h.level = 60
        assert(G.Points(h) == 30 and G.NextTalentLevel(h) == nil)
        state.essence, state.gold = 100000, 100000
        assert(G.LevelCap(h) == 60 and not G.Train(state, 1))
        assert(state.essence == 100000 and state.gold == 100000)
        local level = G.ExperienceResult(h, 100000)
        assert(level == 60)
        h.level = 1
        assert(G.Points(h) == 30 and G.MasteryUnlocked(h))
    end
)

case(
    "Ordinary prestige retains active talents, unspent points, Mastery and free respecs",
    function()
        local state, h = hero(20)
        state.runBest, state.prestigeUnlocked = 9, true
        assert(G.Talent(state, 1, "cleave"))
        G.RewardMastery(h, 8, 125, false)
        local points, mastery = G.Points(h), G.Copy(h.mastery)
        local earned = h.talentProgress.earned
        assert(G.Prestige(state))
        assert(h.level == 1 and h.rank == 0 and h.talents.cleave)
        assert(G.TalentEffects(h).cleave and G.MasteryUnlocked(h))
        assert(G.Points(h) == points and h.talentProgress.earned == earned)
        assert(h.mastery.rank == mastery.rank and h.mastery.xp == mastery.xp)
        assert(h.mastery.frontier == mastery.frontier)
        assert(G.Talent(state, 1, "cleave", true) and G.Points(h) == points + 1)
        assert(G.Talent(state, 1, "cleave") and G.Points(h) == points)
        assert(h.mastery.rank == mastery.rank and h.mastery.xp == mastery.xp)
        assert(G.Prestige(state) and G.Points(h) == points)
        assert(G.Load(state, 1100))
        assert(h.talents.cleave and h.mastery.xp == mastery.xp)
    end
)

case(
    "Mastery unlocks at level 20 and easier encounters cannot farm ranks after prestige",
    function()
        local state, h = hero(19)
        assert(G.RewardMastery(h, 10, 100, true) == 0 and h.mastery.frontier == 10)
        h.level = 20
        assert(G.RewardMastery(h, 9, 100, true) == 0)
        local gained, ranks = G.RewardMastery(h, 10, 50, true)
        assert(gained == 100 and ranks == 1 and h.mastery.rank == 1)
        state.prestigeUnlocked, state.runBest = true, 11
        assert(G.Prestige(state))
        local before = G.Points(h)
        assert(G.RewardMastery(h, 1, 10000, true) == 0)
        assert(h.mastery.xp == 0 and h.mastery.rank == 1 and G.Points(h) == before)
        assert(G.RewardMastery(h, 11, 25, false) == 25)
        assert(h.mastery.frontier == 11 and h.mastery.xp == 25)
        assert(G.RewardMastery(h, 10, 1000, true) == 0 and h.mastery.xp == 25)
    end
)

case(
    "Mastery rank prices grow gently, preserve overflow, and grant one point every three ranks",
    function()
        local _, h = hero(20)
        local initial = G.Points(h)
        assert(G.MasteryCost(0) == 100 and G.MasteryCost(1) == 150 and G.MasteryCost(9) == 650)
        local gained, ranks = G.RewardMastery(h, 10, 300, false)
        assert(gained == 300 and ranks == 2 and h.mastery.rank == 2 and h.mastery.xp == 50)
        assert(G.Points(h) == initial)
        G.RewardMastery(h, 10, 149, false)
        assert(h.mastery.rank == 2 and h.mastery.xp == 199)
        G.RewardMastery(h, 10, 1, false)
        assert(h.mastery.rank == 3 and h.mastery.xp == 0 and G.Points(h) == initial + 1)
    end
)

case("Victory continues to grant Mastery at the character level cap", function()
    local state, h = hero(60)
    state.stage = 96 -- A level 20 encounter in the starting destination.
    G.StartBattle(state)
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(state, 0.25)
    assert(h.level == 60 and h.xp == 0 and h.mastery.xp == 68)
    assert(h.mastery.frontier == 20)
end)

case("Legacy saves retain unspent budgets and over-cap levels become Mastery once", function()
    local state, h = hero(48)
    h.talentProgress, h.mastery = nil, nil
    h.talents.cleave = true
    state.runBest = 9
    assert(G.Load(state, 1000))
    assert(G.Points(h) == 23 and h.talentProgress.earned == 24)
    assert(h.mastery.frontier == 8)
    assert(G.Load(state, 1100) and G.Points(h) == 23)
    state, h = hero(95)
    h.talentProgress, h.mastery = nil, nil
    h.talents.cleave, h.health, h.xp = true, 0.5, 40
    assert(G.Load(state, 1000))
    assert(h.level == 60 and h.health == 0.5 and h.mastery.rank == 35)
    assert(h.mastery.xp == 40 and G.Points(h) == 47)
    assert(G.Load(state, 1100) and h.mastery.rank == 35 and G.Points(h) == 47)
end)

case(
    "Malformed permanent progression refuses loading without discarding selected talents",
    function()
        for _, sample in ipairs({
            { field = "mastery", value = false },
            { field = "mastery", value = { rank = -1, xp = 0, frontier = 0 } },
            { field = "mastery", value = { rank = 0, xp = 100, frontier = 0 } },
            { field = "mastery", value = { rank = 0, xp = math.huge, frontier = 0 } },
            { field = "mastery", value = { rank = 0, xp = 0, frontier = 1.5 } },
            {
                field = "talentProgress",
                value = { bestLevel = 1, earned = 1, levelPoints = false },
            },
            { field = "talentProgress", value = { bestLevel = 1, earned = 0 } },
            { field = "talentProgress", value = { bestLevel = 0 / 0, earned = 1 } },
        }) do
            local state, h = hero()
            h.talents.cleave = true
            h[sample.field] = sample.value
            local loaded, reason = G.Load(state, 1000)
            assert(not loaded and reason and h.talents.cleave and h[sample.field] == sample.value)
        end
    end
)

case("Offline and visible victories use the same permanent Mastery progression", function()
    local state, h = hero(20)
    h.rank, h.mastery.frontier = 4, 4
    state.stage, state.safe.elwynn, state.farming = 20, 20, true
    local job = assert(G.BeginCatchup(state, 1300))
    local visible = G.Copy(job.state)
    for _ = 1, job.remaining do
        G.Step(visible, 0.25)
    end
    while not G.CatchupBatch(job, 1600) do
    end
    G.FinishCatchup(state, job)
    local offline = state.heroes[1]
    assert(offline.mastery.rank > 0)
    assert(offline.mastery.rank == visible.heroes[1].mastery.rank)
    assert(offline.mastery.xp == visible.heroes[1].mastery.xp)
    assert(G.Points(offline) == G.Points(visible.heroes[1]))
end)

case("Late Mastery prices preserve early access and previously earned ranks and XP", function()
    assert(G.MasteryCost(8) == 500)
    assert(G.MasteryCost(9) == 650 and G.MasteryCost(16) == 7300)
    local state, h = hero(60)
    G.TalentProgress(h)
    h.mastery.rank, h.mastery.xp = 16, 899
    h.talentProgress.earned = h.talentProgress.levelPoints + 16
    local loaded = assert(G.Load(G.Copy(state), 1000))
    assert(loaded.heroes[1].mastery.rank == 16 and loaded.heroes[1].mastery.xp == 899)
    assert(loaded.heroes[1].talentProgress.earned == h.talentProgress.earned)
end)

case("Offline Mastery summary sums the actual nonlinear prices across rank eight", function()
    local state, h = hero(60)
    G.TalentProgress(h)
    h.mastery.rank, h.mastery.xp = 8, 490
    h.talentProgress.earned = h.talentProgress.levelPoints + 8
    state.safe.elwynn, state.stage = 100, 100
    local job = assert(G.BeginCatchup(state, 1300))
    local before = G.Copy(h.mastery)
    local earnedHero = job.state.heroes[1]
    local gained = 2000
    G.RewardMastery(earnedHero, 20, gained, false)
    job.remaining = 0
    assert(G.FinishCatchup(state, job))
    local after = state.heroes[1].mastery
    assert(after.rank > before.rank and state.lastOfflineSummary.masteryXP == gained)
end)

return cases
