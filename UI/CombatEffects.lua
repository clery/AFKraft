local _, W = ...
local Effects = {}
W.CombatEffects = Effects

-- Presentation only: these colors and shapes never determine combat outcomes.
local colors = {
    MAGE = { 0.4, 0.85, 1 },
    HUNTER = { 0.9, 0.8, 0.5 },
    PRIEST = { 1, 0.9, 0.55 },
    WARLOCK = { 0.65, 0.3, 1 },
    SHAMAN = { 0.35, 0.65, 1 },
    PALADIN = { 1, 0.8, 0.3 },
    DRUID = { 0.45, 1, 0.45 },
}

local durations = {
    shield = 1.1,
    heal = 0.8,
    slash = 0.3,
    lightning = 0.25,
    burst = 0.65,
    sparkle = 1.2,
    impact = 0.25,
}
local projectiles = { arrow = true, bolt = true, shadow = true, leaf = true }
local gold = { 1, 0.82, 0.3 }
local damage = { 1, 0.55, 0.3 }

local function position(unit)
    return (unit.x or 0) + 66, -(unit.y or 110) - 100
end

function Effects.Create(parent)
    local self = setmetatable({ pool = {} }, { __index = Effects })
    self.frame = CreateFrame("Frame", nil, parent)
    self.frame:SetAllPoints(parent)
    self.frame:SetFrameLevel(parent:GetFrameLevel() + 100)
    self.frame:EnableMouse(false)
    self.frame:SetScript("OnHide", function()
        self:Clear()
    end)
    return self
end

function Effects:Clear()
    for _, effect in ipairs(self.pool) do
        effect.active = false
        effect.source, effect.target = nil, nil
        effect.frame:Hide()
    end
end

