if not test then
    return
end
local function click(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end

test("Route editor drafts steps, saves, selects and pauses independently", function()
    local W = AFKraft
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    state.difficulty.unlocked, state.difficulty.maxTier = true, 3
    G.AddHero(state, "WARRIOR")
    state.legacy, state.guide.dismissed = 1, true
    state.ui.compact = false
    W.state = state
    ui.routeDraft = nil
    ui.frame:Show()
    ui:SetTab("routes")
    click(ui.routeBuy)
    click(ui.routeNew)
    click(ui.routeAdd)
    assertEquals(0, #state.routes.templates)
    ui.routeNameInput:SetText("Across Azeroth")
    click(ui.routeSave)
    assertEquals(1, #state.routes.templates)
    assertEquals("Across Azeroth", state.routes.templates[1].name)
    assertEquals("elwynn", state.zone)
    click(ui.routeUse)
    assertEquals(state.routes.templates[1].id, state.routes.selected)
    ui.routeEnabled:SetChecked(true)
    click(ui.routeEnabled)
    assertTrue(state.routes.enabled)
    assertFalse(state.routes.offlineEnabled)
    ui.routeOffline:SetChecked(true)
    click(ui.routeOffline)
    assertTrue(state.routes.offlineEnabled)
    assertTrue(G.Travel(state, "durotar"))
    ui:Refresh()
    assertTrue(ui.routeResume:IsEnabled())
    click(ui.routeResume)
    assertFalse(state.routes.run.paused)
    click(ui.routeSteps[1].remove)
    assertEquals(1, #state.routes.templates[1].steps)
    assertEquals(0, #ui.routeDraft.steps)
    click(ui.routeDelete)
    assertEquals(0, #state.routes.templates)
end)

test("Route editor configures material stock and outdoor discovery milestones", function()
    local W = AFKraft
    local G, U, ui = W.Game, W.Widgets, W.UI
    local s = G.New(W.Client.Now())
    s.difficulty.unlocked, s.difficulty.maxTier = true, 3
    G.AddHero(s, "WARRIOR")
    s.legacy, s.guide.dismissed = 1, true
    W.state = s
    assertTrue(G.BuyRoutes(s))
    local original, choices = U.Choice, {}
    U.Choice = function(parent, label, x, y, width, options, value, choose)
        local control = original(parent, label, x, y, width, options, value, choose)
        choices[control] = choose
        return control
    end
    local ok, message = pcall(function()
        ui:SetTab("routes")
        click(ui.routeAdd)
        choices[ui.routeSteps[1].kind]("material")
        choices[ui.routeSteps[1].target]("ore")
        choices[ui.routeSteps[1].value](250)
        assertEquals(0, #s.routes.templates)
        click(ui.routeSave)
        assertEquals("material", s.routes.templates[1].steps[1].trigger.kind)
        assertEquals(250, s.routes.templates[1].steps[1].trigger.amount)
        choices[ui.routeSteps[1].kind]("collection")
        local itemID = W.Content.collections[1].pieces[2]
        choices[ui.routeSteps[1].target](itemID)
        click(ui.routeSave)
        assertEquals("collection", s.routes.templates[1].steps[1].trigger.kind)
        assertEquals(itemID, s.routes.templates[1].steps[1].trigger.itemID)
        click(ui.routeUse)
        assertTrue(G.SetRoutesEnabled(s, true))
        assertFalse(G.RouteStatus(s))
        s.outdoorCollections.pieces[itemID] = true
        assertTrue(G.RouteStatus(s))
    end)
    U.Choice = original
    assertTrue(ok, message)
end)
