if not test then
    return
end

local function click(button)
    assertTrue(button:IsEnabled())
    button:GetScript("OnClick")(button)
end

test(
    "Profiles save named setups, apply without resetting timers, and hide native inputs",
    function()
        local W = WoWIdle
        W.Initialize()
        local G, ui = W.Game, W.UI
        local state = G.New(W.Client.Now())
        G.AddHero(state, "WARRIOR")
        state.essence, state.guide.dismissed = 60, true
        assertTrue(G.BuyBoost(state, "battleOrders"))
        assertTrue(G.BuyBoost(state, "ironResolve"))
        W.state = state
        ui.selectedProfile, ui.profileNameSelection = nil, nil
        ui.frame:Show()
        ui:SetTab("profiles")
        ui.profileName:SetText("Boss defense")
        click(ui.profileControls.save)
        local id = ui.selectedProfile
        assertEquals("Boss defense", state.boostProfiles.entries[id].name)
        assertTrue(G.ActivateBoost(state, "battleOrders"))
        assertTrue(G.EquipBoost(state, "ironResolve"))
        click(ui.profileControls.apply)
        assertEquals("battleOrders", state.boosts.equipped)
        assertEquals(600, state.boosts.readyAt.battleOrders)
        ui:SetTab("adventure")
        assertFalse(ui.profileFrame:IsShown())
        ui:SetTab("profiles")
        state.ui.compact = true
        ui:ApplyMode()
        assertFalse(ui.profileFrame:IsShown())
        state.ui.compact = false
        ui:ApplyMode()
        click(ui.profileControls.delete)
        assertTrue(state.boostProfiles.entries[id] == nil)
    end
)
