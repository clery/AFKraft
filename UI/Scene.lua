local _, W = ...
local U, T, C = W.Widgets, W.Theme, W.Content
local Scene = {}
W.Scene = Scene

local function modelLoaded(unit, enemy)
    local id = unit.model:GetModelFileID()
    unit.modelReady = type(id) == "number" and id > 0
    if unit.modelReady then
        pcall(W.Client.FrameModel, unit.model, enemy, unit.modelSpec)
        W.Client.AnimateModel(unit.model, unit.dead and (unit.deathTime and 1 or 6) or 0)
    end
end

function Scene.Create(parent)
    local self = setmetatable({}, { __index = Scene })
    local f = CreateFrame("Frame", nil, parent)
    self.frame = f
    f:SetSize(1296, 360)
    f:SetClipsChildren(true)
    local content = U.BorderContent(f, 6)
    self.sky = U.Rect(content, 0, 0, 1296, 360, T.panel)
    self.scenery = W.Backdrop.Create(content)
    self.border = U.FrameTreatment(f)
    self.chapter = U.Text(content, "", 24, 20, 12, T.gold, 850)
    self.caption = U.Text(content, "", 24, 43, 24, T.text, 900)
    U.SingleLine(self.caption, 900, 32)
    self.status = U.Text(content, "", 980, 24, 12, T.text, 290)
    U.SingleLine(self.status, 290, 20, "RIGHT")
    self.note = U.Text(content, "", 24, 104, 13, T.text, 1150)
    self.units = {}
    for i = 1, 8 do
        local unit = CreateFrame("Frame", nil, content)
        local friendly = i <= 5
        unit:SetSize(132, 224)
        unit.sigil = U.Icon(unit, "INV_Misc_QuestionMark", 36, 55, 60)
        -- Clip only the model, leaving combat text free to rise above the unit.
        unit.viewport = CreateFrame("Frame", nil, unit)
        unit.viewport:SetPoint("TOPLEFT")
        unit.viewport:SetSize(132, 178)
        unit.viewport:SetClipsChildren(true)
        unit.model = CreateFrame("PlayerModel", nil, unit.viewport)
        unit.model:SetAllPoints(unit.viewport)
        unit.model:EnableMouse(false)
        unit.model:SetScript("OnModelLoaded", function()
            modelLoaded(unit, not friendly)
        end)
        unit.name = U.Text(unit, "", 0, 179, 12, T.text, 132)
        U.SingleLine(unit.name, 132, 19, "CENTER")
        unit.hp = U.Bar(unit, 4, 201, 124, 8, friendly and T.green or { 0.86, 0.38, 0.32 })
        unit.detail = U.Text(unit, "", 0, 212, 10, T.muted, 132)
        U.SingleLine(unit.detail, 132, 16, "CENTER")
        unit.floating = U.Text(unit, "", 24, 12, 19, T.gold)
        U.SingleLine(unit.floating, 84, 26, "CENTER")
        unit.floating:SetAlpha(0)
        unit.floatAnimation = unit.floating:CreateAnimationGroup()
        local rise = unit.floatAnimation:CreateAnimation("Translation")
        rise:SetOffset(0, 46)
        rise:SetDuration(1.1)
        local fade = unit.floatAnimation:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetSmoothing("OUT")
        fade:SetDuration(1.1)
        unit.floatAnimation:SetScript("OnFinished", function()
            unit.floating:SetAlpha(0)
        end)
        if friendly then
            local index = i
            unit:SetScript("OnMouseUp", function(_, mouseButton)
                if mouseButton == "LeftButton" and not W.state.ui.locked then
                    W.UI:SelectHero(index)
                end
            end)
        end
        self.units[i] = unit
    end
    return self
end

function Scene:Layout(compact, management)
    self.compact, self.management = compact, management
    local f = self.frame
    f:ClearAllPoints()
    local scale = compact and 556 / 1296 or 1
    f:SetScale(scale)
    f:SetSize(1296, compact and 344 or management and 150 or 360)
    f:SetPoint("TOPLEFT", compact and 12 / scale or 28, compact and -80 / scale or -151)
    self.chapter:SetShown(not compact)
    self.caption:SetShown(not compact)
    self.status:SetShown(not compact)
    self.note:SetShown(management)
    self.scenery.header:SetHeight(management and 150 or 88)
    self.scenery.footer:SetHeight(management and 0 or 78)
    for i, unit in ipairs(self.units) do
        local friendly = i <= 5
        local x = friendly and 30 + (i - 1) * 132 or 862 + (i - 6) * 138
        unit:ClearAllPoints()
        unit:SetPoint("TOPLEFT", x, -122)
        unit:EnableMouse(friendly and not W.state.ui.locked)
        unit.name:SetFont("Fonts\\FRIZQT__.TTF", compact and 24 or 12, "")
        unit.name:SetHeight(compact and 30 or 19)
        unit.name:SetWidth(132)
        unit.detail:SetShown(not compact and not friendly)
    end
    -- The banner and stage have different aspect ratios even in the same zone.
    self.scenery:SetZone(W.state.zone)
end

