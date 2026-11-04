if not test then
    return
end

local register = test
local function test(name, run)
    register(name, function()
        -- Native HelpTips honor this client preference; isolate the test fixture.
        local hidden = GetCVar("hideHelptips")
        SetCVar("hideHelptips", 0)
        local ok, message = pcall(run)
        SetCVar("hideHelptips", hidden)
        assert(ok, message)
    end)
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
    for _, kind in ipairs({ "button", "primary", "selection" }) do
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

local function advanced()
    local W, s, ui = opening()
    s.guide.equipped, s.guide.talent, s.guide.traveled, s.guide.crafted = true, true, true, true
    return W, s, ui
end

test(
    "Milestone lessons acknowledge individually and retain progress after reload and resets",
    function()
        local W, s, ui = advanced()
        local G = W.Game
        assertTrue(W.Tutorial.NextLesson(s) == nil)
        s.essence = 30
        ui:Refresh(false)
        assertEquals("lessonBoost", W.Tutorial.NextLesson(s).key)
        assertEquals(ui.tabs.boosts, ui.guideTarget)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonBoost)
        assertFalse(s.guide.dismissed)
        assertTrue(G.BuyBoost(s, "battleOrders"))
        s.legacy, s.prestigeUnlocked, s.prestiges = 3, true, 1
        assertEquals("lessonAutomation", W.Tutorial.NextLesson(s).key)
        ui:Refresh(false)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonAutomation)
        assertTrue(G.BuyBoostAutomation(s, "onCooldown"))
        assertEquals("lessonProfiles", W.Tutorial.NextLesson(s).key)
        ui:Refresh(false)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonProfiles)
        assertEquals("lessonRoutes", W.Tutorial.NextLesson(s).key)
        ui:Refresh(false)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonRoutes)
        s.collectionBook.pieces[1930] = 0
        assertEquals("lessonCollections", W.Tutorial.NextLesson(s).key)
        ui:Refresh(false)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonCollections)
        s = assert(G.Load(G.Copy(s), W.Client.Now()))
        W.state = s
        s.runBest = 9
        assertTrue(G.Prestige(s))
        assertTrue(G.ResetAdventure(s, true))
        assertTrue(
            s.guide.lessonBoost
                and s.guide.lessonAutomation
                and s.guide.lessonProfiles
                and s.guide.lessonRoutes
                and s.guide.lessonCollections
        )
        assertFalse(s.guide.lessonPrestigePlus)
    end
)

test(
    "Later lessons follow permanent hero milestones and respect guide and client preferences",
    function()
        local W, s, ui = advanced()
        local G, h = W.Game, s.heroes[1]
        local function acknowledge(key)
            assertEquals(key, W.Tutorial.NextLesson(s).key)
            ui:Refresh(false)
            HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
            assertTrue(s.guide[key])
        end
        h.level, h.rank = 20, 4
        G.TalentProgress(h)
        acknowledge("lessonMastery")
        h.level, h.rank = 30, 7
        G.TalentProgress(h)
        acknowledge("lessonEnchanting")
        h.level, h.rank = 40, 9
        G.TalentProgress(h)
        acknowledge("lessonTitanforging")
        h.level, h.rank = 50, 12
        G.TalentProgress(h)
        acknowledge("lessonResearch")
        s.difficulty.unlocked, s.difficulty.maxTier = true, 1
        assertEquals("lessonPrestigePlus", W.Tutorial.NextLesson(s).key)
        s.guide.dismissed = true
        ui:Refresh(false)
        assertTrue(ui.guideTip == nil)
        click(find(ui, "Show guide"))
        assertEquals(ui.tabs.difficulty, ui.guideTarget)
        click(find(ui, "Hide guide"))
        assertTrue(ui.guideTip == nil)
        assertFalse(s.guide.lessonPrestigePlus)
        s.guide.dismissed = false
        SetCVar("hideHelptips", 1)
        ui:Refresh(false)
        assertTrue(ui.guideTip == nil)
        assertFalse(s.guide.lessonPrestigePlus)
        SetCVar("hideHelptips", 0)
        acknowledge("lessonPrestigePlus")
        assertTrue(W.Tutorial.NextLesson(s) == nil)
    end
)

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
    click(find(ui, "Show guide"))
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
    assertNotNil(find(ui, "Explore Heritage"))
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
    ui.bagFilter = 7
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
        ui.bagFilter = 7
        click(ui.tabs.party)
        assertEquals(ui.guideInventoryTarget, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(ui.guideCraftEquipTarget, ui.guideTarget)
        click(ui.guideTarget)
        assertEquals(uid, s.heroes[1].gear[1].uid)
        assertTrue(s.guide.craftItem == nil)
        assertTrue(W.Panels.GuideStep(s, ui.selected) == nil)
        local nextLesson = W.Tutorial.NextLesson(s)
        assertNotNil(nextLesson)
        assertEquals(nextLesson.message, ui.guideTip.text)
        assertEquals(ui.tabs[nextLesson.tab], ui.guideTarget)
    end
)

test("First hunt lesson waits for verified sources and retains its acknowledgement", function()
    local W, s, ui = advanced()
    for key in pairs(s.guide) do
        if key:find("^lesson") then
            s.guide[key] = true
        end
    end
    s.guide.lessonHunt = false
    s.adventure.rank, s.adventure.totalXP = 2, 100
    assertTrue(W.Tutorial.NextLesson(s) == nil)
    local original = W.CollectionSources.ActiveProfile
    W.CollectionSources.ActiveProfile = function()
        return { sources = { [4701] = { verified = true } } }
    end
    local ok, message = pcall(function()
        assertEquals("lessonHunt", W.Tutorial.NextLesson(s).key)
        ui:Refresh()
        assertEquals(ui.tabs.collections, ui.guideTarget)
        HelpTip:Acknowledge(ui.guideOwner, ui.guideTip.text)
        assertTrue(s.guide.lessonHunt)
        assertTrue(W.Tutorial.NextLesson(s) == nil)
        local loaded = assert(W.Game.Load(W.Game.Copy(s), W.Client.Now()))
        assertTrue(loaded.guide.lessonHunt)
    end)
    W.CollectionSources.ActiveProfile = original
    assertTrue(ok, message)
end)


test("A stalled company can review prestige before sixty without resetting from the advice", function()
    local W, s, ui = advanced()
    local G = W.Game
    for _, class in ipairs({ "PRIEST", "MAGE", "ROGUE", "SHAMAN" }) do
        assertTrue(G.AddHero(s, class))
    end
    for index, hero in ipairs(s.heroes) do
        assertTrue(G.Talent(s, index, G.TalentList(hero)[1].id))
    end
    s.best, s.runBest, s.farming, s.prestigeUnlocked = 12, 12, true, true
    s.guide.dismissed = true
    ui:SetTab("adventure")
    assertNotNil(find(ui, "Review prestige"))
    click(find(ui, "Review prestige"))
    assertEquals("legacy", s.ui.tab)
    assertEquals(0, s.prestiges)
    assertEquals(0, s.legacy)
    assertEquals(12, s.runBest)
end)
