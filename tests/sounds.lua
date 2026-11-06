local _, W = ...
if not W then
    return
end
local function fixture()
    local now, visible, played = 0, true, {}
    local namespace = { L = W.L, state = W.Game.New(1000) }
    local frame = {
        IsShown = function()
            return visible
        end,
    }
    namespace.UI = { frame = frame }
    local env = setmetatable({
        GetTime = function()
            return now
        end,
        SOUNDKIT = setmetatable({}, {
            __index = function(_, key)
                return #key
            end,
        }),
        PlaySound = function(kit, channel)
            assert(channel == "SFX")
            played[#played + 1] = kit
            return true, #played
        end,
        StopSound = function() end,
    }, { __index = _G })
    local chunk = assert(loadfile("Compatibility/Sounds.lua"))
    setfenv(chunk, env)
    chunk("AFKraft", namespace)
    local function emit(kind, data)
        data = data or {}
        data.kind = kind
        namespace.OnGameEvent(namespace.state, data)
    end
    return namespace,
        emit,
        played,
        function(value, shown)
            now = value
            visible = shown ~= false
        end,
        env
end
return {
    {
        "Every rendered creature and boss has native attack, wound, entrance and death audio",
        function()
            local assets = { Content = W.Content }
            assert(loadfile("Compatibility/Models.lua"))("AFKraft", assets)
            local creatures = {}
            for _, zone in pairs(assets.ModelAssets.zones) do
                creatures[zone.boss] = true
                for _, creatureID in ipairs(zone.enemies) do
                    creatures[creatureID] = true
                end
            end
            for _, creatureID in pairs(assets.ModelAssets.creatures) do
                creatures[creatureID] = true
            end
            for creatureID in pairs(creatures) do
                local n, emit, played, advance, env = fixture()
                env.SOUNDKIT = {} -- Generic cues cannot satisfy creature coverage.
                n.Client = {
                    ModelSpec = function()
                        return { creatureID = creatureID }
                    end,
                }
                n.state.battle = { enemies = { { name = "Creature", hp = 50 } } }
                emit("encounter")
                n.Audio.Flush()
                assert(#played == 1, "Missing entrance: " .. creatureID)
                advance(5)
                emit("hit", { enemy = false, source = 1 })
                n.Audio.Flush()
                assert(#played == 2, "Missing attack: " .. creatureID)
                advance(7)
                emit("hit", { enemy = true, target = 1 })
                n.Audio.Flush()
                assert(#played == 3, "Missing wound: " .. creatureID)
                advance(9)
                emit("death", { enemy = true, target = 1 })
                n.Audio.Flush()
                assert(#played == 4, "Missing death: " .. creatureID)
            end
        end,
    },
    {
        "New creature voices match their rendered families",
        function()
            for creatureID, kits in pairs({
                [30] = { 423, 426, 422, 424 }, -- Spider
                [3107] = { 1225, 1228, 1230, 1226 }, -- Crab
                [5850] = { 1283, 1286, 1288, 1284 }, -- Fire elemental
                [1802] = { 3419, 3422, 3424, 3420 }, -- Shade
                [7040] = { 367, 369, 367, 370 }, -- Dragonspawn
                [687] = { 704, 707, 708, 705 }, -- Jungle Stalker is a raptor.
                [5251] = { 306, 308, 1015, 309 }, -- Woodpaw Trapper uses a gnoll.
                [23919] = { 736, 738, 739, 737 }, -- Ice elemental uses the earth model.
            }) do
                local n, emit, played, advance = fixture()
                n.Client = {
                    ModelSpec = function()
                        return { creatureID = creatureID }
                    end,
                }
                n.state.battle = { enemies = { { name = "Creature", hp = 50 } } }
                emit("encounter")
                n.Audio.Flush()
                advance(5)
                emit("hit", { enemy = false, source = 1 })
                n.Audio.Flush()
                advance(7)
                emit("hit", { enemy = true, target = 1 })
                n.Audio.Flush()
                advance(9)
                emit("death", { enemy = true, target = 1 })
                n.Audio.Flush()
                assert(played[1] == kits[3] and played[2] == kits[1])
                assert(played[4] == kits[4] and played[5] == kits[2])
            end
        end,
    },
    {
        "Audio prioritizes milestones and bounds repeated combat",
        function()
            local n, emit, played, advance = fixture()
            for _ = 1, 30 do
                emit("hit")
            end
            emit("levelup")
            n.Audio.Flush()
            assert(#played == 1 and played[1] == 888)
            advance(4)
            emit("hit")
            n.Audio.Flush()
            advance(4.5)
            emit("hit")
            n.Audio.Flush()
            assert(#played == 2)
            advance(6)
            emit("hit")
            n.Audio.Flush()
            assert(#played == 3)
        end,
    },
    {
        "Character level-up fanfare is native and cannot be interrupted by ordinary cues",
        function()
            local n, emit, played, advance, env = fixture()
            env.SOUNDKIT = {}
            emit("levelup")
            n.Audio.Flush()
            assert(#played == 1 and played[1] == 888)
            env.SOUNDKIT.UI_GARRISON_FOLLOWER_LEARN_TRAIT = 1
            advance(2.5)
            emit("unlock")
            n.Audio.Flush()
            assert(#played == 1)
            advance(4)
            emit("unlock")
            n.Audio.Flush()
            assert(#played == 2)
        end,
    },
    {
        "Audio respects categories, master mute, hidden windows and catch-up",
        function()
            local n, emit, played, advance = fixture()
            n.state.settings.soundDeaths = false
            emit("death", { enemy = true })
            n.Audio.Flush()
            n.state.settings.soundEnabled = false
            emit("levelup")
            n.Audio.Flush()
            n.state.settings.soundEnabled = true
            advance(4, false)
            emit("levelup")
            n.Audio.Flush()
            advance(8)
            n.catchup = {}
            emit("levelup")
            n.Audio.Flush()
            n.catchup = nil
            n.Audio.Flush()
            assert(#played == 0)
            emit("levelup")
            n.state.settings.soundProgression = false
            n.Audio.Flush()
            assert(#played == 0)
        end,
    },
    {
        "Audio mutes other panels, discards queued cues and resumes in compact mode",
        function()
            local n, emit, played, advance, env = fixture()
            local stopped = {}
            env.StopSound = function(handle)
                stopped[#stopped + 1] = handle
            end
            emit("hit")
            n.Audio.Flush()
            assert(#played == 1)
            advance(2)
            emit("levelup")
            for _, tab in ipairs({ "party", "talents", "crafting", "atlas", "legacy", "loot" }) do
                n.state.ui.tab = tab
                emit("hit")
                n.Audio.Flush()
                assert(#played == 1)
            end
            assert(#stopped == 1)
            n.state.ui.tab = "adventure"
            n.Audio.Flush()
            assert(#played == 1)
            emit("hit")
            n.Audio.Flush()
            assert(#played == 2)
            advance(4)
            n.state.ui.tab = "party"
            n.state.ui.compact = true
            emit("hit")
            n.Audio.Flush()
            assert(#played == 3)
        end,
    },
    {
        "Unavailable client kits are silent and do not break playback",
        function()
            local n, emit, played, advance, env = fixture()
            env.SOUNDKIT = {}
            emit("hit")
            n.Audio.Flush()
            assert(#played == 0)
            env.SOUNDKIT.UI_ADVENTURES_DAMAGE_SWEETENER_MEDIUM = 165960
            advance(2)
            emit("hit")
            n.Audio.Flush()
            assert(#played == 1)
        end,
    },
    {
        "Creature calls and deaths follow the rendered NPC, not its adventure name",
        function()
            local n, emit, played, advance = fixture()
            n.Client = {
                ModelSpec = function()
                    return { creatureID = 448 }
                end,
            }
            n.state.battle = { enemies = { { name = "Hogger" } } }
            emit("encounter", { boss = false })
            n.Audio.Flush()
            assert(played[1] == 1015)
            advance(5)
            emit("hit", { enemy = false, source = 1 })
            n.Audio.Flush()
            assert(played[2] == 306)
            advance(7)
            emit("death", { enemy = true, target = 1 })
            n.state.battle = nil -- The controller may finish the battle before flushing.
            n.Audio.Flush()
            assert(played[3] == 308)
        end,
    },
    {
        "Melee impacts include appearance-specific exertions and stop both handles",
        function()
            local n, emit, played, advance, env = fixture()
            n.state.heroes = { { class = "WARRIOR", appearance = "orc_female" } }
            local stopped = {}
            env.StopSound = function(handle)
                stopped[#stopped + 1] = handle
            end
            emit("hit", { enemy = true, source = 1 })
            n.Audio.Flush()
            assert(played[1] == 235 and played[2] == 209)
            advance(0.1)
            emit("hit", { enemy = true, source = 1 })
            n.Audio.Flush()
            assert(#played == 2)
            advance(1, false)
            n.Audio.Flush()
            assert(#stopped == 2)
        end,
    },
    {
        "Live player voices follow race and sex while casters avoid weapon impacts",
        function()
            local n, emit, played, advance, env = fixture()
            n.Client = {
                Identity = function()
                    return { guid = "player" }
                end,
            }
            n.state.heroes = { { guid = "player", class = "MAGE", appearance = "human_male" } }
            env.UnitRace = function()
                return "Night Elf", "NightElf"
            end
            env.UnitSex = function()
                return 3
            end
            emit("hit", { enemy = true, source = 1 })
            n.Audio.Flush()
            assert(#played == 1 and played[1] == 2933)
            advance(2)
            emit("death", { enemy = false, target = 1 })
            n.Audio.Flush()
            assert(played[2] == 2936)
        end,
    },
    {
        "Both sides of an exchange play attacks and surviving targets' wounds",
        function()
            local n, emit, played, advance = fixture()
            n.Client = {
                ModelSpec = function()
                    return { creatureID = 448 }
                end,
            }
            n.state.heroes = { { class = "WARRIOR", appearance = "human_male" } }
            n.state.battle = {
                heroes = { { hp = 50 } },
                enemies = { { name = "Hogger", hp = 50 } },
            }
            emit("hit", { enemy = true, source = 1, target = 1 })
            emit("hit", { enemy = false, source = 1, target = 1 })
            n.Audio.Flush()
            assert(#played == 5)
            assert(played[1] == 235 and played[2] == 2941 and played[3] == 309)
            assert(played[4] == 306 and played[5] == 2942)
            advance(0.8)
            emit("hit", { enemy = false, source = 1, target = 1 })
            n.Audio.Flush()
            assert(#played == 5)
            advance(1.3)
            emit("hit", { enemy = false, source = 1, target = 1 })
            n.Audio.Flush()
            assert(#played == 7)
        end,
    },
    {
        "Creatures without an aggro kit keep wounds separate from entrance calls",
        function()
            local n, emit, played, advance = fixture()
            n.Client = {
                ModelSpec = function()
                    return { creatureID = 3425 }
                end,
            }
            n.state.battle = { enemies = { { name = "Savannah prowler", hp = 50 } } }
            emit("encounter")
            n.Audio.Flush()
            assert(played[1] == 643)
            advance(2)
            emit("hit", { enemy = true, target = 1 })
            n.Audio.Flush()
            assert(played[#played] == 644)
        end,
    },
    {
        "Lethal hits skip wounds and combat mute discards both sides",
        function()
            local n, emit, played, advance = fixture()
            n.Client = {
                ModelSpec = function()
                    return { creatureID = 448 }
                end,
            }
            n.state.heroes = { { class = "WARRIOR", appearance = "human_male" } }
            n.state.battle = { enemies = { { name = "Hogger", hp = 0 } } }
            emit("hit", { enemy = true, source = 1, target = 1 })
            n.Audio.Flush()
            assert(#played == 2 and played[1] == 235 and played[2] == 2941)
            advance(2)
            emit("hit", { enemy = true, source = 1, target = 1 })
            emit("hit", { enemy = false, source = 1, target = 1 })
            n.state.settings.soundCombat = false
            n.Audio.Flush()
            assert(#played == 2)
            n.state.settings.soundCombat = true
            n.Audio.Flush()
            assert(#played == 2)
        end,
    },
    {
        "Sound settings migration retains explicit category mutes",
        function()
            local state = W.Game.New(1000)
            state.settings = { soundEnabled = false, soundDeaths = false }
            assert(W.Game.Load(state, 1000))
            assert(state.settings.soundCombat and state.settings.soundProgression)
            assert(not state.settings.soundEnabled and not state.settings.soundDeaths)
        end,
    },
    {
        "Lethal combat emits one death event per defeated unit",
        function()
            local state = W.Game.New(1000)
            W.Game.AddHero(state, "WARRIOR")
            W.Game.AddHero(state, "PRIEST")
            W.Game.AddHero(state, "MAGE") -- Use a three-enemy encounter.
            W.Game.StartBattle(state)
            for _, enemy in ipairs(state.battle.enemies) do
                enemy.hp = 1
            end
            state.battle.heroes[1].damage = 10000
            state.heroes[1].talents.cleave = true
            state.events = {}
            local battle = state.battle
            for _ = 1, 80 do
                W.Game.Step(state, 0.25)
                if state.battle ~= battle then
                    break
                end
            end
            local deaths = 0
            for _, event in ipairs(state.events) do
                if event.kind == "death" and event.enemy then
                    deaths = deaths + 1
                end
            end
            assert(deaths == 3)
        end,
    },
}
