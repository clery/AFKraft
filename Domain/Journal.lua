local _, W = ...
local G, C, L = W.Game, W.Content, W.L
local rules = C.journal
local floor, min, max = math.floor, math.min, math.max

local monthLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function yearStart(year)
    local previous = year - 1
    return 365 * (year - 1970)
        + floor(previous / 4)
        - floor(1969 / 4)
        - floor(previous / 100)
        + floor(1969 / 100)
        + floor(previous / 400)
        - floor(1969 / 400)
end

-- UTC calendar arithmetic keeps reset dates independent of host timezone and DST.
function G.JournalCalendar(now)
    local day = floor(now / 86400)
    local year = 1970 + floor(day / 365.2425)
    while day < yearStart(year) do
        year = year - 1
    end
    while day >= yearStart(year + 1) do
        year = year + 1
    end
    local remaining, elapsed = day - yearStart(year), yearStart(year)
    for month, base in ipairs(monthLengths) do
        local length = base
            + (month == 2 and year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) and 1 or 0)
        if remaining < length then
            return year * 12 + month - 1, (elapsed + length) * 86400
        end
        remaining, elapsed = remaining - length, elapsed + length
    end
end

local function nowFor(state)
    return W.Client and W.Client.Now() or state.lastTime
end

function G.NewJournal(now)
    return {
        version = 2,
        month = G.JournalCalendar(now),
        pending = {},
        titles = 0,
        bestRank = 0,
        bonusXP = 0,
        xp = 0,
        claimed = 0,
        title = 0,
        day = floor(now / 86400),
        days = {},
        weekly = {},
        achievements = {},
        totals = {},
        zones = {},
    }
end

local function whole(value)
    return type(value) == "number" and value >= 0 and value < 1e12 and value == floor(value)
end

local function dense(values, limit)
    if type(values) ~= "table" or #values > limit then
        return false
    end
    for key in pairs(values) do
        if not whole(key) or key < 1 or key > #values then
            return false
        end
    end
    return true
end

local function counters(values)
    if type(values) ~= "table" then
        return false
    end
    for key, value in pairs(values) do
        if not C.contractByID[key] or not whole(value) then
            return false
        end
    end
    return true
end

local function zoneSet(values)
    if type(values) ~= "table" then
        return false
    end
    local count = 0
    for id, value in pairs(values) do
        count = count + 1
        if not whole(id) or id == 0 or value ~= true or count > 4096 then
            return false
        end
    end
    return true
end

local function validBatch(batch, weekly)
    if
        type(batch) ~= "table"
        or not whole(batch.period)
        or not counters(batch.progress)
        or not zoneSet(batch.zones)
        or type(batch.bonus) ~= "boolean"
        or batch.weekly ~= weekly
        or not dense(batch.ids, 3)
        or #batch.ids ~= 3
    then
        return false
    end
    local seen = {}
    for _, id in ipairs(batch.ids) do
        if not C.contractByID[id] or seen[id] then
            return false
        end
        seen[id] = true
    end
    for id, value in pairs(batch.progress) do
        if not seen[id] or value > C.contractByID[id][weekly and "weekly" or "daily"] then
            return false
        end
    end
    if batch.bonus then
        local completed = 0
        for _, id in ipairs(batch.ids) do
            if (batch.progress[id] or 0) == C.contractByID[id][weekly and "weekly" or "daily"] then
                completed = completed + 1
            end
        end
        if completed < 2 then
            return false
        end
    end
    return true
end

local function validJournal(state)
    local j = state.journal
    if
        type(j) ~= "table"
        or not whole(j.xp)
        or j.xp > rules.ranks * (j.version == nil and 200 or rules.xpPerRank)
        or not whole(j.claimed)
        or j.claimed > floor(j.xp / (j.version == nil and 200 or rules.xpPerRank))
        or not whole(j.day)
        or not dense(j.days, 3)
        or type(j.weekly) ~= "table"
        or type(j.achievements) ~= "table"
        or type(j.totals) ~= "table"
        or not zoneSet(j.zones)
    then
        return false
    end
    local titles = j.version == nil and j.claimed or j.titles
    if
        not whole(titles)
        or j.title ~= 0 and (not whole(j.title) or j.title % 5 ~= 0 or j.title > titles)
    then
        return false
    end
    if j.version ~= nil then
        if
            j.version ~= 2
            or j.month ~= G.JournalCalendar(j.day * 86400)
            or not whole(j.titles)
            or j.titles > rules.ranks
            or j.titles % 5 ~= 0
            or not whole(j.bestRank)
            or j.bestRank > rules.ranks
            or not whole(j.bonusXP)
            or j.bonusXP >= rules.bonusEveryXP
            or type(j.pending) ~= "table"
        then
            return false
        end
        for rank, count in pairs(j.pending) do
            if
                not whole(rank)
                or rank < 1
                or rank > rules.ranks + 1
                or not whole(count)
                or count == 0
            then
                return false
            end
        end
    end
    local previous = -1
    for _, batch in ipairs(j.days) do
        if
            not validBatch(batch, false)
            or batch.period <= previous
            or batch.period > j.day
            or batch.period < j.day - 2
        then
            return false
        end
        previous = batch.period
    end
    if
        next(j.weekly)
        and (not validBatch(j.weekly, true) or j.weekly.period ~= floor((j.day + 3) / 7))
    then
        return false
    end
    local ids = {}
    for _, achievement in ipairs(C.journalAchievements) do
        ids[achievement.id] = true
    end
    for id, value in pairs(j.achievements) do
        if not ids[id] or value ~= true then
            return false
        end
    end
    for id, value in pairs(j.totals) do
        if
            not (C.contractByID[id] or id == "contracts" or id == "crafted" or id == "heirloom")
            or not whole(value)
        then
            return false
        end
    end
    return true
