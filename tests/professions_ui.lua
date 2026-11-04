if not test then
    return
end
local function click(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end
local function workshop(level)
    local W = WoWIdle
    local s = W.Game.New(W.Client.Now())
    for _, zone in ipairs(W.Content.zones) do
        s.professions.components[zone.id] = 1000
    end
    W.Game.AddHero(s, "WARRIOR")
    local hero = s.heroes[1]
    hero.level = level or 60
    W.Game.TalentProgress(hero)
    local item = W.Game.CraftItem(hero, 1, false)
    item.uid = s.nextItem
    s.nextItem = s.nextItem + 1
    hero.gear[1] = item
    s.gold, s.essence, s.guide.dismissed = 1000000, 1000000, true
    for _, material in ipairs(W.Content.materialOrder) do
        s.materials[material] = 1000000
    end
    W.Game.ValidateProfessions(s)
    W.state = s
    local ui = W.UI
    ui.professionTab, ui.professionResearch, ui.professionHero, ui.professionSlot, ui.professionEnchant =
        "enchanting", "crafting", 1, 1, "offense"
    s.ui.compact, s.ui.locked = false, false
    ui.frame:Show()
    ui:SetTab("workshop")
    return W, s, item
end

test(
    "Workshop previews and applies enchantments with explicit replacement and resource gates",
    function()
        local W, s, item = workshop()
        local ui = W.UI
        assertTrue(ui.professionFrame:IsShown())
        assertTrue(ui.professionControls.commit:IsEnabled())
        click(ui.professionControls.commit)
        assertEquals("offense", item.enchant.id)
        assertFalse(ui.professionControls.commit:IsEnabled())
        click(ui.professionControls.enchants.defense)
        assertTrue(ui.professionControls.commit:IsEnabled())
        click(ui.professionControls.commit)
        assertEquals("defense", item.enchant.id)
        assertEquals(1, s.professions.ranks.enchanting)
        s.materials.relic = 0
        click(ui.professionControls.enchants.utility)
        assertFalse(ui.professionControls.commit:IsEnabled())
        ui:SetTab("adventure")
        assertFalse(ui.professionFrame:IsShown())
    end
)

test("Workshop locks unavailable professions and caps titanforge transactions", function()
    local W, s = workshop(29)
    local ui = W.UI
    assertFalse(ui.professionControls.commit:IsEnabled())
    ui.professionControls.tabs.titanforging:GetScript("OnClick")()
    assertEquals("enchanting", ui.professionTab)
    assertFalse(ui.professionControls.commit:IsEnabled())
    s.heroes[1].level = 50
    W.Game.TalentProgress(s.heroes[1])
    ui:Refresh()
    click(ui.professionControls.tabs.titanforging)
    assertTrue(ui.professionControls.commit:IsEnabled())
    for _ = 1, 5 do
        click(ui.professionControls.commit)
    end
    assertEquals(5, s.heroes[1].gear[1].forge)
    assertFalse(ui.professionControls.commit:IsEnabled())
end)

test("Workshop specialization controls use profession points and pooled layouts", function()
    local W, s = workshop()
    local ui = W.UI
    for _ = 1, 35 do
        W.Game.ProfessionWork(s, "crafting")
    end
    local combat = W.Game.Points(s.heroes[1])
    click(ui.professionControls.tabs.research)
    assertTrue(ui.professionControls.branches.precision[1]:IsEnabled())
    click(ui.professionControls.branches.precision[1])
    assertEquals(1, s.professions.allocations.crafting.precision)
    assertTrue(ui.professionControls.branches.precision[2]:IsEnabled())
    assertEquals(combat, W.Game.Points(s.heroes[1]))
    local counts = {}
    for _, pool in pairs(ui.professionFrame._pool) do
        counts[pool] = pool:GetNumActive()
    end
    ui:Refresh()
    for _, pool in pairs(ui.professionFrame._pool) do
        assertEquals(counts[pool], pool:GetNumActive())
    end
    click(ui.professionControls.respec)
    assertTrue(next(s.professions.allocations.crafting) == nil)
    ui:SetTab("boosts")
    assertFalse(ui.professionFrame:IsShown())
end)

test("Workshop previews runic recipes and gates payment on fragment stock", function()
    local W, state = workshop()
    local ui, G = W.UI, W.Game
    state.difficulty.unlocked, state.difficulty.maxTier = true, 2
    ui:Refresh()
    local control = ui.professionControls.enchants.runicFury
    assertNotNil(control)
    click(control)
    assertFalse(ui.professionControls.commit:IsEnabled())
    state.professions.recipes.runicFury = true
    state.professions.fragments = 2
    ui:Refresh(false)
    assertFalse(ui.professionControls.commit:IsEnabled())
    state.professions.fragments = 3
    ui:Refresh(false)
    assertTrue(ui.professionControls.commit:IsEnabled())
    local essence = state.essence
    click(ui.professionControls.commit)
    assertEquals("runicFury", state.heroes[1].gear[1].enchant.id)
    assertEquals(0, state.professions.fragments)
    assertEquals(essence, state.essence)
    assertTrue(G.ValidateProfessions(state))
end)


test("Workshop shows trophy sources and farms only an earned boss checkpoint", function()
    local W, s = workshop()
    local ui = W.UI
    s.professions.components.westfall = 0
    s.runBest, s.safe.westfall = 20, 17
    ui.professionTab, ui.professionEnchant = "enchanting", "offense"
    ui:Refresh()
    assertFalse(ui.professionControls.commit:IsEnabled())
    assertNotNil(ui.professionControls.farm)
    click(ui.professionControls.farm)
    assertEquals("westfall", s.zone)
    assertEquals(15, s.stage)
    assertTrue(s.farming)
    assertEquals("adventure", s.ui.tab)
end)
