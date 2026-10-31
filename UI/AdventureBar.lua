local _, W = ...
local U, T, C = W.Widgets, W.Theme, W.Content
local Bar = {}
Bar.__index = Bar
W.AdventureBar = Bar

function Bar.Create(parent, x, y, width)
    local self = setmetatable({}, Bar)
    local frame = CreateFrame("Frame", nil, parent)
    self.frame = frame
    frame:SetPoint("TOPLEFT", x, -y)
    frame:SetSize(width, 28)
    frame:SetFrameLevel(parent:GetFrameLevel() + 2)
    frame:EnableMouse(true)
    self.label = U.SingleLine(U.Text(frame, "", 0, 0, 11, T.text), width, 17)
    self.fill = U.Bar(frame, 0, 21, width, 6, { 0.63, 0.38, 0.88 })
    self.fill:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame:SetScript("OnEnter", function()
        local progress, rules = W.state.adventure, C.adventure
        GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Adventure XP · Account-wide", unpack(T.gold))
        GameTooltip:AddLine(
            "Every "
                .. rules.xpPerRank
                .. " XP awards "
                .. rules.essencePerRank
                .. " Essence. Your rank and partial XP survive prestige.",
            0.85,
            0.85,
            0.8,
            true
        )
        GameTooltip:AddLine(" ")
        for _, kind in ipairs(C.activityOrder) do
            local reward = C.activityRewards[kind]
            GameTooltip:AddDoubleLine(
                reward.name,
                reward.xp .. " XP",
                0.85,
                0.85,
                0.8,
                0.95,
                0.77,
                0.33
            )
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "Bosses must be within your XP range. Dungeon completion adds a bonus when confirmed by the client. Heroes earn their own experience through idle combat.",
            0.65,
            0.65,
            0.6,
            true
        )
        GameTooltip:AddLine("Lifetime Adventure XP: " .. progress.totalXP, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return self
end

function Bar:Refresh(state)
    local progress, rules = state.adventure, C.adventure
    if self.state ~= state then
        self.state, self.rank, self.rewardUntil = state, progress.rank, nil
    elseif progress.rank > self.rank then
        self.earned = (progress.rank - self.rank) * rules.essencePerRank
        self.rank, self.rewardUntil = progress.rank, GetTime() + 4
    end
    local text = "Adventure rank "
        .. progress.rank
        .. "  ·  "
        .. progress.xp
        .. " / "
        .. rules.xpPerRank
        .. " XP"
    if self.rewardUntil and GetTime() < self.rewardUntil then
        text = text .. "  ·  +" .. self.earned .. " Essence earned"
        self.label:SetTextColor(unpack(T.gold))
    else
        text = text .. "  ·  Next: " .. rules.essencePerRank .. " Essence"
        self.label:SetTextColor(unpack(T.text))
    end
    self.label:SetText(text)
    self.fill:SetValue(progress.xp / rules.xpPerRank)
end