end

function G.ValidateJournal(state)
    if not validJournal(state) then
        return false
    end
    local j = state.journal
    if j.version == nil then
        j.month, j.pending = G.JournalCalendar(j.day * 86400), {}
        j.titles, j.bestRank = floor(j.claimed / 5) * 5, floor(j.xp / 200)
        j.xp, j.bonusXP, j.version = floor(j.xp * rules.xpPerRank / 200), 0, 2
    end
    return true
end

local function supplyHero(state)
    local selected
    for _, hero in ipairs(state.heroes) do
        if not selected or hero.level > selected.level then
            selected = hero
        end
    end
    return selected
end

function G.DeliverJournalSupplies(state)
    local j = state.journal
    if state.offline or not next(j.pending) then
        return
    end
    local supplies = false
    for rank in pairs(j.pending) do
        if rank == rules.ranks + 1 or rank % 5 ~= 0 and rank % 4 ~= 0 then
            supplies = true
            break
        end
    end
    local hero = supplies and supplyHero(state)
    if not hero then
        return
    end
    local cost = G.Cost(state, hero, false)
    for rank, count in pairs(j.pending) do
        if rank == rules.ranks + 1 then
            state.gold = state.gold + cost.gold * 2 * count
            for material in pairs(state.materials) do
                state.materials[material] = state.materials[material] + cost.material * 2 * count
            end
            j.pending[rank] = nil
            G.Log(state, L.JOURNAL_BONUS_DELIVERED, nil, "rewards")
            G.Emit(
                state,
                "journalReward",
                { heading = L.JOURNAL_REWARD, title = L.JOURNAL_BONUS_DELIVERED }
            )
        elseif rank % 5 ~= 0 and rank % 4 ~= 0 then
            if rank % 2 == 0 then
                for material in pairs(state.materials) do
                    state.materials[material] = state.materials[material]
                        + cost.material * 10 * count
                end
            else
                state.gold = state.gold + cost.gold * 10 * count
            end
            j.pending[rank] = nil
        end
    end
end

function G.JournalRewardRank(state)
    for rank = 1, rules.ranks do
        if state.journal.pending[rank] then
            return rank, true
        end
    end
    local rank = state.journal.claimed + 1
    if rank <= G.JournalRank(state) then
        return rank, false
    end
end

function G.JournalRewardsWaiting(state)
    local count = G.JournalRank(state) - state.journal.claimed
    for rank, pending in pairs(state.journal.pending) do
        if rank <= rules.ranks then
            count = count + pending
        end
    end
    return count
end

local function batch(period, weekly)
    -- Two broadly available objectives; the third offers a different activity.
    return {
        period = period,
        ids = { "quest", "kill", C.contracts[3 + period % 4].id },
        progress = {},
        zones = {},
        bonus = false,
        weekly = weekly,
    }
end

