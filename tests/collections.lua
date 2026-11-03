local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local setID = "redridgeOutriders"
local pieces = { 4701, 2985, 2986, 2987, 2988 }
local oldSet = "westfallOutriders"
local function state()
    local s = G.New(0)
    assert(G.ValidateCollections(s))
    return s
end
local function context(serial, npc, profile)
    npc = npc or 105
    return {
        profile = profile or "syntheticA",
        receipt = string.format("kill:Creature-0-1-1-1-%d-%012X", npc, serial),
        npcID = npc,
        outdoor = true,
        attributed = true,
    }
end
-- Synthetic metadata exercises domain contracts only; it is not real source verification.
local function fixture(fn)
    local previous, random = W.CollectionSources, G.Random
    local sources = {
        profiles = {
            syntheticA = {
                id = "syntheticA",
                enabled = true,
                verified = true,
                chance = 0,
                guarantee = 30,
            },
            syntheticB = {
                id = "syntheticB",
                enabled = true,
                verified = true,
                chance = 0,
                guarantee = 30,
            },
        },
    }
    function sources.Profile(id)
        return sources.profiles[id]
    end
    function sources.Eligible(id, npc)
        local eligible = {
            [101] = { pieces[1], pieces[2] },
            [102] = { pieces[2] },
            [103] = { pieces[3] },
            [104] = { pieces[4], pieces[5] },
            [105] = { pieces[1] },
        }
        return eligible[npc] or {}, sources.profiles[id]
    end
    W.CollectionSources = sources
    local ok, problem = pcall(fn, sources)
    W.CollectionSources, G.Random = previous, random
    if not ok then
        error(problem)
    end
end

case(
    "Outdoor collection catalog keeps real piece IDs separate from archived prototype identities",
    function()
        local collection = assert(C.collectionByID[setID])
        for index, itemID in ipairs(pieces) do
            assert(
                collection.pieces[index] == itemID
                    and C.collectionByItem[itemID] == setID
                    and C.itemByID[itemID]
            )
        end
        assert(not C.collectionByItem[1930] and C.legacyCollectionByItem[1930] == oldSet)
    end
)

case(
    "Collection migration imports exact shared discoveries once without converting counters or granting rewards",
    function()
        local s = state()
        s.outdoorCollections = nil
        s.collectionBook.pieces[1930] = 3
        s.collectionBook.pieces[2985] = 2
        s.collectionBook.counters[oldSet] = { [0] = 17, [1] = 9 }
        s.collectionBook.target = oldSet
        local seed, essence, nextItem = s.seed, s.essence, s.nextItem
        assert(G.ValidateCollections(s))
        assert(s.outdoorCollections.pieces[2985] and not s.outdoorCollections.pieces[4701])
        assert(not s.outdoorCollections.pieces[1930] and s.collectionBook.pieces[1930] == 3)
        assert(s.collectionBook.counters[oldSet][0] == 17 and s.collectionBook.target == oldSet)
        assert(
            next(s.outdoorCollections.counters) == nil
                and s.outdoorCollections.stats.kills == 0
                and s.outdoorCollections.stats.discoveries == 0
        )
        assert(
            s.outdoorCollections.effect == nil
                and s.seed == seed
                and s.essence == essence
                and s.nextItem == nextItem
        )
        s.collectionBook.pieces[2986] = 1
        assert(G.ValidateCollections(s) and not s.outdoorCollections.pieces[2986])
    end
)

case("Idle collection APIs never roll RNG or mutate either collection ledger", function()
    local s = state()
    local seed, nextItem, essence = s.seed, s.nextItem, s.essence
    local lastEncounter = s.collectionBook.lastEncounter
    local random = G.Random
    G.Random = function()
        error("Idle collection API rolled RNG")
    end
    local ok, problem = pcall(function()
        assert(
            G.CollectionVictory(
                s,
                { receipt = "encounter:1", zone = "westfall", family = "humanoid", level = 60 }
            ) == nil
        )
        assert(
            not G.RegisterCollectionDrop(
                s,
                { itemID = 2985 },
                { outdoor = true, attributed = true }
            )
        )
    end)
    G.Random = random
    if not ok then
        error(problem)
    end
    assert(s.seed == seed and s.nextItem == nextItem and s.essence == essence)
    assert(
        next(s.collectionBook.pieces) == nil
            and next(s.collectionBook.counters) == nil
            and s.collectionBook.lastEncounter == lastEncounter
    )
    assert(next(s.outdoorCollections.pieces) == nil and s.outdoorCollections.stats.kills == 0)
end)

