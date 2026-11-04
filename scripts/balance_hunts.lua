-- lua scripts/balance_hunts.lua [samples=1000]
-- Actual catalog/source overlap and CollectionKill command. Travel/access times are assumptions.
local B = dofile("scripts/balance_common.lua")
local G, C, S = B.G, B.C, B.W.CollectionSources
local samples = tonumber(arg[1]) or 1000
assert(samples >= 10 and samples <= 5000 and samples == math.floor(samples))
io.stdout:setvbuf("line")
local original = G.Copy(S.profiles)
print("Forever source metadata model only; not live/client verification. Retail acquisition stays disabled.")
print(
    "Outdoor: 120 eligible kills/hour, 10 minutes per source-zone visit; dungeon: one listed source kill per 45-minute run.")
print("Set | Rank | Completion kills p50/p90/p99 | Hours p50/p90/p99 | Mean commands | Chance")
for _, collection in ipairs(C.collections) do
    local kind = collection.kind or "outdoor"
    local profile = original[kind == "dungeon" and "foreverDungeon16001" or "forever16001"]
    local sources, npcs = {}, {}
    for _, id in ipairs(collection.pieces) do
        local source = profile.sources[id]
        assert(source and source.verified, "Unverified Forever source: " .. id)
        sources[id] = G.Copy(source)
        npcs[source.npcID] = source.zone
    end
    S.profiles.balanceHunt = {
        id = "balanceHunt",
        kind = kind,
        enabled = true,
        verified = true,
        chance = profile.chance,
        sources =
            sources
    }
    for _, rank in ipairs({ 0, 3 }) do
        local times, kills, commands = {}, {}, 0
        for sample = 1, samples do
            local s = G.New(0)
            s.seed = 17 + sample * 7919
            s.legacy = 6
            for _ = 1, rank do assert(G.BuyCollectionTalent(s, kind == "dungeon" and "relicHunter" or "fieldcraft")) end
            local count, elapsed, serial, lastZone = 0, 0, 0, nil
            local book = kind == "dungeon" and s.dungeonCollections or s.outdoorCollections
            while not G.CollectionProgress(s, collection.id).complete do
                local target, best = nil, 0
                local order = {}
                for npc in pairs(npcs) do order[#order + 1] = npc end
                table.sort(order)
                for _, npc in ipairs(order) do
                    local pending = 0
                    for id, source in pairs(sources) do
                        if source.npcID == npc and not book.pieces[id] then pending = pending + 1 end
                    end
                    if pending > best then target, best = npc, pending end
                end
                assert(target and serial < 10000)
                local run = kind == "dungeon" and order or { target }
                if kind == "dungeon" then elapsed = elapsed + 2700 end
                for _, npc in ipairs(run) do
                    if kind == "outdoor" then
                        if lastZone ~= npcs[npc] then elapsed, lastZone = elapsed + 600, npcs[npc] end
                        elapsed = elapsed + 30
                    end
                    serial, count = serial + 1, count + 1
                    G.CollectionKill(s, {
                        profile = "balanceHunt",
                        npcID = npc,
                        kind = kind,
                        attributed = true,
                        outdoor = kind == "outdoor",
                        dungeon = kind == "dungeon",
                        receipt = string.format("kill:Creature-0-1-1-1-%d-%x", npc, serial)
                    })
                    if G.CollectionProgress(s, collection.id).complete then break end
                end
            end
            assert(s.essence == 0 and s.gold == 0 and #s.inventory == 0)
            times[sample], kills[sample] = elapsed / 3600, count
            commands = commands + serial
        end
        table.sort(times)
        table.sort(kills)
        local p50, p90, p99 = math.ceil(samples * .5), math.ceil(samples * .9), math.ceil(samples * .99)
        print(string.format("%s | %d | %d/%d/%d | %.2f/%.2f/%.2f | %.1f | %.2f", collection.id, rank,
            kills[p50], kills[p90], kills[p99], times[p50], times[p90], times[p99], commands / samples,
            G.CollectionDropChance({ collectionTalents = { fieldcraft = rank, relicHunter = rank } }, profile)))
    end
end
S.profiles.balanceHunt = nil
for id, profile in pairs(original) do
    assert(S.profiles[id].enabled == profile.enabled and S.profiles[id].verified == profile.verified)
end
print("Effects: all sets complete, one selectable effect; compare each matching family and partial bonus caps.")
local s = G.New(0)
for _, collection in ipairs(C.collections) do
    local book = collection.kind == "dungeon" and s.dungeonCollections or s.outdoorCollections
    for _, id in ipairs(collection.pieces) do book.pieces[id] = true end
end
for _, collection in ipairs(C.collections) do
    assert(G.SetCollectionEffect(s, collection.id))
    local m = G.CollectionBonuses(s, collection.effect.family)
    assert(m.basicAttack <= 1.10 and m.materials <= 1.10 and m.damageTaken >= 0.95)
    print(string.format("%s | basic %.3f | materials %.3f | matching defense %.3f", collection.id,
        m.basicAttack, m.materials, m.damageTaken))
end
