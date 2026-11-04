local _, W = ...
local L = W.L
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local R = {}
W.RoutePanel = R

local function button(parent, label, x, y, width, action)
    return U.Button(parent, label, x, y, width, 30, action)
end

local function draft(ui, route)
    ui.routeDraft = route and G.Copy(route) or { name = L.NEW_ROUTE, steps = {} }
    ui:Refresh()
end

local function zoneName(id)
    return C.zoneByID[id] and C.zoneByID[id].name or id
end

function R.Draw(ui, parent, state)
    if ui.routeState ~= state then
        ui.routeState, ui.routeDraft = state, nil
        for _, saved in ipairs(state.routes.templates) do
            if saved.id == state.routes.selected then
                ui.routeDraft = G.Copy(saved)
                break
            end
        end
    end
    local frame = ui.routeFrame
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:SetAllPoints(parent)
        ui.routeFrame = frame
        local input = U.Input(frame, 352, 98, 550, 36)
        input:SetScript("OnTextChanged", function(self)
            if ui.routeDraft then
                ui.routeDraft.name = self:GetText()
            end
        end)
        ui.routeNameInput = input
    end
    frame:Show()
    U.Begin(frame)
    U.Text(frame, L.ROUTE_PLANNER_HEADING, 0, 0, 22, T.gold, 1296)
    U.Help(frame, L.ROUTES, 1258, 0, L.ADD_DESTINATIONS_AND_MILESTONES_THEN_SAVE_SELECT_USE_SAVED)
    ui.routeBuy = button(
        frame,
        state.routes.owned and L.PLANNING_LEARNED or L.LEARN_1_HERITAGE,
        0,
        92,
        280,
        function()
            W.Action(G.BuyRoutes)
        end
    )
    U.Enabled(
        ui.routeBuy,
        not state.routes.owned and state.legacy >= 1 and not G.FeatureHint(state, "routes")
    )
    U.Tooltip(
        ui.routeBuy,
        L.ROUTE_PLANNING,
        G.FeatureHint(state, "routes") or L.SPEND_1_HERITAGE_TO_LEARN_ROUTE_PLANNING_PERMANENTLY
    )
    ui.routeEnabled = U.Checkbox(
        frame,
        L.ROUTES_ENABLED,
        0,
        136,
        280,
        state.routes.enabled,
        function(value)
            W.Action(G.SetRoutesEnabled, value)
        end
    )
    ui.routeOffline = U.Checkbox(
        frame,
        L.OFFLINE_CLEARED_ROUTES,
        0,
        174,
        280,
        state.routes.offlineEnabled,
        function(value)
            W.Action(G.SetOfflineRoutesEnabled, value)
        end
    )
    U.Tooltip(
        ui.routeOffline,
        L.OFFLINE_ROUTE_TRAVEL,
        L.WHILE_AWAY_VISIT_ONLY_CHECKPOINTS_CLEARED_IN_THIS_RUN
    )
    ui.routeNew = button(frame, L.NEW_TEMPLATE, 0, 214, 280, function()
        draft(ui)
    end)
    ui.routeTemplates = {}
    for index, route in ipairs(state.routes.templates) do
        local saved = route
        local selected = state.routes.selected == route.id and L.SELECTED_SUFFIX or ""
        ui.routeTemplates[route.id] = U.SelectButton(
            frame,
            route.name .. selected,
            0,
            254 + (index - 1) * 38,
            280,
            30,
            function()
                draft(ui, saved)
            end,
            ui.routeDraft and ui.routeDraft.id == route.id
        )
    end
    if not ui.routeDraft then
        ui.routeDraft = { name = L.NEW_ROUTE, steps = {} }
    end
    local preview = ui.routeDraft
    ui.routeNameInput:SetText(preview.name)
    ui.routeSave = button(frame, L.SAVE_TEMPLATE, 930, 98, 170, function()
        preview.name = ui.routeNameInput:GetText()
        ui.routeNameInput:ClearFocus()
        local ok, value = G.SaveRoute(state, preview.id, preview.name, preview.steps)
        if ok then
            for _, saved in ipairs(state.routes.templates) do
                if saved.id == value then
                    ui.routeDraft = G.Copy(saved)
                end
            end
        else
            W.Notify(value)
        end
        ui:Refresh()
    end)
    ui.routeUse = button(frame, L.USE_SAVED_ROUTE, 352, 142, 224, function()
        W.Action(G.SelectRoute, preview.id)
    end)
    U.Enabled(ui.routeUse, preview.id ~= nil)
    ui.routeDelete = button(frame, L.DELETE, 596, 142, 140, function()
        local ok = G.DeleteRoute(state, preview.id)
        if ok then
            draft(ui)
        end
    end)
    U.Enabled(ui.routeDelete, preview.id ~= nil)
    ui.routeResume = button(frame, L.RESUME_ROUTE, 756, 142, 224, function()
        W.Action(G.ResumeRoute)
    end)
    U.Enabled(ui.routeResume, state.routes.run.paused and state.routes.selected ~= nil)
    local zones, heroes, levels, bosses = {}, {}, {}, {}
    for _, zone in ipairs(C.zones) do
        zones[#zones + 1] = { id = zone.id, name = zone.name }
    end
    for index, hero in ipairs(state.heroes) do
        heroes[#heroes + 1] = { id = index, name = hero.name }
    end
    if #heroes == 0 then
        heroes[1] = { id = 1, name = L.PARTY_MEMBER_1 }
    end
    for value = 1, C.heroLevelCap do
        levels[#levels + 1] = { id = value, name = L.LEVEL_PREFIX .. value }
    end
    for value = 5, C.heroLevelCap * 5, 5 do
        bosses[#bosses + 1] = { id = value, name = L.BOSS_PREFIX .. value }
    end
    local materials, amounts, pieces = {}, {}, {}
    for _, id in ipairs(C.materialOrder) do
        materials[#materials + 1] = { id = id, name = C.materials[id] }
    end
    for _, amount in ipairs({
        1,
        5,
        10,
        25,
        50,
        100,
        250,
        500,
        1000,
        2500,
        5000,
        10000,
        100000,
        1000000,
    }) do
        amounts[#amounts + 1] = { id = amount, name = tostring(amount) }
    end
    for _, collection in ipairs(C.collections) do
        for _, itemID in ipairs(collection.pieces) do
            pieces[#pieces + 1] = { id = itemID, name = G.ItemName(G.CollectionItem(itemID)) }
        end
    end
    local kinds = {
        { id = "boss", name = L.ZONE_BOSS },
        { id = "level", name = L.HERO_LEVEL },
        { id = "unlock", name = L.UNLOCK_ZONE },
        { id = "material", name = L.MATERIAL_STOCK },
        { id = "collection", name = L.DISCOVERY },
    }
    ui.routeSteps = {}
    for index, step in ipairs(preview.steps) do
        local row, trigger = {}, step.trigger
        local y = 192 + (index - 1) * 32
        U.Text(frame, tostring(index), 320, y + 6, 13, T.gold, 26)
        row.destination = U.Choice(
            frame,
            zoneName(step.destination),
            352,
            y,
            260,
            zones,
            step.destination,
            function(value)
                step.destination = value
                ui:Refresh()
            end
        )
        row.kind = U.Choice(
            frame,
            trigger.kind == "boss" and L.ZONE_BOSS
                or trigger.kind == "level" and L.HERO_LEVEL
                or trigger.kind == "material" and L.MATERIAL_STOCK
                or trigger.kind == "collection" and L.DISCOVERY
                or L.UNLOCK_ZONE,
            622,
            y,
            160,
            kinds,
            trigger.kind,
            function(value)
                step.trigger = value == "boss" and { kind = value, zone = state.zone, stage = 5 }
                    or value == "level" and { kind = value, hero = 1, level = 5 }
                    or value == "material" and { kind = value, material = "timber", amount = 100 }
                    or value == "collection" and {
                        kind = value,
                        itemID = C.collections[1].pieces[1],
                    }
                    or { kind = value, zone = step.destination }
                ui:Refresh()
            end
        )
        if trigger.kind == "material" then
            row.target = U.Choice(
                frame,
                C.materials[trigger.material] or L.UNAVAILABLE,
                792,
                y,
                230,
                materials,
                trigger.material,
                function(value)
                    trigger.material = value
                    ui:Refresh()
                end
            )
            row.value = U.Choice(
                frame,
                tostring(trigger.amount),
                1032,
                y,
                150,
                amounts,
                trigger.amount,
                function(value)
                    trigger.amount = value
                    ui:Refresh()
                end
            )
            U.Tooltip(
                row.value,
                L.MATERIAL_STOCK_MILESTONE,
                L.TRAVEL_AFTER_AN_ENCOUNTER_WHEN_YOU_HOLD_THIS_AMOUNT
            )
        elseif trigger.kind == "collection" then
            local item = G.CollectionItem(trigger.itemID)
            row.target = U.Choice(
                frame,
                item and G.ItemName(item) or L.UNAVAILABLE_PIECE,
                792,
                y,
                390,
                pieces,
                trigger.itemID,
                function(value)
                    trigger.itemID = value
                    ui:Refresh()
                end
            )
            U.Tooltip(
                row.target,
                L.COLLECTION_DISCOVERY_MILESTONE,
                L.TRAVEL_AFTER_THIS_OUTDOOR_OR_DUNGEON_PIECE_IS_DISCOVERED
            )
        elseif trigger.kind == "level" then
            row.target = U.Choice(
                frame,
                state.heroes[trigger.hero] and state.heroes[trigger.hero].name
                    or L.PARTY_MEMBER_PREFIX .. trigger.hero,
                792,
                y,
                230,
                heroes,
                trigger.hero,
                function(value)
                    trigger.hero = value
                    ui:Refresh()
                end
            )
            row.value = U.Choice(
                frame,
                L.LEVEL_PREFIX .. trigger.level,
                1032,
                y,
                150,
                levels,
                trigger.level,
                function(value)
                    trigger.level = value
                    ui:Refresh()
                end
            )
        else
            row.target = U.Choice(
                frame,
                zoneName(trigger.zone),
                792,
                y,
                trigger.kind == "boss" and 230 or 390,
                zones,
                trigger.zone,
                function(value)
                    trigger.zone = value
                    ui:Refresh()
                end
            )
            if trigger.kind == "boss" then
                row.value = U.Choice(
                    frame,
                    L.BOSS_PREFIX .. trigger.stage,
                    1032,
                    y,
                    150,
                    bosses,
                    trigger.stage,
                    function(value)
                        trigger.stage = value
                        ui:Refresh()
                    end
                )
            end
        end
        row.remove = button(frame, "×", 1192, y, 36, function()
            table.remove(preview.steps, index)
            ui:Refresh()
        end)
        ui.routeSteps[index] = row
    end
    ui.routeAdd = button(frame, L.ADD_STEP, 352, 588, 224, function()
        local used = {}
        for _, step in ipairs(preview.steps) do
            used[step.destination] = true
        end
        for _, zone in ipairs(C.zones) do
            if not used[zone.id] then
                preview.steps[#preview.steps + 1] =
                    { destination = zone.id, trigger = { kind = "unlock", zone = zone.id } }
                break
            end
        end
        ui:Refresh()
    end)
    U.Enabled(ui.routeAdd, #preview.steps < 12)
    local _, reason = G.RouteStatus(state)
    ui.routeStatus = U.Text(frame, reason, 352, 638, 15, T.gold, 900)
    U.EndBuild(frame)
end
