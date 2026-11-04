-- Earned progression: lua scripts/balance_journey.lua [hours=24] [policy=invest] [seed=17]
-- No starting funds/items/points. Activity rates include assumed travel and downtime.
local B = dofile("scripts/balance_common.lua")
local G, C = B.G, B.C
local hours, policy, seed = tonumber(arg[1]) or 24, arg[2] or "invest", tonumber(arg[3]) or 17
local plans = {
    passive = { cadence = 3600, activity = false, spend = false },
    builder = { cadence = 900, activity = false, spend = true, reset = 12, ascend = true, adaptive = true },
    invest = { cadence = 900, activity = true, spend = true },
    short = { cadence = 900, activity = true, spend = true, reset = 20 },
    deep = { cadence = 900, activity = true, spend = true, reset = 12, ascend = true, adaptive = true },
    casual = { cadence = 3600, activity = true, spend = true, reset = 12, ascend = true, adaptive = true },
    returning = { cadence = 3600, activity = true, spend = true, reset = 12, ascend = true, adaptive = true, offline = true },
}
local plan = assert(plans[policy], "Unknown policy")
assert(hours >= 1 and hours <= 100 and hours == math.floor(hours))
io.stdout:setvbuf("line")
local s = G.New(0)
s.seed = seed
assert(G.AddHero(s, "WARRIOR"))
local metrics = {
    commands = 0,
    checkins = 0,
    crafts = 0,
    upgrades = 0,
    enchants = 0,
    forges = 0,
    resets = 0,
    ascensions = 0,
    defeats = 0,
    wallSeconds = 0,
    goldSpent = 0,
    maxTier = 0,
    lastReset = 0,
    legacyEarned = 0,
    inheritanceEarned = 0,
    lastFrontier = 0,
    stalled = 0
}
local function command(ok)
    if ok then metrics.commands = metrics.commands + 1 end
    return ok
end
local function buyWork(index)
    local hero = s.heroes[index]
    local opportunity = G.CraftingOpportunity(s, index)
    if opportunity then
        if command(G.Craft(s, index, opportunity.slot, opportunity.material, opportunity.heirloom)) then
            metrics.crafts = metrics.crafts + 1
            command(G.EquipBest(s, index))
        end
    end
    -- One purchase per track/hero/check-in, never churn crafts/enchant replacements for XP.
    for _, slot in ipairs(C.equipmentSlots) do
        local item = hero.gear[slot]
        if item then
            if (item.upgrade or 0) < 5 and command(G.Upgrade(s, index, slot)) then
                metrics.upgrades = metrics.upgrades + 1
                break
            end
        end
    end
    for _, slot in ipairs(C.equipmentSlots) do
        local item = hero.gear[slot]
        if item and not item.enchant and command(G.Enchant(s, index, slot, "offense")) then
            metrics.enchants = metrics.enchants + 1
            break
        end
    end
    for _, slot in ipairs(C.equipmentSlots) do
        local item = hero.gear[slot]
        if item and (item.forge or 0) < 2 and command(G.Titanforge(s, index, slot)) then
            metrics.forges = metrics.forges + 1
            break
        end
    end
end
local function permanent()
    for _, id in ipairs({ "battleOrders", "ironResolve", "focusedAssault", "restorativeFocus" }) do
        if not s.boosts.owned[id] then
            local learned = G.BuyBoost(s, id)
            if not learned and s.legacy >= 1 then learned = G.BuyBoost(s, id, "legacy") end
            command(learned)
        end
    end
    for _, branch in ipairs(C.development) do
        command(G.BuyDevelopment(s, branch.id))
        if s.development.ranks[branch.id] >= 3 then
            command(G.SetDevelopmentChoice(s, branch.id, branch.choices[1].id))
        end
    end
    if s.legacy > 0 then
        if not s.boosts.automation.owned.onCooldown then
            command(G.BuyBoostAutomation(s, "onCooldown"))
        end
        if not s.routes.owned then command(G.BuyRoutes(s)) end
        for _, slot in ipairs(C.equipmentSlots) do
            if not s.recipes[slot] then command(G.UnlockRecipe(s, slot)) end
        end
        for _, talent in ipairs(C.collectionTalents) do command(G.BuyCollectionTalent(s, talent.id)) end
    end
    if s.boosts.owned.focusedAssault then
        command(G.EquipBoost(s, "focusedAssault"))
        if s.boosts.automation.owned.onCooldown then
            command(G.ConfigureBoostAutomation(s, "focusedAssault", "enabled", true))
            command(G.SetBoostAutomationEnabled(s, true))
        else
            command(G.ActivateBoost(s, "focusedAssault", true))
        end
    end
    for _, id in ipairs({ "rebuilding", "supplies" }) do command(G.BuyInheritance(s, id)) end
