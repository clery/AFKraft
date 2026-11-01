local _, W = ...
local U, T, C, P = W.Widgets, W.Theme, W.Content, W.CombatPosition
local Scene = {}
W.Scene = Scene

local function baseAnimation(unit)
    if unit.moving or unit.travelling then
        return 5
    end
    return unit.inCombat and W.Client.ReadyAnimation(unit.class, unit.melee) or 0
end

function Scene.FinishAnimation(unit)
    if unit.animTime and not unit.dead then
        -- Clear first: restoring the looping stance must not finish the attack again.
        unit.animTime, unit.animDuration = nil, nil
        local pose = baseAnimation(unit)
        W.Client.AnimateModel(unit.model, pose)
        unit.basePose = pose
    end
end

-- A critically damped spring preserves velocity when quarter-second targets
-- change. Unlike chasing at extra speed, it never catches up and waits for a tick.
local function smoothCoordinate(current, velocity, target, elapsed)
    if math.abs(current - target) < 0.001 and math.abs(velocity) < 0.01 then
        return target, 0
    end
    local frequency = 14
    local change = current - target
    local decay = math.exp(-frequency * elapsed)
    local carry = (velocity + frequency * change) * elapsed
    return target + (change + carry) * decay, (velocity - frequency * carry) * decay
end

function Scene.MoveUnit(unit, elapsed)
    unit.x, unit.velocityX = smoothCoordinate(unit.x, unit.velocityX or 0, unit.targetX, elapsed)
    unit.y, unit.velocityY = smoothCoordinate(unit.y, unit.velocityY or 0, unit.targetY, elapsed)
    local dx, dy = unit.targetX - unit.x, unit.targetY - unit.y
    return dx * dx + dy * dy > 0.04 or math.abs(unit.velocityX) + math.abs(unit.velocityY) > 0.5
end

function Scene:BeginRegroup()
    self.regroup = { elapsed = 0, duration = 0.8 }
    for i = 1, 5 do
        local unit = self.units[i]
        unit.regroupX, unit.regroupY = unit.x, unit.y
        unit.pendingAnimation, unit.animTime, unit.animDuration = nil, nil, nil
        unit.actionAt, unit.recoilAt = nil, nil
        unit.velocityX, unit.velocityY = 0, 0
        if unit:IsShown() and not unit.dead and unit.modelReady then
            -- Start the whole company together, including stationary ranged heroes.
            W.Client.AnimateModel(unit.model, 5)
            unit.basePose = 5
        end
    end
end

local function modelAlpha(unit, now)
    local entrance = math.min(1, math.max(0, (now - (unit.appeared or now - 1)) / 0.35))
    -- Separate PlayerModel viewports can retain depth occlusion when faded.
    -- Corpses remain opaque until their death presentation ends, then are hidden.
    return unit.modelReady and (unit.dead and 1 or entrance) or 0
end

local function updateModelVisibility(unit, now)
    local expired = unit.dead and unit.defeatedAt and now - unit.defeatedAt >= 1.5
    unit.model:SetShown(not expired)
    unit.model:SetAlpha(modelAlpha(unit, now))
end

local function modelLoaded(unit, enemy)
    local id = unit.model:GetModelFileID()
    local wasReady = unit.modelReady
    unit.modelReady = type(id) == "number" and id > 0
    if unit.modelReady then
        if not wasReady then
            unit.appeared = GetTime()
        end
        local ok, framed = pcall(W.Client.FrameModel, unit.model, enemy, unit.modelSpec)
        unit.modelReady = ok and framed == true
        if not unit.modelReady then
            return
        end
        W.Client.AnimateModel(
            unit.model,
            unit.dead and (unit.deathTime and 1 or 6) or baseAnimation(unit)
        )
    end
end

local function stopLevelUp(unit)
    unit.levelUpUntil = nil
    if unit.levelUp then
        unit.levelUp:Hide()
        unit.levelUp:ClearModel()
    end
end

