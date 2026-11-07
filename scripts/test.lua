-- Run from the repository root: lua scripts/test.lua
local W = {}
local files = {
    "Localization.lua",
    "Locales/enUS.lua",
    "Locales/frFR.lua",
    "Locales/deDE.lua",
    "Locales/esES.lua",
    "Locales/ruRU.lua",
    "Locales/zhCN.lua",
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
    "Content/Journal.lua",
    "Domain/State.lua",
    "Domain/Journal.lua",
    "Domain/Development.lua",
    "Domain/Economy.lua",
    "Domain/Boosts.lua",
    "Domain/BoostRules.lua",
    "Domain/Party.lua",
    "Domain/Resources.lua",
    "Domain/Mastery.lua",
    "Domain/Inventory.lua",
    "Domain/Chests.lua",
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
}
for _, file in ipairs(files) do
    assert(loadfile(file))("AFKraft", W)
end
local cases = {}
for _, file in ipairs({
    "tests/localization.lua",
    "tests/domain.lua",
    "tests/offline_fastforward.lua",
    "tests/encounters.lua",
    "tests/progression.lua",
    "tests/positioning.lua",
    "tests/talents.lua",
    "tests/talent_variety.lua",
    "tests/resources.lua",
    "tests/materials.lua",
    "tests/mastery.lua",
    "tests/items.lua",
    "tests/chests.lua",
    "tests/disenchant.lua",
    "tests/client.lua",
    "tests/sounds.lua",
    "tests/activities.lua",
    "tests/outdoor_sources.lua",
    "tests/adventure.lua",
    "tests/boosts.lua",
    "tests/boost_automation.lua",
    "tests/collections.lua",
    "tests/collection_talents.lua",
    "tests/dungeon_collections.lua",
    "tests/dungeon_sources.lua",
    "tests/hunt_session.lua",
    "tests/dungeon_sessions.lua",
    "tests/routes.lua",
    "tests/profiles.lua",
    "tests/professions.lua",
    "tests/difficulty.lua",
    "tests/feature_integration.lua",
    "tests/boost_rules.lua",
    "tests/balance.lua",
    "tests/development.lua",
    "tests/journal.lua",
    "tests/economy.lua",
}) do
    for _, spec in ipairs(assert(loadfile(file))("AFKraft", W)) do
        cases[#cases + 1] = spec
    end
end
local failed = 0
for _, spec in ipairs(cases) do
    local ok, message = pcall(spec[2])
    print((ok and "PASS " or "FAIL ") .. spec[1])
    if not ok then
        print("  " .. tostring(message))
        failed = failed + 1
    end
end
print(string.format("%d passed, %d failed", #cases - failed, failed))
os.exit(failed == 0 and 0 or 1)
