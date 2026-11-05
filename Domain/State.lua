local _, W = ...
local L = W.L
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
        economyVersion = 1,
        development = {
            ranks = { might = 0, resolve = 0, provisioning = 0 },
            choices = {},
            invested = 0,
        },
        guide = {
            dismissed = false,
            equipped = false,
            talent = false,
            traveled = false,
            crafted = false,
            lessonBoost = false,
            lessonAutomation = false,
            lessonProfiles = false,
            lessonRoutes = false,
            lessonCollections = false,
            lessonHunt = false,
            lessonEnchanting = false,
            lessonTitanforging = false,
            lessonResearch = false,
            lessonPrestigePlus = false,
            lessonLegacy = false,
            lessonMastery = false,
            lessonDevelopment = false,
        },
        seed = floor(now) % 2147483646 + 1,
        heroes = {},
        inventory = {},
        nextItem = 1,
        essence = 0,
        adventure = { rank = 1, xp = 0, totalXP = 0, sources = {} },
        gold = 0,
        legacy = 0,
        collectionTalents = {},
        prestiges = 0,
        prestigeStrength = 0,
        materials = { timber = 0, hide = 0, ore = 0, relic = 0 },
        materialRemainders = {},
        routes = {
            offlineEnabled = false,
            owned = false,
            enabled = false,
            templates = {},
            nextID = 1,
            run = { cursor = 1, completed = {}, paused = false },
        },
        boostProfiles = { nextID = 1, entries = {} },
        tier = 0,
        difficulty = {
            unlocked = false,
            maxTier = 0,
            records = {},
            cycleComplete = false,
            finalBossEncounter = 0,
            ascensions = 0,
            currency = 0,
            purchases = {},
        },
        professions = {
            fragments = 0,
            components = {},
            lastComponentEncounter = 0,
            recipes = {},
            lastFragmentEncounter = 0,
            owned = {},
            ranks = { crafting = 0, enchanting = 0, titanforging = 0 },
            xp = { crafting = 0, enchanting = 0, titanforging = 0 },
            allocations = { crafting = {}, enchanting = {}, titanforging = {} },
            bestLevel = 1,
        },
        outdoorCollections = {
            version = 1,
            pieces = {},
            counters = {},
            receipts = {},
            stats = { kills = 0, discoveries = 0 },
        },
        dungeonCollections = {
            version = 1,
            pieces = {},
            counters = {},
            receipts = {},
            stats = { kills = 0, discoveries = 0 },
        },
        collectionBook = {
            pieces = {},
            counters = {},
            receipts = {},
            receiptOrder = {},
            lastEncounter = 0,
        },
        discoveries = {},
        recipes = {},
        best = 1,
        unlocks = { companions = 1, zones = {} },
        runBest = 1,
        zone = "elwynn",
        stage = 1,
        safe = {},
        battle = nil,
        clock = 0,
        boosts = {
            owned = {},
            readyAt = {},
            activeUntil = {},
            automation = copy(C.boostAutomationDefaults),
        },
        encounter = 0,
        paused = false,
        lastTime = now,
        salvage = {
            minQuality = 2,
            keepUpgrades = true,
            keepEffects = true,
            policy = { class = "any", slot = 0, stat = "any" },
        },
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
        stats = { kills = 0, victories = 0, salvaged = 0, essence = 0, boostUses = 0 },
        identities = {},
        seenRewards = {},
        rewardOrder = {},
        log = { L.A_NEW_LEGEND_BEGINS_CHOOSE_YOUR_COMPANIONS },
    }
end

