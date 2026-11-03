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
        state.collectionBook.pieces[set.pieces[1]] = 0
        ui:Refresh()
        assertEquals(1, G.CollectionProgress(state, set.id).found)
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
        ui:SetTab("party")
        assertFalse(GameTooltip:IsShown())
    end
)
