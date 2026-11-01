if not test then
    return
end

local function poolSize(frame, objects)
    local count = 0
    for _, pool in pairs(frame._pool or {}) do
        count = count + pool:GetNumActive()
        for region in pool:EnumerateActive() do
            if objects then
                objects[region] = true
            end
            count = count + poolSize(region, objects)
        end
    end
    return count
end

test("Addon initializes a saved party and window", function()
    WoWIdle.Initialize()
    assertNotNil(WoWIdle.state)
    assertNotNil(WoWIdleWindow)
    assertTrue(#WoWIdle.state.heroes >= 1)
    local scenery = WoWIdle.UI.scene.scenery
    assertTrue(type(scenery.supported) == "boolean")
    if not scenery.supported then
        assertTrue(type(scenery.lastError) == "string")
    end
end)
test("Management views reuse frames and preserve simulation state", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    for _, id in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "DRUID" }) do
        W.Game.AddHero(state, id)
    end
    W.state = state
    W.UI.frame:Show()
    for _, tab in ipairs({ "party", "talents", "crafting", "atlas", "legacy", "loot", "adventure" }) do
        W.UI:SetTab(tab)
    end
    local pooled = W.UI.panel._pool.button
    local count = pooled:GetNumActive()
    local originalObjects = {}
    local total = poolSize(W.UI.panel, originalObjects)
    for _ = 1, 5 do
        W.UI:Refresh()
    end
    assertEquals(count, pooled:GetNumActive())
    local refreshedObjects = {}
    assertEquals(total, poolSize(W.UI.panel, refreshedObjects))
    for region in pairs(refreshedObjects) do
        assertTrue(originalObjects[region], "Repeated redraw allocated a replacement widget")
    end
    assertEquals(5, #W.state.heroes)
    W.state.ui.compact = true
    W.UI:ApplyMode()
    assertTrue(W.UI.compact:IsShown())
    assertFalse(W.UI.expanded:IsShown())
end)

test(
    "Management gets more building space and compact lock leaves only unlock interactive",
    function()
        local ui, state = WoWIdle.UI, WoWIdle.state
        state.ui.compact, state.ui.locked = false, false
        ui:SetTab("adventure")
        local stageHeight, panelHeight = ui.scene.frame:GetHeight(), ui.panel:GetHeight()
        ui:SetTab("party")
        assertTrue(ui.scene.frame:GetHeight() < stageHeight)
        assertTrue(ui.panel:GetHeight() > panelHeight)
        ui:SetTab("talents")
        ui.cards[2]:GetScript("OnClick")(ui.cards[2])
        assertEquals("talents", state.ui.tab)
        assertEquals(2, ui.selected)
        ui:SetTab("crafting")
        ui.cards[3]:GetScript("OnClick")(ui.cards[3])
        assertEquals("crafting", state.ui.tab)
        assertEquals(3, ui.selected)
        state.ui.compact, state.ui.locked = true, true
        ui:ApplyMode()
        assertTrue(ui.lock:IsShown())
        assertFalse(ui.compactExpand:IsShown())
        assertFalse(ui.scene.units[1]:IsMouseEnabled())
        state.ui.compact, state.ui.locked = false, false
        ui:ApplyMode()
    end
)

test("Selecting equipment is free and upgrading uses the displayed quote", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    state.paused, state.essence, state.gold = true, 1000, 1000
    local hero = state.heroes[1]
    hero.gear[1] = W.Game.Item(state, 1, 1, 2)
    W.state = state
    local ui = W.UI
    ui.selected, ui.recruiting, ui.gearSlot, ui.bagFilter = 1, false, 2, 0
    ui:SetTab("party")
    local weapon
    for button in ui.panel._pool.button:EnumerateActive() do
        if button:IsShown() and button._pool and button._pool.text then
            for label in button._pool.text:EnumerateActive() do
                if label:GetText() == "Weapon" then
                    weapon = button
                end
            end
        end
    end
    assertNotNil(weapon)
    weapon:GetScript("OnClick")(weapon)
    assertEquals(1, ui.gearSlot)
    assertEquals(1, ui.bagFilter)
    assertEquals(1000, state.essence)
    local quote, power = W.Game.UpgradeCost(hero.gear[1]), W.Game.ItemPower(hero.gear[1], hero)
    local upgrade
    for button in ui.panel._pool.primary:EnumerateActive() do
        if button:IsShown() and button.text:GetText() == "Upgrade +2 power" then
            upgrade = button
        end
    end
    assertNotNil(upgrade)
    upgrade:GetScript("OnClick")(upgrade)
    assertEquals(1000 - quote.essence, state.essence)
    assertEquals(1000 - quote.gold, state.gold)
    assertEquals(power + 2, W.Game.ItemPower(hero.gear[1], hero))
end)