case(
    "Outdoor source gates reject unverified, disabled, indoor and unattributed kills without RNG",
    function()
        fixture(function(sources)
            local s = state()
            local randomCalls = 0
            G.Random = function()
                randomCalls = randomCalls + 1
                return 100
            end
            for _, changes in ipairs({
                { outdoor = false },
                { attributed = false },
                { npcID = 102 },
                { receipt = "encounter:1" },
                { profile = "missing" },
            }) do
                local c = context(1)
                for key, value in pairs(changes) do
                    c[key] = value
                end
                assert(not G.CollectionKill(s, c))
            end
            sources.profiles.syntheticA.verified = false
            assert(not G.CollectionKill(s, context(2)))
            sources.profiles.syntheticA.verified = true
            sources.profiles.syntheticA.enabled = false
            assert(not G.CollectionKill(s, context(3)))
            sources.profiles.syntheticA.enabled = true
            s.offline = true
            assert(not G.CollectionKill(s, context(4)))
            assert(
                randomCalls == 0
                    and next(s.outdoorCollections.counters) == nil
                    and s.outdoorCollections.stats.kills == 0
            )
        end)
    end
)

case("Each eligible piece has an independent guarantee and every fresh kill counts once", function()
    fixture(function()
        local s = state()
        local gold, essence, nextItem = s.gold, s.essence, s.nextItem
        for serial = 1, 29 do
            assert(G.CollectionKill(s, context(serial)))
        end
        for serial = 30, 36 do
            assert(G.CollectionKill(s, context(serial, 102)))
        end
        local ok, result = G.CollectionKill(s, context(37, 101))
        assert(
            ok
                and result.progressed == 2
                and #result.discoveries == 1
                and result.discoveries[1] == pieces[1]
        )
        assert(
            s.outdoorCollections.pieces[pieces[1]] and not s.outdoorCollections.pieces[pieces[2]]
        )
        assert(
            s.outdoorCollections.counters.syntheticA[pieces[1]] == 30
                and s.outdoorCollections.counters.syntheticA[pieces[2]] == 8
        )
        assert(s.outdoorCollections.receipts.syntheticA[pieces[1]] == nil)
        assert(
            s.outdoorCollections.stats.kills == 37 and s.outdoorCollections.stats.discoveries == 1
        )
        assert(
            s.gold == gold and s.essence == essence and s.nextItem == nextItem and #s.inventory == 0
        )
        assert(G.ValidateCollections(s))
    end)
end)

case(
    "Pending kill receipts survive many unrelated kills and reject replay without history eviction",
    function()
        fixture(function()
            local s = state()
            local first = context(1)
            assert(G.CollectionKill(s, first))
            for serial = 2, 200 do
                G.CollectionKill(s, context(serial, 103))
            end
            for serial = 201, 400 do
                G.CollectionKill(s, context(serial, 104, "syntheticB"))
            end
            local seed, kills = s.seed, s.outdoorCollections.stats.kills
            assert(not G.CollectionKill(s, first))
            assert(s.seed == seed and s.outdoorCollections.stats.kills == kills)
            assert(s.outdoorCollections.counters.syntheticA[pieces[1]] == 1)
            assert(s.outdoorCollections.receipts.syntheticA[pieces[1]][first.receipt])
            assert(G.ValidateCollections(s))
        end)
    end
)

