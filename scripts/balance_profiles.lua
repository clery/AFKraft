-- Run from the repository root: lua scripts/balance_profiles.lua
-- Fixed-seed feasibility checks, not a substitute for supported-client playtests.
local W = {}
assert(loadfile("Localization.lua"))("WoWIdle", W)
assert(loadfile("Locales/enUS.lua"))("WoWIdle", W)
for _, file in ipairs({
    "Content.lua",
    "Content/Encounters.lua",
    "Content/TalentTraits.lua",
    "Content/TalentExpansion.lua",
    "Content/Backdrops.lua",
    "Content/Items.lua",
    "Content/Boosts.lua",
    "Content/Resources.lua",
    "Content/Collections.lua",
    "Content/Professions.lua",
    "Content/Development.lua",
    "Domain/State.lua",
    "Domain/Development.lua",
    "Domain/Economy.lua",
    "Domain/Boosts.lua",
    "Domain/BoostRules.lua",
    "Domain/Party.lua",
    "Domain/Resources.lua",
    "Domain/Mastery.lua",
    "Domain/Inventory.lua",
    "Domain/Collections.lua",
    "Domain/HuntSession.lua",
    "Compatibility/CollectionSources.lua",
    "Domain/Routes.lua",
    "Domain/Profiles.lua",
    "Domain/Professions.lua",
    "Domain/Difficulty.lua",
    "Domain/Prestige.lua",
    "Domain/Adventure.lua",
    "Domain/Rewards.lua",
    "Simulation/Positioning.lua",
    "Simulation/Combat.lua",
    "Simulation/Offline.lua",
}) do
    assert(loadfile(file))("WoWIdle", W)
end
local G, C = W.Game, W.Content
local hours = tonumber(arg and arg[1]) or 6
local checkinSeconds = tonumber(arg and arg[2]) or 900
assert(hours >= 1 and hours <= 100 and hours == math.floor(hours))
assert(
    checkinSeconds >= 60
        and checkinSeconds <= 86400
        and checkinSeconds == math.floor(checkinSeconds)
)
-- Synthetic sources exist only in this standalone process. No client mapping is enabled.
io.stdout:setvbuf("line")
local acquisitionFlags = {}
for id, profile in pairs(W.CollectionSources.profiles) do
    acquisitionFlags[id] = profile.enabled
end
local collection = C.collections[1]
local model = {
    id = "balanceModel",
    enabled = true,
    verified = true,
    chance = 5,
    sources = {},
}
for position, itemID in ipairs(collection.pieces) do
    model.sources[itemID] = { npcID = position, verified = true }
