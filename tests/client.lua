-- Client adapter specifications run with an isolated host API fixture.
local _, W = ...
if not W then
    return
end

local cases = {}

local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

local function adapter(version, overrides)
    local namespace = { Content = W.Content, Game = W.Game }
    local secret = {}
    local environment = setmetatable({
        GetBuildInfo = function()
            return version
        end,
        UnitLevel = function()
            return 20
        end,
        GetInstanceInfo = function()
            return "Dungeon", "party", 1, "Normal", 5, 0, false, 36, 5, 101
        end,
        GetLFGDungeonInfo = function()
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
        GetServerTime = function()
            return 1000
        end,
        UnitClass = function()
            return "Warrior", "WARRIOR"
        end,
        UnitName = function()
            return "Adventurer"
        end,
        UnitGUID = function()
            return "test-character"
        end,
        issecretvalue = function(value)
            return value == secret
        end,
        CombatLogGetCurrentEventInfo = function()
            error("Combat log reads are forbidden in this fixture")
        end,
    }, { __index = _G })
    for name, value in pairs(overrides or {}) do
        environment[name] = value
    end
    local chunk = assert(loadfile("Compatibility/Client.lua"))
    assert(loadfile("Compatibility/Models.lua"))("WoWIdle", namespace)
    setfenv(chunk, environment)
    chunk("WoWIdle", namespace)
    local maps = assert(loadfile("Compatibility/Maps.lua"))
    setfenv(maps, environment)
    maps("WoWIdle", namespace)
    local dungeons = assert(loadfile("Compatibility/Dungeons.lua"))
    setfenv(dungeons, environment)
    dungeons("WoWIdle", namespace)
    return namespace.Client, secret
end

case("Nameplate artwork follows native style on each client", function()
    for _, version in ipairs({ "12.1.5", "1.60.1" }) do
        for _, classic in ipairs({ true, false }) do
            local client =
                adapter(version, { NamePlateSetupOptions = { useClassicHealthBar = classic } })
            local calls = {}
            local function region(kind)
                return setmetatable({}, {
                    __index = function(_, method)
                        return function(_, ...)
                            calls[kind .. method] = { ... }
                        end
                    end,
                })
            end
            local bar, background, fill, border =
                region("bar"), region("bg"), region("fill"), region("border")
            function bar:GetStatusBarTexture()
                return fill
            end
            function bar:CreateTexture()
                return border
            end
            function bar:GetWidth()
                return 124
            end
            function bar:GetHeight()
                return 10
            end
            client.StyleNameplate(bar, background)
            if classic then
                assert(
                    calls.barSetStatusBarTexture[1]
                        == "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
                )
                assert(calls.borderSetTexture[1] == "Interface\\Tooltips\\Nameplate-Border")
                assert(calls.borderSetTexCoord[3] == 0.5)
                assert(not calls.fillSetAtlas and not calls.bgSetAtlas)
            else
                assert(calls.fillSetAtlas[1] == "UI-HUD-CoolDownManager-Bar")
                assert(calls.bgSetAtlas[1] == "UI-HUD-CoolDownManager-Bar-BG")
                assert(not calls.borderSetTexture)
            end
        end
    end
end)

case("Both clients register only public reward events", function()
    for _, version in ipairs({ "12.1.5", "1.60.1" }) do
        local client = adapter(version)
        local registered = {}
        local frame = {
            RegisterEvent = function(_, event)
                registered[event] = true
                assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED", "Protected registration attempted")
                assert(event ~= "COMBAT_LOG_EVENT", "Protected registration attempted")
            end,
        }
        client.Register(frame)
        -- Assert after registration too: pcall could swallow the fixture's error,
        -- just as it cannot prevent the client's forbidden-action notification.
        assert(not registered.COMBAT_LOG_EVENT_UNFILTERED)
        assert(not registered.COMBAT_LOG_EVENT)
        assert(registered.QUEST_TURNED_IN)
        assert(registered.PLAYER_LEVEL_UP)
        assert(registered.BOSS_KILL)
        assert(registered.CHAT_MSG_COMBAT_XP_GAIN)
    end
end)

case("Simultaneous combat-XP awards grant distinct kill rewards", function()
    local client = adapter("12.1.5")
    local state = W.Game.New(1000)
    client.Event(state, "CHAT_MSG_COMBAT_XP_GAIN", "A creature dies; you gain experience.")
    client.Event(state, "CHAT_MSG_COMBAT_XP_GAIN", "A creature dies; you gain experience.")
    assert(state.essence == 0 and state.adventure.xp == 2)
end)

case("Empty and secret combat-XP messages do not grant rewards", function()
    local client, secret = adapter("12.1.5")
    local state = W.Game.New(1000)
    client.Event(state, "CHAT_MSG_COMBAT_XP_GAIN", nil)
    client.Event(state, "CHAT_MSG_COMBAT_XP_GAIN", "")
    client.Event(state, "CHAT_MSG_COMBAT_XP_GAIN", secret)
    client.Event(state, "COMBAT_LOG_EVENT_UNFILTERED")
    assert(state.essence == 0)
end)

case("Quest, level, and boss rewards remain active and deduplicate", function()
    local client = adapter("12.1.5")
    local state = W.Game.New(1000)
    for _ = 1, 2 do
        client.Event(state, "QUEST_TURNED_IN", 123)
        client.Event(state, "PLAYER_LEVEL_UP", 12)
        client.Event(state, "BOSS_KILL", 456)
    end
    assert(state.essence == 0 and state.adventure.totalXP == 50)
    assert(state.discoveries["boss:456"])
end)

