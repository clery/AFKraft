if not test then
    return
end

local function report()
    local W = AFKraft
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    return W, state, W.UI
end

test("Return report opens without claiming rewards and stays out of compact controls", function()
    local W, state, ui = report()
    state.lastOfflineSummary = {
        seconds = 3600,
        remainingSeconds = 0,
        interrupted = false,
        gold = 400,
        victories = 20,
        heroXP = 120,
        heroLevels = 2,
        masteryXP = 30,
        masteryRanks = 1,
        itemsKept = 4,
        salvaged = 10,
        materials = { timber = 22, ore = 0, hide = 0, relic = 10 },
        boostUses = 3,
        discoveries = 1,
        upgrades = 0,
        routeTransitions = 0,
        routesWaiting = true,
    }
    state.gold = 456
    ui:Refresh()
    assertNotNil(ui.offlineReport)
    assertTrue(ui.reportLink:IsShown())
    ui.reportLink:GetScript("OnClick")()
    assertEquals("offline", state.ui.tab)
    assertEquals("Return report", ui.section:GetText())
    assertFalse(ui.scene.frame:IsShown())
    assertNotNil(ui.offlineCards.automation)
    assertEquals(nil, ui.offlineCards.collections)
    assertEquals(456, state.gold)
    local summary = state.lastOfflineSummary
    ui.offlineBack:GetScript("OnClick")()
    assertEquals("adventure", state.ui.tab)
    assertEquals(summary, state.lastOfflineSummary)
    state.ui.compact = true
    ui:ApplyMode()
    assertFalse(ui.panel:IsVisible())
    assertFalse(ui.offlineFrame:IsShown())
    assertEquals(456, W.state.gold)
end)

test("Missing and older return reports display safely", function()
    local _, state, ui = report()
    ui:SetTab("offline")
    assertTrue(next(ui.offlineCards) == nil)
    state.lastOfflineSummary = { discoveries = 1, boostUses = 0 }
    ui:Refresh()
    assertNotNil(ui.offlineCards.progress)
    assertNotNil(ui.offlineCards.materials)
    state.lastOfflineSummary =
        { seconds = 20, interrupted = true, remainingSeconds = 40, materials = false }
    ui:Refresh()
    assertNotNil(ui.offlineBack)
end)

