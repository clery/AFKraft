if not test then
    return
end

test(
    "Dungeon collections expose independent progress and a globally shared target and effect",
    function()
        local W = WoWIdle
        W.Initialize()
        local G, C, ui = W.Game, W.Content, W.UI
        local state = G.New(W.Client.Now())
        G.AddHero(state, "WARRIOR")
        state.guide.dismissed = true
        W.state = state
        ui.frame:Show()
        ui.collectionSelected, ui.collectionPiece = nil, nil
        ui:SetTab("collections")
        ui.collectionChoices.defiasLeather:GetScript("OnClick")()
        assertEquals("defiasLeather", ui.collectionSelected)
        local collection = C.collectionByID.defiasLeather
        local itemID = collection.pieces[1]
        assertTrue(ui.collectionCards[itemID] ~= nil)
        assertFalse(ui.collectionEffect:IsEnabled())
        assertTrue(G.SetCollectionTarget(state, C.collections[1].pieces[1]))
        ui.collectionTarget:GetScript("OnClick")()
        assertEquals(itemID, G.CollectionTarget(state))
        assertEquals(nil, state.outdoorCollections.target)
        local tracked = W.CollectionPanel.TrackedPiece(state)
        assertEquals("dungeon", tracked.kind)
        assertEquals(G.CollectionItem(itemID), tracked.item)
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
        state.ui.compact, state.ui.locked = true, false
        ui:ApplyMode()
        assertTrue(
            ui.compactCollectionGoal.text:GetText():find(G.CollectionItem(itemID).name, 1, true)
                ~= nil
        )
        ui.compactCollectionGoal:GetScript("OnClick")()
        assertEquals(collection.id, ui.collectionSelected)
        assertEquals(itemID, ui.collectionPiece)
        assertEquals("collections", state.ui.tab)
        ui:SetTab("adventure")
        ui.adventureHunt:GetScript("OnClick")()
        assertEquals(collection.id, ui.collectionSelected)
    end
)

test(
    "Dungeon book reports current and saved dungeon sessions without borrowing outdoor totals",
    function()
        local W = WoWIdle
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
        ui.collectionSelected, ui.collectionPiece = "defiasLeather", 10399
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
        ui.collectionChoices.redridgeOutriders:GetScript("OnClick")()
        assertTrue(
            ui.collectionProgress:GetText():find("Previous hunt: 20 kills | Finds: 0", 1, true)
                ~= nil
        )
    end
)
