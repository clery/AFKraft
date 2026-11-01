local _, W = ...
local A = W.Client

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Live actors return six coordinates; some API bindings return two vectors.
local function bounds(x, y, z, topX, topY, topZ)
    if type(x) == "table" and type(y) == "table" then
        return x, y
    end
    if finite(x) and finite(y) and finite(z) and finite(topX) and finite(topY) and finite(topZ) then
        return { x = x, y = y, z = z }, { x = topX, y = topY, z = topZ }
    end
end

-- Fit actual geometry, including animation extents, rather than portrait cameras.
function A.ModelFit(bottom, top, ground, aspect)
    if not bottom or not top or not ground or not finite(aspect) or aspect <= 0 then
        return nil
    end
    for _, point in ipairs({ bottom, top, ground }) do
        if
            type(point) ~= "table"
            or not finite(point.x)
            or not finite(point.y)
            or not finite(point.z)
        then
            return nil
        end
    end
    local width, depth, height = top.x - bottom.x, top.y - bottom.y, top.z - ground.z
    if width <= 0 or depth <= 0 or height <= 0 or top.z <= bottom.z then
        return nil
    end
    local radius = math.sqrt(width * width + depth * depth) / 2
    -- Conservatively fit both axes even on clients using horizontal FOV.
    local tangent = math.tan(0.5 / 2) / math.max(1, aspect)
    local scale = math.min(
        2 / height,
        (6 * tangent + 0.6) / (height + tangent * radius),
        (6 * tangent - 0.6) / (math.max(0, ground.z - bottom.z) + tangent * radius),
        6 * tangent * aspect / (radius * (1 + tangent * aspect))
    ) * 0.85
    return scale, (bottom.x + top.x) / 2, (bottom.y + top.y) / 2, ground.z
end