function Scene:Refresh(s)
    local z = C.zoneByID[s.zone]
    if self.renderState ~= s or self.zone ~= s.zone then
        self.lastBattle = nil
        self.renderState, self.zone = s, s.zone
    end
    local freshBattle = s.battle and s.battle ~= self.lastBattle
    if s.battle then
        self.lastBattle = s.battle
    end
    local b = s.battle or self.lastBattle
    self.scenery:SetZone(z.id)
    self.chapter:SetText("AZEROTH  /  " .. string.upper(z.name))
    self.caption:SetText(z.subtitle)
    self.status:SetText(
        (s.farming and "FARMING" or "ADVANCING")
            .. "  /  Encounter "
            .. s.stage
            .. (b and b.boss and "  ·  BOSS" or "")
    )
    self.note:SetText(
        "Your company keeps adventuring. Equipment, talents, and destinations can be changed at any time."
    )
    for i, unit in ipairs(self.units) do
        local hero = i <= 5 and s.heroes[i] or nil
        local enemy = i > 5 and b and b.enemies[i - 5] or nil
        local present = hero ~= nil or enemy ~= nil
        unit:SetShown(present and not self.management)
        unit.name:SetShown(not self.compact or hero ~= nil)
        if present and not self.management then
            if freshBattle then
                unit.dead, unit.deathTime, unit.animTime = false, nil, nil
                if unit.modelReady then
                    W.Client.AnimateModel(unit.model, 0)
                end
            end
            local class = hero and C.classByID[hero.class]
            local spec = W.Client.ModelSpec(hero, z.id, enemy and enemy.name)
            local key = spec and spec.key or "unavailable"
            if unit.modelKey ~= key then
                unit.modelReady = false
                unit.modelKey = key
                -- Set before ConfigureModel: loading may finish synchronously or later.
                unit.modelSpec = spec
                unit.floatAnimation:Stop()
                unit.floating:SetAlpha(0)
                unit.animTime = nil
                unit.modelConfigured, unit.modelError =
                    W.Client.ConfigureModel(unit.model, spec, enemy ~= nil)
            end
            local hp, maxHP, detail
            if hero then
                local stats = W.Game.Stats(s, hero)
                local battleHero = b and b.heroes[i]
                hp, maxHP =
                    battleHero and battleHero.hp or stats.hp * (hero.health or 1),
                    battleHero and battleHero.maxHP or stats.hp
                detail = b and not battleHero and "Joins next encounter" or ""
                unit.name:SetText(hero.name)
            elseif enemy and b then
                hp, maxHP = enemy.hp, enemy.maxHP
                detail = "Lv " .. b.level .. "  ·  " .. U.Number(hp) .. " HP"
                unit.name:SetText(enemy.name)
            else
                hp, maxHP, detail = 1, 1, ""
            end
            unit.name:SetTextColor(unpack(class and class.color or { 0.95, 0.69, 0.53 }))
            unit.detail:SetShown(not self.compact and (not hero or (b and not b.heroes[i])))
            unit.hp:SetValue(math.max(0, hp / maxHP))
            if hp <= 0 and not unit.dead then
                unit.dead, unit.deathTime = true, GetTime()
                unit.animTime = nil
                if unit.modelReady then
                    W.Client.AnimateModel(unit.model, 1)
                end
            elseif hp > 0 and unit.dead then
                unit.dead, unit.deathTime = false, nil
                W.Client.AnimateModel(unit.model, 0)
            end
            unit.model:SetShown(true)
            unit.model:SetAlpha(unit.modelReady and 1 or 0)
            unit.sigil:SetShown(not unit.modelReady and hp > 0)
            unit.sigil:SetTexture(
                "Interface\\Icons\\" .. (class and class.icon or "Ability_Creature_Cursed_02")
            )
            unit.name:SetAlpha(hp > 0 and 1 or 0.45)
            unit.detail:SetText(hp > 0 and detail or "Defeated")
        end
    end
    if s.events then
        if not self.management then
            for _, event in ipairs(s.events) do
                if event.kind == "hit" or event.kind == "heal" then
                    local unit = self.units[event.target + (event.enemy and 5 or 0)]
                    if unit and unit:IsShown() and s.settings.combatText then
                        unit.floating:SetText((event.kind == "heal" and "+" or "-") .. event.amount)
                        unit.floating:SetTextColor(
                            unpack(event.kind == "heal" and T.green or T.gold)
                        )
                        unit.floatAnimation:Stop()
                        unit.floating:SetAlpha(1)
                        unit.floatAnimation:Play()
                    end
                elseif event.kind == "cast" then
                    local unit = self.units[event.source]
                    if unit and unit.modelReady and not unit.dead then
                        W.Client.AnimateModel(unit.model, event.action == "heal" and 51 or 16)
                        unit.animTime = GetTime()
                    end
                end
            end
        end
        s.events = {}
    end
end

-- Presentation advances at the frame rate, independently of simulation ticks.
function Scene:Animate()
    local now = GetTime()
    for _, unit in ipairs(self.units) do
        if unit.deathTime and now - unit.deathTime >= 1.5 then
            W.Client.AnimateModel(unit.model, 6)
            unit.deathTime = nil
        end
        if unit.animTime and now - unit.animTime > 1 then
            if not unit.dead then
                W.Client.AnimateModel(unit.model, 0)
            end
            unit.animTime = nil
        end
    end
end
