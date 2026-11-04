local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Collection talents charge each rank once and reject invalid purchases atomically", function()
    local s = G.New(0)
    assert(not G.BuyCollectionTalent(s, "fieldcraft"))
    s.legacy = 6
    assert(not G.BuyCollectionTalent(s, "unknown"))
    for rank, balance in ipairs({ 5, 3, 0 }) do
        assert(G.BuyCollectionTalent(s, "fieldcraft"))
        assert(s.collectionTalents.fieldcraft == rank and s.legacy == balance)
    end
    s.legacy = 10
    assert(not G.BuyCollectionTalent(s, "fieldcraft"))
    assert(s.legacy == 10 and s.collectionTalents.fieldcraft == 3)
    s.legacy = 0 / 0
    assert(not G.BuyCollectionTalent(s, "relicHunter"))
    assert(s.collectionTalents.relicHunter == nil)
end)

case("Collection talent saves migrate empty and reject unknown or invalid ranks", function()
    local old = G.New(0)
    old.collectionTalents = nil
    local loaded = assert(G.Load(G.Copy(old), 0))
    assert(next(loaded.collectionTalents) == nil)
    for _, ranks in ipairs({
        { unknown = 1 },
        { fieldcraft = -1 },
        { fieldcraft = 0.5 },
        { fieldcraft = 4 },
        { relicHunter = math.huge },
        { fieldcraft = 0 / 0 },
    }) do
        local s = G.New(0)
        s.collectionTalents = ranks
        assert(not G.Load(s, 0))
    end
end)

case("Collection talent conditions apply only to their acquisition kind", function()
    local s = G.New(0)
    local outdoor, dungeon = { chance = 5 }, { kind = "dungeon", chance = 20 }
    assert(G.CollectionDropChance(s, outdoor) == 5)
    s.collectionTalents.fieldcraft = 3
    assert(G.CollectionDropChance(s, outdoor) == 8)
    assert(G.CollectionDropChance(s, dungeon) == 20)
    s.collectionTalents.relicHunter = 3
    assert(G.CollectionDropChance(s, dungeon) == 32)
    assert(G.CollectionDropChance(s, outdoor) == 8)
    s.collectionTalents.fieldcraft = 1
    assert(G.CollectionDropChance(s, outdoor) == 6)
    assert(G.CollectionDropChance(s, { chance = 0 }) == 0)
end)

case("Collection rolls use fractional talent bonuses without pity or extra rewards", function()
    local sources, random = W.CollectionSources, G.Random
    local profile = { id = "talentFixture", chance = 5, enabled = true, verified = true }
    local roll, itemID = 550, 4701
    W.CollectionSources = {
        Profile = function()
            return profile
        end,
        Eligible = function()
            return { itemID }, profile
        end,
    }
    G.Random = function(_, n)
        assert(n == 10000)
        return roll
    end
    local ok, message = pcall(function()
        local context = {
            profile = profile.id,
            npcID = 423,
            outdoor = true,
            attributed = true,
            receipt = "kill:Creature-0-1-1-1-423-000001",
        }
        local base = G.New(0)
        assert(G.CollectionKill(base, context))
        assert(not base.outdoorCollections.pieces[4701])
        assert(not G.CollectionKill(base, context))
        local boosted = G.New(0)
        boosted.collectionTalents.fieldcraft = 1
        assert(G.CollectionKill(boosted, context))
        assert(boosted.outdoorCollections.pieces[4701])
        assert(boosted.gold == 0 and boosted.essence == 0 and #boosted.inventory == 0)
        local misses = G.New(0)
        misses.collectionTalents.fieldcraft = 3
        roll = 10000
        for serial = 1, 300 do
            context.receipt = string.format("kill:Creature-0-1-1-1-423-%012X", serial)
            assert(G.CollectionKill(misses, context))
        end
        assert(not misses.outdoorCollections.pieces[4701])
        assert(next(misses.outdoorCollections.counters) == nil)
        assert(G.Load(G.Copy(misses), 0))
        profile.kind, profile.chance, itemID, roll = "dungeon", 20, 10399, 2200
        context.kind, context.outdoor, context.dungeon = "dungeon", false, true
        local dungeon = G.New(0)
        dungeon.collectionTalents.fieldcraft = 3
        assert(G.CollectionKill(dungeon, context))
        assert(not dungeon.dungeonCollections.pieces[10399])
        dungeon = G.New(0)
        dungeon.collectionTalents.relicHunter = 1
        assert(G.CollectionKill(dungeon, context))
        assert(dungeon.dungeonCollections.pieces[10399])
    end)
    W.CollectionSources, G.Random = sources, random
    assert(ok, message)
end)

case("Collection talent ranks survive reload, prestige and Prestige+", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    s.legacy = 12
    for _ = 1, 3 do
        assert(G.BuyCollectionTalent(s, "fieldcraft"))
        assert(G.BuyCollectionTalent(s, "relicHunter"))
    end
    s = assert(G.Load(G.Copy(s), 0))
    s.prestigeUnlocked, s.runBest = true, 8
    assert(G.Prestige(s))
    assert(s.collectionTalents.fieldcraft == 3 and s.collectionTalents.relicHunter == 3)
    local hero = s.heroes[1]
    hero.level = 60
    assert(G.TalentProgress(hero))
    s.encounter = s.encounter + 1
    assert(G.DifficultyVictory(s, { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }))
    assert(G.PrestigePlus(s, 1))
    assert(s.collectionTalents.fieldcraft == 3 and s.collectionTalents.relicHunter == 3)
    assert(G.Load(G.Copy(s), 0))
end)

return cases
