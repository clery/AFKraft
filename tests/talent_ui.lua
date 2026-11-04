if not test then
    return
end

local function setup()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    W.Game.AddHero(state, "HUNTER")
    state.paused, state.guide.dismissed = true, true
    state.heroes[1].level = 48
    W.state = state
    W.UI.selected, W.UI.recruiting, W.UI.disenchantOpen = 1, false, false
    W.UI.frame:Show()
    W.UI:SetTab("talents")
    return W, state, W.UI
end

test("Switching classes refreshes icons on buttons with shared legacy talent IDs", function()
    local W, _, ui = setup()
    local button = ui.talentTrees.trees[1].buttons.cleave
    local warriorTexture = button.icon:GetTexture()
    ui.selected = 2
    ui:Refresh()
    local expected = ui.frame:CreateTexture(nil, "ARTWORK")
    expected:SetTexture("Interface\\Icons\\" .. W.Content.talentByClassID.HUNTER.cleave.icon)
    assert(button.icon:GetTexture() == expected:GetTexture())
    assert(button.icon:GetTexture() ~= warriorTexture)
    expected:Hide()
    ui.selected = 1
    ui:Refresh()
    assert(button.icon:GetTexture() == warriorTexture)
end)

test(
    "Expanded talent trees scroll to the ninth row and keep learn/refund controls usable",
    function()
        local W, state, ui = setup()
        local hero = state.heroes[1]
        for _, node in ipairs(W.Game.TalentList(hero)) do
            if node.path == 1 and node.column == 2 and node.row < 9 then
                assert(W.Game.Talent(state, 1, node.id))
            end
        end
        ui:Refresh()
        local tree = ui.talentTrees.trees[1]
        tree.scroll:GetScript("OnMouseWheel")(tree.scroll, -100)
        assert(tree.scroll:GetVerticalScroll() == tree.canvas:GetHeight() - tree.scroll:GetHeight())
        local node = tree.buttons.warrior_1_18
        node:GetScript("OnEnter")(node)
        assert(GameTooltip:IsOwned(node))
        local points = W.Game.Points(hero)
        node:GetScript("OnClick")(node)
        assert(hero.talents.warrior_1_18 and W.Game.Points(hero) == points - 1)
        node:GetScript("OnClick")(node)
        assert(not hero.talents.warrior_1_18 and W.Game.Points(hero) == points)
        assert(node.label:GetWidth() <= 158)
    end
)

test(
    "Mastery appears at level 20 and remains visible with its XP after ordinary prestige",
    function()
        local W, state, ui = setup()
        local hero = state.heroes[1]
        -- Use a new hero record to exercise the unlock, rather than the setup's level-48 record.
        hero.level, hero.rank, hero.talentProgress = 19, 4, nil
        ui:Refresh()
        local bar = ui.talentTrees.mastery
        assert(bar.label:GetText():find("unlocks at hero level 20", 1, true))
        assert(bar:GetValue() == 0)
        hero.level = 20
        W.Game.RewardMastery(hero, 20, 300, false)
        ui:Refresh()
        assert(bar.label:GetText():find("Mastery 2", 1, true))
        assert(bar:GetValue() == 0.25)
        state.prestigeUnlocked, state.runBest = true, 21
        assert(W.Game.Prestige(state))
        ui:Refresh()
        assert(hero.level == 1 and bar:GetValue() == 0.25)
        assert(bar.label:GetText():find("Mastery 2", 1, true))
    end
)

test(
    "Party growth stays natural and the development control remains available at level sixty",
    function()
        local _, state, ui = setup()
        state.heroes[1].level, state.heroes[1].rank = 60, 14
        state.gold, state.essence = 100000, 100000
        ui:SetTab("party")
        assert(not ui.cards[1].detail:GetText():find("Train to grow", 1, true))
        local found
        for _, kind in ipairs({ "button", "primary", "selection" }) do
            local pool = ui.panel._pool[kind]
            if pool then
                for button in pool:EnumerateActive() do
                    assert(not button.text:GetText():find("Train:", 1, true))
                    if button.text:GetText() == "Party development" then
                        assert(
                            button:IsEnabled(),
                            "Permanent development remains available at level 60"
                        )
                        found = button
                    end
                end
            end
        end
        assert(found, "Missing party development control")
        found:GetScript("OnClick")()
        assertEquals("development", state.ui.tab)
        assertEquals(100000, state.essence)
    end
)

test("Hero target selection changes configuration without resetting active combat", function()
    local W, state, ui = setup()
    W.Game.StartBattle(state)
    local unit = state.battle.heroes[1]
    local hp, cd = unit.hp, unit.cd
    local original, chooseTarget = W.Widgets.Choice, nil
    W.Widgets.Choice = function(parent, label, x, y, width, options, value, choose)
        local control = original(parent, label, x, y, width, options, value, choose)
        if options == W.Content.targetModes then
            chooseTarget = choose
        end
        return control
    end
    local ok, message = pcall(function()
        ui:Refresh()
        assertNotNil(ui.heroTargetChoice)
        assertTrue(ui.heroTargetChoice:IsEnabled())
        assert(chooseTarget)("weakest")
        assertEquals("weakest", state.heroes[1].targetMode)
        assertEquals(hp, unit.hp)
        assertEquals(cd, unit.cd)
    end)
    W.Widgets.Choice = original
    assertTrue(ok, message)
end)
