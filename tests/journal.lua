local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local day = 86400
local function fixture()
    local s = G.New(100 * day)
    G.AddHero(s, "WARRIOR")
    G.RefreshJournal(s, 100 * day)
    return s
end

case("Journal creates three distinct contracts and refreshes without duplicates", function()
    local s = fixture()
    for _ = 1, 4 do
        G.RefreshJournal(s, 100 * day)
    end
    assert(#s.journal.days == 1 and #s.journal.weekly.ids == 3)
    assert(s.journal.days[1].ids[1] == "quest" and s.journal.days[1].ids[2] == "kill")
    assert(G.ValidateJournal(s))
end)

case("Real activity receipts advance contracts once without manufacturing Adventure XP", function()
    local s = fixture()
    local xp = s.adventure.totalXP
    assert(G.ActivityReward(s, "journal-test:1", "quest", "Quest"))
    assert(not G.ActivityReward(s, "journal-test:1", "quest", "Quest"))
    assert(s.journal.days[1].progress.quest == 1 and s.journal.weekly.progress.quest == 1)
    assert(s.adventure.totalXP == xp + C.activityRewards.quest.xp)
    G.JournalActivity(s, "explore", 100 * day, 37)
    G.JournalActivity(s, "explore", 100 * day, 37)
    assert(s.journal.totals.explore == 1 and s.journal.days[1].progress.explore == 1)
    assert(s.adventure.totalXP == xp + C.activityRewards.quest.xp)
    assert(G.ActivityReward(s, "journal-test:skin", "skinning", "Skinning"))
    assert(s.journal.totals.gather == 1)
end)

case("Daily completion and two-contract bonus are automatic and cannot repeat", function()
    local s = fixture()
    for _ = 1, 5 do
        G.JournalActivity(s, "quest", 100 * day)
    end
    assert(s.journal.xp == C.journal.dailyXP)
    for _ = 1, 30 do
        G.JournalActivity(s, "kill", 100 * day)
    end
    assert(s.journal.days[1].bonus)
    assert(s.journal.xp == 2 * C.journal.dailyXP + C.journal.bonusXP)
    local xp = s.journal.xp
    G.JournalActivity(s, "kill", 100 * day)
    assert(s.journal.xp == xp and s.journal.totals.contracts == 2)
end)

case("All rotating world objectives and weekly rewards complete at their exact targets", function()
    for offset = 0, 3 do
        local s = G.New((100 + offset) * day)
        G.RefreshJournal(s, (100 + offset) * day)
        local daily = s.journal.days[1]
        local id = daily.ids[3]
        for count = 1, C.contractByID[id].daily do
            G.JournalActivity(s, id, (100 + offset) * day, id == "explore" and count or nil)
        end
        assert(daily.progress[id] == C.contractByID[id].daily)
        assert(s.journal.totals.contracts == 1)
    end
    local s = fixture()
    for _, achievement in ipairs(C.journalAchievements) do
        s.journal.achievements[achievement.id] = true
    end
    for _ = 1, 25 do
        G.JournalActivity(s, "quest", 100 * day)
    end
    assert(s.journal.weekly.progress.quest == 25)
    assert(s.journal.xp == C.journal.dailyXP + C.journal.weeklyXP)
    G.JournalActivity(s, "quest", 100 * day)
    assert(s.journal.xp == C.journal.dailyXP + C.journal.weeklyXP)
end)

case("Three-day catch-up advances the oldest eligible set without triple credit", function()
    local s = fixture()
    G.RefreshJournal(s, 102 * day)
    assert(#s.journal.days == 3)
    G.JournalActivity(s, "quest", 102 * day)
    assert(s.journal.days[1].progress.quest == 1 and s.journal.days[2].progress.quest == nil)
    G.RefreshJournal(s, 103 * day)
    assert(#s.journal.days == 3 and s.journal.days[1].period == 101)
    G.RefreshJournal(s, 100 * day)
    assert(s.journal.day == 103 and #s.journal.days == 3)
    G.RefreshJournal(s, 400 * day)
    assert(#s.journal.days == 3 and s.journal.days[1].period == 398)
    assert(G.ValidateJournal(s))
end)

case("Week resets on Monday UTC and clock rollback cannot restore old objectives", function()
    local s = fixture()
    G.RefreshJournal(s, 101 * day) -- Sunday
    local week = s.journal.weekly.period
    G.JournalActivity(s, "quest", 101 * day)
    G.RefreshJournal(s, 102 * day) -- Monday
    assert(s.journal.weekly.period == week + 1 and not next(s.journal.weekly.progress))
    G.RefreshJournal(s, 101 * day)
    assert(s.journal.weekly.period == week + 1)
end)

case("Achievements award once, recognize old milestones and survive both resets", function()
    local s = fixture()
    s.best, s.guide.crafted, s.prestiges = 60, true, 1
    G.AddHero(s, "MAGE")
    G.CheckJournalAchievements(s)
    assert(
        s.journal.achievements.frontier
            and s.journal.achievements.summit
            and s.journal.achievements.artisan
    )
    local xp = s.journal.xp
    G.CheckJournalAchievements(s)
    assert(s.journal.xp == xp)
    local j = s.journal
    assert(G.ResetAdventure(s, false))
    assert(G.ResetAdventure(s, true))
    assert(s.journal == j and j.xp == xp and j.achievements.artisan)
end)

case("Journal track grants each reward once and only unlocked cosmetic titles equip", function()
    local s = fixture()
    assert(not G.ClaimJournalReward(s))
    assert(not G.SetJournalTitle(s, 5))
    s.journal.xp = C.journal.ranks * C.journal.xpPerRank
    local gold, materials, items = s.gold, s.materials.ore, #s.inventory
    for _ = 1, 20 do
        assert(G.ClaimJournalReward(s))
    end
    assert(s.gold > gold and s.materials.ore > materials and #s.inventory > items)
    assert(s.journal.claimed == 20 and s.journal.title == 20)
    assert(s.recipes[1] and s.legacy == 2 and s.inventory[#s.inventory].heirloom)
    assert(G.SetJournalTitle(s, 5) and s.journal.title == 5)
    assert(G.SetJournalTitle(s, 0) and s.journal.title == 0)
    assert(not G.ClaimJournalReward(s) and not G.SetJournalTitle(s, 25))
    assert(G.ValidateJournal(s) and G.ValidateChests(s))
end)

case(
    "Journal supply rewards scale with crafting and equipment rewards improve the selected hero",
    function()
        local s = fixture()
        G.AddHero(s, "MAGE")
        s.heroes[2].level = 30
        s.journal.xp = C.journal.ranks * C.journal.xpPerRank
        local cost = G.Cost(s, s.heroes[2], false)
        local gold, ore = s.gold, s.materials.ore
        assert(G.ClaimJournalReward(s, 2, 1))
        assert(s.gold == gold + cost.gold * 10)
        assert(G.ClaimJournalReward(s, 2, 1))
        assert(s.materials.ore == ore + cost.material * 10)
        assert(G.ClaimJournalReward(s, 2, 1))
        local item = assert(G.CraftItem(s.heroes[2], 1, false, s))
        item.uid, s.nextItem = s.nextItem, s.nextItem + 1
        s.heroes[2].gear[1] = item
        G.RefreshHero(s, 2)
        local power = G.ItemPower(item, s.heroes[2])
        gold, ore = s.gold, s.materials.ore
        assert(G.ClaimJournalReward(s, 2, 1))
        assert(item.upgrade == 1 and G.ItemPower(item, s.heroes[2]) > power)
        assert(s.gold == gold and s.materials.ore == ore)
        assert(not G.ClaimJournalReward(s, 99, 1) and s.journal.claimed == 4)
        assert(not G.ClaimJournalReward(s, 2, 5) and s.journal.claimed == 4)
        assert(G.ClaimJournalReward(s, 2, 3) and s.recipes[3])
        assert(G.ValidateJournal(s))
    end
)

case(
    "Journal rejects malformed saves and migrates absent progress without clearing existing state",
    function()
        local s = fixture()
        for _, mutate in ipairs({
            function(j)
                j.xp = 0 / 0
            end,
            function(j)
                j.claimed = 21
            end,
            function(j)
                j.title = "5"
            end,
            function(j)
                j.days[1].weekly = true
            end,
            function(j)
                j.days[1].progress.quest = 999
            end,
            function(j)
                j.days[1].ids[3] = "quest"
            end,
            function(j)
                j.weekly.period = 0
            end,
            function(j)
                j.achievements.madeUp = true
            end,
            function(j)
                j.totals.quest = -1
            end,
            function(j)
                j.zones.secret = true
            end,
        }) do
            local copy = G.Copy(s)
            mutate(copy.journal)
            assert(not G.ValidateJournal(copy))
            assert(not G.Load(copy, 100 * day))
        end
        s.journal = nil
        local loaded = assert(G.Load(s, 100 * day))
        assert(loaded.journal.xp == 0 and #loaded.heroes == 1)
    end
)

case(
    "Idle simulation cannot advance real-world contracts or overwrite live catch-up progress",
    function()
        local s = fixture()
        s.safe.elwynn = 1
        s.lastTime = 100 * day - 60
        local job = assert(G.BeginCatchup(s, 100 * day))
        G.JournalActivity(job.state, "quest", 100 * day)
        assert(not next(job.state.journal.totals))
        G.JournalActivity(s, "quest", 100 * day)
        while not G.CatchupBatch(job, 1200) do
        end
        assert(G.FinishCatchup(s, job))
        assert(s.journal.totals.quest == 1 and s.journal.days[1].progress.quest == 1)
        assert(not G.FinishCatchup(s, job))
    end
)

case("Zone travel normalizes outdoor child maps and rejects secret or instance maps", function()
    local namespace = { L = W.L, Game = G }
    local s = fixture()
    local host = { id = 37, inside = false }
    local secret = {}
    local env = setmetatable({
        GetBuildInfo = function()
            return "12.1.5"
        end,
        GetServerTime = function()
            return 100 * day
        end,
        IsInInstance = function()
            return host.inside
        end,
        issecretvalue = function(value)
            return value == secret
        end,
        C_Map = {
            GetBestMapForUnit = function()
                return host.id
            end,
            GetMapInfo = function(id)
                if id == 99 then
                    return { mapType = 5, parentMapID = 37 }
                end
                return { mapType = id == 100 and 4 or 3 }
            end,
        },
    }, { __index = _G })
    local chunk = assert(loadfile("Compatibility/Client.lua"))
    setfenv(chunk, env)("AFKraft", namespace)
    local A = namespace.Client
    A.JournalZone(s)
    host.id = 99
    A.JournalZone(s)
    assert(s.journal.totals.explore == 1)
    host.id = 100
    A.JournalZone(s)
    host.id = secret
    A.JournalZone(s)
    host.id, host.inside = 52, true
    A.JournalZone(s)
    assert(s.journal.totals.explore == 1)
    host.inside = false
    A.JournalZone(s)
    assert(s.journal.totals.explore == 2)
end)
local november, december, january = 1793491200, 1796083200, 1798761600
local function monthlyFixture(now)
    local state = G.New(now)
    G.AddHero(state, "WARRIOR")
    G.RefreshJournal(state, now)
    for _, achievement in ipairs(C.journalAchievements) do
        state.journal.achievements[achievement.id] = true
    end
    return state
end

case("Journal UTC months handle leap days, century rules and year boundaries", function()
    for _, example in ipairs({
        { november, 2026, 11, december },
        { december - 1, 2026, 11, december },
        { december, 2026, 12, january },
        { 1706745600, 2024, 2, 1709251200 },
        { 1709164800, 2024, 2, 1709251200 },
        { 4107456000, 2100, 2, 4107542400 },
        { 951782400, 2000, 2, 951868800 },
    }) do
        local month, finish = G.JournalCalendar(example[1])
        assert(month == example[2] * 12 + example[3] - 1 and finish == example[4])
    end
end)

case(
    "Month rollover pays earned supplies and preserves choice rewards and lifetime progress",
    function()
        local state = monthlyFixture(december - 1)
        local j = state.journal
        j.xp = 10 * C.journal.xpPerRank
        j.claimed, j.title, j.titles = 5, 5, 5
        state.recipes[1], j.totals.quest, j.zones[37] = true, 123, true
        local daily, weekly = j.days[#j.days], j.weekly
        local cost = G.Cost(state, state.heroes[1], false)
        G.RefreshJournal(state, december)
        assert(j.xp == 0 and j.claimed == 0 and j.month == 2026 * 12 + 11)
        assert(state.gold == cost.gold * 20 and state.materials.ore == cost.material * 10)
        assert(j.pending[8] == 1 and j.pending[10] == 1 and G.JournalRewardsWaiting(state) == 2)
        assert(j.title == 5 and j.titles == 10 and G.SetJournalTitle(state, 10))
        assert(
            j.bestRank == 10 and j.achievements.artisan and j.totals.quest == 123 and j.zones[37]
        )
        assert(state.recipes[1] and j.days[#j.days - 1] == daily and j.weekly == weekly)
        assert(G.ValidateJournal(state))
        local gold = state.gold
        G.RefreshJournal(state, december)
        assert(state.gold == gold and j.pending[8] == 1)
        state.lastTime = december
        assert(G.ClaimJournalReward(state, 1, 1) and not j.pending[8])
        assert(G.ClaimJournalReward(state, 1, 3) and not j.pending[10] and state.recipes[3])
        assert(j.claimed == 0 and G.JournalRewardsWaiting(state) == 0)
    end
)

case(
    "Monthly resets never mint rewards for missed months or replay after clock rollback",
    function()
        local state = monthlyFixture(november)
        state.journal.xp = C.journal.ranks * C.journal.xpPerRank
        G.RefreshJournal(state, january)
        local pending, gold = G.Copy(state.journal.pending), state.gold
        assert(G.JournalRewardsWaiting(state) == 8)
        G.RefreshJournal(state, november)
        G.RefreshJournal(state, january + 86400)
        assert(state.gold == gold and state.journal.month == 2027 * 12)
        for rank, count in pairs(pending) do
            assert(state.journal.pending[rank] == count)
        end
        assert(G.ValidateJournal(state))
        -- A second earned track accumulates rewards without replacing earlier choices.
        state.journal.xp = 5 * C.journal.xpPerRank
        G.RefreshJournal(state, january + 32 * 86400)
        assert(state.journal.pending[4] == 2 and state.journal.pending[5] == 2)
        assert(state.journal.pending[20] == 1)
    end
)

case(
    "Old Journal saves keep ranks, titles and claim history when monthly progression migrates",
    function()
        local state = monthlyFixture(november)
        state.journal = {
            xp = 2150,
            claimed = 5,
            title = 5,
            day = math.floor(november / 86400),
            days = {},
            weekly = {},
            achievements = { artisan = true },
            totals = { quest = 42 },
            zones = {},
        }
        assert(G.ValidateJournal(state))
        local j = state.journal
        assert(j.version == 2 and j.xp == math.floor(2150 * 150 / 200))
        assert(G.JournalRank(state) == 10 and j.bestRank == 10 and j.titles == 5 and j.claimed == 5)
        assert(j.totals.quest == 42 and j.achievements.artisan and j.month == 2026 * 12 + 10)
        assert(G.ValidateJournal(state))
        j.pending[0] = 1
        assert(not G.ValidateJournal(state))
        j.pending[0], j.bonusXP = nil, C.journal.bonusEveryXP
        assert(not G.ValidateJournal(state))
    end
)

case(
    "Rank twenty continues with modest repeatable supplies and no extra title or heirloom",
    function()
        local state = monthlyFixture(november)
        local j = state.journal
        j.xp, j.claimed, j.titles = C.journal.ranks * C.journal.xpPerRank, 20, 20
        local cost = G.Cost(state, state.heroes[1], false)
        for _ = 1, 25 do
            G.JournalActivity(state, "quest", november)
        end
        assert(j.bonusXP == C.journal.dailyXP + C.journal.weeklyXP and state.gold == 0)
        for _ = 1, 30 do
            G.JournalActivity(state, "kill", november)
        end
        assert(j.bonusXP == 70 and state.gold == cost.gold * 2)
        assert(state.materials.ore == cost.material * 2 and not next(j.pending))
        assert(j.claimed == 20 and G.JournalRewardsWaiting(state) == 0 and #state.inventory == 0)
        assert(G.ValidateJournal(state))
    end
)

case(
    "Rewards earned at month rollover survive an in-flight offline snapshot and deliver once",
    function()
        local state = monthlyFixture(december - 60)
        state.safe.elwynn = 1
        state.journal.xp = 5 * C.journal.xpPerRank
        local job = assert(G.BeginCatchup(state, december))
        local previous = W.catchup
        W.catchup = job
        local ok, message = pcall(function()
            G.RefreshJournal(state, december)
            assert(state.gold == 0 and state.journal.pending[1] == 1)
            assert(G.FinishCatchup(state, job))
            local cost = G.Cost(state, state.heroes[1], false)
            assert(state.gold == cost.gold * 20 and state.materials.ore == cost.material * 10)
            assert(
                not state.journal.pending[1]
                    and state.journal.pending[4] == 1
                    and state.journal.pending[5] == 1
            )
            local gold = state.gold
            assert(not G.FinishCatchup(state, job))
            G.DeliverJournalSupplies(state)
            assert(state.gold == gold)
        end)
        W.catchup = previous
        assert(ok, message)
    end
)

case("A three-week schedule can finish without every daily or weekly objective", function()
    assert(
        18 * (C.journal.dailyXP * 2 + C.journal.bonusXP) + 6 * C.journal.weeklyXP
            >= C.journal.ranks * C.journal.xpPerRank
    )
end)

return cases
