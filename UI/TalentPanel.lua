local _, W = ...
local L = W.L
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local P = {}
W.TalentPanel = P

local function createTree(parent, path)
    local tree = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tree:SetPoint("TOPLEFT", (path - 1) * 440, 0)
    tree:SetSize(416, 444)
    tree:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    tree:SetBackdropColor(0.035, 0.025, 0.018, 0.96)
    tree.title = U.Text(tree, "", 18, 15, 16, T.gold, 280)
    tree.count = U.SingleLine(U.Text(tree, "", 302, 15, 13, T.gold), 94, 22, "RIGHT")
    tree.scroll = CreateFrame("ScrollFrame", nil, tree)
    tree.scroll:SetPoint("TOPLEFT", 12, -48)
    tree.scroll:SetSize(366, 382)
    tree.scroll:SetClipsChildren(true)
    tree.canvas = CreateFrame("Frame", nil, tree.scroll)
    tree.canvas:SetSize(366, 382)
    tree.scroll:SetScrollChild(tree.canvas)
    tree.scrollBar = CreateFrame("EventFrame", nil, tree, "MinimalScrollBar")
    tree.scrollBar:SetPoint("TOPRIGHT", -22, -48)
    tree.scrollBar:SetPoint("BOTTOMRIGHT", -22, 14)
    tree.scrollBar:RegisterCallback("OnScroll", function(_, percentage)
        local maximum = math.max(0, tree.canvas:GetHeight() - tree.scroll:GetHeight())
        local offset = percentage * maximum
        if math.abs(tree.scroll:GetVerticalScroll() - offset) > 0.01 then
            GameTooltip:Hide()
        end
        tree.scroll:SetVerticalScroll(offset)
    end, tree)
    tree.scroll:EnableMouseWheel(true)
    tree.scroll:SetScript("OnMouseWheel", function(_, delta)
        local maximum = math.max(0, tree.canvas:GetHeight() - tree.scroll:GetHeight())
        if maximum > 0 then
            local offset = tree.scroll:GetVerticalScroll() - delta * 48
            tree.scrollBar:SetScrollPercentage(math.max(0, math.min(1, offset / maximum)))
        end
        GameTooltip:Hide()
    end)
    tree.buttons = {}
    return tree
end

local function drawNode(tree, talent, hero, index)
    local b = tree.buttons[talent.id]
    if not b then
        b = CreateFrame("Button", nil, tree.canvas, "BackdropTemplate")
        b:SetSize(44, 44)
        b:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        b.icon = U.Icon(b, talent.icon, 5, 5, 34)
        b.iconName = talent.icon
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        U.Rect(b, 22, 34, 28, 16, { 0, 0, 0 }, 0.95, "OVERLAY")
        b.rank = U.SingleLine(U.Text(b, "", 19, 33, 12, T.green), 32, 18, "CENTER")
        b.rank:SetDrawLayer("OVERLAY", 7)
        b.label = U.SingleLine(U.Text(b, "", -48, 51, 11, T.text), 140, 18, "CENTER")
        b:SetScript("OnHide", function(self)
            if GameTooltip:IsOwned(self) then
                GameTooltip:Hide()
            end
        end)
        tree.buttons[talent.id] = b
    end
    if b.iconName ~= talent.icon then
        b.icon:SetTexture("Interface\\Icons\\" .. talent.icon)
        b.iconName = talent.icon
    end
    local learned = hero.talents[talent.id]
    local available, reason = G.CanTalent(hero, talent)
    local color = learned and T.gold or available and T.green or T.muted
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", 64 + (talent.column - 2) * 158, -16 - (talent.row - 1) * 82)
    b:SetBackdropBorderColor(unpack(color))
    b.icon:SetDesaturated(not learned and not available)
    b.icon:SetAlpha((learned or available) and 1 or 0.45)
    b.label:SetText(talent.name)
    b.rank:SetText(learned and "1/1" or "0/1")
    b.rank:SetTextColor(unpack(color))
    b:SetScript("OnClick", function()
        GameTooltip:Hide()
        W.Action(G.Talent, index, talent.id)
    end)
    -- Leave unlearnable nodes mouse-enabled so their explanations remain accessible.
    b:SetScript("OnEnter", nil)
    b:SetScript("OnLeave", nil)
    U.Tooltip(
        b,
        talent.name,
        L.RANK_PREFIX
            .. (learned and "1/1" or "0/1")
            .. "\n\n"
            .. talent.text
            .. "\n\n"
            .. (
                not available and reason
                or learned and L.CLICK_TO_UNLEARN_AND_RECOVER_THE_POINT
                or available and L.CLICK_TO_SPEND_ONE_TALENT_POINT
                or L.REACH_NEW_LEVEL_MILESTONES_TO_EARN_PERMANENT_TALENT_POINTS
            ),
        320
    )
    b:Show()
