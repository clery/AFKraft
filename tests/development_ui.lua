if not test then
    return
end
local function click(control)
    assertNotNil(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end
local function board()
    local W = WoWIdle
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.essence, s.guide.dismissed = 100000, true
    s.ui.compact, s.ui.locked = false, false
    W.state = s
    local ui = W.UI
    ui.frame:Show()
    ui:SetTab("development")
    return W, s, ui
end

test("Development board buys and refunds exact prices with live current and next state", function()
    local W, s, ui = board()
    local initial = s.essence
    local branch = ui.developmentControls.branches.might
    assertTrue(branch.buy.text:GetText():find("60 Essence", 1, true) ~= nil)
    assertFalse(branch.refund:IsEnabled())
    click(branch.buy)
    assertEquals(initial - 60, s.essence)
    assertEquals(1, s.development.ranks.might)
    branch = ui.developmentControls.branches.might
    assertTrue(branch.buy.text:GetText():find("240 Essence", 1, true) ~= nil)
    assertTrue(branch.refund.text:GetText():find("60 Essence", 1, true) ~= nil)
    click(branch.refund)
    assertEquals(initial, s.essence)
    assertEquals(0, s.development.invested)
    assertFalse(ui.developmentControls.reset:IsEnabled())
    s.essence = 59
    ui:Refresh()
    assertFalse(ui.developmentControls.branches.might.buy:IsEnabled())
    assertTrue(W.Game.ValidateDevelopment(s))
end)

test("Development milestones unlock, switch freely and persist through redistribution", function()
    local _, s, ui = board()
    assertFalse(ui.developmentControls.branches.resolve.choices.bulwark:IsEnabled())
    for _ = 1, 3 do
        click(ui.developmentControls.branches.resolve.buy)
    end
    click(ui.developmentControls.branches.resolve.choices.bulwark)
    assertEquals("bulwark", s.development.choices.resolve)
    local essence = s.essence
    click(ui.developmentControls.branches.resolve.choices.renewal)
    assertEquals("renewal", s.development.choices.resolve)
    assertEquals(essence, s.essence)
    click(ui.developmentControls.reset)
    assertEquals(100000, s.essence)
    assertEquals("renewal", s.development.choices.resolve)
    assertFalse(ui.developmentControls.branches.resolve.choices.renewal:IsEnabled())
end)

test("Development controls cap ranks and reuse the management frame pools", function()
    local _, s, ui = board()
    for _ = 1, 10 do
        click(ui.developmentControls.branches.provisioning.buy)
    end
    assertEquals(10, s.development.ranks.provisioning)
    assertFalse(ui.developmentControls.branches.provisioning.buy:IsEnabled())
    local counts = {}
    for _, pool in pairs(ui.panel._pool) do
        counts[pool] = pool:GetNumActive()
    end
    ui:Refresh()
    for _, pool in pairs(ui.panel._pool) do
        assertEquals(counts[pool], pool:GetNumActive())
    end
    click(ui.developmentControls.branches.provisioning.refund)
    assertTrue(ui.developmentControls.branches.provisioning.buy:IsEnabled())
    ui:SetTab("adventure")
    assertEquals("adventure", s.ui.tab)
end)

test("Adventure cards preview affordable development without spending", function()
    local W = WoWIdle
    W.Initialize()
    local G, ui = W.Game, W.UI
    local s = G.New(W.Client.Now())
    G.AddHero(s, "WARRIOR")
    s.guide.dismissed, s.essence = true, 60
    W.state = s
    ui.frame:Show()
    ui:SetTab("adventure")
    local branch, quote = W.Panels.DevelopmentOpportunity(s)
    assertEquals("might", branch.id)
    assertEquals(60, quote.cost)
    assertNotNil(ui.adventureDevelopment)
    assertTrue(ui.adventureDevelopment.titleText:GetText():find("Might rank 1", 1, true) ~= nil)
    assertTrue(ui.adventureDevelopment.detailText:GetText():find("+5.0%", 1, true) ~= nil)
    ui.adventureDevelopment:GetScript("OnClick")()
    assertEquals("development", s.ui.tab)
    assertEquals(60, s.essence)
    assertTrue(G.BuyDevelopment(s, "might"))
    branch = W.Panels.DevelopmentOpportunity(s)
    assertEquals("resolve", branch.id)
    s.essence = 0
    ui:SetTab("adventure")
    ui:Refresh(false)
    assertTrue(ui.adventureDevelopment.titleText:GetText():find("Save 60 Essence", 1, true) ~= nil)
    s.essence = 60
    ui:Refresh(false)
    assertTrue(ui.adventureDevelopment.titleText:GetText():find("Save", 1, true) == nil)
    s.development.ranks = { might = 10, resolve = 10, provisioning = 10 }
    s.development.invested, s.essence = 69300, 0
    ui:Refresh(false)
    assertEquals("Growth complete", ui.adventureDevelopment.titleText:GetText())
    assertTrue(G.BeginHuntSession(s, W.Client.Now()))
    assertTrue(G.AdventureXP(s, 100, "quest", "Activity fixture"))
    ui:Refresh(false)
    assertTrue(ui.adventureSession:GetText():find("100 Adventure XP", 1, true) ~= nil)
    assertTrue(ui.adventureSession:GetText():find("60 Essence", 1, true) ~= nil)
    assertTrue(G.AdventureXP(s, 0.25, "skinning", "Partial activity fixture"))
    ui:Refresh(false)
    assertTrue(ui.adventureSession:GetText():find("100.25 Adventure XP", 1, true) ~= nil)
end)
