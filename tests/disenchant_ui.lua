if not test then
    return
end

local function setup()
    local W = WoWIdle
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.paused = true
    local item = W.Game.Item(s, 1, 1, 2)
    item.count = 125
    s.inventory = { item }
    W.state = s
    local ui = W.UI
    ui.selected, ui.recruiting, ui.bagFiltersOpen = 1, false, false
    ui.bagView, ui.bagFilter, ui.bagPage, ui.disenchantQuantity = nil, 0, 0, nil
    ui.disenchantOpen, ui.disenchantItem, ui.disenchantPage = false, nil, 0
    ui.frame:Show()
    ui:SetTab("party")
    return W, s, ui, item
end

local function find(ui, label)
    for _, kind in ipairs({ "button", "primary" }) do
        for b in ui.panel._pool[kind]:EnumerateActive() do
            if b.text:GetText() == label then
                return b
            end
        end
    end
    error("Missing button: " .. label)
end

local function selectItem(ui, item)
    for b in ui.panel._pool.button:EnumerateActive() do
        if b._pool and b._pool.text then
            for label in b._pool.text:EnumerateActive() do
                if label:GetText() == item.name .. " ×" .. (item.count or 1) then
                    b:GetScript("OnClick")(b)
                    return
                end
            end
        end
    end
    error("Missing stack: " .. item.name)
end

local function click(b)
    b:GetScript("OnClick")(b)
end

test("Disenchant workbench opens separately and consumes the selected quantities", function()
    local _, s, ui, item = setup()
    click(find(ui, "Disenchant…"))
    assertTrue(ui.disenchantOpen)
    assertFalse(find(ui, "Disenchant 1 copy"):IsEnabled())
    selectItem(ui, item)
    click(find(ui, "Disenchant 1 copy"))
    assertEquals(124, item.count)
    assertEquals(1, s.stats.salvaged)
    assertEquals(nil, s.heroes[1].gear[1])
    click(find(ui, "10"))
    click(find(ui, "Disenchant 10 copies"))
    assertEquals(114, item.count)
    click(find(ui, "100"))
    click(find(ui, "Disenchant 100 copies"))
    assertEquals(14, item.count)
    click(find(ui, "Disenchant 14 copies"))
    assertEquals(0, #s.inventory)
    assertEquals(125, s.stats.salvaged)
    assertEquals(nil, ui.disenchantItem)
    assertFalse(find(ui, "Disenchant all unprotected"):IsEnabled())
    click(find(ui, "Back to equipment"))
    assertFalse(ui.disenchantOpen)
    find(ui, "Disenchant…")
end)

test(
    "Workbench protection blocks manual and bulk disenchanting across equipment filters",
    function()
        local W, s, ui, item = setup()
        ui.bagFilter, ui.bagPage = 1, 2
        click(find(ui, "Disenchant…"))
        selectItem(ui, item)
        click(find(ui, "Protect"))
        assertTrue(item.protected)
        assertFalse(find(ui, "Disenchant 1 copy"):IsEnabled())
        assertFalse(find(ui, "Disenchant all unprotected"):IsEnabled())
        local other = W.Game.Item(s, 2, 1, 2)
        other.count = 20
        s.inventory[2] = other
        ui:Refresh()
        click(find(ui, "Disenchant all unprotected"))
        assertEquals(1, #s.inventory)
        assertTrue(s.inventory[1] == item)
        assertEquals(20, s.stats.salvaged)
        click(find(ui, "Unprotect"))
        click(find(ui, "Disenchant all unprotected"))
        assertEquals(0, #s.inventory)
        click(find(ui, "Back to equipment"))
        assertEquals(1, ui.bagFilter)
    end
)

test("Workbench can disenchant class-locked equipment without selecting its neighbor", function()
    local W, s, ui = setup()
    s.heroes[1].class = "MAGE"
    local mail = W.Game.Item(s, 2, 1, 3, false, W.Content.itemByID[13123])
    local neighbor = W.Game.Item(s, 1, 1, 2)
    mail.count = 3
    s.inventory = { mail, neighbor }
    ui:Refresh()
    click(find(ui, "Disenchant…"))
    selectItem(ui, mail)
    click(find(ui, "10"))
    click(find(ui, "Disenchant 3 copies"))
    assertEquals(1, #s.inventory)
    assertTrue(s.inventory[1] == neighbor)
    assertEquals(nil, ui.disenchantItem)
    assertFalse(find(ui, "Disenchant 10 copies"):IsEnabled())
    assertEquals(nil, s.heroes[1].gear[2])
    click(find(ui, "Back to equipment"))
end)

test("Workbench pagination clamps after bulk deletion and heirlooms remain safe", function()
    local W, s, ui = setup()
    for i = 2, 7 do
        s.inventory[i] = W.Game.Item(s, 1, 1, 2)
    end
    local heirloom = s.inventory[7]
    heirloom.heirloom = true
    ui:Refresh()
    click(find(ui, "Disenchant…"))
    click(find(ui, "Next"))
    assertEquals(1, ui.disenchantPage)
    selectItem(ui, heirloom)
    assertFalse(find(ui, "Protect"):IsEnabled())
    assertFalse(find(ui, "Disenchant 1 copy"):IsEnabled())
    click(find(ui, "Disenchant all unprotected"))
    assertEquals(1, #s.inventory)
    assertTrue(s.inventory[1] == heirloom)
    assertEquals(0, ui.disenchantPage)
    assertFalse(find(ui, "Next"):IsEnabled())
    click(find(ui, "Back to equipment"))
end)