function G.Log(state, message, quiet, noticeType)
    state.log[#state.log + 1] = message
    if #state.log > 24 then
        table.remove(state.log, 1)
    end
    if not quiet and W.OnLog then
        W.OnLog(state, message, noticeType)
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
        return nil, L.THIS_SAVE_BELONGS_TO_AN_UNSUPPORTED_VERSION_IT_HAS
    end
    local needsTalentMigration = false
    for _, hero in ipairs(type(db.heroes) == "table" and db.heroes or {}) do
        if type(hero) == "table" and hero.talentRanksVersion == nil then needsTalentMigration = true end
    end
    local previousEconomy = db.economyVersion
    if
        previousEconomy == nil
        or needsTalentMigration
        or db.unlocks == nil
        or db.outdoorCollections == nil
        or db.dungeonCollections == nil
        or (type(db.routes) == "table" and db.routes.offlineEnabled == nil)
        or (
            type(db.professions) == "table"
            and (
                db.professions.fragments == nil
                or db.professions.recipes == nil
                or db.professions.lastFragmentEncounter == nil
            )
        )
    then
        db = copy(db)
    end
    local existingGuide = type(db.guide) == "table"
    local needsItemMigration = db.itemStatsVersion ~= 1
    if db.prestigeStrength == nil then
        -- Existing rewarded chapters retain their full advertised party bonus.
        db.prestigeStrength = db.prestiges or 0
    end
    local legacyUnlocks = db.unlocks == nil
    local defaults = G.New(now)
    for k, v in pairs(defaults) do
        if db[k] == nil then
            if k ~= "outdoorCollections" then
                db[k] = copy(v)
            end
        elseif type(db[k]) ~= type(v) then
            return nil,
                L.THE_SAVED_ADVENTURE_HAS_AN_INVALID_PREFIX
                    .. k
                    .. L.FIELD_IT_HAS_NOT_BEEN_RESET_SUFFIX
        end
    end
    if db.salvage.policy == nil then
        db.salvage.policy = copy(defaults.salvage.policy)
    end
    local strength = db.prestigeStrength
    if strength < 0 or strength * 2 >= math.huge or strength * 2 ~= floor(strength * 2) then
        return nil, L.THE_SAVED_PRESTIGE_STRENGTH_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    local policy = db.salvage.policy
    if
        type(policy) ~= "table"
        or (policy.class ~= "any" and not C.classByID[policy.class])
        or (policy.slot ~= 0 and not C.slots[policy.slot])
        or (policy.stat ~= "any" and not C.itemStatNames[policy.stat])
    then
        return nil, L.THE_SAVED_LOOT_POLICY_IS_INVALID_YOUR_ADVENTURE_HAS
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
        return nil, L.THE_SAVED_DESTINATION_IS_UNKNOWN_YOUR_ADVENTURE_HAS_NOT
    end
    if not G.ValidateUnlocks(db, legacyUnlocks) then
        return nil, L.THE_SAVED_ADVENTURE_HAS_AN_INVALID_PREFIX .. "unlocks" .. L.FIELD_IT_HAS_NOT_BEEN_RESET_SUFFIX
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
        return nil, L.THE_SAVED_ADVENTURE_XP_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    if db.boosts.automation == nil then
        db.boosts.automation = copy(C.boostAutomationDefaults)
    end
    local automation = db.boosts.automation
    if type(automation) == "table" and type(automation.abilities) == "table" then
        -- A newly added catalog ability starts disabled without rewriting existing rules.
        for id, config in pairs(C.boostAutomationDefaults.abilities) do
            if automation.abilities[id] == nil then
                automation.abilities[id] = copy(config)
            end
        end
    end
    if not G.ValidateBoosts(db) then
        return nil, L.THE_SAVED_COMMANDER_BOOSTS_ARE_INVALID_YOUR_ADVENTURE_HAS
    end
    for material, remainder in pairs(db.materialRemainders) do
        if
            not C.materials[material]
            or type(remainder) ~= "number"
            or remainder < 0
            or remainder >= 1
            or remainder ~= remainder
        then
            return nil, L.THE_SAVED_MATERIAL_PROGRESS_IS_INVALID_YOUR_ADVENTURE_HAS
        end
    end
    if db.routes.offlineEnabled == nil then
        db.routes.offlineEnabled = false
    end
    if not G.ValidateRoutes(db) then
        return nil, L.THE_SAVED_ROUTES_ARE_INVALID_YOUR_ADVENTURE_HAS_NOT
    end
    if not G.ValidateProfiles(db) then
        return nil, L.THE_SAVED_COMMANDER_PROFILES_ARE_INVALID_YOUR_ADVENTURE_HAS
    end
    if not G.ValidateHuntSummary(db) then
        return nil, L.THE_SAVED_OUTDOOR_HUNT_REPORT_IS_INVALID_YOUR_ADVENTURE
    end
    if not G.ValidateCollections(db) then
        return nil, L.THE_SAVED_COLLECTIONS_ARE_INVALID_YOUR_ADVENTURE_HAS_NOT
    end
    if not whole(db.encounter) or (db.collectionBook.lastEncounter or 0) > db.encounter then
        return nil, L.THE_SAVED_ENCOUNTER_RECEIPTS_ARE_INVALID_YOUR_ADVENTURE_HAS
    end
    if not G.ValidateDifficulty(db) then
        return nil, L.THE_SAVED_DIFFICULTY_PROGRESS_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    if db.tier == 0 and not db.difficulty.records[0] then
        db.difficulty.records[0] = { best = math.max(0, db.runBest - 1), safe = copy(db.safe) }
    end
    if not G.ValidateProfessions(db) then
        return nil, L.THE_SAVED_PROFESSIONS_ARE_INVALID_YOUR_ADVENTURE_HAS_NOT
    end
    if db.stats.boostUses == nil then
        db.stats.boostUses = 0
    elseif not whole(db.stats.boostUses) then
        return nil, L.THE_SAVED_BOOST_USAGE_COUNT_IS_INVALID_YOUR_ADVENTURE
    end
    if migrated then
        G.Log(
            db,
            L.ADVENTURE_XP_UNLOCKED_EXISTING_ESSENCE_AND_HERO_PROGRESSION_RETAINED,
            nil,
            "updates"
        )
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
            G.Log(db, L.THE_PARTY_REGROUPED_AND_IS_READY_TO_CONTINUE, nil, "updates")
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
    local function validModifications(item)
        if type(item) ~= "table" then
            return false
        end
        local forge = item.forge or 0
        if not whole(forge) or forge > C.forgeCap then
            return false
        end
        if
            item.forgePower ~= nil
            and (
                type(item.forgePower) ~= "number"
                or item.forgePower ~= item.forgePower
                or item.forgePower < 0
                or item.forgePower > 0.27500001
                or forge == 0
            )
        then
            return false
        end
        if item.enchant ~= nil then
            local enchant = item.enchant
            if
                type(enchant) ~= "table"
                or not C.enchantByID[enchant.id]
                or type(enchant.stats) ~= "table"
                or (
                    enchant.level ~= nil
                    and (
                        not whole(enchant.level)
                        or enchant.level < 1
                        or enchant.level > C.heroLevelCap
                    )
                )
            then
                return false
            end
            for key, value in pairs(enchant.stats) do
                if
                    not C.enchantByID[enchant.id].stats[key]
                    or type(value) ~= "number"
                    or value ~= value
                    or value < 0
                    or value > 1000000
                then
                    return false
                end
            end
        end
        return true
    end
    for _, item in ipairs(db.inventory) do
        if not validModifications(item) then
            return nil, L.THE_SAVED_ITEM_MODIFICATIONS_ARE_INVALID_YOUR_ADVENTURE_HAS
        end
        migrateItem(item)
    end
    for _, hero in ipairs(db.heroes) do
        if
            hero.resourceThreshold ~= nil
            and (
                type(hero.resourceThreshold) ~= "number"
                or hero.resourceThreshold < 0
                or hero.resourceThreshold > 100
                or hero.resourceThreshold ~= floor(hero.resourceThreshold)
            )
        then
            return nil, L.THE_SAVED_ABILITY_RESOURCE_THRESHOLD_IS_INVALID_YOUR_ADVENTURE
        end
        if hero.targetMode ~= nil and not C.targetModeByID[hero.targetMode] then
            return nil, L.THE_SAVED_COMBAT_TARGET_PRIORITY_IS_INVALID_YOUR_ADVENTURE
        end
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
                return nil, L.THE_SAVED_HERO_EXPERIENCE_IS_INVALID_YOUR_ADVENTURE_HAS
            end
            mastery.rank = mastery.rank + hero.level - C.heroLevelCap
            mastery.xp = math.min(hero.xp, G.MasteryCost(mastery.rank) - 1)
            hero.level, hero.xp = C.heroLevelCap, 0
            db.battle, db.rest = nil, 0
        end
        G.AppearanceSeed(hero)
        for _, item in pairs(hero.gear or {}) do
            if not validModifications(item) then
                return nil, L.THE_SAVED_ITEM_MODIFICATIONS_ARE_INVALID_YOUR_ADVENTURE_HAS
            end
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
    if needsTalentMigration then
        -- Old encounters contain cached stats from the previous talent definitions.
        db.battle, db.rest = nil, 0
    end
    G.ProfessionUnlocks(db)
    if not G.ValidateDevelopment(db) then
        return nil, L.THE_SAVED_PARTY_DEVELOPMENT_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    if not G.MigrateEconomy(db, previousEconomy) then
        return nil, L.THE_SAVED_ECONOMY_CANNOT_BE_MIGRATED_SAFELY_YOUR_ADVENTURE
    end
    db.paused, db.pauseAfter = false, nil
    db.events = nil
    return db
end
