-- lua scripts/balance_matrix.lua [builds|zones|walls|boosts|professions]
-- Synthetic matched snapshots isolate choices; acquisition belongs to balance_journey.lua.
local B = dofile("scripts/balance_common.lua")
local G, C = B.G, B.C
local mode = arg[1] or "walls"
io.stdout:setvbuf("line")
if mode == "builds" then
    print(
        "Synthetic build comparison: 1000 prestige strength and eight Mastery ranks, actual paid gear; not acquisition evidence.")
    print("Class | Path | Level | Tier | Resource threshold | Win | Seconds | Candidate damage/healing per second")
    for _, class in ipairs(C.classes) do
        for path = 1, 3 do
            for _, level in ipairs({ 20, 40, 60 }) do
                for _, tier in ipairs({ 0, 5 }) do
                    local s = B.party(level, { "WARRIOR", "PRIEST", "HUNTER", "MAGE", class.id }, path, true, tier, 1000)
                    for index, hero in ipairs(s.heroes) do
                        hero.mastery.rank = 8
                        hero.talentProgress.earned = hero.talentProgress.earned + 8
                        B.talents(s, index, path)
                    end
                    for _, threshold in ipairs({ 0, 50, 90 }) do
                        local trial = G.Copy(s)
                        assert(G.Configure(trial, 5, "resourceThreshold", threshold))
                        local win, seconds, _, report = B.fight(trial, level)
                        print(string.format("%s | %d | %d | %d | %d | %s | %.2f | %.2f/%.2f", class.id, path, level, tier,
                            threshold, tostring(win), seconds, (report.damage[5] or 0) / seconds,
                            (report.healing[5] or 0) / seconds))
                    end
                end
            end
        end
    end
elseif mode == "zones" then
    print(
        "Zone | Material | Sample level | Gold/min | Primary/secondary materials/min | Gear upgrade drops | Wins/defeats")
    for _, zone in ipairs(C.zones) do
        local level = math.max(20, zone.level)
        local s = B.party(60, nil, 1, true, 0, 20)
        s.zone, s.stage = zone.id, (level - zone.level) * 5 + 1
        local gold, materials = s.gold, G.Copy(s.materials)
        local upgrades, defeats = 0, 0
        for _ = 1, 600 do
            G.Advance(s, 1)
            for _, event in ipairs(s.events) do
                if event.kind == "defeat" then defeats = defeats + 1 end
            end
            s.events = {}
        end
        for _, item in ipairs(s.inventory) do
            if G.IsUpgrade(s, item) then upgrades = upgrades + (item.count or 1) end
        end
        local primary, secondary = (s.materials[zone.material] - materials[zone.material]) / 10, 0
        for id, count in pairs(s.materials) do
            if id ~= zone.material then secondary = secondary + (count - materials[id]) / 10 end
        end
        assert(primary > 0 and secondary >= 0)
        print(string.format("%s | %s | %d | %.1f | %.2f/%.2f | %d | %d/%d", zone.id, zone.material, level,
            (s.gold - gold) / 10, primary, secondary, upgrades, s.stats.victories, defeats))
    end
elseif mode == "walls" then
    print("Wall level | Investment | Win | Seconds")
    for _, level in ipairs({ 20, 40, 60 }) do
        for _, option in ipairs({ "bare", "talents", "gear", "both" }) do
            local s = B.party(level, nil, (option == "talents" or option == "both") and 1 or nil,
                option == "gear" or option == "both")
            local win, seconds = B.fight(s, level)
            print(string.format("%d | %s | %s | %.2f", level, option, tostring(win), seconds))
            if option == "bare" then assert(not win) end
            if option == "both" and level == 20 then assert(win) end
        end
    end
    -- A capped, unmanaged wall: another hour of safe farming must not defeat it for free.
    local idle = B.party(60, nil, nil, false)
    idle.gold, idle.materials, idle.safe.elwynn, idle.stage = 0, { timber = 0, hide = 0, ore = 0, relic = 0 }, 200, 200
    idle.farming = true
    G.Advance(idle, 3600)
    assert(not B.fight(idle, 60))
    print("Cap wall remains after one hour without spending or allocating; saved loot/XP do not auto-equip talents.")
    print(
        "Tier | Bare cap | Crafted+talents | +board rank3 | +1000 strength | +weapon enhancement5, full Mastery, Assault if needed | Seconds at final budget")
    for tier = 0, 10 do
        local bare = B.party(60, nil, nil, false, tier)
        local s = B.party(60, nil, 1, true, tier)
        local initial = B.fight(s, 60)
        s.essence = 10000
        for _, branch in ipairs(C.development) do
            for _ = 1, 3 do assert(G.BuyDevelopment(s, branch.id)) end
            assert(G.SetDevelopmentChoice(s, branch.id, branch.choices[1].id))
        end
        local board = B.fight(s, 60)
        s.prestigeStrength = 1000
        local strength = B.fight(s, 60)
        for index in ipairs(s.heroes) do
            for _ = 1, 5 do assert(G.Upgrade(s, index, 1)) end
        end
        for index, hero in ipairs(s.heroes) do
            hero.mastery.rank = 24
            hero.talentProgress.earned = #G.TalentList(hero)
            B.talents(s, index, 1)
        end
        local enhanced, seconds = B.fight(s, 60)
        if not enhanced then
            assert(G.BuyBoost(s, "focusedAssault"))
            assert(G.ActivateBoost(s, "focusedAssault"))
            enhanced, seconds = B.fight(s, 60)
        end
        assert(not B.fight(bare, 60))
        assert(tier > 0 or enhanced, "Invested base capstone must remain attainable")
        print(string.format("%d | false | %s | %s | %s | %s | %.2f", tier, tostring(initial), tostring(board),
            tostring(strength), tostring(enhanced), seconds))
        if not enhanced then
            for _, power in ipairs({ 3000, 10000 }) do
                s.prestigeStrength = power
                local possible, time = B.fight(s, 60)
                print(string.format("Aspirational tier %d at %d synthetic strength: %s in %.2fs", tier, power,
                    tostring(possible), time))
                if possible then break end
                assert(power < 10000, "No finite tested prestige escape for late tier")
            end
        end
    end
