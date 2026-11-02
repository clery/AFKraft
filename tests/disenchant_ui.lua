if not test then
    return
end

test("Loot disenchant previews rewards, protects stacks, and removes the chosen item", function()
    local W = WoWIdle
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.paused = true
    local item = W.Game.Item(s, 1, 1, 2)
    item.count = 4
    s.inventory = { item }
    W.state = s
    local ui = W.UI
    ui.selected = 1
    ui.frame:Show()
    ui:SetTab("loot")
    local function find(label)
        for b in ui.panel._pool.button:EnumerateActive() do
            if b.text:GetText() == label then
                return b
            end
        end
        error("Missing button: " .. label)
    end
    local protect = find("Protect")
    protect:GetScript("OnClick")(protect)
    assertFalse(find("Disenchant stack"):IsEnabled())
    local unprotect = find("Unprotect")
    unprotect:GetScript("OnClick")(unprotect)
    local reward = W.Game.DisenchantReward(item)
    local destroy = find("Disenchant stack")
    assertTrue(destroy:IsEnabled())
    destroy:GetScript("OnClick")(destroy)
    assertEquals(0, #s.inventory)
    assertEquals(reward.gold, s.gold)
    assertEquals(reward.relic, s.materials.relic)
    assertEquals(4, s.stats.salvaged)
end)
