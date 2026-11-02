local _, W = ...
local A = W.Client
local continents = { kalimdor = "Kalimdor", eastern = "Eastern Kingdoms" }
function A.MapTileTexture(continentID, index, original, info)
    -- The unlabeled flight-map tiles share this Retail artwork's exact grid.
    -- Replace only the title area, retaining the sea names and corner artwork.
    if
        A.flavor ~= "retail"
        or not info
        or info.layerWidth ~= 3840
        or info.layerHeight ~= 2560
        or info.tileWidth ~= 256
        or info.tileHeight ~= 256
    then
        return original
    end
    local row, column = math.floor((index - 1) / 15), (index - 1) % 15
    local name
    if column >= 5 and column <= 9 then
        if continentID == "kalimdor" and row == 4 then
            name = "Kalimdor"
        elseif continentID == "eastern" and (row == 6 or row == 7) then
            name = "EasternKingdoms"
        end
    end
    if name then
        return "Interface\\AdventureMap\\" .. name .. "\\" .. name .. "Taxi" .. (index - 1)
    end
    return original
end

local artChecks = {}

local function geometry(continentID, info)
    local profile = W.MapGeometry and W.MapGeometry[A.flavor]
    local continent = profile and profile.continents[continentID]
    if not continent or A.MapID(continentID) ~= continent.mapID then
        return nil
    end
    if
        info and (info.layerWidth ~= continent.artWidth or info.layerHeight ~= continent.artHeight)
    then
        return nil
    end
    if C_Map and C_Map.GetMapArtLayerTextures then
        local key = A.flavor .. ":" .. continentID
        if artChecks[key] == nil then
            local ok, textures = pcall(C_Map.GetMapArtLayerTextures, continent.mapID, 1)
            artChecks[key] = ok and textures and textures[1] == continent.firstTexture or false
        end
        if not artChecks[key] then
            return nil
        end
    end
    return profile, continent
end

function A.MapMask(key, continentID, info)
    local profile = geometry(continentID, info)
    local mask = profile and profile.masks[key]
    if profile and mask and mask.continent == continentID then
        return mask.bounds, mask.texCoord, profile.textureRoot .. key .. ".tga"
    end
end

local function regionAt(continent, x, y)
    local column = math.min(continent.width - 1, math.floor(x * continent.width))
    local row = math.min(continent.height - 1, math.floor(y * continent.height)) + 1
    local cursor = 0
    for length, label in continent.rows[row]:gmatch("(%d+):(%d+)") do
        cursor = cursor + tonumber(length)
        if column < cursor then
            return continent.names[tonumber(label)]
        end
    end
end

local function normalize(name)
    return name:lower():gsub("^the ", "")
end

function A.MapID(id)
    local profile = A.profile
    profile.continents = profile.continents or {}
    local known = profile.mapIDs[id] or profile.continents[id]
    if known or not C_Map or not C_Map.GetMapChildrenInfo then
        return known
    end
    -- Discover this client's IDs from its map hierarchy instead of borrowing
    -- another client's numeric IDs. Names match the prototype's English content.
    if not profile.discovered then
        profile.discovered = true
        for _, root in ipairs({ 947, 946 }) do
            local ok, maps = pcall(C_Map.GetMapChildrenInfo, root, nil, true)
            for _, info in ipairs(ok and maps or {}) do
                for key, name in pairs(continents) do
                    if info.mapType == 2 and normalize(info.name) == normalize(name) then
                        profile.continents[key] = info.mapID
                    end
                end
                for _, zone in ipairs(W.Content.zones) do
                    if info.mapType == 3 and normalize(info.name) == normalize(zone.name) then
                        profile.mapIDs[zone.id] = info.mapID
                    end
                end
            end
        end
    end
    return profile.mapIDs[id] or profile.continents[id]
end

function A.ZonePosition(zoneID, continentID)
    local _, region = geometry(continentID)
    if region then
        local center = region.centers[zoneID]
        if center then
            return center[1], center[2]
        end
        return nil
    end
    local zone, continent = A.MapID(zoneID), A.MapID(continentID)
    if not zone or not continent or not C_Map then
        return nil
    end
    local ok, left, right, top, bottom
    if C_Map.GetMapRectOnMap then
        ok, left, right, top, bottom = pcall(C_Map.GetMapRectOnMap, zone, continent)
    end
    if
        ok
        and left
        and right
        and top
        and bottom
        and right > left
        and bottom > top
        and left >= 0
        and right <= 1
        and top >= 0
        and bottom <= 1
    then
        return (left + right) / 2, (top + bottom) / 2
    end
end

function A.ZoneAtPosition(continent, x, y)
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 1 or y < 0 or y > 1 then
        return nil
    end
    local mapID = A.MapID(continent)
    if not mapID then
        return nil
    end
    -- The sampled partition is the exact owner field used by the color masks.
    -- It also preserves Classic-only subdivisions absent from Retail map IDs.
    local _, region = geometry(continent)
    if region then
        return W.Content.zoneByID[regionAt(region, x, y)]
    end
    local info = C_Map and C_Map.GetMapInfoAtPosition and C_Map.GetMapInfoAtPosition(mapID, x, y)
    local visited = {}
    while info and not visited[info.mapID] do
        visited[info.mapID] = true
        for _, zone in ipairs(W.Content.zones) do
            if A.MapID(zone.id) == info.mapID then
                return zone
            end
        end
        -- A resolved, unsupported zone must not select an adjacent destination.
        if info.mapType == 3 then
            return nil
        end
        info = C_Map.GetMapInfo and C_Map.GetMapInfo(info.parentMapID)
    end