test("Full and compact Adventure bars share rank rewards without granting hero XP", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.UI:Refresh()
    W.Game.AdventureXP(state, 100.25, "test", "Activity")
    W.UI:Refresh()
    assertEquals(60, state.essence)
    assertEquals(0, state.heroes[1].xp)
    -- Check the authoritative endpoint after the bar's presentation animation.
    W.UI.adventureBar:StopAnimation()
    assertTrue(math.abs(W.UI.adventureBar.fill:GetValue() - 0.0025) < 0.000001)
    assertEquals(W.UI.adventureBar.label:GetText(), W.UI.adventureCompact.label:GetText())
    state.ui.compact = true
    W.UI:ApplyMode()
    assertTrue(W.UI.adventureCompact.frame:IsVisible())
    state.ui.locked = true
    W.UI:Layout()
    assertFalse(W.UI.adventureCompact.frame:IsMouseEnabled())
    state.ui.compact, state.ui.locked = false, false
    W.UI:ApplyMode()
end)

test("Every destination has a screenshot backdrop and missing assets fall back safely", function()
    local renderer = WoWIdle.UI.scene.scenery
    for _, zone in ipairs(WoWIdle.Content.zones) do
        renderer:SetZone(zone.id)
        assertTrue(renderer.supported)
        assertTrue(renderer.lastError == nil)
        assertNotNil(renderer.image:GetTexture())
    end
    renderer:SetZone("unknown-destination")
    assertFalse(renderer.supported)
    assertFalse(renderer.image:IsShown())
    renderer:SetZone(WoWIdle.state.zone)
end)

test(
    "Continent markers travel during combat and locked destinations preserve the encounter",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "WARRIOR")
        W.state = state
        W.UI.selected = 1
        W.Game.StartBattle(state)
        W.UI:SetTab("atlas")
        assertFalse(W.UI.scene.frame:IsShown())
        assertFalse(W.UI.cards[1]:IsShown())
        local maps = W.UI.atlas.maps
        local durotar, winterspring, count
        count = 0
        for _, map in ipairs(maps) do
            for id, pin in pairs(map.pins) do
                if pin:IsShown() then
                    count = count + 1
                end
                if id == "durotar" then
                    durotar = pin
                end
                if id == "winterspring" then
                    winterspring = pin
                end
            end
        end
        assertEquals(12, count)
        assertNotNil(durotar)
        assertNotNil(winterspring)
        local encounter = state.battle
        winterspring:GetScript("OnClick")(winterspring)
        assertEquals(encounter, state.battle)
        durotar:GetScript("OnClick")(durotar)
        assertEquals("durotar", state.zone)
        assertTrue(state.battle == nil)
        assertEquals(0, state.gold)
        W.UI:SetTab("adventure")
        assertFalse(W.UI.atlas.frame:IsShown())
    end
)

test("Clicking painted regions away from markers selects destinations at UI scale", function()
    local W = WoWIdle
    W.state = W.Game.New(W.Client.Now())
    W.Game.AddHero(W.state, "WARRIOR")
    W.UI:SetTab("atlas")
    local map = W.UI.atlas.maps[1]
    local original = GetCursorPosition
    local x, y = W.Client.ZonePosition("durotar", "kalimdor")
    local ok, message = pcall(function()
        GetCursorPosition = function()
            local scale = map:GetEffectiveScale()
            return (map:GetLeft() + (x + 0.018) * map:GetWidth()) * scale,
                (map:GetTop() - (y + 0.020) * map:GetHeight()) * scale
        end
        map:GetScript("OnMouseUp")(map, "RightButton")
        assertEquals("elwynn", W.state.zone)
        map:GetScript("OnMouseUp")(map, "LeftButton")
        assertEquals("durotar", W.state.zone)
    end)
    GetCursorPosition = original
    assertTrue(ok, message)
    W.UI:SetTab("adventure")
end)

