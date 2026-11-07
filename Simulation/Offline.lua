local _, W = ...
local L = W.L
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
    snapshot.stage = state.farming and state.stage % 5 == 0 and math.min(safe, state.stage) or safe
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
        components = copy(snapshot.professions.components),
        salvaged = snapshot.stats.salvaged,
        materials = copy(snapshot.materials),
        inventoryCount = inventoryCount(snapshot),
        chestCount = G.ChestCount(snapshot),
    }
end

-- Builds cannot be edited inside a catch-up snapshot. Only these combat inputs change.
local function combatKey(state)
    local key = { state.zone, state.stage, state.tier, G.CompanionSlots(state) }
    local boundary = math.huge
    local id = state.boosts.equipped
    local config = id and state.boosts.automation.abilities[id]
    for boost, deadline in pairs(state.boosts.activeUntil) do
        if deadline > state.clock then
            key[#key + 1] = boost
            boundary = min(boundary, deadline)
        end
    end
    if config and config.enabled and state.boosts.automation.enabled then
        local readyAt = state.boosts.readyAt[id] or 0
        key[#key + 1] = readyAt <= state.clock and "ready" or "cooldown"
        if readyAt > state.clock then
            boundary = min(boundary, readyAt)
        end
    end
    for i, hero in ipairs(state.heroes) do
        key[#key + 1] = hero.level
        key[#key + 1] = state.battle.heroes[i].hp
    end
    return table.concat(key, ":"), boundary
end

local function catchupStep(job, available)
    local state, battle = job.state, job.state.battle
    if (state.rest or 0) > 0 then
        local ticks = min(available, math.ceil(state.rest / 0.25))
        state.clock = state.clock + ticks * 0.25
        state.rest = max(0, state.rest - ticks * 0.25)
        job.skippedTicks = (job.skippedTicks or 0) + ticks
        return ticks
    end
    if battle and battle.elapsed == 0 then
        local key, boundary = combatKey(state)
        if key then
            local sample = job.combats and job.combats[key]
            if
                sample
                and sample.ticks <= available
                and state.clock + sample.ticks * 0.25 <= boundary
            then
                state.clock = state.clock + sample.ticks * 0.25
                state.battle = copy(sample.battle)
                G.CombatVictory(state, state.battle)
                job.skippedTicks = (job.skippedTicks or 0) + sample.ticks
                return sample.ticks
            end
            job.sample = {
                key = key,
                battle = battle,
                clock = state.clock,
                boundary = boundary,
                victories = state.stats.victories,
                boostUses = state.stats.boostUses,
            }
        end
    end
    G.Step(state, 0.25)
    local sample = job.sample
    if sample and not state.battle then
        job.sample = nil
        if
            state.stats.victories == sample.victories + 1
            and state.stats.boostUses == sample.boostUses
            and state.clock <= sample.boundary
        then
            sample.ticks = floor((state.clock - sample.clock) / 0.25 + 0.5)
            job.combats = job.combats or {}
            job.combatKeys = job.combatKeys or {}
            if not job.combats[sample.key] then
                -- Bound transient memory even when health never settles into a short cycle.
                local slot = (job.combatCursor or 0) % 512 + 1
                local previous = job.combatKeys[slot]
                if previous then
                    job.combats[previous] = nil
                end
                job.combatKeys[slot], job.combatCursor = sample.key, slot
            end
            job.combats[sample.key] = sample
        end
    end
    return 1
end

function G.CatchupBatch(job, steps, shouldYield)
    if job.finished then
        return true
    end
    local n = min(job.remaining, steps or 1600)
    while n > 0 do
        local processed = catchupStep(job, n)
        n = n - processed
        job.remaining = job.remaining - processed
        if shouldYield and shouldYield() then
            break
        end
    end
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
        "chests",
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
                    .. L.FRAGMENT_REACHED_IDLE_LEVEL
                    .. hero.level
                    .. L.CHARACTER_MAXIMUM_WHILE_YOU_WERE_AWAY_MASTERY_CONTINUES_IN_SUFFIX,
                nil,
                "progress"
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
        heroGains = {},
        chests = max(0, G.ChestCount(state) - (job.chestCount or 0)),
        itemsKept = max(0, inventoryCount(state) - (job.inventoryCount or inventoryCount(state))),
        boostUses = (state.stats.boostUses or 0) - (job.boostUses or 0),
        fragments = max(
            0,
            state.professions.fragments - (job.fragments or state.professions.fragments)
        ),
        components = {},
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
    for zone, amount in pairs(state.professions.components) do
        local gained = amount - ((job.components or {})[zone] or 0)
        if gained > 0 then
            summary.components[zone] = gained
        end
    end
    -- Outdoor hunting is live-only; the live ledger is never replaced by this snapshot.
    for index, hero in ipairs(state.heroes) do
        local previous = previousHeroes[index]
        if previous then
            local gainedXP = hero.xp - previous.xp
            for level = previous.level, hero.level - 1 do
                gainedXP = gainedXP + G.LevelXP(level)
            end
            summary.heroXP = summary.heroXP + max(0, gainedXP)
            summary.heroLevels = summary.heroLevels + max(0, hero.level - previous.level)
        end
        if
            previous and (hero.level > previous.level or hero.mastery.rank > previous.mastery.rank)
        then
            summary.heroGains[#summary.heroGains + 1] = {
                hero = index,
                level = hero.level,
                levels = max(0, hero.level - previous.level),
                masteryRanks = max(0, hero.mastery.rank - previous.mastery.rank),
            }
        end
        for _, slot in ipairs(W.Content.equipmentSlots) do
            local item = hero.gear[slot]
            if item then
                local cost = G.UpgradeCost(item, state)
                if
                    state.gold >= cost.gold
                    and state.materials.ore >= cost.materials.ore
                    and (job.gold < cost.gold or job.materials.ore < cost.materials.ore)
                then
                    local gain = G.ItemPower(item, hero, 1) - G.ItemPower(item, hero)
                    if not summary.enhancement or gain > summary.enhancement.gain then
                        summary.enhancement = {
                            hero = index,
                            slot = slot,
                            uid = item.uid,
                            upgrade = item.upgrade or 0,
                            gain = gain,
                        }
                    end
                end
            end
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
                for rank = before.rank, current.rank - 1 do
                    gained = gained + G.MasteryCost(rank)
                end
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
        L.WELCOME_BACK_PREFIX
            .. floor((job.seconds - job.remaining * 0.25) / 60)
            .. L.MINUTES_AWAY_SUFFIX
            .. (state.gold - job.gold)
            .. L.FRAGMENT_GOLD
            .. (state.stats.victories - job.victories)
            .. L.FRAGMENT_VICTORIES
            .. summary.boostUses
            .. L.FRAGMENT_BOOST_USES
            .. summary.masteryRanks
            .. L.MASTERY_RANKS_SUFFIX
            .. summary.masteryXP
            .. L.XP_HEADING
            .. summary.salvaged
            .. L.SALVAGED_SUFFIX
            .. " "
            .. summary.routeTransitions
            .. L.OFFLINE_ROUTE_TRANSITIONS_SUFFIX,
        nil,
        "offline"
    )
    G.CheckJournalAchievements(state)
    G.DeliverJournalSupplies(state)
    job.finished = true
    return true
end
