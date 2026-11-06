if not test then
    return
end
local function fixture()
    local W = AFKraft
    W.Initialize()
    W.Notifications.Clear()
    W.catchup = nil
    local s = W.Game.New(1000)
    W.Game.AddHero(s, "WARRIOR")
    s.heroes[1].level = 60
    s.guide.dismissed = true
    W.state = s
    W.UI.frame:Show()
    W.UI:SetTab("chests")
    return W, s, W.UI
end
local function drop(W, state, count, quality)
    for _ = 1, count do
        local item = W.Game.Item(state, 1, 1, 2, false, W.Content.itemByID[25])
        item.quality, item.stats = quality or 2, { strength = 10 }
        W.Game.StoreChest(state, item)
    end
    W.UI:Refresh()
end

test("Chests panel opens batches, skips presentation and equips revealed upgrades", function()
    local W, state, ui = fixture()
    drop(W, state, 12, 3)
    assertTrue(ui.chestFrame:IsVisible())
    assertEquals("12", ui.tabs.chests.notice:GetText())
    ui.chestControls[10]:GetScript("OnClick")()
    assertEquals(2, W.Game.ChestCount(state))
    assertEquals(10, ui.chestOpening.count)
    assertNotNil(ui.chestOpening)
    assertEquals(0, #ui.chestResultButtons)
    assertNotNil(ui.chestSkip)
    ui.chestSkip:GetScript("OnClick")()
    assertEquals(nil, ui.chestOpening)
    assertEquals(1, #ui.chestResultButtons)
    local uid = state.inventory[1].uid
    table.insert(state.inventory, 1, W.Game.Item(state, 2, 1, 2))
    ui.chestResultButtons[1]:GetScript("OnClick")()
    assertNotNil(state.heroes[1].gear[1])
    assertTrue(state.heroes[1].gear[1].uid ~= uid) -- One copy equipped from a stack.
    assertEquals(9, state.inventory[2].count)
    assertEquals(2, W.Game.ChestCount(state))
end)

test("Instant reveal commits once and closing mid-animation never loses rewards", function()
    local W, state, ui = fixture()
    drop(W, state, 3, 4)
    state.settings.instantChestReveal = true
    ui.chestControls[1]:GetScript("OnClick")()
    assertEquals(nil, ui.chestOpening)
    assertEquals(1, #state.inventory)
    state.settings.instantChestReveal = false
    ui.chestControls[1]:GetScript("OnClick")()
    assertNotNil(ui.chestOpening)
    ui.frame:Hide()
    assertEquals(nil, ui.chestOpening)
    assertEquals(nil, ui.chestReport)
    assertEquals(0, ui.chestPage)
    assertEquals(2, state.inventory[1].count)
    W.state = assert(W.Game.Load(W.Game.Copy(state), 1100))
    ui.frame:Show()
    ui:SetTab("chests")
    assertEquals(nil, ui.chestReport)
    assertEquals(1, W.Game.ChestCount(W.state))
    assertEquals(2, W.state.inventory[1].count)
end)

test("Reveal duration and effects scale with the actual highest reward quality", function()
    for quality = 1, 4 do
        local W, state, ui = fixture()
        drop(W, state, 1, quality)
        ui.chestControls[1]:GetScript("OnClick")()
        local update = ui.chestScene:GetScript("OnUpdate")
        update(ui.chestScene, 0.5)
        assertNotNil(ui.chestOpening)
        assertTrue(ui.chestScene.glow:GetAlpha() > 0)
        assertEquals(quality, ui.chestOpening.quality)
        update(ui.chestScene, 1.2)
        assertEquals(quality == 1, ui.chestOpening == nil)
        if ui.chestOpening then
            update(ui.chestScene, 2)
        end
        assertEquals(nil, ui.chestOpening)
        assertEquals(0, W.Game.ChestCount(state))
    end
end)

test("Chest notifications group earned drops and navigate from compact mode", function()
    local W, state, ui = fixture()
    ui.frame:Hide()
    drop(W, state, 10)
    W.Notifications.Flush()
    assertEquals("chest", W.Notifications.current.kind)
    assertEquals(string.format(W.L.CHESTS_WAITING, 10), W.Notifications.current.title)
    state.ui.compact = true
    ui:ApplyMode()
    W.Notifications.frame.action:GetScript("OnClick")()
    assertTrue(ui.frame:IsShown())
    assertFalse(state.ui.compact)
    assertEquals("chests", state.ui.tab)
    assertTrue(ui.chestFrame:IsVisible())
    ui:SetTab("party")
    assertFalse(ui.chestFrame:IsShown())
end)

test(
    "Opening is unavailable during catch-up and source selection preserves other chests",
    function()
        local W, state, ui = fixture()
        drop(W, state, 2)
        state.zone = "durotar"
        drop(W, state, 2)
        ui.chestZone = "elwynn"
        ui:Refresh()
        state.settings.instantChestReveal = true
        local action = ui.chestControls.all:GetScript("OnClick")
        W.catchup = {}
        action()
        assertEquals(4, W.Game.ChestCount(state))
        W.catchup = nil
        ui:Refresh()
        ui.chestControls.all:GetScript("OnClick")()
        assertEquals(2, W.Game.ChestCount(state))
        assertEquals("durotar", state.chests[1].zone)
        assertEquals(2, ui.chestReport.count)
    end
)

test("Chest result pages retain all rewards and frame pools stabilize on refresh", function()
    local W, state, ui = fixture()
    state.settings.instantChestReveal = true
    for index = 1, 12 do
        local template = W.Content.items[index + 5]
        W.Game.StoreChest(
            state,
            W.Game.Item(state, template.slot, 1, template.quality, false, template)
        )
    end
    ui:Refresh()
    ui.chestControls.all:GetScript("OnClick")()
    assertEquals(12, #ui.chestReport.entries)
    assertEquals(960, ui.chestFrame:GetWidth())
    assertEquals(960, ui.chestCarousel:GetWidth())
    ui.chestPage = 1
    ui:Refresh()
    assertEquals(1, ui.chestPage)
    local function count(frame)
        local total = select("#", frame:GetRegions()) + 1
        for _, child in ipairs({ frame:GetChildren() }) do
            total = total + count(child)
        end
        return total
    end
    ui.chestPage = 0
    ui:Refresh()
    local before = count(ui.chestFrame)
    for _ = 1, 10 do
        ui:Refresh()
    end
    assertEquals(before, count(ui.chestFrame))
    assertTrue(W.Game.ResetAdventure(state, false))
    ui:Refresh()
    assertEquals(nil, ui.chestReport)
    assertEquals(0, W.Game.ChestCount(state))
end)

test("Return reports show earned chests and safely handle malformed older summaries", function()
    local W, state, ui = fixture()
    drop(W, state, 3)
    state.lastOfflineSummary = { chests = 3, materials = {} }
    ui:SetTab("offline")
    assertNotNil(ui.offlineChests)
    assertTrue(ui.offlineChests:IsShown())
    ui.offlineChests:GetScript("OnClick")()
    assertEquals("chests", state.ui.tab)
    state.lastOfflineSummary.chests = "invalid"
    ui:SetTab("offline")
    assertNotNil(ui.offlineCards.equipment)
end)

test(
    "Chest auto equip toggle applies to the batch before its reveal and survives closing",
    function()
        local W, state, ui = fixture()
        drop(W, state, 3, 3)
        ui.chestAutoEquip:SetChecked(true)
        ui.chestAutoEquip:GetScript("OnClick")(ui.chestAutoEquip)
        assertTrue(state.settings.chestAutoEquip)
        ui.chestControls.all:GetScript("OnClick")()
        assertNotNil(ui.chestOpening)
        assertNotNil(state.heroes[1].gear[1])
        assertEquals(1, ui.chestOpening.equipped)
        assertEquals(2, ui.chestOpening.disenchanted)
        ui.frame:Hide()
        assertNotNil(state.heroes[1].gear[1])
        assertEquals(0, #state.inventory)
    end
)

test(
    "Chest models use load callbacks, native poses, rarity lighting and a safe icon fallback",
    function()
        local W, state, ui = fixture()
        local model = ui.chestScene.models[1]
        local file, has, animate, light =
            model.GetModelFileID, model.HasAnimation, model.SetAnimation, model.SetLight
        local animations, lights = {}, {}
        model.GetModelFileID = function()
            return 1100065
        end
        model.HasAnimation = function()
            return true
        end
        model.SetAnimation = function(_, animation)
            animations[#animations + 1] = animation
        end
        model.SetLight = function(_, enabled, spec)
            assert(enabled)
            lights[#lights + 1] =
                { r = spec.diffuseColor.r, g = spec.diffuseColor.g, b = spec.diffuseColor.b }
        end
        local ok, message = pcall(function()
            model.chestReady, model.chestAnimation = nil, nil
            model:GetScript("OnModelLoaded")(model)
            assertTrue(model.chestReady)
            assertFalse(ui.chestScene.chests[1]:IsShown())
            drop(W, state, 2, 4)
            ui.chestControls[1]:GetScript("OnClick")()
            assertEquals(147, animations[#animations])
            ui.chestScene:GetScript("OnUpdate")(ui.chestScene, 0.8)
            assertEquals(148, animations[#animations])
            local color = W.Content.qualityColors[4]
            assertEquals(color[1], lights[#lights].r)
            assertEquals(color[2], lights[#lights].g)
            ui.chestSkip:GetScript("OnClick")()
            assertEquals(149, animations[#animations])
            ui.chestControls[1]:GetScript("OnClick")()
            assertEquals(147, animations[#animations])
            ui.chestScene:GetScript("OnUpdate")(ui.chestScene, 0.8)
            assertEquals(148, animations[#animations])
            ui.chestSkip:GetScript("OnClick")()
        end)
        model.GetModelFileID, model.HasAnimation, model.SetAnimation, model.SetLight =
            file, has, animate, light
        model.chestReady, model.chestAnimation = nil, nil
        ui:Refresh()
        assertTrue(ui.chestScene.chests[1]:IsShown())
        assert(ok, message)
    end
)

test("Forever requests its verified chest model instead of forcing the icon fallback", function()
    local W, _, ui = fixture()
    local create, flavor = CreateFrame, W.Client.flavor
    local requested, model
    local fallback = W.Widgets.Icon(ui.chestFrame, "INV_Misc_TreasureChest01a", 0, 0, 32)
    local ok, message = pcall(function()
        W.Client.flavor = "forever"
        CreateFrame = function(...)
            local frame = create(...)
            frame.SetModel = function(_, fileID)
                requested = fileID
            end
            return frame
        end
        model = W.Client.CreateChestModel(ui.chestFrame, fallback)
        assertEquals(1100065, requested)
        assertNotNil(model:GetScript("OnUpdate"))
        model.GetModelFileID = function()
            return requested
        end
        model.HasAnimation = function()
            return true
        end
        model:GetScript("OnModelLoaded")(model)
        assertTrue(model.chestReady)
        assertFalse(fallback:IsShown())
        assertEquals(1, model:GetAlpha())
    end)
    CreateFrame, W.Client.flavor = create, flavor
    if model then
        model:Hide()
    end
    fallback:Hide()
    assert(ok, message)
end)

test(
    "Repeated chest clicks join the reveal without restarting it or replacing visible results",
    function()
        local W, state, ui = fixture()
        drop(W, state, 6, 3)
        state.settings.instantChestReveal = true
        ui.chestControls[1]:GetScript("OnClick")()
        state.settings.instantChestReveal = false
        ui.chestControls[1]:GetScript("OnClick")()
        local update = ui.chestScene:GetScript("OnUpdate")
        update(ui.chestScene, 0.8)
        local elapsed, duration = ui.chestElapsed, ui.chestDuration
        for _ = 1, 3 do
            ui.chestControls[1]:GetScript("OnClick")()
        end
        assertEquals(elapsed, ui.chestElapsed)
        assertEquals(duration, ui.chestDuration)
        assertEquals(4, ui.chestOpening.count)
        assertEquals(1, ui.chestReport.count)
        assertEquals(1, #ui.chestResultButtons)
        update(ui.chestScene, duration)
        assertEquals(nil, ui.chestOpening)
        assertEquals(5, ui.chestReport.count)
        assertEquals(5, ui.chestReport.entries[1].count)
        ui.chestControls[1]:GetScript("OnClick")()
        assertEquals(0, ui.chestElapsed)
        ui.frame:Hide()
        assertEquals(nil, ui.chestReport)
        assertEquals(6, state.inventory[1].count)
    end
)

test(
    "Merged chest results preserve distinct qualities and finish with bounded highlights",
    function()
        local W, state, ui = fixture()
        drop(W, state, 1, 1)
        ui.chestControls[1]:GetScript("OnClick")()
        local duration = ui.chestDuration
        local update = ui.chestScene:GetScript("OnUpdate")
        update(ui.chestScene, 0.3)
        drop(W, state, 1, 4)
        ui.chestControls[1]:GetScript("OnClick")()
        assertEquals(duration, ui.chestDuration)
        assertEquals(4, ui.chestOpening.quality)
        update(ui.chestScene, duration)
        assertEquals(2, #ui.chestReport.entries)
        update(ui.chestScene, 0.1)
        assertTrue(ui.chestHighlights[1]:GetAlpha() > 0)
        update(ui.chestScene, 1)
        assertEquals(0, ui.chestHighlights[1]:GetAlpha())
        assertEquals(0, ui.chestHighlights[2]:GetAlpha())
    end
)

test(
    "Rare rays and Epic orbiting motes use distinct shapes and lighting without restarting",
    function()
        local sizes, rotations = {}, {}
        for quality = 3, 4 do
            local W, state, ui = fixture()
            drop(W, state, 2, quality)
            ui.chestControls[1]:GetScript("OnClick")()
            ui.chestScene:GetScript("OnUpdate")(ui.chestScene, 0.3)
            local spark = ui.chestScene.sparks[1]
            sizes[quality] = { spark:GetWidth(), spark:GetHeight() }
            rotations[quality] = ui.chestScene.glow:GetRotation()
            ui.chestControls[1]:GetScript("OnClick")()
            assertEquals(0.3, ui.chestElapsed)
            assertEquals(2, ui.chestOpening.count)
            ui.chestSkip:GetScript("OnClick")()
        end
        assertTrue(sizes[3][1] < sizes[3][2])
        assertEquals(sizes[4][1], sizes[4][2])
        assertEquals(0, rotations[3])
        assertTrue(rotations[4] > 0)
    end
)

test("Leaving chest results clears salvaged history and finishes pending openings", function()
    local W, state, ui = fixture()
    state.salvage.minQuality, state.salvage.keepUpgrades, state.salvage.keepEffects =
        4, false, false
    state.settings.instantChestReveal = true
    drop(W, state, 4, 2)
    ui.chestControls[1]:GetScript("OnClick")()
    assertTrue(ui.chestReport.salvaged > 0)
    local gold, ore, inventory = state.gold, state.materials.ore, #state.inventory
    ui:SetTab("party")
    ui:SetTab("chests")
    assertEquals(nil, ui.chestReport)
    assertEquals(0, #ui.chestResultButtons)
    assertEquals(gold, state.gold)
    assertEquals(ore, state.materials.ore)
    assertEquals(inventory, #state.inventory)
    assertEquals(3, W.Game.ChestCount(state))
    ui.chestControls[1]:GetScript("OnClick")()
    state.settings.instantChestReveal = false
    ui.chestControls[1]:GetScript("OnClick")()
    ui.chestScene:GetScript("OnUpdate")(ui.chestScene, 0.3)
    ui:SetTab("party")
    ui:SetTab("chests")
    assertEquals(nil, ui.chestOpening)
    assertEquals(nil, ui.chestReport)
    assertEquals(1, W.Game.ChestCount(state))
end)

test("Leaving chest results clears the session without consuming unopened chests", function()
    local W, state, ui = fixture()
    drop(W, state, 3, 3)
    state.settings.instantChestReveal = true
    ui.chestControls[1]:GetScript("OnClick")()
    assertNotNil(ui.chestReport)
    ui:SetTab("party")
    assertEquals(nil, ui.chestReport)
    assertEquals(nil, ui.chestOpening)
    assertEquals(0, ui.chestPage)
    assertEquals(2, W.Game.ChestCount(state))
    assertEquals(1, state.inventory[1].count or 1)
    ui:SetTab("chests")
    assertEquals(nil, ui.chestReport)
    ui.chestControls[1]:GetScript("OnClick")()
    assertEquals(1, ui.chestReport.count)
    assertEquals(2, state.inventory[1].count)
end)
