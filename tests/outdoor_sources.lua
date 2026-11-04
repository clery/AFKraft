local _, W = ...
if not W then
    return
end
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case(
    "Outdoor source profiles keep unverified clients closed and expose exact Forever pieces",
    function()
        local S = W.CollectionSources
        assert(not S.profiles.retail120105.enabled and not S.profiles.retail120105.verified)
        assert(S.Eligible("retail120105", 423) == nil)
        local cloak, profile = S.Eligible("forever16001", 423)
        assert(profile.enabled and profile.verified and #cloak == 1 and cloak[1] == 4701)
        local leather = S.Eligible("forever16001", 1183)
        for _, itemID in ipairs({ 2985, 2986, 2987, 2988 }) do
            local found = false
            for _, eligible in ipairs(leather) do
                found = found or eligible == itemID
            end
            assert(found)
        end
        assert(#S.Eligible("forever16001", 4464) == 0)
    end
)

case("Forever source adapter can complete the outdoor set without real-item drops", function()
    local client, build, instance = W.Client, GetBuildInfo, IsInInstance
    local S, G = W.CollectionSources, W.Game
    local random = G.Random
    G.Random = function()
        return 1
    end
    local ok, message = pcall(function()
        W.Client = { flavor = "forever" }
        GetBuildInfo = function()
            return "1.60.1", "", "", 16001
        end
        IsInInstance = function()
            return false, "none"
        end
        assert(S.ActiveProfile().id == "forever16001")
        local state = G.New(1000)
        for _, npcID in ipairs({ 423, 1183 }) do
            for kill = 1, 30 do
                S.ObserveKill(state, string.format("Creature-0-1-2-3-%d-%06x", npcID, kill))
            end
        end
        for _, itemID in ipairs({ 4701, 2985, 2986, 2987, 2988 }) do
            assert(state.outdoorCollections.pieces[itemID])
        end
        assert(G.CollectionProgress(state, "redridgeOutriders").found == 5)
        assert(state.outdoorCollections.stats.discoveries >= 5)
        assert(state.adventure.totalXP == 0 and state.essence == 0 and #state.inventory == 0)
        assert(G.SetCollectionEffect(state, "redridgeOutriders"))
        assert(G.Load(state, 1000))
        local blocked = G.New(1000)
        blocked.offline = true
        assert(not S.ObserveKill(blocked, "Creature-0-1-2-3-423-000001"))
        GetBuildInfo = function()
            return "1.60.2", "", "", 16002
        end
        assert(not S.ActiveProfile())
    end)
    G.Random = random
    W.Client, GetBuildInfo, IsInInstance = client, build, instance
    assert(ok, message)
end)

case(
    "Outdoor adapter rejects instances, unknown builds and malformed creature identities",
    function()
        local client, build, instance = W.Client, GetBuildInfo, IsInInstance
        local S, G = W.CollectionSources, W.Game
        local profile = {
            id = "fixture",
            flavor = "fixture",
            interface = 777,
            enabled = true,
            verified = true,
            chance = 0,
            guarantee = 30,
            sources = { [4701] = { npcID = 423, verified = true } },
        }
        local ok, message = pcall(function()
            S.profiles.fixture = profile
            W.Client = { flavor = "fixture" }
            GetBuildInfo = function()
                return "fixture", "", "", 777
            end
            IsInInstance = function()
                return true, "party"
            end
            local state = G.New(0)
            local guid = "Creature-0-1-2-3-423-000001"
            assert(not S.ObserveKill(state, guid))
            IsInInstance = function()
                return false, "none"
            end
            assert(not S.ObserveKill(state, "Player-1-42"))
            assert(S.ObserveKill(state, guid))
            assert(next(state.outdoorCollections.counters) == nil)
            assert(not S.ObserveKill(state, guid))
            GetBuildInfo = function()
                return "fixture", "", "", 778
            end
            assert(not S.ActiveProfile())
            assert(not S.ObserveKill(state, "Creature-0-1-2-3-423-000002"))
            assert(next(state.outdoorCollections.counters) == nil)
        end)
        S.profiles.fixture = nil
        W.Client, GetBuildInfo, IsInInstance = client, build, instance
        assert(ok, message)
    end
)

case("Trivial outdoor collection kills remain separate from Adventure XP eligibility", function()
    local host = { dead = false, denied = false, time = 1 }
    local collected, rewarded = 0, 0
    local ns = {
        Client = {
            Now = function()
                return host.time
            end,
        },
        Game = {
            ActivityReward = function()
                rewarded = rewarded + 1
            end,
        },
        CollectionSources = {
            ActiveProfile = function()
                return {}
            end,
            ObserveKill = function()
                collected = collected + 1
            end,
        },
    }
    local env = setmetatable({
        UnitXPMax = function()
            return 100
        end,
        UnitGUID = function()
            return "Creature-0-1-2-3-423-000001"
        end,
        UnitIsDead = function()
            return host.dead
        end,
        UnitIsTrivial = function()
            return true
        end,
        UnitIsTapDenied = function()
            return host.denied
        end,
        UnitCanAttack = function()
            return true
        end,
        UnitPlayerControlled = function()
            return false
        end,
        UnitIsTappedByPlayer = function()
            return true
        end,
        CanLootUnit = function()
            return false, false
        end,
    }, { __index = _G })
    local chunk = assert(loadfile("Compatibility/Kills.lua"))
    setfenv(chunk, env)("WoWIdle", ns)
    ns.KillRewards.Observe({}, "target")
    host.dead = true
    ns.KillRewards.Observe({}, "target")
    assert(collected == 1 and rewarded == 0)
    host.denied = true
    ns.KillRewards.Observe({}, "target")
    assert(collected == 1 and rewarded == 0)
    host.denied, host.time = false, 122
    ns.KillRewards.Observe({}, "target")
    assert(collected == 1 and rewarded == 0)
end)

case(
    "Every collection has unique pieces, verified Forever sources and durable completion",
    function()
        local C, G, S = W.Content, W.Game, W.CollectionSources
        local seenSets, seenItems = {}, {}
        local random = G.Random
        local ok, message = pcall(function()
            G.Random = function()
                return 1
            end
            local all = G.New(0)
            for _, collection in ipairs(C.collections) do
                assert(not seenSets[collection.id])
                seenSets[collection.id] = true
                local kind = collection.kind or "outdoor"
                local profile =
                    S.Profile(kind == "dungeon" and "foreverDungeon16001" or "forever16001")
                local state = G.New(0)
                assert(not G.SetCollectionEffect(state, collection.id))
                for _, milestone in pairs(collection.milestones) do
                    assert(milestone.pieces <= #collection.pieces)
                end
                for _, itemID in ipairs(collection.pieces) do
                    assert(not seenItems[itemID] and C.collectionByItem[itemID] == collection.id)
                    seenItems[itemID] = true
                    local item, source = G.CollectionItem(itemID), profile.sources[itemID]
                    assert(item and item.itemID == itemID and item.name and item.icon)
                    assert(source and source.verified and source.name and source.zone)
                    if collection.id ~= "redridgeOutriders" then
                        assert(not (C.itemByID[itemID] and C.collectionItemByID[itemID]), itemID)
                        assert(not S.profiles.retail120105.sources[itemID])
                    end
                    assert(G.SetCollectionTarget(state, itemID))
                    if not G.CollectionBook(state, collection.id).pieces[itemID] then
                        local context = {
                            profile = profile.id,
                            kind = kind,
                            outdoor = kind == "outdoor",
                            dungeon = kind == "dungeon",
                            attributed = true,
                            npcID = source.npcID,
                        }
                        context.receipt =
                            string.format("kill:Creature-0-1-1-1-%d-%012X", source.npcID, itemID)
                        assert(G.CollectionKill(state, context))
                        assert(not G.CollectionKill(state, context))
                        assert(G.Load(G.Copy(state), 0))
                    end
                    assert(G.CollectionBook(state, collection.id).pieces[itemID])
                    G.CollectionBook(all, collection.id).pieces[itemID] = true
                end
                assert(G.CollectionProgress(state, collection.id).complete)
                assert(G.SetCollectionEffect(state, collection.id))
                assert(G.Load(G.Copy(state), 0))
                assert(
                    state.essence == 0 and state.adventure.totalXP == 0 and #state.inventory == 0
                )
            end
            local bonuses = G.CollectionBonuses(all, "beast")
            assert(bonuses.basicAttack <= 1.05 and bonuses.materials <= 1.05)
        end)
        G.Random = random
        assert(ok, message)
    end
)

return cases
