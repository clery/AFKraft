local _, W = ...
if not W then
    return
end
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
case("Dungeon profiles keep outdoor, Retail and Forever mappings separate", function()
    local S = W.CollectionSources
    assert(not S.Eligible("foreverDungeon16001", 639))
    assert(not S.Eligible("forever16001", 423, "dungeon"))
    for itemID, npcID in pairs({
        [10399] = 639,
        [10400] = 634,
        [10401] = 634,
        [10402] = 4416,
        [10403] = 647,
    }) do
        local pieces, profile = S.Eligible("foreverDungeon16001", npcID, "dungeon")
        local found = false
        for _, piece in ipairs(pieces) do
            found = found or piece == itemID
        end
        assert(found and profile.kind == "dungeon" and profile.chance == 20)
    end
end)
case(
    "Dungeon adapter derives context and refuses raids, secrets, offline and other clients",
    function()
        local client, build, instance, secret, kill =
            W.Client, GetBuildInfo, IsInInstance, issecretvalue, W.Game.CollectionKill
        local calls, inside, instanceKind, interface = {}, true, "party", 16001
        local ok, message = pcall(function()
            W.Client = { flavor = "forever" }
            GetBuildInfo = function()
                return "", "", "", interface
            end
            IsInInstance = function()
                return inside, instanceKind
            end
            issecretvalue = function(value)
                return value == "secret"
            end
            W.Game.CollectionKill = function(_, context)
                calls[#calls + 1] = context
                return true
            end
            local S, guid = W.CollectionSources, "Creature-0-1-2-3-639-000001"
            assert(S.ActiveProfile().id == "forever16001")
            assert(S.ActiveProfile("dungeon").id == "foreverDungeon16001")
            assert(S.ObserveKill({}, guid))
            assert(
                #calls == 1
                    and calls[1].dungeon
                    and not calls[1].outdoor
                    and calls[1].kind == "dungeon"
                    and calls[1].attributed
            )
            assert(not S.ObserveKill({ offline = true }, guid))
            for _, kind in ipairs({ "raid", "arena", "pvp", "scenario", "secret" }) do
                instanceKind = kind
                assert(not S.ObserveKill({}, guid))
            end
            instanceKind = "party"
            inside = false
            assert(not S.ObserveKill({}, guid))
            inside = true
            assert(not S.ObserveKill({}, "secret"))
            assert(not S.ObserveKill({}, "Player-1-123"))
            interface = 16002
            assert(not S.ObserveKill({}, guid))
            interface, W.Client.flavor = 120105, "retail"
            assert(not S.ActiveProfile("dungeon") and not S.ObserveKill({}, guid))
            assert(#calls == 1)
        end)
        W.Client, GetBuildInfo, IsInInstance, issecretvalue, W.Game.CollectionKill =
            client, build, instance, secret, kill
        assert(ok, message)
    end
)
case(
    "Dungeon attribution observes below-cap kills while rejecting denied, stale and unowned kills",
    function()
        local host = { dead = false, denied = false, time = 1, tapped = true, loot = false }
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
                ActiveProfile = function(kind)
                    if kind == "dungeon" then
                        return {}
                    end
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
                return "Creature-0-1-2-3-639-000001"
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
                return host.tapped
            end,
            UnitThreatSituation = function()
                return nil
            end,
            CanLootUnit = function()
                return false, host.loot
            end,
        }, { __index = _G })
        setfenv(assert(loadfile("Compatibility/Kills.lua")), env)("WoWIdle", ns)
        ns.KillRewards.Observe({}, "target")
        host.dead = true
        ns.KillRewards.Observe({}, "target")
        assert(collected == 1 and rewarded == 0)
        host.denied = true
        ns.KillRewards.Observe({}, "target")
        assert(collected == 1)
        host.denied, host.time = false, 122
        ns.KillRewards.Observe({}, "target")
        assert(collected == 1)
        host.loot = true
        ns.KillRewards.Observe({}, "target")
        assert(collected == 2 and rewarded == 0)
        host.dead, host.loot, host.tapped = false, false, false
        ns.KillRewards.units = {}
        ns.KillRewards.Observe({}, "target")
        host.dead = true
        ns.KillRewards.Observe({}, "target")
        assert(collected == 2)
    end
)
return cases
