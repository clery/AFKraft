local _, W = ...
local L = W.L
local A, G = W.Client, W.Game
local D = { observed = {}, order = {} }
W.DungeonRewards = D
local events = {
    "LFG_COMPLETION_REWARD",
    "CHALLENGE_MODE_COMPLETED",
    "ENCOUNTER_START",
    "PLAYER_ENTERING_WORLD",
}

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

local function number(value)
    return readable(value) and type(value) == "number" and value > 0
end

local function legacyLoot()
    if C_Loot and C_Loot.IsLegacyLootModeEnabled then
        local legacy = C_Loot.IsLegacyLootModeEnabled()
        return not readable(legacy) or legacy == true
    end
    return false
end

local function context()
    if not GetInstanceInfo then
        return nil
    end
    local values = { GetInstanceInfo() }
    if not readable(values[2]) or not readable(values[3]) or not readable(values[8]) then
        return nil
    end
    return { kind = values[2], difficulty = values[3], map = values[8], lfgID = values[10] }
end

local function rangeFor(id, instance, direct)
    if not number(id) or not GetLFGDungeonInfo then
        return nil
    end
    local info = { GetLFGDungeonInfo(id) }
    local low, high, difficulty, map = info[7], info[8], info[12], info[22]
    if
        not number(low)
        or not number(high)
        or high < low
        or not readable(map)
        or map ~= instance.map
    then
        return nil
    end
    if not direct then
        if not readable(difficulty) or not readable(info[3]) then
            return nil
        end
        local matches = difficulty == instance.difficulty
            or (instance.difficulty == 1 and info[3] == 1 and difficulty == 0)
            or (instance.difficulty == 2 and info[3] == 2)
        if not matches then
            return nil
        end
    end
    -- Portal admission limits can be effectively unlimited. Only use the
    -- recommended bracket, which represents the intended content level range.
    if GetMaxPlayerLevel then
        local cap = GetMaxPlayerLevel()
        if number(cap) and high > cap then
            return nil
        end
    end
    if not readable(info[18]) or not readable(info[21]) then
        return nil
    end
    return { low = low, high = high, scaling = info[18] == true or info[21] == true }
end

function D.LevelRange(instance)
    local direct = rangeFor(instance.lfgID, instance, true)
    if direct then
        return direct
    end
    if GetLFDChoiceOrder then
        for _, id in ipairs(GetLFDChoiceOrder() or {}) do
            local range = rangeFor(id, instance, false)
            if range then
                return range
            end
        end
    end
end

function D.Eligible(instance)
    if not instance or (instance.kind ~= "party" and instance.kind ~= "raid") then
        return false
    end
    if legacyLoot() then
        return false
    end
    local range = D.LevelRange(instance)
    if not range then
        return false
    end
    local level
    if not range.scaling and UnitEffectiveLevel then
        level = UnitEffectiveLevel("player")
    elseif UnitLevel then
        level = UnitLevel("player")
    end
    return number(level) and level >= range.low and level <= range.high
end

local function observe(unit)
    if not UnitExists or not UnitIsTrivial then
        return nil
    end
    local exists = UnitExists(unit)
    if not readable(exists) or not exists then
        return nil
    end
    if UnitIsDead then
        local dead = UnitIsDead(unit)
        if readable(dead) and dead then
            return nil
        end
    end
    if UnitPlayerControlled then
        local controlled = UnitPlayerControlled(unit)
        if readable(controlled) and controlled then
            return nil
        end
    end
    local trivial = UnitIsTrivial(unit)
    if not readable(trivial) or type(trivial) ~= "boolean" then
        return nil
    end
    local name = UnitName(unit)
    if readable(name) and type(name) == "string" and name ~= "" then
        if not D.observed[name] then
            D.order[#D.order + 1] = name
            if #D.order > 32 then
                D.observed[table.remove(D.order, 1)] = nil
            end
        end
        D.observed[name] = { eligible = not trivial, time = A.Now() }
    end
    return not trivial
end

function D.Tick()
    local any, known = false, false
    for i = 1, 5 do
        local eligible = observe("boss" .. i)
        if eligible ~= nil then
            any, known = any or eligible, true
        end
    end
    if known and D.encounter then
        D.encounter.eligible, D.encounter.time = any, A.Now()
    end
    observe("target")
    return known and any or nil, known
end

function D.BossEligible(id, name)
    local instance = context()
    if not instance then
        return false
    end
    if legacyLoot() then
        return false
    end
    local eligible, known = D.Tick()
    if
        D.encounter
        and D.encounter.id == id
        and D.encounter.eligible ~= nil
        and A.Now() - D.encounter.time <= 30
    then
        eligible, known = D.encounter.eligible, true
    elseif readable(name) and type(name) == "string" then
        local record = D.observed[name]
        if record and A.Now() - record.time <= 30 then
            eligible, known = record.eligible, true
        end
    end
    if not known then
        eligible = D.Eligible(instance)
    end
    if instance.kind == "party" or instance.kind == "raid" then
        if not D.run or D.run.map ~= instance.map or D.run.difficulty ~= instance.difficulty then
            D.run = { map = instance.map, difficulty = instance.difficulty }
        end
        if D.run.map == instance.map and D.run.difficulty == instance.difficulty then
            D.run.known, D.run.eligible = true, D.run.eligible or eligible == true
        end
    end
    return eligible == true
end

function D.Register(frame)
    for _, event in ipairs(events) do
        if C_EventUtils and C_EventUtils.IsEventValid then
            if C_EventUtils.IsEventValid(event) then
                frame:RegisterEvent(event, "OnGameEvent")
            end
        elseif A.flavor == "retail" then
            frame:RegisterEvent(event, "OnGameEvent")
        end
    end
end

function D.Event(state, event, id)
    if event == "PLAYER_ENTERING_WORLD" then
        D.observed, D.order, D.run, D.encounter = {}, {}, nil, nil
        return
    elseif event == "ENCOUNTER_START" then
        if number(id) then
            D.encounter = { id = id, time = A.Now() }
            D.Tick()
        end
        return
    end
    if event ~= "LFG_COMPLETION_REWARD" and event ~= "CHALLENGE_MODE_COMPLETED" then
        return
    end
    local instance = context()
    if not instance or instance.kind ~= "party" or legacyLoot() then
        return
    end
    local eligible = D.Eligible(instance)
    if
        D.run
        and D.run.map == instance.map
        and D.run.difficulty == instance.difficulty
        and D.run.known
    then
        eligible = D.run.eligible == true
    elseif D.encounter and D.encounter.eligible ~= nil and A.Now() - D.encounter.time <= 30 then
        eligible = D.encounter.eligible
    end
    if not eligible then
        return
    end
    -- Completion requires an explicit server signal. Never infer it from leaving
    -- an instance, a loading screen, or a guessed final-boss mapping.
    local now, identity = A.Now(), A.Identity()
    local receipt = state.adventure.dungeonReceipt
    if receipt and receipt.character == identity.guid and now - receipt.time < 30 then
        return
    end
    local instanceID = instance.map
    if not readable(instanceID) or type(instanceID) ~= "number" then
        instanceID = 0
    end
    local key = "dungeon:" .. identity.guid .. ":" .. instanceID .. ":" .. now
    if G.ActivityReward(state, key, "dungeon", L.DUNGEON_COMPLETED) then
        state.adventure.dungeonReceipt = { character = identity.guid, time = now }
    end
end
