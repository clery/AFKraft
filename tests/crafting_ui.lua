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
    ui.selected, ui.craftSlot, ui.craftHeirloom = 1, 1, false
    ui.frame:Show()
    ui:SetTab("crafting")
    local function check()
        local hero, slot = state.heroes[ui.selected], ui.craftSlot
        local preview = assert(G.CraftItem(hero, slot, ui.craftHeirloom, state))
        local current = G.ItemPower(hero.gear[slot], hero)
        local delta = G.ItemPower(preview, hero) - current
        assertEquals(
            W.L.CURRENT_POWER_PREFIX .. current .. "  ·  " .. string.format("%+.1f", delta),
            ui.craftControls.comparison:GetText()
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
    ui.craftHeirloom = true
    ui:Refresh()
    check()
end)
