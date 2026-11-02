if not test then
    return
end

-- The simulator does not render/load particle M2s. Exercise the real load callback
-- with an explicit matching FileDataID rather than claiming asset rendering works.
local function finishEffectLoad(effect)
    local getter = effect.model.GetModelFileID
    effect.model.GetModelFileID = function()
        return effect.spec.fileID
    end
    local ok, message = pcall(effect.model:GetScript("OnModelLoaded"), effect.model)
    effect.model.GetModelFileID = getter
    assertTrue(ok, message)
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
test("Hero level-up effects play once and clear when hidden or expired", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.Game.AddHero(state, "MAGE")
    W.state = state
    W.Game.StartBattle(state)
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    local scene = W.UI.scene
    W.Game.Emit(state, "levelup", { target = 2 })
    scene:Refresh(state)
    assertTrue(scene.units[2].levelUpUntil ~= nil)
    assertTrue(scene.units[2].levelUp:IsShown())
    assertEquals(scene.units[1].levelUpUntil, nil)
    local effect = scene.units[2].levelUp
    scene.units[2].levelUpUntil = GetTime() - 1
    scene:Animate()
    assertFalse(effect:IsShown())
    scene:Refresh(state)
    assertEquals(scene.units[2].levelUpUntil, nil)
    W.Game.Emit(state, "levelup", { target = 2 })
    scene:Refresh(state)
    assertTrue(scene.units[2].levelUp == effect)
    W.UI.frame:Hide()
    assertEquals(scene.units[2].levelUpUntil, nil)
    W.UI.frame:Show()
    scene:Refresh(state)
    assertFalse(effect:IsShown())
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
    local quote, power = W.Game.UpgradeCost(hero.gear[1]), W.Game.ItemPower(hero.gear[1], hero, 1)
    local upgrade
    for button in ui.panel._pool.primary:EnumerateActive() do
        if button:IsShown() and button.text:GetText() == "Upgrade +10% stats" then
            upgrade = button
        end
    end
    assertNotNil(upgrade)
    upgrade:GetScript("OnClick")(upgrade)
    assertEquals(1000 - quote.essence, state.essence)
    assertEquals(1000 - quote.gold, state.gold)
    assertEquals(power, W.Game.ItemPower(hero.gear[1], hero))
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
    "Continent regions travel during combat and locked destinations preserve the encounter",
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
        local map = maps[1]
        local original = GetCursorPosition
        local function click(zoneID)
            local x, y = W.Client.ZonePosition(zoneID, map.id)
            GetCursorPosition = function()
                local scale = map:GetEffectiveScale()
                return (map:GetLeft() + x * map:GetWidth()) * scale,
                    (map:GetTop() - y * map:GetHeight()) * scale
            end
            map:GetScript("OnMouseUp")(map, "LeftButton")
        end
        local encounter = state.battle
        local ok, message = pcall(function()
            click("winterspring")
            assertEquals(encounter, state.battle)
            assertTrue(W.UI.atlas.frame:IsShown())
            click("durotar")
            assertFalse(W.UI.atlas.frame:IsShown())
            assertTrue(W.UI.scene.frame:IsShown())
        end)
        GetCursorPosition = original
        assertTrue(ok, message)
        assertEquals("durotar", state.zone)
        assertTrue(state.battle == nil)
        assertEquals(0, state.gold)
        W.UI:SetTab("adventure")
        assertFalse(W.UI.atlas.frame:IsShown())
    end
)

