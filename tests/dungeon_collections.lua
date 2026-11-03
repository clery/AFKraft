local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local pieces = { 10399, 10400, 10401, 10402, 10403 }
local function state()
    local s = G.New(0)
    assert(G.ValidateCollections(s))
    return s
end
local function complete(s, id)
    for _, itemID in ipairs(C.collectionByID[id].pieces) do
        G.CollectionBook(s, id).pieces[itemID] = true
    end
end
local function fixture(fn)
    local previous = W.CollectionSources
    local profiles = {
        dungeonFixture = {
            id = "dungeonFixture",
            kind = "dungeon",
            enabled = true,
            verified = true,
            chance = 0,
            guarantee = 2,
        },
        outdoorFixture = {
            id = "outdoorFixture",
            enabled = true,
            verified = true,
            chance = 0,
            guarantee = 2,
        },
    }
    W.CollectionSources = {
        Profile = function(id)
            return profiles[id]
        end,
        Eligible = function(id)
            return { 10399 }, profiles[id]
        end,
    }
    local ok, reason = pcall(fn, profiles)
    W.CollectionSources = previous
    assert(ok, reason)
end
local function kill(serial)
    return {
        profile = "dungeonFixture",
        npcID = 639,
        kind = "dungeon",
        dungeon = true,
        attributed = true,
        receipt = string.format("kill:Creature-0-1-1-1-639-%012X", serial),
    }
