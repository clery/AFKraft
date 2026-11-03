local _, W = ...
local T = {
    bg = { 0.065, 0.052, 0.038 },
    panel = { 0.055, 0.060, 0.078 },
    line = { 0.35, 0.23, 0.10 },
    gold = { 0.95, 0.77, 0.33 },
    text = { 0.90, 0.86, 0.74 },
    muted = { 0.64, 0.61, 0.52 },
    green = { 0.48, 0.78, 0.58 },
}
W.Theme = T
local U = {}
W.Widgets = U
-- Management panels reuse their frame/region pools on redraw. WoW frames cannot
-- be destroyed, so allocating a new tree on every refresh would leak UI objects.

function U.Begin(parent)
    parent._building = true
    for _, pool in pairs(parent._pool or {}) do
        pool:ReleaseAll()
    end
end

function U.EndBuild(parent)
    parent._building = false
end

-- Clip content inside the opaque part of a decorative border. Keep the
-- content's coordinate system unchanged so layouts and texture crops still fit.
function U.BorderContent(parent, inset)
    local clip = CreateFrame("Frame", nil, parent)
    clip:SetPoint("TOPLEFT", inset, -inset)
    clip:SetPoint("BOTTOMRIGHT", -inset, inset)
    clip:SetClipsChildren(true)
    local content = CreateFrame("Frame", nil, clip)
    content:SetAllPoints(parent)
    clip:SetFrameLevel(parent:GetFrameLevel())
    content:SetFrameLevel(parent:GetFrameLevel())
    return content
end

function U.FrameTreatment(parent)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetAllPoints()
    border:SetFrameLevel(parent:GetFrameLevel() + 20)
    border:EnableMouse(false)
    border:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 16,
    })
    border:SetBackdropBorderColor(0.85, 0.72, 0.48)
    return border
end

local function pooled(parent, kind, create)
    if not parent._building then
        return create()
    end
    parent._pool = parent._pool or {}
    if not parent._pool[kind] then
        parent._pool[kind] = CreateObjectPool(create, function(_, region)
            region:Hide()
            region:ClearAllPoints()
        end)
    end
    local region = parent._pool[kind]:Acquire()
    region:ClearAllPoints()
    region:Show()
    return region
end

function U.Color(hex)
    return "|cff" .. hex
end

function U.Rect(parent, x, y, w, h, color, alpha, layer)
    local t = pooled(parent, "rect", function()
        return parent:CreateTexture(nil, layer or "BACKGROUND")
    end)
    t:SetPoint("TOPLEFT", x, -y)
    t:SetSize(w, h)
    t:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return t
end

function U.Text(parent, text, x, y, size, color, width)
    local f = pooled(parent, "text", function()
        return parent:CreateFontString(nil, "OVERLAY")
    end)
    f:SetFont("Fonts\\FRIZQT__.TTF", size or 14, "")
    f:SetPoint("TOPLEFT", x, -y)
    f:SetJustifyH("LEFT")
    f:SetJustifyV("TOP")
    f:SetWidth(width or 0)
    f:SetHeight(0)
    f:SetWordWrap(true)
    f:SetTextColor(unpack(color or T.text))
    f:SetText(text)
    f:SetShadowColor(0, 0, 0, 0.8)
    f:SetShadowOffset(1, -1)
    return f
end

function U.SingleLine(fontString, width, height, align)
    fontString:SetSize(width, height)
    fontString:SetWordWrap(false)
    fontString:SetJustifyH(align or "LEFT")
    fontString:SetJustifyV("MIDDLE")
    return fontString
end

function U.Button(parent, text, x, y, w, h, fn, active, variant)
    local b = pooled(parent, variant == "primary" and "primary" or "button", function()
        if variant == "primary" then
            local ok, button =
                pcall(CreateFrame, "Button", nil, parent, "UIPanelGoldButtonTemplate")
            if ok then
                button.native = true
                return button
            end
        end
        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button.content = U.BorderContent(button, 4)
        button:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        return button
    end)
    -- A pooled button may change roles between pages. Clear any custom content
    -- from its previous role before rebuilding it beneath the button's layer.
    U.Begin(b)
    U.EndBuild(b)
    b:SetPoint("TOPLEFT", x, -y)
    b:SetSize(w, h)
    b:SetEnabled(true)
    local color = active and { 0.085, 0.105, 0.15 } or T.panel
    if not b.fill then
        b.fill = U.Rect(b.content or b, 0, 0, w, h, color)
        b.text = b.native and b:GetFontString() or U.Text(b, text, 0, 0, 13)
    else
        b.fill:SetSize(w, h)
        b.fill:SetColorTexture(unpack(color))
    end
    b.text:ClearAllPoints()
    -- Gold-button artwork sits above the frame center (the native template
    -- anchors its label above the bottom padding). Match that visual center.
    b.text:SetPoint("CENTER", b, "CENTER", 0, b.native and 3 or 0)
    b.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    U.SingleLine(b.text, w - 24, h - 8, b.native and "CENTER" or "LEFT")
    b.text:SetText(text)
    b.text:SetTextColor(unpack(active and T.gold or T.text))
    b.text:SetAlpha(1)
    b.text:Show()
    b.fill:SetAlpha(b.native and 0 or 1)
    if b.SetBackdropBorderColor and not b.native then
        b:SetBackdropBorderColor(unpack(active and T.gold or T.line))
    end
    b:SetScript("OnEnter", function()
        b.fill:SetColorTexture(0.105, 0.125, 0.17)
    end)
    b:SetScript("OnLeave", function()
        local c = active and { 0.085, 0.105, 0.15 } or T.panel
        b.fill:SetColorTexture(unpack(c))
    end)
    b:SetScript("OnClick", fn)
    return b
