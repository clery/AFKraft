local _, W = ...
local G, C, L, U, T = W.Game, W.Content, W.L, W.Widgets, W.Theme
local P = {}
W.JournalPanel = P

local goals = {
    heroes = L.JOURNAL_GOAL_HEROES,
    best = L.JOURNAL_GOAL_BEST,
    crafted = L.JOURNAL_GOAL_CRAFT,
    heirloom = L.JOURNAL_GOAL_HEIRLOOM,
    prestiges = L.JOURNAL_GOAL_PRESTIGE,
    quest = L.JOURNAL_QUESTS,
    explore = L.JOURNAL_EXPLORE,
    contracts = L.JOURNAL_CONTRACTS,
    rank = L.JOURNAL_GOAL_RANK,
}

local function line(parent, text, x, y, size, color, width)
    return U.SingleLine(U.Text(parent, text, x, y, size, color, width), width, size + 8)
end

local function progress(parent, x, y, width, value, target)
    U.Rect(parent, x, y, width, 10, T.panel)
    return U.Rect(
        parent,
        x,
        y,
        math.max(0.01, width * math.min(value, target) / target),
        10,
        T.gold,
        1,
        "ARTWORK"
    )
end

local function contract(parent, entry, id, x, y)
    local definition = C.contractByID[id]
    local target = definition[entry.weekly and "weekly" or "daily"]
    local value = entry.progress[id] or 0
    local xp = entry.weekly and C.journal.weeklyXP or C.journal.dailyXP
    U.Rect(parent, x, y, 624, 100, T.panel, 0.8)
    U.Icon(parent, definition.icon, x + 14, y + 14, 36)
    line(parent, definition.name, x + 64, y + 12, 15, value == target and T.green or T.text, 544)
    line(
        parent,
        value .. "/" .. target .. " · +" .. xp .. " " .. L.JOURNAL_XP,
        x + 64,
        y + 40,
        13,
        T.muted,
        544
    )
    progress(parent, x + 14, y + 76, 594, value, target)
end

local rankSpacing = 208

local function circle(parent, size, layer, color)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetSize(size, size)
    texture:SetPoint("TOPLEFT", (192 - size) / 2, -140 + size / 2)
    texture:SetColorTexture(unpack(color))
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(texture)
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    texture:AddMaskTexture(mask)
    return texture
end

local function rewardIcon(rank)
    if rank == 20 then
        return C.journalTitles[4].icon
    end
    if rank % 5 == 0 then
        return "INV_Misc_Book_09"
    end
    if rank % 4 == 0 then
        return "INV_Misc_TreasureChest01a"
    end
    return rank % 2 == 0 and "Trade_BlackSmithing" or "INV_Misc_Coin_01"
end