case(
    "Discovery clears pending receipts across source profiles and freezes completed counters",
    function()
        fixture(function(sources)
            local s = state()
            assert(G.CollectionKill(s, context(1)))
            assert(G.CollectionKill(s, context(2, 105, "syntheticB")))
            sources.profiles.syntheticA.chance = 100
            local ok, result = G.CollectionKill(s, context(3))
            assert(ok and #result.discoveries == 1)
            assert(
                s.outdoorCollections.receipts.syntheticA[pieces[1]] == nil
                    and s.outdoorCollections.receipts.syntheticB[pieces[1]] == nil
            )
            assert(s.outdoorCollections.counters.syntheticB[pieces[1]] == 1)
            assert(not G.CollectionKill(s, context(4, 105, "syntheticB")))
            assert(
                s.outdoorCollections.counters.syntheticB[pieces[1]] == 1
                    and G.ValidateCollections(s)
            )
        end)
    end
)

case("One attributed kill independently discovers multiple eligible pieces", function()
    fixture(function(sources)
        sources.profiles.syntheticA.chance = 100
        local s = state()
        local ok, result = G.CollectionKill(s, context(1, 101))
        assert(ok and result.progressed == 2 and #result.discoveries == 2)
        assert(
            s.outdoorCollections.stats.kills == 1 and s.outdoorCollections.stats.discoveries == 2
        )
        assert(G.ValidateCollections(s))
    end)
end)

case("Collection tracking never changes deterministic discovery outcomes", function()
    fixture(function(sources)
        sources.profiles.syntheticA.chance = 5
        local a, b = state(), state()
        assert(G.SetCollectionTarget(a, pieces[1]))
        assert(not G.SetCollectionTarget(a, setID))
        for serial = 1, 40 do
            local x = G.CollectionKill(a, context(serial, 101))
            local y = G.CollectionKill(b, context(serial, 101))
            assert(x == y)
        end
        assert(a.seed == b.seed)
        for _, itemID in ipairs(pieces) do
            assert(a.outdoorCollections.pieces[itemID] == b.outdoorCollections.pieces[itemID])
        end
        assert(G.SetCollectionTarget(a, nil))
    end)
end)

case(
    "Archived collection floors retain exact ranks and family defense without stacking duplicate bonuses",
    function()
        local s = state()
        for _, itemID in ipairs(C.legacyCollectionByID[oldSet].pieces) do
            s.collectionBook.pieces[itemID] = 2
        end
        local legacy = G.LegacyCollectionBonuses(s, "humanoid")
        local scale = G.CollectionRankScale(2)
        assert(
            math.abs(legacy.basicAttack - (1 + 0.02 * scale)) < 0.000001
                and math.abs(legacy.materials - (1 + 0.03 * scale)) < 0.000001
        )
        assert(math.abs(legacy.damageTaken - (1 - 0.03 * scale)) < 0.000001)
        assert(G.LegacyCollectionProgress(s, oldSet).completedRank == 2)
        for _, itemID in ipairs(pieces) do
            s.outdoorCollections.pieces[itemID] = true
        end
        assert(G.SetCollectionEffect(s, setID))
        local modern = G.CollectionBonuses(s, "humanoid")
        assert(math.abs(modern.basicAttack - math.max(legacy.basicAttack, 1.045)) < 0.000001)
        assert(modern.materials == legacy.materials and modern.damageTaken == legacy.damageTaken)
        assert(G.CollectionBonuses(s, "beast").damageTaken == 1)
    end
)

case(
    "Only a complete selected outdoor effect applies and selection never spends resources",
    function()
        local s = state()
        assert(not G.SetCollectionEffect(s, setID))
        for _, itemID in ipairs(pieces) do
            s.outdoorCollections.pieces[itemID] = true
        end
        local before = G.CollectionBonuses(s)
        local gold, essence, seed = s.gold, s.essence, s.seed
        assert(G.SetCollectionEffect(s, setID) and G.CollectionEffectStatus(s))
        local selected = G.CollectionBonuses(s)
        assert(math.abs(selected.basicAttack - before.basicAttack - 0.04) < 0.000001)
        assert(
            G.SetCollectionEffect(s, setID)
                and G.CollectionBonuses(s).basicAttack == selected.basicAttack
        )
        assert(not G.SetCollectionEffect(s, "unknown") and s.outdoorCollections.effect == setID)
        assert(
            G.SetCollectionEffect(s, nil)
                and G.CollectionBonuses(s).basicAttack == before.basicAttack
        )
        assert(s.gold == gold and s.essence == essence and s.seed == seed)
    end
)

case(
    "Modern partial milestones are additively capped rather than multiplied across sets",
    function()
        local s = state()
        s.outdoorCollections.pieces[pieces[1]] = true
        local count = #C.collections
        local ok, problem = pcall(function()
            for index = 1, 12 do
                local collection = {
                    id = "syntheticSet" .. index,
                    name = "Synthetic",
                    pieces = { pieces[1] },
                    milestones = {
                        basicAttack = { pieces = 1, bonus = 0.02 },
                        materials = {
                            pieces = 1,
                            bonus = 0.02,
                        },
                    },
                    effect = { basicAttack = 0.04 },
                }
                C.collections[#C.collections + 1] = collection
                C.collectionByID[collection.id] = collection
            end
            local bonuses = G.CollectionBonuses(s)
            assert(
                math.abs(bonuses.basicAttack - 1.05) < 0.000001
                    and math.abs(bonuses.materials - 1.05) < 0.000001
            )
            assert(G.SetCollectionEffect(s, "syntheticSet1"))
            assert(math.abs(G.CollectionBonuses(s).basicAttack - 1.09) < 0.000001)
        end)
        for index = #C.collections, count + 1, -1 do
            C.collectionByID[C.collections[index].id] = nil
            C.collections[index] = nil
        end
        if not ok then
            error(problem)
        end
    end
)

case(
    "Outdoor validation rejects malformed pieces, profiles, counters, receipts and incomplete effects",
    function()
        fixture(function()
            for _, mutate in ipairs({
                function(s)
                    s.outdoorCollections.pieces[pieces[1]] = 1
                end,
                function(s)
                    s.outdoorCollections.pieces[1930] = true
                end,
                function(s)
                    s.outdoorCollections.version = 2
                end,
                function(s)
                    s.outdoorCollections.target = setID
                end,
                function(s)
                    s.outdoorCollections.effect = setID
                end,
                function(s)
                    s.outdoorCollections.stats.kills = 0 / 0
                end,
                function(s)
                    s.outdoorCollections.stats.discoveries = 1
                end,
                function(s)
                    s.outdoorCollections.counters.unknown = { [pieces[1]] = 1 }
                end,
                function(s)
                    s.outdoorCollections.counters.syntheticA = { [pieces[1]] = 30 }
                end,
                function(s)
                    s.outdoorCollections.counters.syntheticA = { [pieces[1]] = 1 }
                end,
                function(s)
                    s.outdoorCollections.receipts.syntheticA =
                        { [pieces[1]] = { [context(1).receipt] = true } }
                end,
            }) do
                local s = state()
                mutate(s)
                assert(not G.ValidateCollections(s))
            end
            local legacy = state()
            legacy.collectionBook.pieces[1930] = -1
            assert(not G.ValidateCollections(legacy))
        end)
    end
)

case(
    "Outdoor discoveries, pending receipts, target and effect persist across reload and both resets",
    function()
        fixture(function(sources)
            local s = state()
            G.AddHero(s, "WARRIOR")
            assert(G.CollectionKill(s, context(1)))
            assert(G.SetCollectionTarget(s, pieces[1]))
            s = assert(G.Load(G.Copy(s), 10))
            assert(not G.CollectionKill(s, context(1)))
            s.prestigeUnlocked, s.runBest = true, 8
            assert(G.Prestige(s))
            assert(
                s.outdoorCollections.counters.syntheticA[pieces[1]] == 1
                    and s.outdoorCollections.target == pieces[1]
            )
            sources.profiles.syntheticA.chance = 100
            for serial, npc in ipairs({ 101, 103, 104 }) do
                assert(G.CollectionKill(s, context(serial + 1, npc)))
            end
            assert(G.SetCollectionEffect(s, setID))
            local hero = s.heroes[1]
            hero.level = 60
            assert(G.TalentProgress(hero))
            s.encounter = s.encounter + 1
            assert(G.DifficultyVictory(s, { boss = true, level = 60 }))
            assert(G.PrestigePlus(s, 1))
            assert(s.outdoorCollections.effect == setID and G.CollectionProgress(s, setID).complete)
            assert(G.Load(G.Copy(s), 20))
        end)
    end
)

case(
    "Finishing idle catch-up retains concurrent outdoor progress and player preferences",
    function()
        fixture(function(sources)
            local s = state()
            G.AddHero(s, "WARRIOR")
            s.safe.elwynn, s.stage, s.farming = 1, 1, true
            local job = assert(G.BeginCatchup(s, 20))
            assert(G.CollectionKill(s, context(1)))
            assert(G.SetCollectionTarget(s, pieces[1]))
            local live = s.outdoorCollections
            assert(G.CatchupBatch(job, 10000))
            assert(G.FinishCatchup(s, job))
            assert(s.outdoorCollections == live and s.outdoorCollections.target == pieces[1])
            assert(s.outdoorCollections.counters.syntheticA[pieces[1]] == 1)
            assert(s.outdoorCollections.receipts.syntheticA[pieces[1]][context(1).receipt])
            assert(not G.CollectionKill(s, context(1)))
            sources.profiles.syntheticA.chance = 100
            s.lastTime = 20
            local second = assert(G.BeginCatchup(s, 40))
            for serial, npc in ipairs({ 101, 103, 104 }) do
                assert(G.CollectionKill(s, context(serial + 2, npc)))
            end
            assert(G.SetCollectionEffect(s, setID))
            assert(G.SetCollectionTarget(s, pieces[5]))
            assert(G.CatchupBatch(second, 10000) and G.FinishCatchup(s, second))
            assert(
                s.outdoorCollections.effect == setID and s.outdoorCollections.target == pieces[5]
            )
            assert(G.CollectionProgress(s, setID).complete and G.ValidateCollections(s))
        end)
    end
)

return cases