end

function P.Draw(ui, parent, hero, index)
    if not ui.talentTrees then
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetPoint("TOPLEFT", 0, -43)
        frame:SetSize(1296, 444)
        frame.mastery = U.Bar(frame, 760, -39, 536, 18, { 0.35, 0.55, 0.85 })
        frame.mastery.label = frame.mastery:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.mastery.label:SetPoint("CENTER")
        frame.mastery.label:SetWidth(520)
        frame.mastery:EnableMouse(true)
        frame.trees = {}
        for path = 1, 3 do
            frame.trees[path] = createTree(frame, path)
        end
        ui.talentTrees = frame
    end
    local talents = G.TalentList(hero)
    local mastery = G.MasteryProgress(hero)
    local progress = G.TalentProgress(hero)
    local bar = ui.talentTrees.mastery
    local unlocked = G.MasteryUnlocked(hero)
    local cost = G.MasteryCost(mastery.rank)
    local complete = progress.earned >= #talents
    bar:SetValue(complete and 1 or unlocked and mastery.xp / cost or 0)
    bar.label:SetText(
        not unlocked and (L.MASTERY_UNLOCKS_AT_HERO_LEVEL_PREFIX .. C.mastery.unlockLevel)
            or complete and (L.MASTERY_PREFIX .. mastery.rank .. L.ALL_TALENT_POINTS_EARNED_SUFFIX)
            or (
                L.MASTERY_PREFIX
                .. mastery.rank
                .. " · "
                .. mastery.xp
                .. " / "
                .. cost
                .. L.XP_HEADING_2
            )
    )
    U.Tooltip(
        bar,
        L.PERMANENT_MASTERY,
        L.UNLOCKS_AT_HERO_LEVEL_PREFIX
            .. C.mastery.unlockLevel
            .. L.EACH_RANK_GRANTS_1_PERMANENT_TALENT_POINT_TIER_PREFIX
            .. W.state.tier
            .. L.EARN_XP_FROM_VICTORIES_AT_ENCOUNTER_LEVEL_PREFIX
            .. math.max(1, G.MasteryFrontier(hero, W.state.tier))
            .. L.BOSSES_AWARD_DOUBLE_XP_MASTERY_SURVIVES_BOTH_RESETS_AND_PREFIX
            .. C.heroLevelCap
            .. ".\n"
            .. (
                complete and L.ALL_TALENT_POINTS_EARNED
                or (L.NEXT_RANK_PREFIX .. cost .. L.XP_HEADING_3)
            ),
        360
    )
    ui.talentTrees:Show()
    for path, tree in ipairs(ui.talentTrees.trees) do
        local spent, count, rows = 0, 0, 1
        for _, b in pairs(tree.buttons) do
            b:Hide()
        end
        for _, talent in ipairs(talents) do
            if talent.path == path then
                count = count + 1
                spent = spent + (hero.talents[talent.id] and 1 or 0)
                rows = math.max(rows, talent.row)
                drawNode(tree, talent, hero, index)
            end
        end
        tree.title:SetText(C.classByID[hero.class].paths[path])
        tree.count:SetText(spent .. " / " .. count)
        local height = math.max(382, 32 + rows * 82)
        tree.canvas:SetHeight(height)
        local maximum = math.max(0, height - tree.scroll:GetHeight())
        local offset = math.min(tree.scroll:GetVerticalScroll(), maximum)
        tree.scrollBar:SetVisibleExtentPercentage(tree.scroll:GetHeight() / height)
        tree.scrollBar:SetPanExtentPercentage(maximum > 0 and 24 / maximum or 0)
        tree.scrollBar:SetScrollPercentage(maximum > 0 and offset / maximum or 0)
        tree.scrollBar:SetShown(maximum > 0)
    end
end
