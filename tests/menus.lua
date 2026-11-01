if not test then
    return
end

local function menuState()
    local W = WoWIdle
    W.Initialize()
    W.state = W.Game.New(W.Client.Now())
    for _, class in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "DRUID" }) do
        W.Game.AddHero(W.state, class)
    end
    W.state.paused = true
    W.UI.selected, W.UI.recruiting = 1, false
    W.UI.frame:Show()
    W.state.ui.compact = false
    return W, W.state, W.UI
end

local function findButton(ui, label)
    for _, kind in ipairs({ "button", "primary" }) do
        local pool = ui.panel._pool[kind]
        if pool then
            for button in pool:EnumerateActive() do
                if button.text and button.text:GetText() == label then
                    return button
                end
            end
        end
    end
    error("Missing button: " .. label)
end

local function click(button)
    button:GetScript("OnClick")(button)
end

test("Chapter review cannot reset on a repeated review click and cancellation is free", function()
    local W, state, ui = menuState()
    state.prestigeUnlocked, state.runBest, state.gold = true, 9, 120
    state.heroes[1].level = 6
    ui:SetTab("legacy")
    assertFalse(ui.scene.frame:IsShown())
    assertFalse(ui.cards[1]:IsShown())
    local review = findButton(ui, "Review new chapter…")
    local reviewClick = review:GetScript("OnClick")
    local _, _, _, reviewX, reviewY = review:GetPoint()
    reviewClick(review)
    reviewClick(review)
    assertEquals(120, state.gold)
    assertEquals(0, state.prestiges)
    local confirm = findButton(ui, "Reset adventure and begin chapter")
    local _, _, _, confirmX, confirmY = confirm:GetPoint()
    assertTrue(reviewX ~= confirmX and reviewY ~= confirmY)
    click(findButton(ui, "Keep adventuring"))
    assertFalse(ui.confirmPrestige)
    assertEquals(6, state.heroes[1].level)
    click(findButton(ui, "Review new chapter…"))
    ui.frame:Hide()
    assertFalse(ui.confirmPrestige)
    ui.frame:Show()
    ui:SetTab("legacy")
    click(findButton(ui, "Review new chapter…"))
    click(findButton(ui, "Reset adventure and begin chapter"))
    assertEquals(2, state.legacy)
    assertEquals(1, state.prestiges)
    assertEquals(1, state.heroes[1].level)
    assertEquals(0, state.gold)
    assertEquals("adventure", state.ui.tab)
    assertTrue(W.state == state)
end)

test("Locked chapters stay explorable and heirloom links preserve the chosen slot", function()
    local _, state, ui = menuState()
    ui:SetTab("legacy")
    assertFalse(findButton(ui, "Review new chapter…"):IsEnabled())
    ui.craftSlot, ui.craftHeirloom = 3, false
    ui:SetTab("crafting")
    click(findButton(ui, "Heirloom"))
    assertTrue(ui.craftHeirloom)
    click(findButton(ui, "View recipe in Legacy"))
    assertEquals("legacy", state.ui.tab)
    assertEquals(3, ui.legacySlot)
    state.legacy = 1
    click(findButton(ui, "Unlock · Head · 1 Legacy"))
    assertTrue(state.recipes[3])
    assertEquals(0, state.legacy)
    assertEquals("crafting", state.ui.tab)
    assertEquals(3, ui.craftSlot)
    assertTrue(ui.craftHeirloom)
    click(findButton(ui, "Ordinary"))
    assertFalse(ui.craftHeirloom)
end)

test(
    "Opportunities refresh for other heroes and loot checkboxes change only future rules",
    function()
        local W, state, ui = menuState()
        ui:SetTab("adventure")
        local before = ui.tabs.talents.notice:GetText()
        state.heroes[2].level = 8
        ui:Refresh(false)
        assertTrue(before ~= ui.tabs.talents.notice:GetText())
        state.prestigeUnlocked, state.runBest = true, 9
        ui:Refresh(false)
        assertEquals("+2 Legacy", ui.tabs.legacy.notice:GetText())
        ui:SetTab("loot")
        assertFalse(ui.scene.frame:IsShown())
        assertFalse(ui.cards[1]:IsShown())
        local item = W.Game.Item(state, 1, 1, 2)
        state.inventory[1] = item
        local changed = false
        for check in ui.panel._pool.checkbox:EnumerateActive() do
            if check.label:GetText() == "Keep potential upgrades" then
                local previous = state.salvage.keepUpgrades
                check:SetChecked(not previous)
                click(check)
                assertEquals(not previous, state.salvage.keepUpgrades)
                changed = true
                break
            end
        end
        assertTrue(changed)
        assertTrue(state.inventory[1] == item)
    end
)
