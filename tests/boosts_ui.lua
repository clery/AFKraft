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
    s.professions.bestLevel = 22
    s.essence, s.guide.dismissed = 60, true
    W.state = s
    local ui = W.UI
    ui.selectedBoost = nil
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
    assertTrue(controls.status:GetText():find("Active 15:00 / Ready 30:00", 1, true) ~= nil)
    s.clock = 900
    ui:Refresh(false)
    assertTrue(ui.boostControls.battleOrders == controls)
    assertEquals("Ready in 15:00", controls.status:GetText())
    assertFalse(controls.activate:IsEnabled())
    s.clock = 1800
    ui:Refresh(false)
    assertEquals("Ready.", controls.status:GetText())
    assertTrue(controls.activate:IsEnabled())
    click(ui.boostTiles.ironResolve.button)
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
    s.professions.bestLevel = math.max(s.professions.bestLevel, 22)
    assertTrue(W.Game.BuyBoost(s, "battleOrders"))
    W.state = s
    local ui = W.UI
    ui.selectedBoost = nil
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

test("Commander automation purchases, rules and pause remain inspectable", function()
    local W = WoWIdle
    local G, U = W.Game, W.Widgets
    local s = G.New(W.Client.Now())
    s.professions.bestLevel = 60
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy, s.guide.dismissed = 30, 3, true
    assertTrue(G.BuyBoost(s, "battleOrders"))
    W.state = s
    local ui = W.UI
    ui.selectedBoost = nil
    s.ui.compact, s.ui.locked = false, false
    ui.frame:Show()
    local originalChoice = U.Choice
    local choices = {}
    U.Choice = function(parent, label, x, y, width, options, value, choose)
        local control = originalChoice(parent, label, x, y, width, options, value, choose)
        choices[control] = { options = options, choose = choose }
        return control
    end
    ui:SetTab("boosts")
    assertFalse(ui.boostAutomationPurchases.conditional:IsEnabled())
    local ruleChoice = choices[ui.boostControls.battleOrders.mode]
    assertEquals(1, #ruleChoice.options)
    click(ui.boostAutomationPurchases.onCooldown)
    assertEquals(2, s.legacy)
    assertFalse(ui.boostAutomationPurchases.onCooldown:IsEnabled())
    assertTrue(ui.boostAutomationPurchases.conditional:IsEnabled())
    ruleChoice = choices[ui.boostControls.battleOrders.mode]
    assertEquals(2, #ruleChoice.options)
    ruleChoice.choose("onCooldown")
    assertEquals("onCooldown", s.boosts.automation.abilities.battleOrders.mode)
    click(ui.boostAutomationPurchases.conditional)
    assertEquals(0, s.legacy)
    local controls = ui.boostControls.battleOrders
    ruleChoice = choices[controls.mode]
    assertEquals(#W.Content.boostAutomationModes, #ruleChoice.options)
    ruleChoice.choose("lowHealth")
    controls = ui.boostControls.battleOrders
    assertTrue(controls.threshold:IsEnabled())
    choices[controls.threshold].choose(65)
    assertEquals(65, s.boosts.automation.abilities.battleOrders.healthBelow)
    controls = ui.boostControls.battleOrders
    controls.automationEnabled:SetChecked(true)
    click(controls.automationEnabled)
    assertTrue(s.boosts.automation.abilities.battleOrders.enabled)
    ui.boostAutomationEnabled:SetChecked(true)
    click(ui.boostAutomationEnabled)
    assertTrue(s.boosts.automation.enabled)
    ui.boostAutomationEnabled:SetChecked(false)
    click(ui.boostAutomationEnabled)
    controls = ui.boostControls.battleOrders
    assertTrue(controls.automaticStatus:GetText():find("paused", 1, true) ~= nil)
    click(controls.activate)
    assertTrue(s.boosts.activeUntil.battleOrders > s.clock)
    controls = ui.boostControls.battleOrders
    local previous = controls
    ui:Refresh(false)
    assertTrue(previous == ui.boostControls.battleOrders)
    local _, reason = G.BoostAutomationStatus(s, "battleOrders")
    assertEquals(reason, controls.automaticStatus:GetText())
    U.Choice = originalChoice
end)

test("Commander selectors recover enabled state across redraws and pooled reuse", function()
    local W = WoWIdle
    local G, U = W.Game, W.Widgets
    local s = G.New(W.Client.Now())
    s.professions.bestLevel = 60
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy, s.guide.dismissed = 30, 1, true
    assertTrue(G.BuyBoost(s, "battleOrders"))
    assertTrue(G.BuyBoostAutomation(s, "onCooldown"))
    W.state = s
    local ui = W.UI
    ui.selectedBoost = nil
    s.ui.compact, s.ui.locked = false, false
    for _ = 1, 4 do
        ui:SetTab("boosts")
        ui:Refresh()
        assertTrue(ui.boostControls.battleOrders.mode:IsEnabled())
        assertFalse(ui.boostControls.battleOrders.threshold:IsEnabled())
        ui:SetTab("loot")
    end
    -- One choice in its own pool makes disabled-frame reuse deterministic.
    local parent = CreateFrame("Frame", nil, ui.panel)
    U.Begin(parent)
    local first = U.Choice(parent, "First", 0, 0, 100, {}, nil, function() end)
    first:SetEnabled(false)
    U.EndBuild(parent)
    U.Begin(parent)
    local reused = U.Choice(parent, "Next", 0, 0, 100, {}, nil, function() end)
    U.EndBuild(parent)
    assertTrue(reused == first and reused:IsEnabled())
    parent:Hide()
end)

test("Boost automation runs while the addon window is hidden", function()
    local W = WoWIdle
    local G = W.Game
    local s = G.New(W.Client.Now())
    s.professions.bestLevel = 60
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy, s.guide.dismissed = 30, 1, true
    assertTrue(G.BuyBoost(s, "battleOrders"))
    assertTrue(G.BuyBoostAutomation(s, "onCooldown"))
    assertTrue(G.ConfigureBoostAutomation(s, "battleOrders", "mode", "onCooldown"))
    assertTrue(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assertTrue(G.SetBoostAutomationEnabled(s, true))
    G.StartBattle(s)
    W.state = s
    W.UI.frame:Hide()
    W.Controller.Update(nil, 0.25)
    assertTrue(s.boosts.readyAt.battleOrders ~= nil)
    assertTrue(s.clock >= 0.25)
    W.UI.frame:Show()
    W.UI:SetTab("boosts")
end)

test("Commander icon grid selects ten boosts and reuses its controls", function()
    local W = WoWIdle
    local C, G, ui = W.Content, W.Game, W.UI
    local s = G.New(W.Client.Now())
    G.AddHero(s, "WARRIOR")
    s.guide.dismissed = true
    W.state = s
    ui.selectedBoost = nil
    s.ui.compact, s.ui.locked = false, false
    local originalCount = #C.boosts
    local ok, problem = pcall(function()
        for index = originalCount + 1, 10 do
            local source, boost = C.boosts[1], {}
            for key, value in pairs(source) do
                boost[key] = value
            end
            boost.id, boost.name = "testBoost" .. index, "Test boost " .. index
            C.boosts[index], C.boostByID[boost.id] = boost, boost
            s.boosts.automation.abilities[boost.id] =
                { enabled = false, mode = "manual", healthBelow = 50 }
        end
        ui:SetTab("boosts")
        local count = 0
        for _ in pairs(ui.boostTiles) do
            count = count + 1
        end
        assertEquals(10, count)
        local _, _, _, firstX, firstY = ui.boostTiles.battleOrders.button:GetPoint()
        local _, _, _, sixthX, sixthY = ui.boostTiles.testBoost6.button:GetPoint()
        assertEquals(firstX, sixthX)
        assertTrue(sixthY < firstY)
        click(ui.boostTiles.testBoost10.button)
        assertEquals("testBoost10", ui.selectedBoost)
        assertTrue(ui.boostControls.testBoost10 ~= nil)
        assertTrue(ui.boostControls.battleOrders == nil)
        assertFalse(ui.boostControls.testBoost10.purchase:IsEnabled())
        assertTrue(
            ui.boostControls.testBoost10.purchase.text:GetText():find("30 Essence", 1, true) ~= nil
        )
        click(ui.boostTiles.battleOrders.button)
        assertTrue(ui.boostControls.battleOrders ~= nil)
        assertTrue(ui.boostControls.testBoost10 == nil)
        local before, after = {}, 0
        for _, pool in pairs(ui.panel._pool) do
            before[pool] = pool:GetNumActive()
        end
        ui:Refresh()
        for _, pool in pairs(ui.panel._pool) do
            assertEquals(before[pool], pool:GetNumActive())
            after = after + pool:GetNumActive()
        end
        assertTrue(after > 0)
    end)
    for index = #C.boosts, originalCount + 1, -1 do
        s.boosts.automation.abilities[C.boosts[index].id] = nil
        C.boostByID[C.boosts[index].id] = nil
        C.boosts[index] = nil
    end
    ui.selectedBoost = nil
    ui:SetTab("boosts")
    assertTrue(G.Load(G.Copy(s), W.Client.Now()) ~= nil)
    if not ok then
        error(problem)
    end
end)
