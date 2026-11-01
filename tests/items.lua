local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function state()
    local s = G.New(1000)
    G.AddHero(s, "WARRIOR")
    G.AddHero(s, "MAGE")
    return s
end
case("Catalog identities, source stats and zone references are complete", function()
    local seen = {}
    for _, item in ipairs(C.items) do
        assert(not seen[item.itemID])
        seen[item.itemID] = true
        assert(item.icon and item.name and next(item.stats))
        assert(item.level >= 1 and C.slots[item.slot] and C.qualityNames[item.quality])
        for key, value in pairs(item.stats) do
            assert(C.itemStatNames[key] and value >= 0)
        end
    end
    for _, zone in ipairs(C.zones) do
        assert(#C.zoneItems[zone.id] > 0)
        local s = state()
        s.zone = zone.id
        assert(G.ZoneLoot(s, zone.level), "No starting loot in " .. zone.id)
        for _, id in ipairs(C.zoneItems[zone.id]) do
            assert(C.itemByID[id])
        end
    end
    assert(C.itemByID[821].stats.agility == 1 and C.itemByID[821].stats.stamina == 2)
    assert(C.itemByID[1455].stats.strength == 8)
end)
case("Zone drops retain catalog stats, requirements and deterministic identity", function()
    local s = state()
    s.zone = "redridge"
    local other = G.Copy(s)
    for _ = 1, 100 do
        local item, twin = G.ZoneLoot(s, 20), G.ZoneLoot(other, 20)
        local source = C.itemByID[item.itemID]
        assert(item.itemID == twin.itemID and item.uid == twin.uid)
        assert(item.level == source.level and item.quality == source.quality)
        assert(item.power == nil and G.SameItem(item, source))
        item.stats.strength = 999
        assert(source.stats.strength ~= 999)
    end
end)
case("Power follows stats and class instead of item level or rarity", function()
    local s = state()
    local item = { stats = { strength = 10 }, level = 1, quality = 1 }
    local warrior, mage = s.heroes[1], s.heroes[2]
    assert(G.ItemPower(item, warrior) > G.ItemPower(item, mage))
    local power = G.ItemPower(item, warrior)
    item.level, item.quality, item.power = 99, 4, 99999
    assert(G.ItemPower(item, warrior) == power)
    item.stats.strength = 20
    assert(G.ItemPower(item, warrior) == power * 2)
    item.stats = { intellect = 20 }
    assert(G.ItemPower(item, mage) > G.ItemPower(item, warrior))
end)
case("Ordinary source stats stay fixed and upgrades preview the exact result", function()
    local s = state()
    local hero = s.heroes[1]
    local item = G.Item(s, 1, 5, 3)
    hero.gear[1] = item
    local power = G.ItemPower(item, hero)
    hero.level = 20
    assert(G.ItemPower(item, hero) == power)
    local quote = G.ItemPower(item, hero, 1)
    s.essence, s.gold = 1000, 1000
    assert(G.Upgrade(s, 1, 1))
    assert(G.ItemPower(item, hero) == quote)
    local source = C.itemByID[item.itemID]
    assert(item.stats.weaponDPS == source.stats.weaponDPS)
    assert(G.ItemStats(item, hero).weaponDPS == source.stats.weaponDPS * 1.1)
end)
case("Different real items and different stat rolls cannot merge", function()
    local s = state()
    local a = G.Item(s, 1, 1, 1, false, C.itemByID[25])
    local b = G.Item(s, 1, 1, 1, false, C.itemByID[36])
    G.Loot(s, a)
    G.Loot(s, b)
    assert(#s.inventory == 2)
    local roll = G.Copy(a)
    roll.stats.agility = 1
    G.Loot(s, roll)
    assert(#s.inventory == 3)
    G.Loot(s, G.Copy(a))
    assert(#s.inventory == 3 and a.count == 2)
end)
case("Attributes affect combat and haste changes both timer recoveries", function()
    local s = state()
    local hero = s.heroes[1]
    local before = G.Stats(s, hero)
    hero.gear[2] =
        { stats = { stamina = 5, armor = 100, strength = 10, haste = 25, healthRegen = 10 } }
    local after = G.Stats(s, hero)
    assert(after.hp == before.hp + 50 and after.damage > before.damage)
    assert(after.mitigation > 0 and after.haste == 1.25 and after.regen == 2)
    G.StartBattle(s)
    local unit = s.battle.heroes[1]
    unit.cd, unit.attackCD, unit.hp = 4, 2, unit.maxHP - 10
    G.Step(s, 0.25)
    assert(unit.cd == 3.6875 and unit.attackCD == 1.6875)
    assert(unit.hp == unit.maxHP - 9.5)
end)
case("Old saved equipment migrates once without losing stacks or upgrades", function()
    local s = state()
    s.itemStatsVersion = nil
    local item = {
        uid = 123,
        slot = 2,
        name = "Protected old armor",
        level = 3,
        quality = 3,
        power = 14,
        upgrade = 4,
        count = 7,
        protected = true,
        effect = "renewal",
    }
    s.inventory = { item }
    s.heroes[1].gear[1] =
        { uid = 124, slot = 1, name = "Old weapon", level = 1, quality = 2, power = 8 }
    s.nextItem = 125
    G.StartBattle(s)
    local loaded = assert(G.Load(s, 1000))
    assert(loaded.inventory[1] == item and item.count == 7 and item.upgrade == 4 and item.protected)
    assert(
        item.uid == 123
            and item.power == nil
            and item.stats.stamina > 0
            and item.effect == "renewal"
    )
    assert(loaded.nextItem == 125 and loaded.itemStatsVersion == 1 and not loaded.battle)
    local stats = item.stats
    G.StartBattle(loaded)
    local battle = loaded.battle
    assert(G.Load(loaded, 1000))
    assert(item.stats == stats and loaded.battle == battle)
end)
case("Nonfinite and negative item stats cannot poison derived power", function()
    local s = state()
    local item =
        { stats = { strength = 0 / 0, agility = -1, stamina = math.huge, intellect = "bad" } }
    assert(G.ItemPower(item, s.heroes[1]) == 0)
end)
case("Unavailable low-level crafting slots do not spend resources or identities", function()
    local s = state()
    s.essence, s.gold, s.materials.ore = 1000, 1000, 1000
    local nextItem = s.nextItem
    assert(not G.Craft(s, 1, 5, "ore", false))
    assert(s.essence == 1000 and s.gold == 1000 and s.materials.ore == 1000)
    assert(s.nextItem == nextItem and #s.inventory == 0)
end)
case(
    "Useful crafting previews match the result without spending resources or identities",
    function()
        local s = state()
        local hero = s.heroes[1]
        assert(not G.CraftingOpportunity(s, 1))
        s.essence, s.gold, s.materials.timber = 100, 100, 100
        local nextItem, seed = s.nextItem, s.seed
        local craft = assert(G.CraftingOpportunity(s, 1))
        assert(craft.slot == 1 and craft.material == "timber" and not craft.heirloom)
        assert(G.CraftingOpportunity(s, 1))
        assert(s.nextItem == nextItem and s.seed == seed and #s.inventory == 0)
        assert(s.essence == 100 and s.gold == 100 and s.materials.timber == 100)
        assert(not G.CraftItem(hero, 5, false))
        assert(G.Craft(s, 1, craft.slot, craft.material, craft.heirloom))
        assert(s.inventory[1].itemID == craft.item.itemID)
        assert(G.ItemPower(s.inventory[1], hero) == G.ItemPower(craft.item, hero))
        assert(s.inventory[1].uid == nextItem and s.nextItem == nextItem + 1)
    end
)

case(
    "Crafting opportunities skip equal equipped or stored gear and respect the selected hero",
    function()
        local s = state()
        local hero = s.heroes[1]
        s.essence, s.gold, s.materials.ore = 1000, 1000, 1000
        for slot = 1, #C.slots do
            hero.gear[slot] = G.CraftItem(hero, slot, false)
        end
        assert(not G.CraftingOpportunity(s, 1))
        assert(G.CraftingOpportunity(s, 2))
        for slot, item in pairs(hero.gear) do
            s.inventory[#s.inventory + 1] = item
            hero.gear[slot] = nil
        end
        assert(not G.CraftingOpportunity(s, 1))
        s.inventory = {}
        assert(G.CraftingOpportunity(s, 1))
        s.essence = 0
        assert(not G.CraftingOpportunity(s, 1))
    end
)

case("Heirloom crafting guidance requires a known recipe and its exact affordable cost", function()
    local s = state()
    s.heroes[1].level = 30
    s.essence, s.gold, s.materials.hide = 45, 30, 12
    assert(not G.CraftingOpportunity(s, 1))
    s.recipes[1] = true
    local craft = assert(G.CraftingOpportunity(s, 1))
    assert(craft.heirloom and craft.slot == 1 and craft.material == "hide")
    s.materials.hide = 11
    assert(not G.CraftingOpportunity(s, 1))
end)

case("Crafting lesson progress and the exact reward survive reload until equipped", function()
    local s = state()
    s.guide.crafted = nil
    s.guide.craftItem, s.guide.craftHero = "bad", -1
    assert(G.Load(s, 1000))
    assert(s.guide.crafted == false and s.guide.craftItem == nil and s.guide.craftHero == nil)
    assert(not G.Craft(s, 1, 1, "ore", false))
    assert(not s.guide.crafted)
    s.essence, s.gold, s.materials.ore = 100, 100, 100
    assert(G.Craft(s, 1, 1, "ore", false))
    local uid = s.inventory[1].uid
    assert(s.guide.crafted and s.guide.craftItem == uid and s.guide.craftHero == 1)
    assert(G.Load(s, 1000))
    assert(s.guide.crafted and s.guide.craftItem == uid)
    assert(G.Equip(s, 1, 1))
    assert(s.heroes[1].gear[1].uid == uid)
    assert(s.guide.crafted and s.guide.craftItem == nil and s.guide.craftHero == nil)
end)
return cases
