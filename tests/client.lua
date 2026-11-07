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
    local namespace = { L = W.L, Content = W.Content, Game = W.Game }
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
    assert(loadfile("Compatibility/Models.lua"))("AFKraft", namespace)
    setfenv(chunk, environment)
    chunk("AFKraft", namespace)
    local equipment = assert(loadfile("Compatibility/Equipment.lua"))
    setfenv(equipment, environment)
    equipment("AFKraft", namespace)
    local framing = assert(loadfile("Compatibility/ModelFraming.lua"))
    setfenv(framing, environment)
    framing("AFKraft", namespace)
    local maps = assert(loadfile("Compatibility/Maps.lua"))
    setfenv(maps, environment)
    maps("AFKraft", namespace)
    assert(loadfile("Compatibility/MapMasks.lua"))("AFKraft", namespace)
    assert(loadfile("Compatibility/MapMasksForever.lua"))("AFKraft", namespace)
    local dungeons = assert(loadfile("Compatibility/Dungeons.lua"))
    setfenv(dungeons, environment)
    dungeons("AFKraft", namespace)
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

case("Measured model bounds fit the viewport at every size and origin", function()
    local client = adapter("12.1.5")
    for _, aspect in ipairs({ 260 / 240, 360 / 240 }) do
        for _, size in ipairs({ 0.1, 1, 100 }) do
            for _, pivot in ipairs({ -50, 0, 80 }) do
                local bottom = { x = -3 * size, y = -size, z = pivot }
                local top = { x = 5 * size, y = 2 * size, z = pivot + 6 * size }
                local scale, x, y, z = client.ModelFit(bottom, top, bottom, aspect)
                assert(scale and scale > 0)
                assert((bottom.z - z) * scale == 0)
                local radius = math.sqrt((top.x - bottom.x) ^ 2 + (top.y - bottom.y) ^ 2) / 2
                local distance = 6 - radius * scale
                local halfHeight = distance * math.tan(0.25)
                assert(radius * scale < halfHeight * aspect)
                assert((top.z - z) * scale - 0.6 < halfHeight)
                assert(0.6 < halfHeight)
                assert(math.abs(x / size - 1) < 0.00001 and math.abs(y / size - 0.5) < 0.00001)
                local larger = client.ModelFit(
                    { x = bottom.x * 2, y = bottom.y * 2, z = bottom.z * 2 },
                    { x = top.x * 2, y = top.y * 2, z = top.z * 2 },
                    { x = bottom.x * 2, y = bottom.y * 2, z = bottom.z * 2 },
                    aspect
                )
                assert(math.abs(larger * 2 / scale - 1) < 0.00001)
            end
        end
    end
    assert(not client.ModelFit(nil, nil, nil, 1))
    assert(not client.ModelFit({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, {}, 1))
end)

case("Wide model bounds produce wider visual contact footprints", function()
    local client = adapter("12.1.5")
    local bottom = { x = -0.5, y = -0.5, z = 0 }
    local top = { x = 0.5, y = 0.5, z = 2 }
    local narrow = client.ModelRadius(bottom, top, 360, 240, 0.5, 1.05)
    local wide = client.ModelRadius(
        { x = -2, y = -1, z = 0 },
        { x = 2, y = 1, z = 2 },
        360,
        240,
        0.5,
        1.05
    )
    assert(wide > narrow and wide <= 180)
    assert(client.ModelRadius({ x = -2, y = -1, z = 0 }, { x = 2, y = 1, z = 2 }, 360, 240) >= 80)
    assert(client.ModelRadius(nil, nil, 360, 240) == nil)
end)

case("Actor loading binds through its XML template without frame script methods", function()
    local called, creates = 0, 0
    local actor = setmetatable({ SetAlpha = function() end }, {
        __index = function(_, key)
            error("Unexpected actor method: " .. key)
        end,
    })
    local methods = {}
    for _, name in ipairs({
        "SetAllPoints",
        "EnableMouse",
        "SetCameraFieldOfView",
        "SetCameraPosition",
        "SetCameraOrientationByAxisVectors",
        "SetCameraNearClip",
        "SetCameraFarClip",
        "SetLightAmbientColor",
        "SetLightDiffuseColor",
        "SetLightDirection",
        "SetLightVisible",
        "SetModelAlpha",
        "Hide",
        "Show",
        "SetScript",
        "SetAlpha",
        "SetKeepModelOnHide",
        "RegisterEvent",
        "RegisterUnitEvent",
    }) do
        methods[name] = function() end
    end
    methods.CreateActor = function(_, name, template)
        assert(name == nil and template == "AFKraftAdventureActorTemplate")
        return actor
    end
    methods.SetKeepModelOnHide = function(self, keep)
        self.keepModel = keep
    end
    methods.SetIsFrameBuffer = function()
        error("Adventure scenes must preserve native viewport projection")
    end
    methods.SetAllowOverlappedModels = function(self, enabled)
        self.allowOverlappedModels = enabled
    end
    local client = adapter("12.1.5", {
        CreateFrame = function(kind, _, parent)
            creates = creates + 1
            assert(kind == ({ "Frame", "DressUpModel", "ModelScene" })[creates])
            return setmetatable({
                parent = parent,
                alpha = 1,
                scripts = {},
                SetScript = function(self, script, callback)
                    self.scripts[script] = callback
                end,
                SetAlpha = function(self, alpha)
                    self.alpha = alpha
                end,
                GetModelFileID = function()
                    return 42
                end,
            }, { __index = methods })
        end,
    })
    local model = client.CreateAdventureModel({}, function()
        called = called + 1
    end)
    assert(model.adventureActor == actor and creates == 3)
    assert(model.appearanceSource.parent == model)
    assert(model.adventureScene.parent == model)
    assert(model.adventureScene.allowOverlappedModels == true)
    assert(model.appearanceSource.allowOverlappedModels == nil)
    assert(model.appearanceSource.alpha == 0)
    assert(model.appearanceSource.keepModel == true)
    assert(model.alpha == 1 and model.adventureScene.alpha == 1)
    assert(model:GetModelFileID() == 42)
    model:SetAlpha(0.5)
    assert(model.appearanceSource.alpha == 0 and model.adventureScene.alpha == 1)
    actor.onModelLoaded()
    assert(called == 1)
    local refreshed, dressed = 0, 0
    model.appearanceSource.RefreshUnit = function()
        refreshed = refreshed + 1
    end
    model.appearanceSource.Dress = function()
        dressed = dressed + 1
    end
    model.appearanceUnit = "player"
    model.scripts.OnEvent(model, "UNIT_INVENTORY_CHANGED", "target")
    assert(refreshed == 0 and dressed == 0)
    model.scripts.OnEvent(model, "UNIT_INVENTORY_CHANGED", "player")
    model.scripts.OnEvent(model, "TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
    assert(refreshed == 2 and dressed == 0 and called == 3)
    model.appearanceUnit = nil
    model.scripts.OnEvent(model, "UNIT_INVENTORY_CHANGED", "player")
    assert(refreshed == 2 and dressed == 0 and called == 3)
    model.nativeAppearance = true
    model.equipmentAppliedKey = "equipped"
    model.applyingEquipment = true
    model.appearanceSource.scripts.OnModelLoaded()
    assert(called == 3 and model.equipmentAppliedKey == "equipped")
    model.applyingEquipment = false
    model.appearanceSource.scripts.OnModelLoaded()
    assert(called == 4 and model.equipmentAppliedKey == "equipped")
    assert(model.adventureScene.scripts.OnUpdate)
    model.appearanceSource.scripts.OnHide()
    assert(model.equipmentAppliedKey == nil)
    model.equipmentAppliedKey = "stale"
    model.appearanceSource.scripts.OnShow()
    assert(model.equipmentAppliedKey == nil and called == 5)
    assert(model.adventureScene.scripts.OnUpdate)
    model.nativeAppearance = false
    model.appearanceSource.scripts.OnShow()
    assert(called == 5)
    model.pendingEquipment = { [13101] = true }
    model.equipmentAppliedKey = "partial"
    model.scripts.OnEvent(model, "ITEM_DATA_LOAD_RESULT", 13101, true)
    assert(model.pendingEquipment[13101] == nil and model.equipmentAppliedKey == nil)
    assert(called == 6 and model.adventureScene.scripts.OnUpdate)
    -- Older clients may not expose native scene overlap control.
    methods.SetAllowOverlappedModels = nil
    creates = 0
    local fallback = client.CreateAdventureModel({}, function() end)
    assert(fallback.adventureScene.allowOverlappedModels == nil and creates == 3)
end)

case("Adventure model layers reset after parent reordering", function()
    local client = adapter("12.1.5")
    local function frame(level)
        return {
            level = level,
            GetFrameLevel = function(self)
                return self.level
            end,
            SetFrameLevel = function(self, value)
                self.level = value
            end,
        }
    end
    local model = frame(100)
    model.appearanceSource = frame(180)
    model.adventureScene = frame(190)
    client.SetAdventureModelFrameLevel(model, 32)
    assert(model.level == 32)
    assert(model.appearanceSource.level == 33 and model.adventureScene.level == 33)
    client.SetAdventureModelFrameLevel(model, 72)
    assert(model.level == 72)
    assert(model.appearanceSource.level == 73 and model.adventureScene.level == 73)
end)

case(
    "Native characters wear idle equipment without live transmog or display-ID conversion",
    function()
        local client = adapter("12.1.5")
        local flags, sourceAlpha, actorAlpha, hidden, animation = {}, 0, 0, false, nil
        local dressed, undressed, tried = 0, 0, {}
        local cameraPosition
        local fileID
        local source = {
            ClearModel = function()
                fileID = nil
            end,
            ClearAllPoints = function() end,
            SetPoint = function() end,
            SetSize = function(_, width, height)
                flags.warm = width == 1 and height == 1
            end,
            SetAllPoints = function()
                flags.warm = false
            end,
            SetAlpha = function(_, alpha)
                sourceAlpha = alpha
            end,
            SetAutoDress = function(_, enabled)
                flags.auto = enabled
            end,
            SetUseTransmogSkin = function(_, enabled)
                flags.skin = enabled
            end,
            SetUseTransmogChoices = function(_, enabled)
                flags.preview = enabled
            end,
            SetObeyHideInTransmogFlag = function(_, enabled)
                flags.hidden = enabled
            end,
            SetUnit = function(_, unit)
                assert(
                    unit == "player"
                        and flags.auto == false
                        and flags.skin == false
                        and flags.hidden
                )
                assert(flags.preview == false)
                assert(flags.warm and flags.parentAlpha == 1)
                fileID = 42
            end,
            SetCreature = function(_, id)
                assert(id == 911 and flags.auto == false and flags.skin == false)
                assert(flags.warm and flags.parentAlpha == 1)
                fileID = 42
            end,
            Dress = function()
                dressed = dressed + 1
            end,
            Undress = function()
                undressed = undressed + 1
                tried = {}
            end,
            TryOn = function(_, link)
                tried[#tried + 1] = link
            end,
            GetModelFileID = function()
                return fileID
            end,
            GetWidth = function()
                return 360
            end,
            GetHeight = function()
                return 240
            end,
            RefreshCamera = function() end,
            SetCamera = function(_, index)
                assert(index == 0)
                cameraPosition = { 3, 4, 1 }
            end,
            GetCameraPosition = function()
                return unpack(cameraPosition)
            end,
            GetCameraTarget = function()
                return 0, 0, 1
            end,
            SetCustomCamera = function(_, index)
                assert(index == 1)
            end,
            SetCameraPosition = function(_, x, y, z)
                cameraPosition = { x, y, z }
            end,
            SetCameraTarget = function(_, x, y, z)
                assert(x == 0 and y == 0 and z == 1)
            end,
            SetPortraitZoom = function() end,
            SetCamDistanceScale = function() end,
            SetRotation = function(_, facing, animate)
                assert(facing == 1.05 and animate == false)
            end,
            SetAnimation = function(_, value)
                animation = value
            end,
        }
        local model = {
            SetAlpha = function(_, alpha)
                flags.parentAlpha = alpha
            end,
            appearanceSource = source,
            adventureActor = {
                ClearModel = function() end,
                SetScale = function() end,
                SetPosition = function() end,
                SetModelByFileID = function(_, file)
                    assert(file == 42)
                end,
                IsLoaded = function()
                    return true
                end,
                GetModelFileID = function()
                    return 42
                end,
                GetActiveBoundingBox = function()
                    return -2, -1, 0, 2, 1, 3
                end,
                SetAlpha = function(_, value)
                    actorAlpha = value
                end,
            },
            adventureScene = {
                SetScript = function() end,
                Show = function()
                    hidden = false
                end,
                Hide = function()
                    hidden = true
                end,
            },
        }
        function model:ClearModel()
            source:ClearModel()
        end
        function model:SetUnit(unit)
            source:SetUnit(unit)
        end
        function model:SetCreature(id)
            source:SetCreature(id)
        end
        local geometryReady = false
        source.IsGeoReady = function()
            return geometryReady
        end
        local playerSpec = {
            key = "player:test",
            unit = "player",
            equipment = { 25, 821 },
            equipmentKey = "25:821",
        }
        assert(client.ConfigureModel(model, playerSpec, false))
        assert(model.loadingAppearance and flags.warm and not hidden and undressed == 0)
        assert(not client.FrameAdventureModel(model, false, playerSpec))
        geometryReady = true
        assert(client.FrameAdventureModel(model, false, playerSpec))
        assert(dressed == 0 and undressed == 1 and tried[1] == "item:25" and tried[2] == "item:821")
        assert(sourceAlpha == 1 and actorAlpha == 0 and hidden)
        assert(model.loadingAppearance == false and flags.warm == false)
        assert(model.spacingRadius > 80)
        local elevatedZ = cameraPosition[3]
        assert(elevatedZ > 1)
        assert(
            math.abs(cameraPosition[1] ^ 2 + cameraPosition[2] ^ 2 + (elevatedZ - 1) ^ 2 - 25)
                < 0.00001
        )
        assert(client.AnimateModel(model, 16) and animation == 16)
        model.adventureActor.IsLoaded = function()
            return false
        end
        assert(
            client.ConfigureModel(
                model,
                { key = "companion:911", creatureID = 911, equipment = {}, equipmentKey = "" },
                false
            )
        )
        assert(dressed == 0 and undressed == 2 and #tried == 0)
        assert(sourceAlpha == 1 and actorAlpha == 0 and hidden)
        client.PrepareAppearanceLoad(model)
        fileID = nil
        assert(not client.FrameAdventureModel(model, false, { key = "companion:911" }))
        assert(model.loadingAppearance and flags.warm and flags.parentAlpha == 1)
        fileID = 42
        assert(client.FrameAdventureModel(model, false, { key = "companion:911" }))
        assert(model.loadingAppearance == false and flags.warm == false)
        assert(cameraPosition[3] == elevatedZ)
        source.GetCameraPosition = function()
            return nil
        end
        assert(client.FrameAdventureModel(model, false, { key = "companion:911" }))
    end
)

case("Missing source models are requested again without clearing loaded geometry", function()
    local client = adapter("12.1.5")
    for _, spec in ipairs({ { unit = "player" }, { creatureID = 911 } }) do
        local update, file, requests = nil, nil, 0
        local model = {
            appearanceSpec = spec,
            SetAlpha = function() end,
            appearanceSource = {
                ClearAllPoints = function() end,
                SetPoint = function() end,
                SetSize = function() end,
                SetAlpha = function() end,
            },
            adventureScene = {
                Show = function() end,
                SetScript = function(_, _, callback)
                    update = callback
                end,
            },
            GetModelFileID = function()
                return file
            end,
            SetUnit = function(_, unit)
                assert(unit == "player")
                requests = requests + 1
            end,
            SetCreature = function(_, id)
                assert(id == 911)
                requests = requests + 1
            end,
        }
        client.AwaitAdventureModel(model)
        for _ = 1, 20 do
            assert(update)
            update(model.adventureScene, 0.1)
        end
        assert(requests == 2)
        file = 42
        for _ = 1, 30 do
            assert(update)
            update(model.adventureScene, 0.1)
        end
        assert(requests == 2 and update == nil)
    end
end)

case("Geometry retries stop after success or a bounded loading window", function()
    local client = adapter("12.1.5")
    local update, calls, finishAt, shown = nil, 0, nil, false
    local scene = {
        Show = function()
            shown = true
        end,
        SetScript = function(_, script, callback)
            assert(script == "OnUpdate")
            update = callback
        end,
    }
    local model = {
        adventureScene = scene,
        onModelLoaded = function()
            calls = calls + 1
            if calls == finishAt then
                scene:SetScript("OnUpdate", nil)
            end
        end,
    }
    client.AwaitAdventureModel(model)
    assert(shown)
    for _ = 1, 50 do
        assert(update)
        update(scene, 0.1)
    end
    assert(not update and calls == 50)
    calls, finishAt = 0, 2
    client.AwaitAdventureModel(model)
    update(scene, 0.1)
    update(scene, 0.1)
    assert(not update and calls == 2)
end)

case("Actor framing waits for geometry and stays fixed through animation", function()
    local client = adapter("12.1.5")
    local loaded, fits, loads = false, 0, 0
    local position, actorScale, yaw, transmog
    local actor = {
        SetScale = function(_, scale)
            actorScale = scale
        end,
        SetPosition = function(_, x, y, z)
            position = { x, y, z }
        end,
        SetUseCenterForOrigin = function() end,
        SetUseTransmogSkin = function(_, enabled)
            transmog = enabled
        end,
        SetModelByUnit = function(_, unit, sheathed, autoDress, hideWeapons, nativeForm)
            assert(transmog == true)
            assert(unit == "player" and sheathed == false and autoDress == true)
            assert(hideWeapons == false and nativeForm == true)
        end,
        SetAnimation = function() end,
        SetYaw = function(_, angle)
            yaw = angle
        end,
        SetModelByCreatureDisplayID = function(_, display)
            assert(display == 123)
            loads = loads + 1
        end,
        IsLoaded = function()
            return loaded
        end,
        GetMaxBoundingBox = function()
            fits = fits + 1
            return -2, -1, -3, 2, 1, 5
        end,
        GetActiveBoundingBox = function()
            fits = fits + 1
            return -2, -1, -2, 2, 1, 4
        end,
        SetAlpha = function() end,
        Show = function() end,
    }
    local visible = false
    local model = {
        adventureActor = actor,
        appearanceSource = { SetAlpha = function() end },
        adventureScene = {
            SetScript = function() end,
            GetWidth = function()
                return 360
            end,
            GetHeight = function()
                return 240
            end,
            Show = function()
                visible = true
            end,
        },
        GetDisplayInfo = function()
            return 123
        end,
    }
    local spec = { key = "enemy:test", creatureID = 1 }
    assert(not client.FrameAdventureModel(model, true, spec))
    assert(not visible and fits == 0)
    loaded = true
    assert(client.FrameAdventureModel(model, true, spec))
    assert(visible and fits == 1 and loads == 1)
    assert(transmog == false)
    assert(yaw == 1.05)
    assert(math.abs(position[3] - 2 * actorScale) < 0.00001)
    assert(client.FrameAdventureModel(model, true, spec))
    assert(fits == 1 and loads == 1)
    local normalScale = actorScale
    assert(client.FrameAdventureModel(model, true, {
        key = "enemy:particles",
        creatureID = 2,
        framing = { cameraDistance = 2.3 },
    }))
    assert(actorScale < normalScale)
    actor.GetActiveBoundingBox = function() end
    assert(
        client.FrameAdventureModel(model, true, { key = "enemy:delayed-bounds", creatureID = 3 })
    )
    assert(math.abs(position[3] - 3 * actorScale) < 0.00001)
    assert(client.FrameAdventureModel(model, false, { key = "companion:test", creatureID = 4 }))
    assert(yaw == -1.05)
    assert(client.FrameAdventureModel(model, false, { key = "player:test", unit = "player" }))
    assert(transmog == true)
    assert(client.FrameAdventureModel(model, true, { key = "enemy:reset", creatureID = 5 }))
    assert(transmog == false)
end)

case(
    "Appearance choices persist without consuming loot randomness and gear changes model identity",
    function()
        local client = adapter("12.1.5")
        local state = W.Game.New(1000)
        assert(W.Game.AddHero(state, "WARRIOR"))
        local hero = state.heroes[1]
        hero.appearance = "human_male"
        local before = state.seed
        local first = client.ModelSpec(hero)
        assert(client.ModelSpec(hero).creatureID == first.creatureID and state.seed == before)
        hero.gear[1] = { itemID = 25 }
        local equipped = client.ModelSpec(hero)
        assert(equipped.key ~= first.key and equipped.creatureID == first.creatureID)
        assert(equipped.equipment[1] == 25)
        hero.gear[4] = { itemID = 13094 }
        assert(client.ModelSpec(hero).key == equipped.key)
        hero.gear[4] = { itemID = 1930 }
        assert(client.ModelSpec(hero).equipment[3] == 1930)
        local seen = {}
        for seed = 1, 20 do
            hero.appearanceSeed = seed
            seen[client.ModelSpec(hero).creatureID] = true
        end
        local count = 0
        for _ in pairs(seen) do
            count = count + 1
        end
        assert(count == 5)
        hero.appearanceSeed = nil
        local migrated = W.Game.Load(W.Game.Copy(state), 1000)
        local seed = migrated.heroes[1].appearanceSeed
        assert(seed and W.Game.Load(W.Game.Copy(migrated), 1000).heroes[1].appearanceSeed == seed)
    end
)

case("Every new hero and the main character have stat-free clothing in empty slots", function()
    local client = adapter("12.1.5")
    for _, class in ipairs(W.Content.classes) do
        local s = W.Game.New(1000)
        assert(W.Game.AddHero(s, class.id))
        local hero = s.heroes[1]
        local seed, nextItem = s.seed, s.nextItem
        local outfit = client.ModelSpec(hero).equipment
        assert(#outfit == 3)
        assert(next(hero.gear) == nil and #s.inventory == 0)
        assert(s.seed == seed and s.nextItem == nextItem)
        assert(W.Game.Stats(s, hero).attributes.armor == nil)
        local baseline = client.ModelSpec(hero).equipmentKey
        hero.guid = "test-character"
        local main = client.ModelSpec(hero)
        assert(main.unit == "player" and main.equipmentKey == baseline)
        hero.gear[2] = W.Game.Item(s, 2, 1, 1, false, W.Content.itemByID[2568])
        local dressed = client.ModelSpec(hero)
        assert(#dressed.equipment == 3 and dressed.equipment[1] == 2568)
        assert(dressed.equipment[2] == outfit[2] and dressed.equipment[3] == outfit[3])
        hero.gear[2] = nil
        assert(client.ModelSpec(hero).equipmentKey == baseline)
        assert(W.Game.Load(s, 1000))
        assert(client.ModelSpec(hero).equipmentKey == baseline)
    end
end)

case("Uncached equipment does not block characters and dresses when data arrives", function()
    local cached, requests, tried = false, 0, 0
    local geometry = false
    local client = adapter("12.1.5", {
        C_Item = {
            IsItemDataCachedByID = function()
                return cached
            end,
            RequestLoadItemDataByID = function(id)
                assert(id == 25)
                requests = requests + 1
            end,
        },
    })
    local model = {
        appearanceSource = {
            IsGeoReady = function()
                return geometry
            end,
            Undress = function() end,
            TryOn = function(_, link)
                assert(link == "item:25")
                tried = tried + 1
            end,
        },
    }
    local spec = { equipmentKey = "25", equipment = { 25 } }
    assert(client.ApplyModelEquipment(model, spec) == false)
    assert(requests == 0 and tried == 0 and model.equipmentAppliedKey == nil)
    geometry = true
    assert(client.ApplyModelEquipment(model, spec))
    assert(client.ApplyModelEquipment(model, spec))
    assert(requests == 1 and tried == 0 and model.pendingEquipment[25])
    assert(model.equipmentAppliedKey == spec.equipmentKey)
    cached = true
    -- ITEM_DATA_LOAD_RESULT invalidates the outfit when the requested item arrives.
    model.equipmentAppliedKey = nil
    assert(client.ApplyModelEquipment(model, spec))
    assert(requests == 1 and tried == 1)
end)

case(
    "Unavailable equipment preserves the character and other wearable items on both clients",
    function()
        for _, version in ipairs({ "12.1.5", "1.60.1" }) do
            local client = adapter(version)
            local tried = {}
            local model = {
                appearanceSource = {
                    Undress = function() end,
                    TryOn = function(_, link)
                        tried[#tried + 1] = link
                        if link == "item:13101" then
                            error("Unavailable item")
                        end
                    end,
                },
            }
            local spec = { equipmentKey = "13101;25", equipment = { 13101, 25 } }
            assert(client.ApplyModelEquipment(model, spec))
            assert(#tried == 2 and tried[2] == "item:25")
            assert(model.equipmentErrors[13101])
            assert(not model.applyingEquipment)
            assert(client.ApplyModelEquipment(model, spec) and #tried == 2)
        end
    end
)

case("Continent title tiles use unlabeled Retail artwork without replacing decorations", function()
    local client = adapter("12.1.5")
    local info = { layerWidth = 3840, layerHeight = 2560, tileWidth = 256, tileHeight = 256 }
    local original = 12345
    for _, entry in ipairs({
        { "kalimdor", 66, "Kalimdor", 65 },
        { "kalimdor", 70, "Kalimdor", 69 },
        { "eastern", 96, "EasternKingdoms", 95 },
        { "eastern", 100, "EasternKingdoms", 99 },
        { "eastern", 111, "EasternKingdoms", 110 },
        { "eastern", 115, "EasternKingdoms", 114 },
    }) do
        assert(
            client.MapTileTexture(entry[1], entry[2], original, info)
                == "Interface\\AdventureMap\\"
                    .. entry[3]
                    .. "\\"
                    .. entry[3]
                    .. "Taxi"
                    .. entry[4]
        )
    end
    for _, entry in ipairs({
        { "kalimdor", 1 },
        { "kalimdor", 65 },
        { "kalimdor", 71 },
        { "kalimdor", 150 },
        { "eastern", 1 },
        { "eastern", 95 },
        { "eastern", 101 },
        { "eastern", 110 },
        { "eastern", 116 },
        { "eastern", 150 },
        { "elwynn", 66 },
    }) do
        assert(client.MapTileTexture(entry[1], entry[2], original, info) == original)
    end
    assert(client.MapTileTexture("kalimdor", 66, original, nil) == original)
    info.layerWidth = 1002
    assert(client.MapTileTexture("kalimdor", 66, original, info) == original)
    info.layerWidth = 3840
    local other = adapter("1.60.1")
    assert(other.MapTileTexture("kalimdor", 66, original, info) == original)
end)

case("Native map hit testing resolves city submaps to their adventure zone", function()
    local client = adapter("12.1.5", {
        C_Map = {
            GetMapArtLayerTextures = function()
                return { 999999 }
            end,
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

case("Retail regions follow artwork and remain clickable without native hit data", function()
    local client = adapter("12.1.5", { C_Map = {} })
    for _, zone in ipairs(W.Content.zones) do
        local found = 0
        for _, continent in ipairs({ "kalimdor", "eastern" }) do
            local x, y = client.ZonePosition(zone.id, continent)
            if x then
                found = found + 1
                assert(client.ZoneAtPosition(continent, x, y).id == zone.id, zone.id)
                -- Query adjacent pixels in the same shared label field.
                for _, offset in ipairs({ -0.0001, 0.0001 }) do
                    local hit = client.ZoneAtPosition(continent, x + offset, y)
                    assert(hit and hit.id == zone.id, zone.id)
                end
            end
        end
        assert(found == 1)
    end
    assert(not client.ZoneAtPosition("eastern", 0.2, 0.2))
    assert(not client.ZoneAtPosition("eastern", -0.1, 0.8))
end)

case("Unmatched artwork uses native borders instead of a stale color partition", function()
    local client = adapter("12.1.5", {
        C_Map = {
            GetMapArtLayerTextures = function()
                return { 999999 }
            end,
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
    assert(client.ZoneAtPosition("eastern", x, y).id == "elwynn")
    assert(client.MapMask("elwynn", "eastern"))
end)

case("Forever uses its own masks and hit regions with matching native artwork metadata", function()
    local client = adapter("1.60.1", {
        C_Map = {
            GetMapChildrenInfo = function()
                return {
                    { mapID = 1414, mapType = 2, name = "Kalimdor" },
                    { mapID = 1415, mapType = 2, name = "Eastern Kingdoms" },
                }
            end,
            GetMapArtLayerTextures = function(id)
                return { id == 1414 and 8025526 or 8023297 }
            end,
        },
    })
    local info = { layerWidth = 1002, layerHeight = 668 }
    for _, continent in ipairs({ "kalimdor", "eastern" }) do
        local bounds, texture = client.MapMask(continent, continent, info)
        assert(bounds and texture:find("Maps\\forever\\", 1, true))
    end
    for _, zone in ipairs(W.Content.zones) do
        local found = 0
        for _, continent in ipairs({ "kalimdor", "eastern" }) do
            local x, y = client.ZonePosition(zone.id, continent)
            if x then
                found = found + 1
                assert(client.MapMask(zone.id, continent, info))
                assert(client.ZoneAtPosition(continent, x, y).id == zone.id)
            end
        end
        assert(found == 1, zone.id)
    end
    assert(not client.ZoneAtPosition("kalimdor", 536.5 / 1200, 205.5 / 800))
    assert(not client.ZoneAtPosition("kalimdor", 530.5 / 1200, 510.5 / 800))
    assert(not client.ZoneAtPosition("eastern", 711.5 / 1200, 426.5 / 800))
    assert(client.ZoneAtPosition("eastern", 694.5 / 1200, 441.5 / 800).id == "loch_modan")
    assert(client.ZoneAtPosition("eastern", 524.5 / 1200, 250.5 / 800).id == "silverpine")
    assert(client.ZoneAtPosition("eastern", 533.5 / 1200, 250.5 / 800).id == "alterac")
    assert(client.ZoneAtPosition("eastern", 556.5 / 1200, 267.5 / 800).id == "hillsbrad")
    assert(client.ZoneAtPosition("kalimdor", 675.5 / 1200, 310.5 / 800).id == "ashenvale")
    assert(client.ZoneAtPosition("eastern", 639.5 / 1200, 460.5 / 800).id == "badlands")
    assert(not client.ZoneAtPosition("eastern", 530.5 / 1200, 515.5 / 800))
    assert(not client.ZoneAtPosition("eastern", 660.5 / 1200, 120.5 / 800))
    assert(not client.ZoneAtPosition("eastern", 488.5 / 1200, 277.5 / 800))
end)

case("Forever rejects mismatched artwork instead of reusing Retail geometry", function()
    local client = adapter("1.60.1", {
        C_Map = {
            GetMapArtLayerTextures = function(id)
                return { id == 1414 and 272075 or 2353944 }
            end,
        },
    })
    assert(not client.MapMask("kalimdor", "kalimdor"))
    assert(not client.MapMask("eastern", "eastern"))
    client = adapter("1.60.1", { C_Map = {} })
    assert(not client.MapMask("kalimdor", "kalimdor", { layerWidth = 3840, layerHeight = 2560 }))
end)

case("Haste scales native and actor animations and resets on stance changes", function()
    local client = adapter("12.0.5")
    local sequence, offset, actorSpeed
    local source = {
        SetAnimation = function() end,
        SetSequenceTime = function(_, id, timeOffset)
            sequence, offset = id, timeOffset
        end,
    }
    local model = { nativeAppearance = true, appearanceSource = source }
    local played, speed = client.AnimateModel(model, 16, 2)
    assert(played and speed == 2)
    client.AdvanceModelAnimation(model, 0.25)
    assert(sequence == 16 and offset == 500)
    client.AnimateModel(model, 25)
    client.AdvanceModelAnimation(model, 0.5)
    assert(offset == 500 and model.animationSequence == nil)
    model.nativeAppearance = false
    model.adventureActor = {
        SetAnimation = function(_, _, _, animationSpeed)
            actorSpeed = animationSpeed
        end,
    }
    client.AnimateModel(model, 53, 1.5)
    assert(actorSpeed == 1.5)
    client.AnimateModel(model, 0)
    assert(actorSpeed == 1)
    client.AnimateModel(model, 16, 0 / 0)
    assert(actorSpeed == 1)
end)

case("Native geometry export is bounded, cancellable and independent of shipped masks", function()
    local scripts, captured = {}, nil
    local frame = {
        SetScript = function(_, name, fn)
            scripts[name] = fn
        end,
        Hide = function() end,
    }
    local client = adapter("12.1.5", {
        CreateFrame = function()
            return frame
        end,
        C_Map = {
            GetMapArtLayers = function()
                return { { layerWidth = 3840, layerHeight = 2560 } }
            end,
            GetMapArtLayerTextures = function(id)
                return { id == 12 and 272075 or 2353944 }
            end,
            GetMapInfoAtPosition = function(id, x, y)
                if y < 0.25 then
                    return nil
                end
                if x > 0.75 then
                    return { mapID = 999, parentMapID = 0 }
                end
                return { mapID = id == 12 and 1 or 37, parentMapID = id }
            end,
            GetMapInfo = function() end,
        },
    })
    assert(not client.ExportMapGeometry(function() end, 0, 16))
    assert(client.ExportMapGeometry(function(result)
        captured = result
    end, 16, 16) == frame)
    local step = scripts.OnUpdate
    step()
    assert(captured == nil)
    for _ = 1, 20 do
        if scripts.OnUpdate then
            scripts.OnUpdate()
        end
    end
    assert(captured and captured.profile == "retail")
    assert(not scripts.OnUpdate)
    for _, id in ipairs({ "kalimdor", "eastern" }) do
        local map = captured.continents[id]
        assert(#map.rows == 16)
        assert(#map.names == 2)
        assert(map.names[1] == (id == "kalimdor" and "durotar" or "elwynn"))
        assert(map.names[2] == "_map_999")
        for _, row in ipairs(map.rows) do
            local width = 0
            for _, run in ipairs(row) do
                assert(run[1] >= 1 and run[2] >= -1 and run[2] < #map.names)
                width = width + run[1]
            end
            assert(width == 16)
        end
    end
    local called = false
    assert(client.ExportMapGeometry(function()
        called = true
    end, 16, 16))
    scripts.OnHide()
    assert(not scripts.OnUpdate and not called)
end)

case("Generated coastal hits keep Felwood out of Darkshore and reject open water", function()
    local client = adapter("12.1.5", { C_Map = {} })
    for _, point in ipairs({
        { "darkshore", 545, 190 },
        { "felwood", 578, 170 },
        { "felwood", 592, 185 },
        { "felwood", 590, 225 },
        { "thousand_needles", 628, 566 },
    }) do
        local zone =
            client.ZoneAtPosition("kalimdor", (point[2] + 0.5) / 1200, (point[3] + 0.5) / 800)
        assert(zone and zone.id == point[1], point[1])
    end
    assert(not client.ZoneAtPosition("kalimdor", 536.5 / 1200, 205.5 / 800))
end)

return cases
