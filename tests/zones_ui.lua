if not test then
    return
end

test("Every outdoor destination supports continent-map travel in both window sizes", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    state.runBest, state.best, state.guide.dismissed = 18, 18, true
    W.state = state
    W.UI.frame:Show()
    local original, fullscreen = GetCursorPosition, W.UI.fullscreen
    local ok, message = pcall(function()
        for _, full in ipairs({ true, false }) do
            W.UI.fullscreen = full
            W.UI:ApplyMode()
            for _, zone in ipairs(W.Content.zones) do
                W.UI:SetTab("atlas")
                local found = false
                for _, map in ipairs(W.UI.atlas.maps) do
                    local x, y = W.Client.ZonePosition(zone.id, map.id)
                    if x then
                        found = true
                        local hit = W.Client.ZoneAtPosition(map.id, x, y)
                        assert(
                            hit and hit.id == zone.id,
                            zone.id .. " map hit: " .. tostring(hit and hit.id)
                        )
                        GetCursorPosition = function()
                            local scale = map:GetEffectiveScale()
                            return (map:GetLeft() + x * map:GetWidth()) * scale,
                                (map:GetTop() - y * map:GetHeight()) * scale
                        end
                        map:GetScript("OnMouseUp")(map, "LeftButton")
                        assertEquals(zone.id, state.zone)
                        assertFalse(W.UI.atlas.frame:IsShown())
                        assertTrue(W.UI.scene.scenery.supported, zone.id)
                    end
                end
                assertTrue(found, zone.id)
            end
        end
    end)
    GetCursorPosition, W.UI.fullscreen = original, fullscreen
    W.UI:ApplyMode()
    assert(ok, message)
end)

test("Padded continent masks use native full-texture coordinates at frontier nine", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    state.runBest, state.best, state.guide.dismissed = 9, 9, true
    for _, class in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "DRUID" }) do
        assertTrue(W.Game.AddHero(state, class))
        state.heroes[#state.heroes].level = 4
    end
    state.zone, state.stage, state.rest = "westfall", 31, 0
    W.Game.StartBattle(state)
    assertEquals(9, state.battle.level)
    W.state = state
    W.UI.frame:Show()
    W.UI:SetTab("atlas")
    for _, map in ipairs(W.UI.atlas.maps) do
        local function check(region)
            local ulx, uly, llx, lly, urx, ury, lrx, lry = region.mask:GetTexCoord()
            assertEquals(0, ulx)
            assertEquals(0, uly)
            assertEquals(0, llx)
            assertEquals(1, lly)
            assertEquals(1, urx)
            assertEquals(0, ury)
            assertEquals(1, lrx)
            assertEquals(1, lry)
        end
        check(map.grayRegion)
        for _, zone in ipairs(W.Content.zones) do
            local bounds = W.Client.MapMask(zone.id, map.id, map.artInfo)
            if bounds then
                local region = map.colorRegions[zone.id]
                if W.Game.IsUnlocked(state, zone) then
                    assertNotNil(region)
                    check(region)
                    assertTrue(region.tiles[1]:IsShown())
                elseif region then
                    assertFalse(region.tiles[1]:IsShown())
                end
            end
        end
    end
    assertFalse(W.Game.IsUnlocked(state, W.Content.zoneByID.stranglethorn))
    assertFalse(W.Game.IsUnlocked(state, W.Content.zoneByID.winterspring))
end)

test("Scaled coastal clicks select Darkshore and ignore its offshore margin", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    state.runBest, state.best, state.guide.dismissed = 9, 9, true
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.UI.frame:Show()
    local original, fullscreen = GetCursorPosition, W.UI.fullscreen
    local map, originalMouse
    local ok, message = pcall(function()
        for _, full in ipairs({ true, false }) do
            W.UI.fullscreen = full
            W.UI:ApplyMode()
            W.UI:SetTab("atlas")
            map = W.UI.atlas.maps[1]
            originalMouse = map.IsMouseOver
            map.IsMouseOver = function()
                return true
            end
            local function point(x, y)
                GetCursorPosition = function()
                    local scale = map:GetEffectiveScale()
                    return (map:GetLeft() + (x + 0.5) / 1200 * map:GetWidth()) * scale,
                        (map:GetTop() - (y + 0.5) / 800 * map:GetHeight()) * scale
                end
                map:GetScript("OnUpdate")(map, 0.05)
            end
            point(552, 170)
            assertEquals("darkshore", map.hovered.id)
            map:GetScript("OnMouseUp")(map, "LeftButton")
            assertEquals("darkshore", state.zone)
            W.UI:SetTab("atlas")
            point(590, 225)
            assertEquals("felwood", map.hovered.id)
            map:GetScript("OnMouseUp")(map, "LeftButton")
            assertEquals("darkshore", state.zone)
            local battle = state.battle
            point(536, 205)
            assertTrue(map.hovered == nil)
            assertFalse(GameTooltip:IsShown())
            map:GetScript("OnMouseUp")(map, "LeftButton")
            assertEquals("darkshore", state.zone)
            assertEquals(battle, state.battle)
            map.IsMouseOver = originalMouse
            originalMouse = nil
        end
    end)
    if map and originalMouse then
        map.IsMouseOver = originalMouse
    end
    GetCursorPosition, W.UI.fullscreen = original, fullscreen
    W.UI:ApplyMode()
    assert(ok, message)
end)