local function playLevelUp(unit)
    if not unit.levelUp then
        -- Keep the native particle effect separate from the character's poses.
        unit.levelUp = CreateFrame("PlayerModel", nil, unit.viewport)
        unit.levelUp:SetAllPoints(unit.viewport)
        unit.levelUp:EnableMouse(false)
        unit.levelUp:SetScript("OnModelLoaded", function(model)
            W.Client.FrameSpellEffect(model, W.Client.SpellEffectSpec("levelup"))
            if model:IsShown() then
                unit.levelUpUntil = GetTime() + 3
            end
        end)
    end
    unit.levelUp:Show()
    if W.Client.PlayLevelUp(unit.levelUp) then
        unit.levelUpUntil = GetTime() + 3
    else
        stopLevelUp(unit)
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
    self.nameplates = CreateFrame("Frame", nil, content)
    self.nameplates:SetAllPoints(content)
    self.nameplates:SetFrameLevel(content:GetFrameLevel() + 200)
    self.effects = W.CombatEffects.Create(content)
    self.units = {}
    self.plateOrder = {}
    for i = 1, 8 do
        local unit = CreateFrame("Frame", nil, content)
        local friendly = i <= 5
        unit.index = i
        unit:SetScript("OnHide", stopLevelUp)
        unit:SetSize(132, 204)
        unit.sigil = U.Icon(unit, "INV_Misc_QuestionMark", 36, 88, 60)
        -- Transparent model viewports extend beyond the small interaction/nameplate
        -- footprint, leaving room for tails, weapons, particles and attack poses.
        unit.viewport = CreateFrame("Frame", nil, unit)
        unit.groundOffset = friendly and 0 or W.ModelAssets.creatureGroundOffset
        unit.viewport:SetPoint("BOTTOM", unit, "BOTTOM", 0, unit.groundOffset)
        unit.viewport:SetSize(360, 240)
        unit.viewport:SetClipsChildren(false)
        unit.model = W.Client.CreateAdventureModel(unit.viewport, function()
            modelLoaded(unit, not friendly)
        end)
        unit.model:SetAllPoints(unit.viewport)
        unit.model:EnableMouse(false)
        unit.plate = CreateFrame("Frame", nil, self.nameplates)
        unit.plate:SetSize(132, 52)
        unit.plate:SetPoint("TOP", unit, "TOP")
        unit.name = U.Text(unit.plate, "", 0, 0, 12, T.text, 132)
        U.SingleLine(unit.name, 132, 19, "CENTER")
        unit.hp = U.Bar(unit.plate, 4, 24, 124, 10, friendly and { 0, 1, 0 } or { 1, 0, 0 }, true)
        unit.detail = U.Text(unit.plate, "", 0, 36, 10, T.muted, 132)
        U.SingleLine(unit.detail, 132, 16, "CENTER")
        unit.floating = U.Text(unit.plate, "", 24, 58, 19, T.gold)
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
    if self.compact ~= compact or self.management ~= management then
        self.effects:Clear()
    end
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
        local x = unit.x or (friendly and 30 + (i - 1) * 132 or 862 + (i - 6) * 138)
        unit:ClearAllPoints()
        unit:SetPoint("TOPLEFT", x, -(unit.y or 110))
        unit:EnableMouse(friendly and not W.state.ui.locked)
        unit.name:SetFont("Fonts\\FRIZQT__.TTF", compact and 20 or 12, "")
        unit.name:SetHeight(compact and 24 or 19)
        unit.name:SetWidth(132)
        unit.detail:SetShown(not compact and unit.waiting)
    end
    -- The banner and stage have different aspect ratios even in the same zone.
    self.scenery:SetZone(W.state.zone)
end

