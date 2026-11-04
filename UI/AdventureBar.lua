local _, W = ...
local U, T, C = W.Widgets, W.Theme, W.Content
local Bar = {}
Bar.__index = Bar
W.AdventureBar = Bar

-- Animate presentation only; rewards and the label always use authoritative XP.
function Bar:StopAnimation()
    self.animating = false
    self.display = self.target
    self.fill:SetValue(self.target and self.target % 1 or 0)
    self.spark:Hide()
    self.flash:Hide()
end

function Bar:Update(elapsed)
    self.phase = (self.phase + elapsed) % 4
    local phase = self.phase / 4
    self.ambient:SetAlpha(0.06 + 0.04 * math.sin(phase * math.pi * 2))
    self.shimmer:ClearAllPoints()
    self.shimmer:SetPoint("CENTER", self.fill, "LEFT", 18 + phase * (self.fill:GetWidth() - 36), 0)
    self.shimmer:SetAlpha(0.2 * math.sin(phase * math.pi) ^ 2)
    if self.animating then
        self:Animate(elapsed)
    end
end

function Bar:Animate(elapsed)
    self.elapsed = self.elapsed + elapsed
    local t = math.min(self.elapsed / self.duration, 1)
    local previous = self.display
    self.display = self.start + (self.target - self.start) * (1 - (1 - t) ^ 3)
    if math.floor(self.display) > math.floor(previous) then
        self.flashTime = 0.6
    end
    local fraction = self.display % 1
    self.fill:SetValue(fraction)
    self.spark:ClearAllPoints()
    self.spark:SetPoint("CENTER", self.fill, "LEFT", fraction * self.fill:GetWidth(), 0)
    self.spark:SetAlpha(math.min(1, (1 - t) * 5))
    self.spark:SetShown(t < 1 and fraction > 0)
    self.flashTime = math.max(0, (self.flashTime or 0) - elapsed)
    self.flash:SetAlpha(self.flashTime / 0.6)
    self.flash:SetShown(self.flashTime > 0)
    if t == 1 and self.flashTime == 0 then
        self:StopAnimation()
    end
end

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
    self.phase = 0
    self.ambient = self.fill:CreateTexture(nil, "OVERLAY")
    self.ambient:SetAllPoints()
    self.ambient:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.ambient:SetVertexColor(0.55, 0.3, 0.8)
    self.ambient:SetBlendMode("ADD")
    self.ambient:SetAlpha(0.06)
    self.shimmer = self.fill:CreateTexture(nil, "OVERLAY")
    self.shimmer:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    self.shimmer:SetBlendMode("ADD")
    self.shimmer:SetVertexColor(0.65, 0.45, 1)
    self.shimmer:SetSize(36, 10)
    self.shimmer:SetAlpha(0)
    self.spark = self.fill:CreateTexture(nil, "OVERLAY", nil, 2)
    self.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    self.spark:SetBlendMode("ADD")
    self.spark:SetVertexColor(0.85, 0.65, 1)
    self.spark:SetSize(18, 22)
    self.spark:Hide()
    self.flash = self.fill:CreateTexture(nil, "OVERLAY", nil, 1)
    self.flash:SetAllPoints()
    self.flash:SetColorTexture(1, 0.78, 0.3, 0.8)
    self.flash:SetBlendMode("ADD")
    self.flash:Hide()
    frame:SetScript("OnHide", function()
        self:StopAnimation()
        frame:SetScript("OnUpdate", nil)
    end)
    local function update(_, elapsed)
        self:Update(elapsed)
    end
    frame:SetScript("OnUpdate", update)
    frame:SetScript("OnShow", function()
        frame:SetScript("OnUpdate", update)
    end)
    frame:SetScript("OnEnter", function()
        local rules = C.adventure
        GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Adventure XP · Account-wide", unpack(T.gold))
        GameTooltip:AddLine(
            rules.xpPerRank
                .. " Adventure XP = "
                .. rules.essencePerRank
                .. " Essence. Rank and partial XP survive both resets.",
            0.85,
            0.85,
            0.8,
            true
        )
        GameTooltip:AddLine(" ")
        for _, kind in ipairs(C.activityOrder) do
            local reward = C.activityRewards[kind]
            GameTooltip:AddLine(reward.name .. " · " .. reward.xp .. " XP", 0.85, 0.85, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "No gray or legacy rewards. Gathering must be skill-up eligible. Idle battles earn hero XP instead.",
            0.65,
            0.65,
            0.6,
            true
        )
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return self
end

function Bar:Refresh(state)
    local progress, rules = state.adventure, C.adventure
    local target = progress.rank + progress.xp / rules.xpPerRank
    local reset = self.state ~= state or not self.target or target < self.target
    if self.state ~= state then
        self.state, self.rank, self.rewardUntil = state, progress.rank, nil
    elseif progress.rank > self.rank then
        self.earned = (progress.rank - self.rank) * rules.essencePerRank
        self.rank, self.rewardUntil = progress.rank, GetTime() + 4
    end
    local text = "Adventure rank " .. progress.rank
    if self.rewardUntil and GetTime() < self.rewardUntil then
        text = text .. "  ·  +" .. self.earned .. " Essence earned"
        self.label:SetTextColor(unpack(T.gold))
    else
        text = text .. "  ·  Next: " .. rules.essencePerRank .. " Essence"
        self.label:SetTextColor(unpack(T.text))
    end
    self.label:SetText(text)
    if reset or not self.frame:IsVisible() then
        self.target = target
        self:StopAnimation()
    elseif target > self.target then
        -- Coalesce large rewards into one visible rollover rather than replaying
        -- every rank. A new gain continues from the currently painted position.
        self.start = math.max(self.display, math.floor(target) - 1)
        self.target, self.elapsed, self.flashTime = target, 0, 0
        self.duration = math.floor(target) > math.floor(self.start) and 1.1 or 0.65
        self.animating = true
    end
end