function Effects:Acquire()
    for _, effect in ipairs(self.pool) do
        if not effect.active then
            return effect
        end
    end
    -- Bound both allocations and per-frame work during multi-target attacks.
    if #self.pool >= 32 then
        return nil
    end
    local effect = { parts = {}, starts = {}, ends = {} }
    effect.frame = CreateFrame("Frame", nil, self.frame)
    effect.frame:SetSize(1, 1)
    effect.frame:EnableMouse(false)
    effect.art = CreateFrame("Frame", nil, effect.frame)
    effect.art:SetSize(1, 1)
    effect.art:SetPoint("CENTER")
    effect.art:EnableMouse(false)
    for i = 1, 24 do
        effect.parts[i] = effect.art:CreateLine(nil, "OVERLAY")
    end
    self.pool[#self.pool + 1] = effect
    return effect
end

local function drawLine(effect, index, x1, y1, x2, y2, thickness, color)
    -- Anchor endpoints through regions so all effect geometry follows UI scaling.
    local first, last = effect.starts[index], effect.ends[index]
    if not first then
        first = effect.art:CreateTexture(nil, "BACKGROUND")
        last = effect.art:CreateTexture(nil, "BACKGROUND")
        first:SetSize(1, 1)
        last:SetSize(1, 1)
        effect.starts[index], effect.ends[index] = first, last
    end
    first:SetPoint("CENTER", effect.art, "CENTER", x1, y1)
    last:SetPoint("CENTER", effect.art, "CENTER", x2, y2)
    local line = effect.parts[index]
    line:SetStartPoint("CENTER", first, 0, 0)
    line:SetEndPoint("CENTER", last, 0, 0)
    line:SetThickness(thickness)
    line:SetColorTexture(color[1], color[2], color[3], 0.85)
    line:Show()
end

local function segment(effect, index, x, y, width, height, rotation, color)
    local dx, dy = math.cos(rotation) * width / 2, math.sin(rotation) * width / 2
    drawLine(
        effect,
        index,
        (x - dx) * effect.direction,
        y - dy,
        (x + dx) * effect.direction,
        y + dy,
        height,
        color
    )
end

function Effects:Draw(effect)
    local kind, color = effect.kind, effect.color
    for _, texture in ipairs(effect.parts) do
        texture:Hide()
    end
    if kind == "shield" or kind == "burst" then
        local radiusX, radiusY = kind == "shield" and 40 or 35, kind == "shield" and 63 or 25
        for i = 1, 24 do
            local a, b = (i - 1) * math.pi / 12, i * math.pi / 12
            drawLine(
                effect,
                i,
                math.cos(a) * radiusX,
                math.sin(a) * radiusY,
                math.cos(b) * radiusX,
                math.sin(b) * radiusY,
                2,
                color
            )
        end
    elseif kind == "lightning" then
        local x, y = position(effect.target)
        local dx, dy = x - effect.x, y - effect.y
        local previousX, previousY = 0, 0
        for i = 1, 10 do
            local nextX = dx * i / 10
            local nextY = dy * i / 10 + (i == 10 and 0 or (i % 2 == 0 and -13 or 13))
            drawLine(effect, i, previousX, previousY, nextX, nextY, 3, color)
            previousX, previousY = nextX, nextY
        end
    elseif kind == "sparkle" or kind == "impact" then
        for i = 1, 8 do
            local angle = i * math.pi / 4
            local radius = kind == "sparkle" and 34 or 14
            local x, y = math.cos(angle) * radius, math.sin(angle) * radius
            segment(effect, i * 2 - 1, x, y, 10, 2, 0, color)
            segment(effect, i * 2, x, y, 10, 2, math.pi / 2, color)
        end
    elseif kind == "slash" then
        for i = 1, 8 do
            local angle = -1 + i * 0.25
            segment(
                effect,
                i,
                math.cos(angle) * 22 - 12,
                math.sin(angle) * 34,
                12,
                3,
                angle + math.pi / 2,
                color
            )
        end
    elseif kind == "heal" then
        segment(effect, 1, 0, 0, 32, 6, math.pi / 2, color)
        segment(effect, 2, 0, 0, 24, 6, 0, color)
    elseif kind == "arrow" then
        segment(effect, 1, 0, 0, 38, 2, 0, color)
        segment(effect, 2, 14, 3, 12, 2, -0.6, color)
        segment(effect, 3, 14, -3, 12, 2, 0.6, color)
        segment(effect, 4, -14, 0, 8, 7, 0, color)
    elseif kind == "leaf" then
        segment(effect, 1, 0, 0, 28, 2, 0.4, color)
        segment(effect, 2, 1, 4, 18, 5, -0.4, color)
        segment(effect, 3, -3, -4, 18, 5, -0.4, color)
    elseif kind == "shadow" then
        for i = 1, 6 do
            local angle = i * math.pi / 3
            segment(effect, i, math.cos(angle) * 6, math.sin(angle) * 6, 12, 4, angle, color)
        end
    else
        segment(effect, 1, 0, 0, 28, 9, 0, color)
        segment(effect, 2, -14, 0, 26, 3, 0, color)
        segment(effect, 3, 9, 0, 10, 12, 0.7, color)
    end
end

function Effects:Play(source, target, kind, color)
    if not source or not target or not source:IsShown() or not target:IsShown() then
        return
    end
    local effect = self:Acquire()
    if not effect then
        return
    end
    effect.active, effect.started = true, GetTime()
    effect.source, effect.target = source, target
    effect.kind, effect.color = kind, color
    effect.projectile = projectiles[kind] or false
    effect.direction = effect.projectile and (target.x or 0) < (source.x or 0) and -1 or 1
    effect.art:SetScale(1)
    effect.x, effect.y = position(source)
    effect.duration = durations[kind] or 0.45
    self:Draw(effect)
    local x, y = position(kind == "lightning" and source or target)
    -- Projectiles start at the caster; auras and reactions start at the recipient.
    if effect.projectile then
        x, y = effect.x, effect.y
    end
    effect.frame:ClearAllPoints()
    effect.frame:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
    effect.frame:SetAlpha(0)
    effect.frame:Show()
end

function Effects:Event(units, state, event)
    if event.kind == "victory" or event.kind == "loot" then
        for i = 1, 5 do
            local unit = units[i]
            if unit and not unit.dead then
                self:Play(unit, unit, "sparkle", gold)
            end
        end
        return
    elseif event.kind == "cast" and event.action == "special" then
        local unit = units[event.source]
        if unit then
            self:Play(unit, unit, "burst", colors[unit.class] or gold)
        end
        return
    elseif event.kind == "death" then
        local unit = units[(event.target or 0) + (event.enemy and 5 or 0)]
        self:Play(unit, unit, "burst", damage)
        return
    elseif event.kind ~= "hit" and event.kind ~= "heal" then
        return
    end
    local sourceIndex = event.source
    if type(sourceIndex) ~= "number" or type(event.target) ~= "number" then
        return
    end
    local friendly = event.kind == "heal" or event.enemy
    local source = units[sourceIndex + (friendly and 0 or 5)]
    local target = units[event.target + (event.enemy and 5 or 0)]
    local hero = friendly and state.heroes[sourceIndex]
    local class = hero and hero.class
    if event.kind == "heal" then
        self:Play(
            source,
            target,
            class == "PRIEST" and "shield" or "heal",
            colors[class] or colors.DRUID
        )
    elseif source then
        local kind = source.melee and "slash"
            or class == "HUNTER" and "arrow"
            or class == "SHAMAN" and "lightning"
            or class == "DRUID" and "leaf"
            or class == "WARLOCK" and "shadow"
            or "bolt"
        self:Play(source, target, kind, colors[class] or damage)
    end
end

function Effects:Animate(now)
    for _, effect in ipairs(self.pool) do
        if effect.active then
            local progress = (now - effect.started) / effect.duration
            local target = effect.target
            if
                progress >= 1
                and effect.projectile
                and target:IsShown()
                and effect.source:IsShown()
            then
                -- Reuse the projectile itself instead of allocating another effect for impact.
                effect.kind, effect.projectile = "impact", false
                effect.started = effect.started + effect.duration
                effect.duration = durations.impact
                effect.source = target
                progress = (now - effect.started) / effect.duration
                self:Draw(effect)
            end
            if progress >= 1 or not target:IsShown() or not effect.source:IsShown() then
                effect.active = false
                effect.source, effect.target = nil, nil
                effect.frame:Hide()
            else
                local x, y = position(target)
                local aura = not effect.projectile and effect.kind ~= "lightning"
                if aura then
                    y = y + (effect.kind == "heal" and progress * 35 or 0)
                elseif effect.kind == "lightning" then
                    x, y = effect.x, effect.y
                else
                    x = effect.x + (x - effect.x) * progress
                    y = effect.y + (y - effect.y) * progress
                end
                if effect.kind == "burst" or effect.kind == "impact" then
                    effect.art:SetScale(0.6 + progress * 1.3)
                elseif effect.kind == "sparkle" then
                    effect.art:SetScale(0.7 + progress * 0.5)
                    y = y + progress * 28
                end
                effect.frame:ClearAllPoints()
                effect.frame:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
                effect.frame:SetAlpha(
                    effect.projectile and 1 - progress * 0.4 or math.sin(progress * math.pi)
                )
            end
        end
    end
end
