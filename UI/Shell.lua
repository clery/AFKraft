local _, W = ...
local L = W.L
local U, T, C = W.Widgets, W.Theme, W.Content
local UI = {}
UI.__index = UI
local tabs = {
    { "adventure", L.ADVENTURE, L.JOURNEY_HEADING },
    { "atlas", L.WORLD_MAP },
    { "routes", L.ROUTES },
    { "party", L.PARTY_EQUIPMENT, L.COMPANY_HEADING },
    { "chests", L.CHESTS },
    { "talents", L.TALENTS_PRIORITIES },
    { "crafting", L.FORGE },
    { "boosts", L.COMMANDER, L.STRATEGY_HEADING },
    { "profiles", L.PROFILES },
    { "loot", L.LOOT_RULES },
    { "development", L.GROWTH, L.PROGRESSION_HEADING },
    { "collections", L.COLLECTIONS },
    { "legacy", L.HERITAGE },
    { "difficulty", L.TRANSCENDENCE },
}
local tabIcons = {
    adventure = "INV_Misc_Map_01",
    party = "Achievement_GuildPerk_EverybodysFriend",
    chests = "INV_Misc_TreasureChest02a",
    talents = "Ability_Marksmanship",
    crafting = "Trade_BlackSmithing",
    atlas = "INV_Misc_Map02",
    legacy = "INV_Misc_Book_09",
    loot = "INV_Misc_Bag_10",
    boosts = "Ability_Warrior_RallyingCry",
    profiles = "INV_Misc_Note_01",
    routes = "Ability_Hunter_Pathfinding",
    collections = "INV_Misc_TreasureChest01a",
    workshop = "Trade_BlackSmithing",
    difficulty = "Ability_Warrior_InnerRage",
    development = "Ability_Warrior_BattleShout",
}

function UI:SelectHero(index)
    if W.catchup then
        return
    end
    self.selected = index
    self.recruiting = not W.state.heroes[index]
    local tab = W.state.ui.tab
    if self.recruiting or (tab ~= "party" and tab ~= "talents" and tab ~= "crafting") then
        tab = "party"
    end
    self:SetTab(tab)
end

function UI:SetTab(tab)
    if W.catchup then
        return
    end
    W.state.ui.tab = tab
    if self.map then
        self.map:Hide()
    end
    self.confirmPrestige = false
    self.difficultyConfirm = false
    if W.state.ui.compact then
        W.state.ui.compact = false
        self:ApplyMode()
    else
        self:Layout()
    end
    self:Refresh()
end

function UI:SaveGeometry()
    local f, s = self.frame, W.state
    if self.fullscreen and not s.ui.compact then
        return
    end
    local x, y = f:GetLeft(), f:GetTop()
    s.ui[s.ui.compact and "compactGeometry" or "expandedGeometry"] =
        { w = f:GetWidth(), h = f:GetHeight(), x = x, y = y }
end

function UI:ApplyMode()
    local f, s = self.frame, W.state
    local compact = s.ui.compact
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    local minW, minH = math.min(1280, screenW), math.min(720, screenH)
    f:ClearAllPoints()
    if compact then
        self.confirmPrestige = false
        local geo = s.ui.compactGeometry or { w = 580, h = 370 }
        f:SetSize(math.min(geo.w, screenW), math.min(geo.h, screenH))
        if geo.x and geo.y then
            f:SetPoint(
                "TOPLEFT",
                UIParent,
                "BOTTOMLEFT",
                math.max(0, math.min(geo.x, screenW - f:GetWidth())),
                math.min(screenH, math.max(f:GetHeight(), geo.y))
            )
        else
            f:SetPoint("RIGHT", UIParent, "RIGHT", -24, 0)
        end
        f:SetResizeBounds(400, 255, math.max(400, screenW), math.max(255, screenH))
    elseif self.fullscreen then
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
        f:SetSize(screenW, screenH)
        f:SetResizeBounds(minW, minH, screenW, screenH)
    else
        local geo = s.ui.expandedGeometry
            or {
                w = math.min(1280, screenW),
                h = math.min(720, screenH),
            }
        f:SetSize(
            math.max(minW, math.min(geo.w, screenW)),
            math.max(minH, math.min(geo.h, screenH))
        )
        if geo.x and geo.y then
            f:SetPoint(
                "TOPLEFT",
                UIParent,
                "BOTTOMLEFT",
                math.max(0, math.min(geo.x, screenW - f:GetWidth())),
                math.min(screenH, math.max(f:GetHeight(), geo.y))
            )
        else
            f:SetPoint("CENTER")
        end
        f:SetResizeBounds(minW, minH, screenW, screenH)
    end
    self:Layout()
    self:Refresh()
