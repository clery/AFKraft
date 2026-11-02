local _, W = ...
local A = W.Client

-- Native M2 FileDataIDs verified against the community listfile. No game art is bundled.
-- https://github.com/wowdev/wow-listfile/releases/latest
-- These are model files, not spell IDs or SpellVisualKit IDs. Camera composition
-- and particle rendering still require verification in the actual target client.
local retail = {
    bolt = { fileID = 1598570, width = 110, height = 90, yawOffset = math.pi }, -- Frostbolt missile
    arrow = { fileID = 1608507, width = 100, height = 70, yawOffset = math.pi }, -- Multi-Shot arrow
    shadow = { fileID = 1955423, width = 110, height = 90, yawOffset = math.pi }, -- Shadow Bolt missile
    leaf = { fileID = 1513210, width = 110, height = 90, yawOffset = math.pi }, -- Wrath missile
    lightning = { fileID = 529304, width = 110, height = 90, yawOffset = math.pi }, -- Lightning Bolt missile
    shield = { fileID = 166360, width = 220, height = 240 }, -- Holy Word Shield, chest
    heal = { fileID = 166197, width = 210, height = 240 }, -- Flash Heal
    slash = { fileID = 1274646, width = 160, height = 180, cameraHeight = 0 }, -- Cleave impact
    burst = { fileID = 1634276, width = 210, height = 240 }, -- Holy Nova impact
    sparkle = { fileID = 166698, width = 210, height = 240 }, -- Reputation reward
    levelup = { fileID = 166464, width = 260, height = 240, glow = 1 }, -- Level Up
    impact = { fileID = 165559, width = 140, height = 160 }, -- Aimed Shot impact
}
local impacts = {
    MAGE = { fileID = 1599028, width = 160, height = 180 },
    WARLOCK = { fileID = 166814, width = 160, height = 180 },
    SHAMAN = { fileID = 530800, width = 160, height = 180 },
    DRUID = { fileID = 1521174, width = 160, height = 180 },
}

local bursts = {
    WARRIOR = { fileID = 167199, width = 220, height = 220 }, -- Whirlwind
    ROGUE = { fileID = 249502, width = 200, height = 200 }, -- Fan of Knives
    MAGE = { fileID = 166210, width = 220, height = 220 }, -- Frost Nova
    SHAMAN = { fileID = 166493, width = 210, height = 210 }, -- Lightning ring
    WARLOCK = { fileID = 166803, width = 220, height = 220 }, -- Shadow nova
    DRUID = { fileID = 165794, width = 210, height = 240 }, -- Circle of renewal
}

function A.SpellEffectSpec(kind, class)
    -- Forever assets and visual API behavior have not been validated together.
    if A.flavor ~= "retail" then
        return nil
    end
    if kind == "burst" then
        -- Hunter specials already emit their native arrows for each target.
        if class == "HUNTER" then
            return nil
        end
        return bursts[class] or retail.burst
    end
    return kind == "impact" and impacts[class] or retail[kind]
end

function A.CreateSpellEffectModel(parent, loaded)
    local scene = CreateFrame("ModelScene", nil, parent)
    scene:EnableMouse(false)
    scene:SetCameraFieldOfView(0.5)
    scene:SetCameraNearClip(0.1)
    scene:SetCameraFarClip(200)
    scene:SetLightAmbientColor(1, 1, 1)
    scene:SetLightDiffuseColor(0, 0, 0)
    scene:SetLightVisible(true)
    local actor = scene:CreateActor(nil, "WoWIdleAdventureActorTemplate")
    scene.spellActor = actor
    actor.onModelLoaded = function()
        loaded(scene)
    end
    scene.GetModelFileID = function()
        return actor:GetModelFileID()
    end
    scene.ClearModel = function()
        actor:ClearModel()
    end
    return scene
end

local function frameSpellActor(scene, spec, direction, viewportScale)
    local actor = scene.spellActor
    if not actor:IsLoaded() then
        return false
    end
    -- Explicit world-space projection avoids PlayerModel's portrait camera and
    -- automatic model normalization. Padding increases distance, not effect size.
    local height = spec.cameraHeight or 0
    scene:SetCameraPosition(0, -8 * (viewportScale or 1), height)
    scene:SetCameraOrientationByAxisVectors(0, 1, 0, 1, 0, 0, 0, 0, 1)
    actor:SetUseCenterForOrigin(false, false, false)
    actor:SetPosition(0, 0, 0)
    actor:SetScale(1)
    actor:SetPitch(0)
    actor:SetRoll(0)
    -- Native missiles face opposite the impact models in this side camera.
    actor:SetYaw(((direction == -1 and math.pi or 0) + (spec.yawOffset or 0)) % (2 * math.pi))
    actor:SetAnimation(0)
    actor:SetAlpha(1)
    actor:Show()
    return true
end

function A.FrameSpellEffect(model, spec, direction, viewportScale)
    if not spec then
        return false
    end
    if model.spellActor then
        local ok, framed = pcall(frameSpellActor, model, spec, direction, viewportScale)
        model.spellError = not ok and framed or nil
        return ok and framed == true
    end
    return pcall(function()
        -- Particle emitters and native bloom are separate from the animated mesh.
        if model.SetParticlesEnabled then
            model:SetParticlesEnabled(true)
        end
        if model.SetGlow then
            model:SetGlow(spec.glow or 0)
        end
        -- Spell M2s need not contain the portrait camera used by characters.
        -- Look across the missile axis so its authored trail is visible in profile.
        -- Convert the active camera; selecting an absent authored camera by
        -- index leaves spell models without a usable custom camera.
        model:MakeCurrentCameraCustom()
        local height = spec.cameraHeight or 0.75
        model:SetCameraPosition(0, -8 * (viewportScale or 1), height)
        model:SetCameraTarget(0, 0, height)
        -- Legacy frames are used only for the separate level-up effect.
        local facing = direction == -1 and -1 or 1
        model:SetCameraRoll(0)
        model:SetRoll(0)
        model:SetPitch(0)
        model:SetFacing(facing == -1 and math.pi or 0)
        if not model.HasAnimation or model:HasAnimation(0) then
            model:SetAnimation(0)
        end
    end)
end

function A.LoadSpellEffect(model, spec)
    if not spec then
        return false
    end
    if model.spellActor then
        local ok = pcall(function()
            local actor = model.spellActor
            actor:ClearModel()
            actor:SetAlpha(0)
            return actor:SetModelByFileID(spec.fileID)
        end)
        -- Actual readiness is checked with IsLoaded and a matching file ID;
        -- unsupported/missing assets expire through the bounded load timeout.
        return ok
    end
    return pcall(function()
        model:ClearModel()
        if model.SetParticlesEnabled then
            model:SetParticlesEnabled(true)
        end
        model:SetModel(spec.fileID)
    end)
end
