if not test then
    return
end

test("Offline catch-up yields between bounded batches without changing rewards", function()
    local W = AFKraft
    W.Initialize()
    local G = W.Game
    local previous, catchup = W.state, W.catchup
    local clock, step = GetTimePreciseSec, G.Step
    local now, calls = 0, 0
    local ok, message = pcall(function()
        local state = G.New(1000)
        G.AddHero(state, "WARRIOR")
        state.safe.elwynn = 1
        local expected = G.Copy(state)
        local reference = assert(G.BeginCatchup(expected, 1120))
        while not G.CatchupBatch(reference, 1200) do
        end
        G.FinishCatchup(expected, reference)
        GetTimePreciseSec = function()
            return now
        end
        G.Step = function(s, seconds)
            calls = calls + 1
            now = now + 0.001
            step(s, seconds)
        end
        W.state = state
        W.catchup = assert(G.BeginCatchup(state, 1000 + 86400))
        W.Controller.Update(nil, 1)
        assertTrue(calls >= 2 and calls <= 3)
        assertEquals(345600 - calls, W.catchup.remaining)
        local before = calls
        for _ = 1, 100 do
            W.Controller.Update(nil, 1)
        end
        assertEquals(before, calls)
        -- A fresh short absence must receive the same seeded simulation and totals.
        W.catchup = assert(G.BeginCatchup(state, 1000 + 86400 + 120))
        while W.catchup do
            now = now + 0.051
            before = calls
            W.Controller.Update(nil, 1)
            assertTrue(calls - before <= 3)
        end
        assertEquals(expected.seed, state.seed)
        assertEquals(expected.gold, state.gold)
        assertEquals(expected.clock, state.clock)
        assertEquals(expected.stats.victories, state.stats.victories)
        assertEquals(expected.heroes[1].xp, state.heroes[1].xp)
        assertEquals(expected.lastOfflineSummary.seconds, state.lastOfflineSummary.seconds)
    end)
    GetTimePreciseSec, G.Step = clock, step
    W.state, W.catchup = previous, catchup
    W.UI:Refresh()
    assert(ok, message)
end)
