-- Run from the repository root: lua scripts/balance_heirlooms.lua
local B = assert(loadfile("scripts/balance_common.lua"))()
local G, C = B.G, B.C

print("Synthetic prior account: five level-60 heroes, retained talents, no prestige strength.")
print("Pays for 50 heirlooms, enchants, enhancements and forge steps from fixture funds.")
print("Seeds 17/91; both resets; no post-reset funding. This is not earned pacing evidence.")
print("Reset | Seed | Hero/boss level | Enchant AP | Party power | Win | Seconds")
for _, deep in ipairs({ false, true }) do
    for _, seed in ipairs({ 17, 91 }) do
        local s = B.party(60, nil, 1, false)
        s.seed = seed
        for index, hero in ipairs(s.heroes) do
            for _, slot in ipairs(C.equipmentSlots) do
                s.recipes[slot] = true -- Declared prior-account entitlement, not earned access.
                assert(G.Craft(s, index, slot, "ore", true))
                assert(hero.gear[slot] and hero.gear[slot].heirloom)
                assert(G.Upgrade(s, index, slot))
                assert(G.Enchant(s, index, slot, "offense"))
                assert(G.Titanforge(s, index, slot))
            end
        end
        assert(G.ResetAdventure(s, deep))
        for _, level in ipairs({ 1, 10, 30, 60 }) do
            local sample = G.Copy(s)
            local power = 0
            for index, hero in ipairs(sample.heroes) do
                hero.level = level
                G.EquipBest(sample, index)
                G.RefreshHero(sample, index)
                assert(G.ProfessionStatBonus(hero.gear[1], hero).attackPower == 36)
                for _, item in pairs(hero.gear) do
                    power = power + G.ItemPower(item, hero)
                end
            end
            local win, seconds = B.fight(sample, level)
            print(
                string.format(
                    "%s | %d | %d | %.1f | %.1f | %s | %.2f",
                    deep and "Deep" or "Ordinary",
                    seed,
                    level,
                    G.ProfessionStatBonus(sample.heroes[1].gear[1], sample.heroes[1]).attackPower,
                    power,
                    tostring(win),
                    seconds
                )
            )
        end
    end
end
