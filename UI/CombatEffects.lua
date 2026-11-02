local _, W = ...
local Effects = {}
W.CombatEffects = Effects

local durations = { shield = 1.1, heal = 0.8, slash = 0.5, burst = 0.8, impact = 0.6 }
local projectiles = { arrow = true, bolt = true, shadow = true, leaf = true, lightning = true }

local function position(unit)
    local scale = unit.depthScale or 1
    return (unit.renderX or unit.x or 0) + 66, -(unit.renderY or unit.y or 110) - 204 + 104 * scale
end

local function finishLoad(effect)
    local model, spec = effect.model, effect.spec
    if
        effect.active
        and not effect.loaded
        and spec
        and model:GetModelFileID() == spec.fileID
        and W.Client.FrameSpellEffect(model, spec, effect.direction)
    then
        effect.loaded, effect.started = true, GetTime()
        model:SetSize(spec.width, spec.height)
    end
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
    effect.model:SetScript("OnModelLoaded", function()
        -- A repeated callback must not restart a projectile already in flight.
        finishLoad(effect)
    end)
    self.pool[#self.pool + 1] = effect
    return effect
end

function Effects:Load(effect, kind)
    effect.kind = kind
    effect.spec = W.Client.SpellEffectSpec(kind, effect.class)
    effect.loaded, effect.checked = false, nil
    effect.requested = GetTime()
    -- A transparent/hidden model can defer resource preparation indefinitely.
    -- Keep a drawable one-pixel viewport until framing is ready.
    effect.model:SetAlpha(1)
    effect.model:SetSize(1, 1)
    if not effect.spec then
        release(effect)
        return false
    end
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
    effect.direction = effect.projectile
            and (target.renderX or target.x or 0) < (source.renderX or source.x or 0)
            and -1
        or 1
    effect.x, effect.y = position(source)
    effect.duration = durations[kind] or 0.45
    local x, y = position(effect.projectile and source or target)
    effect.frame:ClearAllPoints()
    effect.frame:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
    effect.frame:SetAlpha(1)
    effect.frame:Show()
    self:Load(effect, kind)
end

function Effects:Event(units, state, event)
    if event.kind == "cast" and event.action == "special" then
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
                -- Cached assets may become ready without another load callback.
                -- Bound readiness queries to ten per second while loading only.
                if not effect.checked or now - effect.checked >= 0.1 then
                    effect.checked = now
                    finishLoad(effect)
                end
                if not effect.loaded and now - effect.requested >= 1.5 then
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
