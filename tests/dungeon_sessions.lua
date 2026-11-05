local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
case("Dungeon sessions count only new dungeon identities without mixing outdoor totals", function()
    local s = G.New(0)
    s.dungeonCollections.pieces[10399] = true
    s.dungeonCollections.stats.kills = 4
    assert(G.BeginHuntSession(s, 10))
    assert(not G.SaveHuntSession(s, 11))
    s.dungeonCollections.stats.kills = 7
    s.dungeonCollections.pieces[10400] = true
    local report = assert(G.HuntSessionSummary(s, 40))
    assert(report.seconds == 30 and report.kills == 0 and report.discoveries == 0)
    assert(report.dungeon.kills == 3 and report.dungeon.discoveries == 1)
    assert(report.dungeon.pieces[10400] and not report.dungeon.pieces[10399])
    assert(G.HasSessionProgress(report) and G.SaveHuntSession(s, 40))
    assert(G.ValidateHuntSummary(s))
    report.dungeon.pieces[10400] = nil
    assert(s.lastHuntSummary.dungeon.pieces[10400])
    local restored = assert(G.Load(G.Copy(s), 40))
    assert(G.BeginHuntSession(restored, 40))
    assert(not G.SaveHuntSession(restored, 50))
    assert(restored.lastHuntSummary.dungeon.kills == 3)
    assert(G.HuntSessionSummary(restored, 50).dungeon.kills == 0)
end)
case(
    "Saved session validation keeps old reports and rejects cross-ledger discovery data",
    function()
        local s = G.New(0)
        s.lastHuntSummary = { seconds = 1, kills = 0, discoveries = 0, pieces = {} }
        assert(G.ValidateHuntSummary(s))
        s.lastHuntSummary.dungeon = { kills = 1, discoveries = 1, pieces = { [10399] = true } }
        assert(G.ValidateHuntSummary(s))
        local changes = {
            function(r)
                r.dungeon.kills = -1
            end,
            function(r)
                r.dungeon.kills = 0 / 0
            end,
            function(r)
                r.dungeon.discoveries = 2
            end,
            function(r)
                r.dungeon.pieces[10399] = 1
            end,
            function(r)
                r.dungeon.pieces = { [4701] = true }
            end,
            function(r)
                r.pieces = { [10399] = true }
                r.discoveries = 1
            end,
            function(r)
                r.dungeon = false
            end,
        }
        for _, change in ipairs(changes) do
            local bad = G.Copy(s)
            change(bad.lastHuntSummary)
            assert(not G.ValidateHuntSummary(bad))
            assert(not G.Load(bad, 1))
        end
    end
)
case("Dungeon session deltas survive both resets and repeated session starts", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    assert(G.BeginHuntSession(s, 10))
    s.dungeonCollections.stats.kills = 2
    s.dungeonCollections.pieces[10399] = true
    s.prestigeUnlocked, s.runBest = true, 8
    assert(G.Prestige(s))
    assert(G.BeginHuntSession(s, 20))
    assert(G.HuntSessionSummary(s, 20).dungeon.kills == 2)
    local hero = s.heroes[1]
    hero.level = 60
    assert(G.TalentProgress(hero))
    s.encounter = s.encounter + 1
    assert(
        G.DifficultyVictory(
            s,
            { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }
        )
    )
    assert(G.PrestigePlus(s, 1))
    local report = assert(G.HuntSessionSummary(s, 30))
    assert(report.seconds == 20 and report.dungeon.kills == 2 and report.dungeon.discoveries == 1)
    assert(report.kills == 0 and report.discoveries == 0)
end)
case(
    "Offline snapshots cannot report dungeon gains and live reconciliation retains dungeon sessions",
    function()
        local s = G.New(0)
        G.AddHero(s, "WARRIOR")
        s.safe.elwynn = 1
        assert(G.BeginHuntSession(s, 0))
        local job = assert(G.BeginCatchup(s, 60))
        assert(not G.BeginHuntSession(job.state, 0))
        assert(not G.HuntSessionSummary(job.state, 60))
        s.dungeonCollections.stats.kills = 2
        s.dungeonCollections.pieces[10399] = true
        assert(G.SaveHuntSession(s, 30))
        while not G.CatchupBatch(job, 1000) do
        end
        assert(G.FinishCatchup(s, job))
        local report = assert(G.HuntSessionSummary(s, 60))
        assert(report.dungeon.kills == 2 and report.dungeon.discoveries == 1)
        assert(s.lastHuntSummary.dungeon.pieces[10399])
        assert(s.lastOfflineSummary.discoveries == 0)
    end
)
return cases