test("Defeated models play death and damage text rises with a frame-rate fade", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.Game.StartBattle(state)
    W.UI:SetTab("adventure")
    local scene, animation = W.UI.scene, W.Client.AnimateModel
    local unit, playedDeath = scene.units[6], false
    unit.modelReady = true
    W.Client.AnimateModel = function(model, id)
        if model == unit.model and id == 1 then
            playedDeath = true
        end
    end
    local ok, message = pcall(function()
        state.battle.enemies[1].hp = 0
        scene:Refresh(state)
        assertTrue(playedDeath)
        assertTrue(unit.model:IsShown())
        assertFalse(unit.sigil:IsShown())
        state.battle = nil
        scene:Refresh(state)
        assertTrue(unit.model:IsShown())
        state.events = { { kind = "hit", target = 1, enemy = true, amount = 12 } }
        scene:Refresh(state)
        assertTrue(unit.floatAnimation:IsPlaying())
        assertEquals("-12", unit.floating:GetText())
        unit.floatAnimation:Stop()
        unit.floatAnimation:GetScript("OnFinished")(unit.floatAnimation)
        assertEquals(0, unit.floating:GetAlpha())
    end)
    W.Client.AnimateModel = animation
    assertTrue(ok, message)
end)

test("Minimap notices ignore snapshots and open the expanded adventure", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.UI.frame:Hide()
    W.OnLog(W.Game.Copy(state), "Snapshot event")
    assertTrue(state.ui.minimapNotice == nil)
    W.OnLog(state, "A destination unlocked.")
    assertTrue(W.Minimap.bubble:IsShown())
    assertEquals("A destination unlocked.", state.ui.minimapNotice)
    state.ui.compact, state.ui.locked, state.ui.tab = true, true, "party"
    W.Minimap.button:GetScript("OnClick")(W.Minimap.button, "LeftButton")
    assertTrue(W.UI.frame:IsShown())
    assertFalse(state.ui.compact)
    assertTrue(W.UI.expanded:IsShown())
    assertEquals("adventure", state.ui.tab)
    assertFalse(W.Minimap.bubble:IsShown())
    assertEquals("A destination unlocked.", W.UI.message)
    W.OnLog(state, "Already visible event")
    assertTrue(state.ui.minimapNotice == nil)
    state.ui.compact = true
    W.OnLog(state, "Train your companion.")
    assertEquals("Train your companion.", state.ui.minimapNotice)
    W.Minimap.Open()
    state.ui.locked = false
end)

test("Minimap launcher uses shared libraries and persists its display settings", function()
    local W = WoWIdle
    W.Initialize()
    local icons = LibStub("LibDBIcon-1.0")
    local button = icons:GetMinimapButton("WoWIdle")
    assertEquals(button, W.Minimap.button)
    assertEquals(W.Minimap.launcher, LibStub("LibDataBroker-1.1"):GetDataObjectByName("WoWIdle"))
    assertEquals("launcher", W.Minimap.launcher.type)
    W.Minimap.Create()
    assertEquals(button, W.Minimap.button)

    local saved = { minimapPos = 120, hide = true, lock = true }
    icons:Refresh("WoWIdle", saved)
    assertEquals(saved, button.db)
    assertFalse(button:IsShown())
    saved.hide = false
    icons:Refresh("WoWIdle", saved)
    assertTrue(button:IsShown())
    assertEquals(120, saved.minimapPos)
    icons:Refresh("WoWIdle", W.state.ui.minimap)
end)