end

-- Explicit developer action only. No queries run during ordinary gameplay.
-- Sampling native child-map ownership keeps exports independent of this addon's
-- shipped partition, and makes a new client/artwork a data-generation task.
function A.ExportMapGeometry(onDone, width, height)
    if
        not C_Map
        or not C_Map.GetMapInfoAtPosition
        or not C_Map.GetMapArtLayers
        or not C_Map.GetMapArtLayerTextures
    then
        return nil, "Native map queries are unavailable in this client."
    end
    if onDone ~= nil and type(onDone) ~= "function" then
        return nil, "The export callback must be a function."
    end
    width, height = width or 1200, height or 800
    if
        type(width) ~= "number"
        or type(height) ~= "number"
        or width % 1 ~= 0
        or height % 1 ~= 0
        or width < 16
        or height < 16
        or width > 1200
        or height > 800
    then
        return nil, "Export dimensions must be integers between 16 and 1200 by 800."
    end
    local export = { version = 1, profile = A.flavor, build = GetBuildInfo(), continents = {} }
    local mapZones, tasks = {}, {}
    for _, zone in ipairs(W.Content.zones) do
        local mapID = A.MapID(zone.id)
        if mapID then
            mapZones[mapID] = zone.id
        end
    end
    for _, id in ipairs({ "kalimdor", "eastern" }) do
        local mapID = A.MapID(id)
        local layers = mapID and C_Map.GetMapArtLayers(mapID)
        local info = layers and layers[1]
        if not info then
            return nil, "Continent artwork metadata is unavailable."
        end
        local textures = C_Map.GetMapArtLayerTextures(mapID, 1)
        if not textures or type(textures[1]) ~= "number" then
            return nil, "Continent texture metadata is unavailable."
        end
        local task = {
            mapID = mapID,
            artSize = { info.layerWidth, info.layerHeight },
            firstTexture = textures and textures[1],
            size = { width, height },
            names = {},
            rows = {},
        }
        export.continents[id] = task
        tasks[#tasks + 1] = task
    end
    local collector = CreateFrame("Frame")
    local canceled, window, edit
    collector:SetScript("OnHide", function()
        canceled = true
        collector:SetScript("OnUpdate", nil)
    end)
    if not onDone then
        local gui = LibStub("AceGUI-3.0")
        window = gui:Create("Frame")
        window:SetTitle("Map geometry export")
        window:SetWidth(800)
        window:SetHeight(600)
        window:SetLayout("Fill")
        edit = gui:Create("MultiLineEditBox")
        edit:SetLabel("Sampling native map regions. Close to cancel.")
        edit:SetNumLines(24)
        edit:SetFullWidth(true)
        edit:DisableButton(true)
        window:AddChild(edit)
        window:SetCallback("OnClose", function()
            canceled = true
            collector:SetScript("OnUpdate", nil)
            collector:Hide()
            gui:Release(window)
        end)
    end
    local taskIndex, row, indices, mapCache = 1, 0, {}, {}
    local function tagAt(task, x, y)
        local info = C_Map.GetMapInfoAtPosition(task.mapID, x, y)
        local original = info and info.mapID
        if not original or original == task.mapID then
            return nil
        end
        if mapCache[original] then
            return mapCache[original]
        end
        local visited = {}
        while info and not visited[info.mapID] do
            visited[info.mapID] = true
            local zone = mapZones[info.mapID]
            if zone then
                mapCache[original] = zone
                return zone
            end
            info = C_Map.GetMapInfo and C_Map.GetMapInfo(info.parentMapID)
        end
        local tag = "_map_" .. original
        mapCache[original] = tag
        return tag
    end
    local function encode(value)
        if type(value) == "string" then
            return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
        elseif type(value) ~= "table" then
            return tostring(value)
        end
        local parts = {}
        if #value > 0 then
            for _, item in ipairs(value) do
                parts[#parts + 1] = encode(item)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            parts[#parts + 1] = encode(key) .. ":" .. encode(value[key])
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    collector:SetScript("OnUpdate", function()
        if canceled then
            return
        end
        -- Fixed bounded work; collection is cancellable and never persisted.
        for _ = 1, 2 do
            local task = tasks[taskIndex]
            if not task then
                collector:SetScript("OnUpdate", nil)
                collector:Hide()
                if onDone then
                    onDone(export)
                else
                    edit:SetLabel("Copy this JSON to a file outside the addon, then close.")
                    edit:SetText(encode(export))
                end
                return
            end
            local runs, previous, length = {}, -1, 0
            for column = 0, width - 1 do
                local tag = tagAt(task, (column + 0.5) / width, (row + 0.5) / height)
                local label = -1
                if tag then
                    if indices[tag] == nil then
                        indices[tag] = #task.names
                        task.names[#task.names + 1] = tag
                    end
                    label = indices[tag]
                end
                if length > 0 and label ~= previous then
                    runs[#runs + 1] = { length, previous }
                    length = 0
                end
                previous, length = label, length + 1
            end
            runs[#runs + 1] = { length, previous }
            task.rows[#task.rows + 1] = runs
            row = row + 1
            if window then
                window:SetStatusText(
                    "Sampling continent " .. taskIndex .. " / 2 · row " .. row .. " / " .. height
                )
            end
            if row == height then
                taskIndex, row, indices = taskIndex + 1, 0, {}
            end
        end
    end)
    return collector
end
