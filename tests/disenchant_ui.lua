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
    ui.frame:Show()
    ui:SetTab("party")
    return W, s, ui, item
end

local function find(ui, label)
    for b in ui.panel._pool.button:EnumerateActive() do
        if b.text:GetText() == label then
            return b
        end
    end
    error("Missing button: " .. label)
end

local function row(ui)
    for b in ui.panel._pool.button:EnumerateActive() do
        if b.text:GetText() == "" and b.disenchantButton then
            return b
        end
    end
    error("Missing inventory row")
end

local function click(b)
    b:GetScript("OnClick")(b)
end

test("Equipment hover actions disenchant selected quantities without equipping", function()
    local _, s, ui, item = setup()
    local b = row(ui)
    b:GetScript("OnEnter")(b)
    assertTrue(b.disenchantButton:IsShown())
    click(b.disenchantButton)
    assertEquals(124, item.count)
    assertEquals(1, s.stats.salvaged)
    assertTrue(s.heroes[1].gear[1] == nil)
    click(find(ui, "10"))
    click(row(ui).disenchantButton)
    assertEquals(114, item.count)
    click(find(ui, "100"))
    click(row(ui).disenchantButton)
    assertEquals(14, item.count)
    click(row(ui).disenchantButton)
    assertEquals(0, #s.inventory)
    assertEquals(125, s.stats.salvaged)
end)

test("Equipment protection blocks manual and bulk disenchanting across filters", function()
    local W, s, ui, item = setup()
    click(row(ui).protectButton)
    assertTrue(item.protected)
    assertFalse(row(ui).disenchantButton:IsEnabled())
    assertFalse(find(ui, "Disenchant all"):IsEnabled())
    local other = W.Game.Item(s, 2, 1, 2)
    other.count = 20
    s.inventory[2] = other
    ui.bagFilter = 1
    ui:Refresh()
    click(find(ui, "Disenchant all"))
    assertEquals(1, #s.inventory)
    assertTrue(s.inventory[1] == item)
    assertEquals(20, s.stats.salvaged)
    click(row(ui).protectButton)
    assertFalse(item.protected)
    click(find(ui, "Disenchant all"))
    assertEquals(0, #s.inventory)
    ui:SetTab("loot")
    for b in ui.panel._pool.button:EnumerateActive() do
        assertFalse((b.text:GetText() or ""):find("Disenchant") ~= nil)
    end
end)

test("Equipment that cannot be equipped still exposes disenchant hover actions", function()
    local W, s, ui = setup()
    s.heroes[1].class = "MAGE"
    local mail = W.Game.Item(s, 2, 1, 3, false, W.Content.itemByID[13123])
    mail.count = 3
    s.inventory = { mail }
    ui:Refresh()
    local b = row(ui)
    assertFalse(b:IsEnabled())
    assertTrue(b:GetMotionScriptsWhileDisabled())
    b:GetScript("OnEnter")(b)
    assertTrue(b.disenchantButton:IsShown())
    assertTrue(b.disenchantButton:IsEnabled())
    click(b.disenchantButton)
    assertEquals(2, mail.count)
    assertEquals(nil, s.heroes[1].gear[2])
end)
