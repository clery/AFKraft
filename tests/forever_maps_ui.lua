if not test then
    return
end

-- Installed 1.60.1.70790 UiMapArtTile/UiMapArtStyleLayer data. The simulator
-- lacks these native map records; only the data getters are supplied here.
local textures = {
    [1414] = {
        8025526,
        8025566,
        8025567,
        8025572,
        8025573,
        8025574,
        8025575,
        8025576,
        8025577,
        8025527,
        8025548,
        8025561,
    },
    [1415] = {
        8023297,
        8023301,
        8023302,
        8023303,
        8023304,
        8023305,
        8023306,
        8023307,
        8023308,
        8023298,
        8023299,
        8023300,
    },
}

test(
    "Forever masks align with native tiles and travel uses the same regions in both window sizes",
    function()
        local W = WoWIdle
        W.Initialize()
        local client, ui = W.Client, W.UI
        local flavor, profile, state = client.flavor, client.profile, W.state
        local atlas, fullscreen = ui.atlas, ui.fullscreen
        local layers, tiles, cursor =
            C_Map.GetMapArtLayers, C_Map.GetMapArtLayerTextures, GetCursorPosition
        if atlas then
            atlas.frame:Hide()
        end
        ui.atlas = nil
        local ok, message = pcall(function()
            client.flavor, client.profile = "forever", client.profiles.forever
            C_Map.GetMapArtLayers = function(id)
                if textures[id] then
                    return {
                        { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 },
                    }
                end
                return layers(id)
            end
            C_Map.GetMapArtLayerTextures = function(id, layer)
                return textures[id] or tiles(id, layer)
            end
            local s = W.Game.New(client.Now())
            W.Game.AddHero(s, "WARRIOR")
            s.runBest, s.best, s.guide.dismissed = 60, 60, true
            W.state = s
            ui.frame:Show()
            for _, full in ipairs({ true, false }) do
                ui.fullscreen = full
                ui:ApplyMode()
                ui:SetTab("atlas")
                for _, map in ipairs(ui.atlas.maps) do
                    assertEquals(12, #map.tiles)
                    assertNotNil(map.grayRegion)
                    for i, tile in ipairs(map.tiles) do
                        assertEquals(textures[client.MapID(map.id)][i], tile:GetTexture())
                    end
                end
                for _, zone in ipairs(W.Content.zones) do
                    local found = 0
                    for _, map in ipairs(ui.atlas.maps) do
                        local x, y = client.ZonePosition(zone.id, map.id)
                        if x then
                            found = found + 1
                            ui:SetTab("atlas")
                            assertEquals(zone.id, client.ZoneAtPosition(map.id, x, y).id)
                            assertNotNil(map.colorRegions[zone.id])
                            GetCursorPosition = function()
                                local scale = map:GetEffectiveScale()
                                return (map:GetLeft() + x * map:GetWidth()) * scale,
                                    (map:GetTop() - y * map:GetHeight()) * scale
                            end
                            map:GetScript("OnMouseUp")(map, "LeftButton")
                            assertEquals(zone.id, s.zone)
                        end
                    end
                    assertEquals(1, found)
                end
                s.runBest, s.best = 9, 9
                ui:SetTab("atlas")
                for _, map in ipairs(ui.atlas.maps) do
                    for id, region in pairs(map.colorRegions) do
                        for _, tile in ipairs(region.tiles) do
                            assertEquals(
                                W.Game.IsUnlocked(s, W.Content.zoneByID[id]),
                                tile:IsShown()
                            )
                        end
                    end
                end
                s.runBest, s.best = 60, 60
            end
        end)
        if ui.atlas then
            ui.atlas.frame:Hide()
        end
        client.flavor, client.profile, W.state = flavor, profile, state
        C_Map.GetMapArtLayers, C_Map.GetMapArtLayerTextures, GetCursorPosition =
            layers, tiles, cursor
        ui.atlas, ui.fullscreen = atlas, fullscreen
        ui:ApplyMode()
        ui:Refresh()
        assert(ok, message)
    end
)