end
local function travel()
    -- Rotate resource shortages. Choose the highest safely accessible native destination
    -- for that material; never set frontiers/safe records or fabricate material income.
    local desired = "ore"
    if s.materials.relic < 20 and s.professions.owned.enchanting then desired = "relic" end
    if s.materials[desired] > 80 then return end
    local target
    for _, zone in ipairs(C.zones) do
        if zone.material == desired and G.IsUnlocked(s, zone)
            and zone.level <= math.max(1, s.runBest - 3)
            and (not target or zone.level > target.level) then
            target = zone
        end
    end
    if target and target.id ~= s.zone then command(G.Travel(s, target.id)) end
end
local discovered = {}
local function milestones(second)
    G.ProfessionUnlocks(s)
    local available = {
        Mastery = s.professions.bestLevel >= 20,
        Commander = not G.FeatureHint(s, "boosts"),
        Enchanting = s.professions.owned.enchanting,
        Titanforging = s.professions.owned.titanforging,
        Specializations = s.professions.owned.research,
        Automation = not G.FeatureHint(s, "onCooldown"),
        Conditional = not G.FeatureHint(s, "conditional"),
        Routes = not G.FeatureHint(s, "routes"),
        Heirlooms = not G.FeatureHint(s, "heirlooms"),
    }
    for _, name in ipairs({ "Mastery", "Commander", "Enchanting", "Automation", "Titanforging", "Specializations", "Conditional", "Routes", "Heirlooms" }) do
        if available[name] and not discovered[name] then
            discovered[name] = true
            print(string.format("UNLOCK | %.2fh | %s", second / 3600, name))
        end
    end
