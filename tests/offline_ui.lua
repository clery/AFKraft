if not test then
    return
end

local function report()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    return W, state, W.UI
end

test("Return report opens without claiming rewards and stays out of compact controls", function()
    local W, state, ui = report()
    state.lastOfflineSummary = {
        seconds = 3600,
        remainingSeconds = 0,
        interrupted = false,
        gold = 400,
        victories = 20,
        heroXP = 120,
        heroLevels = 2,
        masteryXP = 30,
        masteryRanks = 1,
        itemsKept = 4,
        salvaged = 10,
        materials = { timber = 22, ore = 0, hide = 0, relic = 10 },
        boostUses = 3,
        discoveries = 1,
        upgrades = 0,
        routeTransitions = 0,
        routesWaiting = true,
    }
    state.gold = 456
    ui:Refresh()
    assertNotNil(ui.offlineReport)
    assertTrue(ui.reportLink:IsShown())
    ui.reportLink:GetScript("OnClick")()
    assertEquals("offline", state.ui.tab)
    assertEquals("Return report", ui.section:GetText())
    assertFalse(ui.scene.frame:IsShown())
    assertNotNil(ui.offlineCards.automation)
    assertEquals(nil, ui.offlineCards.collections)
    assertEquals(456, state.gold)
    local summary = state.lastOfflineSummary
    ui.offlineBack:GetScript("OnClick")()
    assertEquals("adventure", state.ui.tab)
    assertEquals(summary, state.lastOfflineSummary)
    state.ui.compact = true
    ui:ApplyMode()
    assertFalse(ui.panel:IsVisible())
    assertEquals(456, W.state.gold)
end)

test("Missing and older return reports display safely", function()
    local _, state, ui = report()
    ui:SetTab("offline")
    assertTrue(next(ui.offlineCards) == nil)
    state.lastOfflineSummary = { discoveries = 1, boostUses = 0 }
    ui:Refresh()
    assertNotNil(ui.offlineCards.progress)
    assertNotNil(ui.offlineCards.materials)
    state.lastOfflineSummary =
        { seconds = 20, interrupted = true, remainingSeconds = 40, materials = false }
    ui:Refresh()
    assertNotNil(ui.offlineBack)
end)
