if not test then
    return
end

local function click(button)
    assertTrue(button:IsEnabled())
    button:GetScript("OnClick")(button)
end

test("Commander controls buy once, equip, activate, and refresh timers without redraw", function()
    local W = WoWIdle
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.essence, s.guide.dismissed = 60, true
    W.state = s
    local ui = W.UI
    s.ui.compact, s.ui.locked = false, false
    ui.frame:Show()
    ui:SetTab("boosts")
    local controls = ui.boostControls.battleOrders
    click(controls.purchase)
    assertEquals(30, s.essence)
    controls = ui.boostControls.battleOrders
    assertFalse(controls.purchase:IsEnabled())
    click(controls.activate)
    controls = ui.boostControls.battleOrders
    assertTrue(controls.status:GetText():find("Active 5:00 / Ready 10:00", 1, true) ~= nil)
    s.clock = 300
    ui:Refresh(false)
    assertTrue(ui.boostControls.battleOrders == controls)
    assertEquals("Ready in 5:00", controls.status:GetText())
    assertFalse(controls.activate:IsEnabled())
    s.clock = 600
    ui:Refresh(false)
    assertEquals("Ready.", controls.status:GetText())
    assertTrue(controls.activate:IsEnabled())
    click(ui.boostControls.ironResolve.purchase)
    click(ui.boostControls.ironResolve.equip)
    assertEquals("ironResolve", s.boosts.equipped)
    assertEquals(0, s.essence)
end)

test("Adventure and compact boost controls share readiness and respect window locking", function()
    local W = WoWIdle
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.essence, s.guide.dismissed = 30, true
    assertTrue(W.Game.BuyBoost(s, "battleOrders"))
    W.state = s
    local ui = W.UI
    ui:SetTab("adventure")
    assertTrue(ui.boostQuick:IsEnabled())
    s.ui.compact = true
    ui:ApplyMode()
    click(ui.compactBoost)
    assertTrue(s.boosts.activeUntil.battleOrders > s.clock)
    assertFalse(ui.compactBoost:IsEnabled())
    W.Notify("Commander notice")
    assertFalse(ui.compactBoost:IsShown())
    assertEquals("Commander notice", ui.compactHint:GetText())
    ui.messageUntil = GetTime() - 1
    ui:Refresh(false)
    assertTrue(ui.compactBoost:IsShown())
    s.ui.locked = true
    ui:Layout()
    ui:Refresh(false)
    assertFalse(ui.compactBoost:IsShown())
    assertTrue(ui.lock:IsShown())
    s.ui.locked, s.ui.compact = false, false
    ui:ApplyMode()
    assertFalse(ui.boostQuick:IsEnabled())
end)
