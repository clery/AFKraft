if not test then
    return
end

local function setup()
    local W = AFKraft
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
    for id in pairs(ui.tabs) do
        state.guide["menu_" .. id] = true
    end
    ui:Refresh()
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

test("Every navigation destination has a distinct icon", function()
    local _, state, ui = setup()
    for id in pairs(ui.tabs) do
        state.guide["menu_" .. id] = true
    end
    ui:Refresh()
    local seen = {}
    for id, tab in pairs(ui.tabs) do
        local icon
        for _, region in ipairs({ (tab.content or tab):GetRegions() }) do
            if region:GetObjectType() == "Texture" and region:GetWidth() == 20 then
                icon = region:GetTexture()
            end
        end
        assert(icon, id .. " has no icon")
        assert(not seen[icon], id .. " repeats " .. (seen[icon] or ""))
        seen[icon] = id
    end
end)

test("Inventory fills the management workspace and filters retain valid pagination", function()
    local W, state, ui = setup()
    for index = 1, 20 do
        state.inventory[index] = W.Game.Item(state, 1, 1, 2)
    end
    ui:SetTab("party")
    local function rows()
        local count = 0
        for control in ui.bagCarousel.currentPane._pool.selection:EnumerateActive() do
            if control:GetWidth() == 312 and control:GetHeight() == 62 then
                count = count + 1
            end
        end
        return count
    end
    assertEquals(12, rows())
    ui.bagFiltersOpen = true
    ui:Refresh()
    assertEquals(10, rows())
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
    state.heroes[1].level = 30
    ui:SetTab("crafting")
    assertEquals("Forge", ui.section:GetText())
    assertNotNil(ui.craftControls.hero)
    assertTrue(ui.forgeTabs.enchanting:IsVisible())
    assertTrue(ui.forgeContainer:IsShown())
    assertTrue(ui.forgeTabs.enchanting:GetParent() == ui.forgeContainer)
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
    assertFalse(ui.forgeContainer:IsShown())
end)

test("Help is readable, separates paragraphs and reuses pooled controls", function()
    local W = AFKraft
    local U = W.Widgets
    local parent = CreateFrame("Frame", nil, UIParent)
    parent:SetSize(400, 200)
    local description = "First paragraph.\n\nSecond paragraph."
    U.Begin(parent)
    local help = U.Help(parent, "Guide", 0, 0, function()
        return description
    end)
    U.EndBuild(parent)
    assertEquals(28, help:GetWidth())
    assertNotNil(help.icon:GetTexture())
    local addLine, lines, styles = GameTooltip.AddLine, {}, {}
    GameTooltip.AddLine = function(self, value, red, green, blue, wrap)
        lines[#lines + 1] = value
        styles[#styles + 1] = { red, green, blue, wrap }
        return addLine(self, value, red, green, blue, wrap)
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
        help:GetScript("OnLeave")(help)
        lines, styles = {}, {}
        U.Tooltip(help, "Guide", "\nFirst line\n\n\n|cffff0000Warning|r\n")
        help:GetScript("OnEnter")(help)
        assertEquals(320, GameTooltip:GetMinimumWidth())
        assertEquals(3, #lines)
        assertEquals("First line", lines[1])
        assertEquals(" ", lines[2])
        assertEquals(1, styles[3][1])
        assertEquals(0, styles[3][2])
        assertTrue(styles[1][4])
        assertTrue(styles[3][4])
        help:GetScript("OnLeave")(help)
        lines = {}
        U.Tooltip(help, "Close", "")
        help:GetScript("OnEnter")(help)
        assertEquals(0, #lines)
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

test(
    "Unknown menus mask names and icons until discovery, then survive reload and chapters",
    function()
        local W, state, ui = setup()
        local tab = ui.tabs.development
        assertEquals("???", tab.text:GetText())
        assertTrue(tab.icon:GetTexture() == ui.tabs.legacy.icon:GetTexture())
        assertFalse(tab.notice:IsShown())
        assertTrue(
            W.Tutorial.MenuHint(state, "development"):find("Discover this when", 1, true) == 1
        )
        tab:GetScript("OnClick")()
        assertEquals("adventure", state.ui.tab)
        state.essence = 1
        ui:Refresh(false)
        assertEquals("Growth", tab.text:GetText())
        state.essence = 0
        W.state = assert(W.Game.Load(W.Game.Copy(state), W.Client.Now()))
        ui:Refresh()
        assertEquals("Growth", tab.text:GetText())
        assertTrue(W.Game.ResetAdventure(W.state, true))
        ui:Refresh()
        assertEquals("Growth", tab.text:GetText())
        ui:SetTab("crafting")
        assertFalse(ui.forgeTabs.enchanting:IsShown())
        assertFalse(ui.forgeTabs.titanforging:IsShown())
        assertFalse(ui.forgeTabs.research:IsShown())
        ui.forgeTabs.enchanting:GetScript("OnClick")()
        assertEquals("crafting", W.state.ui.tab)
        W.state.heroes[1].level = 30
        ui:Refresh()
        assertEquals("Enchant", ui.forgeTabs.enchanting.text:GetText())
        assertTrue(ui.forgeTabs.enchanting:IsShown())
    end
)

test(
    "Sidebar scrolls independently, separates section headings and keeps footer actions fixed",
    function()
        local _, state, ui = setup()
        local menu, content = ui.menuScroll, ui.menuContent
        assertTrue(content:GetHeight() > menu:GetHeight())
        ui:SetMenuOffset(0)
        menu:GetScript("OnMouseWheel")(menu, -1)
        assertTrue(menu:GetVerticalScroll() > 0)
        local offset = menu:GetVerticalScroll()
        ui:Refresh()
        assertEquals(offset, menu:GetVerticalScroll())
        assertEquals(content, ui.tabs.party:GetParent())
        assertEquals(ui.expanded, ui.settingsLink:GetParent())
        assertEquals(ui.expanded, ui.reportLink:GetParent())
        local _, _, _, _, settingsY = ui.settingsLink:GetPoint(1)
        assertEquals(-850, settingsY)
        local _, _, _, _, companyY = ui.menuHeadings[2]:GetPoint(1)
        assertEquals(-(ui.tabs.routes.menuY + 40 + 16), companyY)
        menu:GetScript("OnMouseWheel")(menu, -100)
        assertEquals(content:GetHeight() - menu:GetHeight(), menu:GetVerticalScroll())
        ui:SetTab("difficulty")
        assertTrue(
            ui.tabs.difficulty.menuY + ui.tabs.difficulty:GetHeight()
                <= menu:GetVerticalScroll() + menu:GetHeight()
        )
        ui:SetTab("adventure")
        assertTrue(ui.tabs.adventure.menuY >= menu:GetVerticalScroll())
        ui.tabs.party:GetScript("OnMouseWheel")(ui.tabs.party, -1)
        assertTrue(menu:GetVerticalScroll() > 0)
        state.ui.compact = true
        ui:ApplyMode()
        assertFalse(menu:IsVisible())
        state.ui.compact = false
        ui:ApplyMode()
        assertTrue(menu:IsVisible())
    end
)
