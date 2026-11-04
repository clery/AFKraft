-- Shared fixture helpers for standalone balance checks, never loaded by the addon.
local W = {}
for line in io.lines("WoWIdle.toc") do
    local file = line:gsub("\\", "/")
    if file:match("^Content") or file:match("^Domain/") or file:match("^Simulation/") then
        assert(loadfile(file))("WoWIdle", W)
    end
end
assert(loadfile("Compatibility/CollectionSources.lua"))("WoWIdle", W)
local G, C = W.Game, W.Content
local B = { G = G, C = C, W = W }
B.classes = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }

function B.talents(state, index, path)
    local hero = state.heroes[index]
    for pass = 0, 2 do
        for _, talent in ipairs(G.TalentList(hero)) do
            if talent.path == (path + pass - 1) % 3 + 1 and not hero.talents[talent.id] then
                G.Talent(state, index, talent.id)
            end
        end
    end
end

-- Synthetic comparison fixture, not an earned-progression claim.
function B.party(level, classes, path, geared, tier, strength)
    local s = G.New(0)
    s.seed, s.tier, s.prestigeStrength = 17, tier or 0, strength or 0
    s.difficulty.unlocked, s.difficulty.maxTier = s.tier > 0, s.tier
    s.gold = 1000000
    for _, material in ipairs(C.materialOrder) do
        s.materials[material] = 100000
    end
    for _, class in ipairs(classes or B.classes) do
        assert(G.AddHero(s, class))
        local index, hero = #s.heroes, s.heroes[#s.heroes]
        hero.level = level
        G.TalentProgress(hero)
        if path then
            B.talents(s, index, path)
        end
        G.ConfigurePreset(s, index, class == "PRIEST" and "support" or "offense")
        G.Configure(s, index, "resourceThreshold", 0)
        if geared then
            for _, slot in ipairs(C.equipmentSlots) do
                local quote = G.Cost(s, hero, false)
                local gold, ore = s.gold, s.materials.ore
                assert(G.Craft(s, index, slot, "ore", false))
                assert(s.gold == gold - quote.gold and s.materials.ore == ore - quote.material)
                assert(G.Equip(s, index, #s.inventory))
            end
        end
    end
    return s
end

function B.fight(state, level, zone, boss, stage)
    local s = G.Copy(state)
    s.battle, s.rest, s.zone, s.farming = nil, 0, zone or state.zone, true
    s.stage = stage or (level - C.zoneByID[s.zone].level) * 5 + (boss == false and 1 or 5)
    assert(s.stage >= 1)
    local victories, gold = s.stats.victories, s.gold
    G.StartBattle(s)
    local ticks, report = 0, { damage = {}, healing = {}, taken = 0 }
    while s.battle and ticks < 721 do
        G.Step(s, 0.25)
        for _, event in ipairs(s.events) do
            if event.kind == "hit" and event.enemy and type(event.source) == "number" then
                report.damage[event.source] = (report.damage[event.source] or 0) + event.amount
            elseif event.kind == "heal" and type(event.source) == "number" then
                report.healing[event.source] = (report.healing[event.source] or 0) + event.amount
            elseif event.kind == "hit" and not event.enemy then
                report.taken = report.taken + event.amount
            end
        end
        s.events = {}
        ticks = ticks + 1
    end
    assert(not s.battle and ticks <= 720)
    local win = s.stats.victories > victories
    assert(win or s.gold == gold, "Failed challenges must not pay victory rewards")
    return win, ticks / 4, s, report
end

return B
