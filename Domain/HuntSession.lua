local _, W = ...
local G, C = W.Game, W.Content
local sessions = setmetatable({}, { __mode = "k" })

local function whole(value)
    return type(value) == "number"
        and value >= 0
        and value <= 1000000000000
        and value == math.floor(value)
end

local function validFinds(report, kind)
    if
        type(report) ~= "table"
        or not whole(report.kills)
        or not whole(report.discoveries)
        or type(report.pieces) ~= "table"
    then
        return false
    end
    local count = 0
    for itemID, found in pairs(report.pieces) do
        local setID = C.collectionByItem[itemID]
        local collection = setID and C.collectionByID[setID]
        if not collection or (collection.kind or "outdoor") ~= kind or found ~= true then
            return false
        end
        count = count + 1
    end
    return count == report.discoveries
end

function G.ValidateHuntSummary(state)
    local report = state.lastHuntSummary
    if report == nil then
        return true
    end
    if
        not validFinds(report, "outdoor")
        or not whole(report.seconds)
        or (report.dungeon ~= nil and not validFinds(report.dungeon, "dungeon"))
        or (report.adventureXP ~= nil and (type(report.adventureXP) ~= "number" or not whole(
            report.adventureXP * 4
        )))
        or (report.essence ~= nil and not whole(report.essence))
    then
        return false
    end
    return true
end

local function timestamp(value)
    return type(value) == "number" and value >= 0 and value <= 1000000000000
end

function G.BeginHuntSession(state, now)
    if not timestamp(now) or state.offline then
        return false
    end
    if sessions[state] then
        return true
    end
    sessions[state] = {
        started = math.floor(now),
        kills = state.outdoorCollections.stats.kills,
        adventureXP = state.adventure.totalXP,
        essence = state.stats.essence or 0,
        pieces = G.Copy(state.outdoorCollections.pieces),
        dungeon = {
            kills = state.dungeonCollections.stats.kills,
            pieces = G.Copy(state.dungeonCollections.pieces),
        },
    }
    return true
end

function G.HuntSessionSummary(state, now)
    local session = sessions[state]
    if not session or not timestamp(now) or state.offline then
        return nil
    end
    local report = {
        seconds = math.max(0, math.floor(now) - session.started),
        kills = math.max(0, state.outdoorCollections.stats.kills - session.kills),
        discoveries = 0,
        adventureXP = math.max(0, state.adventure.totalXP - session.adventureXP),
        essence = math.max(0, (state.stats.essence or 0) - session.essence),
        pieces = {},
        dungeon = {
            kills = math.max(0, state.dungeonCollections.stats.kills - session.dungeon.kills),
            discoveries = 0,
            pieces = {},
        },
    }
    for itemID in pairs(state.outdoorCollections.pieces) do
        if not session.pieces[itemID] then
            report.pieces[itemID] = true
            report.discoveries = report.discoveries + 1
        end
    end
    for itemID in pairs(state.dungeonCollections.pieces) do
        if not session.dungeon.pieces[itemID] then
            report.dungeon.pieces[itemID] = true
            report.dungeon.discoveries = report.dungeon.discoveries + 1
        end
    end
    return report
end

function G.HasSessionProgress(report)
    return report ~= nil
        and (
            report.kills > 0
            or (report.adventureXP or 0) > 0
            or (report.essence or 0) > 0
            or report.discoveries > 0
            or (
                report.dungeon ~= nil
                and (report.dungeon.kills > 0 or report.dungeon.discoveries > 0)
            )
        )
end

function G.SaveHuntSession(state, now)
    local report = G.HuntSessionSummary(state, now)
    if not G.HasSessionProgress(report) then
        return false
    end
    state.lastHuntSummary = report
    return true
end
