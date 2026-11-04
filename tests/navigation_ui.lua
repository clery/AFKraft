if not test then
    return
end

local function setup()
    local W = WoWIdle
    W.Initialize()
    W.state = W.Game.New(W.Client.Now())
    W.Game.AddHero(W.state, "WARRIOR")
    W.state.guide.dismissed = true
    local ui = W.UI
    ui.selected, ui.recruiting, ui.disenchantOpen = 1, false, false
    ui.bagView, ui.bagFilter, ui.bagPage, ui.bagFiltersOpen = nil, 0, 0, false
    ui.frame:Show()
    ui:SetTab("adventure")
    return W, W.state, ui
end

test("Navigation keeps every feature reachable and gives management the workspace", function()
    local _, state, ui = setup()
    local heroPages = { party = true, talents = true }
    for id, tab in pairs(ui.tabs) do
        tab:GetScript("OnClick")()
        assertEquals(id, state.ui.tab)
        assertTrue(tab.selection:IsShown())
        assertEquals(id == "adventure", ui.scene.frame:IsShown())
        assertEquals(id == "adventure" or heroPages[id] == true, ui.cards[1]:IsShown())
        assertTrue(
            ui.panel:GetHeight()
                >= (
                    heroPages[id] and 590
                    or id == "adventure" and 240
                    or id == "crafting" and 630
                    or 690
                )
        )
        for otherID, other in pairs(ui.tabs) do
            assertEquals(otherID == id, other.selection:IsShown())
        end
    end
    state.ui.compact, state.ui.locked = true, true
    ui:ApplyMode()
    assertTrue(ui.scene.frame:IsShown())
    assertTrue(ui.lock:IsVisible())
    ui.tabs.party:GetScript("OnClick")()
    assertFalse(state.ui.compact)
    assertEquals("party", state.ui.tab)
    state.ui.locked = false
    ui:ApplyMode()
end)

test("Inventory fills the management workspace and filters retain valid pagination", function()
    local W, state, ui = setup()
    for index = 1, 20 do
        state.inventory[index] = W.Game.Item(state, 1, 1, 2)
    end
    ui:SetTab("party")
    local function rows()
        local count = 0
        for control in ui.panel._pool.button:EnumerateActive() do
            if control:GetWidth() == 688 and control:GetHeight() == 46 then
                count = count + 1
            end
        end
        return count
    end
    assertEquals(9, rows())
    ui.bagFiltersOpen = true
    ui:Refresh()
    assertEquals(8, rows())
    ui.bagPage = 99
    state.inventory = {}
    ui:Refresh()
    assertEquals(0, ui.bagPage)
    assertEquals(0, rows())
end)

test("Adventure suggestions open the right hero and preserve gameplay", function()
    local W, state, ui = setup()
    state.inventory[1] = W.Game.Item(state, 1, 1, 2)
    ui:Refresh()
    assertEquals("Review equipment", ui.adventureNext.text:GetText())
    ui.adventureNext:GetScript("OnClick")()
    assertEquals("party", state.ui.tab)
    state.inventory, state.guide.equipped = {}, true
    state.heroes[1].level = 8
    ui:SetTab("adventure")
    assertEquals("Spend talent points", ui.adventureNext.text:GetText())
    local points = W.Game.Points(state.heroes[1])
    ui.adventureNext:GetScript("OnClick")()
    assertEquals("talents", state.ui.tab)
    assertEquals(1, ui.selected)
    assertEquals(points, W.Game.Points(state.heroes[1]))
    local tree = ui.talentTrees.trees[1]
    assertTrue(tree.scroll:GetHeight() >= 350)
    assertTrue(ui.talentTrees:GetHeight() < ui.panel:GetHeight())
end)

test("Forge keeps crafting and profession actions under one navigation entry", function()
    local W, state, ui = setup()
    W.Game.AddHero(state, "PRIEST")
    ui.selected = 2
    ui:SetTab("crafting")
    assertEquals("Forge", ui.section:GetText())
    assertNotNil(ui.craftControls.hero)
    assertTrue(ui.forgeTabs.enchanting:IsVisible())
    ui.forgeTabs.enchanting:GetScript("OnClick")()
    assertEquals("workshop", state.ui.tab)
    assertEquals("enchanting", ui.professionTab)
    assertEquals(2, ui.professionHero)
    assertTrue(ui.tabs.crafting.selection:IsShown())
    assertTrue(ui.professionControls.tabs == ui.forgeTabs)
    ui.professionHero = 1
    ui.forgeTabs.crafting:GetScript("OnClick")()
    assertEquals("crafting", state.ui.tab)
    assertEquals(1, ui.selected)
    ui:SetTab("party")
    assertFalse(ui.forgeTabs.enchanting:IsShown())
end)

test("Help is readable, separates paragraphs and reuses pooled controls", function()
    local W = WoWIdle
    local U = W.Widgets
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(400, 200)
    local description = "First paragraph.\n\nSecond paragraph."
    U.Begin(parent)
    local help = U.Help(parent, "Guide", 0, 0, function()
        return description
    end)
    U.EndBuild(parent)
    assertTrue(help.text:GetWidth() >= 20)
    local addLine, lines = GameTooltip.AddLine, {}
    GameTooltip.AddLine = function(self, value, ...)
        lines[#lines + 1] = value
        return addLine(self, value, ...)
    end
    local ok, message = pcall(function()
        help:GetScript("OnClick")(help)
        assertEquals("First paragraph.", lines[1])
        assertEquals(" ", lines[2])
        assertEquals("Second paragraph.", lines[3])
        help:GetScript("OnLeave")(help)
        description, lines = "Updated help.", {}
        help:GetScript("OnEnter")(help)
        assertEquals("Updated help.", lines[1])
    end)
    GameTooltip.AddLine = addLine
    GameTooltip:Hide()
    assert(ok, message)
    U.Begin(parent)
    local reused = U.Help(parent, "Other help", 0, 0, "Details")
    U.EndBuild(parent)
    assertTrue(reused == help)
    parent:Hide()
end)
