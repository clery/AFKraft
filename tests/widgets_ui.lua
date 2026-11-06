if not test then
    return
end

local function parentFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(500, 300)
    return frame, AFKraft.Widgets
end

test("Gold and standard buttons keep matching bounds and fonts across states and reuse", function()
    local parent, U = parentFrame()
    local function build(y, height)
        U.Begin(parent)
        local standard = U.Button(parent, "Retry", 0, y, 160, height, function() end)
        local gold = U.Button(
            parent,
            "World map",
            180,
            y,
            160,
            height,
            function() end,
            nil,
            "primary"
        )
        U.EndBuild(parent)
        local _, _, _, _, standardY = standard:GetPoint()
        local _, _, _, _, goldY = gold:GetPoint()
        local _, _, _, _, standardTextY = standard.text:GetPoint()
        local _, _, _, _, goldTextY = gold.text:GetPoint()
        assertEquals(standardY, goldY)
        assertEquals(standardY + standardTextY, goldY + goldTextY)
        assertEquals(height, gold:GetHeight())
        for _, button in ipairs({ standard, gold }) do
            for _, enabled in ipairs({ false, true }) do
                button:SetEnabled(enabled)
                button:LockHighlight()
                local font, size, flags = button.text:GetFont()
                assertEquals(AFKraft.font, font)
                assertEquals(13, size)
                assertEquals("", flags)
                assertFalse(button.text == button:GetFontString())
                button:UnlockHighlight()
            end
        end
        return gold
    end
    local gold = build(20, 32)
    assertTrue(gold == build(60, 34))
    parent:Hide()
end)

test("Commands, selections, tabs and passive cards keep distinct behaviors", function()
    local parent, U = parentFrame()
    U.Begin(parent)
    local calls = 0
    local action = U.Button(parent, "Apply", 0, 0, 160, 32, function()
        calls = calls + 1
    end)
    local selection = U.SelectButton(parent, "Choice", 0, 40, 160, 32, function() end, true)
    local tab = U.Tab(parent, "Page", 0, 80, 160, 34, function() end, true)
    local card = U.Card(parent, 0, 120, 200, 80)
    U.EndBuild(parent)
    assertTrue(action.native)
    action:GetScript("OnClick")(action)
    assertEquals(1, calls)
    assertTrue(selection.selection:IsShown())
    U.Selected(selection, false)
    selection:GetScript("OnLeave")(selection)
    assertFalse(selection.selection:IsShown())
    assertTrue(tab.nativeTab)
    assertTrue(tab.isSelected)
    U.Selected(tab, false)
    assertFalse(tab.isSelected)
    assertEquals("Frame", card:GetObjectType())
    assertEquals(nil, card:GetScript("OnMouseUp"))
    U.Begin(parent)
    local reused = U.Button(parent, "Other command", 0, 0, 160, 32, function()
        calls = calls + 10
    end)
    U.EndBuild(parent)
    assertTrue(reused == action)
    reused:GetScript("OnClick")(reused)
    assertEquals(11, calls)
    parent:Hide()
end)

test("Selection hover survives refreshes and clears on leave, hide and reuse", function()
    local parent, U = parentFrame()
    U.Begin(parent)
    local button = U.SelectButton(parent, "Choice", 0, 0, 160, 32, function() end)
    U.EndBuild(parent)
    local color
    hooksecurefunc(button.fill, "SetColorTexture", function(_, r, g, b)
        color = { r, g, b }
    end)
    local function assertColor(expected)
        for i = 1, 3 do
            assertEquals(expected[i], color[i])
        end
    end
    button:GetScript("OnEnter")(button)
    U.Selected(button, false)
    assertColor(AFKraft.Theme.hover)
    U.Selected(button, true)
    assertColor(AFKraft.Theme.hover)
    button:GetScript("OnLeave")(button)
    assertColor(AFKraft.Theme.selected)
    button:GetScript("OnEnter")(button)
    parent:Hide()
    assertFalse(button.hovered)
    assertColor(AFKraft.Theme.selected)
    parent:Show()
    button:GetScript("OnEnter")(button)
    U.Begin(parent)
    local reused = U.SelectButton(parent, "Other choice", 0, 0, 160, 32, function() end)
    U.EndBuild(parent)
    assertTrue(reused == button)
    assertFalse(reused.hovered)
    assertColor(AFKraft.Theme.panel)
    parent:Hide()
end)

test("Repeated tooltips replace their handlers and pooled toggles reset safely", function()
    local parent, U = parentFrame()
    U.Begin(parent)
    local check = U.Checkbox(parent, "Enabled", 0, 0, 200, false, function() end)
    U.EndBuild(parent)
    local enters = 0
    check:SetScript("OnEnter", function()
        enters = enters + 1
    end)
    U.Tooltip(check, "Old help", "Old details", 380)
    U.Tooltip(check, "Current help", "Current details", 380)
    check:GetScript("OnEnter")(check)
    assertEquals(1, enters)
    assertTrue(GameTooltip:IsOwned(check))
    check:SetEnabled(false)
    U.Begin(parent)
    assertFalse(GameTooltip:IsShown())
    local reused = U.Checkbox(parent, "Other toggle", 0, 0, 200, true, function() end)
    U.EndBuild(parent)
    assertTrue(reused == check)
    assertTrue(reused:IsEnabled())
    assertTrue(reused:GetChecked())
    reused:GetScript("OnEnter")(reused)
    assertFalse(GameTooltip:IsShown())
    parent:Hide()
end)

test("Name inputs share focus behavior and retain draft text when hidden", function()
    local parent, U = parentFrame()
    local input = U.Input(parent, 8, 8, 300, 36)
    input:SetText("My route")
    input:SetFocus()
    input:GetScript("OnEnterPressed")(input)
    assertFalse(input:HasFocus())
    input:SetFocus()
    input:GetScript("OnEscapePressed")(input)
    assertFalse(input:HasFocus())
    input:SetFocus()
    parent:Hide()
    assertFalse(input:HasFocus())
    assertEquals("My route", input:GetText())
end)