end
W.CollectionSources.profiles[model.id] = model
local profiles = {
    { name = "Idle only", quests = 0, kills = 0, gathers = 0, hunt = 0 },
    { name = "Mixed play", quests = 8, kills = 80, gathers = 4, hunt = 12 },
    { name = "Focused hunt", quests = 0, kills = 150, gathers = 0, hunt = 120 },
}
local classes = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }
local function checkin(state)
    while #state.heroes < G.CompanionSlots(state) do
        assert(G.Recruit(state, classes[#state.heroes + 1]))
    end
    for index, hero in ipairs(state.heroes) do
        for _, talent in ipairs(G.TalentList(hero)) do
            if G.TalentRank(hero, talent) < talent.maxRanks then
                G.Talent(state, index, talent.id)
            end
        end
        G.EquipBest(state, index)
        local opportunity = G.CraftingOpportunity(state, index)
        if opportunity and opportunity.slot then
            G.Craft(state, index, opportunity.slot, opportunity.material, opportunity.heirloom)
            G.EquipBest(state, index)
        end
    end
    -- One next affordable rank per branch per check-in; no free or fixture equipment.
    for _, branch in ipairs(C.development) do
        G.BuyDevelopment(state, branch.id)
    end
    if state.farming then
        G.Retry(state)
    end
end
local function run(profile, seed)
    local state = G.New(0)
    state.seed = seed
    assert(G.AddHero(state, "WARRIOR"))
    local activities = { quest = 0, kill = 0, gather = 0 }
    local rates = { quest = profile.quests, kill = profile.kills, gather = profile.gathers }
    local huntCount, firstPrestige, firstPiece, completed = 0, nil, nil, nil
    for second = 1, hours * 3600 do
        -- Real activity runs through the actual XP command; counts include travel/downtime.
        for _, kind in ipairs({ "quest", "kill", "gather" }) do
            local due = math.floor(second * rates[kind] / 3600)
            if due > activities[kind] then
                G.AdventureXP(state, C.activityRewards[kind].xp, kind, "Balance model")
                activities[kind] = due
            end
        end
        local due = math.floor(second * profile.hunt / 3600)
        if due > huntCount then
            huntCount = due
            local source
            for position, itemID in ipairs(collection.pieces) do
                if not state.outdoorCollections.pieces[itemID] then
                    source = position
                    break
                end
            end
            if source then
                G.CollectionKill(state, {
                    profile = model.id,
                    npcID = source,
                    attributed = true,
                    outdoor = true,
                    receipt = string.format("kill:Creature-0-1-1-1-%d-%x", source, huntCount),
                })
            end
            local count = state.outdoorCollections.stats.discoveries
            if count > 0 then
                firstPiece = firstPiece or second
            end
            if count == #collection.pieces then
                completed = completed or second
                G.SetCollectionEffect(state, collection.id)
            end
        end
        G.Advance(state, 1)
        state.events = {} -- Presentation events are not consumed by this headless scenario.
        if state.prestigeUnlocked then
            firstPrestige = firstPrestige or second
        end
        if second == 1 or second % checkinSeconds == 0 then
            checkin(state)
        end
        if second == 900 or second == 3600 or second == hours * 3600 then
            local level = 0
            for _, hero in ipairs(state.heroes) do
                level = math.max(level, hero.level)
            end
            print(
                string.format(
                    "%s | %d | %.2f | %d | %d | %d | %d | %d/%d/%d | %d | %s | %s | %s",
                    profile.name,
                    seed,
                    second / 3600,
                    level,
                    state.runBest,
                    state.gold,
                    state.adventure.totalXP,
                    state.development.ranks.might,
                    state.development.ranks.resolve,
                    state.development.ranks.provisioning,
                    state.outdoorCollections.stats.discoveries,
                    firstPrestige and string.format("%.2f", firstPrestige / 3600) or "> horizon",
                    firstPiece and string.format("%.2f", firstPiece / 3600) or "> horizon",
                    completed and string.format("%.2f", completed / 3600) or "> horizon"
                )
            )
        end
    end
    assert(G.Load(G.Copy(state), hours * 3600), "Profile must leave a loadable save")
end
print(
    string.format(
        "Hypotheses only: %d online idle hours, %g-minute check-ins, fixed class/talent policy, no resets.",
        hours,
        checkinSeconds / 60
    )
)
print(
    "Hunts use synthetic one-piece sources: 5% independent rolls, no collection talents; never verified client availability."
)
print(
    "Mixed: 8 quests/80 kills/4 gathers and 12 eligible hunt kills per hour; focused: 150 kills, 120 eligible."
)
print(
    "Hunt kills are a subset of activity kills; travel included in rates. No actual-client playtest evidence."
)
print(
    "Profile | Seed | Hours | Max hero level | Frontier | Gold | Real XP | Board M/R/P | Pieces | Prestige h | First piece h | Set h"
)
for _, profile in ipairs(profiles) do
    for _, seed in ipairs(arg and arg[3] and { assert(tonumber(arg[3])) } or { 17, 91, 403 }) do
        run(profile, seed)
    end
end

-- A scenario fixture must never enable a shipped acquisition profile.
for id, enabled in pairs(acquisitionFlags) do
    assert(W.CollectionSources.profiles[id].enabled == enabled)
end
