local _, W = ...
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local P = {}
W.TalentPanel = P

local function createTree(parent, path)
    local tree = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tree:SetPoint("TOPLEFT", (path - 1) * 440, 0)
    tree:SetSize(416, 282)
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
    tree.scroll:SetSize(366, 220)
    tree.scroll:SetClipsChildren(true)
    tree.canvas = CreateFrame("Frame", nil, tree.scroll)
    tree.canvas:SetSize(366, 220)
    tree.scroll:SetScrollChild(tree.canvas)
    tree.slider = CreateFrame("Slider", nil, tree, "OptionsSliderTemplate")
    tree.slider:SetPoint("TOPRIGHT", -15, -58)
    tree.slider:SetSize(14, 194)
    tree.slider:SetOrientation("VERTICAL")
    tree.slider:SetValueStep(24)
    tree.slider:SetMinMaxValues(0, 0)
    tree.slider:SetValue(0)
    tree.slider:SetScript("OnValueChanged", function(_, value)
        tree.scroll:SetVerticalScroll(value)
    end)
    tree.scroll:EnableMouseWheel(true)
    tree.scroll:SetScript("OnMouseWheel", function(_, delta)
        local _, maximum = tree.slider:GetMinMaxValues()
        tree.slider:SetValue(math.max(0, math.min(maximum, tree.slider:GetValue() - delta * 48)))
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
        "Rank "
            .. (learned and "1/1" or "0/1")
            .. "\n\n"
            .. talent.text
            .. "\n\n"
            .. (
                not available and reason
                or learned and "Click to unlearn and recover the point."
                or available and "Click to spend one talent point."
                or "Gain more idle levels to earn talent points."
            )
    )
    b:Show()
end

function P.Draw(ui, parent, hero, index)
    if not ui.talentTrees then
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetPoint("TOPLEFT", 0, -67)
        frame:SetSize(1296, 282)
        frame.trees = {}
        for path = 1, 3 do
            frame.trees[path] = createTree(frame, path)
        end
        ui.talentTrees = frame
    end
    local talents = G.TalentList(hero)
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
        local height = math.max(220, 32 + rows * 82)
        tree.canvas:SetHeight(height)
        local maximum = math.max(0, height - tree.scroll:GetHeight())
        tree.slider:SetMinMaxValues(0, maximum)
        tree.slider:SetValue(math.min(tree.slider:GetValue(), maximum))
        tree.slider:SetShown(maximum > 0)
    end
end
