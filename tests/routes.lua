local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function party()
    local state = G.New(0)
    G.AddHero(state, "WARRIOR")
    state.legacy = 1
    assert(G.BuyRoutes(state))
    return state
end
local function step(destination, trigger)
    return {
        destination = destination,
        trigger = trigger or { kind = "unlock", zone = destination },
    }
end
local function route(state, steps)
    local ok, id = G.SaveRoute(state, nil, "Test route", steps or { step("durotar") })
    assert(ok)
    assert(G.SelectRoute(state, id))
    assert(G.SetRoutesEnabled(state, true))
    return id
end

case("Route planning is a permanent atomic purchase and defaults disabled", function()
    local state = G.New(0)
    assert(not G.BuyRoutes(state))
    state.legacy = 1
    assert(G.BuyRoutes(state))
    assert(state.legacy == 0 and not state.routes.enabled)
    assert(not G.BuyRoutes(state) and state.legacy == 0)
    assert(not G.SetRoutesEnabled(state, 1))
end)

case("Routes have bounded names, typed milestones and distinct destinations", function()
    local state = party()
    for _, steps in ipairs({
        {},
        { step("durotar"), step("durotar") },
        { step("durotar", { kind = "boss", zone = "elwynn", stage = 6 }) },
        { step("durotar", { kind = "level", hero = 0, level = 5 }) },
        { step("durotar", { kind = "script" }) },
    }) do
        assert(not G.SaveRoute(state, nil, "Bad", steps))
    end
    assert(not G.SaveRoute(state, nil, string.rep("a", 41), { step("durotar") }))
    assert(not G.SaveRoute(state, nil, "bad\nname", { step("durotar") }))
    assert(#state.routes.templates == 0 and state.routes.nextID == 1)
    for index = 1, 8 do
        assert(G.SaveRoute(state, nil, "Route " .. index, { step("durotar") }))
    end
    assert(not G.SaveRoute(state, nil, "Ninth", { step("durotar") }))
end)

case("Saved routes retain stable step IDs and edit without travel", function()
    local state = party()
    local id = route(state)
    local saved = G.Copy(state.routes.templates[1])
    assert(G.SaveRoute(state, id, "Renamed", saved.steps))
    assert(state.routes.templates[1].steps[1].id == saved.steps[1].id)
    assert(state.zone == "elwynn" and state.routes.run.cursor == 1)
    assert(G.ValidateRoutes(state))
    saved.steps[1].id = 9999
    assert(not G.SaveRoute(state, id, "No foreign IDs", saved.steps))
end)

case("Route boundary travels at most once per resolved encounter and never offline", function()
    local state = party()
    route(state, { step("durotar"), step("elwynn") })
    state.encounter = 1
    state.battle = {}
    assert(not G.RouteBoundary(state))
    state.battle, state.offline = nil, true
    assert(not G.RouteBoundary(state))
    state.offline = nil
    assert(G.RouteBoundary(state))
    assert(state.zone == "durotar" and state.routes.run.cursor == 2)
    assert(not G.RouteBoundary(state) and state.zone == "durotar")
    state = assert(G.Load(G.Copy(state), 0))
    assert(not G.RouteBoundary(state))
    state.encounter = 2
    assert(G.RouteBoundary(state) and state.zone == "elwynn")
    assert(not G.RouteStatus(state))
    assert(G.ValidateRoutes(state))
end)

case("Removed and locked destinations wait without losing route configuration", function()
    local state = party()
    route(state, { step("removed_destination") })
    state.encounter = 1
    local eligible, reason = G.RouteStatus(state)
    assert(not eligible and reason:find("unavailable"))
    assert(not G.RouteBoundary(state) and state.routes.run.cursor == 1)
    assert(G.Load(G.Copy(state), 0))
    route(state, { step("westfall") })
    assert(not G.RouteStatus(state))
    assert(state.routes.templates[2].steps[1].destination == "westfall")
end)

case("Boss milestones use run safe progress and levels use the named current hero", function()
    local state = party()
    route(state, { step("durotar", { kind = "boss", zone = "elwynn", stage = 5 }) })
    state.runBest = 100
    assert(not G.RouteStatus(state))
    state.safe.elwynn = 5
    assert(G.RouteStatus(state))
    route(state, { step("durotar", { kind = "level", hero = 2, level = 5 }) })
    state.heroes[1].level = 60
    assert(not G.RouteStatus(state))
    G.AddHero(state, "PRIEST")
    assert(not G.RouteStatus(state))
    state.heroes[2].level = 5
    assert(G.RouteStatus(state))
end)

case("Manual override pauses routes until resume and a fresh encounter boundary", function()
    local state = party()
    route(state)
    state.encounter = 1
    assert(G.Travel(state, "durotar"))
    assert(state.routes.run.paused)
    assert(not G.RouteBoundary(state))
    assert(G.ResumeRoute(state))
    assert(not G.RouteBoundary(state))
    state.encounter = 2
    assert(G.RouteBoundary(state))
end)

case("Route resets retain capabilities and templates but clear run progress", function()
    local state = party()
    route(state)
    state.encounter = 1
    assert(G.RouteBoundary(state))
    state.routes.run.paused = true
    G.ResetRouteRun(state)
    assert(state.routes.owned and state.routes.enabled and #state.routes.templates == 1)
    assert(
        state.routes.run.cursor == 1
            and not state.routes.run.paused
            and not next(state.routes.run.completed)
    )
end)

case("Malformed saved route receipts and IDs fail validation", function()
    local original = party()
    route(original)
    for _, corrupt in ipairs({
        function(s)
            s.routes.enabled = "yes"
        end,
        function(s)
            s.routes.nextID = 1
        end,
        function(s)
            s.routes.selected = 999
        end,
        function(s)
            s.routes.run.completed[999] = true
        end,
        function(s)
            s.routes.run.cursor = 2
        end,
        function(s)
            s.routes.templates[1].steps[1].trigger.kind = "unknown"
        end,
    }) do
        local state = G.Copy(original)
        corrupt(state)
        assert(not G.ValidateRoutes(state))
    end
end)

return cases
