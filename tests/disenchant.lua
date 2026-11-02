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
return cases
