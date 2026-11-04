if not test then
    return
end

test(
    "Collection book renders discoveries and source tooltips without retaining native inputs",
    function()
        local W = WoWIdle
        W.Initialize()
        local G, C, ui = W.Game, W.Content, W.UI
        local state = G.New(W.Client.Now())
        G.AddHero(state, "WARRIOR")
        state.guide.dismissed = true
        W.state = state
        ui.frame:Show()
        ui:SetTab("collections")
        local set = C.collections[1]
        state.outdoorCollections.pieces[set.pieces[1]] = true
        ui:Refresh()
        assertEquals(1, G.CollectionProgress(state, set.id).found)
        assertTrue(G.BeginHuntSession(state, W.Client.Now()))
        state.outdoorCollections.stats.kills = 8
        ui:Refresh()
        assertTrue(ui.collectionProgress:GetText():find("Session hunt: 8 kills", 1, true) ~= nil)
        local card = ui.collectionCards[set.pieces[1]]
        card:GetScript("OnEnter")(card)
        assertTrue(GameTooltip:IsShown())
        card:GetScript("OnLeave")(card)
        assertFalse(ui.collectionEffect:IsEnabled())
        state.collectionBook.pieces[C.legacyCollections[1].pieces[1]] = 0
        ui:Refresh()
        assertTrue(ui.collectionLegacyStatus:GetText():find("1/5", 1, true) ~= nil)
        ui:SetTab("party")
        assertFalse(GameTooltip:IsShown())
    end
)

test("Outdoor collections browse individual pieces and select one completed effect", function()
    local W = WoWIdle
    local G, C, ui = W.Game, W.Content, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    ui.collectionSelected = nil
    ui:SetTab("collections")
    local set = C.collections[1]
    local selected = set.pieces[2]
    assertNotNil(ui.collectionCards[selected])
    assertEquals(0, G.CollectionProgress(state, set.id).found)
    for _, itemID in ipairs(set.pieces) do
        state.outdoorCollections.pieces[itemID] = true
    end
    ui:Refresh(false)
    assertTrue(ui.collectionEffect:IsEnabled())
    ui.collectionEffect:GetScript("OnClick")()
    assertEquals(set.id, state.outdoorCollections.effect)
    assertTrue(ui.collectionEffectStatus:GetText():find(set.name, 1, true) ~= nil)
    ui.collectionEffect:GetScript("OnClick")()
    assertEquals(nil, state.outdoorCollections.effect)
    assertTrue(G.CollectionBonuses(state).basicAttack > 1)
    assertEquals("Complete", ui.collectionRows[set.id].statusText:GetText())
end)

test("Collection selector reaches every set and uses each set's milestone counts", function()
    local W = WoWIdle
    W.Initialize()
    local ui, G, C = W.UI, W.Game, W.Content
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    ui.frame:Show()
    ui:SetTab("collections")
    for _, collection in ipairs(C.collections) do
        ui.collectionRows[collection.id]:GetScript("OnClick")()
        assertEquals(collection.id, ui.collectionSelected)
        assertTrue(ui.collectionCards[collection.pieces[1]] ~= nil)
    end
    ui.collectionRows.blessingOfKalimdor:GetScript("OnClick")()
    assertTrue(ui.collectionMilestones:GetText():find("3 pieces: +0.5% materials", 1, true) ~= nil)
    local browser = ui.collectionFrame
    browser.scroll:GetScript("OnMouseWheel")(browser.scroll, -100)
    local maximum = browser.catalog:GetHeight() - browser.scroll:GetHeight()
    assertTrue(math.abs(maximum - browser.scroll:GetVerticalScroll()) < 0.1)
    ui:Refresh()
    assertTrue(math.abs(maximum - browser.scroll:GetVerticalScroll()) < 0.1)
    browser.scroll:GetScript("OnMouseWheel")(browser.scroll, 100)
    assertEquals(0, browser.scroll:GetVerticalScroll())
    ui:SetTab("party")
    assertFalse(browser:IsShown())
end)
