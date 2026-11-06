local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Activities share one XP bar and only completed ranks pay Essence", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    for i = 1, 4 do
        assert(G.ActivityReward(s, "quest:" .. i, "quest", "Quest"))
    end
    assert(s.adventure.xp == 80 and s.adventure.rank == 1 and s.essence == 0)
    assert(G.ActivityReward(s, "boss:1", "boss", "Boss"))
    assert(s.adventure.xp == 5 and s.adventure.rank == 2 and s.adventure.totalXP == 105)
    assert(s.essence == 60 and s.stats.essence == 60)
    assert(s.heroes[1].xp == 0 and s.heroes[1].level == 1)
    assert(not G.ActivityReward(s, "boss:1", "boss", "Boss"))
    assert(s.adventure.totalXP == 105 and s.essence == 60)
    assert(s.adventure.sources.quest.count == 4 and s.adventure.sources.quest.xp == 80)
end)

case("XP overflow can pay multiple ranks without dropping the remainder", function()
    local s = G.New(0)
    G.AdventureXP(s, 350, "test", "Large activity")
    assert(s.adventure.rank == 4 and s.adventure.xp == 50)
    assert(s.essence == 180 and s.stats.essence == 180)
end)

case("Quarter-XP skinning stays exact across rewards and reloads", function()
    local s = G.New(0)
    for i = 1, 399 do
        G.ActivityReward(s, "skin:" .. i, "skinning", "Skinning")
    end
    assert(s.adventure.xp == 99.75 and s.essence == 0)
    s = assert(G.Load(G.Copy(s), 1))
    G.ActivityReward(s, "skin:400", "skinning", "Skinning")
    assert(s.adventure.rank == 2 and s.adventure.xp == 0 and s.adventure.totalXP == 100)
    assert(s.essence == 60)
end)

case("Prestige retains global rank, partial XP, and unspent Essence", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    G.AdventureXP(s, 125, "test", "Activity")
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s))
    assert(s.adventure.rank == 2 and s.adventure.xp == 25 and s.essence == 60)
    assert(s.adventure.totalXP == 125)
end)

case("Version-one migration preserves previously earned currency and hero progression", function()
    local old = G.New(0)
    G.AddHero(old, "WARRIOR")
    old.version, old.adventure, old.essence = 1, nil, 237
    old.heroes[1].xp, old.stats.activityXP = 33, 500
    local migrated = assert(G.Load(old, 1))
    assert(migrated.version == W.Content.version and migrated.essence == 237)
    assert(migrated.heroes[1].xp == 33 and migrated.stats.activityXP == 500)
    assert(migrated.adventure.totalXP == 0 and migrated.adventure.rank == 1)
    assert(old.version == 1 and old.adventure == nil)
    assert(G.Load(migrated, 2).essence == 237)
end)

case("Invalid global progress is rejected without discarding the save", function()
    local s = G.New(0)
    s.adventure.xp, s.essence = -1, 200
    assert(not G.Load(s, 0))
    assert(s.adventure.xp == -1 and s.essence == 200)
end)

case("Rank payouts received during offline catch-up survive reconciliation", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 10))
    for i = 1, 5 do
        G.ActivityReward(s, "live:" .. i, "quest", "Quest")
    end
    while not G.CatchupBatch(job, 100) do
    end
    G.FinishCatchup(s, job)
    assert(s.adventure.rank == 2 and s.adventure.xp == 0)
    assert(s.essence == 60 and s.stats.essence == 60)
end)