end

function U.Checkbox(parent, label, x, y, width, checked, choose)
    local check = pooled(parent, "checkbox", function()
        local frame = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        frame.label = U.Text(frame, "", 36, 7, 14, T.text)
        return frame
    end)
    check:SetPoint("TOPLEFT", x, -y)
    check:SetSize(32, 32)
    check:SetHitRectInsets(0, -(width - 32), 0, 0)
    U.SingleLine(check.label, width - 40, 22)
    check.label:SetText(label)
    check:SetChecked(checked)
    check:SetScript("OnClick", function(self)
        choose(self:GetChecked() == true)
    end)
    return check
end

function U.Enabled(button, enabled)
    button:SetEnabled(enabled)
    button.text:SetAlpha(enabled and 1 or 0.5)
end

function U.Icon(parent, name, x, y, size)
    local t = pooled(parent, "icon", function()
        return parent:CreateTexture(nil, "ARTWORK")
    end)
    t:SetPoint("TOPLEFT", x, -y)
    t:SetSize(size, size)
    t:SetTexture("Interface\\Icons\\" .. name)
    t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return t
end

local tooltipWidth, tooltipWidthForce
local tooltipWidthHooked = false

function U.Tooltip(frame, title, text, width)
    local enter, leave = frame:GetScript("OnEnter"), frame:GetScript("OnLeave")
    frame:SetScript("OnEnter", function(self)
        if enter then
            enter(self)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if width then
            if not tooltipWidthHooked then
                GameTooltip:HookScript("OnHide", function()
                    if tooltipWidth then
                        GameTooltip:SetMinimumWidth(tooltipWidth, tooltipWidthForce)
                        tooltipWidth, tooltipWidthForce = nil, nil
                    end
                end)
                tooltipWidthHooked = true
            end
            tooltipWidth, tooltipWidthForce = GameTooltip:GetMinimumWidth()
            GameTooltip:SetMinimumWidth(width)
        end
        GameTooltip:SetText(title, unpack(T.gold))
        if width then
            for value in (text .. "\n"):gmatch("([^\n]*)\n") do
                local red, green, blue = value:match("^|c%x%x(%x%x)(%x%x)(%x%x)")
                if red then
                    GameTooltip:AddLine(
                        value,
                        tonumber(red, 16) / 255,
                        tonumber(green, 16) / 255,
                        tonumber(blue, 16) / 255,
                        true
                    )
                else
                    GameTooltip:AddLine(value ~= "" and value or " ", 0.8, 0.85, 0.85, true)
                end
            end
        else
            GameTooltip:AddLine(text, 0.8, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        if leave then
            leave(self)
        end
        GameTooltip:Hide()
    end)
end

function U.Choice(parent, label, x, y, w, options, value, choose)
    local dropdown = pooled(parent, "choice", function()
        local ok, frame =
            pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        if ok and frame.SetupMenu then
            return frame
        end
        if ok then
            frame:Hide()
        end
        return CreateFrame("Button", nil, parent)
    end)
    dropdown:SetPoint("TOPLEFT", x, -y)
    dropdown:SetSize(w, 32)
    -- Choice frames retain disabled state when released by another panel.
    dropdown:SetEnabled(true)
    if dropdown.SetupMenu then
        dropdown:SetDefaultText(label)
        dropdown:SetupMenu(function(_, root)
            for _, option in ipairs(options) do
                local id = option.id
                root:CreateRadio(option.name, function()
                    return value == id
                end, function()
                    choose(id)
                end)
            end
        end)
    else
        if not dropdown.label then
            dropdown.label = U.Text(dropdown, label, 10, 9, 13, T.gold, w - 20)
        end
        dropdown.label:SetText(label)
        dropdown:SetScript("OnClick", function()
            local nextIndex = 1
            for i, option in ipairs(options) do
                if option.id == value then
                    nextIndex = i % #options + 1
                end
            end
            choose(options[nextIndex].id)
        end)
    end
    return dropdown
end

function U.Bar(parent, x, y, w, h, color, nameplate)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetPoint("TOPLEFT", x, -y)
    b:SetSize(w, h)
    b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    b:SetStatusBarColor(unpack(color))
    b:SetMinMaxValues(0, 1)
    b:SetValue(1)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.15, 0.15, 0.15, 1)
    if nameplate then
        W.Client.StyleNameplate(b, bg)
        return b
    end
    -- Keep the outline thickness independent of the bar aspect ratio.
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local border = b:CreateTexture(nil, "OVERLAY")
        border:SetColorTexture(0.35, 0.23, 0.10, 1)
        if edge == "TOP" or edge == "BOTTOM" then
            border:SetPoint(edge .. "LEFT", b, edge .. "LEFT", -1, edge == "TOP" and 1 or -1)
            border:SetPoint(edge .. "RIGHT", b, edge .. "RIGHT", 1, edge == "TOP" and 1 or -1)
            border:SetHeight(1)
        else
            border:SetPoint("TOP" .. edge, b, "TOP" .. edge, edge == "LEFT" and -1 or 1, 0)
            border:SetPoint("BOTTOM" .. edge, b, "BOTTOM" .. edge, edge == "LEFT" and -1 or 1, 0)
            border:SetWidth(1)
        end
    end
    return b
end

U.Number = AbbreviateNumbers
