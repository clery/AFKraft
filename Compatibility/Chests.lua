local _, W = ...
local A = W.Client

-- Native HD treasure chest; FileDataID and matching content verified in both client asset roots.
-- AnimationData IDs: Closed 147, Open 148, Opened 149. Probe all three on the loaded asset.
local fileID = 1100065
local poses = { closed = 147, opening = 148, opened = 149 }

function A.ChestPose(model, pose)
    model.chestPose = pose
    if not model.chestReady then
        return
    end
    local animation = poses[pose]
    if model.chestAnimation ~= animation then
        model.chestAnimation = animation
        model:SetAnimation(animation)
    end
end

function A.ChestLight(model, color, strength)
    if not model.chestReady or not model.SetLight then
        return
    end
    local light = model.chestLight
    light.diffuseColor.r, light.diffuseColor.g, light.diffuseColor.b = unpack(color)
    light.diffuseIntensity = 0.5 + strength
    light.ambientIntensity = 0.85 + strength * 0.15
    pcall(model.SetLight, model, true, light)
end

function A.CreateChestModel(parent, fallback)
    local model = CreateFrame("PlayerModel", nil, parent)
    model:EnableMouse(false)
    model.chestPose = "closed"
    model.chestLight = {
        omnidirectional = false,
        point = { x = -1, y = 1, z = -1 },
        ambientIntensity = 0.85,
        ambientColor = { r = 1, g = 1, b = 1 },
        diffuseIntensity = 0.5,
        diffuseColor = { r = 1, g = 1, b = 1 },
    }
    model:SetKeepModelOnHide(true)
    local function loaded()
        if model.chestReady or model:GetModelFileID() ~= fileID then
            return
        end
        for _, animation in pairs(poses) do
            if not model:HasAnimation(animation) then
                model:SetAlpha(0)
                return
            end
        end
        local ok = pcall(function()
            model:MakeCurrentCameraCustom()
            model:SetCameraPosition(4, -6, 3.4)
            model:SetCameraTarget(0, 0, 0.9)
            model:SetFacing(0)
            model:SetPitch(0)
            model:SetRoll(0)
        end)
        if not ok then
            model:SetAlpha(0)
            return
        end
        model.chestReady = true
        A.ChestPose(model, model.chestPose)
        A.ChestLight(model, { 1, 1, 1 }, 0)
        fallback:Hide()
        model:SetAlpha(1)
        model:SetScript("OnUpdate", nil)
    end
    model:SetScript("OnModelLoaded", loaded)
    if A.flavor == "retail" or A.flavor == "forever" then
        -- Keep the loader drawable until asynchronous geometry becomes available.
        model:SetAlpha(0.001)
        local elapsed, attempts = 0, 0
        model:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed < 0.1 then
                return
            end
            elapsed = 0
            attempts = attempts + 1
            loaded()
            if attempts >= 30 and not model.chestReady then
                model:SetScript("OnUpdate", nil)
                model:SetAlpha(0)
            end
        end)
        local ok = pcall(model.SetModel, model, fileID)
        if not ok then
            model:SetScript("OnUpdate", nil)
            model:SetAlpha(0)
        end
    else
        -- Unknown client profiles retain the icon until their chest assets are verified.
        model:SetAlpha(0)
    end
    return model
end
