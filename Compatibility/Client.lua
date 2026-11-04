local _, W = ...
local L = W.L
local A = {
    status = L.QUEST_LEVEL_BOSS_ELIGIBLE_KILL_AND_GATHERING_REWARDS_ACTIVE,
    xpSequence = 0,
}
W.Client = A
A.animations = { cheer = 68, readyUnarmed = 25, readyBow = 29, readySpell = 51, fireBow = 47 }
local version = GetBuildInfo and GetBuildInfo() or ""
A.flavor = version:match("^1%.60%.") and "forever" or "retail"
A.profiles = {
    retail = {
        continents = { kalimdor = 12, eastern = 13 },
        mapIDs = {
            elwynn = 37,
            durotar = 1,
            westfall = 52,
            barrens = 10,
            redridge = 49,
            ashenvale = 63,
            duskwood = 47,
            wetlands = 56,
            stranglethorn = 50,
            desolace = 66,
            tanaris = 71,
            winterspring = 83,
        },
    },
    -- Fill verified Forever map IDs here; do not reuse Retail IDs silently.
    forever = { mapIDs = {} },
}
A.profile = A.profiles[A.flavor]

function A.StyleNameplate(bar, background)
    local options = NamePlateSetupOptions
    local classic = A.flavor == "forever"
    if options and type(options.useClassicHealthBar) == "boolean" then
        classic = options.useClassicHealthBar
    end
    background:ClearAllPoints()
    background:SetVertexColor(1, 1, 1, 1)
    if classic then
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
        background:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
        background:SetAllPoints(bar)
        background:SetVertexColor(0.15, 0.15, 0.15, 1)
        local border = bar:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Tooltips\\Nameplate-Border")
        -- The health surround occupies the first 107 pixels of the 256x32
        -- sheet; omit the adjoining level box and the transparent padding.
        border:SetTexCoord(0, 107 / 256, 0.5, 1)
        border:SetPoint("CENTER")
        border:SetSize(bar:GetWidth() + 8, bar:GetHeight() + 6)
    else
        bar:GetStatusBarTexture():SetAtlas(L.UI_HUD_COOLDOWNMANAGER_BAR)
        background:SetAtlas(L.UI_HUD_COOLDOWNMANAGER_BAR_BG)
        background:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 3)
        background:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 6, -6)
    end
end

local function readable(v)
    return not issecretvalue or not issecretvalue(v)
end

function A.Now()
    return GetServerTime and GetServerTime() or time()
end

function A.Identity()
    local _, class = UnitClass("player")
    return {
        name = UnitName("player") or L.ADVENTURER,
        class = class or "WARRIOR",
        guid = UnitGUID("player") or "local-player",
    }
end

function A.MapTiles(zoneID)
    if not C_Map or not C_Map.GetMapArtLayers then
        return nil
    end
    local id = A.MapID(zoneID)
    if not id then
        return nil
    end
    local ok, layers = pcall(C_Map.GetMapArtLayers, id)
    if not ok or not layers or not layers[1] then
        return nil
    end
    local ok2, textures = pcall(C_Map.GetMapArtLayerTextures, id, 1)
    if ok2 then
        return textures, layers[1]
    end
end