end
case("Dungeon collection identities remain outside ordinary equipment pools", function()
    assert(C.collectionByID.defiasLeather.kind == "dungeon")
    for _, itemID in ipairs(pieces) do
        assert(G.CollectionItem(itemID) and not C.itemByID[itemID])
        assert(C.collectionByItem[itemID] == "defiasLeather")
    end
end)
case(
    "Dungeon kills use independent durable counters and reject repeats and wrong contexts",
    function()
        fixture(function()
            local s = state()
            assert(G.CollectionKill(s, kill(1)))
            assert(not G.CollectionKill(s, kill(1)))
            assert(s.dungeonCollections.counters.dungeonFixture[10399] == 1)
            assert(s.dungeonCollections.stats.kills == 1 and s.outdoorCollections.stats.kills == 0)
            local context = kill(2)
            context.dungeon = false
            assert(not G.CollectionKill(s, context))
            context.dungeon, context.profile = true, "outdoorFixture"
            assert(not G.CollectionKill(s, context))
            s.offline = true
            assert(not G.CollectionKill(s, kill(2)))
            s.offline = nil
            assert(G.CollectionKill(s, kill(2)))
            assert(s.dungeonCollections.pieces[10399] and not s.outdoorCollections.pieces[10399])
            assert(s.dungeonCollections.stats.discoveries == 1 and G.ValidateCollections(s))
        end)
    end
)
case("Tracking and selected effects are shared across collection books", function()
    local s = state()
    assert(G.SetCollectionTarget(s, 4701) and G.CollectionTarget(s) == 4701)
    assert(G.SetCollectionTarget(s, 10399) and G.CollectionTarget(s) == 10399)
    assert(s.outdoorCollections.target == nil)
    assert(not G.SetCollectionEffect(s, "defiasLeather"))
    complete(s, "redridgeOutriders")
    complete(s, "defiasLeather")
    assert(G.SetCollectionEffect(s, "redridgeOutriders"))
    assert(G.SetCollectionEffect(s, "defiasLeather"))
    assert(s.outdoorCollections.effect == nil and G.ActiveCollectionEffect(s) == "defiasLeather")
    assert(G.CollectionBonuses(s, "humanoid").damageTaken == 0.96)
    assert(G.CollectionBonuses(s, "beast").damageTaken == 1)
    assert(G.CollectionBonuses(s, "beast").basicAttack == 1.01)
    assert(G.ValidateCollections(s))
end)
case("Collection save validation rejects cross-ledger pieces and dual selections", function()
    local s = state()
    s.dungeonCollections.pieces[4701] = true
    assert(not G.ValidateCollections(s))
    s.dungeonCollections.pieces[4701] = nil
    s.outdoorCollections.target, s.dungeonCollections.target = 4701, 10399
    assert(not G.ValidateCollections(s))
    s.outdoorCollections.target, s.dungeonCollections.target = nil, nil
    complete(s, "redridgeOutriders")
    complete(s, "defiasLeather")
    s.outdoorCollections.effect, s.dungeonCollections.effect = "redridgeOutriders", "defiasLeather"
    assert(not G.ValidateCollections(s))
end)
case("Older saves initialize dungeon collections without mutating their source", function()
    local s = state()
    s.dungeonCollections = nil
    local restored = assert(G.Load(s, 0))
    assert(restored.dungeonCollections and next(restored.dungeonCollections.pieces) == nil)
    assert(s.dungeonCollections == nil)
end)
case("Profiles restore one dungeon effect atomically and reject unavailable effects", function()
    local s = state()
    complete(s, "redridgeOutriders")
    complete(s, "defiasLeather")
    assert(G.SetCollectionEffect(s, "defiasLeather"))
    local ok, id = G.SaveBoostProfile(s, nil, "Dungeon")
    assert(ok)
    assert(G.SetCollectionEffect(s, "redridgeOutriders"))
    assert(G.ApplyBoostProfile(s, id))
    assert(G.ActiveCollectionEffect(s) == "defiasLeather" and not s.outdoorCollections.effect)
    s.dungeonCollections.pieces[10399] = nil
    assert(G.SetCollectionEffect(s, "redridgeOutriders"))
    local boost, automation = s.boosts.equipped, s.boosts.automation.abilities
    assert(not G.ApplyBoostProfile(s, id))
    assert(G.ActiveCollectionEffect(s) == "redridgeOutriders" and s.boosts.equipped == boost)
    assert(s.boosts.automation.abilities == automation)
end)
case("Dungeon context rejects contradictory location flags without consuming progress", function()
    fixture(function()
        local s = state()
        local context = kill(1)
        context.outdoor = true
        assert(not G.CollectionKill(s, context))
        context.kind = "outdoor"
        assert(not G.CollectionKill(s, context))
        context.kind, context.outdoor = "dungeon", "false"
        assert(not G.CollectionKill(s, context))
        assert(s.dungeonCollections.stats.kills == 0 and next(s.dungeonCollections.counters) == nil)
        assert(s.outdoorCollections.stats.kills == 0 and next(s.outdoorCollections.counters) == nil)
    end)
end)
case("Dungeon kills cannot advance outdoor discovery milestones or counters", function()
    fixture(function()
        local s = state()
        s.outdoorCollections.pieces[4701] = true
        s.outdoorCollections.stats.kills = 12
        s.outdoorCollections.stats.discoveries = 1
        assert(G.CollectionKill(s, kill(1)))
        assert(G.CollectionKill(s, kill(2)))
        assert(
            s.outdoorCollections.stats.kills == 12 and s.outdoorCollections.stats.discoveries == 1
        )
        assert(s.outdoorCollections.pieces[4701] and not s.outdoorCollections.pieces[10399])
        assert(
            next(s.outdoorCollections.counters) == nil
                and next(s.outdoorCollections.receipts) == nil
        )
        assert(G.CollectionProgress(s, "redridgeOutriders").found == 1)
    end)
end)
case(
    "Dungeon discoveries, pending receipts, target and effect survive reload and both resets",
    function()
        fixture(function()
            local s = state()
            G.AddHero(s, "WARRIOR")
            assert(G.CollectionKill(s, kill(1)))
            assert(G.SetCollectionTarget(s, 10399))
            s = assert(G.Load(G.Copy(s), 10))
            assert(not G.CollectionKill(s, kill(1)))
            s.prestigeUnlocked, s.runBest = true, 8
            assert(G.Prestige(s))
            assert(s.dungeonCollections.counters.dungeonFixture[10399] == 1)
            assert(s.dungeonCollections.receipts.dungeonFixture[10399][kill(1).receipt])
            assert(G.CollectionTarget(s) == 10399)
            assert(G.CollectionKill(s, kill(2)))
            complete(s, "defiasLeather")
            assert(G.SetCollectionEffect(s, "defiasLeather"))
            local hero = s.heroes[1]
            hero.level = 60
            assert(G.TalentProgress(hero))
            s.encounter = s.encounter + 1
            assert(G.DifficultyVictory(s, { boss = true, level = 60 }))
            assert(G.PrestigePlus(s, 1))
            assert(
                G.CollectionTarget(s) == 10399 and G.ActiveCollectionEffect(s) == "defiasLeather"
            )
            assert(G.CollectionProgress(s, "defiasLeather").complete)
            assert(
                s.dungeonCollections.stats.kills == 2
                    and s.dungeonCollections.stats.discoveries == 1
            )
            assert(s.dungeonCollections.counters.dungeonFixture[10399] == 2)
            assert(G.Load(G.Copy(s), 20))
        end)
    end
)
return cases
