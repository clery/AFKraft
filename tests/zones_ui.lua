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
