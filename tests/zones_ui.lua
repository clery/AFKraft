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