test("Preferences migrate once and AceConfig updates state with immediate effects", function()
    local W = WoWIdle
    local previousDB, previousPreferences = WoWIdlePreferencesDB, W.preferences
    local state = W.Game.New(W.Client.Now())
    state.ui.compact = true
    state.ui.expandedGeometry = { w = 1200, h = 760, x = 20, y = 800 }
    state.ui.minimap = { minimapPos = 120, hide = false }
    state.settings.soundEnabled = false
    WoWIdlePreferencesDB = nil
    local ok, message = pcall(function()
        assertTrue(W.BindPreferences(state))
        assertTrue(state.ui.compact)
        assertEquals(120, state.ui.minimap.minimapPos)
        assertEquals(1200, state.ui.expandedGeometry.w)
        assertFalse(state.settings.soundEnabled)
        local later = W.Game.New(W.Client.Now())
        assertTrue(W.BindPreferences(later))
        assertTrue(later.ui.compact)
        assertFalse(later.settings.soundEnabled)
        assertEquals(later.ui, W.preferences.global.ui)
        local invalid = { global = { settings = "invalid" } }
        WoWIdlePreferencesDB = invalid
        assertFalse(W.BindPreferences(W.Game.New(0)))
        assertEquals(invalid, WoWIdlePreferencesDB)
    end)
    WoWIdlePreferencesDB, W.preferences = previousDB, previousPreferences
    assertTrue(ok, message)

    local options = W.settingsOptions
    local info = { "WoWIdle", "locked" }
    options.set(info, true)
    assertTrue(W.state.ui.locked)
    assertTrue(options.get(info))
    options.set(info, false)
    info[2] = "combatText"
    local animation = W.UI.scene.units[1].floatAnimation
    animation:Play()
    options.set(info, false)
    assertFalse(animation:IsPlaying())
    assertEquals(0, W.UI.scene.units[1].floating:GetAlpha())
    options.set(info, true)
end)

test("Ace lifecycle re-enables without duplicate timers, commands or reward delivery", function()
    local W = WoWIdle
    local root = W.Controller
    assertEquals(root, LibStub("AceAddon-3.0"):GetAddon("WoWIdle"))
    local commands = {}
    for command in LibStub("AceConsole-3.0"):IterateChatCommands() do
        commands[command] = true
    end
    assertTrue(commands.wowidle and commands.wi)
    local state = W.state
    local timers = LibStub("AceTimer-3.0").activeTimers
    local function timerCount()
        local count = 0
        for _, timer in pairs(timers) do
            if timer.object == root then
                count = count + 1
            end
        end
        return count
    end
    assertEquals(2, timerCount())
    root:Disable()
    assertFalse(W.UI.frame:IsShown())
    assertEquals(0, timerCount())
    local beforeDisabled = state.adventure.totalXP
    LibStub("AceEvent-3.0").events:Fire("QUEST_TURNED_IN", 987653)
    assertEquals(beforeDisabled, state.adventure.totalXP)
    root:Enable()
    assertEquals(2, timerCount())
    assertEquals(state, W.state)
    local before = state.adventure.totalXP
    LibStub("AceEvent-3.0").events:Fire("QUEST_TURNED_IN", 987654)
    assertEquals(before + W.Content.activityRewards.quest.xp, state.adventure.totalXP)
    LibStub("AceEvent-3.0").events:Fire("QUEST_TURNED_IN", 987654)
    assertEquals(before + W.Content.activityRewards.quest.xp, state.adventure.totalXP)
end)

test("AceDB shutdown saves gameplay before removing preference defaults", function()
    local W = WoWIdle
    local state = W.state
    state.events = { { kind = "test" } }
    state.lastTime = 0
    local before = W.Client.Now()
    W.preferences.callbacks:Fire("OnDatabaseShutdown", W.preferences)
    assertTrue(state.events == nil)
    assertTrue(state.lastTime >= before and state.lastTime <= W.Client.Now())
    assertEquals(true, state.settings.combatText)
end)

