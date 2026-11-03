if not test then
    return
end
local function click(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end

test("Route editor drafts steps, saves, selects and pauses independently", function()
    local W = WoWIdle
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
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
