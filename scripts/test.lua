-- Run from the repository root: lua scripts/test.lua
local W = {}
local files = {
    "Content.lua",
    "Content/TalentTraits.lua",
    "Content/Backdrops.lua",
    "Content/Items.lua",
    "Domain/State.lua",
    "Domain/Party.lua",
    "Domain/Inventory.lua",
    "Domain/Prestige.lua",
    "Domain/Adventure.lua",
    "Domain/Rewards.lua",
    "Simulation/Positioning.lua",
    "Simulation/Combat.lua",
    "Simulation/Offline.lua",
}
for _, file in ipairs(files) do
    assert(loadfile(file))("WoWIdle", W)
end
local cases = {}
for _, file in ipairs({
    "tests/domain.lua",
    "tests/progression.lua",
    "tests/positioning.lua",
    "tests/talents.lua",
    "tests/items.lua",
    "tests/disenchant.lua",
    "tests/client.lua",
    "tests/sounds.lua",
    "tests/activities.lua",
    "tests/adventure.lua",
}) do
    for _, spec in ipairs(assert(loadfile(file))("WoWIdle", W)) do
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
