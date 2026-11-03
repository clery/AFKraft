local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case(
    "Hunt sessions count only live collection changes and retain the last meaningful report",
    function()
        local s = G.New(0)
        local itemID = C.collections[1].pieces[1]
        assert(G.BeginHuntSession(s, 100.5))
        assert(not G.SaveHuntSession(s, 120) and s.lastHuntSummary == nil)
        s.outdoorCollections.stats.kills = 12
        s.outdoorCollections.pieces[itemID] = true
        assert(G.BeginHuntSession(s, 150))
        local report = assert(G.HuntSessionSummary(s, 160.9))
        assert(report.seconds == 60 and report.kills == 12 and report.discoveries == 1)
        assert(report.pieces[itemID] and G.SaveHuntSession(s, 160))
        assert(G.ValidateHuntSummary(s))
        report.pieces[itemID] = nil
        assert(s.lastHuntSummary.pieces[itemID])
        local reload = assert(G.Load(G.Copy(s), 160))
        assert(G.BeginHuntSession(reload, 160))
        assert(not G.SaveHuntSession(reload, 200))
        assert(reload.lastHuntSummary.kills == 12)
        assert(G.HuntSessionSummary(reload, 200).kills == 0)
        reload.lastHuntSummary.discoveries = 99
        assert(not G.Load(G.Copy(reload), 200))
    end
)

case(
    "Offline catchup cannot manufacture hunt sessions or overwrite live hunting reports",
    function()
        local s = G.New(0)
        G.AddHero(s, "WARRIOR")
        s.safe.elwynn = 1
        assert(G.BeginHuntSession(s, 0))
        local job = assert(G.BeginCatchup(s, 60))
        assert(not G.BeginHuntSession(job.state, 0))
        assert(G.HuntSessionSummary(job.state, 60) == nil)
        s.outdoorCollections.stats.kills = 3
        assert(G.SaveHuntSession(s, 30))
        while not G.CatchupBatch(job, 1000) do
        end
        G.FinishCatchup(s, job)
        assert(s.lastHuntSummary.kills == 3 and G.HuntSessionSummary(s, 60).kills == 3)
    end
)

case(
    "Session activity totals count earned XP and Essence without counting purchases or refunds",
    function()
        local s = G.New(0)
        G.AddHero(s, "WARRIOR")
        assert(G.BeginHuntSession(s, 0))
        assert(G.AdventureXP(s, 100.25, "quest", "Activity fixture"))
        assert(G.BuyDevelopment(s, "might"))
        assert(G.ResetDevelopment(s))
        s.essence = s.essence + 20
        local report = assert(G.HuntSessionSummary(s, 60))
        assert(report.adventureXP == 100.25 and report.essence == 60 and report.kills == 0)
        assert(G.SaveHuntSession(s, 60) and G.ValidateHuntSummary(s))
        local older = G.Copy(s)
        older.lastHuntSummary.adventureXP, older.lastHuntSummary.essence = nil, nil
        assert(G.ValidateHuntSummary(older))
        for _, invalid in ipairs({ "100", -1, math.huge, 0.1 }) do
            local bad = G.Copy(s)
            bad.lastHuntSummary.adventureXP = invalid
            assert(not G.ValidateHuntSummary(bad))
        end
    end
)

case(
    "Catchup retains real activity earned live and never attributes absence to activity",
    function()
        local s = G.New(0)
        G.AddHero(s, "WARRIOR")
        s.safe.elwynn = 1
        assert(G.BeginHuntSession(s, 0))
        local job = assert(G.BeginCatchup(s, 60))
        assert(G.AdventureXP(s, 100, "quest", "Live during catchup"))
        while not G.CatchupBatch(job, 1000) do
        end
        G.FinishCatchup(s, job)
        local report = assert(G.HuntSessionSummary(s, 60))
        assert(report.adventureXP == 100 and report.essence == 60)
        assert(s.lastOfflineSummary.discoveries == 0 and report.discoveries == 0)
    end
)

return cases
