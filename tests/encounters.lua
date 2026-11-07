local _, W = ...
if not W then
    return
end
local C, G = W.Content, W.Game
local cases = {}

cases[#cases + 1] = {
    "Zone caps unlock the next tier and repeat without losing old checkpoints",
    function()
        for _, zone in ipairs(C.zones) do
            assert(zone.maxStage >= 5 and zone.maxStage % 5 == 0)
            local finalLevel = zone.level + math.floor((zone.maxStage - 1) / 5)
            local nextLevel = C.transcendenceBoss.level
            for _, destination in ipairs(C.zones) do
                if destination.level > zone.level then
                    nextLevel = math.min(nextLevel, destination.unlockLevel - 1)
                end
            end
            assert(finalLevel >= nextLevel and finalLevel <= nextLevel + 1)
        end
        local state = G.New(1000)
        assert(G.AddHero(state, "WARRIOR"))
        local cap = C.zoneByID.elwynn.maxStage
        state.stage = cap
        G.StartBattle(state)
        for _, enemy in ipairs(state.battle.enemies) do
            enemy.hp = 0
        end
        G.Step(state, 0.25)
        assert(state.stage == cap and state.safe.elwynn == cap)
        assert(G.IsUnlocked(state, C.zoneByID.westfall))
        G.StartBattle(state)
        assert(state.battle.stage == cap and state.battle.boss)
        state.battle = nil
        state.safe.elwynn, state.stage = 100, 101
        local loaded = assert(G.Load(G.Copy(state), 1000))
        G.StartBattle(loaded)
        assert(loaded.battle.stage == cap and loaded.safe.elwynn == 100)
        assert(G.Travel(loaded, "westfall"))
        assert(G.Travel(loaded, "elwynn") and loaded.stage == cap)
    end,
}

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
    "Bounded zone frontiers never select locked creatures or mismatched families",
    function()
        local state = G.New(1000)
        for _ = 1, 3 do
            assert(G.AddHero(state, "WARRIOR"))
        end
        for _, zone in ipairs(C.zones) do
            state.zone = zone.id
            local seen = {}
            for stage = 1, zone.maxStage do
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
                if entry.level <= zone.level + math.floor((zone.maxStage - 1) / 5) then
                    assert(seen[entry.name], zone.id .. " never encounters " .. entry.name)
                end
            end
        end
    end,
}

cases[#cases + 1] = {
    "Expanded encounters survive reload and preserve deterministic farming",
    function()
        local state = G.New(1000)
        assert(G.AddHero(state, "HUNTER"))
        state.zone, state.stage = "blackrock_mountain", 100
        G.StartBattle(state)
        assert(state.battle.enemies[1].name == C.encounterAdditions.blackrock_mountain[4].name)
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