function Scene:Refresh(s)
    local z = C.zoneByID[s.zone]
    if self.renderState ~= s or self.zone ~= s.zone then
        self.effects:Clear()
        self.regroup = nil
        self.lastBattle = nil
        self.renderState, self.zone = s, s.zone
    end
    local freshBattle = s.battle and s.battle ~= self.lastBattle
    if freshBattle then
        self.effects:Clear()
        self.regroup = nil
    end
    if s.battle then
        self.lastBattle = s.battle
    end
    local b = s.battle or self.lastBattle
    local wasTravelling = self.travelling
    self.travelling = s.battle == nil
    if s.battle then
        P.Ensure(s, s.battle)
    end
    self.scenery:SetZone(z.id)
    self.chapter:SetText("AZEROTH  /  " .. string.upper(z.name))
    self.caption:SetText(z.subtitle)
    self.status:SetText(
        (s.farming and "FARMING" or "ADVANCING")
            .. "  /  Encounter "
            .. s.stage
            .. (b and ("  ·  LEVEL " .. b.level .. (b.boss and " BOSS" or " MOBS")) or "")
    )
    self.note:SetText(
        "Your company keeps adventuring. Equipment, talents, and destinations can be changed at any time."
    )
    for i, unit in ipairs(self.units) do
        local hero = i <= 5 and s.heroes[i] or nil
        local enemy = i > 5 and b and b.enemies[i - 5] or nil
        local present = hero ~= nil or enemy ~= nil
        unit:SetShown(present and not self.management)
        unit.name:Show()
        unit.plate:SetShown(present and not self.management)
        if present and not self.management then
            if freshBattle then
                unit.dead, unit.deathTime, unit.animTime = false, nil, nil
                unit.moving, unit.basePose = nil, nil
                unit.recoilAt, unit.actionAt = nil, nil
                if i > 5 then
                    unit.velocityX, unit.velocityY = 0, 0
                    unit.appeared = GetTime()
                end
                if unit.modelReady then
                    W.Client.AnimateModel(unit.model, 0)
                end
            end
            local class = hero and C.classByID[hero.class]
            local combatant = hero and b and b.heroes[i] or enemy
            unit.class = hero and hero.class
            unit.combatant = combatant
            unit.homeX = combatant and combatant.homeX or 40 + (i - 1) * 112
            unit.homeY = combatant and combatant.homeY or 96 + (i - 1) * 9
            unit.melee = combatant and combatant.melee or false
            unit.inCombat = s.battle ~= nil and combatant ~= nil
            unit.travelling = hero ~= nil and self.travelling
            if unit.wasInCombat ~= unit.inCombat then
                unit.wasInCombat = unit.inCombat
                if
                    unit.modelReady
                    and not unit.dead
                    and not unit.animTime
                    and not unit.travelling
                then
                    W.Client.AnimateModel(unit.model, baseAnimation(unit))
                end
            end
            local x = unit.travelling and unit.homeX or combatant and combatant.x or unit.homeX
            local y = unit.travelling and unit.homeY or combatant and combatant.y or unit.homeY
            unit.targetX, unit.targetY = x, y
            if freshBattle then
                unit.pendingAnimation = nil
                unit.sampleTime, unit.sampleX, unit.sampleY = nil, nil, nil
                unit.previousX, unit.previousY = nil, nil
                unit.x = hero and (unit.x or x) or x
                unit.y = hero and (unit.y or y) or y
            else
                unit.x, unit.y = unit.x or x, unit.y or y
            end
            unit:ClearAllPoints()
            unit:SetPoint("TOPLEFT", unit.x, -unit.y)
            local spec = W.Client.ModelSpec(hero, z.id, enemy and enemy.name)
            local key = spec and spec.key or "unavailable"
            if unit.modelKey ~= key then
                unit.modelReady = false
                unit.modelKey = key
                unit.appeared = GetTime()
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
            unit.waiting = hero ~= nil and b ~= nil and not b.heroes[i]
            unit.detail:SetShown(not self.compact and unit.waiting)
            unit.hp:SetValue(maxHP > 0 and math.max(0, hp / maxHP) or 0)
            if hp <= 0 and not unit.dead then
                unit.dead, unit.deathTime = true, GetTime()
                unit.defeatedAt = unit.deathTime
                unit.velocityX, unit.velocityY = 0, 0
                unit.animTime, unit.pendingAnimation = nil, nil
                if unit.modelReady then
                    W.Client.AnimateModel(unit.model, 1)
                end
            elseif hp > 0 and unit.dead then
                unit.dead, unit.deathTime, unit.defeatedAt = false, nil, nil
                W.Client.AnimateModel(unit.model, 0)
            end
            updateModelVisibility(unit, GetTime())
            unit.sigil:SetShown(not unit.modelReady and hp > 0)
            unit.sigil:SetTexture(
                "Interface\\Icons\\" .. (class and class.icon or "Ability_Creature_Cursed_02")
            )
            unit.name:SetAlpha(hp > 0 and 1 or 0.45)
            unit.detail:SetText(hp > 0 and detail or "Defeated")
        end
    end
    if self.travelling and not wasTravelling and b then
        self:BeginRegroup()
    end
    if s.events then
        if not self.management then
            for _, event in ipairs(s.events) do
                self.effects:Event(self.units, s, event)
                if event.kind == "hit" or event.kind == "heal" then
                    local unit = self.units[event.target + (event.enemy and 5 or 0)]
                    -- Basic swings and enemy attacks also animate, even with combat text off.
                    if event.kind == "hit" then
                        local source = self.units[(event.source or 0) + (event.enemy and 0 or 5)]
                        if source and not source.dead then
                            source.pendingAnimation =
                                W.Client.AttackAnimation(source.class, source.melee)
                        end
                    end
                    if unit and event.kind == "hit" and not unit.dead then
                        unit.recoilAt = GetTime()
                    end
                    if unit and unit:IsShown() and s.settings.combatText then
                        unit.floating:SetText((event.kind == "heal" and "+" or "-") .. event.amount)
                        unit.floating:SetTextColor(
                            unpack(event.kind == "heal" and T.green or T.gold)
                        )
                        unit.floatAnimation:Stop()
                        unit.floating:SetAlpha(1)
                        unit.floatAnimation:Play()
                    end
                elseif event.kind == "levelup" and event.target then
                    local unit = self.units[event.target]
                    if unit and event.target <= 5 and unit:IsVisible() then
                        playLevelUp(unit)
                    end
                elseif event.kind == "cast" then
                    local unit = self.units[event.source]
                    if unit and not unit.dead then
                        unit.pendingAnimation =
                            W.Client.AttackAnimation(unit.class, unit.melee, event.action)
                    end
                end
            end
        end
        s.events = {}
    end