end

function UI:Layout()
    local compact = W.state.ui.compact
    local width, height = compact and 580 or 1600, compact and 370 or 900
    local scale = math.min(self.frame:GetWidth() / width, self.frame:GetHeight() / height)
    self.canvas:SetScale(scale)
    self.canvas:SetSize(width, height)
    local management = not compact and (W.state.ui.tab or "adventure") ~= "adventure"
    if management then
        W.Audio.Stop()
    end
    local heroPage = W.state.ui.tab == "party" or W.state.ui.tab == "talents"
    local forge = W.state.ui.tab == "crafting" or W.state.ui.tab == "workshop"
    self.forgeContainer:SetShown(not compact and forge)
    for _, control in pairs(self.forgeTabs) do
        control:SetShown(not compact and forge)
    end
    self.scene:Layout(compact, management)
    self.scene.frame:SetShown(compact or not management)
    if not compact then
        self.scene.frame:ClearAllPoints()
        self.scene.frame:SetPoint("TOPLEFT", self.workspace, "TOPLEFT", 0, -151)
    end
    for i, card in ipairs(self.cards) do
        card:SetShown(not management or heroPage)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", (i - 1) * 261.6, management and -155 or -528)
    end
    self.panel:ClearAllPoints()
    self.panel:SetPoint(
        "TOPLEFT",
        0,
        forge and -211 or management and (heroPage and -251 or -155) or -620
    )
    self.panel:SetSize(1296, forge and 639 or management and (heroPage and 599 or 695) or 240)
    self.expanded:SetShown(not compact)
    self.compact:SetShown(compact)
    for tab, frame in pairs({
        chests = self.chestFrame,
        routes = self.routeFrame,
        profiles = self.profileFrame,
        collections = self.collectionFrame,
        workshop = self.professionFrame,
    }) do
        if frame then
            frame:SetShown(not compact and W.state.ui.tab == tab and not W.catchup)
        end
    end
    self.adventureCompact.frame:EnableMouse(not W.state.ui.locked)
    self.grip:SetShown(not self.fullscreen or compact)
    self.scene.frame:EnableMouse(not W.state.ui.locked)
    self.frame:EnableMouse(not compact or not W.state.ui.locked)
    if self.drag then
        self.drag:EnableMouse(not W.state.ui.locked)
    end
end

function UI:ShowMap()
    local zone = C.zoneByID[W.state.zone]
    local map = self.map
    if not map then
        map = CreateFrame("Frame", nil, self.canvas)
        self.map = map
        map:SetPoint("CENTER")
        map:SetSize(960, 690)
        map:EnableMouse(true)
        map:SetFrameLevel(self.canvas:GetFrameLevel() + 50)
        U.Rect(map, 0, 0, 960, 690, T.bg)
        map.tiles = {}
        map.title = U.Text(map, "", 24, 22, 22, T.gold)
        U.Button(map, L.CLOSE_MAP, 780, 20, 150, 32, function()
            map:Hide()
        end)
        map.note = U.Text(map, "", 24, 640, 14, T.muted, 900)
        local clip = CreateFrame("Frame", nil, map)
        map.clip = clip
        clip:SetPoint("TOPLEFT", 24, -80)
        clip:SetSize(912, 540)
        clip:SetClipsChildren(true)
    end
    map.title:SetText(zone.name)
    for _, tile in ipairs(map.tiles) do
        tile:Hide()
    end
    local textures, info = W.Client.MapTiles(zone.id)
    if textures and info then
        local tw, th = info.tileWidth or 256, info.tileHeight or 256
        local lw, lh = info.layerWidth or 1002, info.layerHeight or 668
        local columns = math.ceil(lw / tw)
        local scale = math.min(912 / lw, 540 / lh)
        for i, id in ipairs(textures) do
            local tile = map.tiles[i]
            if not tile then
                tile = map.clip:CreateTexture(nil, "ARTWORK")
                map.tiles[i] = tile
            end
            tile:ClearAllPoints()
            tile:SetPoint(
                "TOPLEFT",
                (i - 1) % columns * tw * scale,
                -math.floor((i - 1) / columns) * th * scale
            )
            tile:SetSize(tw * scale, th * scale)
            tile:SetTexture(id)
            tile:Show()
        end
        map.note:SetText(L.YOUR_PARTY_TRAVELS_INDEPENDENTLY_OF_YOUR_WOW_CHARACTER_CHOOSE)
    else
        map.note:SetText(L.MAP_ARTWORK_IS_UNAVAILABLE_HERE_DESTINATIONS_REMAIN_AVAILABLE_IN)
    end
    map:Show()