test("Only land is gray while sea, parchment and accessible regions retain color", function()
    local W = WoWIdle
    W.state = W.Game.New(W.Client.Now())
    W.Game.AddHero(W.state, "WARRIOR")
    W.UI:SetTab("atlas")
    for _, map in ipairs(W.UI.atlas.maps) do
        assertTrue(#map.tiles > 0)
        for _, tile in ipairs(map.tiles) do
            assertFalse(tile:IsDesaturated())
        end
        assertNotNil(map.grayRegion)
        assertTrue(#map.grayRegion.tiles > 0)
        assertTrue(#map.grayRegion.tiles < #map.tiles)
        for _, tile in ipairs(map.grayRegion.tiles) do
            assertTrue(tile:IsDesaturated())
            assertEquals(1, tile:GetNumMaskTextures())
        end
    end
    local map = W.UI.atlas.maps[1]
    assertTrue(map.colorRegions.winterspring == nil)
    local starting = map.colorRegions.durotar
    assertNotNil(starting)
    for _, tile in ipairs(starting.tiles) do
        assertTrue(tile:IsShown())
        assertFalse(tile:IsDesaturated())
        assertEquals(1, tile:GetNumMaskTextures())
    end
    W.state.runBest = 100
    W.UI:Refresh()
    local unlocked = map.colorRegions.winterspring
    assertNotNil(unlocked)
    assertTrue(unlocked.tiles[1]:IsShown())
    W.state.runBest = 1
    W.UI:Refresh()
    assertFalse(unlocked.tiles[1]:IsShown())
    assertTrue(starting.tiles[1]:IsShown())
    W.UI:SetTab("adventure")
end)

test("Hovering and clicking painted regions uses tooltips and travel at UI scale", function()
    local W = WoWIdle
    W.state = W.Game.New(W.Client.Now())
    W.Game.AddHero(W.state, "WARRIOR")
    W.UI:SetTab("atlas")
    local map = W.UI.atlas.maps[1]
    local original, mouseOver = GetCursorPosition, map.IsMouseOver
    local x, y = W.Client.ZonePosition("durotar", "kalimdor")
    local ok, message = pcall(function()
        GetCursorPosition = function()
            local scale = map:GetEffectiveScale()
            return (map:GetLeft() + (x + 0.018) * map:GetWidth()) * scale,
                (map:GetTop() - (y + 0.020) * map:GetHeight()) * scale
        end
        map.IsMouseOver = function()
            return true
        end
        map:GetScript("OnUpdate")(map, 0.05)
        assertEquals("durotar", map.hovered.id)
        assertTrue(GameTooltip:IsOwned(map))
        assertTrue(GameTooltip:IsShown())
        map:GetScript("OnLeave")(map)
        assertTrue(map.hovered == nil)
        assertFalse(GameTooltip:IsShown())
        map:GetScript("OnUpdate")(map, 0.05)
        assertTrue(GameTooltip:IsShown())
        map:GetScript("OnMouseUp")(map, "RightButton")
        assertEquals("elwynn", W.state.zone)
        map:GetScript("OnMouseUp")(map, "LeftButton")
        assertEquals("durotar", W.state.zone)
        assertFalse(W.UI.atlas.frame:IsShown())
        assertTrue(W.UI.scene.frame:IsShown())
        assertFalse(GameTooltip:IsShown())
    end)
    GetCursorPosition, map.IsMouseOver = original, mouseOver
    assertTrue(ok, message)
    W.UI:SetTab("adventure")
    assertFalse(GameTooltip:IsShown())
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

test("Adventure models follow combat positions with roomy transparent viewports", function()
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
    for _, opponent in ipairs(state.battle.enemies) do
        opponent.hp, opponent.maxHP = 10000, 10000
    end
    local scene = W.UI.scene
    local front, ranged, enemy = scene.units[1], scene.units[2], scene.units[6]
    assertTrue(front.melee)
    assertFalse(ranged.melee)
    assertTrue(enemy.x > scene.frame:GetWidth())
    local start = enemy.x
    for _ = 1, 8 do
        W.Game.Step(state, 0.25)
        W.UI:Refresh()
        for _ = 1, 6 do
            scene.lastAnimation = GetTime() - 0.05
            scene:Animate()
        end
    end
    assertTrue(enemy.x < start)
    -- The spring deliberately trails moving targets; it settles without snapping.
    for _ = 1, 30 do
        scene.lastAnimation = GetTime() - 0.05
        scene:Animate()
    end
    assertEquals(state.battle.enemies[1], enemy.combatant)
    assertTrue(math.abs(enemy.x - enemy.combatant.x) < 1)
    assertEquals(enemy.combatant.targetID, enemy.targetID)
    assertTrue(front.x < enemy.x)
    assertTrue(enemy.viewport:GetWidth() > enemy:GetWidth() * 2)
    assertTrue(enemy.viewport:GetHeight() > 178)
    assertFalse(enemy.viewport:DoesClipChildren())
    local _, _, _, _, friendlyGround = front.viewport:GetPoint()
    local _, _, _, _, enemyGround = enemy.viewport:GetPoint()
    assertEquals(0, friendlyGround)
    assertEquals(W.ModelAssets.creatureGroundOffset, enemyGround)
    enemy.actionAt, enemy.visualOffset = GetTime(), nil
    scene:Animate()
    local _, _, _, _, actionGround = enemy.viewport:GetPoint()
    assertEquals(enemyGround, actionGround)
    for i, unit in ipairs(scene.plateOrder) do
        local _, _, _, x, y = unit.plate:GetPoint()
        assertTrue(x >= 0 and x + unit.plate:GetWidth() <= 1284)
        for j = 1, i - 1 do
            local other = scene.plateOrder[j]
            local _, _, _, otherX, otherY = other.plate:GetPoint()
            assertTrue(math.abs(y - otherY) >= 10 or math.abs(x - otherX) >= 124)
        end
    end
    local _, _, _, _, nameY = front.name:GetPoint()
    local _, _, _, _, healthY = front.hp:GetPoint()
    assertTrue(nameY > healthY)
    local partyX = front.x
    state.battle = nil
    W.UI:Refresh()
    scene.lastAnimation = GetTime() - 0.05
    scene:Animate()
    assertTrue(front.travelling)
    assertTrue(front.x < partyX)
    state.ui.compact = true
    W.UI:ApplyMode()
    assertTrue(enemy.name:IsShown())
    assertTrue(front.hp:IsShown())
end)

test(
    "Model bounds separate opposing bodies and their plates without changing combat coordinates",
    function()
        local scene = WoWIdle.Scene.Create(UIParent)
        for _, unit in ipairs(scene.units) do
            unit:Hide()
        end
        local hero, enemy = scene.units[1], scene.units[6]
        hero.x, hero.y, enemy.x, enemy.y = 480, 110, 580, 110
        hero.model.spacingRadius, enemy.model.spacingRadius = 120, 150
        hero:Show()
        enemy:Show()
        scene:PlaceModels()
        assertTrue(enemy.renderX - hero.renderX >= 298)
        assertEquals(480, hero.x)
        assertEquals(580, enemy.x)
        local _, _, _, x = hero:GetPoint()
        assertEquals(hero.renderX, x)
        scene:PlaceNameplates()
        local _, _, _, plateX = hero.plate:GetPoint()
        assertEquals(hero.renderX, plateX)
        local largeGap = enemy.renderX - hero.renderX
        enemy.model.spacingRadius = 60
        scene:PlaceModels(1)
        assertTrue(enemy.renderX - hero.renderX < largeGap)
        assertTrue(enemy.renderX - hero.renderX >= 208)
        scene.travelling = true
        scene:PlaceModels()
        assertEquals(hero.x, hero.renderX)
        assertEquals(enemy.x, enemy.renderX)
        scene.frame:Hide()
    end
)

test("Player and enemy nameplates follow their displayed models vertically", function()
    local scene = WoWIdle.Scene.Create(UIParent)
    for _, unit in ipairs(scene.units) do
        unit:Hide()
    end
    for _, index in ipairs({ 1, 5, 6, 8 }) do
        local unit = scene.units[index]
        unit.x, unit.y = 600, 110
        unit:Show()
        scene:PlaceNameplates()
        local _, _, _, x, y = unit.plate:GetPoint()
        assertEquals(600, x)
        assertEquals(-88, y)
        unit.y = 130
        scene:PlaceNameplates()
        local _, _, _, movedX, movedY = unit.plate:GetPoint()
        assertEquals(x, movedX)
        assertEquals(-102, movedY)
        unit.y = 95
        scene:PlaceNameplates()
        local _, _, _, _, raisedY = unit.plate:GetPoint()
        assertEquals(-88, raisedY)
        unit:Hide()
    end
    -- Crowded plates stay horizontally attached and use separate heights in every layout.
    for _, compact in ipairs({ false, true }) do
        scene:Layout(compact, false)
        for i, unit in ipairs(scene.units) do
            unit.x, unit.y = 500 + i * 10, 96 + i * 4
            unit:Show()
        end
        scene:PlaceNameplates()
        for i, unit in ipairs(scene.plateOrder) do
            local _, _, _, x, y = unit.plate:GetPoint()
            assertEquals(unit.x, x)
            assertTrue(x >= 8 and x + 132 <= 1284)
            for j = 1, i - 1 do
                local other = scene.plateOrder[j]
                assertTrue(math.abs(x - other.plateX) >= 124 or math.abs(-y - other.plateY) >= 10)
            end
        end
    end
    scene.frame:Hide()
end)

test("Nameplates only change height when health bars overlap", function()
    local scene = WoWIdle.Scene.Create(UIParent)
    for _, unit in ipairs(scene.units) do
        unit:Hide()
    end
    local first, second = scene.units[1], scene.units[2]
    first.x, first.y = 400, 140
    first:Show()
    second:Show()
    for _, gap in ipairs({ 124, 130, 139 }) do
        second.x, second.y = first.x + gap, first.y
        scene:PlaceNameplates()
        assertEquals(112, first.plateY)
        assertEquals(112, second.plateY)
    end
    second.x = first.x + 123
    scene:PlaceNameplates()
    assertEquals(34, math.abs(first.plateY - second.plateY))
    second.y = first.y + first.hp:GetHeight()
    scene:PlaceNameplates()
    assertEquals(112, first.plateY)
    assertEquals(122, second.plateY)
    scene.frame:Hide()
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

test("Class effects follow recipients, stay bounded and clear across scene transitions", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    for _, class in ipairs({ "MAGE", "HUNTER", "PRIEST" }) do
        W.Game.AddHero(state, class)
    end
    W.state = state
    W.Game.StartBattle(state)
    W.UI:SetTab("adventure")
    local scene = W.UI.scene
    scene:Refresh(state)
    scene.effects:Clear()
    state.settings.combatText = false
    state.events = {
        { kind = "hit", source = 1, target = 1, enemy = true, amount = 10 },
        { kind = "hit", source = 2, target = 2, enemy = true, amount = 10 },
        { kind = "heal", source = 3, target = 1, amount = 10 },
    }
    scene:Refresh(state)
    local pool = scene.effects.pool
    assertEquals("bolt", pool[1].kind)
    assertEquals("arrow", pool[2].kind)
    assertEquals("shield", pool[3].kind)
    assertEquals(scene.units[1], pool[3].target)
    for _, effect in ipairs(pool) do
        if effect.active then
            finishEffectLoad(effect)
            effect.started = GetTime() - effect.duration * 0.5
        end
    end
    scene.effects:Animate(GetTime())
    assertTrue(pool[3].frame:GetAlpha() > 0.9)
    for _ = 1, 60 do
        scene.effects:Play(scene.units[1], scene.units[6], "bolt", "MAGE")
    end
    assertEquals(32, #pool)
    scene.effects:Animate(GetTime() + 2)
    for _, effect in ipairs(pool) do
        assertFalse(effect.active)
        assertFalse(effect.frame:IsShown())
    end
    scene.effects:Play(scene.units[3], scene.units[1], "shield", "PRIEST")
    assertEquals(32, #pool)
    scene:Layout(true, false)
    assertFalse(pool[1].active)
    state.settings.combatText = true
end)

test("Hunter poses fall back without requiring bow animations on companion models", function()
    local W = WoWIdle
    assertEquals(47, W.Client.AttackAnimation("HUNTER", false))
    assertEquals(53, W.Client.AttackAnimation("HUNTER", false, "heal"))
    assertEquals(16, W.Client.AttackAnimation("WARRIOR", true))
    local played
    local model = {
        HasAnimation = function(_, id)
            return id == 53
        end,
        SetAnimation = function(_, id)
            played = id
        end,
    }
    assertTrue(W.Client.AnimateModel(model, 46))
    assertEquals(53, played)
end)

test(
    "Movement keeps velocity across simulation ticks and converges at different frame rates",
    function()
        local move = WoWIdle.Scene.MoveUnit
        local slow = { x = 0, y = 100, targetX = 80, targetY = 110 }
        local fast = { x = 0, y = 100, targetX = 80, targetY = 110 }
        for _ = 1, 15 do
            move(slow, 1 / 60)
        end
        for _ = 1, 30 do
            move(fast, 1 / 120)
        end
        assertTrue(slow.x > 0 and slow.x < 80)
        assertTrue(slow.velocityX > 0)
        assertTrue(math.abs(slow.x - fast.x) < 0.0001)
        assertTrue(math.abs(slow.velocityX - fast.velocityX) < 0.0001)
        local x, velocity = slow.x, slow.velocityX
        slow.targetX = 160
        move(slow, 0)
        assertEquals(x, slow.x)
        assertEquals(velocity, slow.velocityX)
        move(slow, 1 / 120)
        assertTrue(slow.x > x and slow.x - x < 5)
        assertTrue(slow.velocityX > 0)
        for _ = 1, 240 do
            move(slow, 1 / 120)
            assertTrue(slow.x <= 160)
        end
        assertTrue(math.abs(slow.x - 160) < 0.01)
        assertTrue(math.abs(slow.y - 110) < 0.01)
        x = slow.x
        move(slow, 0)
        assertEquals(x, slow.x)
    end
)

test("Combat effects reuse projectiles for impacts without level-up flashes on victory", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    for _, class in ipairs({ "WARRIOR", "SHAMAN", "DRUID", "WARLOCK" }) do
        W.Game.AddHero(state, class)
    end
    W.state = state
    W.Game.StartBattle(state)
    W.UI:SetTab("adventure")
    local scene = W.UI.scene
    scene:Refresh(state)
    local effects = scene.effects
    effects:Clear()
    local kinds = { "slash", "lightning", "leaf", "shadow" }
    for i, kind in ipairs(kinds) do
        effects:Event(scene.units, state, { kind = "hit", source = i, target = 1, enemy = true })
        assertEquals(kind, effects.pool[i].kind)
    end
    local leaf = effects.pool[3]
    finishEffectLoad(leaf)
    leaf.started = GetTime() - leaf.duration - 0.1
    local count = #effects.pool
    effects:Animate(GetTime())
    assertEquals("impact", leaf.kind)
    assertTrue(leaf.active)
    assertEquals(count, #effects.pool)
    finishEffectLoad(leaf)
    effects:Animate(GetTime() + 3)
    assertFalse(leaf.active)
    effects:Clear()
    scene.units[1].dead = true
    effects:Event(scene.units, state, { kind = "victory" })
    effects:Event(scene.units, state, { kind = "loot" })
    local active = 0
    for _, effect in ipairs(effects.pool) do
        if effect.active then
            active = active + 1
            assertEquals("sparkle", effect.kind)
            assertTrue(effect.target ~= scene.units[1])
        end
    end
    assertEquals(0, active)
    state.events = { { kind = "cast", source = 2, action = "special" } }
    scene:Refresh(state)
    local burst
    for _, effect in ipairs(effects.pool) do
        burst = burst or (effect.active and effect.kind == "burst")
    end
    assertTrue(burst)
    effects:Clear()
end)

test(
    "Model reactions leave encounter coordinates alone and victory does not trigger level-up",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "WARRIOR")
        W.state = state
        W.Game.StartBattle(state)
        W.UI:SetTab("adventure")
        local scene = W.UI.scene
        scene:Refresh(state)
        local unit = scene.units[1]
        unit.x, unit.y = unit.combatant.x, unit.combatant.y
        unit.velocityX, unit.velocityY = 0, 0
        unit.modelReady = true
        unit.appeared = GetTime() - 0.175
        state.events = { { kind = "hit", source = 1, target = 1, amount = 1, enemy = false } }
        scene:Refresh(state)
        unit.recoilAt, unit.actionAt = GetTime() - 0.15, nil
        local x, y = unit.combatant.x, unit.combatant.y
        scene:Animate()
        assertTrue(unit.visualOffset < -5)
        assertEquals(x, unit.x)
        assertEquals(y, unit.y)
        assertEquals(x, unit.combatant.x)
        assertTrue(unit.model:GetAlpha() > 0.4 and unit.model:GetAlpha() < 0.6)
        state.events = { { kind = "victory" } }
        scene:Refresh(state)
        assertEquals(nil, unit.celebrateUntil)
        assertEquals(nil, unit.levelUpUntil)
        scene:Animate()
        assertEquals(nil, unit.celebrateUntil)
        assertEquals(nil, unit.pendingAnimation)
        assertEquals(nil, unit.animTime)
        unit.combatant.hp = 0
        scene:Refresh(state)
        unit.defeatedAt = GetTime() - 2
        unit.appeared = GetTime() - 3
        scene:Animate()
        assertEquals(1, unit.model:GetAlpha())
        assertFalse(unit.model:IsShown())
        assertEquals(0, unit.visualOffset)
    end
)

test(
    "Hunter shooting completion restores combat stance and the watchdog covers missing callbacks",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "HUNTER")
        W.state = state
        W.Game.StartBattle(state)
        W.UI:SetTab("adventure")
        local scene = W.UI.scene
        scene:Refresh(state)
        local unit = scene.units[1]
        unit.x, unit.y = unit.combatant.x, unit.combatant.y
        unit.velocityX, unit.velocityY = 0, 0
        unit.modelReady, unit.moving, unit.travelling = true, false, false
        local animate, played = W.Client.AnimateModel, {}
        W.Client.AnimateModel = function(model, animation)
            if model == unit.model then
                played[#played + 1] = animation
            end
            return true
        end
        local ok, message = pcall(function()
            assertEquals(29, W.Client.ReadyAnimation("HUNTER", false))
            assertEquals(25, W.Client.ReadyAnimation("WARRIOR", true))
            assertEquals(51, W.Client.ReadyAnimation("MAGE", false))
            unit.pendingAnimation = W.Client.AttackAnimation("HUNTER", false)
            scene:Animate()
            assertEquals(47, played[#played])
            assertNotNil(unit.animTime)
            W.Scene.FinishAnimation(unit)
            assertEquals(29, played[#played])
            assertEquals(nil, unit.animTime)
            local count = #played
            W.Scene.FinishAnimation(unit)
            assertEquals(count, #played)
            unit.pendingAnimation = 47
            scene:Animate()
            unit.animTime = GetTime() - 0.7
            scene:Animate()
            assertEquals(29, played[#played])
            assertEquals(nil, unit.animTime)
            state.battle = nil
            scene:Refresh(state)
            unit.moving, unit.travelling = false, false
            unit.animTime = GetTime()
            W.Scene.FinishAnimation(unit)
            assertEquals(0, played[#played])
        end)
        W.Client.AnimateModel = animate
        assertTrue(ok, message)
    end
)

test("Native spell models wait for matching assets and reject late recycled callbacks", function()
    local W = WoWIdle
    local scene = W.UI.scene
    W.UI:SetTab("adventure")
    scene.effects:Clear()
    local source, target = scene.units[1], scene.units[6]
    source:Show()
    target:Show()
    scene.effects:Play(source, target, "shield", "PRIEST")
    local effect = scene.effects.pool[1]
    assertEquals(166360, effect.spec.fileID)
    assertEquals(1, effect.model:GetAlpha())
    assertEquals(1, effect.model:GetWidth())
    finishEffectLoad(effect)
    assertTrue(effect.loaded)
    assertEquals(1, effect.model:GetAlpha())
    assertEquals(1599028, W.Client.SpellEffectSpec("impact", "MAGE").fileID)
    scene.effects:Clear()
    effect.model:GetScript("OnModelLoaded")(effect.model)
    assertFalse(effect.active)
    assertFalse(effect.loaded)
    scene.effects:Play(source, target, "bolt", "MAGE")
    assertFalse(effect.loaded)
    scene.effects:Animate(GetTime() + 2)
    assertFalse(effect.active)
    assertFalse(effect.frame:IsShown())
    local flavor = W.Client.flavor
    W.Client.flavor = "forever"
    assertEquals(nil, W.Client.SpellEffectSpec("shield"))
    W.Client.flavor = flavor
end)

test(
    "Cached native missiles complete loading without a callback and callbacks do not rewind flight",
    function()
        local W = WoWIdle
        local scene = W.UI.scene
        W.UI:SetTab("adventure")
        local effects = scene.effects
        effects:Clear()
        local source, target = scene.units[1], scene.units[6]
        source:Show()
        target:Show()
        effects:Play(source, target, "bolt", "MAGE")
        local effect = effects.pool[1]
        local getter = effect.model.GetModelFileID
        effect.model.GetModelFileID = function()
            return effect.spec.fileID
        end
        local ok, message = pcall(function()
            assertEquals(1, effect.model:GetWidth())
            assertTrue(effect.frame:IsShown())
            effects:Animate(GetTime())
            assertTrue(effect.loaded)
            assertEquals(effect.spec.width, effect.model:GetWidth())
            effect.started = GetTime() - 0.2
            local started = effect.started
            effect.model:GetScript("OnModelLoaded")(effect.model)
            assertEquals(started, effect.started)
            effects:Animate(GetTime())
            local _, _, _, x = effect.frame:GetPoint()
            assertTrue(math.abs(x - effect.x) > 0.01)
        end)
        effect.model.GetModelFileID = getter
        effects:Clear()
        assertTrue(ok, message)
    end
)

test("Render motion advances each OnUpdate frame even when GetTime is unchanged", function()
    local W = WoWIdle
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.Game.StartBattle(state)
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    local scene = W.UI.scene
    scene:Refresh(state)
    local unit = scene.units[1]
    unit.x, unit.y = unit.combatant.x, unit.combatant.y
    unit.velocityX, unit.velocityY = 0, 0
    local clock, fixed = GetTime, GetTime()
    GetTime = function()
        return fixed
    end
    local ok, message = pcall(function()
        -- Establish the initial sample, then advance the fixed-step simulation
        -- only once. All remaining motion must happen on individual render frames.
        scene:Animate(1 / 60, 0)
        state.battle.elapsed = 0.25
        unit.combatant.x = unit.combatant.x + 80
        for frame = 1, 14 do
            local x = unit.x
            scene:Animate(1 / 60, frame / 15)
            assertTrue(unit.x > x)
            assertTrue(unit.x - x < 8)
            local _, _, _, anchoredX = unit:GetPoint()
            assertTrue(math.abs(anchoredX - unit.x) < 0.001)
        end
        -- The next stationary tick must not replay the previous 80-pixel step.
        state.battle.elapsed = 0.5
        scene:Animate(1 / 60, 0)
        assertEquals(unit.combatant.x, unit.previousX)
        assertEquals(unit.combatant.x, unit.targetX)
        scene.travelling = true
        scene:Animate(1 / 60, 0.9)
        scene:Animate(1 / 60, 0)
        assertEquals(unit.combatant.x, unit.targetX)
    end)
    GetTime = clock
    assertTrue(ok, message)
end)

test(
    "The live controller supplies render elapsed and the fixed-step interpolation fraction",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "WARRIOR")
        W.state = state
        W.Game.StartBattle(state)
        W.UI.frame:Show()
        W.UI:SetTab("adventure")
        local scene, animate = W.UI.scene, W.UI.scene.Animate
        local calls = 0
        scene.Animate = function(_, elapsed, fraction)
            assertEquals(1 / 120, elapsed)
            assertTrue(fraction >= 0 and fraction < 1)
            calls = calls + 1
        end
        local ok, message = pcall(function()
            for _ = 1, 60 do
                W.Controller.Update(nil, 1 / 120)
            end
            assertEquals(60, calls)
        end)
        scene.Animate = animate
        assertTrue(ok, message)
    end
)

test(
    "Level-up models enable their native particles and glow alongside the animated mesh",
    function()
        local W = WoWIdle
        local spec = W.Client.SpellEffectSpec("levelup")
        local particles, glow, loaded
        local model = {
            ClearModel = function() end,
            SetParticlesEnabled = function(_, enabled)
                particles = enabled
            end,
            SetGlow = function(_, value)
                glow = value
            end,
            SetModel = function(_, fileID)
                assertTrue(particles)
                loaded = fileID
            end,
            SetCustomCamera = function(_, index)
                assertEquals(1, index)
            end,
            SetCameraPosition = function(_, x, y, z)
                assertEquals(0, x)
                assertTrue(y < 0)
                assertEquals(0.75, z)
            end,
            SetCameraTarget = function() end,
            SetFacing = function() end,
            SetAnimation = function() end,
        }
        assertTrue(W.Client.LoadSpellEffect(model, spec))
        assertEquals(166464, loaded)
        assertTrue(W.Client.FrameSpellEffect(model, spec))
        assertTrue(particles)
        assertEquals(1, glow)
        assertTrue(W.Client.FrameSpellEffect(model, W.Client.SpellEffectSpec("heal")))
        assertEquals(0, glow)
    end
)

test(
    "The party slides into formation together and keeps a synchronized run through travel",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        for _, class in ipairs({ "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "MAGE" }) do
            W.Game.AddHero(state, class)
        end
        W.state = state
        W.Game.StartBattle(state)
        W.UI.frame:Show()
        W.UI:SetTab("adventure")
        local scene = W.UI.scene
        scene:Refresh(state)
        for i = 1, 5 do
            local unit = scene.units[i]
            unit.modelReady = true
            unit.x = i == 1 and 640 or i == 3 and 590 or unit.homeX
            unit.y = unit.homeY
            unit.combatant.x = unit.x
            unit.combatant.y = unit.y
        end
        local battle = state.battle
        local animate, runs = W.Client.AnimateModel, {}
        W.Client.AnimateModel = function(model, animation)
            if animation == 5 then
                runs[model] = (runs[model] or 0) + 1
            end
            return true
        end
        local ok, message = pcall(function()
            state.battle = nil
            state.events = { { kind = "victory" }, { kind = "loot" } }
            scene:Refresh(state)
            assertNotNil(scene.regroup)
            local front, rogue = scene.units[1], scene.units[3]
            scene:Animate(0.1, 0)
            assertTrue(front.x < 640 and front.x > front.homeX)
            assertTrue(rogue.x < 590 and rogue.x > rogue.homeX)
            local first = (640 - front.x) / (640 - front.homeX)
            local third = (590 - rogue.x) / (590 - rogue.homeX)
            assertTrue(math.abs(first - third) < 0.0001)
            for _ = 1, 60 do
                scene:Animate(1 / 60, 0)
            end
            assertEquals(nil, scene.regroup)
            for i = 1, 5 do
                local unit = scene.units[i]
                assertEquals(unit.homeX, unit.x)
                assertEquals(unit.homeY, unit.y)
                assertEquals(1, runs[unit.model])
                assertTrue(unit.travelling)
                assertEquals(nil, unit.levelUpUntil)
                assertEquals(nil, unit.pendingAnimation)
            end
            -- Presentation must not rewrite the finished battle or start another one.
            assertEquals(640, battle.heroes[1].x)
            assertEquals(590, battle.heroes[3].x)
            assertEquals(nil, state.battle)
            state.events = { { kind = "levelup", target = 2 } }
            scene:Refresh(state)
            assertNotNil(scene.units[2].levelUpUntil)
            assertEquals(nil, scene.units[1].levelUpUntil)
            W.Game.StartBattle(state)
            scene:Refresh(state)
            assertEquals(nil, scene.regroup)
            assertTrue(scene.units[1].inCombat)
            assertFalse(scene.units[1].travelling)
        end)
        W.Client.AnimateModel = animate
        assertTrue(ok, message)
    end
)

test(
    "Dead friendly and enemy models stay opaque before being hidden and do not reappear on refresh",
    function()
        local W = WoWIdle
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "WARRIOR")
        W.Game.AddHero(state, "MAGE")
        W.state = state
        W.Game.StartBattle(state)
        W.UI.frame:Show()
        W.UI:SetTab("adventure")
        local scene = W.UI.scene
        scene:Refresh(state)
        for _, index in ipairs({ 1, 6 }) do
            local unit = scene.units[index]
            unit.modelReady = true
            unit.combatant.hp = 0
            scene:Refresh(state)
            unit.defeatedAt = GetTime() - 0.5
            scene:Animate(1 / 60)
            assertTrue(unit.model:IsShown())
            assertEquals(1, unit.model:GetAlpha())
            unit.defeatedAt = GetTime() - 1.6
            scene:Animate(1 / 60)
            assertFalse(unit.model:IsShown())
            scene:Refresh(state)
            assertFalse(unit.model:IsShown())
            unit.combatant.hp = unit.combatant.maxHP
            scene:Refresh(state)
            assertTrue(unit.model:IsShown())
            assertFalse(unit.dead)
        end
    end
)