function A.CreateAdventureModel(parent, loaded)
    -- Native character models retain complete NPC skins and player outfit data.
    -- Creature enemies use the separately fitted scene actor.
    local model = CreateFrame("Frame", nil, parent)
    local source = CreateFrame("DressUpModel", nil, model)
    source:SetAllPoints(model)
    source:EnableMouse(false)
    source:SetAlpha(0)
    model.appearanceSource = source
    model.onModelLoaded = loaded
    for _, name in ipairs({
        "ClearModel",
        "SetUnit",
        "SetCreature",
        "GetDisplayInfo",
        "GetModelFileID",
        "HasAnimation",
    }) do
        model[name] = function(_, ...)
            return source[name](source, ...)
        end
    end
    local scene = CreateFrame("ModelScene", nil, model)
    scene:SetAllPoints(model)
    scene:EnableMouse(false)
    scene:SetCameraFieldOfView(0.5)
    scene:SetCameraPosition(6, 0, 0.6)
    scene:SetCameraOrientationByAxisVectors(-1, 0, 0, 0, 1, 0, 0, 0, 1)
    scene:SetCameraNearClip(0.1)
    scene:SetCameraFarClip(100)
    scene:SetLightAmbientColor(0.8, 0.8, 0.8)
    scene:SetLightDiffuseColor(0.6, 0.6, 0.6)
    scene:SetLightDirection(-1, -1, -1)
    scene:SetLightVisible(true)
    local actor = scene:CreateActor(nil, "WoWIdleAdventureActorTemplate")
    model.adventureScene, model.adventureActor = scene, actor
    actor:SetAlpha(0)
    source:SetScript("OnModelLoaded", function()
        source:SetAlpha(model.nativeAppearance and 1 or 0)
        loaded()
    end)
    model:SetScript("OnEvent", function(_, event, unit, success)
        if event == "ITEM_DATA_LOAD_RESULT" then
            if model.pendingEquipment and model.pendingEquipment[unit] then
                model.pendingEquipment[unit] = nil
                if success then
                    model.equipmentAppliedKey = nil
                    loaded()
                end
            end
            return
        end
        if model.appearanceUnit == "player" and (not unit or unit == "player") then
            model.equipmentAppliedKey = nil
            source:RefreshUnit()
            loaded()
        end
    end)
    model:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player")
    model:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    if C_Item and C_Item.RequestLoadItemDataByID then
        model:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    end
    if
        C_EventUtils
        and C_EventUtils.IsEventValid
        and C_EventUtils.IsEventValid("TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
    then
        model:RegisterEvent("TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
    end
    actor.onModelLoaded = loaded
    return model
end

function A.AwaitAdventureModel(model)
    local elapsed, attempts = 0, 0
    -- Geometry can become available after OnModelLoaded. Retry only while loading,
    -- with a bounded window; successful framing removes this update handler.
    model.adventureScene:SetScript("OnUpdate", function(scene, delta)
        elapsed = elapsed + delta
        if elapsed < 0.1 then
            return
        end
        elapsed = 0
        attempts = attempts + 1
        if attempts >= 50 then
            scene:SetScript("OnUpdate", nil)
        end
        local loaded = model.onModelLoaded
        if loaded then
            loaded(model)
        end
    end)
end

function A.FrameAdventureModel(model, enemy, spec)
    local actor, scene = model.adventureActor, model.adventureScene
    if not spec then
        return false
    end
    if model.nativeAppearance then
        local source = model.appearanceSource
        local file = source:GetModelFileID()
        if not finite(file) or file <= 0 then
            return false
        end
        source:RefreshCamera()
        source:SetPortraitZoom(0)
        source:SetCamDistanceScale(1.7)
        source:SetRotation(-1.05, false)
        source:SetAlpha(1)
        local equipped = A.ApplyModelEquipment(model, spec)
        actor:SetAlpha(0)
        if equipped then
            scene:SetScript("OnUpdate", nil)
            scene:Hide()
        else
            scene:Show()
        end
        return true
    end
    if model.adventureKey ~= spec.key then
        model.adventureKey = spec.key
        actor:SetScale(1)
        actor:SetPosition(0, 0, 0)
        actor:SetUseCenterForOrigin(false, false, false)
        actor:SetAnimation(0)
        if actor.SetUseTransmogSkin then
            actor:SetUseTransmogSkin(spec.unit ~= nil)
        end
        if spec.unit then
            actor:SetModelByUnit(spec.unit, false, true, false, true)
        else
            local display = model:GetDisplayInfo()
            if not finite(display) or display <= 0 then
                model.adventureKey = nil
                return false
            end
            actor:SetModelByCreatureDisplayID(display)
        end
    end
    if not actor:IsLoaded() then
        return false
    end
    if model.adventureFittedKey ~= spec.key then
        actor:SetAnimation(0)
        -- All-animation bounds can include long movement/death trajectories and
        -- shrink a stationary creature to a speck. Fit the standing geometry once.
        local bottom, top = bounds(actor:GetActiveBoundingBox())
        if not bottom then
            bottom, top = bounds(actor:GetMaxBoundingBox())
        end
        local ground = bottom
        local scale, x, y, z = A.ModelFit(bottom, top, ground, scene:GetWidth() / scene:GetHeight())
        if not scale then
            return false
        end
        local padding = spec.framing and spec.framing.cameraDistance
        if finite(padding) and padding > 1.7 then
            scale = scale * 1.7 / padding
        end
        local yaw = enemy and 1.05 or -1.05
        actor:SetYaw(yaw)
        actor:SetScale(scale)
        actor:SetPosition(
            -(x * math.cos(yaw) - y * math.sin(yaw)) * scale,
            -(x * math.sin(yaw) + y * math.cos(yaw)) * scale,
            -z * scale
        )
        model.adventureFittedKey = spec.key
    end
    actor:SetAlpha(1)
    actor:Show()
    scene:SetScript("OnUpdate", nil)
    scene:Show()
    return true
end
