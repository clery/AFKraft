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
    W.UI.selected = 1
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
    "Expanded talent trees scroll to the eighth row and keep learn/refund controls usable",
    function()
        local W, state, ui = setup()
        local hero = state.heroes[1]
        for _, node in ipairs(W.Game.TalentList(hero)) do
            if node.path == 1 and node.column == 2 and node.row < 8 then
                assert(W.Game.Talent(state, 1, node.id))
            end
        end
        ui:Refresh()
        local tree = ui.talentTrees.trees[1]
        tree.scroll:GetScript("OnMouseWheel")(tree.scroll, -100)
        assert(tree.scroll:GetVerticalScroll() == tree.canvas:GetHeight() - tree.scroll:GetHeight())
        local node = tree.buttons.warrior_1_16
        node:GetScript("OnEnter")(node)
        assert(GameTooltip:IsOwned(node))
        local points = W.Game.Points(hero)
        node:GetScript("OnClick")(node)
        assert(hero.talents.warrior_1_16 and W.Game.Points(hero) == points - 1)
        node:GetScript("OnClick")(node)
        assert(not hero.talents.warrior_1_16 and W.Game.Points(hero) == points)
        assert(node.label:GetWidth() <= 158)
    end
)
