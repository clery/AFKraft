if not test then
    return
end
local function click(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end

test("Prestige+ tier selection previews retention before an explicit deeper reset", function()
    local W = WoWIdle
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.heroes[1].level = 60
    assertTrue(G.TalentProgress(state.heroes[1]) ~= nil)
    state.encounter = 1
    assertTrue(G.DifficultyVictory(state, { boss = true, level = 60 }))
    state.ui.compact, state.guide.dismissed = false, true
    W.state = state
    ui.difficultyTier, ui.difficultyConfirm = nil, false
    ui.frame:Show()
    ui:SetTab("difficulty")
    click(ui.difficultyTiers[1])
    assertEquals(0, state.tier)
    assertEquals(60, state.heroes[1].level)
    click(ui.difficultyReview)
    assertTrue(ui.difficultyConfirm)
    assertTrue(ui.difficultyExecute:IsEnabled())
    click(ui.difficultyCancel)
    assertEquals(60, state.heroes[1].level)
    click(ui.difficultyReview)
    click(ui.difficultyExecute)
    assertEquals(1, state.tier)
    assertEquals(1, state.heroes[1].level)
    assertEquals(1, state.difficulty.currency)
    click(ui.inheritancePurchases.rebuilding)
    assertEquals(1, state.difficulty.purchases.rebuilding)
    assertEquals(0, state.difficulty.currency)
end)
