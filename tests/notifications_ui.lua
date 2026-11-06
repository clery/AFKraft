if not test then
    return
end

local function fixture()
    local W = AFKraft
    W.Initialize()
    W.Notifications.Clear()
    W.catchup = nil
    local state = W.Game.New(1000)
    W.Game.AddHero(state, "WARRIOR")
    state.heroes[1].level = 60
    state.guide.dismissed = true
    W.state = state
    W.UI.frame:Hide()
    return W, state, W.Notifications
end

local function drop(W, state, strength)
    local item = W.Game.Item(state, 1, 1, 2, false, W.Content.itemByID[25])
    item.stats = { strength = strength }
    W.Game.Loot(state, item)
    return item
end

test("Upgrade spotlights stay visible with the window closed and equip by identity", function()
    local W, state, N = fixture()
    local item = drop(W, state, 10)
    N.Flush()
    assertEquals(item, N.current.item)
    assertTrue(N.frame:IsShown())
    assertEquals("FULLSCREEN_DIALOG", N.frame:GetFrameStrata())
    assertFalse(W.UI.frame:IsShown())
    assertEquals(W.L.NEW_UPGRADE, N.current.heading)
    assertTrue(N.current.detail:find(state.heroes[1].name, 1, true) ~= nil)
    table.insert(state.inventory, 1, W.Game.Item(state, 2, 1, 2))
    N.frame.action:GetScript("OnClick")()
    assertEquals(item, state.heroes[1].gear[1])
    assertEquals(nil, N.current)
    assertFalse(N.frame:IsShown())
end)

test("Duplicate, inferior, salvaged and stale loot cannot flood upgrade spotlights", function()
    local W, state, N = fixture()
    local item = drop(W, state, 10)
    drop(W, state, 10)
    drop(W, state, 5)
    assertEquals(1, #N.queue)
    assertEquals(2, item.count)
    local better = drop(W, state, 20)
    assertEquals(1, #N.queue)
    assertEquals(better, N.queue[1].item)
    assertTrue(W.Game.Disenchant(state, better))
    N.Flush()
    assertEquals(nil, N.current)
    N.Clear()
    state.salvage.minQuality, state.salvage.keepUpgrades = 4, false
    drop(W, state, 30)
    assertEquals(0, #N.queue)
end)

test("An expired upgrade cannot replace newer equipment", function()
    local W, state, N = fixture()
    local item = drop(W, state, 10)
    N.Flush()
    local better = drop(W, state, 20)
    state.heroes[1].gear[1] = better
    for index, stored in ipairs(state.inventory) do
        if stored == better then
            table.remove(state.inventory, index)
            break
        end
    end
    N.frame.action:GetScript("OnClick")()
    assertEquals(better, state.heroes[1].gear[1])
    assertTrue(item ~= better)
end)

test("Reward toasts coalesce levels, bound bursts and open the relevant panel", function()
    local W, state, N = fixture()
    for _ = 1, 20 do
        W.Game.Emit(state, "levelup", { target = 1 })
    end
    assertEquals(1, #N.queue)
    N.Flush()
    N.frame.action:GetScript("OnClick")()
    assertTrue(W.UI.frame:IsShown())
    assertEquals("talents", state.ui.tab)
    for _, item in ipairs(W.Content.items) do
        W.Game.Emit(state, "collection", { itemID = item.itemID })
    end
    assertTrue(#N.queue <= 5)
    N.Clear()
    W.Game.AddHero(state, "MAGE")
    N.Flush()
    assertEquals("recruit", N.current.kind)
    assertEquals(2, N.current.target)
end)

test("Toasts ignore offline snapshots and catch-up and clear on mute or reset", function()
    local W, state, N = fixture()
    local snapshot = W.Game.Copy(state)
    W.Game.Emit(snapshot, "levelup", { target = 1 })
    W.catchup = {}
    W.Game.Emit(state, "levelup", { target = 1 })
    assertEquals(0, #N.queue)
    W.catchup = nil
    W.Game.Emit(state, "levelup", { target = 1 })
    N.Flush()
    state.settings.rewardToasts = false
    N.Flush()
    assertEquals(nil, N.current)
    assertFalse(N.frame:IsShown())
    W.Game.Emit(state, "levelup", { target = 1 })
    assertEquals(0, #N.queue)
    state.settings.rewardToasts = true
    W.Game.Emit(state, "levelup", { target = 1 })
    N.Flush()
    W.Game.Emit(state, "prestige")
    assertEquals(nil, N.current)
    assertEquals(0, #N.queue)
    W.ResetAdventure()
    assertEquals(nil, N.current)
    assertEquals(0, #N.queue)
    assertFalse(N.frame:IsShown())
end)

test("Toast lifetime fades, pauses on hover and reuses a single frame", function()
    local W, state, N = fixture()
    W.Game.Emit(state, "levelup", { target = 1 })
    N.Flush()
    local frame = N.frame
    local update = frame:GetScript("OnUpdate")
    update(frame, 0.25)
    assertTrue(frame:GetAlpha() > 0)
    local age = N.age
    update({
        IsMouseOver = function()
            return true
        end,
        SetAlpha = function() end,
    }, 3)
    assertEquals(age, N.age)
    update({
        IsMouseOver = function()
            return false
        end,
        SetAlpha = function() end,
    }, 9)
    assertEquals(nil, N.current)
    W.Game.Emit(state, "levelup", { target = 1 })
    N.Flush()
    assertEquals(frame, N.frame)
    N.Clear()
end)

test(
    "Crafted upgrades use the same spotlight and notification settings clear immediately",
    function()
        local W, state, N = fixture()
        state.gold, state.materials.ore = 100000, 10000
        assertTrue(W.Game.Craft(state, 1, 1, "ore", false))
        N.Flush()
        assertNotNil(N.current)
        assertEquals("upgrade", N.current.kind)
        local option = W.settingsOptions.args.rewardToasts
        assertNotNil(option)
        W.settingsOptions.set({ "rewardToasts" }, false)
        assertFalse(state.settings.rewardToasts)
        assertFalse(N.frame:IsShown())
        assertEquals(0, #N.queue)
    end
)
