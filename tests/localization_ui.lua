if not test then
    return
end

test("Localized button labels fit and pooled font sizes recover for short labels", function()
    local W = AFKraft
    W.Initialize()
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(400, 100)
    parent:SetPoint("CENTER")
    local originalFont = W.font
    local fonts = { ruRU = "Fonts\\ARIALN.TTF", zhCN = "Fonts\\ARKai_T.ttf" }
    for _, locale in ipairs({ "frFR", "deDE", "esES", "ruRU", "zhCN" }) do
        W.font = fonts[locale] or originalFont
        local catalog = W.Locales[locale]
        local button = W.Widgets.Button(
            parent,
            catalog.EQUIP_BEST_POWER,
            0,
            0,
            168,
            32,
            function() end
        )
        assert(button.text:GetFont() == W.font)
        assert(button.text:GetUnboundedStringWidth() <= button.text:GetWidth() + 1, locale)
        button.text:SetText(catalog.CLOSE)
        local _, size = button.text:GetFont()
        assert(size == 13)
        button:Hide()
    end
    W.font = originalFont
    parent:Hide()
end)

test("Language settings preserve gameplay and validate saved choices", function()
    local W = AFKraft
    W.Initialize()
    local setting = W.settingsOptions.args.locale
    local previous = W.preferences.global.locale
    local state, locale = W.state, W.locale
    local gold, essence = state.gold, state.essence
    setting.set(nil, "deDE")
    assert(setting.get() == "deDE")
    assert(W.locale == locale)
    setting.set(nil, "invalid")
    assert(setting.get() == "deDE")
    assert(setting.values.enUS == "English")
    for _, choice in ipairs({ "ruRU", "zhCN" }) do
        assert(setting.values[choice])
        setting.set(nil, choice)
        assert(setting.get() == choice)
    end
    setting.set(nil, "enUS")
    assert(setting.get() == "enUS")
    assert(W.state == state and state.gold == gold and state.essence == essence)
    W.preferences.global.locale = previous
end)

test("Pooled wrapping labels do not inherit single-line font fitting", function()
    local W = AFKraft
    W.Initialize()
    local parent = CreateFrame("Frame", nil, UIParent)
    W.Widgets.Begin(parent)
    local first = W.Widgets.Text(parent, "Long single-line label", 0, 0, 13)
    W.Widgets.SingleLine(first, 90, 22)
    W.Widgets.EndBuild(parent)
    W.Widgets.Begin(parent)
    local reused = W.Widgets.Text(parent, "A heading", 0, 0, 24, nil, 300)
    local _, size = reused:GetFont()
    assert(reused == first and size == 24 and reused.fitSize == nil)
    W.Widgets.EndBuild(parent)
    parent:Hide()
end)
