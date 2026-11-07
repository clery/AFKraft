local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Disenchant consumes a stored stack exactly once and preserves Essence", function()
    local s = G.New(0)
    local item = G.Item(s, 1, 3, 2)
    item.count = 10
    s.inventory = { item }
    s.guide.craftItem, s.guide.craftHero = item.uid, 1
    local reward = G.DisenchantReward(item)
    local gold, dust, essence = s.gold, s.materials.relic, s.essence
    assert(G.Disenchant(s, item))
    assert(#s.inventory == 0)
    assert(s.gold == gold + reward.gold and s.materials.relic == dust + reward.relic)
    assert(s.essence == essence and s.stats.salvaged == 10)
    assert(not s.guide.craftItem and not s.guide.craftHero)
    assert(not G.Disenchant(s, item))
    assert(s.gold == gold + reward.gold)
end)

case("Disenchant refuses protected, heirloom, equipped and stale items", function()
    local s = G.New(0)
    local item = G.Item(s, 1, 1, 2)
    s.inventory = { item }
    item.protected = true
    assert(not G.Disenchant(s, item))
    item.protected, item.heirloom = nil, true
    assert(not G.Disenchant(s, item))
    item.heirloom = nil
    local stale = G.Copy(item)
    assert(not G.Disenchant(s, stale))
    assert(#s.inventory == 1 and s.stats.salvaged == 0)
    G.AddHero(s, "WARRIOR")
    s.heroes[1].gear[1], s.inventory = item, {}
    assert(not G.Disenchant(s, item))
    assert(s.heroes[1].gear[1] == item)
end)

case("Disenchant rewards cannot repay the gold cost of crafting", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    local hero = s.heroes[1]
    for _, level in ipairs({ 1, 20, 40, 60 }) do
        hero.level = level
        local cost = G.Cost(s, hero, false)
        for _, slot in ipairs(W.Content.equipmentSlots) do
            local item = G.CraftItem(hero, slot, false)
            if item then
                local reward = G.DisenchantReward(item)
                assert(reward.gold < cost.gold and reward.relic < cost.material)
            end
        end
    end
end)

case("Disenchant rejects invalid counts without changing state", function()
    local s = G.New(0)
    local item = G.Item(s, 1, 1, 2)
    s.inventory = { item }
    for _, count in ipairs({ 0, -1, 0.5, "2" }) do
        item.count = count
        assert(not G.Disenchant(s, item))
    end
    assert(#s.inventory == 1 and s.stats.salvaged == 0)
end)
case("Disenchant quantities clamp to the stack and retain identities and guide targets", function()
    for _, quantity in ipairs({ 1, 10, 100 }) do
        local s = G.New(0)
        local item = G.Item(s, 1, 3, 2)
        item.count = 150
        s.inventory = { item }
        s.guide.craftItem, s.guide.craftHero = item.uid, 1
        local reward = G.DisenchantReward(item, quantity)
        assert(reward.count == quantity)
        assert(G.Disenchant(s, item, quantity))
        assert(item.count == 150 - quantity and s.inventory[1] == item)
        assert(s.guide.craftItem == item.uid and s.guide.craftHero == 1)
        assert(s.gold == reward.gold and s.materials.relic == reward.relic)
        assert(s.stats.salvaged == quantity)
        local loaded = G.Load(G.Copy(s), 0)
        assert(loaded.inventory[1].count == item.count)
        assert(loaded.materials.relic == reward.relic)
    end
    local s = G.New(0)
    local item = G.Item(s, 1, 1, 2)
    item.count = 4
    s.inventory = { item }
    assert(G.DisenchantReward(item, 100).count == 4)
    assert(not G.Disenchant(s, item, 5))
    assert(item.count == 4)
    assert(G.Disenchant(s, item, 100))
    assert(#s.inventory == 0 and s.stats.salvaged == 4)
end)

case("Disenchant all skips protected and heirloom stacks and awards exactly once", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    local item, protected, heirloom =
        G.Item(s, 1, 1, 2), G.Item(s, 1, 1, 2), G.Item(s, 1, 1, 2, true)
    item.count, protected.protected = 120, true
    local equipped = G.Item(s, 1, 1, 2)
    s.heroes[1].gear[1] = equipped
    s.inventory = { protected, item, heirloom, G.Item(s, 2, 1, 2) }
    s.guide.craftItem, s.guide.craftHero = item.uid, 1
    local total = G.DisenchantAllReward(s)
    assert(total.count == 121)
    assert(#s.inventory == 4 and s.gold == 0)
    assert(G.DisenchantAll(s))
    assert(#s.inventory == 2 and s.inventory[1] == protected and s.inventory[2] == heirloom)
    assert(s.heroes[1].gear[1] == equipped and s.essence == 0)
    assert(not s.guide.craftItem)
    assert(s.gold == total.gold and s.materials.relic == total.relic)
    assert(s.stats.salvaged == total.count)
    assert(not G.DisenchantAll(s))
    assert(s.gold == total.gold)
end)

case("Bulk disenchant retains inventory identity, survivor order and invalid items", function()
    local s = G.New(0)
    local inventory, survivors = s.inventory, {}
    for i = 1, 30 do
        local item = G.Item(s, 2, 1, 2)
        inventory[i] = item
        if i % 3 == 0 then
            item.protected = true
            survivors[#survivors + 1] = item
        elseif i % 5 == 0 then
            item.count = 0
            survivors[#survivors + 1] = item
        end
    end
    s.guide.craftItem, s.guide.craftHero = survivors[1].uid, 1
    local total = G.DisenchantAllReward(s)
    assert(G.DisenchantAll(s))
    assert(s.inventory == inventory and #inventory == #survivors)
    for i, item in ipairs(survivors) do
        assert(inventory[i] == item)
    end
    assert(s.gold == total.gold and s.materials.relic == total.relic)
    assert(s.guide.craftItem == survivors[1].uid and s.guide.craftHero == 1)
    assert(not G.DisenchantAll(s))
    assert(s.gold == total.gold and #inventory == #survivors)
end)

return cases
