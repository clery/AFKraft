if not test then
    return
end

local function opening()
    local W = WoWIdle
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    W.state = s
    W.UI.selected, W.UI.recruiting = 1, false
    W.UI.frame:Show()
    W.UI:SetTab("adventure")
    return W, s, W.UI
end

local function find(ui, label)
    for _, kind in ipairs({ "button", "primary" }) do
        local pool = ui.panel._pool[kind]
        if pool then
            for button in pool:EnumerateActive() do
                if button.text and button.text:GetText() == label then
                    return button
                end
                if button._pool and button._pool.text then
                    for text in button._pool.text:EnumerateActive() do
                        if text:GetText() == label then
                            return button
                        end
                    end
                end
            end
        end
    end
end

local function click(button)
    assertNotNil(button)
    button:GetScript("OnClick")(button)
end

test(
    "Undiscovered companions explain their milestones and discoveries recruit only one hero",
    function()
        local W, s, ui = opening()
        assertEquals(1, #s.heroes)
        assertEquals("Milestone boss level 1", ui.cards[2].detail:GetText())
        assertTrue(ui.tabs.party.notice:GetText() ~= "Recruit")
        click(ui.cards[2])
        assertNotNil(find(ui, "Back to equipment"))
        assertTrue(find(ui, "Priest") == nil)
        assertEquals(1, #s.heroes)
        s.best = 2
        ui:SetTab("adventure")
        assertEquals("Recruit", ui.tabs.party.notice:GetText())
        click(find(ui, "Recruit companions"))
        click(find(ui, "Priest"))
        assertEquals(2, #s.heroes)
        assertEquals("PRIEST", s.heroes[2].class)
        assertFalse(ui.recruiting)
        assertFalse(W.Game.Recruit(s, "MAGE"))
        assertEquals("Milestone boss level 3", ui.cards[3].detail:GetText())
    end
)

test("Starter guide can be dismissed and reopened without losing completed lessons", function()
    local W, s, ui = opening()
    assertEquals(1, W.Panels.GuideStep(s))
    click(find(ui, "Dismiss guide"))
    assertTrue(s.guide.dismissed)
    W.state = assert(W.Game.Load(s, W.Client.Now()))
    ui:Refresh(false)
    click(find(ui, "Show starter guide"))
    assertFalse(s.guide.dismissed)
    s.stats.victories = 1
    ui:Refresh(false)
    assertEquals(2, W.Panels.GuideStep(s))
    click(find(ui, "Equip rewards"))
    assertEquals("party", s.ui.tab)
    s.inventory[1] = W.Game.Item(s, 1, 1, 2)
    assertTrue(W.Game.Equip(s, 1, 1))
    assertEquals(3, W.Panels.GuideStep(s))
    assertTrue(W.Game.Talent(s, 1, W.Game.TalentList(s.heroes[1])[1].id))
    assertEquals(4, W.Panels.GuideStep(s))
    assertTrue(W.Game.Travel(s, "durotar"))
    ui:SetTab("adventure")
    assertTrue(W.Panels.GuideStep(s) == nil)
    assertTrue(find(ui, "Dismiss guide") == nil)
    assertNotNil(find(ui, "Explore Legacy"))
    assertTrue(s.guide.equipped and s.guide.talent and s.guide.traveled)
end)