local function scrollTrack(frame, value, instant)
    value = math.max(0, math.min((C.journal.ranks - 1) * rankSpacing, value))
    if not instant and value == frame.target then
        return
    end
    frame.target = value
    frame.left:SetShown(value > 0)
    frame.right:SetShown(value < (C.journal.ranks - 1) * rankSpacing)
    GameTooltip:Hide()
    frame:SetScript("OnUpdate", nil)
    if instant then
        frame.scroll:SetHorizontalScroll(value)
        frame.direction = nil
        return
    end
    local start, elapsed = frame.scroll:GetHorizontalScroll(), 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = math.min(0.28, elapsed + dt)
        local t = elapsed / 0.28
        self.scroll:SetHorizontalScroll(start + (value - start) * (1 - (1 - t) ^ 3))
        if elapsed >= 0.28 then
            self.scroll:SetHorizontalScroll(value)
            self.direction = nil
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function createTrack(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 0, -160)
    frame:SetSize(1296, 410)
    frame.scroll = CreateFrame("ScrollFrame", nil, frame)
    frame.scroll:SetPoint("TOPLEFT")
    frame.scroll:SetSize(1296, 352)
    frame.scroll:SetClipsChildren(true)
    local maximum = (C.journal.ranks - 1) * rankSpacing
    frame.content = CreateFrame("Frame", nil, frame.scroll)
    -- Trailing space lets the final earned rank align left, too.
    frame.content:SetSize(maximum + 1296, 352)
    frame.scroll:SetScrollChild(frame.content)
    U.Rect(frame.content, 96, 136, maximum, 8, T.line)
    frame.progress = U.Rect(frame.content, 96, 136, 1, 8, T.gold, 1, "ARTWORK")
    local function move(delta)
        if delta == 0 then
            return
        end
        local base = frame.target or frame.scroll:GetHorizontalScroll()
        if frame.direction and frame.direction * delta < 0 then
            base = frame.scroll:GetHorizontalScroll()
        end
        frame.direction = delta
        scrollTrack(frame, base + delta)
    end
    frame.left, frame.right = U.ScrollEdges(frame, 352)
    U.SingleLine(U.Text(frame, L.SCROLL_HORIZONTAL_HINT, 0, 372, 12, T.muted), 1296, 26, "CENTER")
    local function wheel(_, delta)
        move(-delta * rankSpacing)
    end
    frame.scroll:EnableMouseWheel(true)
    frame.scroll:SetScript("OnMouseWheel", wheel)
    frame.nodes = {}
    for rank = 1, C.journal.ranks do
        local node = CreateFrame("Frame", nil, frame.content)
        node:SetPoint("TOPLEFT", (rank - 1) * rankSpacing, 0)
        node:SetSize(192, 336)
        node:EnableMouse(true)
        node:EnableMouseWheel(true)
        node:SetScript("OnMouseWheel", wheel)
        circle(node, 108, "BACKGROUND", T.bg)
        node.rim = circle(node, 100, "BORDER", { 1, 1, 1 })
        circle(node, 90, "ARTWORK", T.bg)
        node.icon = circle(node, 82, "OVERLAY", { 1, 1, 1 })
        node.icon:SetTexture("Interface\\Icons\\" .. rewardIcon(rank))
        node.rank =
            U.SingleLine(U.Text(node, L.RANK_PREFIX .. rank, 0, 40, 18, T.gold), 192, 30, "CENTER")
        node.reward = U.Text(node, "", 0, 208, 14, T.text, 192)
        node.reward:SetHeight(64)
        node.reward:SetJustifyH("CENTER")
        node.status = U.SingleLine(U.Text(node, "", 0, 292, 12, T.muted), 192, 26, "CENTER")
        frame.nodes[rank] = node
    end
    frame:SetScript("OnHide", function()
        frame.focusState, frame.target, frame.direction = nil, nil, nil
        frame:SetScript("OnUpdate", nil)
    end)
    return frame
end

local function drawTrack(ui, parent, state, rank)
    ui.journalTrack = ui.journalTrack or createTrack(parent)
    local frame, j = ui.journalTrack, state.journal
    frame:Show()
    local partial = rank < C.journal.ranks and j.xp % C.journal.xpPerRank / C.journal.xpPerRank or 0
    frame.progress:SetWidth(math.max(0.01, (rank - 1 + partial) * rankSpacing))
    for rewardRank, node in ipairs(frame.nodes) do
        local claimed, earned = rewardRank <= j.claimed, rewardRank <= rank
        local color = claimed and T.green or earned and T.gold or T.muted
        node.rim:SetVertexColor(unpack(color))
        node.icon:SetDesaturated(not earned)
        node.icon:SetAlpha(earned and 1 or 0.45)
        node.rank:SetTextColor(unpack(color))
        node.reward:SetText(G.JournalReward(rewardRank, state, ui.journalHero))
        node.reward:SetTextColor(unpack(earned and T.text or T.muted))
        node.status:SetText(
            claimed and L.COMPLETE
                or earned and L.AVAILABLE
                or rewardRank * C.journal.xpPerRank .. " " .. L.JOURNAL_XP
        )
        node.status:SetTextColor(unpack(color))
        U.Tooltip(
            node,
            L.RANK_PREFIX .. rewardRank,
            node.reward:GetText() .. "\n\n" .. node.status:GetText(),
            320
        )
    end
    if frame.focusState ~= state or frame.focusMonth ~= j.month then
        scrollTrack(frame, (math.max(1, rank) - 1) * rankSpacing, true)
        frame.focusState, frame.focusMonth = state, j.month
    end