local function dungeonAdapter()
    local n, now = { Content = W.Content, Game = G, L = W.L }, 1000
    local settings = { level = 20, visible = false, trivial = false }
    local host = setmetatable({
        GetBuildInfo = function()
            return "12.1.5"
        end,
        GetServerTime = function()
            return now
        end,
        UnitClass = function()
            return "Warrior", "WARRIOR"
        end,
        UnitName = function()
            return "Adventurer"
        end,
        UnitGUID = function()
            return "player-guid"
        end,
        GetInstanceInfo = function()
            return "Dungeon", "party", 1, "Normal", 5, 0, false, 36, 5, 101
        end,
        GetLFGDungeonInfo = function()
            if settings.unknown then
                return nil
            end
            return "Dungeon",
                1,
                1,
                10,
                90,
                20,
                18,
                26,
                0,
                0,
                nil,
                1,
                5,
                "",
                false,
                0,
                1,
                false,
                "",
                0,
                false,
                36
        end,
        UnitLevel = function()
            return settings.level
        end,
        UnitExists = function(unit)
            return settings.visible and unit == "boss1"
        end,
        UnitIsTrivial = function()
            return settings.trivial
        end,
        C_Loot = {
            IsLegacyLootModeEnabled = function()
                return settings.legacy or false
            end,
        },
        C_EventUtils = {
            IsEventValid = function(event)
                return event ~= "CHALLENGE_MODE_COMPLETED"
            end,
        },
    }, { __index = _G })
    for _, file in ipairs({ "Compatibility/Client.lua", "Compatibility/Dungeons.lua" }) do
        local chunk = assert(loadfile(file))
        setfenv(chunk, host)
        chunk("AFKraft", n)
    end
    return n, function(value)
        now = value
    end, settings
end

case(
    "Confirmed dungeon completions deduplicate across signals, reloads, and time buckets",
    function()
        local n, setTime = dungeonAdapter()
        local s = G.New(0)
        n.Client.Event(s, "LFG_COMPLETION_REWARD")
        setTime(1001)
        n.Client.Event(s, "CHALLENGE_MODE_COMPLETED")
        assert(s.adventure.totalXP == 40)
        local reloaded = assert(G.Load(G.Copy(s), 1002))
        n.Client.Event(reloaded, "LFG_COMPLETION_REWARD")
        assert(reloaded.adventure.totalXP == 40)
        setTime(1200)
        n.Client.Event(reloaded, "LFG_COMPLETION_REWARD")
        assert(reloaded.adventure.totalXP == 80)
        n.Client.Event(reloaded, "PLAYER_LEAVING_WORLD")
        assert(reloaded.adventure.totalXP == 80)
    end
)

case("Unsupported dungeon events are never registered", function()
    local n = dungeonAdapter()
    local events = {}
    n.DungeonRewards.Register({
        RegisterEvent = function(_, event)
            events[event] = true
        end,
    })
    assert(events.LFG_COMPLETION_REWARD and not events.CHALLENGE_MODE_COMPLETED)
end)

case("Boss and dungeon metadata reject characters outside the intended level bracket", function()
    for _, level in ipairs({ 17, 18, 26, 27 }) do
        local n, _, settings = dungeonAdapter()
        local s = G.New(0)
        settings.level = level
        n.Client.Event(s, "BOSS_KILL", 123, "Adventurer")
        n.Client.Event(s, "LFG_COMPLETION_REWARD")
        assert(s.adventure.totalXP == ((level == 18 or level == 26) and 65 or 0))
    end
end)

case(
    "Observed boss XP eligibility survives the boss disappearing and overrides metadata",
    function()
        for _, trivial in ipairs({ true, false }) do
            local n, _, settings = dungeonAdapter()
            local s = G.New(0)
            settings.visible, settings.trivial, settings.level = true, trivial, 60
            n.Client.Event(s, "ENCOUNTER_START", 123)
            settings.visible = false
            n.Client.Event(s, "BOSS_KILL", 123, "Adventurer")
            n.Client.Event(s, "LFG_COMPLETION_REWARD")
            assert(s.adventure.totalXP == (trivial and 0 or 65))
        end
    end
)

case(
    "Unknown level ranges and legacy farming never invent boss or completion eligibility",
    function()
        for _, mode in ipairs({ "unknown", "legacy" }) do
            local n, _, settings = dungeonAdapter()
            local s = G.New(0)
            settings[mode] = true
            n.Client.Event(s, "BOSS_KILL", 123, "Adventurer")
            n.Client.Event(s, "LFG_COMPLETION_REWARD")
            assert(s.adventure.totalXP == 0)
        end
    end
)

return cases
