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
        local hovered = false
        for card in ui.panel._pool.button:EnumerateActive() do
            if math.abs(card:GetWidth() - 244) < 0.1 then
                local enter, leave = card:GetScript("OnEnter"), card:GetScript("OnLeave")
                enter(card)
                assertTrue(GameTooltip:IsShown())
                leave(card)
                hovered = true
                break
            end
        end
        assertTrue(hovered)
        assertTrue(ui.collectionSourceStatus:GetText():find("disabled", 1, true) ~= nil)
        assertFalse(ui.collectionEffect:IsEnabled())
        state.collectionBook.pieces[C.legacyCollections[1].pieces[1]] = 0
        ui:Refresh()
        assertTrue(ui.collectionLegacyStatus:GetText():find("1/5", 1, true) ~= nil)
        ui:SetTab("party")
        assertFalse(GameTooltip:IsShown())
    end
)

test("Outdoor collections track individual pieces and select one completed effect", function()
    local W = WoWIdle
    local G, C, ui = W.Game, W.Content, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    ui.collectionSelected, ui.collectionPiece = nil, nil
    ui:SetTab("collections")
    local set = C.collections[1]
    local selected = set.pieces[2]
    ui.collectionCards[selected]:GetScript("OnClick")()
    ui.collectionTarget:GetScript("OnClick")()
    assertEquals(selected, state.outdoorCollections.target)
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
    ui.collectionTarget:GetScript("OnClick")()
    assertEquals(nil, state.outdoorCollections.target)
    assertTrue(G.CollectionBonuses(state).basicAttack > 1)
    assertTrue(G.SetCollectionTarget(state, selected))
    state.ui.compact, state.ui.locked = true, false
    ui:ApplyMode()
    assertTrue(ui.compactCollectionGoal:IsShown())
    assertTrue(
        ui.compactCollectionGoal.text:GetText():find(C.itemByID[selected].name, 1, true) ~= nil
    )
    state.ui.locked = true
    ui:Refresh(false)
    assertFalse(ui.compactCollectionGoal:IsShown())
    state.ui.locked = false
    ui:Refresh(false)
    ui.compactCollectionGoal:GetScript("OnClick")()
    assertFalse(state.ui.compact)
    assertEquals("collections", state.ui.tab)
end)