elseif mode == "boosts" then
    print("Party | Tier | Boost | Mode | Wins | Defeats | Uses | Frontier")
    for _, composition in ipairs({ "offense", "support" }) do
        for _, tier in ipairs({ 0, 5, 8, 10 }) do
            for _, boost in ipairs(C.boosts) do
                for _, automation in ipairs({ "none", "onCooldown", "boss", "lowHealth" }) do
                    local s = B.party(60,
                        composition == "support" and { "PALADIN", "PRIEST", "DRUID", "WARRIOR", "WARLOCK" } or nil,
                        composition == "support" and 2 or 1, true, tier, 1000)
                    s.essence, s.legacy = 1000, 10
                    assert(G.BuyBoost(s, boost.id))
                    assert(G.BuyBoostAutomation(s, "onCooldown"))
                    assert(G.BuyBoostAutomation(s, "conditional"))
                    assert(G.ConfigureBoostAutomation(s, boost.id, "enabled", true))
                    assert(G.ConfigureBoostAutomation(s, boost.id, "mode", automation == "none" and "manual" or
                        automation))
                    assert(G.SetBoostAutomationEnabled(s, automation ~= "none"))
                    for index, hero in ipairs(s.heroes) do
                        hero.mastery.rank = 8
                        hero.talentProgress.earned = hero.talentProgress.earned + 8
                        B.talents(s, index, composition == "support" and 2 or 1)
                    end
                    s.stage, s.safe.elwynn, s.best, s.runBest = 296, 295, 60, 60
                    local defeats = 0
                    for _ = 1, 1800 do
                        G.Advance(s, 1)
                        for _, event in ipairs(s.events) do if event.kind == "defeat" then defeats = defeats + 1 end end
                        s.events = {}
                    end
                    assert(s.essence == 1000 - boost.cost and s.legacy == 7)
                    print(string.format("%s | %d | %s | %s | %d | %d | %d | %d", composition, tier, boost.id,
                        automation, s.stats.victories, defeats, s.stats.boostUses or 0, s.runBest))
                end
            end
        end
    end
elseif mode == "professions" then
    print(
        "Synthetic profession comparison: 3000 prestige strength, eight Mastery ranks, work rank7; ordinary and heirloom gear.")
    print("Craft branch | Forge branch | Enchant | Tier | Win | Seconds | Total gold/ore/dust paid")
    for _, craft in ipairs({ "efficiency", "quality", "precision" }) do
        for _, forge in ipairs({ "efficiency", "potential", "heirloom" }) do
            for _, enchant in ipairs({ "offense", "defense", "utility" }) do
                local s = B.party(60, nil, 1, false, 8, 3000)
                for index, hero in ipairs(s.heroes) do
                    hero.mastery.rank = 8
                    hero.talentProgress.earned = hero.talentProgress.earned + 8
                    B.talents(s, index, 1)
                end
                for _, profession in ipairs(C.professions) do s.professions.ranks[profession.id] = 7 end
                G.ProfessionUnlocks(s)
                for _, choice in ipairs({ { "crafting", craft }, { "titanforging", forge }, { "enchanting", enchant } }) do
                    for _ = 1, 3 do assert(G.AllocateProfession(s, choice[1], choice[2])) end
                end
                local gold, ore, relic = s.gold, s.materials.ore, s.materials.relic
                for index in ipairs(s.heroes) do
                    for _, slot in ipairs(C.equipmentSlots) do
                        assert(G.Craft(s, index, slot, "ore", false))
                        assert(G.Equip(s, index, #s.inventory))
                        assert(G.Enchant(s, index, slot, enchant))
                        for _ = 1, 2 do assert(G.Titanforge(s, index, slot)) end
                    end
                end
                local win, seconds = B.fight(s, 60)
                print(string.format("%s | %s | %s | 8 | %s | %.2f | %d/%d/%d", craft, forge, enchant, tostring(win),
                    seconds,
                    gold - s.gold, ore - s.materials.ore, relic - s.materials.relic))
            end
        end
    end
else
    error("Unknown matrix: " .. mode)
end