end

function P.Draw(ui, parent, state)
    if not ui.journalBorder then
        ui.journalBorder = U.FrameTreatment(parent)
        ui.journalBorder:ClearAllPoints()
        ui.journalBorder:SetPoint("TOPLEFT", -12, -126)
        ui.journalBorder:SetSize(1320, 548)
    end
    ui.journalBorder:Show()
    local now = W.Client.Now()
    G.RefreshJournal(state, now)
    local j, rank = state.journal, G.JournalRank(state)
    local nextReward, saved = G.JournalRewardRank(state)
    local _, nextMonth = G.JournalCalendar(j.day * 86400)
    ui.journalMode = ui.journalMode or "contracts"
    if ui.journalTrack then
        ui.journalTrack:SetShown(ui.journalMode == "track")
    end
    local heroes, slots = {}, {}
    ui.journalHero = state.heroes[ui.journalHero] and ui.journalHero or 1
    ui.journalSlot = ui.journalSlot or 1
    for index, hero in ipairs(state.heroes) do
        heroes[#heroes + 1] = { id = index, name = hero.name }
    end
    for _, slot in ipairs(C.equipmentSlots) do
        slots[#slots + 1] = { id = slot, name = C.slots[slot] }
    end
    line(parent, L.JOURNAL_NAME .. " · " .. L.RANK_PREFIX .. rank .. "/20", 0, 0, 22, T.gold, 850)
    local currentXP = rank == 20 and j.bonusXP or j.xp % C.journal.xpPerRank
    local targetXP = rank == 20 and C.journal.bonusEveryXP or C.journal.xpPerRank
    local xpLabel = rank == 20 and L.JOURNAL_EXTRA_SUPPLIES or L.JOURNAL_XP
    line(
        parent,
        currentXP
            .. "/"
            .. targetXP
            .. " "
            .. xpLabel
            .. " · "
            .. string.format(
                L.JOURNAL_MONTH_STATUS,
                math.floor(j.month / 12),
                j.month % 12 + 1,
                math.max(1, math.ceil((nextMonth - now) / 86400))
            ),
        0,
        34,
        14,
        T.muted,
        850
    )
    ui.journalProgress = progress(parent, 0, 64, 850, currentXP, targetXP)
    local options = { { id = 0, name = L.JOURNAL_NO_TITLE } }
    for _, title in ipairs(C.journalTitles) do
        if title.rank <= j.titles then
            options[#options + 1] = { id = title.rank, name = title.name }
        end
    end
    ui.journalTitle = U.Choice(
        parent,
        j.title == 0 and L.JOURNAL_NO_TITLE or C.journalTitles[j.title / 5].name,
        900,
        0,
        396,
        options,
        j.title,
        function(value)
            W.Action(G.SetJournalTitle, value)
        end
    )
    U.Help(parent, L.JOURNAL_NAME, 1260, 52, L.JOURNAL_PERMANENT .. " " .. L.JOURNAL_ELIGIBILITY)
    ui.journalTabs = {}
    for index, entry in ipairs({
        { "contracts", L.JOURNAL_CONTRACTS },
        { "achievements", L.JOURNAL_ACHIEVEMENTS },
        { "track", L.JOURNAL_TRACK },
    }) do
        local id = entry[1]
        ui.journalTabs[id] = U.Tab(parent, entry[2], (index - 1) * 254, 96, 238, 34, function()
            ui.journalMode = id
            ui:Refresh()
        end, ui.journalMode == id)
        ui.journalTabs[id]:SetFrameLevel(ui.journalBorder:GetFrameLevel() - 1)
    end
    ui.journalClaim = U.Button(
        parent,
        ui.journalMode == "track"
                and (saved and string.format(
                    L.JOURNAL_SAVED_REWARDS,
                    G.JournalRewardsWaiting(state)
                ) or L.JOURNAL_CLAIM)
            or L.JOURNAL_TRACK,
        960,
        96,
        336,
        34,
        function()
            if ui.journalMode ~= "track" then
                ui.journalMode = "track"
                ui:Refresh()
            else
                W.Action(G.ClaimJournalReward, ui.journalHero, ui.journalSlot)
            end
        end,
        false,
        "primary"
    )
    U.Enabled(ui.journalClaim, nextReward ~= nil)
    U.Tooltip(
        ui.journalClaim,
        L.JOURNAL_REWARD,
        nextReward and G.JournalReward(nextReward, state, ui.journalHero) or L.COMPLETE
    )
    if ui.journalMode == "contracts" then
        line(parent, L.JOURNAL_DAILY, 0, 152, 18, T.gold, 624)
        line(parent, L.JOURNAL_WEEKLY, 672, 152, 18, T.gold, 624)
        ui.journalDay = math.min(ui.journalDay or #j.days, #j.days)
        ui.journalDays = {}
        for index, entry in ipairs(j.days) do
            ui.journalDays[index] = U.Button(
                parent,
                string.format(L.JOURNAL_SET, entry.period + 3 - j.day),
                (index - 1) * 212,
                188,
                200,
                28,
                function()
                    ui.journalDay = index
                    ui:Refresh()
                end,
                ui.journalDay == index
            )
        end
        local daily = j.days[ui.journalDay]
        for index = 1, 3 do
            contract(parent, daily, daily.ids[index], 0, 232 + (index - 1) * 116)
            contract(parent, j.weekly, j.weekly.ids[index], 672, 232 + (index - 1) * 116)
        end
        local completed = 0
        for _, id in ipairs(daily.ids) do
            if (daily.progress[id] or 0) >= C.contractByID[id].daily then
                completed = completed + 1
            end
        end
        line(
            parent,
            string.format(L.JOURNAL_BONUS_PROGRESS, math.min(2, completed), C.journal.bonusXP),
            0,
            590,
            14,
            daily.bonus and T.green or T.muted,
            624
        )
        line(parent, L.JOURNAL_RESETS, 0, 626, 12, T.muted, 1250)
        U.Help(
            parent,
            L.JOURNAL_CONTRACTS,
            1260,
            626,
            L.JOURNAL_RULES .. " " .. L.JOURNAL_ELIGIBILITY
        )
    elseif ui.journalMode == "achievements" then
        for index, achievement in ipairs(C.journalAchievements) do
            local x, y = (index - 1) % 3 * 440, 160 + math.floor((index - 1) / 3) * 126
            local earned = j.achievements[achievement.id]
            local value = earned and achievement.target
                or math.min(achievement.target, G.JournalMetric(state, achievement.metric))
            U.Rect(parent, x, y, 416, 112, T.panel, 0.8)
            line(parent, achievement.name, x + 14, y + 12, 15, earned and T.green or T.gold, 388)
            line(parent, goals[achievement.metric], x + 14, y + 42, 12, T.text, 388)
            line(
                parent,
                value
                    .. "/"
                    .. achievement.target
                    .. " · +"
                    .. C.journal.achievementXP
                    .. " "
                    .. L.JOURNAL_XP,
                x + 14,
                y + 66,
                12,
                T.muted,
                388
            )
            progress(parent, x + 14, y + 94, 388, value, achievement.target)
        end
    else
        drawTrack(ui, parent, state, rank)
        ui.journalHeroChoice = U.Choice(
            parent,
            state.heroes[ui.journalHero].name,
            0,
            626,
            300,
            heroes,
            ui.journalHero,
            function(value)
                ui.journalHero = value
                ui:Refresh()
            end
        )
        ui.journalSlotChoice = U.Choice(
            parent,
            C.slots[ui.journalSlot],
            320,
            626,
            240,
            slots,
            ui.journalSlot,
            function(value)
                ui.journalSlot = value
                ui:Refresh()
            end
        )
        U.Help(parent, L.JOURNAL_REWARD, 590, 626, L.JOURNAL_TARGET_HELP)
        line(
            parent,
            state.heroes[ui.journalHero].name .. " · " .. C.slots[ui.journalSlot],
            632,
            626,
            14,
            T.gold,
            664
        )
    end
end
