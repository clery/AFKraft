-- Pure Lua specifications; consumed by scripts/test.lua, not loaded by the addon.
local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}

local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

local function equal(a, b)
    assert(a == b, tostring(a) .. " ~= " .. tostring(b))
end

local function party()
    local s = G.New(1000)
    for _, id in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "DRUID" }) do
        assert(G.AddHero(s, id))
    end
    return s
end
case("Content uses unique stable IDs and valid references", function()
    local ids = {}
    for _, z in ipairs(C.zones) do
        assert(not ids[z.id])
        ids[z.id] = true
        assert(C.materials[z.material])
        assert(C.biomes[z.biome])
        equal(
            C.backdrops[z.id],
            "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\" .. z.id .. ".tga"
        )
        assert(#z.enemies > 0)
    end
    equal(C.slots[5], false)
    equal(C.slots[6], false)
    equal(#C.equipmentSlots, 10)
    equal(#C.classes, 9)
end)
case("Classic outdoor roster supports travel, combat, loot and saved destinations", function()
    equal(#C.zones, 41)
    for _, id in ipairs({
        "dun_morogh",
        "teldrassil",
        "mulgore",
        "tirisfal",
        "loch_modan",
        "darkshore",
        "silverpine",
        "stonetalon",
        "hillsbrad",
        "thousand_needles",
        "alterac",
        "arathi",
        "badlands",
        "swamp_sorrows",
        "dustwallow",
        "feralas",
        "hinterlands",
        "azshara",
        "searing_gorge",
        "blasted_lands",
        "felwood",
        "ungoro",
        "burning_steppes",
        "western_plaguelands",
        "deadwind",
        "eastern_plaguelands",
        "silithus",
        "moonglade",
        "blackrock_mountain",
    }) do
        assert(C.zoneByID[id], id)
    end
    for _, zone in ipairs(C.zones) do
        local state = party()
        state.runBest = zone.unlockLevel
        assert(G.Travel(state, zone.id))
        equal(state.zone, zone.id)
        assert(G.ZoneLoot(state, zone.level))
        state.rest, state.stage = 0, 1
        G.StartBattle(state)
        assert(#state.battle.enemies > 0)
        local names = {}
        for _, name in ipairs(zone.enemies) do
            names[name] = true
        end
        for _, enemy in ipairs(state.battle.enemies) do
            assert(names[enemy.name], zone.id)
        end
        state.battle, state.rest, state.stage = nil, 0, 5
        G.StartBattle(state)
        equal(state.battle.enemies[1].name, zone.boss)
        equal(assert(G.Load(G.Copy(state), 1000)).zone, zone.id)
    end
end)
case("Party allows duplicates but never a sixth hero", function()
    local s = G.New(0)
    for _ = 1, 5 do
        assert(G.AddHero(s, "MAGE"))
    end
    assert(not G.AddHero(s, "WARRIOR"))
    equal(#s.heroes, 5)
end)
case("Alts replace only same-class generated heroes", function()
    local s = party()
    s.heroes[1].level = 4
    assert(not G.Replace(s, 1, { name = "Alt", class = "MAGE", guid = "alt" }))
    assert(G.Replace(s, 1, { name = "Alt", class = "WARRIOR", guid = "alt" }))
    equal(s.heroes[1].level, 4)
    equal(s.heroes[1].name, "Alt")
    assert(not G.Replace(s, 1, { name = "Other", class = "WARRIOR", guid = "other" }))
end)

case("Mid-fight recruits join the next encounter without duplicating rewards", function()
    local state = G.New(1000)
    G.AddHero(state, "WARRIOR")
    G.AddHero(state, "WARRIOR")
    G.StartBattle(state)
    for _, classID in ipairs({ "PRIEST", "MAGE", "DRUID" }) do
        assert(G.AddHero(state, classID))
    end
    equal(#state.battle.heroes, 2)
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(state, 0.25)
    equal(state.gold, 5)
    equal(state.stats.victories, 1)
    equal(state.heroes[1].xp, 11)
    equal(state.heroes[2].xp, 11)
    for i = 3, 5 do
        equal(state.heroes[i].xp, 0)
        equal(state.heroes[i].health, 1)
    end
    G.Advance(state, 2.25)
    equal(#state.battle.heroes, 5)
    equal(state.gold, 5)
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(state, 0.25)
    equal(state.gold, 10)
    equal(state.stats.victories, 2)
    equal(state.heroes[1].xp, 22)
    equal(state.heroes[3].xp, 11)
end)

case("Victory level-up events identify only heroes that gained a level", function()
    local state = party()
    state.heroes[2].xp = 44
    G.StartBattle(state)
    state.events = {}
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(state, 0.25)
    local count = 0
    for _, event in ipairs(state.events) do
        if event.kind == "levelup" then
            equal(event.target, 2)
            count = count + 1
        end
    end
    equal(count, 1)
    equal(state.heroes[2].level, 2)
end)

case("Interrupted victory saves recover without replaying partial rewards", function()
    local state = party()
    G.StartBattle(state)
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    state.gold = 55
    state.essence = 80
    state.heroes[1].xp = 11
    state.pauseAfter = true
    local loaded = assert(G.Load(state, 1000))
    assert(not loaded.battle)
    assert(not loaded.paused)
    equal(#loaded.heroes, 5)
    equal(loaded.gold, 55)
    equal(loaded.essence, 80)
    equal(loaded.heroes[1].xp, 11)
    G.Step(loaded, 0.25)
    equal(loaded.gold, 55)
end)

case("Missing participants cannot partially commit victory rewards", function()
    local state = party()
    G.StartBattle(state)
    state.heroes[5] = nil
    for _, enemy in ipairs(state.battle.enemies) do
        enemy.hp = 0
    end
    G.Step(state, 0.25)
    assert(not state.battle)
    equal(state.gold, 0)
    equal(state.stats.victories, 0)
    equal(state.heroes[1].xp, 0)
end)

case("Same seed and commands produce identical battles", function()
    local a, b = party(), party()
    G.Advance(a, 120)
    G.Advance(b, 120)
    equal(a.gold, b.gold)
    equal(a.seed, b.seed)
    equal(a.stats.kills, b.stats.kills)
    equal(a.stage, b.stage)
    assert(a.stats.victories > 0)
end)
case("Natural experience passes the retired training gates without Essence", function()
    local s = party()
    G.Advance(s, 3600)
    assert(s.heroes[1].level > 4 and s.heroes[1].level <= 60)
    equal(s.essence, 0)
    local level, xp = G.ExperienceResult(s.heroes[1], 1000000)
    equal(level, 60)
    assert(xp < 60 * 45)
    local gold, experience = s.gold, s.heroes[1].xp
    assert(not G.Train(s, 1))
    equal(s.gold, gold)
    equal(s.heroes[1].xp, experience)
    equal(G.LevelCap(s.heroes[1]), 60)
end)
case("Talent and priority changes are free during active encounters", function()
    local s = party()
    s.essence = 12
    assert(G.Talent(s, 1, "guard"))
    equal(s.essence, 12)
    assert(G.Talent(s, 1, "guard"))
    equal(G.Points(s.heroes[1]), 1)
    G.StartBattle(s)
    assert(G.Talent(s, 1, "guard"))
    assert(G.Configure(s, 1, "healBelow", 40))
    s.battle = nil
    assert(G.Configure(s, 1, "healBelow", 40))
    equal(s.heroes[1].healBelow, 40)
    assert(not G.Configure(s, 1, "class", "MAGE"))
end)
case("Equipment changes update a live fight without healing or resetting cooldowns", function()
    local s = party()
    s.essence, s.gold, s.materials.ore = 1000, 1000, 100
    G.StartBattle(s)
    local unit = s.battle.heroes[1]
    unit.hp, unit.cd, unit.attackCD = unit.maxHP * 0.4, 4, 1.5
    local before = unit.damage
    s.inventory[1] = G.Item(s, 1, 1, 3)
    assert(G.Equip(s, 1, 1))
    assert(unit.damage > before)
    assert(math.abs(unit.hp / unit.maxHP - 0.4) < 0.0001)
    equal(unit.cd, 4)
    equal(unit.attackCD, 1.5)
    assert(G.Upgrade(s, 1, 1))
    assert(not G.Train(s, 1))
    assert(G.Talent(s, 1, "guard"))
    assert(G.Configure(s, 1, "priority", "attack"))
    equal(unit.cd, 4)
end)

case("Travel cancels combat without rewards and preserves health", function()
    local s = party()
    G.StartBattle(s)
    local battle = s.battle
    battle.heroes[1].hp = battle.heroes[1].maxHP * 0.35
    assert(G.Travel(s, "elwynn"))
    equal(s.battle, battle)
    assert(not G.Travel(s, "winterspring"))
    equal(s.battle, battle)
    assert(G.Travel(s, "durotar"))
    assert(not s.battle)
    equal(s.zone, "durotar")
    equal(s.gold, 0)
    equal(s.stats.victories, 0)
    assert(math.abs(s.heroes[1].health - 0.35) < 0.0001)
    G.Step(s, 0.25)
    assert(s.battle)
end)

case("Inventory sorts by effective power with stable ties and original indices", function()
    local s = party()
    s.heroes[1].level, s.heroes[1].rank = 12, 3
    s.inventory =
        { G.Item(s, 1, 1, 1), G.Item(s, 1, 5, 3), G.Item(s, 1, 1, 3, true), G.Item(s, 1, 5, 3) }
    s.inventory[3].upgrade = 20
    local entries = G.InventoryEntries(s, s.heroes[1], 1)
    equal(entries[1].index, 3)
    equal(entries[2].index, 2)
    equal(entries[3].index, 4)
    equal(entries[4].index, 1)
    for _, entry in ipairs(entries) do
        equal(s.inventory[entry.index], entry.item)
    end
end)

case("Inventory combines hero requirements, quality, slot and trait filters", function()
    local s = party()
    local hero = s.heroes[1]
    hero.level = 4
    local usable = G.Item(s, 1, 3, 3)
    local locked = G.Item(s, 1, 9, 3)
    local legacy = G.Item(s, 2, 9, 3, true)
    usable.protected, usable.upgrade, usable.quality, usable.effect = true, 1, 3, "renewal"
    s.inventory = { usable, locked, legacy, G.Item(s, 1, 2, 1) }
    equal(#G.InventoryEntries(s, hero, 0, { availability = "usable" }), 3)
    equal(G.InventoryEntries(s, hero, 0, { availability = "locked" })[1].item, locked)
    equal(#G.InventoryEntries(s, hero, 1, { availability = "usable", quality = 3 }), 1)
    for _, trait in ipairs({ "protected", "upgraded", "effect" }) do
        equal(
            G.InventoryEntries(s, hero, 1, { availability = "usable", trait = trait })[1].item,
            usable
        )
    end
    equal(G.InventoryEntries(s, hero, 0, { trait = "heirloom" })[1].item, legacy)
    hero.gear[1] = usable
    local upgrades = G.InventoryEntries(s, hero, 1, { availability = "upgrades" })
    equal(#upgrades, 0)
    equal(#s.inventory, 4)
end)

case("Inventory sorting supports both directions without changing equip indices", function()
    local s = party()
    s.inventory = { G.Item(s, 2, 3, 1), G.Item(s, 1, 6, 3), G.Item(s, 3, 2, 2) }
    for _, sort in ipairs({ "power", "level", "quality", "slot", "name" }) do
        for _, ascending in ipairs({ true, false }) do
            local entries =
                G.InventoryEntries(s, s.heroes[1], 0, { sort = sort, ascending = ascending })
            for i, entry in ipairs(entries) do
                equal(s.inventory[entry.index], entry.item)
                if i > 1 then
                    local previous = entries[i - 1]
                    local a = sort == "power" and previous.power or previous.item[sort]
                    local b = sort == "power" and entry.power or entry.item[sort]
                    assert((ascending and a <= b) or (not ascending and a >= b))
                end
            end
        end
    end
end)

case("Auto equip selects usable effective power and preserves stacks and other heroes", function()
    local s = party()
    local hero = s.heroes[1]
    hero.level = 4
    local old = G.Item(s, 1, 1, 1)
    hero.gear[1] = old
    local stacked = G.Item(s, 1, 4, 3)
    stacked.count = 3
    local locked = G.Item(s, 2, 5, 4)
    local upgraded = G.Item(s, 2, 1, 1)
    upgraded.upgrade = 10
    local heirloom = G.Item(s, 3, 99, 1, true)
    heirloom.stats = { stamina = 1000 }
    local tied = G.Item(s, 4, 1, 2)
    hero.gear[4] = G.Copy(tied)
    local current = hero.gear[4]
    s.heroes[2].gear[1] = G.Item(s, 1, 4, 4)
    local other = s.heroes[2].gear[1]
    s.inventory = { stacked, locked, upgraded, heirloom, tied, G.Item(s, 3, 1, 1) }
    G.StartBattle(s)
    local unit = s.battle.heroes[1]
    unit.hp, unit.cd = unit.maxHP * 0.4, 3
    assert(G.EquipBest(s, 1))
    equal(G.ItemPower(hero.gear[1], hero), G.ItemPower(stacked, hero))
    equal(stacked.count, 2)
    assert(hero.gear[1].uid ~= stacked.uid)
    equal(hero.gear[2], upgraded)
    equal(hero.gear[3], heirloom)
    equal(hero.gear[4], current)
    equal(hero.gear[5], nil)
    equal(s.heroes[2].gear[1], other)
    local foundOld, foundLocked = false, false
    for _, item in ipairs(s.inventory) do
        foundOld = foundOld or item == old
        foundLocked = foundLocked or item == locked
    end
    assert(foundOld and foundLocked)
    assert(math.abs(unit.hp / unit.maxHP - 0.4) < 0.0001)
    equal(unit.cd, 3)
    local nextItem, count = s.nextItem, #s.inventory
    assert(G.EquipBest(s, 1))
    equal(s.nextItem, nextItem)
    equal(#s.inventory, count)
    assert(not G.EquipBest(s, 99))
end)

case("Auto equip handles an empty inventory", function()
    local s = party()
    assert(G.EquipBest(s, 1))
    equal(next(s.heroes[1].gear), nil)
end)

case("Adventure XP arriving during offline catch-up is retained once", function()
    local s = party()
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 1010))
    assert(G.ActivityReward(s, "gather:live", "gather", "Mining"))
    while not G.CatchupBatch(job, 100) do
    end
    local expected = job.state.heroes[1].xp
    G.FinishCatchup(s, job)
    equal(s.heroes[1].xp, expected)
    equal(s.adventure.totalXP, 4)
    equal(s.adventure.xp, 4)
    equal(s.essence, 0)
end)

case("Priority healing selects the injured ally", function()
    local s = party()
    s.heroes[1].health = 0.2
    G.StartBattle(s)
    local before = s.battle.heroes[1].hp
    G.Step(s, 0.25)
    assert(s.battle.heroes[1].hp > before)
end)
case("Defeat automatically falls back without gear loss", function()
    local s = party()
    local item = G.Item(s, 1, 1, 3)
    s.heroes[1].gear[1] = item
    s.safe.elwynn = 2
    s.stage = 100
    G.StartBattle(s)
    for _, h in ipairs(s.battle.heroes) do
        h.hp = 0
    end
    G.Step(s, 0.25)
    assert(s.farming)
    equal(s.stage, 2)
    equal(s.heroes[1].gear[1], item)
end)
case("Locked destinations cannot be selected", function()
    local s = party()
    assert(not G.Travel(s, "winterspring"))
    equal(s.zone, "elwynn")
    s.runBest = C.zoneByID.winterspring.unlockLevel
    assert(G.Travel(s, "winterspring"))
    equal(s.zone, "winterspring")
end)
case("Crafting is atomic when resources are insufficient", function()
    local s = party()
    s.gold = 100
    s.materials.ore = 0
    local gold = s.gold
    assert(not G.Craft(s, 1, 1, "ore", false))
    equal(s.gold, gold)
    equal(#s.inventory, 0)
    s.materials.ore = 50
    assert(G.Craft(s, 1, 1, "ore", false))
    equal(s.essence, 0)
    equal(#s.inventory, 1)
    assert(s.gold < gold)
end)
case("Equipment swaps preserve the previous item", function()
    local s = party()
    local a = G.Item(s, 1, 1, 2)
    local b = G.Item(s, 1, 1, 3)
    s.heroes[1].gear[1] = a
    s.inventory = { b }
    assert(G.Equip(s, 1, 1))
    equal(s.inventory[1], a)
    equal(s.heroes[1].gear[1], b)
end)

case("Duplicate drops stack and equipping consumes exactly one", function()
    local state = party()
    for _ = 1, 100 do
        G.Loot(state, G.Item(state, 1, 1, 2))
    end
    equal(#state.inventory, 1)
    equal(state.inventory[1].count, 100)
    assert(G.Equip(state, 1, 1))
    equal(state.inventory[1].count, 99)
    assert(state.heroes[1].gear[1].count == nil)
    assert(state.heroes[1].gear[1].uid ~= state.inventory[1].uid)
end)

case("Catch-up preserves real-world rewards delivered during reconciliation", function()
    local state = party()
    state.safe.elwynn = 1
    local job = G.BeginCatchup(state, 1120)
    G.Reward(state, "quest:live", 12, "Quest")
    state.discoveries["boss:live"] = true
    while not G.CatchupBatch(job, 100) do
    end
    G.FinishCatchup(state, job)
    equal(state.essence, 12)
    equal(state.stats.essence, 12)
    assert(state.discoveries["boss:live"])
end)
case("Salvage rules retain protected, new-effect, and upgrade loot", function()
    local s = party()
    s.salvage.minQuality = 4
    local protected = G.Item(s, 1, 1, 1)
    protected.protected = true
    G.Loot(s, protected)
    equal(#s.inventory, 1)
    s.salvage.keepUpgrades = false
    local effectItem = G.Item(s, 2, 1, 3)
    effectItem.effect = "renewal"
    G.Loot(s, effectItem)
    equal(#s.inventory, 2)
    G.Loot(s, G.Copy(effectItem))
    equal(s.stats.salvaged, 1)
    local heirloom = G.Item(s, 3, 1, 1, true)
    assert(not G.Salvage(s, heirloom))
end)
case("Prestige retains Essence, discoveries, and heirlooms", function()
    local s = party()
    s.prestigeUnlocked = true
    s.runBest = 9
    s.essence = 222
    s.gold = 900
    s.materials.ore = 12
    s.discoveries.test = true
    s.recipes[1] = true
    local heirloom = G.Item(s, 1, 1, 3, true)
    s.heroes[1].gear[1] = heirloom
    s.heroes[1].gear[2] = G.Item(s, 2, 1, 3)
    s.heroes[1].level = 10
    s.heroes[1].rank = 3
    s.inventory = { G.Item(s, 3, 1, 3), G.Item(s, 4, 1, 3, true) }
    local before = G.ItemPower(heirloom, s.heroes[1])
    assert(G.Prestige(s))
    equal(s.essence, 222)
    equal(s.gold, 0)
    equal(s.materials.ore, 0)
    equal(s.heroes[1].rank, 0)
    assert(s.discoveries.test and s.recipes[1])
    equal(s.heroes[1].gear[1], heirloom)
    assert(not s.heroes[1].gear[2])
    equal(#s.inventory, 1)
    assert(G.ItemPower(heirloom, s.heroes[1]) < before)
end)
case("Empty resets never grant power or Legacy", function()
    local s = party()
    s.prestigeUnlocked = true
    assert(G.Prestige(s))
    assert(G.Prestige(s))
    equal(s.prestiges, 0)
    equal(s.legacy, 0)
end)
case("Duplicate real-world reward sources grant once", function()
    local s = party()
    assert(G.Reward(s, "kill:unit", 1, "Kill"))
    assert(not G.Reward(s, "kill:unit", 1, "Kill"))
    equal(s.essence, 1)
end)
case("Unknown save versions are preserved instead of reset", function()
    local db = { version = 999, essence = 800 }
    local s, message = G.Load(db, 1000)
    assert(not s and message)
    equal(db.essence, 800)
end)
case("Malformed save fields are rejected without discarding progression", function()
    local state = party()
    state.essence = 800
    state.heroes = "invalid"
    local loaded, message = G.Load(state, 1000)
    assert(not loaded and message)
    equal(state.essence, 800)
end)

case("Offline rewards are capped and require a safe encounter", function()
    local s = party()
    assert(not G.BeginCatchup(s, 2000))
    s.lastTime = 1000
    s.safe.elwynn = 1
    local job = G.BeginCatchup(s, 1000 + 86400 * 3)
    equal(job.seconds, 86400)
    equal(job.remaining, 345600)
end)
case("Offline and visible farming use identical combat rules", function()
    local s = party()
    s.safe.elwynn = 1
    s.stage = 1
    s.farming = true
    local visible = G.Copy(s)
    visible.rest = 0
    G.Advance(visible, 120)
    local job = G.BeginCatchup(s, 1120)
    while not G.CatchupBatch(job, 100) do
    end
    G.FinishCatchup(s, job)
    equal(s.gold, visible.gold)
    equal(s.seed, visible.seed)
    equal(s.stats.victories, visible.stats.victories)
    equal(s.heroes[1].level, visible.heroes[1].level)
    equal(s.runBest, 1)
    assert(not G.BeginCatchup(s, 1120))
end)
case("Clock rollback does not mint catch-up earnings", function()
    local s = party()
    s.safe.elwynn = 1
    assert(not G.BeginCatchup(s, 900))
    equal(s.lastTime, 1000)
    assert(not G.BeginCatchup(s, 1000))
end)
case("Interrupted catch-up preserves remaining earning time", function()
    local s = party()
    s.safe.elwynn = 1
    local job = G.BeginCatchup(s, 1120)
    G.CatchupBatch(job, 40)
    G.FinishCatchup(s, job)
    equal(s.lastTime, 1010)
    local resumed = G.BeginCatchup(s, 1120)
    equal(resumed.seconds, 110)
end)
case("Milestone logs notify once while routine XP stays quiet", function()
    local notices = {}
    W.OnLog = function(_, message)
        notices[#notices + 1] = message
    end
    local ok, message = pcall(function()
        local s = party()
        notices = {}
        G.AdventureXP(s, 1, "test", "Test")
        equal(#notices, 0)
        s.heroes[1].level, s.heroes[1].xp = 59, 2654
        s.heroes[1].mastery.frontier = 100
        s.heroes[1].mastery.frontiers[0] = 100
        G.StartBattle(s)
        for _, enemy in ipairs(s.battle.enemies) do
            enemy.hp = 0
        end
        G.Step(s, 0.25)
        equal(#notices, 1)
        assert(notices[1]:find("maximum", 1, true))
        s.rest, s.stage = 0, 25
        G.StartBattle(s)
        s.battle.enemies[1].hp = 0
        G.Step(s, 0.25)
        equal(#notices, 2)
        assert(notices[2]:find(C.zoneByID[s.zone].name, 1, true))
        s.rest, s.stage, s.farming = 0, 25, true
        G.StartBattle(s)
        s.battle.enemies[1].hp = 0
        G.Step(s, 0.25)
        equal(#notices, 2)
        -- A previously unvisited destination can have an already surpassed boss milestone.
        s.zone, s.rest, s.stage, s.farming = "durotar", 0, 5, false
        s.runBest = 7
        G.StartBattle(s)
        s.battle.enemies[1].hp = 0
        local victories, gold = s.stats.victories, s.gold
        G.Step(s, 0.25)
        equal(#notices, 2)
        equal(s.stats.victories, victories + 1)
        assert(s.gold > gold)
        equal(s.safe.durotar, 5)
        s.rest, s.stage = 0, 55
        G.StartBattle(s)
        s.battle.enemies[1].hp = 0
        G.Step(s, 0.25)
        equal(#notices, 3)
        assert(notices[3]:find(C.zoneByID[s.zone].name, 1, true))
    end)
    W.OnLog = nil
    assert(ok, message)
end)

case("Offline level caps remain in the final adventure log", function()
    local s = party()
    s.safe.elwynn = 1
    s.heroes[1].level, s.heroes[1].xp = 59, 2654
    local job = assert(G.BeginCatchup(s, 1120))
    while not G.CatchupBatch(job, 100) do
    end
    G.FinishCatchup(s, job)
    equal(s.heroes[1].level, 60)
    local count = 0
    for _, message in ipairs(s.log) do
        if
            message:find(
                s.heroes[1].name .. " reached idle level 60 (character maximum) while you were away",
                1,
                true
            )
        then
            count = count + 1
        end
    end
    equal(count, 1)
end)
case("Optional settings migrate safely and retain disabled preferences", function()
    local s = party()
    s.settings = nil
    s.ui.fullscreen = false
    s.salvage.minQuality = 3
    local loaded = assert(G.Load(s, 1000))
    equal(loaded.settings.chatAnnouncements, true)
    equal(loaded.settings.combatText, true)
    equal(loaded.ui.fullscreen, false)
    equal(loaded.salvage.minQuality, 3)
    loaded.settings.chatAnnouncements = false
    loaded.settings.combatText = false
    loaded = assert(G.Load(loaded, 1000))
    equal(loaded.settings.chatAnnouncements, false)
    equal(loaded.settings.combatText, false)
    loaded.settings.combatText = "invalid"
    equal(assert(G.Load(loaded, 1000)).settings.combatText, true)
end)

case("Defeat feedback distinguishes a living-party timeout from a wipe", function()
    local function encounter()
        local state = G.New(1000)
        assert(G.AddHero(state, "WARRIOR"))
        G.StartBattle(state)
        for _, unit in ipairs(state.battle.heroes) do
            unit.cd, unit.attackCD = 100, 100
        end
        for _, enemy in ipairs(state.battle.enemies) do
            enemy.attackCD = 100
        end
        return state
    end
    local timeout = encounter()
    timeout.battle.elapsed = 179.75
    G.Step(timeout, 0.25)
    assert(timeout.lastDefeat:find("timed out", 1, true))
    assert(timeout.lastDefeat:find("100% health", 1, true))
    assert(timeout.lastDefeat:find("Improve damage", 1, true))
    assert(timeout.farming and not timeout.battle and timeout.stats.victories == 0)
    local wipe = encounter()
    wipe.battle.heroes[1].hp = 0
    G.Step(wipe, 0.25)
    assert(wipe.lastDefeat:find("All companions fell", 1, true))
    assert(wipe.lastDefeat:find("Improve survival", 1, true))
    assert(not wipe.lastDefeat:find("timed out", 1, true))
    assert(wipe.farming and not wipe.battle and wipe.stats.victories == 0)
end)

return cases