case(
    "Companions use complete NPC appearances and the current player keeps their unit model",
    function()
        local client = adapter("12.1.5")
        for _, class in ipairs(W.Content.classes) do
            for _, appearance in ipairs(W.Content.appearances[class.id]) do
                local spec = client.ModelSpec({ class = class.id, appearance = appearance })
                assert(spec and spec.creatureID and not spec.unit)
                local creature
                local model = {
                    ClearModel = function() end,
                    SetCreature = function(_, id)
                        creature = id
                    end,
                    SetDisplayInfo = function()
                        error("Bare display IDs must not be used")
                    end,
                    SetPortraitZoom = function() end,
                    SetCamDistanceScale = function() end,
                    SetFacing = function() end,
                }
                assert(client.ConfigureModel(model, spec, false))
                assert(creature == spec.creatureID)
            end
        end
        local player = client.ModelSpec({ guid = "test-character", class = "WARRIOR" })
        assert(player.unit == "player" and not player.creatureID)
    end
)

case("Enemy models follow each named creature and unknown assets fall back safely", function()
    local client = adapter("12.1.5")
    for _, zone in ipairs(W.Content.zones) do
        for _, name in ipairs(zone.enemies) do
            assert(client.ModelSpec(nil, zone.id, name).creatureID)
        end
        assert(client.ModelSpec(nil, zone.id, zone.boss).creatureID)
    end
    local boar = client.ModelSpec(nil, "durotar", "Savannah boar")
    local scorpid = client.ModelSpec(nil, "durotar", "Scorpid hunter")
    local scout = client.ModelSpec(nil, "durotar", "Razormane scout")
    assert(boar.key ~= scorpid.key and scorpid.key ~= scout.key)
    assert(client.ModelSpec(nil, "unknown-zone", "Unknown enemy") == nil)
    assert(client.ModelSpec(nil, "durotar", "Unknown enemy") == nil)
    assert(not client.ConfigureModel({}, nil, false))
    assert(not client.ConfigureModel({
        ClearModel = function()
            error("Unavailable")
        end,
    }, boar, true))
end)

case("Creature framing survives loading and resets when a slot changes creature", function()
    local client = adapter("12.1.5")
    local dust = client.ModelSpec(nil, "westfall", "Dust devil")
    local normal = client.ModelSpec(nil, "westfall", "Defias cutpurse")
    local distance
    local model = {
        ClearModel = function() end,
        SetCreature = function() end,
        SetPortraitZoom = function() end,
        SetFacing = function() end,
        SetCamDistanceScale = function(_, value)
            distance = value
        end,
    }
    assert(client.ConfigureModel(model, dust, true))
    local dustDistance = distance
    assert(client.ConfigureModel(model, normal, true))
    assert(dustDistance > distance)
    client.FrameModel(model, true, dust)
    assert(distance == dustDistance)
    client.FrameModel(model, true, normal)
    assert(distance == 1.7)
end)

case("Native map hit testing resolves city submaps to their adventure zone", function()
    local client = adapter("12.1.5", {
        C_Map = {
            GetMapInfoAtPosition = function()
                return { mapID = 84, parentMapID = 37 }
            end,
            GetMapInfo = function(id)
                return id == 37 and { mapID = 37, parentMapID = 13 } or nil
            end,
        },
    })
    assert(client.ZoneAtPosition("eastern", 0.5, 0.5).id == "elwynn")
end)

case(
    "Retail markers follow artwork and every region remains clickable without native hit data",
    function()
        local client = adapter("12.1.5", { C_Map = {} })
        for _, zone in ipairs(W.Content.zones) do
            local found = 0
            for _, continent in ipairs({ "kalimdor", "eastern" }) do
                local x, y = client.ZonePosition(zone.id, continent)
                if x then
                    found = found + 1
                    assert(client.ZoneAtPosition(continent, x, y).id == zone.id)
                    -- Click well away from the 20-pixel marker on a 616-pixel map.
                    local offset = zone.id == "westfall" and -0.018 or 0.018
                    assert(
                        client.ZoneAtPosition(continent, x + offset, y + 0.020).id == zone.id,
                        zone.id
                    )
                end
            end
            assert(found == 1)
        end
        assert(not client.ZoneAtPosition("eastern", 0.2, 0.2))
        assert(not client.ZoneAtPosition("eastern", -0.1, 0.8))
    end
)

case("Native zone borders take precedence over fallback artwork outlines", function()
    local client = adapter("12.1.5", {
        C_Map = {
            GetMapInfoAtPosition = function()
                return { mapID = 999, mapType = 3, parentMapID = 13 }
            end,
        },
    })
    assert(not client.ZoneAtPosition("eastern", 0.475, 0.785))
end)

case("A different client discovers its own map IDs without importing Retail IDs", function()
    local client = adapter("1.60.1", {
        C_Map = {
            GetMapChildrenInfo = function()
                return {
                    { mapID = 1414, mapType = 2, name = "Kalimdor" },
                    { mapID = 1415, mapType = 2, name = "Eastern Kingdoms" },
                    { mapID = 1429, mapType = 3, name = "Elwynn Forest" },
                }
            end,
            GetMapRectOnMap = function(zone, continent)
                assert(zone == 1429 and continent == 1415)
                return 0.4, 0.6, 0.7, 0.8
            end,
        },
    })
    assert(client.MapID("eastern") == 1415)
    assert(client.MapID("elwynn") == 1429)
    local x, y = client.ZonePosition("elwynn", "eastern")
    assert(x == 0.5 and math.abs(y - 0.75) < 0.0001)
end)

return cases