test("Talent icons preserve choices and scroll through expanded trees", function()
    local W = WoWIdle
    W.Initialize()
    W.state = W.Game.New(W.Client.Now())
    W.Game.AddHero(W.state, "WARRIOR")
    W.UI.selected = 1
    W.UI.frame:Show()
    W.UI:SetTab("talents")
    local trees = W.UI.talentTrees
    local tree = trees.trees[1]
    local node = tree.buttons.cleave
    node:GetScript("OnEnter")(node)
    assertTrue(GameTooltip:IsOwned(node))
    node:GetScript("OnClick")(node)
    assertTrue(W.state.heroes[1].talents.cleave)
    assertEquals("1/1", node.rank:GetText())
    node:GetScript("OnClick")(node)
    assertFalse(W.state.heroes[1].talents.cleave == true)
    assertEquals("0/1", node.rank:GetText())
    local talent = W.Content.talents[1]
    local row = talent.row
    talent.row = 20
    W.UI:Refresh()
    talent.row = row
    local _, maximum = tree.slider:GetMinMaxValues()
    assertTrue(maximum > 1000)
    tree.scroll:GetScript("OnMouseWheel")(tree.scroll, -100)
    assertEquals(maximum, tree.scroll:GetVerticalScroll())
    W.UI:SetTab("party")
    assertFalse(trees:IsShown())
    W.UI:SetTab("talents")
    assertTrue(trees == W.UI.talentTrees)
    assertTrue(node == tree.buttons.cleave)
    local _, restoredMaximum = tree.slider:GetMinMaxValues()
    assertEquals(restoredMaximum, tree.scroll:GetVerticalScroll())
end)

test("Adventure nameplates follow formations and enemies enter from the right", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    for _, id in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "ROGUE" }) do
        W.Game.AddHero(state, id)
    end
    W.state = state
    state.settings.combatText = false
    state.ui.compact, state.ui.locked = false, false
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    W.Game.StartBattle(state)
    W.UI:Refresh()
    local scene = W.UI.scene
    local front, ranged, enemy = scene.units[1], scene.units[2], scene.units[6]
    assertTrue(front.melee)
    assertFalse(ranged.melee)
    assertTrue(front.targetX > ranged.targetX)
    assertTrue(enemy.x > scene.frame:GetWidth())
    local start = enemy.x
    scene.lastAnimation = GetTime() - 0.05
    scene:Animate()
    assertTrue(enemy.x < start)
    assertTrue(enemy.x > enemy.targetX)
    assertTrue(enemy.moving)
    for _ = 1, 100 do
        scene.lastAnimation = GetTime() - 0.05
        scene:Animate()
    end
    assertTrue(math.abs(enemy.x - enemy.targetX) < 1)
    assertFalse(enemy.moving)
    assertTrue(front.x < enemy.x)
    local _, _, _, _, nameY = front.name:GetPoint()
    local _, _, _, _, healthY = front.hp:GetPoint()
    local _, _, _, _, modelY = front.viewport:GetPoint()
    assertTrue(nameY > healthY and healthY > modelY)
    local partyX = front.x
    state.battle = nil
    W.UI:Refresh()
    scene.lastAnimation = GetTime() - 0.05
    scene:Animate()
    assertTrue(front.travelling)
    assertEquals(partyX, front.x)
    W.Game.StartBattle(state)
    W.UI:Refresh()
    assertEquals(partyX, front.x)
    assertTrue(enemy.x > scene.frame:GetWidth())
    state.ui.compact = true
    W.UI:ApplyMode()
    assertTrue(enemy.name:IsShown())
    assertTrue(front.hp:IsShown())
end)

test("Talent trees change with class and keep class selections independent", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.Game.AddHero(state, "MAGE")
    W.state, W.UI.selected = state, 1
    W.UI.frame:Show()
    W.UI:SetTab("talents")
    local tree = W.UI.talentTrees.trees[1]
    local warrior = tree.buttons.warrior_1_4
    warrior:GetScript("OnClick")(warrior)
    W.UI.selected = 2
    W.UI:Refresh()
    assertEquals("Arcane", tree.title:GetText())
    assertFalse(warrior:IsShown())
    local mage = tree.buttons.mage_1_1
    assertTrue(mage:IsShown())
    assertEquals("Arcane Power", mage.label:GetText())
    mage:GetScript("OnClick")(mage)
    assertTrue(state.heroes[2].talents.mage_1_1)
    assertTrue(state.heroes[1].talents.warrior_1_4)
    assertFalse(state.heroes[2].talents.warrior_1_4 == true)
    W.UI.selected = 1
    W.UI:Refresh()
    assertEquals("Arms", tree.title:GetText())
    assertTrue(warrior:IsShown())
    assertFalse(mage:IsShown())
end)
