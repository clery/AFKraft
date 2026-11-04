local _, W = ...
if not W then
    return
end
local C, G = W.Content, W.Game
local cases = {}

cases[#cases + 1] = {
    "Every destination gains six opponents with bounded frontier unlocks",
    function()
        local total = 0
        for _, zone in ipairs(C.zones) do
            local entries = C.encounterAdditions[zone.id]
            assert(#entries == 6)
            assert(#zone.enemies == #zone.enemyFamilies and #zone.enemies == #zone.enemyLevels)
            local names = {}
            for index, name in ipairs(zone.enemies) do
                assert(not names[name], zone.id .. " repeats " .. name)
                names[name] = true
                assert(zone.enemyFamilies[index] and zone.enemyLevels[index] >= 1)
            end
            for index, entry in ipairs(entries) do
                assert(entry.level == ({ 1, 1, 1, 20, 40, 60 })[index])
                assert(C.creatureFamilies[entry.appearance])
                total = total + 1
            end
        end
        assert(total == 246)
    end,
}

cases[#cases + 1] = {
    "Frontiers one through sixty never select locked creatures or mismatched families",
    function()
        local state = G.New(1000)
        for _ = 1, 3 do
            assert(G.AddHero(state, "WARRIOR"))
        end
        for _, zone in ipairs(C.zones) do
            state.zone = zone.id
            local seen = {}
            for stage = 1, (60 - zone.level + 1) * 5 do
                state.stage = stage
                G.StartBattle(state)
                local battle = state.battle
                for _, enemy in ipairs(battle.enemies) do
                    if enemy.name == zone.boss then
                        assert(battle.boss and enemy.family == zone.bossFamily)
                    else
                        local found
                        for index, name in ipairs(zone.enemies) do
                            if enemy.name == name then
                                assert(zone.enemyLevels[index] <= battle.level)
                                assert(enemy.family == zone.enemyFamilies[index])
                                found = true
                            end
                        end
                        assert(found, enemy.name)
                        seen[enemy.name] = true
                    end
                end
            end
            for _, entry in ipairs(C.encounterAdditions[zone.id]) do
                assert(seen[entry.name], zone.id .. " never encounters " .. entry.name .. " by 60")
            end
        end
    end,
}

cases[#cases + 1] = {
    "Expanded encounters survive reload and preserve deterministic farming",
    function()
        local state = G.New(1000)
        assert(G.AddHero(state, "HUNTER"))
        state.stage = 100
        G.StartBattle(state)
        assert(state.battle.enemies[1].name == "Eastvale packleader")
        local loaded = assert(G.Load(G.Copy(state), 1000))
        assert(loaded.battle.enemies[1].name == state.battle.enemies[1].name)
        for _ = 1, 8 do
            G.Step(state, 0.25)
            G.Step(loaded, 0.25)
        end
        assert(state.seed == loaded.seed)
        assert(state.battle.enemies[1].hp == loaded.battle.enemies[1].hp)
    end,
}

return cases
