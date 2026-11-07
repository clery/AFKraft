if not test then
    return
end

test("Forge compares crafted power with the selected hero and equipment slot", function()
    local W = AFKraft
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    G.AddHero(state, "PRIEST")
    state.guide.dismissed = true
    W.state = state
    ui.selected, ui.craftSlot = 1, 1
    ui.frame:Show()
    ui:SetTab("crafting")
    local function check(heirloom)
        local hero, slot = state.heroes[ui.selected], ui.craftSlot
        local preview = assert(G.CraftItem(hero, slot, heirloom, state))
        local current = G.ItemPower(hero.gear[slot], hero)
        local delta = G.ItemPower(preview, hero) - current
        assertEquals(
            W.L.CURRENT_POWER_PREFIX .. current .. "  ·  " .. string.format("%+.1f", delta),
            ui.craftControls[heirloom and "heirloom" or "ordinary"].comparison:GetText()
        )
        return delta
    end
    assertTrue(check() > 0)
    local hero = state.heroes[1]
    hero.gear[1] = G.CraftItem(hero, 1, false, state)
    ui:Refresh()
    assertEquals(0, check())
    hero.gear[1].upgrade = 3
    ui:Refresh()
    assertTrue(check() < 0)
    ui.craftControls.slots[2]:GetScript("OnClick")()
    assertTrue(check() > 0)
    ui.selected = 2
    ui:Refresh()
    assertTrue(check() > 0)
    state.best = 60
    ui:Refresh()
    check(true)
end)

test("Forge offers both crafts together and keeps heirloom requirements separate", function()
    local W = AFKraft
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    state.gold, state.materials.timber = 10000, 10000
    W.state = state
    ui.selected, ui.craftSlot, ui.craftMaterial = 1, 1, "timber"
    ui.frame:Show()
    ui:SetTab("crafting")
    assertTrue(ui.craftControls.ordinary.craft:IsVisible())
    assertTrue(ui.craftControls.heirloom.craft:IsVisible())
    assertTrue(ui.craftControls.ordinary.craft:IsEnabled())
    assertFalse(ui.craftControls.heirloom.craft:IsEnabled())
    state.difficulty.maxTier = 4
    ui:Refresh()
    assertFalse(ui.craftControls.heirloom.craft:IsEnabled())
    state.recipes[1] = true
    ui:Refresh()
    assertTrue(ui.craftControls.heirloom.craft:IsEnabled())
    ui.craftControls.heirloom.craft:GetScript("OnClick")()
    assertTrue(state.heroes[1].gear[1].heirloom)
    local gold = state.gold
    local cost = G.Cost(state, state.heroes[1], false)
    ui.craftControls.ordinary.craft:GetScript("OnClick")()
    assertEquals(gold - cost.gold, state.gold)
    local ordinary = not state.heroes[1].gear[1].heirloom
    for _, item in ipairs(state.inventory) do
        ordinary = ordinary or not item.heirloom
    end
    assertTrue(ordinary)
end)