function G.RefreshJournal(state, now)
    local j = state.journal
    local day = max(j.day, floor(now / 86400))
    local renewed = false
    if day ~= j.day then
        local month = G.JournalCalendar(day * 86400)
        if month > j.month then
            local rank = G.JournalRank(state)
            j.bestRank = max(j.bestRank, rank)
            j.titles = max(j.titles, floor(rank / 5) * 5)
            for reward = j.claimed + 1, rank do
                j.pending[reward] = (j.pending[reward] or 0) + 1
            end
            j.xp, j.claimed, j.bonusXP, j.month = 0, 0, 0, month
            renewed = true
        end
    end
    if not W.catchup then
        G.DeliverJournalSupplies(state)
    end
    local week = floor((day + 3) / 7)
    if day == j.day and #j.days > 0 and j.weekly.period == week then
        return
    end
    local first = #j.days > 0 and j.days[#j.days].period + 1 or j.day
    local retained = {}
    for _, entry in ipairs(j.days) do
        if entry.period >= day - 2 then
            retained[#retained + 1] = entry
        end
    end
    for period = max(first, day - 2), day do
        retained[#retained + 1] = batch(period, false)
    end
    j.days, j.day = retained, day
    if j.weekly.period ~= week then
        j.weekly = batch(week, true)
    end
    if renewed then
        G.Log(state, L.JOURNAL_RESET_NOTICE, nil, "progress")
        G.Emit(state, "journal", { heading = L.JOURNAL_NAME, title = L.JOURNAL_RESET_NOTICE })
    end
end

function G.JournalRank(state)
    return min(rules.ranks, floor(state.journal.xp / rules.xpPerRank))
end

local function awardXP(state, amount)
    local j = state.journal
    local total = j.xp + amount
    local overflow = max(0, total - rules.ranks * rules.xpPerRank)
    j.xp = min(rules.ranks * rules.xpPerRank, total)
    j.bestRank = max(j.bestRank, G.JournalRank(state))
    j.bonusXP = j.bonusXP + overflow
    local supplies = floor(j.bonusXP / rules.bonusEveryXP)
    j.bonusXP = j.bonusXP % rules.bonusEveryXP
    if supplies > 0 then
        j.pending[rules.ranks + 1] = (j.pending[rules.ranks + 1] or 0) + supplies
        if not W.catchup then
            G.DeliverJournalSupplies(state)
        end
    end
end

function G.JournalMetric(state, metric)
    if metric == "heroes" then
        return #state.heroes
    end
    if metric == "best" then
        return state.best
    end
    if metric == "prestiges" then
        return state.prestiges
    end
    if metric == "rank" then
        return max(state.journal.bestRank, G.JournalRank(state))
    end
    if metric == "crafted" then
        return max(state.guide.crafted and 1 or 0, state.journal.totals.crafted or 0)
    end
    if metric == "heirloom" then
        for _, item in ipairs(state.inventory) do
            if item.heirloom then
                return 1
            end
        end
        for _, hero in ipairs(state.heroes) do
            for _, item in pairs(hero.gear) do
                if item.heirloom then
                    return 1
                end
            end
        end
    end
    return state.journal.totals[metric] or 0
end

function G.CheckJournalAchievements(state)
    if state.offline then
        return
    end
    G.RefreshJournal(state, nowFor(state))
    for _, achievement in ipairs(C.journalAchievements) do
        if
            not state.journal.achievements[achievement.id]
            and G.JournalMetric(state, achievement.metric) >= achievement.target
        then
            state.journal.achievements[achievement.id] = true
            awardXP(state, rules.achievementXP)
            G.Log(
                state,
                achievement.name .. " · +" .. rules.achievementXP .. " " .. L.JOURNAL_XP,
                nil,
                "progress"
            )
            G.Emit(state, "journal", { heading = L.JOURNAL_ACHIEVEMENT, title = achievement.name })
        end
    end
end

local function advance(state, entry, kind, zone)
    local weekly = entry.weekly
    for _, id in ipairs(entry.ids) do
        local target = C.contractByID[id][weekly and "weekly" or "daily"]
        local count = entry.progress[id] or 0
        if id == kind and count < target and (kind ~= "explore" or not entry.zones[zone]) then
            if zone then
                entry.zones[zone] = true
            end
            entry.progress[id] = count + 1
            if count + 1 == target then
                local xp = weekly and rules.weeklyXP or rules.dailyXP
                awardXP(state, xp)
                local totals = state.journal.totals
                totals.contracts = (totals.contracts or 0) + 1
                G.Log(
                    state,
                    C.contractByID[id].name .. " · +" .. xp .. " " .. L.JOURNAL_XP,
                    nil,
                    "rewards"
                )
                G.Emit(
                    state,
                    "journal",
                    { heading = L.JOURNAL_CONTRACT_COMPLETE, title = C.contractByID[id].name }
                )
                local completed = 0
                for _, objective in ipairs(entry.ids) do
                    if
                        (entry.progress[objective] or 0)
                        >= C.contractByID[objective][weekly and "weekly" or "daily"]
                    then
                        completed = completed + 1
                    end
                end
                if not weekly and completed >= 2 and not entry.bonus then
                    entry.bonus = true
                    awardXP(state, rules.bonusXP)
                    G.Log(
                        state,
                        L.JOURNAL_DAILY_BONUS .. " · +" .. rules.bonusXP .. " " .. L.JOURNAL_XP,
                        nil,
                        "rewards"
                    )
                end
            end
            return true
        end
    end
    return false
end

function G.JournalActivity(state, kind, now, zone)
    if state.offline or not C.contractByID[kind] then
        return
    end
    if kind == "explore" and (not whole(zone) or zone == 0) then
        return
    end
    G.RefreshJournal(state, now)
    local j = state.journal
    if kind ~= "explore" or not j.zones[zone] then
        j.totals[kind] = (j.totals[kind] or 0) + 1
        if zone then
            j.zones[zone] = true
        end
    end
    -- One activity advances one saved daily batch, plus the current weekly.
    for _, entry in ipairs(j.days) do
        if advance(state, entry, kind, zone) then
            break
        end
    end
    advance(state, j.weekly, kind, zone)
    G.CheckJournalAchievements(state)
end

function G.JournalReward(rank, state, heroIndex)
    if rank == 20 then
        return L.JOURNAL_HEIRLOOM_REWARD
    end
    if rank % 5 == 0 then
        return L.JOURNAL_RECIPE_REWARD
    end
    if rank % 4 == 0 then
        return L.JOURNAL_UPGRADE_REWARD
    end
    local hero = state.heroes[heroIndex or 1]
    local cost = G.Cost(state, hero, false)
    if rank % 2 == 0 then
        return string.format(L.JOURNAL_MATERIAL_REWARD, cost.material * 10)
    end
    return string.format(L.JOURNAL_GOLD_REWARD, cost.gold * 10)
end

function G.ClaimJournalReward(state, heroIndex, slot)
    G.RefreshJournal(state, nowFor(state))
    local j = state.journal
    local rank, saved = G.JournalRewardRank(state)
    if not rank then
        return false, L.JOURNAL_NOT_READY
    end
    heroIndex, slot = heroIndex or 1, slot or 1
    local hero = state.heroes[heroIndex]
    if not hero or not C.slots[slot] then
        return false, L.CHOOSE_A_HERO_AND_EQUIPMENT_SLOT
    end
    local item
    if rank == 20 or rank % 4 == 0 and not hero.gear[slot] then
        local reason
        item, reason = G.CraftItem(hero, slot, rank == 20, state)
        if not item then
            return false, reason
        end
    end
    local message = G.JournalReward(rank, state, heroIndex)
    local cost = G.Cost(state, hero, false)
    if saved then
        j.pending[rank] = j.pending[rank] - 1
        if j.pending[rank] == 0 then
            j.pending[rank] = nil
        end
    else
        j.claimed = rank
    end
    if rank % 5 == 0 then
        if rank > j.titles then
            j.title = rank
        end
        j.titles = max(j.titles, rank)
        if rank ~= 20 then
            if state.recipes[slot] then
                state.legacy = state.legacy + 1
                message = L.JOURNAL_DUPLICATE_RECIPE
            else
                state.recipes[slot] = true
                G.Emit(state, "unlock")
            end
        end
    end
    if item then
        item.uid, state.nextItem = state.nextItem, state.nextItem + 1
        item.protected = true
        state.inventory[#state.inventory + 1] = item
        G.Emit(state, "item", { item = item })
    elseif rank % 4 == 0 and rank ~= 20 then
        local equipped = hero.gear[slot]
        equipped.upgrade = (equipped.upgrade or 0) + 1
        G.RefreshHero(state, heroIndex)
        G.Emit(state, "upgrade")
    elseif rank % 5 ~= 0 then
        if rank % 2 == 0 then
            for material in pairs(state.materials) do
                state.materials[material] = state.materials[material] + cost.material * 10
            end
        else
            state.gold = state.gold + cost.gold * 10
        end
    end
    G.CheckJournalAchievements(state)
    G.Emit(state, "journalReward", { heading = L.JOURNAL_REWARD, title = message })
    return true, message
end

function G.SetJournalTitle(state, rank)
    if rank ~= 0 and (not whole(rank) or rank % 5 ~= 0 or rank > state.journal.titles) then
        return false
    end
    state.journal.title = rank
    return true
end

function G.JournalEvent(state, event)
    if state.offline then
        return
    end
    if event.kind == "craft" then
        local totals = state.journal.totals
        totals.crafted = (totals.crafted or 0) + 1
        if event.item and event.item.heirloom then
            totals.heirloom = 1
        end
    end
    if
        event.kind == "craft"
        or event.kind == "victory"
        or event.kind == "recruit"
        or event.kind == "prestige"
    then
        G.CheckJournalAchievements(state)
    end
end