end

function UI:Refresh(redraw)
    local s = W.state
    if not s then
        return
    end
    self.selected = math.min(self.selected or 1, #s.heroes)
    self.currencies.essence:SetText(U.Number(s.essence))
    self.currencies.gold:SetText(U.Number(s.gold))
    self.currencies.legacy:SetText(U.Number(s.legacy))
    self.adventureBar:Refresh(s)
    self.adventureCompact:Refresh(s)
    self.destination.text:SetText(s.ui.tab == "atlas" and L.ADVENTURE or L.WORLD_MAP)
    local resourceText = ""
    for _, id in ipairs(C.materialOrder) do
        resourceText = resourceText .. C.materials[id] .. " " .. U.Number(s.materials[id]) .. "    "
    end
    self.materials:SetText(resourceText)
    self.compactInfo:SetText(
        U.Number(s.essence) .. L.FRAGMENT_ESSENCE_2 .. U.Number(s.gold) .. L.GOLD_SUFFIX_2
    )
    self.compactZone:SetText(C.zoneByID[s.zone].name .. L.FRAGMENT_ENCOUNTER .. s.stage)
    self.battleState:SetText(
        (
            s.farming and L.FARMING
            or not s.battle and (s.rest or 0) > 0 and L.RECOVERING
            or L.ADVANCING
        )
            .. L.FRAGMENT_ENCOUNTER_2
            .. s.stage
    )
    U.Enabled(self.retry, s.farming == true)
    self.lock.text:SetText(s.ui.locked and L.UNLOCK or L.LOCK)
    self.compactMap:SetShown(not s.ui.locked)
    self.compactExpand:SetShown(not s.ui.locked)
    self.compactRetry:SetShown(not s.ui.locked)
    U.Enabled(self.compactRetry, s.farming == true)
    self.compactHint:SetText(
        s.ui.locked and L.WINDOW_LOCKED_ADVENTURE_CONTINUES
            or L.SELECT_A_HERO_TO_MANAGE_THEIR_BUILD_AT_ANY
    )
    for i, button in ipairs(self.cards) do
        local h = s.heroes[i]
        if h then
            local class = C.classByID[h.class]
            button.label:SetText(h.name)
            button.label:SetTextColor(unpack(i == self.selected and T.gold or class.color))
            local cap = W.Game.LevelCap(h)
            button.detail:SetText(
                L.LV_PREFIX
                    .. h.level
                    .. " / "
                    .. cap
                    .. "  ·  "
                    .. (
                        h.level >= C.heroLevelCap
                            and (L.MASTERY_PREFIX .. W.Game.MasteryProgress(h).rank)
                        or class.name
                    )
            )
            if h.level >= C.heroLevelCap then
                local mastery = W.Game.MasteryProgress(h)
                local cost = W.Game.MasteryCost(mastery.rank)
                button.xp:SetMinMaxValues(0, cost)
                button.xp:SetValue(
                    W.Game.TalentProgress(h).earned >= #W.Game.TalentList(h) and cost or mastery.xp
                )
            else
                button.xp:SetMinMaxValues(0, W.Game.LevelXP(h.level))
                button.xp:SetValue(h.xp)
            end
            button.icon:SetTexture("Interface\\Icons\\" .. class.icon)
            button.xp:Show()
        else
            local available = i <= W.Game.CompanionSlots(s)
            button.label:SetText(
                available and L.COMPANION_FOUND or L.COMPANION_PREFIX .. i .. L.LOCKED_SUFFIX
            )
            button.label:SetTextColor(unpack(available and T.gold or T.muted))
            button.detail:SetText(
                available and L.CHOOSE_A_CLASS_IN_PARTY
                    or L.MILESTONE_BOSS_LEVEL_PREFIX .. C.companionMilestones[i]
            )
            button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            button.xp:Hide()
        end
        U.Selected(button, i == self.selected)
    end
    local points, _, cappedHero, routes = W.Panels.Opportunities(s)
    self.tabs.talents.notice:SetText(
        points > 0 and (points .. (points == 1 and L.POINT_SUFFIX_2 or L.POINTS_SUFFIX_2)) or ""
    )
    local chestCount = W.Game.ChestCount(s)
    self.tabs.chests.notice:SetText(chestCount > 0 and tostring(chestCount) or "")
    self.tabs.party.notice:SetText(#s.heroes < W.Game.CompanionSlots(s) and L.RECRUIT or "")
    self.tabs.atlas.notice:SetText(routes > 0 and (routes .. L.DESTINATIONS_SUFFIX) or "")
    self.tabs.legacy.notice:SetText(
        s.prestigeUnlocked and ("+" .. W.Game.PrestigeReward(s) .. L.HERITAGE_SUFFIX) or ""
    )
    local nextLesson = W.Tutorial.NextLesson(s)
    local guidance = table.concat({
        points,
        cappedHero or 0,
        s.runBest,
        s.zone,
        tostring(s.prestigeUnlocked),
        W.Game.PrestigeReward(s),
        tostring(s.farming),
        W.Panels.GuideStep(s, self.selected) or 0,
        tostring(s.guide.dismissed),
        W.Game.CompanionSlots(s),
        nextLesson and nextLesson.key or "",
        chestCount,
    }, ":")
    for id, button in pairs(self.tabs) do
        local active = s.ui.tab == id or (id == "crafting" and s.ui.tab == "workshop")
        U.Selected(button, active)
        local hint = W.Tutorial.MenuHint(s, id)
        button.text:SetText(hint and "???" or button.menuLabel)
        button.icon:SetTexture(
            "Interface\\Icons\\" .. (hint and "INV_Misc_QuestionMark" or tabIcons[id])
        )
        button.notice:SetShown(not hint)
        if button.menuHint ~= hint then
            U.Tooltip(
                button,
                hint and "???" or button.menuLabel,
                hint or (L.OPEN_PREFIX .. button.menuLabel)
            )
            button.menuHint = hint
        end
    end
    for _, entry in ipairs(tabs) do
        if entry[1] == s.ui.tab then
            self.section:SetText(entry[2])
        end
    end
    for id, control in pairs(self.forgeTabs) do
        local active = id == "crafting" and s.ui.tab == "crafting"
            or s.ui.tab == "workshop" and id == (self.professionTab or "enchanting")
        U.Selected(control, active)
        local hint = W.Tutorial.MenuHint(s, id)
        control.text:SetText(
            hint and "|TInterface\\Icons\\INV_Misc_QuestionMark:18|t ???" or control.menuLabel
        )
        if control.menuHint ~= hint then
            U.Tooltip(
                control,
                hint and "???" or control.menuLabel,
                hint or (L.OPEN_PREFIX .. control.menuLabel)
            )
            control.menuHint = hint
        end
    end
    if s.ui.tab == "workshop" then
        self.section:SetText(L.FORGE)
    end
    if s.ui.tab == "offline" then
        self.section:SetText(L.RETURN_REPORT)
    end
    self.sectionDetail:Hide()
    self.sectionHelp:SetShown(
        s.ui.tab == "profiles" or s.ui.tab == "crafting" or s.ui.tab == "workshop"
    )
    self.sectionHelp:ClearAllPoints()
    self.sectionHelp:SetPoint(
        "TOPLEFT",
        self.workspace,
        "TOPLEFT",
        math.min(600, self.section:GetStringWidth() + 12),
        -105
    )
    self.reportLink:SetShown(s.lastOfflineSummary ~= nil)
    self.sectionDetail:SetText(
        s.ui.tab == "adventure" and L.YOUR_COMPANY_S_JOURNEY_THROUGH_AZEROTH
            or s.ui.tab == "party" and L.SELECT_A_COMPANION_TO_MANAGE_EQUIPMENT_AND_GROWTH
            or s.ui.tab == "talents" and L.SHAPE_A_COMPANION_S_TALENTS_AND_COMBAT_PRIORITIES
            or s.ui.tab == "crafting" and L.FORGE_PANEL_DESCRIPTION
            or s.ui.tab == "legacy" and L.PERMANENT_REWARDS_HEIRLOOMS_AND_CHAPTER_RESETS
            or s.ui.tab == "chests" and L.CHESTS_DESCRIPTION
            or s.ui.tab == "loot" and L.CHOOSE_WHAT_TO_KEEP_FROM_FUTURE_DROPS
            or s.ui.tab == "boosts" and L.PERMANENT_ABILITIES_FOR_TEMPORARY_PARTY_SUPPORT
            or s.ui.tab == "profiles" and L.PROFILES_PANEL_DESCRIPTION
            or s.ui.tab == "routes" and L.PLAN_YOUR_NEXT_DESTINATIONS
            or s.ui.tab == "collections" and L.PERMANENT_DISCOVERIES_AND_SET_BONUSES
            or s.ui.tab == "workshop" and L.PROFESSIONS_PANEL_DESCRIPTION
            or s.ui.tab == "difficulty" and L.DEEPER_RESETS_AND_PERMANENT_INHERITANCE
            or s.ui.tab == "offline" and L.YOUR_LATEST_OFFLINE_ADVENTURE
            or s.ui.tab == "development" and L.PERMANENT_ESSENCE_INVESTMENT_FOR_THE_WHOLE_PARTY
            or L.EXPLORE_DESTINATIONS_AND_THEIR_UNLOCK_REQUIREMENTS
    )
    self.scene:Refresh(s)
    local featureState
    if s.ui.tab == "adventure" then
        local d, book = s.development, s.outdoorCollections
        featureState = table.concat({
            s.essence,
            s.adventure.totalXP,
            s.stats.essence or 0,
            book.stats.kills,
            book.stats.discoveries,
            d.ranks.might,
            d.ranks.resolve,
            d.ranks.provisioning,
            d.choices.might or "",
            d.choices.resolve or "",
            d.choices.provisioning or "",
            s.dungeonCollections.stats.kills,
            s.dungeonCollections.stats.discoveries,
            tostring(s.lastOfflineSummary),
            tostring(s.farming),
            s.lastDefeat or "",
        }, ":")
    elseif s.ui.tab == "development" then
        local d = s.development
        featureState = table.concat({
            s.essence,
            d.invested,
            d.ranks.might,
            d.ranks.resolve,
            d.ranks.provisioning,
            d.choices.might or "",
            d.choices.resolve or "",
            d.choices.provisioning or "",
        }, ":")
    elseif s.ui.tab == "collections" then
        local progress =
            W.Game.CollectionProgress(s, self.collectionSelected or C.collections[1].id)
        featureState = progress
            and table.concat({
                progress.found,
                tostring(progress.complete),
                s.outdoorCollections.stats.kills,
                s.outdoorCollections.stats.discoveries,
                s.dungeonCollections.stats.kills,
                s.dungeonCollections.stats.discoveries,
                W.Game.ActiveCollectionEffect(s) or "",
                self.collectionSelected or "",
            }, ":")
    elseif s.ui.tab == "difficulty" then
        local d = s.difficulty
        featureState = table.concat({
            tostring(d.unlocked),
            tostring(d.cycleComplete),
            d.currency,
            d.maxTier,
            d.ascensions,
            s.tier,
        }, ":")
    elseif s.ui.tab == "workshop" then
        local p = s.professions
        local recipes = 0
        for _ in pairs(p.recipes) do
            recipes = recipes + 1
        end
        featureState = table.concat({
            s.gold,
            s.essence,
            s.materials.ore,
            s.materials.relic,
            p.fragments,
            recipes,
            p.ranks.crafting,
            p.ranks.enchanting,
            p.ranks.titanforging,
            p.bestLevel,
        }, ":")
    end
    local heroLevel = s.heroes[self.selected] and s.heroes[self.selected].level
    if
        not s.ui.compact
        and (
            redraw ~= false
            or self.panelFeature ~= featureState
            or self.panelGuidance ~= guidance
            or self.panelLevel ~= heroLevel
            or self.panelItems ~= #s.inventory
            or self.panelBattle ~= (s.battle ~= nil)
            or (
                (s.ui.tab == "party" or s.ui.tab == "crafting")
                and (self.panelGold ~= s.gold or self.panelEssence ~= s.essence)
            )
        )
    then
        W.Panels.Draw(self)
        self.panelGuidance = guidance
        self.panelLevel = heroLevel
        self.panelItems = #s.inventory
        self.panelBattle = s.battle ~= nil
        self.panelGold, self.panelEssence = s.gold, s.essence
        self.panelFeature = featureState
    end
    local message = self.message and GetTime() < (self.messageUntil or 0) and self.message or nil
    self.footer:SetText(message or (W.catchup and L.RESOLVING_OFFLINE_PROGRESS or ""))
    self.footer:SetShown(message ~= nil or W.catchup ~= nil)
    W.Panels.RefreshBoosts(self, s, message)
    if self.routeStatus and s.ui.tab == "routes" and not W.catchup then
        local _, reason = W.Game.RouteStatus(s)
        self.routeStatus:SetText(reason)
    end
    W.Tutorial.Refresh(self)
    self.compactHint:SetText(message or self.compactHint:GetText())
end

function W.CreateUI()
    if W.UI then
        return
    end
    local ui = setmetatable({ selected = 1, tabs = {}, cards = {} }, UI)
    W.UI = ui
    local f = CreateFrame("Frame", "AFKraftWindow", UIParent)
    ui.frame = f
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    -- Keep the interactive window above HIGH overlays and bring it forward
    -- among other dialogs whenever it opens.
    f:SetScript("OnShow", function(self)
        self:Raise()
        if ui.panel then
            ui:Refresh()
        end
    end)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:EnableMouse(true)
    local content = U.BorderContent(f, 6)
    local backdrop = content:CreateTexture(nil, "BACKGROUND")
    backdrop:SetAllPoints(f)
    backdrop:SetColorTexture(unpack(T.bg))
    U.FrameTreatment(f)
    ui.fullscreen = W.state.ui.fullscreen ~= false
    local canvas = CreateFrame("Frame", nil, content)
    ui.canvas = canvas
    canvas:SetPoint("CENTER", f, "CENTER")
    local expanded = CreateFrame("Frame", nil, canvas)
    expanded:SetAllPoints()
    ui.expanded = expanded
    U.Rect(expanded, 2, 2, 1596, 90, T.header)
    U.Icon(expanded, "INV_Misc_Map_01", 28, 27, 44)
    U.Text(expanded, "AFKcraft", 91, 23, 30, T.gold)
    ui.adventureBar = W.AdventureBar.Create(expanded, 92, 61, 490)
    ui.currencies = {}
    for i, currency in ipairs({
        { "essence", L.ESSENCE_HEADING },
        { "gold", L.GOLD_HEADING },
        { "legacy", L.HERITAGE_HEADING },
    }) do
        local x = 810 + (i - 1) * 198
        U.Text(expanded, currency[2], x + 12, 23, 12, T.muted, 160)
        ui.currencies[currency[1]] = U.Text(expanded, "0", x + 12, 38, 19, T.gold, 160)
        local help = CreateFrame("Frame", nil, expanded)
        help:SetPoint("TOPLEFT", x, -18)
        help:SetSize(185, 50)
        help:EnableMouse(true)
        local descriptions = {
            essence = L.EARN_PREFIX
                .. C.adventure.essencePerRank
                .. L.FRAGMENT_ESSENCE_PER
                .. C.adventure.xpPerRank
                .. L.ADVENTURE_XP_FROM_REAL_WOW_ACTIVITIES_SPEND_IT_IN_SUFFIX,
            gold = L.GOLD_DESCRIPTION,
            legacy = L.HERITAGE_DESCRIPTION,
        }
        U.Tooltip(help, currency[2], descriptions[currency[1]])
    end
    ui.materials = U.Text(expanded, "", 810, 72, 12, T.muted, 610)
    local minimize = U.Button(expanded, "-", 1440, 28, 38, 32, function()
        ui:SaveGeometry()
        W.state.ui.compact = true
        ui:ApplyMode()
    end)
    local resize = U.Button(expanded, "+", 1485, 28, 38, 32, function()
        ui:SaveGeometry()
        ui.fullscreen = not ui.fullscreen
        W.state.ui.fullscreen = ui.fullscreen
        ui:ApplyMode()
    end)
    local close = U.Button(expanded, "x", 1530, 28, 38, 32, function()
        ui:SaveGeometry()
        f:Hide()
    end)
    for _, control in ipairs({ minimize, resize, close }) do
        control.text:SetJustifyH("CENTER")
    end
    U.Tooltip(
        minimize,
        L.COMPACT_WINDOW,
        L.KEEP_A_SMALL_INTERACTIVE_ADVENTURE_SCENE_BESIDE_YOUR_GAME
    )
    U.Tooltip(resize, L.WINDOW_SIZE, L.SWITCH_BETWEEN_FULLSCREEN_AND_A_RESIZABLE_WINDOW)
    U.Tooltip(close, L.CLOSE, L.YOUR_COMPANY_CONTINUES_ADVENTURING_WHEN_THIS_WINDOW_IS_CLOSED)
    local workspace = CreateFrame("Frame", nil, expanded)
    workspace:SetPoint("TOPLEFT", 276, 0)
    workspace:SetSize(1296, 900)
    ui.workspace = workspace
    ui.section = U.SingleLine(U.Text(workspace, L.ADVENTURE, 0, 105, 24, T.gold), 600, 30)
    ui.sectionDetail = U.SingleLine(U.Text(workspace, "", 0, 137, 14, T.muted), 780, 20)
    ui.sectionHelp = U.Help(workspace, L.ABOUT_THIS_PANEL, 624, 105, function()
        return ui.sectionDetail:GetText()
    end)
    ui.battleState = U.SingleLine(U.Text(workspace, "", 790, 113, 14, T.muted), 220, 22, "RIGHT")
    local y = 118
    for _, entry in ipairs(tabs) do
        local id = entry[1]
        if entry[3] then
            U.Text(expanded, entry[3], 32, y, 12, T.muted, 204)
            y = y + 26
        end
        local tab = U.SelectButton(expanded, "", 24, y, 220, 38, function()
            if not W.Tutorial.MenuHint(W.state, id) then
                ui:SetTab(id)
            end
        end)
        tab.text:ClearAllPoints()
        tab.text:SetPoint("TOPLEFT", 42, -2)
        tab.text:SetFont(W.font, 14, "")
        U.SingleLine(tab.text, 172, 26)
        tab.text:SetText(entry[2])
        tab.menuLabel = entry[2]
        tab.icon = U.Icon(tab.content or tab, tabIcons[id], 12, 10, 20)
        tab.notice = U.SingleLine(U.Text(tab, "", 42, 25, 10, T.gold), 170, 12)
        U.Tooltip(tab, entry[2], L.OPEN_PREFIX .. entry[2])
        ui.tabs[id] = tab
        y = y + 40
    end
    ui.forgeContainer = CreateFrame("Frame", nil, workspace)
    ui.forgeContainer:SetPoint("TOPLEFT", -12, -185)
    ui.forgeContainer:SetSize(1320, 674)
    local forgeBorder = U.FrameTreatment(ui.forgeContainer)
    ui.forgeTabs = {}
    for index, entry in ipairs({
        { "crafting", L.CRAFT_EQUIPMENT },
        { "enchanting", L.ENCHANT },
        { "titanforging", L.TITANFORGE },
        { "research", L.SPECIALIZATIONS },
    }) do
        local id = entry[1]
        ui.forgeTabs[id] = U.Tab(
            ui.forgeContainer,
            entry[2],
            12 + (index - 1) * 244,
            -30,
            228,
            34,
            function()
                if W.Tutorial.MenuHint(W.state, id) then
                    return
                end
                if id == "crafting" then
                    ui.selected = ui.professionHero or ui.selected
                    ui:SetTab("crafting")
                else
                    if W.state.ui.tab == "crafting" then
                        ui.professionHero = ui.selected
                    end
                    ui.professionTab = id
                    ui:SetTab("workshop")
                end
            end
        )
        ui.forgeTabs[id].menuLabel = entry[2]
        ui.forgeTabs[id]:SetFrameLevel(forgeBorder:GetFrameLevel() - 1)
    end
    ui.settingsLink = U.Button(expanded, L.SETTINGS, 24, 850, 220, 34, function()
        LibStub("AceConfigDialog-3.0"):Open("AFKraft")
    end)
    ui.reportLink = U.Button(expanded, L.RETURN_REPORT, 24, 808, 220, 34, function()
        ui:SetTab("offline")
    end)
    ui.destination = U.Button(workspace, L.WORLD_MAP, 1028, 105, 148, 34, function()
        ui:SetTab(W.state.ui.tab == "atlas" and "adventure" or "atlas")
    end, false, "primary")
    ui.retry = U.Button(workspace, L.RETRY_FRONTIER, 1188, 105, 108, 34, function()
        W.Action(W.Game.Retry)
        ui:Refresh()
    end)
    ui.retry.text:SetText(L.RETRY)
    ui.retry.text:SetJustifyH("CENTER")
    U.Tooltip(ui.retry, L.RETRY_FRONTIER, L.LEAVE_SAFE_FARMING_AND_TRY_THE_NEXT_UNBEATEN_ENCOUNTER)
    for i = 1, 5 do
        local index = i
        local card = U.SelectButton(workspace, "", 0, 0, 249.6, 72, function()
            ui:SelectHero(index)
        end)
        card.text:Hide()
        card.icon = U.Icon(card.content or card, "INV_Misc_QuestionMark", 12, 12, 40)
        card.label = U.Text(card, "", 64, 10, 16, T.text, 173)
        U.SingleLine(card.label, 173, 24)
        card.detail = U.Text(card, "", 64, 38, 11, T.muted, 173)
        U.SingleLine(card.detail, 173, 18)
        card.xp = U.Bar(card, 64, 58, 173, 6, T.gold)
        ui.cards[i] = card
    end
    ui.panel = CreateFrame("Frame", nil, workspace)
    ui.panel:SetSize(1296, 240)
    ui.footer = U.SingleLine(U.Text(workspace, "", 0, 873, 14, T.text), 1296, 22)
    local compact = CreateFrame("Frame", nil, canvas)
    compact:SetAllPoints()
    ui.compact = compact
    U.Text(compact, "AFKcraft", 14, 17, 21, T.gold)
    ui.compactInfo = U.Text(compact, "", 200, 21, 12, T.gold, 330)
    ui.compactZone = U.Text(compact, "", 12, 50, 13, T.text, 550)
    U.SingleLine(ui.compactZone, 550, 20)
    ui.compactMap = U.Button(compact, L.WORLD_MAP, 12, 235, 98, 32, function()
        ui:SetTab("atlas")
    end)
    ui.compactExpand = U.Button(compact, L.EXPAND, 122, 235, 125, 32, function()
        ui:SaveGeometry()
        W.state.ui.compact = false
        ui:ApplyMode()
    end)
    ui.compactRetry = U.Button(compact, L.RETRY, 259, 235, 98, 32, function()
        W.Action(W.Game.Retry)
        ui:Refresh()
    end)
    ui.lock = U.Button(compact, L.LOCK, 470, 235, 98, 32, function()
        W.state.ui.locked = not W.state.ui.locked
        ui:Layout()
        ui:Refresh()
    end)
    ui.compactHint = U.Text(compact, "", 12, 282, 12, T.muted, 550)
    ui.compactHint:SetHeight(24)
    ui.compactHint:Hide()
    ui.compactBoost = U.Button(compact, L.COMMANDER_BOOSTS, 12, 273, 550, 26, function()
        if W.Tutorial.MenuHint(W.state, "boosts") then
            return
        end
        local id = W.state.boosts.equipped
        if id then
            W.Action(W.Game.ActivateBoost, id)
        else
            ui:SetTab("boosts")
        end
    end)
    ui.compactBoost.icon = U.Icon(ui.compactBoost, "INV_Misc_Book_09", 10, 4, 18)
    ui.compactBoost.icon:SetParent(ui.compactBoost.content or ui.compactBoost)
    ui.compactBoost.text:ClearAllPoints()
    ui.compactBoost.text:SetPoint("LEFT", 38, 0)
    U.SingleLine(ui.compactBoost.text, 500, 18)
    ui.adventureCompact = W.AdventureBar.Create(compact, 12, 305, 550)
    U.Text(compact, L.OFFLINE_EARNINGS_UP_TO_24_HOURS, 12, 337, 11, T.muted)
    ui.scene = W.Scene.Create(canvas)
    local drag = CreateFrame("Frame", nil, f)
    ui.drag = drag
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("TOPRIGHT")
    drag:SetHeight(18)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        if (W.state.ui.compact or not ui.fullscreen) and not W.state.ui.locked then
            f:StartMoving()
        end
    end)
    drag:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        ui:SaveGeometry()
    end)
    ui.grip = CreateFrame("Button", nil, f)
    ui.grip:SetPoint("BOTTOMRIGHT")
    ui.grip:SetSize(20, 20)
    U.Text(ui.grip, "//", 0, 0, 16, T.gold)
    ui.grip:SetScript("OnMouseDown", function()
        if not W.state.ui.locked then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    ui.grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        ui:SaveGeometry()
    end)
    f:SetScript("OnSizeChanged", function()
        if f:GetWidth() > 0 and f:GetHeight() > 0 then
            ui:Layout()
        end
    end)
    f:SetScript("OnHide", function()
        W.Tutorial.Hide(ui)
        ui:SaveGeometry()
        ui.confirmPrestige = false
        if ui.map then
            ui.map:Hide()
        end
    end)
    UISpecialFrames[#UISpecialFrames + 1] = "AFKraftWindow"
    ui:ApplyMode()
    f:Hide()
end
