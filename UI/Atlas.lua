local _, W = ...
local L = W.L
local A, C, G, U, T = W.Client, W.Content, W.Game, W.Widgets, W.Theme
local Atlas = {}
W.Atlas = Atlas

local function unlockText(zone)
    return L.UNLOCK_DEFEAT_A_LEVEL_PREFIX
        .. math.max(1, (zone.unlockLevel or zone.level) - 1)
        .. L.OR_HIGHER_MILESTONE_BOSS_SUFFIX
end

local function familySpoils(zone)
    local spoils, seen = {}, {}
    local function include(family)
        local material = C.familyMaterials[family]
        if material and not seen[material] then
            seen[material] = true
            spoils[#spoils + 1] = C.materials[material]
        end
    end
    for _, family in ipairs(zone.enemyFamilies or {}) do
        include(family)
    end
    include(zone.bossFamily)
    return #spoils > 0 and table.concat(spoils, ", ") or nil
end

local function describe(self, zone)
    zone = zone or C.zoneByID[W.state.zone]
    self.focus = zone
    self.title:SetText(zone.name)
    local spoils = familySpoils(zone)
    self.detail:SetText(
        C.materials[zone.material]
            .. L.FRAGMENT_FRONTIER
            .. zone.level
            .. "  ·  "
            .. string.format(L.HERO_XP_CEILING, zone.heroLevelCap)
            .. "  ·  "
            .. (G.IsUnlocked(W.state, zone) and L.AVAILABLE or unlockText(zone))
            .. (spoils and (L.FRAGMENT_SECONDARY_SPOILS .. spoils .. L.UP_TO_25_SUFFIX) or "")
    )
end

local function travel(self, zone)
    if zone and W.Action(G.Travel, zone.id) then
        describe(self, zone)
        W.Notify(L.YOUR_COMPANY_IS_TRAVELING_THROUGH_PREFIX .. zone.name .. ".")
        W.UI:SetTab("adventure")
    end
end

local function zoneTooltip(map, zone)
    GameTooltip:SetOwner(map, "ANCHOR_CURSOR")
    U.SetTooltipWidth(340)
    GameTooltip:SetText(zone.name, unpack(T.gold))
    GameTooltip:AddLine(
        C.materials[zone.material] .. L.FRAGMENT_FRONTIER_2 .. zone.level,
        0.8,
        0.8,
        0.7,
        true
    )
    GameTooltip:AddLine(string.format(L.HERO_XP_CEILING, zone.heroLevelCap), 0.8, 0.8, 0.7, true)
    GameTooltip:AddLine(
        #zone.enemies .. L.CREATURE_ENCOUNTERS_NEW_OPPONENTS_AT_FRONTIERS_20_40_AND_SUFFIX,
        0.8,
        0.8,
        0.7,
        true
    )
    GameTooltip:AddLine(
        C.zoneComponents[zone.id].name
            .. L.FRAGMENT_OWNED
            .. (W.state.professions.components[zone.id] or 0),
        1,
        0.82,
        0,
        true
    )
    GameTooltip:AddLine(
        L.IDLE_BOSSES_GUARANTEE_1_TROPHY_FOR_ENCHANTING_OR_TITANFORGING,
        0.8,
        0.8,
        0.7,
        true
    )
    local spoils = familySpoils(zone)
    if spoils then
        GameTooltip:AddLine(L.FAMILY_SPOILS_PREFIX .. spoils, 0.8, 0.8, 0.7, true)
        GameTooltip:AddLine(
            L.UP_TO_25_ADDITIONAL_IDLE_MATERIALS_SHARED_ACROSS_THE,
            0.7,
            0.7,
            0.7,
            true
        )
    end
    GameTooltip:AddLine(
        G.IsUnlocked(W.state, zone) and L.CLICK_TO_TRAVEL or unlockText(zone),
        0.8,
        0.8,
        0.7,
        true
    )
    GameTooltip:Show()
end

local function cursorPosition(map)
    local x, y = GetCursorPosition()
    local scale = map:GetEffectiveScale()
    return (x / scale - map:GetLeft()) / map:GetWidth(),
        (map:GetTop() - y / scale) / map:GetHeight()
end

local function highlight(map, zone, x, y)
    local texture = map.highlight
    if not zone then
        texture:Hide()
        return
    end
    local bounds, mask = A.MapMask(zone.id, map.id, map.artInfo)
    if bounds then
        -- Hover, color and travel share one partition, including subdivisions
        -- that the native continent highlight provider merges or displaces.
        local left, top, right, bottom = unpack(bounds)
        texture:ClearAllPoints()
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetTexture(mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        texture:SetPoint("TOPLEFT", left * map:GetWidth(), -top * map:GetHeight())
        texture:SetSize((right - left) * map:GetWidth(), (bottom - top) * map:GetHeight())
        texture:SetAlpha(0.2)
        texture:Show()
        return
    end
    local id = A.MapID(map.id)
    if not id or not C_Map or not C_Map.GetMapHighlightInfoAtPosition then
        texture:Hide()
        return
    end
    -- Unpackaged clients use native ownership and its matching highlight.
    local fileID, atlas, u, v, width, height, left, top =
        C_Map.GetMapHighlightInfoAtPosition(id, x, y)
    if
        not u
        or not v
        or not width
        or not height
        or not left
        or not top
        or (not atlas and (not fileID or fileID == 0))
    then
        texture:Hide()
        return false
    end
    local w, h = map:GetWidth(), map:GetHeight()
    texture:SetAlpha(0.55)
    texture:ClearAllPoints()
    texture:SetTexCoord(0, u, 0, v)
    if atlas then
        texture:SetAtlas(atlas, true)
        texture:SetSize(width * w, height * h)
        texture:SetPoint("CENTER", ((left + width / 2) - 0.5) * w, -((top + height / 2) - 0.5) * h)
    else
        texture:SetTexture(fileID)
        texture:SetSize(width * w, height * h)
        texture:SetPoint("TOPLEFT", left * w, -top * h)
    end
    texture:Show()
    return true
end

local function createMap(self, parent, id, name, x)
    local box = CreateFrame("Frame", nil, parent)
    box:SetPoint("TOPLEFT", x, -77)
    box:SetSize(632, 496)
    local content = U.BorderContent(box, 6)
    U.Rect(content, 0, 0, 632, 496, T.panel)
    U.FrameTreatment(box)
    U.Text(content, name, 18, 13, 21, T.gold)
    local map = CreateFrame("Frame", nil, content)
    map.id, map.tiles, map.colorRegions = id, {}, {}
    map:SetPoint("TOPLEFT", 8, -48)
    map:SetSize(616, 410)
    map:SetClipsChildren(true)
    map:EnableMouse(true)
    map.highlight = map:CreateTexture(nil, "OVERLAY")
    map.highlight:SetAlpha(0.55)
    map.highlight:SetBlendMode("ADD")
    map.highlight:Hide()
    map.message = U.Text(map, "", 20, 160, 15, T.muted, 576)

    map:SetScript("OnUpdate", function(frame, dt)
        frame.elapsed = (frame.elapsed or 0) + dt
        if frame.elapsed < 0.04 or not frame:IsMouseOver() then
            return
        end
        frame.elapsed = 0
        local nx, ny = cursorPosition(frame)
        local zone = A.ZoneAtPosition(id, nx, ny)
        frame.highlight:SetDesaturated(not zone or not G.IsUnlocked(W.state, zone))
        highlight(frame, zone, nx, ny)
        if zone ~= frame.hovered then
            frame.hovered = zone
            if zone then
                describe(self, zone)
                zoneTooltip(frame, zone)
            elseif GameTooltip:IsOwned(frame) then
                GameTooltip:Hide()
            end
        end
    end)
    local function clearHover()
        map.hovered = nil
        map.highlight:Hide()
        if GameTooltip:IsOwned(map) then
            GameTooltip:Hide()
        end
    end
    map:SetScript("OnLeave", clearHover)
    map:SetScript("OnHide", clearHover)
    map:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            local nx, ny = cursorPosition(map)
            travel(self, A.ZoneAtPosition(id, nx, ny))
        end
    end)
    return map
end

local function paintMap(map)
    for _, tile in ipairs(map.tiles) do
        tile:Hide()
    end
    local textures, info = A.MapTiles(map.id)
    map.message:SetText(textures and "" or L.CONTINENT_ARTWORK_IS_UNAVAILABLE_IN_THIS_CLIENT)
    if not textures or not info then
        return
    end
    map.artInfo = info
    local tw, th = info.tileWidth or 256, info.tileHeight or 256
    local width, height = info.layerWidth or 1002, info.layerHeight or 668
    local columns = math.ceil(width / tw)
    local sx, sy = map:GetWidth() / width, map:GetHeight() / height
    for i, texture in ipairs(textures) do
        local tile = map.tiles[i]
        if not tile then
            tile = map:CreateTexture(nil, "BACKGROUND")
            map.tiles[i] = tile
        end
        tile:ClearAllPoints()
        tile:SetPoint(
            "TOPLEFT",
            (i - 1) % columns * tw * sx,
            -math.floor((i - 1) / columns) * th * sy
        )
        tile:SetSize(tw * sx, th * sy)
        tile:SetTexture(A.MapTileTexture(map.id, i, texture, info))
        tile.mapBounds = {
            (i - 1) % columns * tw / width,
            math.floor((i - 1) / columns) * th / height,
            ((i - 1) % columns + 1) * tw / width,
            (math.floor((i - 1) / columns) + 1) * th / height,
        }
        tile:SetDesaturated(false)
        tile:Show()
    end
end

local function createMaskedRegion(map, texture, bounds, desaturated)
    if not map.CreateMaskTexture then
        return
    end
    local left, top, right, bottom = unpack(bounds)
    local region = { tiles = {} }
    local mask = map:CreateMaskTexture()
    -- Native masks use the full padded texture and transparent overflow.
    -- Avoid cropped mask UVs: the simulator and live client can project them differently.
    mask:SetTexture(texture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetPoint("TOPLEFT", left * map:GetWidth(), -top * map:GetHeight())
    mask:SetSize((right - left) * map:GetWidth(), (bottom - top) * map:GetHeight())
    region.mask = mask
    for _, source in ipairs(map.tiles) do
        local area = source.mapBounds
        if area[1] < right and area[3] > left and area[2] < bottom and area[4] > top then
            local tile = map:CreateTexture(nil, "ARTWORK", nil, desaturated and 0 or 1)
            tile:SetAllPoints(source)
            tile:SetTexture(source:GetTexture())
            tile:SetDesaturated(desaturated)
            tile:AddMaskTexture(mask)
            region.tiles[#region.tiles + 1] = tile
        end
    end
    return region
end

local function updateAccessibleRegions(map)
    if map.coloredFrontier == W.state.runBest then
        return
    end
    map.coloredFrontier = W.state.runBest
    -- Gray the land only; the base artwork keeps sea and parchment in color.
    if not map.grayRegion then
        local bounds, texture = A.MapMask(map.id, map.id, map.artInfo)
        if bounds then
            map.grayRegion = createMaskedRegion(map, texture, bounds, true)
        end
    end
    for _, zone in ipairs(C.zones) do
        local region = map.colorRegions[zone.id]
        local unlocked = G.IsUnlocked(W.state, zone)
        if unlocked and not region then
            local bounds, texture = A.MapMask(zone.id, map.id, map.artInfo)
            if bounds then
                region = createMaskedRegion(map, texture, bounds, false)
                map.colorRegions[zone.id] = region
            end
        end
        if region then
            for _, tile in ipairs(region.tiles) do
                tile:SetShown(unlocked)
            end
        end
    end
end

function Atlas.Draw(ui)
    local self = ui.atlas
    if not self then
        self = { frame = CreateFrame("Frame", nil, ui.panel) }
        ui.atlas = self
        self.frame:SetAllPoints()
        U.Text(self.frame, L.DESTINATIONS_HEADING, 0, 0, 24, T.gold)
        U.Help(
            self.frame,
            L.WORLD_MAP,
            1258,
            0,
            L.HOVER_A_REGION_TO_INSPECT_ITS_REWARDS_AND_REQUIREMENTS
        )
        self.maps = {
            createMap(self, self.frame, "kalimdor", L.KALIMDOR, 0),
            createMap(self, self.frame, "eastern", L.EASTERN_KINGDOMS, 664),
        }
        self.title = U.Text(self.frame, "", 0, 599, 22, T.gold, 900)
        self.detail = U.Text(self.frame, "", 0, 634, 13, T.muted, 920)
        for _, map in ipairs(self.maps) do
            paintMap(map)
        end
    end
    self.frame:Show()
    for _, map in ipairs(self.maps) do
        updateAccessibleRegions(map)
    end
    local step, _, destination = W.Panels.GuideStep(W.state)
    local guided = not W.state.guide.dismissed and step == 4
    describe(self, guided and destination or self.focus)
end
