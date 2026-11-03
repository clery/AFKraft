local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
case("Family material profiles preserve base output and cap shared secondary spoils", function()
    local zone = { material = "hide" }
    local result = G.EncounterMaterials(zone, {
        enemies = {
            { family = "humanoid" },
            { family = "mechanical" },
            { family = "elemental" },
            { family = "unknown" },
        },
    })
    assert(result.hide == 1)
    assert(result.timber == 0.0625 and result.ore == 0.0625 and result.relic == 0.0625)
    local boss = G.EncounterMaterials(zone, { boss = true, enemies = { { family = "beast" } } })
    assert(boss.hide == 6.25)
    local empty = G.EncounterMaterials(zone, { enemies = {} })
    assert(empty.hide == 1 and next(empty, "hide") == nil)
end)
case("Untagged encounters retain existing zone materials without guessed family loot", function()
    local result = G.EncounterMaterials({ material = "ore" }, { enemies = { {}, {} } })
    assert(result.ore == 1)
    local total = 0
    for _, amount in pairs(result) do
        total = total + amount
    end
    assert(total == 1)
end)
case("Family spoils survive fractional reconciliation with equal offline results", function()
    local state = G.New(1000)
    assert(G.AddHero(state, "MAGE"))
    state.zone, state.safe.westfall, state.farming = "westfall", 3, true
    state.heroes[1].level = 30
    G.TalentProgress(state.heroes[1])
    local job = assert(G.BeginCatchup(state, 1120))
    local online = G.Copy(job.state)
    online.offline, online.offlineRoute = nil, nil
    G.Advance(online, 120)
    while not G.CatchupBatch(job, 31) do
    end
    for _, material in ipairs(W.Content.materialOrder) do
        assert(job.state.materials[material] == online.materials[material])
        assert(job.state.materialRemainders[material] == online.materialRemainders[material])
    end
    assert(job.state.materials.ore > 0 and job.state.materials.relic > 0)
    assert(job.state.adventure.totalXP == 0 and job.state.essence == 0)
end)
case("Every destination has aligned explicit family profiles with bounded yields", function()
    for _, zone in ipairs(W.Content.zones) do
        assert(#zone.enemyFamilies == #zone.enemies)
        assert(type(zone.bossFamily) == "string")
        local enemies, known = {}, 0
        for index, family in ipairs(zone.enemyFamilies) do
            assert(family == "unknown" or W.Content.familyMaterials[family])
            enemies[index] = { family = family }
            if W.Content.familyMaterials[family] then
                known = known + 1
            end
        end
        local yields = G.EncounterMaterials(zone, { enemies = enemies })
        local total = 0
        for material, amount in pairs(yields) do
            assert(W.Content.materials[material] and amount >= 0)
            total = total + amount
        end
        assert(math.abs(total - (1 + 0.25 * known / #enemies)) < 0.000001)
        local boss =
            G.EncounterMaterials(zone, { boss = true, enemies = { { family = zone.bossFamily } } })
        total = 0
        for _, amount in pairs(boss) do
            total = total + amount
        end
        assert(total == (W.Content.familyMaterials[zone.bossFamily] and 6.25 or 5))
    end
end)
return cases
