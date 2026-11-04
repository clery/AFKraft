local _, W = ...
local L = W.L
local A, G = W.Client, W.Game
local K = { units = {}, order = {}, tokens = {} }
W.KillRewards = K

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

function K.AtCap()
    local maximum = UnitXPMax and UnitXPMax("player")
    if readable(maximum) and type(maximum) == "number" and maximum == 0 then
        return true
    end
    if UnitLevel and GetMaxPlayerLevel then
        local level, cap = UnitLevel("player"), GetMaxPlayerLevel()
        return readable(level)
            and readable(cap)
            and type(level) == "number"
            and type(cap) == "number"
            and cap > 0
            and level >= cap
    end
    return false
end

local function participated(unit)
    if UnitIsTappedByPlayer then
        local tapped = UnitIsTappedByPlayer(unit)
        if readable(tapped) and tapped == true then
            return true
        end
    end
    if UnitThreatSituation then
        for _, source in ipairs({ "player", "pet" }) do
            local threat = UnitThreatSituation(source, unit)
            if readable(threat) and type(threat) == "number" then
                return true
            end
        end
    end
    return false
end

function K.Observe(state, unit)
    if
        not (
            K.AtCap()
            or (
                W.CollectionSources
                and (
                    W.CollectionSources.ActiveProfile()
                    or W.CollectionSources.ActiveProfile("dungeon")
                )
            )
        )
        or not UnitIsDead
        or not UnitIsTrivial
        or not UnitIsTapDenied
        or not UnitCanAttack
        or not UnitPlayerControlled
    then
        return
    end
    local guid, dead, denied = UnitGUID(unit), UnitIsDead(unit), UnitIsTapDenied(unit)
    if
        not readable(guid)
        or not readable(dead)
        or not readable(denied)
        or type(guid) ~= "string"
        or guid == ""
    then
        return
    end
    local record = K.units[guid]
    if dead then
        local lootCredit = false
        if CanLootUnit then
            local _, canLoot = CanLootUnit(guid)
            lootCredit = readable(canLoot) and canLoot == true
        end
        local eligible = record and record.eligible and A.Now() - record.seen <= 120
        if lootCredit and not eligible then
            local trivial, controlled = UnitIsTrivial(unit), UnitPlayerControlled(unit)
            eligible = readable(trivial) and readable(controlled) and not trivial and not controlled
        end
        -- Loot rights also prove participation for one-shot kills, whose threat
        -- entry can disappear before a unit event observes it.
        local collectionEligible = record
            and record.collectionEligible
            and A.Now() - record.seen <= 120
        if lootCredit and not collectionEligible then
            local controlled = UnitPlayerControlled(unit)
            collectionEligible = readable(controlled) and not controlled
        end
        if
            collectionEligible
            and not denied
            and (lootCredit or (record and record.participated))
            and W.CollectionSources
        then
            W.CollectionSources.ObserveKill(state, guid)
        end
        if
            K.AtCap()
            and eligible
            and not denied
            and (lootCredit or (record and record.participated))
        then
            G.ActivityReward(state, "kill:" .. guid, "kill", L["Non-trivial creature defeated"])
        end
        return
    end
    local trivial, controlled, attackable =
        UnitIsTrivial(unit), UnitPlayerControlled(unit), UnitCanAttack("player", unit)
    if not readable(trivial) or not readable(controlled) or not readable(attackable) then
        return
    end
    if not record then
        record = {}
        K.units[guid] = record
        K.order[#K.order + 1] = guid
        if #K.order > 128 then
            K.units[table.remove(K.order, 1)] = nil
        end
    end
    record.collectionEligible = not controlled and attackable and not denied
    record.eligible = not trivial and not controlled and attackable and not denied
    record.participated = record.participated or participated(unit)
    record.seen = A.Now()
end

function K.Event(state, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        K.Observe(state, "target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        K.Observe(state, "mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        if readable(unit) and type(unit) == "string" then
            K.Observe(state, unit)
            K.tokens[unit] = event == "NAME_PLATE_UNIT_ADDED" or nil
        end
    elseif
        event == "UNIT_HEALTH"
        or event == "UNIT_FLAGS"
        or event == "UNIT_THREAT_LIST_UPDATE"
    then
        if readable(unit) and type(unit) == "string" then
            K.Observe(state, unit)
        end
    end
end

function K.Tick(state)
    if
        K.AtCap()
        or (
            W.CollectionSources
            and (
                W.CollectionSources.ActiveProfile() or W.CollectionSources.ActiveProfile("dungeon")
            )
        )
    then
        for _, unit in ipairs({ "target", "focus", "mouseover", "softenemy" }) do
            K.Observe(state, unit)
        end
        for unit in pairs(K.tokens) do
            K.Observe(state, unit)
        end
    end
end
