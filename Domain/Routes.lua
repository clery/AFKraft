local _, W = ...
local L = W.L
local G, C = W.Game, W.Content

local function whole(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end

local function identifier(value)
    return type(value) == "string"
        and #value > 0
        and #value <= 80
        and value:match("^[%w_%-]+$") ~= nil
end

local function template(state, id)
    for index, route in ipairs(state.routes.templates) do
        if route.id == id then
            return route, index
        end
    end
end

local function validSteps(steps, saved)
    if type(steps) ~= "table" or #steps < 1 or #steps > 12 then
        return false
    end
    local destinations, ids, count = {}, {}, 0
    for key in pairs(steps) do
        if not whole(key, 1, #steps) then
            return false
        end
        count = count + 1
    end
    if count ~= #steps then
        return false
    end
    for _, step in ipairs(steps) do
        if
            type(step) ~= "table"
            or not identifier(step.destination)
            or destinations[step.destination]
        then
            return false
        end
        destinations[step.destination] = true
        if saved or step.id ~= nil then
            if not whole(step.id, 1, 1000000000) or ids[step.id] then
                return false
            end
            ids[step.id] = true
        end
        local trigger = step.trigger
        if type(trigger) ~= "table" then
            return false
        end
        if trigger.kind == "boss" then
            if
                not identifier(trigger.zone)
                or not whole(trigger.stage, 5, 1000000)
                or trigger.stage % 5 ~= 0
            then
                return false
            end
        elseif trigger.kind == "level" then
            if not whole(trigger.hero, 1, 5) or not whole(trigger.level, 1, C.heroLevelCap) then
                return false
            end
        elseif trigger.kind == "material" then
            if not C.materials[trigger.material] or not whole(trigger.amount, 1, 1000000) then
                return false
            end
        elseif trigger.kind == "collection" then
            if not whole(trigger.itemID, 1, 1000000000) then
                return false
            end
        elseif trigger.kind == "unlock" then
            if not identifier(trigger.zone) then
                return false
            end
        else
            return false
        end
    end
    return true
end

function G.ResetRouteRun(state)
    state.routes.run =
        { cursor = 1, completed = {}, paused = false, lastEncounter = state.encounter }
end

function G.ValidateRoutes(state)
    local routes = state.routes
    if
        type(routes) ~= "table"
        or type(routes.owned) ~= "boolean"
        or type(routes.enabled) ~= "boolean"
        or type(routes.offlineEnabled) ~= "boolean"
        or (routes.offlineEnabled and not routes.owned)
        or (routes.enabled and not routes.owned)
        or type(routes.templates) ~= "table"
        or #routes.templates > 8
        or not whole(routes.nextID, 1, 1000000000)
    then
        return false
    end
    local ids, maximum, count = {}, 0, 0
    for key in pairs(routes.templates) do
        if not whole(key, 1, #routes.templates) then
            return false
        end
        count = count + 1
    end
    if count ~= #routes.templates then
        return false
    end
    for _, route in ipairs(routes.templates) do
        if
            type(route) ~= "table"
            or not whole(route.id, 1, 1000000000)
            or ids[route.id]
            or type(route.name) ~= "string"
            or #route.name < 1
            or #route.name > 40
            or route.name:find("[%c]")
            or not validSteps(route.steps, true)
        then
            return false
        end
        ids[route.id], maximum = true, math.max(maximum, route.id)
        for _, step in ipairs(route.steps) do
            if ids[step.id] then
                return false
            end
            ids[step.id], maximum = true, math.max(maximum, step.id)
        end
    end
    if routes.nextID <= maximum then
        return false
    end
    local selected = template(state, routes.selected)
    if routes.selected ~= nil and not selected then
        return false
    end
    local run = routes.run
    if
        type(run) ~= "table"
        or not whole(run.cursor, 1, selected and #selected.steps + 1 or 1)
        or type(run.completed) ~= "table"
        or type(run.paused) ~= "boolean"
        or (run.lastEncounter ~= nil and not whole(run.lastEncounter, 0, state.encounter))
    then
        return false
    end
    local completed = {}
    if selected then
        for index, step in ipairs(selected.steps) do
            if index < run.cursor then
                completed[step.id] = true
            end
        end
    end
    for id, value in pairs(run.completed) do
        if not completed[id] or value ~= true then
            return false
        end
        completed[id] = nil
    end
    return next(completed) == nil
end

function G.BuyRoutes(state)
    if state.routes.owned then
        return false, L.ROUTE_PLANNING_IS_ALREADY_LEARNED
    end
    local hint = G.FeatureHint(state, "routes")
    if hint then
        return false, hint
    end
    if state.legacy < 1 then
        return false, L.ROUTE_PLANNING_COSTS_1_HERITAGE
    end
    state.legacy = state.legacy - 1
    state.routes.owned = true
    G.Log(state, L.ROUTE_PLANNING_LEARNED_PERMANENTLY, nil, "progress")
    return true
end

function G.SaveRoute(state, id, name, steps)
    local routes = state.routes
    if not routes.owned then
        return false, L.LEARN_ROUTE_PLANNING_FIRST
    end
    if type(name) ~= "string" then
        return false, L.GIVE_THE_ROUTE_A_NAME
    end
    name = name:match("^%s*(.-)%s*$")
    if #name < 1 or #name > 40 or name:find("[%c]") or not validSteps(steps, false) then
        return false, L.USE_A_NAME_UP_TO_40_CHARACTERS_AND_1
    end
    local previous, index = template(state, id)
    if id ~= nil and not previous then
        return false, L.UNKNOWN_ROUTE_TEMPLATE
    end
    if not previous and #routes.templates >= 8 then
        return false, L.KEEP_AT_MOST_EIGHT_ROUTES
    end
    local nextID, existing = routes.nextID, {}
    if previous then
        for _, step in ipairs(previous.steps) do
            existing[step.id] = true
        end
    end
    local saved = { name = name, steps = G.Copy(steps) }
    if previous then
        saved.id = previous.id
    else
        saved.id, nextID = nextID, nextID + 1
    end
    for _, step in ipairs(saved.steps) do
        if step.id and not existing[step.id] then
            return false, L.UNKNOWN_ROUTE_STEP
        end
        if not step.id then
            step.id, nextID = nextID, nextID + 1
        end
    end
    if nextID > 1000000000 then
        return false, L.ROUTE_IDENTIFIER_LIMIT_REACHED
    end
    routes.templates[index or #routes.templates + 1] = saved
    routes.nextID = nextID
    if routes.selected == saved.id then
        G.ResetRouteRun(state)
    end
    return true, saved.id
end

function G.SelectRoute(state, id)
    if not state.routes.owned or (id ~= nil and not template(state, id)) then
        return false, L.CHOOSE_A_LEARNED_ROUTE_TEMPLATE
    end
    state.routes.selected = id
    G.ResetRouteRun(state)
    return true
end

function G.SetRoutesEnabled(state, enabled)
    if type(enabled) ~= "boolean" then
        return false, L.CHOOSE_WHETHER_ROUTES_ARE_ENABLED
    end
    if enabled and not state.routes.owned then
        return false, L.LEARN_ROUTE_PLANNING_FIRST
    end
    state.routes.enabled = enabled
    return true
end

function G.SetOfflineRoutesEnabled(state, enabled)
    if type(enabled) ~= "boolean" or (enabled and not state.routes.owned) then
        return false, L.LEARN_ROUTE_PLANNING_BEFORE_ENABLING_OFFLINE_ROUTES
    end
    state.routes.offlineEnabled = enabled
    return true
end

function G.ResumeRoute(state)
    if not state.routes.selected then
        return false, L.SELECT_A_ROUTE_FIRST
    end
    state.routes.run.paused = false
    state.routes.run.lastEncounter = state.encounter
    return true
end

function G.DeleteRoute(state, id)
    local _, index = template(state, id)
    if not index then
        return false, L.UNKNOWN_ROUTE_TEMPLATE
    end
    table.remove(state.routes.templates, index)
    if state.routes.selected == id then
        state.routes.selected = nil
        G.ResetRouteRun(state)
    end
    return true
end

function G.RouteStatus(state)
    local routes = state.routes
    if not routes.owned then
        return false, L.LEARN_ROUTE_PLANNING_FOR_1_HERITAGE
    end
    if not routes.enabled then
        return false, L.ROUTE_TRAVEL_DISABLED
    end
    if routes.run.paused then
        return false, L.PAUSED_BY_MANUAL_TRAVEL_RESUME_WHEN_READY
    end
    local route = template(state, routes.selected)
    if not route then
        return false, L.SELECT_A_SAVED_ROUTE
    end
    local step = route.steps[routes.run.cursor]
    if not step then
        return false, L.ROUTE_COMPLETE
    end
    local destination = C.zoneByID[step.destination]
    if not destination then
        return false, L.DESTINATION_UNAVAILABLE_PREFIX .. step.destination, step, "destination"
    end
    if state.offline then
        local permission = state.offlineRoute
        if not routes.offlineEnabled or not permission then
            return false, L.OFFLINE_ROUTE_TRAVEL_IS_DISABLED, step
        end
        if permission.tier ~= state.tier or permission.transitions >= 12 then
            return false, L.OFFLINE_ROUTE_TRAVEL_LIMIT_REACHED, step
        end
        if not permission.safe[step.destination] or permission.safe[step.destination] < 1 then
            return false,
                L.WAITING_FOR_AN_ONLINE_CLEAR_OF_PREFIX .. destination.name .. ".",
                step,
                "destination"
        end
    end
    local trigger = step.trigger
    if trigger.kind == "boss" then
        local zone = C.zoneByID[trigger.zone]
        if not zone then
            return false, L.MILESTONE_DESTINATION_UNAVAILABLE_PREFIX .. trigger.zone, step
        end
        if (state.safe[trigger.zone] or 0) < trigger.stage then
            return false,
                L.WAITING_FOR_PREFIX .. zone.name .. L.FRAGMENT_BOSS .. trigger.stage .. ".",
                step
        end
    elseif trigger.kind == "level" then
        local hero = state.heroes[trigger.hero]
        if not hero then
            return false, L.WAITING_FOR_PARTY_MEMBER_PREFIX .. trigger.hero .. ".", step
        end
        if hero.level < trigger.level then
            return false,
                L.WAITING_FOR_PREFIX
                    .. hero.name
                    .. L.FRAGMENT_LEVEL
                    .. trigger.level
                    .. " ("
                    .. hero.level
                    .. ").",
                step
        end
    elseif trigger.kind == "material" then
        local held = state.materials[trigger.material] or 0
        if held < trigger.amount then
            return false,
                L.WAITING_FOR_PREFIX
                    .. trigger.amount
                    .. " "
                    .. C.materials[trigger.material]
                    .. L.IN_STOCK_SUFFIX
                    .. held
                    .. ").",
                step
        end
    elseif trigger.kind == "collection" then
        local item = G.CollectionItem(trigger.itemID)
        if not C.collectionByItem[trigger.itemID] or not item then
            return false, L.COLLECTION_PIECE_UNAVAILABLE_PREFIX .. trigger.itemID .. ".", step
        end
        if
            not G.CollectionBook(state, C.collectionByItem[trigger.itemID]).pieces[trigger.itemID]
        then
            return false, L.WAITING_FOR_COLLECTION_DISCOVERY_PREFIX .. G.ItemName(item) .. ".", step
        end
    elseif trigger.kind == "unlock" then
        local zone = C.zoneByID[trigger.zone]
        if not zone then
            return false, L.MILESTONE_DESTINATION_UNAVAILABLE_PREFIX .. trigger.zone, step
        end
        if not G.IsUnlocked(state, zone) then
            return false, L.WAITING_TO_UNLOCK_PREFIX .. zone.name .. ".", step
        end
    end
    if not G.IsUnlocked(state, destination) then
        return false, L.WAITING_TO_UNLOCK_PREFIX .. destination.name .. ".", step, "destination"
    end
    return true, L.NEXT_ENCOUNTER_BOUNDARY_PREFIX .. destination.name .. ".", step
end

function G.RouteBoundary(state)
    local run = state.routes.run
    if
        (state.offline and (not state.routes.offlineEnabled or not state.offlineRoute))
        or state.battle
        or state.encounter < 1
        or run.lastEncounter == state.encounter
    then
        return false
    end
    run.lastEncounter = state.encounter
    local eligible, _, step, waiting = G.RouteStatus(state)
    if not eligible or not step then
        if waiting == "destination" then
            state.stage = math.max(1, state.safe[state.zone] or 1)
            state.farming = true
        end
        return false
    end
    local ok = G.Travel(state, step.destination, true)
    if not ok then
        return false
    end
    if state.offline then
        state.stage = state.offlineRoute.safe[step.destination]
        state.farming = true
        state.offlineRoute.transitions = state.offlineRoute.transitions + 1
    end
    run.completed[step.id] = true
    run.cursor = run.cursor + 1
    return true
end