function A.ModelSpec(hero, zoneID, enemyName)
    if hero then
        local equipment, equipmentKey = A.EquipmentSpec(hero)
        if hero.guid == A.Identity().guid then
            return {
                key = "player:" .. hero.guid .. ":" .. equipmentKey,
                unit = "player",
                equipment = equipment,
                equipmentKey = equipmentKey,
            }
        end
        local class = W.ModelAssets.classes[hero.class]
        local id = class and class[hero.appearance]
            or W.ModelAssets.appearances[hero.appearance]
            or class and class.default
        local variants = W.ModelAssets.variants[hero.appearance]
        if variants and #variants > 0 then
            id = variants[W.Game.AppearanceSeed(hero) % #variants + 1]
        end
        if id then
            return {
                key = "companion:" .. id .. ":" .. equipmentKey,
                creatureID = id,
                equipment = equipment,
                equipmentKey = equipmentKey,
            }
        end
        return nil
    end
    local zone, assets = W.Content.zoneByID[zoneID], W.ModelAssets.zones[zoneID]
    if not zone or not assets then
        return nil
    end
    local id = enemyName == zone.boss and assets.boss or nil
    for i, name in ipairs(zone.enemies) do
        if enemyName == name then
            id = assets.enemies[i]
            break
        end
    end
    if id then
        return { key = "enemy:" .. id, creatureID = id, framing = W.ModelAssets.framing[id] }
    end
end

function A.FrameModel(model, enemy, spec)
    if model.SetDoBlend then
        model:SetDoBlend(true)
    end
    if model.adventureScene then
        return A.FrameAdventureModel(model, enemy, spec)
    end
    model:SetPortraitZoom(0)
    model:SetCamDistanceScale(
        spec and spec.framing and spec.framing.cameraDistance or (enemy and 1.7 or 1.5)
    )
    model:SetFacing(enemy and -1.05 or 1.05)
    return true
end

-- AnimationData sequences; individual creature models may lack weapon poses.
function A.ReadyAnimation(class, melee)
    return class == "HUNTER" and not melee and A.animations.readyBow
        or melee and A.animations.readyUnarmed
        or A.animations.readySpell
end

function A.AttackAnimation(class, melee, action)
    if action == "heal" then
        return 53
    end
    return class == "HUNTER" and not melee and A.animations.fireBow or melee and 16 or 53
end

local animationFallbacks = {
    [47] = { 46, 53 },
    [46] = { 53 },
    [29] = { 25, 0 },
    [51] = { 25, 0 },
    [25] = { 0 },
}

function A.AnimateModel(model, animation, speed)
    speed = type(speed) == "number" and speed > 0 and speed < math.huge and speed or 1
    model.animationSequence, model.animationSpeed = nil, nil
    local ok, played = pcall(function()
        if model.HasAnimation and not model:HasAnimation(animation) then
            local fallback = animationFallbacks[animation]
            animation = nil
            for _, candidate in ipairs(fallback or {}) do
                if model:HasAnimation(candidate) then
                    animation = candidate
                    break
                end
            end
        end
        if animation then
            local target = model.nativeAppearance and model.appearanceSource
                or model.adventureActor
                or model
            if target == model.adventureActor then
                target:SetAnimation(animation, nil, speed)
            else
                target:SetAnimation(animation)
                -- A live unit model has its own animation state. Repeated seeking
                -- can visibly restart/blend its attack on every rendered frame.
                if speed ~= 1 and model.appearanceUnit ~= "player" and target.SetSequenceTime then
                    model.animationSequence, model.animationSpeed = animation, speed
                else
                    speed = 1
                end
            end
            return true
        end
        return false
    end)
    return ok and played, speed
end

function A.AdvanceModelAnimation(model, elapsed)
    if model.animationSequence then
        local target = model.nativeAppearance and model.appearanceSource or model
        target:SetSequenceTime(model.animationSequence, elapsed * model.animationSpeed * 1000)
    end
end

function A.PlayLevelUp(model)
    return A.LoadSpellEffect(model, A.SpellEffectSpec("levelup"))
end

function A.ConfigureModel(model, spec, enemy)
    if not spec then
        return false
    end
    return pcall(function()
        model:ClearModel()
        if model.adventureScene then
            model.appearanceSpec = spec
            model.nativeAppearance = not enemy
            model.appearanceUnit = spec.unit
            model.adventureKey = nil
            model.adventureFittedKey = nil
            model.measurementFile, model.spacingRadius = nil, nil
            model.equipmentAppliedKey = nil
            model.pendingEquipment = {}
            model.adventureActor:ClearModel()
            model.adventureActor:SetAlpha(0)
            model.adventureScene:Show()
            A.PrepareAppearanceLoad(model)
            local source = model.appearanceSource
            source:SetAutoDress(false)
            source:SetUseTransmogSkin(false)
            source:SetUseTransmogChoices(false)
            source:SetObeyHideInTransmogFlag(true)
            A.AwaitAdventureModel(model)
        end
        if spec.unit then
            model:SetUnit(spec.unit)
        else
            model:SetCreature(spec.creatureID)
        end
        A.FrameModel(model, enemy, spec)
    end)
end

function A.Register(frame)
    -- Protected event registration can report ADDON_ACTION_FORBIDDEN even inside
    -- pcall. Subscribe only to public reward signals; never probe combat-log access.
    for _, event in ipairs({
        "QUEST_TURNED_IN",
        "PLAYER_LEVEL_UP",
        "BOSS_KILL",
        "CHAT_MSG_COMBAT_XP_GAIN",
        "PLAYER_TARGET_CHANGED",
        "UPDATE_MOUSEOVER_UNIT",
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "UNIT_HEALTH",
        "UNIT_FLAGS",
        "UNIT_THREAT_LIST_UPDATE",
        "UNIT_SPELLCAST_SENT",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "CHAT_MSG_SKILL",
    }) do
        frame:RegisterEvent(event, "OnGameEvent")
    end
    if W.DungeonRewards then
        W.DungeonRewards.Register(frame)
    end
end

function A.Event(s, event, ...)
    local G = W.Game
    if W.KillRewards then
        W.KillRewards.Event(s, event, ...)
        W.GatheringRewards.Event(s, event, ...)
    end
    if W.DungeonRewards then
        W.DungeonRewards.Event(s, event, ...)
    end
    if event == "QUEST_TURNED_IN" then
        local questID = ...
        if readable(questID) and type(questID) == "number" then
            -- Repeatable quests can reward again; suppress only duplicate delivery.
            G.ActivityReward(
                s,
                "quest:" .. questID .. ":" .. math.floor(A.Now() / 2),
                "quest",
                L.QUEST_COMPLETED
            )
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if readable(level) and type(level) == "number" then
            G.ActivityReward(
                s,
                "level:" .. A.Identity().guid .. ":" .. level,
                "level",
                L.CHARACTER_LEVEL_PREFIX .. level
            )
        end
    elseif event == "BOSS_KILL" then
        local id, name = ...
        if readable(id) and type(id) == "number" then
            if W.DungeonRewards and W.DungeonRewards.BossEligible(id, name) then
                G.ActivityReward(
                    s,
                    "boss:" .. id .. ":" .. math.floor(A.Now() / 30),
                    "boss",
                    L.BOSS_DEFEATED
                )
            end
            s.discoveries["boss:" .. id] = true
        end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        if W.KillRewards and W.KillRewards.AtCap() then
            return
        end
        local message = ...
        if not readable(message) or type(message) ~= "string" or message == "" then
            return
        end
        -- Each delivery is one combat-XP award. A sequence keeps simultaneous
        -- kills distinct without parsing localized text or reading combat logs.
        A.xpSequence = A.xpSequence + 1
        G.ActivityReward(
            s,
            "combat-xp:" .. A.Identity().guid .. ":" .. A.Now() .. ":" .. A.xpSequence,
            "kill",
            L.COMBAT_EXPERIENCE
        )
    end
end

function A.Sample(state)
    W.KillRewards.Tick(state)
    W.GatheringRewards.Sample()
    if W.DungeonRewards then
        W.DungeonRewards.Tick()
    end
end
