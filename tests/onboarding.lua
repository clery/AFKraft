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
    assertEquals(3, W.Panels.GuideStep(s))
    s.inventory[1] = W.Game.Item(s, 1, 1, 2)
    ui:Refresh()
    assertEquals(2, W.Panels.GuideStep(s))
    HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
    assertTrue(s.guide.dismissed)
    W.state = assert(W.Game.Load(s, W.Client.Now()))
    ui:Refresh(false)
    click(find(ui, "Show starter guide"))
    assertFalse(s.guide.dismissed)
    s.stats.victories = 1
    ui:Refresh(false)
    assertEquals(2, W.Panels.GuideStep(s))
    click(ui.tabs.party)
    assertEquals("party", s.ui.tab)
    assertTrue(W.Game.Equip(s, 1, 1))
    assertEquals(3, W.Panels.GuideStep(s))
    assertTrue(W.Game.Talent(s, 1, W.Game.TalentList(s.heroes[1])[1].id))
    assertTrue(W.Panels.GuideStep(s) == nil)
    s.runBest = 4
    assertEquals(4, W.Panels.GuideStep(s))
    assertTrue(W.Game.Travel(s, "durotar"))
    ui:SetTab("adventure")
    assertTrue(W.Panels.GuideStep(s) == nil)
    assertTrue(find(ui, "Dismiss guide") == nil)
    assertNotNil(find(ui, "Explore Legacy"))
    assertTrue(s.guide.equipped and s.guide.talent and s.guide.traveled)
end)

test("Starter lessons skip unavailable actions and point at live controls", function()
    local W, s, ui = opening()
    s.heroes[1].level = 1
    assertTrue(W.Game.Talent(s, 1, W.Game.TalentList(s.heroes[1])[1].id))
    s.guide.talent = false
    s.inventory[1] = W.Game.Item(s, 1, 4, 2)
    assertTrue(W.Panels.GuideStep(s) == nil)
    s.heroes[1].talents = {}
    s.heroes[1].level = 2
    assertEquals(3, W.Panels.GuideStep(s))
    ui:Refresh(false)
    assertEquals(ui.tabs.talents, ui.guideTarget)
    ui:SetTab("talents")
    assertEquals(ui.talentTrees.trees[1], ui.guideTarget)
    for path = 1, 3 do
        assertEquals(ui.talentTrees.trees[path], ui.guideTarget)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
    end
    local talent = W.Game.TalentList(s.heroes[1])[1]
    ui.talentTrees.trees[talent.path].buttons[talent.id]:GetScript("OnClick")()
    assertTrue(s.guide.talent)
    assertTrue(ui.guideTarget == nil)
    s.heroes[1].level = 4
    ui:SetTab("adventure")
    assertEquals(2, W.Panels.GuideStep(s))
    click(ui.tabs.party)
    ui.bagFilter = 6
    ui:Refresh()
    assertEquals(ui.guideInventoryTarget, ui.guideTarget)
    click(ui.guideInventoryTarget)
    assertNotNil(ui.guideEquipTarget)
    assertEquals(ui.guideEquipTarget, ui.guideTarget)
    ui.guideEquipTarget:GetScript("OnClick")()
    assertTrue(s.guide.equipped)
    s.runBest = 4
    ui:SetTab("atlas")
    assertEquals(4, W.Panels.GuideStep(s))
    local targetMap
    for _, map in ipairs(ui.atlas.maps) do
        if W.Client.ZonePosition(ui.atlas.focus.id, map.id) then
            targetMap = map
        end
    end
    assertNotNil(targetMap)
    assertEquals(targetMap, ui.guideTarget)
    assertTrue(ui.atlas.focus.level > W.Content.zoneByID[s.zone].level)
    assertTrue(W.Game.IsUnlocked(s, ui.atlas.focus))
end)

test(
    "Native tutorial hides in compact mode and when closed, and survives ordinary refreshes",
    function()
        local _, s, ui = opening()
        assertTrue(HelpTip:IsShowing(ui.guideOwner, ui.guideTip.text))
        local info = ui.guideTip
        ui:Refresh(false)
        assertEquals(info, ui.guideTip)
        ui:SetTab("talents")
        assertEquals(1, ui.guideTree)
        s.ui.compact = true
        ui:ApplyMode()
        assertTrue(ui.guideTip == nil)
        s.ui.compact = false
        ui:ApplyMode()
        assertNotNil(ui.guideTip)
        ui.frame:Hide()
        assertTrue(ui.guideTip == nil)
        ui.frame:Show()
        assertNotNil(ui.guideTip)
    end
)

test(
    "Crafting lesson waits for an upgrade and follows mode, slot, material, craft and equip",
    function()
        local W, s, ui = opening()
        s.guide.equipped, s.guide.talent, s.guide.traveled = true, true, true
        ui:Refresh(false)
        assertTrue(ui.guideTip == nil)
        s.essence, s.gold, s.materials.timber = 100, 100, 100
        ui:Refresh(false)
        assertEquals(5, W.Panels.GuideStep(s, ui.selected))
        assertEquals(ui.tabs.crafting, ui.guideTarget)
        ui.craftHeirloom, ui.craftSlot, ui.craftMaterial = true, 6, "ore"
        click(ui.tabs.crafting)
        assertEquals(ui.craftControls.ordinary, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(ui.craftControls.slots[1], ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(ui.craftControls.materials.timber, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(ui.craftControls.craft, ui.guideTarget)
        click(ui.guideTarget)
        assertTrue(s.guide.crafted)
        local uid = s.guide.craftItem
        assertEquals(6, W.Panels.GuideStep(s, ui.selected))
        assertEquals(ui.tabs.party, ui.guideTarget)
        W.state = assert(W.Game.Load(s, W.Client.Now()))
        ui.bagFilter = 6
        click(ui.tabs.party)
        assertEquals(ui.guideInventoryTarget, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(ui.guideCraftEquipTarget, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(uid, s.heroes[1].gear[1].uid)
        assertTrue(s.guide.craftItem == nil)
        assertTrue(ui.guideTip == nil)
        assertTrue(W.Panels.GuideStep(s, ui.selected) == nil)
    end
)
