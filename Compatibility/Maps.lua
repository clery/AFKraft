local _, W = ...
local A = W.Client
local continents = { kalimdor = "Kalimdor", eastern = "Eastern Kingdoms" }
-- Centers and region outlines on Retail's continent artwork. World-space map
-- rectangles include margins and do not reliably follow these painted borders.
-- Outlines are used only when the client cannot resolve a region at the cursor.
local retailRegions = {
    durotar = {
        "kalimdor",
        0.585,
        0.480,
        { 0.568, 0.460, 0.603, 0.465, 0.614, 0.512, 0.598, 0.554, 0.574, 0.548, 0.563, 0.504 },
    },
    barrens = {
        "kalimdor",
        0.535,
        0.555,
        { 0.477, 0.490, 0.535, 0.488, 0.563, 0.520, 0.560, 0.583, 0.533, 0.616, 0.492, 0.588 },
    },
    ashenvale = {
        "kalimdor",
        0.505,
        0.405,
        {
            0.439,
            0.367,
            0.492,
            0.351,
            0.552,
            0.380,
            0.568,
            0.426,
            0.541,
            0.463,
            0.488,
            0.449,
            0.441,
            0.422,
        },
    },
    desolace = {
        "kalimdor",
        0.420,
        0.605,
        { 0.394, 0.546, 0.438, 0.548, 0.461, 0.594, 0.445, 0.650, 0.392, 0.663, 0.376, 0.613 },
    },
    tanaris = {
        "kalimdor",
        0.545,
        0.895,
        {
            0.512,
            0.831,
            0.566,
            0.815,
            0.590,
            0.856,
            0.588,
            0.929,
            0.551,
            0.968,
            0.508,
            0.950,
            0.491,
            0.890,
        },
    },
    winterspring = {
        "kalimdor",
        0.575,
        0.245,
        {
            0.537,
            0.180,
            0.583,
            0.150,
            0.619,
            0.180,
            0.624,
            0.263,
            0.601,
            0.316,
            0.559,
            0.307,
            0.539,
            0.257,
        },
    },
    elwynn = {
        "eastern",
        0.475,
        0.770,
        { 0.443, 0.758, 0.483, 0.753, 0.507, 0.776, 0.501, 0.805, 0.454, 0.812, 0.435, 0.787 },
    },
    westfall = {
        "eastern",
        0.430,
        0.835,
        { 0.394, 0.792, 0.435, 0.787, 0.454, 0.812, 0.444, 0.873, 0.414, 0.889, 0.393, 0.851 },
    },
    redridge = {
        "eastern",
        0.530,
        0.785,
        { 0.507, 0.755, 0.551, 0.751, 0.566, 0.787, 0.548, 0.817, 0.501, 0.805, 0.507, 0.776 },
    },
    duskwood = {
        "eastern",
        0.480,
        0.835,
        { 0.454, 0.812, 0.501, 0.805, 0.548, 0.817, 0.535, 0.855, 0.493, 0.876, 0.444, 0.873 },
    },
    wetlands = {
        "eastern",
        0.475,
        0.570,
        {
            0.453,
            0.548,
            0.501,
            0.533,
            0.557,
            0.551,
            0.563,
            0.602,
            0.523,
            0.631,
            0.477,
            0.621,
            0.443,
            0.585,
        },
    },
    stranglethorn = {
        "eastern",
        0.485,
        0.890,
        { 0.444, 0.873, 0.493, 0.876, 0.511, 0.909, 0.490, 0.957, 0.455, 0.980, 0.433, 0.938 },
    },
}

local function contains(outline, x, y)
    local inside = false
    local j = #outline - 1
    for i = 1, #outline, 2 do
        local xi, yi, xj, yj = outline[i], outline[i + 1], outline[j], outline[j + 1]
        if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
            inside = not inside
        end
        j = i
    end
    return inside
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
    local region = A.flavor == "retail" and retailRegions[zoneID]
    if region then
        if region[1] == continentID then
            return region[2], region[3]
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
    if A.flavor == "retail" then
        for _, zone in ipairs(W.Content.zones) do
            local region = retailRegions[zone.id]
            if region and region[1] == continent and contains(region[4], x, y) then
                return zone
            end
        end
    end
end
