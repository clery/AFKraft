local _, W = ...
local Effects = {}
W.CombatEffects = Effects

local durations =
    { shield = 1.1, heal = 0.8, slash = 0.5, burst = 0.8, sparkle = 1.2, impact = 0.6 }
local projectiles = { arrow = true, bolt = true, shadow = true, leaf = true, lightning = true }

local function position(unit)
    return (unit.x or 0) + 66, -(unit.y or 110) - 100
end

local function release(effect)
    effect.active, effect.loaded = false, false
    effect.source, effect.target, effect.spec = nil, nil, nil
    effect.model:Hide()
    effect.model:ClearModel()
    effect.frame:Hide()
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
        release(effect)
    end
end

function Effects:Acquire()
    for _, effect in ipairs(self.pool) do
        if not effect.active then
            return effect
        end
    end
    -- Bound allocations and per-frame work during multi-target attacks.
    if #self.pool >= 32 then
        return nil
    end
    local effect = {}
    effect.frame = CreateFrame("Frame", nil, self.frame)
    effect.frame:SetSize(1, 1)
    effect.frame:EnableMouse(false)
    effect.model = CreateFrame("PlayerModel", nil, effect.frame)
    effect.model:SetPoint("CENTER")
    effect.model:EnableMouse(false)
    effect.model:SetAlpha(0)
    effect.model:SetScript("OnModelLoaded", function(model)
        local spec = effect.spec
        -- Ignore callbacks from cleared or recycled models. Loading is asynchronous.
        if effect.active and spec and model:GetModelFileID() == spec.fileID then
            if W.Client.FrameSpellEffect(model, spec, effect.direction) then
                effect.loaded, effect.started = true, GetTime()
                model:SetAlpha(1)
            end
        end
    end)
    self.pool[#self.pool + 1] = effect
    return effect
end

function Effects:Load(effect, kind)
    effect.kind = kind
    effect.spec = W.Client.SpellEffectSpec(kind, effect.class)
    effect.loaded = false
    effect.requested = GetTime()
    effect.model:SetAlpha(0)
    if not effect.spec then
        release(effect)
        return false
    end
    effect.model:SetSize(effect.spec.width, effect.spec.height)
    effect.model:Show()
    if not W.Client.LoadSpellEffect(effect.model, effect.spec) then
        release(effect)
        return false
    end
    return true
end

function Effects:Play(source, target, kind, class)
    if not source or not target or not source:IsShown() or not target:IsShown() then
        return
    end
    local effect = self:Acquire()
    if not effect then
        return
    end
    effect.active, effect.started = true, GetTime()
    effect.source, effect.target, effect.class = source, target, class
    effect.projectile = projectiles[kind] or false
    effect.direction = effect.projectile and (target.x or 0) < (source.x or 0) and -1 or 1
    effect.x, effect.y = position(source)
    effect.duration = durations[kind] or 0.45
    if not self:Load(effect, kind) then
        return
    end
    local x, y = position(effect.projectile and source or target)
    effect.frame:ClearAllPoints()
    effect.frame:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
    effect.frame:SetAlpha(1)
    effect.frame:Show()
end

function Effects:Event(units, state, event)
    if event.kind == "victory" or event.kind == "loot" then
        for i = 1, 5 do
            local unit = units[i]
            if unit and not unit.dead then
                self:Play(unit, unit, "sparkle")
            end
        end
        return
    elseif event.kind == "cast" and event.action == "special" then
        local unit = units[event.source]
        if unit then
            self:Play(unit, unit, "burst", unit.class)
        end
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
        self:Play(source, target, class == "PRIEST" and "shield" or "heal", class)
    elseif source then
        local kind = source.melee and "slash"
            or class == "HUNTER" and "arrow"
            or class == "SHAMAN" and "lightning"
            or class == "DRUID" and "leaf"
            or class == "WARLOCK" and "shadow"
            or "bolt"
        self:Play(source, target, kind, class)
    end
end

function Effects:Animate(now)
    for _, effect in ipairs(self.pool) do
        if effect.active then
            local target = effect.target
            local progress = (now - effect.started) / effect.duration
            if not target:IsShown() or not effect.source:IsShown() then
                release(effect)
            elseif not effect.loaded then
                -- A missing asset stays invisible; never replace it with a drawn sprite.
                if now - effect.requested >= 1.5 then
                    release(effect)
                end
            elseif
                effect.projectile and now - effect.started >= effect.duration + durations.impact
            then
                release(effect)
            elseif progress >= 1 and effect.projectile then
                effect.projectile = false
                effect.source = target
                effect.duration = durations.impact
                self:Load(effect, "impact")
            elseif progress >= 1 then
                release(effect)
            else
                local x, y = position(target)
                if effect.projectile then
                    x = effect.x + (x - effect.x) * progress
                    y = effect.y + (y - effect.y) * progress
                end
                effect.frame:ClearAllPoints()
                effect.frame:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
                -- Native particles provide their own motion and shape. Only fade
                -- the tail of the effect so persistent auras do not pop away.
                effect.frame:SetAlpha(math.min(1, (1 - progress) * 5))
            end
        end
    end
end
