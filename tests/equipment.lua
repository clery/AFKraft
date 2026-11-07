if not test then
    return
end

test(
    "Wearable recipes craft into their selected slot and retired slots stay unavailable",
    function()
        local W = AFKraft
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
            assertEquals(slot, state.heroes[1].gear[slot].slot)
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
    local W = AFKraft
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
    for button in ui.bagCarousel.currentPane._pool.selection:EnumerateActive() do
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
    assertEquals(nil, mailButton)
    assertNotNil(clothButton)
    assertTrue(clothButton:IsEnabled())
    assertEquals("usable", ui.bagView.availability)
    -- A direct callback also goes through the domain restriction.
    W.Game.Equip(s, 1, 1)
    assertEquals(nil, s.heroes[1].gear[2])
    clothButton:GetScript("OnClick")(clothButton)
    assertEquals(cloth, s.heroes[1].gear[2])
    ui.bagView.availability = "all"
    ui:Refresh()
    assertEquals(1, #W.Game.InventoryEntries(s, s.heroes[1], 0, ui.bagView))
    local unavailable = ui.bagCarousel.currentPane._pool.selection:EnumerateActive()()
    assertNotNil(unavailable)
    assertFalse(unavailable:IsEnabled())
end)

test("Party stat guide restores the shared tooltip width when hidden", function()
    local W = AFKraft
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

test("Equipped items expose their own upgrade button on the right", function()
    local W = AFKraft
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    local hero = state.heroes[1]
    hero.level = 60
    state.guide.dismissed = true
    state.gold = 100000
    for _, material in ipairs(W.Content.materialOrder) do
        state.materials[material] = 100000
    end
    hero.gear[1] = W.Game.Item(state, 1, 1, 2)
    hero.gear[2] = W.Game.Item(state, 2, 1, 2)
    W.state = state
    local ui = W.UI
    ui.selected, ui.gearSlot = 1, 2
    ui.frame:Show()
    ui:SetTab("party")
    local buttons = {}
    for box in ui.panel._pool.selection:EnumerateActive() do
        if box._pool and box._pool.selection then
            for button in box._pool.selection:EnumerateActive() do
                if button.text:GetText() == "+" then
                    buttons[#buttons + 1] = button
                    local _, _, _, x = button:GetPoint()
                    assertEquals(242, x)
                    assertNotNil(button:GetScript("OnEnter"))
                end
            end
        end
    end
    assertEquals(2, #buttons)
    buttons[1]:GetScript("OnClick")(buttons[1])
    assertEquals(1, (hero.gear[1].upgrade or 0) + (hero.gear[2].upgrade or 0))
end)
