if not test then
    return
end

test("Localized button labels fit and pooled font sizes recover for short labels", function()
    local W = WoWIdle
    W.Initialize()
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(400, 100)
    parent:SetPoint("CENTER")
    for _, locale in ipairs({ "frFR", "deDE", "esES" }) do
        local catalog = W.Locales[locale]
        local button = W.Widgets.Button(
            parent,
            catalog["Equip best power"],
            0,
            0,
            168,
            32,
            function() end
        )
        assert(button.text:GetUnboundedStringWidth() <= button.text:GetWidth() + 1, locale)
        button.text:SetText(catalog["Close"])
        local _, size = button.text:GetFont()
        assert(size == 13)
        button:Hide()
    end
    parent:Hide()
end)

test("Language settings preserve gameplay and validate saved choices", function()
    local W = WoWIdle
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
    setting.set(nil, "enUS")
    assert(setting.get() == "enUS")
    assert(W.state == state and state.gold == gold and state.essence == essence)
    W.preferences.global.locale = previous
end)

test("Pooled wrapping labels do not inherit single-line font fitting", function()
    local W = WoWIdle
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
