if not test then
    return
end

local function click(button)
    assertTrue(button:IsEnabled())
    button:GetScript("OnClick")(button)
end

test("Ordered boost rule drafts reorder four rows and save only on request", function()
    local W = WoWIdle
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.essence, state.legacy, state.guide.dismissed = 30, 3, true
    assertTrue(G.BuyBoost(state, "battleOrders"))
    assertTrue(G.BuyBoostAutomation(state, "onCooldown"))
    assertTrue(G.BuyBoostAutomation(state, "conditional"))
    W.state, ui.selectedBoost, ui.boostRuleDrafts = state, "battleOrders", nil
    ui.boostRulesExpanded = false
    ui.frame:Show()
    ui:SetTab("boosts")
    click(ui.boostRulesToggle)
    for _ = 1, 4 do
        click(ui.boostRuleControls.add)
    end
    assertFalse(ui.boostRuleControls.add:IsEnabled())
    local config = state.boosts.automation.abilities.battleOrders
    assertTrue(config.rules == nil or #config.rules == 0)
    local draft = ui.boostRuleDrafts.battleOrders.rules
    draft[1].condition = "always"
    draft[2].condition, draft[2].threshold = "lowHealth", 65
    draft[3].condition, draft[3].threshold = "tier", 2
    draft[4].condition = "farming"
    ui:Refresh()
    click(ui.boostRuleControls.rows[3].up)
    assertEquals("tier", ui.boostRuleDrafts.battleOrders.rules[2].condition)
    click(ui.boostRuleControls.rows[1].down)
    assertEquals("tier", ui.boostRuleDrafts.battleOrders.rules[1].condition)
    assertFalse(ui.boostRuleControls.rows[1].up:IsEnabled())
    assertFalse(ui.boostRuleControls.rows[4].down:IsEnabled())
    click(ui.boostRuleControls.save)
    assertEquals(4, #config.rules)
    assertEquals("tier", config.rules[1].condition)
    assertEquals(2, config.rules[1].threshold)
    assertEquals(nil, state.boosts.readyAt.battleOrders)
    click(ui.boostRuleControls.rows[4].remove)
    assertEquals(4, #config.rules)
    click(ui.boostRuleControls.save)
    assertEquals(3, #config.rules)
    for _, row in ipairs(ui.boostRuleControls.rows) do
        local bottom = row.remove:GetTop() - row.remove:GetHeight()
        assertTrue(bottom >= ui.panel:GetBottom() - 0.1)
    end
end)

test("Ordered boost rule editor respects ownership and survives tab pooling", function()
    local W = WoWIdle
    W.Initialize()
    local state, ui = W.Game.New(W.Client.Now()), W.UI
    W.Game.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state, ui.selectedBoost, ui.boostRuleDrafts = state, "battleOrders", nil
    ui.boostRulesExpanded = false
    ui.frame:Show()
    ui:SetTab("boosts")
    assertFalse(ui.boostRulesToggle:IsEnabled())
    assertEquals(nil, ui.boostRuleControls)
    ui:SetTab("collections")
    ui:SetTab("boosts")
    assertFalse(ui.boostRulesToggle:IsEnabled())
    assertEquals(nil, ui.boostRuleControls)
end)
