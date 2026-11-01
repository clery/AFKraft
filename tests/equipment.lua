if not test then
    return
end

test(
    "Wearable recipes craft into their selected slot and retired slots stay unavailable",
    function()
        local W = WoWIdle
        W.Initialize()
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "WARRIOR")
        state.heroes[1].level = 60
        state.guide.dismissed = true
        state.essence, state.gold, state.materials.timber = 10000, 10000, 10000
        W.state = state
        local ui = W.UI
        ui.selected, ui.craftSlot, ui.craftMaterial, ui.craftHeirloom = 1, 1, "timber", false
        ui.frame:Show()
        ui:SetTab("crafting")
        for _, slot in ipairs(W.Content.equipmentSlots) do
            local control = ui.craftControls.slots[slot]
            assertNotNil(control)
            control:GetScript("OnClick")(control)
            assertEquals(slot, ui.craftSlot)
            ui.craftControls.craft:GetScript("OnClick")(ui.craftControls.craft)
            assertEquals(slot, state.inventory[#state.inventory].slot)
        end
        assertEquals(nil, ui.craftControls.slots[5])
        assertEquals(nil, ui.craftControls.slots[6])
        ui:SetTab("party")
        assertTrue(W.Game.EquipBest(state, 1))
        for _, slot in ipairs(W.Content.equipmentSlots) do
            assertNotNil(state.heroes[1].gear[slot])
        end
        ui:Refresh()
    end
)