end

-- Keep overhead bars above their owners, with horizontal spacing when crowded.
local function sortByPosition(a, b)
    return a.x < b.x or (a.x == b.x and a.index < b.index)
end

function Scene:PlaceNameplates()
    local order, count = self.plateOrder, 0
    for _, unit in ipairs(self.units) do
        local visible = unit:IsShown() and unit.x and unit.x < 1270
        unit.plate:SetShown(visible)
        if visible then
            count = count + 1
            order[count] = unit
        end
    end
    for i = #order, count + 1, -1 do
        order[i] = nil
    end
    table.sort(order, sortByPosition)
    -- Keep the health bar relative to its rendered owner. Resolve congestion along
    -- the horizontal axis so no row pushes a bar down onto a character or up
    -- into the scene heading. All eight plates fit within the stage width.
    local previous = -132
    for _, unit in ipairs(order) do
        unit.plateX = math.max(8, unit.x, previous + 140)
        previous = unit.plateX
    end
    local nextX = 1280
    for i = count, 1, -1 do
        local unit = order[i]
        unit.plateX = math.min(unit.plateX, nextX - 140)
        nextX = unit.plateX
        local y = (unit.y or 110) - 28
        if unit.plateX ~= unit.lastPlateX or y ~= unit.lastPlateY then
            unit.plate:ClearAllPoints()
            unit.plate:SetPoint("TOPLEFT", self.nameplates, "TOPLEFT", unit.plateX, -y)
            unit.lastPlateX, unit.lastPlateY = unit.plateX, y
        end
    end
end

