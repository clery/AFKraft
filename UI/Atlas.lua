local _, W = ...
local A, C, G, U, T = W.Client, W.Content, W.Game, W.Widgets, W.Theme
local Atlas = {}
W.Atlas = Atlas

local function describe(self, zone)
    zone = zone or C.zoneByID[W.state.zone]
    self.focus = zone
    self.title:SetText(zone.name)
    self.detail:SetText(
        zone.subtitle
            .. "\n"
            .. C.materials[zone.material]
            .. "  ·  Frontier "
            .. zone.level
            .. "  ·  "
            .. (
                G.IsUnlocked(W.state, zone) and "Click the region or its marker to travel."
                or "Defeat harder encounters to unlock this region."
            )
    )
    self.action.text:SetText(
        W.state.zone == zone.id and "Current destination" or "Travel to " .. zone.name
    )
    U.Enabled(self.action, G.IsUnlocked(W.state, zone) and W.state.zone ~= zone.id)
end

local function travel(self, zone)
    if zone and W.Action(G.Travel, zone.id) then
        describe(self, zone)
        W.Notify("Your company is traveling through " .. zone.name .. ".")
    end
end

local function cursorPosition(map)
    local x, y = GetCursorPosition()
    local scale = map:GetEffectiveScale()
    return (x / scale - map:GetLeft()) / map:GetWidth(),
        (map:GetTop() - y / scale) / map:GetHeight()
end

local function highlight(map, x, y)
    local id = A.MapID(map.id)
    if not id or not C_Map.GetMapHighlightInfoAtPosition then
        map.highlight:Hide()
        return
    end
    -- Use the same zone highlight geometry as Blizzard's map highlight provider.
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
        map.highlight:Hide()
        return
    end
    local texture, w, h = map.highlight, map:GetWidth(), map:GetHeight()
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
    map.id, map.tiles, map.pins = id, {}, {}
    map:SetPoint("TOPLEFT", 8, -48)
    map:SetSize(616, 410)
    map:SetClipsChildren(true)
    map:EnableMouse(true)
    map.highlight = map:CreateTexture(nil, "ARTWORK")
    map.highlight:SetAlpha(0.55)
    map.highlight:SetBlendMode("ADD")
    map.highlight:Hide()
    map.message = U.Text(map, "", 20, 160, 15, T.muted, 576)
    U.Text(content, "Hover a region · Click to travel", 18, 471, 12, T.muted)
    map:SetScript("OnUpdate", function(frame, dt)
        frame.elapsed = (frame.elapsed or 0) + dt
        if frame.elapsed < 0.04 or not frame:IsMouseOver() then
            return
        end
        frame.elapsed = 0
        local nx, ny = cursorPosition(frame)
        frame.hovered = A.ZoneAtPosition(id, nx, ny)
        highlight(frame, nx, ny)
        if frame.hovered then
            describe(self, frame.hovered)
        end
    end)
    map:SetScript("OnLeave", function()
        map.highlight:Hide()
    end)
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
    map.message:SetText(textures and "" or "Continent artwork is unavailable in this client.")
    if not textures or not info then
        return
    end
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
        tile:SetTexture(texture)
        tile:Show()
    end
end

local function updatePins(self, map)
    for _, zone in ipairs(C.zones) do
        local x, y = A.ZonePosition(zone.id, map.id)
        local pin = map.pins[zone.id]
        if x and y then
            if not pin then
                pin = CreateFrame("Button", nil, map)
                map.pins[zone.id] = pin
                pin:SetSize(20, 25)
                pin.icon = pin:CreateTexture(nil, "ARTWORK")
                pin.icon:SetAllPoints()
                pin:SetScript("OnClick", function()
                    travel(self, zone)
                end)
                pin:SetScript("OnEnter", function()
                    describe(self, zone)
                    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
                    GameTooltip:SetText(zone.name, unpack(T.gold))
                    GameTooltip:AddLine(
                        C.materials[zone.material] .. " · Frontier " .. zone.level,
                        0.8,
                        0.8,
                        0.7
                    )
                    GameTooltip:AddLine(
                        G.IsUnlocked(W.state, zone) and "Click to travel" or "Not yet unlocked",
                        0.8,
                        0.8,
                        0.7
                    )
                    GameTooltip:Show()
                end)
                pin:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", map, "TOPLEFT", x * map:GetWidth(), -y * map:GetHeight())
            pin.icon:SetAtlas(
                W.state.zone == zone.id and "Waypoint-MapPin-Tracked" or "Waypoint-MapPin-Untracked"
            )
            pin.icon:SetDesaturated(not G.IsUnlocked(W.state, zone))
            pin:SetAlpha(G.IsUnlocked(W.state, zone) and 1 or 0.5)
            pin:Show()
        elseif pin then
            pin:Hide()
        end
    end
end

function Atlas.Draw(ui)
    local self = ui.atlas
    if not self then
        self = { frame = CreateFrame("Frame", nil, ui.panel) }
        ui.atlas = self
        self.frame:SetAllPoints()
        U.Text(self.frame, "Choose your next horizon", 0, 0, 24, T.gold)
        U.Text(
            self.frame,
            "Travel at any time. Marked regions are the destinations in your company’s current adventure.",
            0,
            39,
            13,
            T.muted,
            1296
        )
        self.maps = {
            createMap(self, self.frame, "kalimdor", "Kalimdor", 0),
            createMap(self, self.frame, "eastern", "Eastern Kingdoms", 664),
        }
        self.title = U.Text(self.frame, "", 0, 599, 22, T.gold, 900)
        self.detail = U.Text(self.frame, "", 0, 634, 13, T.muted, 920)
        self.action = U.Button(self.frame, "Travel", 958, 610, 338, 38, function()
            travel(self, self.focus)
        end, false, "primary")
        for _, map in ipairs(self.maps) do
            paintMap(map)
        end
    end
    self.frame:Show()
    for _, map in ipairs(self.maps) do
        updatePins(self, map)
    end
    describe(self, self.focus)
end
