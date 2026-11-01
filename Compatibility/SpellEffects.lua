local _, W = ...
local A = W.Client

-- Native M2 FileDataIDs verified against the community listfile. No game art is bundled.
-- https://github.com/wowdev/wow-listfile/releases/latest
-- These are model files, not spell IDs or SpellVisualKit IDs. Camera composition
-- and particle rendering still require verification in the actual target client.
local retail = {
    bolt = { fileID = 1598570, width = 110, height = 90 }, -- Frostbolt missile
    arrow = { fileID = 1608507, width = 100, height = 70 }, -- Multi-Shot arrow
    shadow = { fileID = 1955423, width = 110, height = 90 }, -- Shadow Bolt missile
    leaf = { fileID = 1513210, width = 110, height = 90 }, -- Wrath missile
    lightning = { fileID = 529304, width = 110, height = 90 }, -- Lightning Bolt missile
    shield = { fileID = 166360, width = 220, height = 240 }, -- Holy Word Shield, chest
    heal = { fileID = 166197, width = 210, height = 240 }, -- Flash Heal
    slash = { fileID = 1274646, width = 160, height = 180 }, -- Cleave impact
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

function A.FrameSpellEffect(model, spec, direction)
    if not spec then
        return false
    end
    return pcall(function()
        -- Particle emitters and native bloom are separate from the animated mesh.
        if model.SetParticlesEnabled then
            model:SetParticlesEnabled(true)
        end
        if model.SetGlow then
            model:SetGlow(spec.glow or 0)
        end
        model:SetCamera(0)
        model:SetPortraitZoom(0)
        model:SetCamDistanceScale(1)
        model:SetFacing(direction == -1 and math.pi or 0)
        if not model.HasAnimation or model:HasAnimation(0) then
            model:SetAnimation(0)
        end
    end)
end

function A.LoadSpellEffect(model, spec)
    if not spec then
        return false
    end
    return pcall(function()
        model:ClearModel()
        if model.SetParticlesEnabled then
            model:SetParticlesEnabled(true)
        end
        model:SetModel(spec.fileID)
    end)
end
