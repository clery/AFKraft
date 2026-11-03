local _, W = ...
local G = W.Game
local min, max, floor = math.min, math.max, math.floor
local copy = G.Copy

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
    return {
        state = snapshot,
        remaining = floor(seconds / 0.25),
        seconds = seconds,
        gold = snapshot.gold,
        victories = snapshot.stats.victories,
        boostUses = snapshot.stats.boostUses or 0,
        salvaged = snapshot.stats.salvaged,
        materials = copy(snapshot.materials),
        collectionPieces = copy(snapshot.collectionBook.pieces),
    }
end

function G.CatchupBatch(job, steps)
    local n = min(job.remaining, steps or 1600)
    for _ = 1, n do
        G.Step(job.state, 0.25)
    end
    job.remaining = job.remaining - n
    job.state.events = {}
    return job.remaining == 0
end

function G.FinishCatchup(state, job)
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
    for i, hero in ipairs(earned.heroes) do
        local previous = previousHeroes[i]
        if previous and previous.level < G.LevelCap(hero) and hero.level == G.LevelCap(hero) then
            G.Log(
                state,
                hero.name
                    .. " reached idle level "
                    .. hero.level
                    .. (
                        hero.level == W.Content.heroLevelCap
                            and " (character maximum) while you were away. Mastery continues in harder encounters."
                        or " (maximum) while you were away. Train to raise the level cap."
                    )
            )
        end
    end
    if job.remaining > 0 then
        state.lastTime = state.lastTime - job.remaining * 0.25
    end
    state.battle = nil
    state.rest = 1
    local summary = {
        boostUses = (state.stats.boostUses or 0) - (job.boostUses or 0),
        discoveries = 0,
        upgrades = 0,
        masteryRanks = 0,
        masteryXP = 0,
        gold = state.gold - job.gold,
        victories = state.stats.victories - job.victories,
        salvaged = state.stats.salvaged - (job.salvaged or state.stats.salvaged),
        materials = {},
        routeTransitions = 0,
        routesWaiting = state.routes.enabled,
    }
    for material, amount in pairs(state.materials) do
        summary.materials[material] = amount - ((job.materials or {})[material] or amount)
    end
    for itemID, tier in pairs(state.collectionBook.pieces) do
        local previous = (job.collectionPieces or {})[itemID]
        if previous == nil then
            summary.discoveries = summary.discoveries + 1
        elseif tier > previous then
            summary.upgrades = summary.upgrades + 1
        end
    end
    for index, hero in ipairs(state.heroes) do
        local previous = previousHeroes[index]
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
            .. " salvaged · "
            .. summary.discoveries
            .. " collection discoveries, "
            .. summary.upgrades
            .. " upgrades."
            .. (state.routes.enabled and " Routes wait while offline." or "")
    )
end
