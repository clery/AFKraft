local _, W = ...
local U, T, C = W.Widgets, W.Theme, W.Content
local UI = {}
UI.__index = UI
local tabs = {
    { "adventure", "Adventure" },
    { "party", "Party" },
    { "talents", "Talents" },
    { "crafting", "Crafting" },
    { "atlas", "World map" },
    { "legacy", "Legacy" },
    { "loot", "Loot rules" },
}
local tabIcons = {
    adventure = "INV_Misc_Map_01",
    party = "Achievement_GuildPerk_EverybodysFriend",
    talents = "Ability_Marksmanship",
    crafting = "Trade_BlackSmithing",
    atlas = "INV_Misc_Map02",
    legacy = "INV_Misc_Book_09",
    loot = "INV_Misc_Bag_10",
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
    local minW, minH = math.min(1152, screenW), math.min(720, screenH)
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
                w = math.min(1152, screenW),
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
    local width, height = compact and 580 or 1440, compact and 370 or 900
    local scale = math.min(self.frame:GetWidth() / width, self.frame:GetHeight() / height)
    self.canvas:SetScale(scale)
    self.canvas:SetSize(width, height)
    local management = not compact and (W.state.ui.tab or "adventure") ~= "adventure"
    local atlas = not compact and W.state.ui.tab == "atlas"
    local company = not compact and (W.state.ui.tab == "legacy" or W.state.ui.tab == "loot")
    self.scene:Layout(compact, management)
    self.scene.frame:SetShown(not atlas and not company)
    for i, card in ipairs(self.cards) do
        card:SetShown(not atlas and not company)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 28 + (i - 1) * 261.6, management and -320 or -528)
    end
    self.panel:ClearAllPoints()
    self.panel:SetPoint("TOPLEFT", 28, (atlas or company) and -155 or management and -422 or -620)
    self.panel:SetSize(1296, (atlas or company) and 695 or management and 430 or 240)
    self.expanded:SetShown(not compact)
    self.compact:SetShown(compact)
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
        U.Button(map, "Close map", 780, 20, 150, 32, function()
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
        map.note:SetText(
            "Your party travels independently of your WoW character. Choose destinations in the Atlas."
        )
    else
        map.note:SetText(
            "Map artwork is unavailable here. Destinations remain available in the Atlas."
        )
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
    self.destination.text:SetText(s.ui.tab == "atlas" and "Adventure" or "World map")
    local resourceText = ""
    for _, id in ipairs(C.materialOrder) do
        resourceText = resourceText .. C.materials[id] .. " " .. U.Number(s.materials[id]) .. "    "
    end
    self.materials:SetText(resourceText)
    self.compactInfo:SetText(
        U.Number(s.essence) .. " Essence   /   " .. U.Number(s.gold) .. " Gold"
    )
    self.compactZone:SetText(C.zoneByID[s.zone].name .. "  /  Encounter " .. s.stage)
    self.battleState:SetText(
        (
            s.farming and "Farming"
            or not s.battle and (s.rest or 0) > 0 and "Recovering"
            or "Advancing"
        )
            .. " · Encounter "
            .. s.stage
    )
    U.Enabled(self.retry, s.farming == true)
    self.lock.text:SetText(s.ui.locked and "Unlock" or "Lock")
    self.compactMap:SetShown(not s.ui.locked)
    self.compactExpand:SetShown(not s.ui.locked)
    self.compactRetry:SetShown(not s.ui.locked)
    U.Enabled(self.compactRetry, s.farming == true)
    self.compactHint:SetText(
        s.ui.locked and "Window locked · adventure continues"
            or "Select a hero to manage their build at any time."
    )
    for i, button in ipairs(self.cards) do
        local h = s.heroes[i]
        if h then
            local class = C.classByID[h.class]
            button.label:SetText(h.name)
            button.label:SetTextColor(unpack(i == self.selected and T.gold or class.color))
            local cap = W.Game.LevelCap(h)
            button.detail:SetText(
                "Lv "
                    .. h.level
                    .. " / "
                    .. cap
                    .. "  ·  "
                    .. (
                        h.level >= C.heroLevelCap
                            and ("Mastery " .. W.Game.MasteryProgress(h).rank)
                        or h.level >= cap and "Train to grow"
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
                button.xp:SetMinMaxValues(0, h.level * 45)
                button.xp:SetValue(h.xp)
            end
            button.icon:SetTexture("Interface\\Icons\\" .. class.icon)
            button.xp:Show()
        else
            local available = i <= W.Game.CompanionSlots(s)
            button.label:SetText(
                available and "Companion found!" or "Companion " .. i .. " · Locked"
            )
            button.label:SetTextColor(unpack(available and T.gold or T.muted))
            button.detail:SetText(
                available and "Choose a class in Party"
                    or "Milestone boss level " .. C.companionMilestones[i]
            )
            button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            button.xp:Hide()
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(unpack(i == self.selected and T.gold or T.line))
        end
    end
    local points, _, cappedHero, routes = W.Panels.Opportunities(s)
    self.tabs.talents.notice:SetText(
        points > 0 and (points .. (points == 1 and " point" or " points")) or ""
    )
    self.tabs.party.notice:SetText(
        #s.heroes < W.Game.CompanionSlots(s) and "Recruit" or cappedHero and "Train" or ""
    )
    self.tabs.atlas.notice:SetText(routes > 0 and (routes .. " routes") or "")
    self.tabs.legacy.notice:SetText(
        s.prestigeUnlocked and ("+" .. W.Game.PrestigeReward(s) .. " Legacy") or ""
    )
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
    }, ":")
    for id, button in pairs(self.tabs) do
        button.text:SetTextColor(unpack(s.ui.tab == id and T.gold or T.muted))
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(unpack(s.ui.tab == id and T.gold or T.line))
        end
    end
    for _, entry in ipairs(tabs) do
        if entry[1] == s.ui.tab then
            self.section:SetText(entry[2])
        end
    end
    self.sectionDetail:SetText(
        s.ui.tab == "adventure" and "Your company’s journey through Azeroth"
            or s.ui.tab == "party" and "Select a companion to manage equipment and training"
            or s.ui.tab == "talents" and "Shape a companion’s talents and combat priorities"
            or s.ui.tab == "crafting" and "Create ordinary equipment or lasting heirlooms"
            or s.ui.tab == "legacy" and "Permanent rewards, heirlooms and chapter resets"
            or s.ui.tab == "loot" and "Choose what to keep from future drops"
            or "Explore destinations and their unlock requirements"
    )
    self.scene:Refresh(s)
    local heroLevel = s.heroes[self.selected] and s.heroes[self.selected].level
    if
        not s.ui.compact
        and (
            redraw ~= false
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
    end
    local message = self.message and GetTime() < (self.messageUntil or 0) and self.message or nil
    self.footer:SetText(message or (W.catchup and "Resolving offline progress…" or ""))
    self.footer:SetShown(message ~= nil or W.catchup ~= nil)
    W.Tutorial.Refresh(self)
    self.compactHint:SetText(message or self.compactHint:GetText())
end

function W.CreateUI()
    if W.UI then
        return
    end
    local ui = setmetatable({ selected = 1, tabs = {}, cards = {} }, UI)
    W.UI = ui
    local f = CreateFrame("Frame", "WoWIdleWindow", UIParent)
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
    U.Rect(expanded, 2, 2, 1436, 90, { 0.085, 0.067, 0.044 })
    U.Icon(expanded, "INV_Misc_Map_01", 28, 27, 44)
    U.Text(expanded, "WoWIdle", 91, 23, 30, T.gold)
    ui.adventureBar = W.AdventureBar.Create(expanded, 92, 61, 490)
    ui.currencies = {}
    for i, currency in ipairs({
        { "essence", "ESSENCE" },
        { "gold", "GOLD" },
        { "legacy", "LEGACY" },
    }) do
        local x = 650 + (i - 1) * 198
        U.Text(expanded, currency[2], x + 12, 23, 10, T.muted, 160)
        ui.currencies[currency[1]] = U.Text(expanded, "0", x + 12, 38, 19, T.gold, 160)
        local help = CreateFrame("Frame", nil, expanded)
        help:SetPoint("TOPLEFT", x, -18)
        help:SetSize(185, 50)
        help:EnableMouse(true)
        local descriptions = {
            essence = "Earn Essence from Adventure XP ranks by playing your WoW character. Spend it on training, crafting and upgrades. Hero XP comes from idle battles instead.",
            gold = "Your heroes earn gold from idle battles. Spend it on training, crafting and equipment upgrades. This is separate from your WoW character’s gold.",
            legacy = "Earn Legacy by beginning a new chapter after unlocking resets. Spend it on permanent heirloom recipes. Review reset consequences in Legacy.",
        }
        U.Tooltip(help, currency[2], descriptions[currency[1]])
    end
    ui.materials = U.Text(expanded, "", 650, 72, 11, T.muted, 610)
    local minimize = U.Button(expanded, "-", 1280, 28, 38, 32, function()
        ui:SaveGeometry()
        W.state.ui.compact = true
        ui:ApplyMode()
    end)
    local resize = U.Button(expanded, "+", 1325, 28, 38, 32, function()
        ui:SaveGeometry()
        ui.fullscreen = not ui.fullscreen
        W.state.ui.fullscreen = ui.fullscreen
        ui:ApplyMode()
    end)
    local close = U.Button(expanded, "x", 1370, 28, 38, 32, function()
        ui:SaveGeometry()
        f:Hide()
    end)
    for _, control in ipairs({ minimize, resize, close }) do
        control.text:SetJustifyH("CENTER")
    end
    U.Tooltip(
        minimize,
        "Compact window",
        "Keep a small, interactive adventure scene beside your game."
    )
    U.Tooltip(resize, "Window size", "Switch between fullscreen and a resizable window.")
    U.Tooltip(
        close,
        "Close",
        "Your company continues adventuring when this window is closed. Open it again with /wowidle."
    )
    U.Rect(expanded, 28, 94, 1384, 1, T.line)
    ui.section = U.Text(expanded, "Adventure", 28, 111, 22, T.gold)
    ui.sectionDetail = U.Text(expanded, "", 220, 116, 12, T.muted, 620)
    ui.battleState = U.Text(expanded, "", 860, 116, 12, T.muted, 185)
    U.SingleLine(ui.battleState, 185, 18, "RIGHT")
    for i, entry in ipairs(tabs) do
        local id = entry[1]
        local tab = U.Button(expanded, "", 1340, 151 + (i - 1) * 79, 78, 69, function()
            ui:SetTab(id)
        end)
        tab.text:ClearAllPoints()
        tab.text:SetPoint("BOTTOM", 0, 5)
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        U.SingleLine(tab.text, 74, 16, "CENTER")
        tab.text:SetText(entry[2])
        U.Icon(tab, tabIcons[id], 27, 23, 24)
        U.Tooltip(tab, entry[2], "Open " .. entry[2])
        tab.notice = U.SingleLine(U.Text(tab, "", 2, 4, 10, T.gold), 74, 16, "CENTER")
        ui.tabs[id] = tab
    end
    ui.destination = U.Button(expanded, "World map", 1068, 105, 148, 34, function()
        ui:SetTab(W.state.ui.tab == "atlas" and "adventure" or "atlas")
    end, false, "primary")
    ui.retry = U.Button(expanded, "Retry frontier", 1228, 105, 96, 34, function()
        W.Action(W.Game.Retry)
        ui:Refresh()
    end)
    ui.retry.text:SetText("Retry")
    ui.retry.text:SetJustifyH("CENTER")
    U.Tooltip(
        ui.retry,
        "Retry frontier",
        "Leave safe farming and try the next unbeaten encounter again."
    )
    for i = 1, 5 do
        local index = i
        local card = U.Button(expanded, "", 0, 0, 249.6, 72, function()
            ui:SelectHero(index)
        end)
        card.text:Hide()
        card.icon = U.Icon(card, "INV_Misc_QuestionMark", 12, 12, 40)
        card.label = U.Text(card, "", 64, 10, 16, T.text, 173)
        U.SingleLine(card.label, 173, 24)
        card.detail = U.Text(card, "", 64, 38, 11, T.muted, 173)
        U.SingleLine(card.detail, 173, 18)
        card.xp = U.Bar(card, 64, 58, 173, 6, T.gold)
        ui.cards[i] = card
    end
    ui.panel = CreateFrame("Frame", nil, expanded)
    ui.panel:SetSize(1296, 240)
    ui.footer = U.Text(expanded, "", 28, 873, 11, T.muted, 1384)
    local compact = CreateFrame("Frame", nil, canvas)
    compact:SetAllPoints()
    ui.compact = compact
    U.Text(compact, "WoWIdle", 14, 17, 21, T.gold)
    ui.compactInfo = U.Text(compact, "", 200, 21, 12, T.gold, 330)
    ui.compactZone = U.Text(compact, "", 12, 50, 13, T.text, 550)
    U.SingleLine(ui.compactZone, 550, 20)
    ui.compactMap = U.Button(compact, "World map", 12, 235, 98, 32, function()
        ui:SetTab("atlas")
    end)
    ui.compactExpand = U.Button(compact, "Expand", 122, 235, 125, 32, function()
        ui:SaveGeometry()
        W.state.ui.compact = false
        ui:ApplyMode()
    end)
    ui.compactRetry = U.Button(compact, "Retry", 259, 235, 98, 32, function()
        W.Action(W.Game.Retry)
        ui:Refresh()
    end)
    ui.lock = U.Button(compact, "Lock", 470, 235, 98, 32, function()
        W.state.ui.locked = not W.state.ui.locked
        ui:Layout()
        ui:Refresh()
    end)
    ui.compactHint = U.Text(compact, "", 12, 282, 12, T.muted, 550)
    ui.compactHint:SetHeight(24)
    ui.adventureCompact = W.AdventureBar.Create(compact, 12, 305, 550)
    U.Text(compact, "Offline earnings: up to 24 hours", 12, 337, 11, T.muted)
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
    UISpecialFrames[#UISpecialFrames + 1] = "WoWIdleWindow"
    ui:ApplyMode()
    f:Hide()
end