test("Southern Eastern Kingdoms hover and travel use the visible zone masks", function()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    state.runBest, state.best, state.guide.dismissed = 18, 18, true
    W.Game.AddHero(state, "WARRIOR")
    W.state = state
    W.UI.frame:Show()
    local original, fullscreen = GetCursorPosition, W.UI.fullscreen
    local nativeHighlight = C_Map.GetMapHighlightInfoAtPosition
    local nativeCalls = 0
    C_Map.GetMapHighlightInfoAtPosition = function(mapID, x, y)
        nativeCalls = nativeCalls + 1
        error(
            "Unexpected native highlight query: "
                .. tostring(mapID)
                .. ":"
                .. tostring(x)
                .. ":"
                .. tostring(y)
        )
    end
    local map, originalMouse
    local ok, message = pcall(function()
        for _, full in ipairs({ true, false }) do
            W.UI.fullscreen = full
            W.UI:ApplyMode()
            W.UI:SetTab("atlas")
            map = W.UI.atlas.maps[2]
            originalMouse = map.IsMouseOver
            map.IsMouseOver = function()
                return true
            end
            for _, point in ipairs({
                { "duskwood", 588, 655 },
                { "deadwind", 595, 650 },
                { "deadwind", 603, 663 },
                { "deadwind", 607, 679 },
                { "swamp_sorrows", 625, 650 },
                { "blasted_lands", 620, 690 },
                { "blasted_lands", 627, 710 },
                { "stranglethorn", 595, 700 },
            }) do
                W.UI:SetTab("atlas")
                GetCursorPosition = function()
                    local scale = map:GetEffectiveScale()
                    return (map:GetLeft() + (point[2] + 0.5) / 1200 * map:GetWidth()) * scale,
                        (map:GetTop() - (point[3] + 0.5) / 800 * map:GetHeight()) * scale
                end
                map:GetScript("OnUpdate")(map, 0.05)
                assertEquals(point[1], map.hovered.id)
                local bounds, texture = W.Client.MapMask(point[1], map.id, map.artInfo)
                assertTrue(map.highlight:IsShown())
                assertEquals(texture, map.highlight:GetTexture())
                assertTrue(
                    math.abs((bounds[3] - bounds[1]) * map:GetWidth() - map.highlight:GetWidth())
                        < 0.001
                )
                assertTrue(
                    math.abs((bounds[4] - bounds[2]) * map:GetHeight() - map.highlight:GetHeight())
                        < 0.001
                )
                local _, _, _, x, y = map.highlight:GetPoint(1)
                assertTrue(math.abs(bounds[1] * map:GetWidth() - x) < 0.001)
                assertTrue(math.abs(-bounds[2] * map:GetHeight() - y) < 0.001)
                local ulx, uly, _, lly, urx, _, lrx, lry = map.highlight:GetTexCoord()
                assertEquals(0, ulx)
                assertEquals(0, uly)
                assertEquals(1, lly)
                assertEquals(1, urx)
                assertEquals(1, lrx)
                assertEquals(1, lry)
                map:GetScript("OnMouseUp")(map, "LeftButton")
                assertEquals(point[1], state.zone)
            end
            map.IsMouseOver = originalMouse
            originalMouse = nil
        end
        assertEquals(0, nativeCalls)
    end)
    if map and originalMouse then
        map.IsMouseOver = originalMouse
    end
    C_Map.GetMapHighlightInfoAtPosition = nativeHighlight
    GetCursorPosition, W.UI.fullscreen = original, fullscreen
    W.UI:ApplyMode()
    assert(ok, message)
end)
