local _, W = ...
local C = W.Content
local G = {}
W.Game = G
local floor = math.floor

local function copy(t)
    if type(t) ~= "table" then
        return t
    end
    local r = {}
    for k, v in pairs(t) do
        r[k] = copy(v)
    end
    return r
end
G.Copy = copy

function G.Random(state, n)
    state.seed = (state.seed * 16807) % 2147483647
    return floor(state.seed / 2147483647 * n) + 1
end

function G.Emit(state, kind, data)
    if not state.events then
        state.events = {}
    end
    data = data or {}
    data.kind = kind
    if W.OnGameEvent then
        W.OnGameEvent(state, data)
    end
    state.events[#state.events + 1] = data
    if #state.events > 60 then
        table.remove(state.events, 1)
    end
end

function G.New(now)
    return {
        version = C.version,
        itemStatsVersion = 1,
        guide = {
            dismissed = false,
            equipped = false,
            talent = false,
            traveled = false,
            crafted = false,
        },
        seed = floor(now) % 2147483646 + 1,
        heroes = {},
        inventory = {},
        nextItem = 1,
        essence = 0,
        adventure = { rank = 1, xp = 0, totalXP = 0, sources = {} },
        gold = 0,
        legacy = 0,
        prestiges = 0,
        materials = { timber = 0, hide = 0, ore = 0, relic = 0 },
        discoveries = {},
        recipes = {},
        best = 1,
        runBest = 1,
        zone = "elwynn",
        stage = 1,
        safe = {},
        battle = nil,
        clock = 0,
        encounter = 0,
        paused = false,
        lastTime = now,
        salvage = { minQuality = 2, keepUpgrades = true, keepEffects = true },
        ui = { compact = false, locked = false, tab = "adventure" },
        settings = {
            chatAnnouncements = true,
            combatText = true,
            soundEnabled = true,
            soundCombat = true,
            soundSpells = true,
            soundDeaths = true,
            soundEncounters = true,
            soundProgression = true,
            soundEquipment = true,
            soundTravel = true,
        },
        stats = { kills = 0, victories = 0, salvaged = 0, essence = 0 },
        identities = {},
        seenRewards = {},
        rewardOrder = {},
        log = { "A new legend begins. Choose your companions." },
    }
end

function G.Log(state, message, quiet)
    state.log[#state.log + 1] = message
    if #state.log > 24 then
        table.remove(state.log, 1)
    end
    if not quiet and W.OnLog then
        W.OnLog(state, message)
    end
end

function G.Load(db, now)
    if type(db) ~= "table" then
        return G.New(now)
    end
    local migrated = db.version == 1
    if migrated then
        -- Previously paid Essence and hero XP are retained, not awarded again.
        db = copy(db)
        db.version = C.version
        db.adventure = { rank = 1, xp = 0, totalXP = 0, sources = {} }
    elseif db.version ~= C.version then
        return nil, "This save belongs to an unsupported version. It has not been changed."
    end
    local existingGuide = type(db.guide) == "table"
    local needsItemMigration = db.itemStatsVersion ~= 1
    local defaults = G.New(now)
    for k, v in pairs(defaults) do
        if db[k] == nil then
            db[k] = copy(v)
        elseif type(db[k]) ~= type(v) then
            return nil,
                "The saved adventure has an invalid " .. k .. " field. It has not been reset."
        end
    end
    for key, value in pairs(defaults.guide) do
        if type(db.guide[key]) ~= "boolean" then
            db.guide[key] = value
        end
    end
    for _, key in ipairs({ "craftItem", "craftHero" }) do
        local value = db.guide[key]
        if type(value) ~= "number" or value <= 0 or value >= math.huge or value ~= floor(value) then
            db.guide[key] = nil
        end
    end
    if not existingGuide then
        -- Existing adventures retain their party and can opt into the guide.
        db.guide.dismissed = true
        db.guide.traveled = db.zone ~= "elwynn"
        for _, hero in ipairs(db.heroes) do
            db.guide.equipped = db.guide.equipped or next(hero.gear or {}) ~= nil
            db.guide.talent = db.guide.talent or next(hero.talents or {}) ~= nil
        end
    end
    for key, value in pairs(defaults.settings) do
        if type(db.settings[key]) ~= "boolean" then
            db.settings[key] = value
        end
    end
    if not C.zoneByID[db.zone] then
        return nil, "The saved destination is unknown. Your adventure has not been reset."
    end
    local progress = db.adventure
    local function whole(value)
        return type(value) == "number"
            and value >= 0
            and value < math.huge
            and value == floor(value)
    end
    local function points(value)
        return type(value) == "number" and whole(value * 4)
    end
    if
        not whole(progress.rank)
        or not points(progress.xp)
        or not points(progress.totalXP)
        or progress.rank ~= 1 + floor(progress.totalXP / C.adventure.xpPerRank)
        or progress.xp ~= progress.totalXP % C.adventure.xpPerRank
        or type(progress.sources) ~= "table"
    then
        return nil, "The saved Adventure XP is invalid. Your adventure has not been reset."
    end
    if migrated then
        G.Log(db, "Adventure XP unlocked. Existing Essence and hero progression retained.")
    end
    -- A terminal encounter cannot normally be saved: Step resolves it in the
    -- same call. Older versions could throw after partially applying victory
    -- rewards. Discard that finished encounter instead of replaying its payout.
    if type(db.battle) == "table" and type(db.battle.enemies) == "table" then
        local finished = #db.battle.enemies > 0
        for _, enemy in ipairs(db.battle.enemies) do
            if type(enemy.hp) ~= "number" or enemy.hp > 0 then
                finished = false
                break
            end
        end
        if finished then
            db.battle = nil
            db.rest = 0
            G.Log(db, "The party regrouped and is ready to continue.")
        end
    end
    -- Purge excluded equipment from older saves, including protected stacks and heirlooms.
    local removedItems = {
        [13094] = true,
        [13095] = true,
        [13097] = true,
        [13002] = true,
        [13085] = true,
        [13096] = true,
        [833] = true,
    }
    local function excluded(item)
        return type(item) == "table"
            and (item.slot == 5 or item.slot == 6 or removedItems[item.itemID])
    end
    local function clearCraftTarget(item)
        if type(item) == "table" and db.guide.craftItem == item.uid then
            db.guide.craftItem, db.guide.craftHero = nil, nil
        end
    end
    for index = #db.inventory, 1, -1 do
        local item = db.inventory[index]
        if excluded(item) then
            clearCraftTarget(item)
            table.remove(db.inventory, index)
        end
    end
    for _, hero in ipairs(db.heroes) do
        for slot, item in pairs(hero.gear or {}) do
            if slot == 5 or slot == 6 or excluded(item) then
                clearCraftTarget(item)
                hero.gear[slot] = nil
                -- Restart without rewards rather than retaining combat stats from removed gear.
                db.battle, db.rest = nil, 0
            end
        end
    end
    db.recipes[5], db.recipes[6] = nil, nil
    local function migrateItem(item)
        if type(item) ~= "table" or type(item.stats) == "table" then
            return
        end
        local power = type(item.power) == "number" and item.power or 0
        if power < 0 or power >= math.huge or power ~= power then
            power = 0
        end
        -- Preserve old gear rather than replacing paid upgrades or protected stacks.
        item.stats = (item.slot == 2 or item.slot == 3)
                and { stamina = power * 0.6, armor = power * 16 }
            or { weaponDPS = power * 0.65 }
        item.power = nil
    end
    for _, item in ipairs(db.inventory) do
        migrateItem(item)
    end
    for _, hero in ipairs(db.heroes) do
        local talentProgress, errorMessage = G.TalentProgress(hero)
        if not talentProgress then
            return nil, errorMessage
        end
        local missingMastery = hero.mastery == nil
        local mastery, masteryError = G.MasteryProgress(hero)
        if not mastery then
            return nil, masteryError
        end
        if missingMastery and db.runBest >= 1 and db.runBest < math.huge then
            mastery.frontier = math.max(0, floor(db.runBest) - 1)
        end
        if hero.level > C.heroLevelCap then
            -- Older uncapped levels become Mastery ranks without taking away
            -- their existing talent budget or allocated build.
            if
                type(hero.xp) ~= "number"
                or hero.xp < 0
                or hero.xp >= math.huge
                or hero.xp ~= floor(hero.xp)
            then
                return nil,
                    "The saved hero experience is invalid. Your adventure has not been reset."
            end
            mastery.rank = mastery.rank + hero.level - C.heroLevelCap
            mastery.xp = math.min(hero.xp, G.MasteryCost(mastery.rank) - 1)
            hero.level, hero.xp = C.heroLevelCap, 0
            db.battle, db.rest = nil, 0
        end
        G.AppearanceSeed(hero)
        for _, item in pairs(hero.gear or {}) do
            migrateItem(item)
        end
    end
    for _, hero in ipairs(db.heroes) do
        if G.ReturnUnusableGear(db, hero) then
            db.battle, db.rest = nil, 0
        end
    end
    if needsItemMigration then
        db.battle = nil
        db.rest = 0
        db.itemStatsVersion = 1
    end
    db.paused, db.pauseAfter = false, nil
    db.events = nil
    return db
end
