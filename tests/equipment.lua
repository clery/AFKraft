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

test("Party equipment buttons enforce class armor restrictions", function()
    local W = WoWIdle
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "MAGE")
    s.heroes[1].level = 39
    s.guide.dismissed = true
    local mail = W.Game.Item(s, 2, 1, 3, false, W.Content.itemByID[13123])
    local cloth = W.Game.Item(s, 2, 1, 2, false, W.Content.itemByID[3069])
    s.inventory = { mail, cloth }
    W.state = s
    local ui = W.UI
    ui.selected, ui.bagFilter, ui.bagView, ui.bagPage = 1, 0, {}, 0
    ui:SetTab("party")
    local mailButton, clothButton
    for button in ui.panel._pool.selection:EnumerateActive() do
        if button._pool and button._pool.text then
            for label in button._pool.text:EnumerateActive() do
                if label:GetText() == mail.name then
                    mailButton = button
                end
                if label:GetText() == cloth.name then
                    clothButton = button
                end
            end
        end
    end
    assertNotNil(mailButton)
    assertNotNil(clothButton)
    assertFalse(mailButton:IsEnabled())
    assertTrue(clothButton:IsEnabled())
    -- A direct callback also goes through the domain restriction.
    mailButton:GetScript("OnClick")(mailButton)
    assertEquals(nil, s.heroes[1].gear[2])
    clothButton:GetScript("OnClick")(clothButton)
    assertEquals(cloth, s.heroes[1].gear[2])
end)

test("Party stat guide restores the shared tooltip width when hidden", function()
    local W = WoWIdle
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.guide.dismissed = true
    W.state = s
    W.UI.selected = 1
    W.UI:SetTab("party")
    local help = W.UI.panel._pool.help:EnumerateActive()()
    assertNotNil(help)
    assertNotNil(help.icon:GetTexture())
    local width, force = GameTooltip:GetMinimumWidth()
    help:GetScript("OnEnter")(help)
    assertEquals(380, GameTooltip:GetMinimumWidth())
    help:GetScript("OnLeave")(help)
    help:GetScript("OnEnter")(help)
    help:Hide()
    GameTooltip:Hide()
    local restored, restoredForce = GameTooltip:GetMinimumWidth()
    assertEquals(width, restored)
    assertEquals(force, restoredForce)
end)
