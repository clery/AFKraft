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
        if item.slot == 1 then
            assert(C.weaponNames[item.weaponType], item.name .. " is missing a weapon subclass")
        elseif item.slot ~= 4 then
            assert(C.armorRanks[item.armorType], item.name .. " is missing an armor subclass")
        end
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
case("Wearable slots have recipes and zone loot excludes retired jewelry and trinkets", function()
    local s = state()
    local hero = s.heroes[1]
    hero.level = 60
    local available = {}
    for _, slot in ipairs(C.equipmentSlots) do
        available[slot] = true
        local craft = assert(G.CraftItem(hero, slot, false))
        assert(craft.slot == slot)
        assert(G.CraftItem(hero, slot, true))
    end
    for _, pool in pairs(C.zoneItems) do
        for _, id in ipairs(pool) do
            local item = C.itemByID[id]
            assert(available[item.slot])
        end
    end
    s.legacy = 5
    assert(not G.UnlockRecipe(s, 5) and not G.UnlockRecipe(s, 6))
    assert(s.legacy == 5)
    assert(not G.CraftItem(hero, 5, true) and not G.CraftItem(hero, 6, false))
    assert(C.itemByID[2974].stats.agility == 3)
    assert(C.itemByID[13101].stats.spellPower == 13)
end)
case(
    "Excluded gear and recipes are purged from old saves without touching wearable gear",
    function()
        local s = state()
        local removedIDs = { 13094, 13095, 13097, 13002, 13085, 13096, 833 }
        for index, id in ipairs(removedIDs) do
            assert(C.itemByID[id] == nil)
            s.inventory[#s.inventory + 1] = {
                uid = 100 + index,
                itemID = id,
                slot = id == 833 and 5 or 4,
                stats = { stamina = 10 },
                count = 3,
                protected = true,
                heirloom = true,
            }
        end
        local cloak = G.Item(s, 4, 3, 2, false, C.itemByID[5111])
        cloak.count, cloak.upgrade, cloak.protected = 4, 2, true
        s.inventory[#s.inventory + 1] = cloak
        s.heroes[1].level = 60
        s.heroes[1].level = 60
        local shoulders = G.Item(s, 7, 15, 3)
        s.heroes[1].gear = {
            [4] = { uid = 200, itemID = 13097, slot = 4, stats = { strength = 8 } },
            [5] = { uid = 201, slot = 5, stats = { stamina = 2 } },
            [6] = {
                uid = 202,
                itemID = 833,
                slot = 6,
                stats = { healthRegen = 10 },
                heirloom = true,
            },
            [7] = shoulders,
        }
        s.recipes = { [4] = true, [5] = true, [6] = true, [7] = true }
        s.guide.craftItem, s.guide.craftHero = 101, 1
        G.StartBattle(s)
        local loaded = assert(G.Load(s, 1000))
        assert(#loaded.inventory == 1 and loaded.inventory[1] == cloak)
        assert(cloak.count == 4 and cloak.upgrade == 2 and cloak.protected)
        assert(
            not loaded.heroes[1].gear[4]
                and not loaded.heroes[1].gear[5]
                and not loaded.heroes[1].gear[6]
        )
        assert(loaded.heroes[1].gear[7] == shoulders)
        assert(not loaded.recipes[5] and not loaded.recipes[6])
        assert(loaded.recipes[4] and loaded.recipes[7])
        assert(not loaded.guide.craftItem and not loaded.guide.craftHero)
        assert(not loaded.battle and loaded.stats.victories == 0)
        G.StartBattle(loaded)
        local battle = loaded.battle
        assert(G.Load(loaded, 1000).battle == battle)
        assert(#loaded.inventory == 1)
    end
)
case("Classic armor proficiencies permit lighter armor and unlock only at idle level 40", function()
    local armor = { cloth = 3069, leather = 3055, mail = 4074, plate = 13067 }
    local maxima = {
        WARRIOR = { 3, 4 },
        PALADIN = { 3, 4 },
        HUNTER = { 2, 3 },
        SHAMAN = { 2, 3 },
        ROGUE = { 2, 2 },
        DRUID = { 2, 2 },
        MAGE = { 1, 1 },
        PRIEST = { 1, 1 },
        WARLOCK = { 1, 1 },
    }
    for class, limits in pairs(maxima) do
        for index, level in ipairs({ 39, 40 }) do
            local hero = { class = class, level = level }
            for kind, id in pairs(armor) do
                local item = G.Copy(C.itemByID[id])
                item.armorType = nil -- Existing saved items resolve the canonical subclass by ID.
                assert(
                    G.CanEquip(hero, item) == (C.armorRanks[kind] <= limits[index]),
                    class .. kind .. level
                )
                item.heirloom = true
                assert(G.CanEquip(hero, item) == (C.armorRanks[kind] <= limits[index]))
            end
            assert(G.CanEquip(hero, C.itemByID[5111]))
            if (class == "WARRIOR" or class == "PALADIN") and level == 40 then
                assert(G.CraftItem(hero, 2, false).armorType == "plate")
            end
            for _, slot in ipairs(C.equipmentSlots) do
                local craft = G.CraftItem(hero, slot, false)
                if craft then
                    assert(G.CanEquip(hero, craft))
                end
                local heirloom = G.CraftItem(hero, slot, true)
                if heirloom then
                    assert(G.CanEquip(hero, heirloom))
                end
            end
        end
    end
end)
case("Armor restrictions drive auto equip, upgrade retention and inventory availability", function()
    local s = state()
    local mage = s.heroes[2]
    mage.level = 39
    s.heroes[1].class = "PRIEST"
    local mail = G.Item(s, 2, 1, 3, false, C.itemByID[13123])
    local cloth = G.Item(s, 2, 1, 2, false, C.itemByID[3069])
    s.inventory = { mail, cloth }
    assert(not G.IsUpgrade(s, mail))
    local nextItem = s.nextItem
    local allowed, reason = G.Equip(s, 2, 1)
    assert(not allowed and reason:find("cannot wear Mail", 1, true))
    assert(#s.inventory == 2 and s.nextItem == nextItem)
    assert(#G.InventoryEntries(s, mage, 0, { availability = "usable" }) == 1)
    assert(#G.InventoryEntries(s, mage, 0, { availability = "locked" }) == 1)
    assert(#G.InventoryEntries(s, mage, 0, { availability = "upgrades" }) == 1)
    assert(G.EquipBest(s, 2))
    assert(mage.gear[2] == cloth and s.inventory[1] == mail)
end)
case("Incompatible saved armor returns to inventory once with enhancements intact", function()
    local s = state()
    local mage = s.heroes[2]
    local mail = G.Item(s, 2, 1, 3, true, C.itemByID[13123])
    mail.upgrade, mail.protected, mail.count = 5, true, 3
    mage.gear[2] = mail
    G.StartBattle(s)
    assert(G.Load(s, 1000))
    assert(mage.gear[2] == nil and s.inventory[1] == mail)
    assert(mail.upgrade == 5 and mail.protected and mail.count == 3)
    assert(not s.battle and s.stats.victories == 0)
    assert(G.Load(s, 1000) and #s.inventory == 1)
end)
case("Prestige unequips higher armor proficiencies until the hero reaches 40 again", function()
    local s = state()
    local hero = s.heroes[1]
    hero.class, hero.level = "HUNTER", 40
    local mail = G.Item(s, 2, 1, 3, true, C.itemByID[13123])
    hero.gear[2], s.prestigeUnlocked = mail, true
    assert(G.Prestige(s))
    assert(hero.level == 1 and not hero.gear[2] and s.inventory[1] == mail)
    assert(not G.Equip(s, 1, 1))
    hero.level = 40
    assert(G.Equip(s, 1, 1))
end)
case("Both starting zones provide wearable chest, leg and foot upgrades for every class", function()
    for _, zone in ipairs({ "elwynn", "durotar" }) do
        for _, class in ipairs(C.classes) do
            local covered = {}
            for _, id in ipairs(C.zoneItems[zone]) do
                local item = C.itemByID[id]
                if item.level == 1 and G.CanEquip({ class = class.id, level = 1 }, item) then
                    covered[item.slot] = true
                end
            end
            assert(covered[2] and covered[10] and covered[11], zone .. class.id)
        end
    end
end)
case("Every class has two usable starter weapons in both starting zones and a recipe", function()
    for _, class in ipairs(C.classes) do
        local hero = { class = class.id, level = 1 }
        for _, zone in ipairs({ "elwynn", "durotar" }) do
            local count = 0
            for _, id in ipairs(C.zoneItems[zone]) do
                local item = C.itemByID[id]
                if item.slot == 1 and G.CanEquip(hero, item) then
                    count = count + 1
                end
            end
            assert(count >= 2, zone .. class.id)
        end
        for _, heirloom in ipairs({ false, true }) do
            local craft = assert(G.CraftItem(hero, 1, heirloom))
            assert(G.CanEquip(hero, craft), class.id)
        end
    end
end)
case("Weapon proficiencies distinguish classes and one-handed from two-handed weapons", function()
    local allowed = {
        WARRIOR = { 2092, 13045, 12989, 25, 35, 36, 37, 1455, 13043 },
        PALADIN = { 13045, 12989, 25, 36, 37, 1455, 13043 },
        HUNTER = { 2092, 2509, 12989, 25, 35, 37, 1455, 13043, 13022, 13040 },
        ROGUE = { 2092, 25, 36 },
        PRIEST = { 2092, 11287, 35, 36 },
        SHAMAN = { 2092, 13045, 35, 36, 37, 1455 },
        MAGE = { 2092, 11287, 25, 35 },
        WARLOCK = { 2092, 11287, 25, 35 },
        DRUID = { 2092, 13045, 35, 36 },
    }
    for class, ids in pairs(allowed) do
        local expected = {}
        for _, id in ipairs(ids) do
            expected[G.ItemWeaponType(C.itemByID[id])] = true
        end
        for _, source in ipairs(C.items) do
            if source.slot == 1 then
                local item = G.Copy(source)
                item.weaponType = nil -- Saved items resolve their canonical type by ID.
                local hero = { class = class, level = 60 }
                assert(
                    G.CanEquip(hero, item) == (expected[source.weaponType] == true),
                    class .. source.name
                )
                item.heirloom = true
                hero.level = 1
                assert(G.CanEquip(hero, item) == (expected[source.weaponType] == true))
            end
        end
    end
end)
case("Weapon restrictions drive equip, filters, upgrades and saved gear recovery", function()
    local s = state()
    local mage = s.heroes[2]
    s.heroes[1].class = "PRIEST"
    local axe = G.Item(s, 1, 1, 3, true, C.itemByID[13015])
    local staff = G.Item(s, 1, 1, 1, false, C.itemByID[35])
    s.inventory = { axe, staff }
    assert(not G.IsUpgrade(s, axe))
    local equipped, reason = G.Equip(s, 2, 1)
    assert(not equipped and reason:find("cannot use", 1, true))
    assert(G.ItemDescription(axe, mage):find("cannot use", 1, true))
    assert(#G.InventoryEntries(s, mage, 1, { availability = "usable" }) == 1)
    assert(#G.InventoryEntries(s, mage, 1, { availability = "locked" }) == 1)
    assert(G.EquipBest(s, 2) and mage.gear[1] == staff)
    s.inventory = {}
    axe.upgrade, axe.protected, axe.count = 5, true, 3
    mage.gear[1] = axe
    G.StartBattle(s)
    assert(G.Load(s, 1000))
    assert(not mage.gear[1] and s.inventory[1] == axe and not s.battle)
    assert(axe.upgrade == 5 and axe.protected and axe.count == 3 and axe.heirloom)
    assert(G.Load(s, 1000) and #s.inventory == 1)
end)
case("Melee companions return saved ranged weapons intact and cannot re-equip them", function()
    for _, class in ipairs({ "WARRIOR", "ROGUE" }) do
        local s = G.New(0)
        G.AddHero(s, class)
        local weapon = G.Item(s, 1, 1, 1, false, C.itemByID[2509])
        weapon.upgrade, weapon.protected = 3, true
        s.heroes[1].gear[1] = weapon
        G.StartBattle(s)
        local loaded = assert(G.Load(s, 0))
        assert(not loaded.heroes[1].gear[1] and not loaded.battle)
        assert(loaded.inventory[1] == weapon and weapon.upgrade == 3 and weapon.protected)
        assert(not G.Equip(loaded, 1, 1))
        assert(G.EquipBest(loaded, 1) and not loaded.heroes[1].gear[1])
    end
end)

case("Every progression band offers multiple usable weapons for every class", function()
    local bands = {
        elwynn = 1,
        durotar = 1,
        westfall = 5,
        barrens = 5,
        redridge = 7,
        ashenvale = 7,
        duskwood = 9,
        wetlands = 9,
        stranglethorn = 11,
        desolace = 11,
        tanaris = 13,
        winterspring = 15,
    }
    for zone, level in pairs(bands) do
        for _, class in ipairs(C.classes) do
            local hero, count = { class = class.id, level = level }, 0
            for _, id in ipairs(C.zoneItems[zone]) do
                local item = C.itemByID[id]
                if item.slot == 1 and G.CanEquip(hero, item) then
                    count = count + 1
                end
            end
            assert(count >= 2, zone .. " lacks weapon choices for " .. class.id)
            assert(G.CanEquip(hero, assert(G.CraftItem(hero, 1, false))))
        end
    end
end)
case("Role equipment retains source stats and reaches loot, crafting and tooltips", function()
    assert(C.itemByID[13000].stats.intellect == 25)
    assert(C.itemByID[13045].stats.attackPower == 34)
    assert(C.itemByID[15048].stats.intellect == 28)
    assert(C.itemByID[15059].stats.healingPower == 26)
    assert(C.itemByID[15062].stats.attackPower == 46)
    local found = {}
    for _, pool in pairs(C.zoneItems) do
        local seen = {}
        for _, id in ipairs(pool) do
            assert(not seen[id], "Duplicate loot weight for " .. id)
            seen[id], found[id] = true, true
        end
    end
    for _, item in ipairs(C.items) do
        assert(found[item.itemID], item.name .. " is unavailable as loot")
        if item.note then
            local saved = G.Copy(item)
            saved.note = nil -- Canonical notes also cover previously saved copies.
            assert(G.ItemDescription(saved):find(item.note, 1, true))
        end
    end
    for _, class in ipairs(C.classes) do
        local hero = { class = class.id, level = 60 }
        for _, slot in ipairs(C.equipmentSlots) do
            for _, heirloom in ipairs({ false, true }) do
                local crafted = assert(G.CraftItem(hero, slot, heirloom))
                assert(G.CanEquip(hero, crafted), class.id .. slot)
            end
        end
    end
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
case("Class main stats match their intended archetypes and scale through progression", function()
    local expected = {
        WARRIOR = "strength",
        PALADIN = "strength",
        HUNTER = "agility",
        ROGUE = "agility",
        PRIEST = "intellect",
        SHAMAN = "intellect",
        MAGE = "intellect",
        WARLOCK = "intellect",
        DRUID = "intellect",
    }
    for class, main in pairs(expected) do
        assert(C.primaryStats[class] == main, class)
        for _, level in ipairs({ 1, 20, 60 }) do
            local s = state()
            local hero = s.heroes[1]
            hero.class, hero.level = class, level
            local base = G.Stats(s, hero)
            local item = { stats = { [main] = 10 }, itemID = 1455 }
            hero.gear = { item }
            local power = G.ItemPower(item, hero)
            assert(math.abs(G.Stats(s, hero).damage - base.damage - 10) < 0.000001, class)
            item.upgrade = 3
            assert(math.abs(G.Stats(s, hero).damage - base.damage - 13) < 0.000001, class)
            assert(G.ItemPower(item, hero) > power, class)
            item.heirloom = true
            local mainAmount = 13 * level / C.itemByID[1455].level
            assert(math.abs(G.ItemStats(item, hero)[main] - mainAmount) < 0.000001, class)
            assert(math.abs(G.Stats(s, hero).damage - base.damage - mainAmount) < 0.000001, class)
            s.prestigeStrength = 25
            assert(
                math.abs(G.Stats(s, hero).damage - (base.damage + mainAmount) * 2) < 0.000001,
                class
            )
        end
    end
end)
case("Every class has several main-stat drops in each progression pool", function()
    local bands = {
        elwynn = 3,
        durotar = 3,
        westfall = 5,
        barrens = 5,
        redridge = 7,
        ashenvale = 7,
        duskwood = 9,
        wetlands = 9,
        stranglethorn = 11,
        desolace = 11,
        tanaris = 13,
        winterspring = 15,
    }
    for zone, level in pairs(bands) do
        for _, class in ipairs(C.classes) do
            local hero = { class = class.id, level = level }
            local count, slots = 0, {}
            for _, id in ipairs(C.zoneItems[zone]) do
                local item = C.itemByID[id]
                if G.CanEquip(hero, item) and (item.stats[C.primaryStats[class.id]] or 0) > 0 then
                    count = count + 1
                    slots[item.slot] = true
                end
            end
            local slotCount = 0
            for _ in pairs(slots) do
                slotCount = slotCount + 1
            end
            assert(
                count >= 2 and slotCount >= 2,
                zone .. " lacks main-stat choices for " .. class.id
            )
        end
    end
end)
case("Every class scores its main stat and offensive bonuses by their combat effects", function()
    for _, class in ipairs(C.classes) do
        local s = state()
        local hero = s.heroes[1]
        hero.class = class.id
        local base = G.Stats(s, hero)
        local main = C.primaryStats[class.id]
        for _, key in ipairs({ "strength", "agility", "intellect", "attackPower", "spellPower" }) do
            local item = { stats = { [key] = 10 } }
            hero.gear = { item }
            local stats = G.Stats(s, hero)
            if key == main then
                assert(stats.damage == base.damage + 10, class.id)
                assert(G.ItemPower(item, hero) >= 15, class.id)
            elseif key == "attackPower" then
                assert((stats.damage > base.damage) == (main ~= "intellect"), class.id)
            elseif key == "spellPower" then
                assert(
                    (stats.damage > base.damage) == (main == "intellect" or class.role == "hybrid"),
                    class.id
                )
            else
                assert(stats.damage == base.damage, class.id)
                assert(G.ItemPower(item, hero) < G.ItemPower({ stats = { [main] = 10 } }, hero))
            end
        end
    end
end)
case("Healing and secondary gear changes its stated effect rather than base damage", function()
    local s = state()
    local hero = s.heroes[1]
    hero.class = "PRIEST"
    local base = G.Stats(s, hero)
    for _, key in ipairs({ "spirit", "healingPower", "haste", "armor", "healthRegen", "stamina" }) do
        local item = { stats = { [key] = 10 } }
        hero.gear = { item }
        local stats = G.Stats(s, hero)
        assert(stats.damage == base.damage and G.ItemPower(item, hero) > 0, key)
        if key == "spirit" or key == "healingPower" then
            assert(stats.healing > base.healing, key)
        elseif key == "haste" then
            assert(stats.haste == 1.1)
        elseif key == "armor" then
            assert(stats.mitigation > base.mitigation)
        elseif key == "healthRegen" then
            assert(stats.regen == 2)
        else
            assert(stats.hp == base.hp + 100)
        end
    end
    assert(
        G.ItemPower({ stats = { spirit = 10 } }, hero)
            > G.ItemPower({ stats = { spirit = 10 } }, s.heroes[2])
    )
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
    s.essence, s.gold, s.materials.ore = 1000, 1000, 100
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
        assert(hero.gear[craft.slot].itemID == craft.item.itemID)
        assert(G.ItemPower(hero.gear[craft.slot], hero) == G.ItemPower(craft.item, hero))
        assert(hero.gear[craft.slot].uid == nextItem and s.nextItem == nextItem + 1)
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
        assert(G.CraftingOpportunity(s, 1))
        s.gold = 0
        assert(not G.CraftingOpportunity(s, 1))
    end
)

case("Ordinary crafted upgrades preserve displaced, equal and stronger gear", function()
    local s = state()
    local hero = s.heroes[2]
    s.gold, s.materials.ore = 10000, 10000
    local previous = assert(G.CraftItem(hero, 1, false, s))
    previous.stats = { weaponDPS = 0.01 }
    hero.gear[1] = previous
    assert(G.Craft(s, 2, 1, "ore", false))
    local equipped = hero.gear[1]
    assert(equipped ~= previous and s.inventory[1] == previous)
    assert(s.heroes[1].gear[1] == nil)
    assert(G.Craft(s, 2, 1, "ore", false))
    assert(hero.gear[1] == equipped and #s.inventory == 2)
    equipped.stats = { weaponDPS = 100000 }
    assert(G.Craft(s, 2, 1, "ore", false))
    assert(hero.gear[1] == equipped and #s.inventory == 3)
end)

case("Heirloom crafting rejects bag and selected-hero duplicates without payment", function()
    for _, equipped in ipairs({ false, true }) do
        local s = state()
        local hero = s.heroes[1]
        s.gold, s.materials.ore, s.recipes[1] = 10000, 10000, true
        local item = assert(G.CraftItem(hero, 1, true, s))
        item.upgrade, item.count = 5, not equipped and 2 or nil
        if equipped then
            hero.gear[1] = item
        else
            s.inventory = { item }
        end
        local gold, ore, nextItem = s.gold, s.materials.ore, s.nextItem
        local preview, reason = G.CraftItem(hero, 1, true, s)
        assert(not preview and reason == W.L.THIS_HEIRLOOM_IS_ALREADY_OWNED)
        assert(not G.Craft(s, 1, 1, "ore", true))
        assert(s.gold == gold and s.materials.ore == ore and s.nextItem == nextItem)
        assert(s.professions.xp.crafting == 0 and item.upgrade == 5)
        assert(G.CraftItem(hero, 1, false, s))
        if equipped then
            assert(G.AddHero(s, "WARRIOR"))
            assert(G.Craft(s, 3, 1, "ore", true))
        else
            s.inventory = {}
            assert(G.Craft(s, 1, 1, "ore", true))
        end
    end
end)

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

case("Crafting automatically completes equipment guidance and survives reload", function()
    local s = state()
    s.guide.crafted = nil
    s.guide.craftItem, s.guide.craftHero = "bad", -1
    assert(G.Load(s, 1000))
    assert(s.guide.crafted == false and s.guide.craftItem == nil and s.guide.craftHero == nil)
    assert(not G.Craft(s, 1, 1, "ore", false))
    assert(not s.guide.crafted)
    s.essence, s.gold, s.materials.ore = 100, 100, 100
    assert(G.Craft(s, 1, 1, "ore", false))
    local uid = s.heroes[1].gear[1].uid
    assert(#s.inventory == 0 and s.guide.equipped)
    assert(s.guide.crafted and s.guide.craftItem == nil and s.guide.craftHero == nil)
    assert(G.Load(s, 1000))
    assert(s.heroes[1].gear[1].uid == uid)
    assert(s.guide.crafted and s.guide.craftItem == nil and s.guide.craftHero == nil)
end)
case(
    "Equipment descriptions show stat gains, losses and unchanged values without source clutter",
    function()
        local s = state()
        local hero = s.heroes[1]
        hero.gear[2] = { stats = { stamina = 4, agility = 3, spirit = 2, armor = 10 } }
        local item = {
            slot = 2,
            stats = { stamina = 6, agility = 1, armor = 10 },
            itemID = 1,
            requiredLevel = 60,
        }
        local text = G.ItemDescription(item, hero, true)
        assert(text:find("|cff1eff00+6.0 Stamina (+2.0)|r", 1, true))
        assert(text:find("|cffff6060+1.0 Agility (-2.0)|r", 1, true))
        assert(text:find("|cffffffff+10.0 Armor|r", 1, true))
        assert(text:find("|cffff6060-2.0 Spirit|r", 1, true))
        assert(not text:find("Classic item", 1, true) and not text:find("WoW level", 1, true))
        hero.gear[2] = nil
        text = G.ItemDescription(item, hero, true)
        assert(text:find("|cff1eff00+6.0 Stamina (+6.0)|r", 1, true))
        assert(not text:find("Lost on equip", 1, true))
        text = G.ItemDescription(item, hero)
        assert(text:find("|cffffffff+6.0 Stamina|r", 1, true))
    end
)
return cases