end
local function checkin(second)
    milestones(second)
    metrics.checkins = metrics.checkins + 1
    metrics.lastWall = s.farming
    while #s.heroes < G.CompanionSlots(s) do
        assert(command(G.Recruit(s, B.classes[#s.heroes + 1])))
    end
    metrics.stalled = s.runBest <= metrics.lastFrontier and s.farming and metrics.stalled + 1 or 0
    metrics.lastFrontier = s.runBest
    local gold = s.gold
    if plan.spend then permanent() end
    for index, hero in ipairs(s.heroes) do
        if plan.spend then
            B.talents(s, index, hero.class == "PRIEST" and 2 or 1)
            G.ConfigurePreset(s, index, hero.class == "PRIEST" and "support" or "offense")
        end
        G.EquipBest(s, index)
        if plan.spend then buyWork(index) end
    end
    metrics.goldSpent = metrics.goldSpent + gold - s.gold
    if plan.spend then
        for _, profession in ipairs(C.professions) do
            for _, branch in ipairs(profession.branches) do
                command(G.AllocateProfession(s, profession.id, branch.id))
            end
        end
    end
    local awaitingCap = plan.ascend and s.runBest >= 60 and not s.difficulty.cycleComplete
    local target = plan.adaptive and math.min(60, plan.reset + s.prestiges * 3) or plan.reset
    local eligible = G.PrestigePlusPreview(s, math.min(10, s.tier + 1))
    if plan.ascend and eligible.eligible and eligible.inheritance > 0 then
        local inheritance = eligible.inheritance
        print(string.format("ASCEND | %.2fh | tier %d -> %d | +%d Inheritance", second / 3600, s.tier,
            eligible.targetTier, inheritance))
        assert(command(G.PrestigePlus(s, eligible.targetTier)))
        metrics.ascensions = metrics.ascensions + 1
        metrics.inheritanceEarned = metrics.inheritanceEarned + inheritance
        metrics.maxTier = math.max(metrics.maxTier, s.tier)
        metrics.lastReset, metrics.lastFrontier, metrics.stalled = second, 0, 0
    elseif plan.reset and not awaitingCap and s.prestigeUnlocked and G.PrestigeReward(s) > 0
        and ((s.runBest >= target and (not plan.ascend or s.runBest < 60)) or metrics.stalled >= 1) then
        local reward = G.PrestigeReward(s)
        local level = 1
        for _, hero in ipairs(s.heroes) do level = math.max(level, hero.level) end
        print(string.format("RESET | %.2fh | frontier %d | hero %d | +%d Legacy", second / 3600, s.runBest, level, reward))
        assert(command(G.Prestige(s)))
        metrics.resets = metrics.resets + 1
        metrics.legacyEarned = metrics.legacyEarned + reward
        metrics.lastReset, metrics.lastFrontier, metrics.stalled = second, 0, 0
    elseif awaitingCap then
        command(G.Travel(s, C.transcendenceBoss.zone))
    elseif plan.spend then
        travel()
    end
    if s.farming then command(G.Retry(s)) end
    assert(G.Load(G.Copy(s), second), "Check-in must leave a loadable save")
end
print("Earned journey; activity 8 quests/80 kills/4 nodes per hour when enabled; no synthetic hunts.")
print(
    "Policy | Seed | Hours | Tier/max | Hero levels | Frontier | Gold/spent | Craft/upgrade/enchant/forge | Reset/deep | Legacy/Inheritance earned | Defeats | Wall hours | Successful calls/checkins")
checkin(0)
local second = 1
while second <= hours * 3600 do
    if plan.offline and second % 86400 == 3601 then
        local untilTime = math.min(hours * 3600, second - 3601 + 86400)
        s.lastTime = second - 1
        local job = G.BeginCatchup(s, untilTime)
        if job then
            while not G.CatchupBatch(job, 1600) do end
            assert(G.FinishCatchup(s, job))
            metrics.wallSeconds = metrics.wallSeconds + job.seconds
        end
        second = untilTime
    else
        if plan.activity then
            for _, activity in ipairs({ { "quest", 8 }, { "kill", 80 }, { "gather", 4 } }) do
                if math.floor(second * activity[2] / 3600) > math.floor((second - 1) * activity[2] / 3600) then
                    G.AdventureXP(s, C.activityRewards[activity[1]].xp, activity[1], "Journey model")
                end
            end
        end
        G.Advance(s, 1)
        for _, event in ipairs(s.events) do
            if event.kind == "defeat" then metrics.defeats = metrics.defeats + 1 end
        end
        s.events = {}
        if s.farming then metrics.wallSeconds = metrics.wallSeconds + 1 end
    end
    if second % plan.cadence == 0 then checkin(second) end
    if second == 3600 or second == 21600 or second == 86400 or second == hours * 3600 then
        local low, high = 60, 1
        for _, hero in ipairs(s.heroes) do low, high = math.min(low, hero.level), math.max(high, hero.level) end
        print(string.format(
            "%s | %d | %.1f | %d/%d | %d-%d | %d | %d/%d | %d/%d/%d/%d | %d/%d | %d/%d | %d | %.2f | %d/%d",
            policy, seed, second / 3600, s.tier, metrics.maxTier, low, high, s.runBest, s.gold, metrics.goldSpent,
            metrics.crafts, metrics.upgrades, metrics.enchants, metrics.forges, metrics.resets, metrics.ascensions,
            metrics.legacyEarned, metrics.inheritanceEarned, metrics.defeats, metrics.wallSeconds / 3600,
            metrics.commands, metrics.checkins))
    end
    second = second + 1
end
assert(G.Load(G.Copy(s), hours * 3600))
assert(plan.activity or s.adventure.totalXP == 0)
assert(s.gold >= 0 and s.essence >= 0 and s.legacy >= 0)

-- Compare a real stalled account with reinvesting its own unspent stock; no extra funding.
if plan.spend and metrics.lastWall and metrics.lastReset < hours * 3600 then
    local rescue = G.Copy(s)
    local stage = (s.safe[s.zone] or 0) + 1
    local level = C.zoneByID[s.zone].level + math.floor((stage - 1) / 5)
    local before, seconds = B.fight(rescue, level, nil, nil, stage)
    local gold, spent = rescue.gold, 0
    for index, hero in ipairs(rescue.heroes) do
        for _, slot in ipairs(C.equipmentSlots) do
            local item = hero.gear[slot]
            if item then
                while (item.upgrade or 0) < 20 do
                    if not G.Upgrade(rescue, index, slot) then break end
                    spent = spent + 1
                end
                while (item.forge or 0) < C.forgeCap do
                    if not G.Titanforge(rescue, index, slot) then break end
                    spent = spent + 1
                end
            end
        end
    end
    local after, improvedSeconds = B.fight(rescue, level, nil, nil, stage)
    assert(G.Load(G.Copy(rescue), hours * 3600))
    print(string.format(
        "Earned wall intervention | level %d tier %d | before %s %.2fs | after %s %.2fs | paid %d gold/%d modifications",
        level, s.tier, tostring(before), seconds, tostring(after), improvedSeconds, gold - rescue.gold, spent))
end