-- Presentation advances at the frame rate, independently of simulation ticks.
function Scene:Animate(frameElapsed, simulationFraction)
    local now = GetTime()
    -- OnUpdate's elapsed is the render clock. GetTime can lose sub-frame
    -- precision after long client/system uptimes; retain it only for event ages.
    local elapsed = math.min(0.1, math.max(0, frameElapsed or now - (self.lastAnimation or now)))
    self.lastAnimation = now
    if self.management or not self.frame:IsShown() then
        return
    end
    local regroup = self.regroup
    local regroupProgress
    if regroup then
        regroup.elapsed = math.min(regroup.duration, regroup.elapsed + elapsed)
        local fraction = regroup.elapsed / regroup.duration
        regroupProgress = fraction * fraction * (3 - 2 * fraction)
    end
    for _, unit in ipairs(self.units) do
        if unit.levelUpUntil and now >= unit.levelUpUntil then
            stopLevelUp(unit)
        end
        if unit:IsShown() and unit.travelling then
            unit.targetX, unit.targetY = unit.homeX, unit.homeY
        elseif unit:IsShown() and unit.combatant then
            local combatant = unit.combatant
            local tick = self.lastBattle and self.lastBattle.elapsed
            if simulationFraction and tick and not self.travelling then
                if unit.sampleTime ~= tick then
                    -- Capture every tick, including stationary samples, so alpha
                    -- wrapping to zero cannot replay the previous movement.
                    unit.previousX = unit.sampleX or unit.x
                    unit.previousY = unit.sampleY or unit.y
                    unit.sampleX, unit.sampleY = combatant.x, combatant.y
                    unit.sampleTime = tick
                end
                local alpha = math.min(1, math.max(0, simulationFraction))
                unit.targetX = unit.previousX + (unit.sampleX - unit.previousX) * alpha
                unit.targetY = unit.previousY + (unit.sampleY - unit.previousY) * alpha
            else
                unit.targetX, unit.targetY = combatant.x, combatant.y
            end
            unit.targetID, unit.targetEnemy = unit.combatant.targetID, unit.combatant.targetEnemy
        end
        if unit:IsShown() and unit.targetX then
            local moving = false
            if not unit.dead then
                local x, y = unit.x, unit.y
                if unit.travelling and regroupProgress and unit.regroupX then
                    unit.x = unit.regroupX + (unit.homeX - unit.regroupX) * regroupProgress
                    unit.y = unit.regroupY + (unit.homeY - unit.regroupY) * regroupProgress
                    moving = regroupProgress < 1 and (unit.x ~= unit.homeX or unit.y ~= unit.homeY)
                else
                    moving = Scene.MoveUnit(unit, elapsed)
                        or (not self.travelling and unit.combatant and unit.combatant.moving)
                        or false
                end
                if x ~= unit.x or y ~= unit.y then
                    unit:ClearAllPoints()
                    unit:SetPoint("TOPLEFT", unit.x, -unit.y)
                end
            end
            if moving ~= unit.moving or unit.travelAnimation ~= unit.travelling then
                unit.moving, unit.travelAnimation = moving, unit.travelling
                if not unit.dead then
                    local pose = baseAnimation(unit)
                    if pose ~= unit.basePose or unit.animTime then
                        W.Client.AnimateModel(unit.model, pose)
                        unit.basePose = pose
                    end
                    unit.animTime = nil
                end
            end
        end
        if
            unit.pendingAnimation
            and not unit.travelling
            and not unit.moving
            and unit.modelReady
            and not unit.dead
        then
            W.Client.AnimateModel(unit.model, unit.pendingAnimation)
            unit.basePose = nil
            unit.actionAt = now
            -- Completion callbacks restore the stance; this bound also covers models
            -- that do not deliver OnAnimFinished for their selected sequence.
            unit.animDuration = unit.pendingAnimation == W.Client.animations.fireBow and 0.65 or 1
            unit.pendingAnimation, unit.animTime = nil, now
        end
        updateModelVisibility(unit, now)
        -- Reactions offset only the viewport, never the simulation coordinates.
        local offset = 0
        if not unit.dead and unit:IsShown() then
            local actionAge = unit.actionAt and now - unit.actionAt or 1
            local recoilAge = unit.recoilAt and now - unit.recoilAt or 1
            if actionAge < 0.4 then
                offset = math.sin(actionAge / 0.4 * math.pi) * (unit.melee and 9 or -3)
            end
            if recoilAge < 0.3 then
                offset = offset - math.sin(recoilAge / 0.3 * math.pi) * 6
            end
            offset = offset * (unit.index <= 5 and 1 or -1)
        end
        if offset ~= unit.visualOffset then
            unit.viewport:ClearAllPoints()
            unit.viewport:SetPoint("BOTTOM", unit, "BOTTOM", offset, unit.groundOffset)
            unit.visualOffset = offset
        end
        if unit.deathTime and now - unit.deathTime >= 1.5 then
            W.Client.AnimateModel(unit.model, 6)
            unit.deathTime = nil
        end
        if unit.animTime and now - unit.animTime >= (unit.animDuration or 1) then
            Scene.FinishAnimation(unit)
        end
    end
    if regroup and regroup.elapsed >= regroup.duration then
        self.regroup = nil
    end
    self.effects:Animate(now)
    self:PlaceNameplates()
end
