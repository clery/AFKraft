if not test then
    return
end
local function click(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end

test("Prestige+ tier selection previews retention before an explicit deeper reset", function()
    local W = AFKraft
    W.Initialize()
    local G, ui = W.Game, W.UI
    local state = G.New(W.Client.Now())
    G.AddHero(state, "WARRIOR")
    state.heroes[1].level = 60
    assertTrue(G.TalentProgress(state.heroes[1]) ~= nil)
    state.encounter = 1
    assertTrue(
        G.DifficultyVictory(
            state,
            { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }
        )
    )
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

test("Difficulty previews expose tier affixes without changing the active adventure", function()
    local W = AFKraft
    local G, ui = W.Game, W.UI
    local s = G.New(W.Client.Now())
    G.AddHero(s, "WARRIOR")
    s.difficulty.unlocked, s.difficulty.maxTier, s.guide.dismissed = true, 8, true
    W.state = s
    ui.difficultyTier, ui.difficultyConfirm = 8, false
    ui:SetTab("difficulty")
    assertEquals(0, s.tier)
    for _, id in ipairs({ "relentless", "renewal", "fury" }) do
        local card = ui.difficultyAffixes[id]
        assertNotNil(card)
        card:GetScript("OnEnter")(card)
        assertTrue(GameTooltip:IsShown())
        card:GetScript("OnLeave")(card)
    end
    click(ui.difficultyTiers[0])
    assertTrue(next(ui.difficultyAffixes) == nil)
    assertEquals(0, s.tier)
end)
