local _, W = ...
local T = {
    bg = { 0.065, 0.052, 0.038 },
    panel = { 0.055, 0.060, 0.078 },
    header = { 0.085, 0.067, 0.044 },
    selected = { 0.16, 0.13, 0.075 },
    line = { 0.35, 0.23, 0.10 },
    gold = { 0.95, 0.77, 0.33 },
    text = { 0.90, 0.86, 0.74 },
    muted = { 0.74, 0.72, 0.66 },
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
    t:SetDrawLayer(layer or "BACKGROUND")
    t:SetPoint("TOPLEFT", x, -y)
    t:SetSize(w, h)
    t:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return t
end

function U.Text(parent, text, x, y, size, color, width)
    local f = pooled(parent, "text", function()
        return parent:CreateFontString(nil, "OVERLAY")
    end)
    f.fitSize = nil
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

function U.FitText(fontString)
    local font, currentSize, flags = fontString:GetFont()
    local size = fontString.fitSize
    if not size then
        return
    end
    if currentSize ~= size then
        fontString:SetFont(font, size, flags)
    end
    local width = fontString:GetWidth()
    local natural = fontString.GetUnboundedStringWidth and fontString:GetUnboundedStringWidth()
        or fontString:GetStringWidth()
    if width > 0 and natural > width then
        fontString:SetFont(font, math.max(10, math.floor(size * width / natural)), flags)
    end
end

function U.SingleLine(fontString, width, height, align)
    local _, size = fontString:GetFont()
    fontString.fitSize = size
    if not fontString.fitHook then
        hooksecurefunc(fontString, "SetText", U.FitText)
        fontString.fitHook = true
    end
    fontString:SetSize(width, height)
    fontString:SetWordWrap(false)
    fontString:SetJustifyH(align or "LEFT")
    fontString:SetJustifyV("MIDDLE")
    U.FitText(fontString)
    return fontString
end

local function surface(parent, kind)
    local frame = CreateFrame(kind, nil, parent, "BackdropTemplate")
    frame.content = U.BorderContent(frame, 4)
    frame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    frame:SetBackdropBorderColor(unpack(T.line))
    frame.fill = U.Rect(frame.content, 0, 0, 1, 1, T.panel)
    return frame
end

function U.Selected(button, selected)
    if button.nativeTab then
        button:SetTabSelected(selected)
        button.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    else
        button.selected = selected == true
        if button.fill then
            button.fill:SetColorTexture(unpack(button.selected and T.selected or T.panel))
        end
        if button.selection then
            button.selection:SetShown(button.selected)
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(unpack(button.selected and T.gold or T.line))
        end
    end
    U.FitText(button.text)
    button.text:SetTextColor(unpack(selected and T.gold or T.text))
end

local function resetTooltip(frame)
    if frame:GetScript("OnEnter") == frame.tooltipEnter then
        frame:SetScript("OnEnter", frame.tooltipBaseEnter)
    end
    if frame:GetScript("OnLeave") == frame.tooltipLeave then
        frame:SetScript("OnLeave", frame.tooltipBaseLeave)
    end
    frame.tooltipEnter, frame.tooltipLeave = nil, nil
end

function U.Button(parent, text, x, y, w, h, fn, active, variant)
    local selection = variant == "selection"
    local kind = selection and "selection" or variant == "primary" and "primary" or "button"
    local b = pooled(parent, kind, function()
        if not selection then
            local template = variant == "primary" and "UIPanelGoldButtonTemplate"
                or "UIPanelButtonTemplate"
            local ok, button = pcall(CreateFrame, "Button", nil, parent, template)
            if ok then
                button.native = true
                button.text = button:GetFontString()
                return button
            end
        end
        local button = surface(parent, "Button")
        button.text = U.Text(button, "", 0, 0, 13)
        if selection then
            button.selection = U.Rect(button.content, 4, 6, 3, 1, T.gold, 1, "OVERLAY")
        end
        return button
    end)
    U.Begin(b)
    U.EndBuild(b)
    b:SetPoint("TOPLEFT", x, -y)
    b:SetSize(w, h)
    b:SetEnabled(true)
    if b.fill then
        b.fill:SetSize(w, h)
    end
    if b.selection then
        b.selection:SetHeight(math.max(1, h - 12))
    end
    b.text:ClearAllPoints()
    b.text:SetPoint("CENTER", b, "CENTER", 0, variant == "primary" and b.native and 3 or 0)
    b.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    U.SingleLine(b.text, w - 24, h - 8, selection and "LEFT" or "CENTER")
    b.text:SetText(text)
    b.text:SetAlpha(1)
    b.text:Show()
    U.Selected(b, active)
    b:SetScript("OnEnter", function(self)
        if self.fill then
            self.fill:SetColorTexture(0.105, 0.125, 0.17)
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self.fill then
            self.fill:SetColorTexture(unpack(self.selected and T.selected or T.panel))
        end
    end)
    b:SetScript("OnClick", fn)
    return b
end

function U.SelectButton(parent, text, x, y, w, h, fn, selected)
    return U.Button(parent, text, x, y, w, h, fn, selected, "selection")
end

function U.Tab(parent, text, x, y, w, h, fn, selected)
    local tab = pooled(parent, "tab", function()
        local ok, button = pcall(CreateFrame, "Button", nil, parent, "TabSystemTopButtonTemplate")
        if ok and button.SetTabSelected and button.Text then
            button:HandleRotation()
            for _, texture in ipairs(button.RotatedTextures) do
                texture:SetVertexColor(0.70, 0.58, 0.40)
            end
            button.nativeTab = true
            button.text = button.Text
            return button
        end
        if ok then
            button:Hide()
        end
        button = surface(parent, "Button")
        button.text = U.Text(button, "", 0, 0, 13)
        button.text:SetPoint("CENTER")
        return button
    end)
    tab:SetPoint("TOPLEFT", x, -y)
    tab:SetSize(w, h)
    if tab.fill then
        tab.fill:SetSize(w, h)
    end
    U.SingleLine(tab.text, w - 24, h - 8, "CENTER")
    tab.text:SetText(text)
    tab:SetScript("OnClick", fn)
    U.Selected(tab, selected)
    return tab
end

function U.Card(parent, x, y, w, h)
    local card = pooled(parent, "card", function()
        local frame = surface(parent, "Frame")
        frame:EnableMouse(true)
        return frame
    end)
    U.Begin(card)
    U.EndBuild(card)
    card:SetPoint("TOPLEFT", x, -y)
    card:SetSize(w, h)
    card.fill:SetSize(w, h)
    return card
end

function U.Input(parent, x, y, w, h)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", x, -y)
    edit:SetSize(w, h)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(40)
    edit:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    edit:SetScript("OnHide", function(self)
        self:ClearFocus()
    end)
    return edit
end

function U.Checkbox(parent, label, x, y, width, checked, choose)
    local check = pooled(parent, "checkbox", function()
        local frame = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        frame.label = U.Text(frame, "", 36, 7, 14, T.text)
        return frame
    end)
    resetTooltip(check)
    check:SetEnabled(true)
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
    resetTooltip(frame)
    if not frame.tooltipHideHooked then
        frame:HookScript("OnHide", function(self)
            if GameTooltip:IsOwned(self) then
                GameTooltip:Hide()
            end
        end)
        frame.tooltipHideHooked = true
    end
    if frame.SetMotionScriptsWhileDisabled then
        frame:SetMotionScriptsWhileDisabled(true)
    end
    local enter, leave = frame:GetScript("OnEnter"), frame:GetScript("OnLeave")
    frame.tooltipBaseEnter, frame.tooltipBaseLeave = enter, leave
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
        local description = type(text) == "function" and text() or text
        if width then
            for value in (description .. "\n"):gmatch("([^\n]*)\n") do
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
            GameTooltip:AddLine(description, 0.8, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        if leave then
            leave(self)
        end
        GameTooltip:Hide()
    end)
    frame.tooltipEnter, frame.tooltipLeave = frame:GetScript("OnEnter"), frame:GetScript("OnLeave")
end

function U.Help(parent, title, x, y, description)
    local help = pooled(parent, "help", function()
        local button = CreateFrame("Button", nil, parent)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button.icon:SetTexture("Interface\\common\\help-i")
        button:SetHighlightTexture("Interface\\common\\help-i", "ADD")
        button:SetScript("OnClick", function(self)
            self:GetScript("OnEnter")(self)
        end)
        return button
    end)
    help:SetPoint("TOPLEFT", x, -y)
    help:SetSize(28, 28)
    help:SetScript("OnEnter", nil)
    help:SetScript("OnLeave", nil)
    U.Tooltip(help, title, description, 380)
    return help
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
    resetTooltip(dropdown)
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
