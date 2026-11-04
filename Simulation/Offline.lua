local _, W = ...
local G = W.Game
local min, max, floor = math.min, math.max, math.floor
local copy = G.Copy

local function inventoryCount(state)
    local count = 0
    for _, item in ipairs(state.inventory) do
        count = count + (item.count or 1)
    end
    return count
end

function G.BeginCatchup(state, now)
    local seconds = min(86400, max(0, now - (state.lastTime or now)))
    -- Clock rollback must not create earnings once the clock catches up again.
    state.lastTime = max(state.lastTime or now, now)
    if #state.heroes == 0 or seconds < 2 then
        return nil
    end
    local safe = state.safe[state.zone]
    if not safe then
        return nil
    end
    local snapshot = copy(state)
    snapshot.events = {}
    snapshot.battle = nil
    snapshot.rest = 0
    snapshot.pauseAfter = nil
    snapshot.stage = safe
    snapshot.farming = true
    snapshot.offline = true
    snapshot.offlineRoute = {
        safe = copy(state.safe),
        tier = state.tier,
        transitions = 0,
    }
    return {
        state = snapshot,
        remaining = floor(seconds / 0.25),
        seconds = seconds,
        gold = snapshot.gold,
        victories = snapshot.stats.victories,
        boostUses = snapshot.stats.boostUses or 0,
        fragments = snapshot.professions.fragments,
        salvaged = snapshot.stats.salvaged,
        materials = copy(snapshot.materials),
        inventoryCount = inventoryCount(snapshot),
    }
end

function G.CatchupBatch(job, steps)
    if job.finished then
        return true
    end
    local n = min(job.remaining, steps or 1600)
    for _ = 1, n do
        G.Step(job.state, 0.25)
    end
    job.remaining = job.remaining - n
    job.state.events = {}
    return job.remaining == 0
end

function G.FinishCatchup(state, job)
    if job.finished then
        return false
    end
    local earned = job.state
    local previousHeroes = state.heroes
    for key, value in pairs(state.discoveries) do
        earned.discoveries[key] = value
    end
    -- Adventure XP lives on the live account state, outside the idle snapshot.
    earned.stats.essence = state.stats.essence
    for _, key in ipairs({
        "heroes",
        "inventory",
        "nextItem",
        "gold",
        "materials",
        "materialRemainders",
        "collectionBook",
        "professions",
        "difficulty",
        "discoveries",
        "seed",
        "clock",
        "encounter",
        "boosts",
        "stats",
        "log",
    }) do
        state[key] = earned[key]
    end
    if earned.routes.offlineEnabled then
        state.routes.run = earned.routes.run
        if earned.offlineRoute.transitions > 0 then
            state.zone, state.stage, state.farming = earned.zone, earned.stage, true
        end
    end
    for i, hero in ipairs(earned.heroes) do
        local previous = previousHeroes[i]
        if previous and previous.level < G.LevelCap(hero) and hero.level == G.LevelCap(hero) then
            G.Log(
                state,
                hero.name
                    .. " reached idle level "
                    .. hero.level
                    .. " (character maximum) while you were away. Mastery continues in harder encounters."
            )
        end
    end
    if job.remaining > 0 then
        state.lastTime = state.lastTime - job.remaining * 0.25
    end
    state.battle = nil
    state.rest = 1
    local routeReady, routeReason, routeStep = G.RouteStatus(earned)
    local summary = {
        seconds = job.seconds - job.remaining * 0.25,
        remainingSeconds = job.remaining * 0.25,
        interrupted = job.remaining > 0,
        heroXP = 0,
        heroLevels = 0,
        itemsKept = max(0, inventoryCount(state) - (job.inventoryCount or inventoryCount(state))),
        boostUses = (state.stats.boostUses or 0) - (job.boostUses or 0),
        fragments = max(
            0,
            state.professions.fragments - (job.fragments or state.professions.fragments)
        ),
        collectionMode = "outdoor",
        discoveries = 0,
        upgrades = 0,
        masteryRanks = 0,
        masteryXP = 0,
        gold = state.gold - job.gold,
        victories = state.stats.victories - job.victories,
        salvaged = state.stats.salvaged - (job.salvaged or state.stats.salvaged),
        materials = {},
        routeTransitions = earned.offlineRoute.transitions,
        routesWaiting = state.routes.enabled and routeStep ~= nil and not routeReady,
        routeStatus = routeReason,
    }
    for material, amount in pairs(state.materials) do
        summary.materials[material] = amount - ((job.materials or {})[material] or amount)
    end
    -- Outdoor hunting is live-only; the live ledger is never replaced by this snapshot.
    for index, hero in ipairs(state.heroes) do
        local previous = previousHeroes[index]
        if previous then
            summary.heroXP = summary.heroXP
                + max(
                    0,
                    45 * (hero.level - previous.level) * (hero.level + previous.level - 1) / 2
                        + hero.xp
                        - previous.xp
                )
            summary.heroLevels = summary.heroLevels + max(0, hero.level - previous.level)
        end
        summary.masteryRanks = summary.masteryRanks
            + math.max(
                0,
                (hero.mastery and hero.mastery.rank or 0)
                    - (previous and previous.mastery and previous.mastery.rank or 0)
            )
        local current, before = hero.mastery, previous and previous.mastery
        if current and before then
            local ranks = current.rank - before.rank
            local gained = current.xp - before.xp
            if ranks > 0 then
                gained = gained
                    + ranks
                        * (W.Content.mastery.baseXP + (current.rank + before.rank - 1) * W.Content.mastery.xpPerRank / 2)
            end
            if gained >= 0 and gained < math.huge then
                summary.masteryXP = summary.masteryXP + gained
            end
        end
    end
    state.lastOfflineSummary = summary
    -- Offline farming never unlocks destinations or bosses.
    G.Log(
        state,
        "Welcome back. "
            .. floor((job.seconds - job.remaining * 0.25) / 60)
            .. " minutes away · +"
            .. (state.gold - job.gold)
            .. " gold · "
            .. (state.stats.victories - job.victories)
            .. " victories · "
            .. summary.boostUses
            .. " boost uses · "
            .. summary.masteryRanks
            .. " Mastery ranks (+"
            .. summary.masteryXP
            .. " XP) · "
            .. summary.salvaged
            .. " salvaged."
            .. " "
            .. summary.routeTransitions
            .. " offline route transitions."
    )
    job.finished = true
    return true
end
