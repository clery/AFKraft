if not test then
    return
end

test("Dungeon collections expose independent progress and a globally shared effect", function()
    local W = AFKraft
    W.Initialize()
    local G, C, ui = W.Game, W.Content, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    ui.frame:Show()
    ui.collectionSelected = nil
    ui:SetTab("collections")
    ui.collectionSelected = "defiasLeather"
    ui:Refresh()
    assertEquals("defiasLeather", ui.collectionSelected)
    local collection = C.collectionByID.defiasLeather
    local itemID = collection.pieces[1]
    assertTrue(ui.collectionCards[itemID] ~= nil)
    assertFalse(ui.collectionEffect:IsEnabled())
    state.dungeonCollections.stats.kills = 4
    ui:Refresh()
    assertTrue(ui.collectionProgress:GetText():find("4 eligible dungeon kills", 1, true) ~= nil)
    for _, id in ipairs(collection.pieces) do
        state.dungeonCollections.pieces[id] = true
    end
    ui:Refresh()
    assertTrue(ui.collectionEffect:IsEnabled())
    ui.collectionEffect:GetScript("OnClick")()
    assertEquals(collection.id, G.ActiveCollectionEffect(state))
    assertTrue(ui.collectionEffectStatus:GetText():find(collection.name, 1, true) ~= nil)
end)

test(
    "Dungeon book reports current and saved dungeon sessions without borrowing outdoor totals",
    function()
        local W = AFKraft
        W.Initialize()
        local G, ui = W.Game, W.UI
        local state = G.New(W.Client.Now())
        G.AddHero(state, "WARRIOR")
        state.guide.dismissed = true
        W.state = state
        assertTrue(G.BeginHuntSession(state, W.Client.Now()))
        state.outdoorCollections.stats.kills = 20
        state.dungeonCollections.stats.kills = 3
        state.dungeonCollections.pieces[10399] = true
        state.dungeonCollections.stats.discoveries = 1
        ui.collectionSelected = "defiasLeather"
        ui.frame:Show()
        ui:SetTab("collections")
        assertTrue(
            ui.collectionProgress
                :GetText()
                :find("Session dungeon hunt: 3 kills | Finds: 1", 1, true) ~= nil
        )
        assertFalse(ui.collectionProgress:GetText():find("20 kills", 1, true) ~= nil)
        assertTrue(G.SaveHuntSession(state, W.Client.Now()))
        local nextState = G.New(W.Client.Now())
        G.AddHero(nextState, "WARRIOR")
        nextState.guide.dismissed = true
        nextState.lastHuntSummary = G.Copy(state.lastHuntSummary)
        W.state = nextState
        assertTrue(G.BeginHuntSession(nextState, W.Client.Now()))
        ui:SetTab("collections")
        assertTrue(
            ui.collectionProgress
                :GetText()
                :find("Previous dungeon hunt: 3 kills | Finds: 1", 1, true) ~= nil
        )
        nextState.lastHuntSummary.dungeon = nil
        ui:Refresh()
        assertTrue(
            ui.collectionProgress:GetText():find("Previous dungeon hunt: Unrecorded", 1, true)
                ~= nil
        )
        ui.collectionSelected = "redridgeOutriders"
        ui:Refresh()
        assertTrue(
            ui.collectionProgress:GetText():find("Previous hunt: 20 kills | Finds: 0", 1, true)
                ~= nil
        )
    end
)