test(
    "Return highlights offer real equipment, enhancement and talent actions before totals",
    function()
        local W, state, ui = report()
        local G = W.Game
        local equipped = G.Item(state, 1, 1, 2, false, W.Content.itemByID[25])
        equipped.stats = { strength = 4 }
        state.heroes[1].gear[1] = equipped
        state.gold, state.materials.ore = 100, 20
        state.lastOfflineSummary = {
            seconds = 3600,
            gold = 100,
            heroXP = 20,
            chests = 1,
            materials = {},
            heroGains = { { hero = 1, levels = 1, level = 2, masteryRanks = 0 } },
            enhancement = { hero = 1, slot = 1, uid = equipped.uid, upgrade = 0 },
        }
        local item = G.Item(state, 1, 1, 3, false, W.Content.itemByID[25])
        item.stats = { strength = 20 }
        G.StoreChest(state, G.Item(state, 2, 1, 2))
        ui:SetTab("offline")
        assertEquals(3, #ui.offlineHighlights)
        assertNotNil(ui.offlineChests)
        ui.offlineHighlights[1].action:GetScript("OnClick")()
        assertEquals(1, equipped.upgrade)
        assertEquals(84, state.gold)
        assertEquals(18, state.materials.ore)
        G.Loot(state, item)
        ui:Refresh()
        assertTrue(
            ui.offlineHighlights[1].titleText:GetText():find(G.ItemName(item), 1, true) ~= nil
        )
        ui.offlineHighlights[1].action:GetScript("OnClick")()
        assertEquals(item.uid, state.heroes[1].gear[1].uid)
        local gold = state.gold
        local update = ui.offlineFrame:GetScript("OnUpdate")
        update(ui.offlineFrame, 0.2)
        assertTrue(ui.offlineAge > 0)
        update(ui.offlineFrame, 2)
        assertEquals("+100" .. W.L.GOLD_SUFFIX_3, ui.offlineCards.earnings.counterText:GetText())
        assertEquals(gold, state.gold)
        local age = ui.offlineAge
        ui:Refresh()
        assertEquals(age, ui.offlineAge)
        ui.offlineChests:GetScript("OnClick")()
        assertEquals("chests", state.ui.tab)
        assertFalse(ui.offlineFrame:IsShown())
        ui:SetTab("offline")
        ui.offlineParty:GetScript("OnClick")()
        assertEquals("party", state.ui.tab)
    end
)

test(
    "New return reports wait for expanded mode, appear once and survive leaving the report",
    function()
        local W, state, ui = report()
        state.safe.elwynn = 1
        ui.frame:Hide()
        state.ui.compact = true
        ui:ApplyMode()
        W.catchup = assert(W.Game.BeginCatchup(state, state.lastTime + 120))
        W.catchup.remaining = 0
        W.Controller.Update(nil, 0.01)
        assertNotNil(ui.returnReportPending)
        assertEquals("adventure", state.ui.tab)
        ui.frame:Show()
        assertEquals("adventure", state.ui.tab)
        state.ui.compact = false
        ui:ApplyMode()
        assertEquals("offline", state.ui.tab)
        assertEquals(nil, ui.returnReportPending)
        local summary = state.lastOfflineSummary
        ui.offlineBack:GetScript("OnClick")()
        ui:Refresh()
        assertEquals("adventure", state.ui.tab)
        assertEquals(summary, state.lastOfflineSummary)
    end
)

test("Return reports avoid redundant chest popups and reuse their frames", function()
    local W, state, ui = report()
    for _ = 1, 10 do
        W.Game.StoreChest(state, W.Game.Item(state, 1, 1, 2))
    end
    state.lastOfflineSummary = { seconds = 300, chests = 10, materials = {}, gold = 25 }
    ui:SetTab("offline")
    W.Notifications.Flush()
    assertEquals(nil, W.Notifications.current)
    assertEquals(nil, state.ui.lastChestToastTime)
    local function count(frame)
        local total = select("#", frame:GetRegions()) + 1
        for _, child in ipairs({ frame:GetChildren() }) do
            total = total + count(child)
        end
        return total
    end
    local before = count(ui.offlineFrame)
    for _ = 1, 10 do
        ui:Refresh()
    end
    assertEquals(before, count(ui.offlineFrame))
    ui.offlineHighlights[1].action:GetScript("OnClick")()
    assertEquals("chests", state.ui.tab)
    W.Notifications.Flush()
    assertEquals(nil, W.Notifications.current)
end)

test("Mastery milestones and stale equipment actions remain truthful", function()
    local W, state, ui = report()
    state.lastOfflineSummary = {
        seconds = 3600,
        materials = {},
        heroGains = { { hero = 1, level = state.heroes[1].level, levels = 0, masteryRanks = 2 } },
    }
    local item = W.Game.Item(state, 1, 1, 2, false, W.Content.itemByID[25])
    item.stats = { strength = 10 }
    W.Game.Loot(state, item)
    ui:SetTab("offline")
    assertTrue(ui.offlineHighlights[2].titleText:GetText():find("2", 1, true) ~= nil)
    local equip = ui.offlineHighlights[1].action:GetScript("OnClick")
    local better = W.Game.Item(state, 1, 1, 2, false, W.Content.itemByID[25])
    better.stats = { strength = 100 }
    state.heroes[1].gear[1] = better
    equip()
    assertEquals(better, state.heroes[1].gear[1])
    assertEquals(item, state.inventory[1])
end)

test("Login and reload select the return menu even without an offline catch-up", function()
    local W, previous, ui = report()
    local saved, catchup = AFKraftDB, W.catchup
    local load, bind, create, minimap, settings =
        W.Game.Load, W.BindPreferences, W.CreateUI, W.Minimap.Create, W.RegisterSettings
    local ok, message = pcall(function()
        for _, compact in ipairs({ false, true }) do
            local state = W.Game.New(W.Client.Now())
            W.Game.AddHero(state, "WARRIOR")
            state.ui.tab, state.ui.compact = "party", compact
            W.Game.Load = function()
                return state
            end
            W.BindPreferences = function()
                return true
            end
            W.CreateUI = function()
                assertEquals("offline", state.ui.tab)
                assertEquals(compact, state.ui.compact)
            end
            W.Minimap.Create = function() end
            W.RegisterSettings = function() end
            W.state = nil
            W.Initialize()
            assertEquals(nil, W.catchup)
            assertEquals("offline", state.ui.tab)
        end
    end)
    W.Game.Load, W.BindPreferences, W.CreateUI, W.Minimap.Create, W.RegisterSettings =
        load, bind, create, minimap, settings
    W.state, AFKraftDB, W.catchup = previous, saved, catchup
    ui:Refresh()
    assert(ok, message)
end)
