local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function party()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy = 60, 10
    assert(G.BuyBoost(s, "battleOrders"))
    assert(G.BuyBoost(s, "ironResolve"))
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(G.BuyBoostAutomation(s, "conditional"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "mode", "lowHealth"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", 65))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(G.SetBoostAutomationEnabled(s, true))
    return s
end

case(
    "Profiles save independent snapshots and apply configuration without gameplay effects",
    function()
        local s = party()
        assert(G.ActivateBoost(s, "battleOrders"))
        assert(G.SetBoostRules(s, "battleOrders", {
            { condition = "lowHealth", action = "activate", threshold = 60 },
            { condition = "boss", action = "activate" },
        }))
        local ok, id = G.SaveBoostProfile(s, nil, "  Boss support  ")
        assert(ok and id == 1 and s.boostProfiles.entries[id].name == "Boss support")
        assert(G.EquipBoost(s, "ironResolve"))
        assert(G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", 35))
        assert(G.SetBoostAutomationEnabled(s, false))
        local profile = s.boostProfiles.entries[id]
        assert(profile.automation.abilities.battleOrders.healthBelow == 65)
        assert(
            G.SetBoostRules(s, "battleOrders", { { condition = "always", action = "activate" } })
        )
        assert(profile.automation.abilities.battleOrders.rules[1].threshold == 60)
        local clock, gold, essence, legacy = s.clock, s.gold, s.essence, s.legacy
        local active, cooldown, journal = s.boosts.activeUntil, s.boosts.readyAt, #s.log
        assert(G.ApplyBoostProfile(s, id))
        assert(s.boosts.equipped == "battleOrders" and s.boosts.automation.enabled)
        assert(s.boosts.automation.abilities.battleOrders.healthBelow == 65)
        assert(#s.boosts.automation.abilities.battleOrders.rules == 2)
        s.boosts.automation.abilities.battleOrders.rules[1].threshold = 40
        assert(profile.automation.abilities.battleOrders.rules[1].threshold == 60)
        assert(s.boosts.activeUntil == active and s.boosts.readyAt == cooldown)
        assert(
            s.clock == clock
                and s.gold == gold
                and s.essence == essence
                and s.legacy == legacy
                and #s.log == journal
        )
        s.boosts.automation.abilities.battleOrders.healthBelow = 80
        assert(profile.automation.abilities.battleOrders.healthBelow == 65)
    end
)

case(
    "Profiles bound names and capacity, retain stable IDs, rename without overwriting rules",
    function()
        local s = party()
        assert(not G.SaveBoostProfile(s, nil, " "))
        assert(not G.SaveBoostProfile(s, nil, string.rep("x", 41)))
        assert(not G.SaveBoostProfile(s, nil, "Bad\nname"))
        for index = 1, 8 do
            local ok, id = G.SaveBoostProfile(s, nil, "Setup " .. index)
            assert(ok and id == index)
        end
        assert(not G.SaveBoostProfile(s, nil, "Ninth"))
        local entry = s.boostProfiles.entries[1]
        assert(G.RenameBoostProfile(s, 1, "Renamed"))
        assert(
            entry.name == "Renamed" and entry.automation.abilities.battleOrders.healthBelow == 65
        )
        assert(not G.RenameBoostProfile(s, 1, ""))
        assert(not G.RenameBoostProfile(s, 99, "Unknown"))
        assert(not G.SaveBoostProfile(s, 99, "Unknown"))
        assert(not G.DeleteBoostProfile(s, 99))
        assert(G.SaveBoostProfile(s, 1, "Updated"))
        assert(G.DeleteBoostProfile(s, 4))
        local ok, id = G.SaveBoostProfile(s, nil, "Replacement")
        assert(ok and id == 9 and s.boostProfiles.nextID == 10)
        assert(G.ValidateProfiles(s))
    end
)

case("Profiles atomically reject removed boosts and missing entitlement", function()
    local s = party()
    local _, id = G.SaveBoostProfile(s, nil, "Setup")
    local original = s.boosts.automation
    s.boostProfiles.entries[id].equipped = "removedBoost"
    assert(G.ValidateProfiles(s))
    assert(not G.ApplyBoostProfile(s, id))
    assert(s.boosts.automation == original and s.boosts.equipped == "battleOrders")
    s.boostProfiles.entries[id].equipped = "battleOrders"
    s.boosts.automation.owned.conditional = nil
    assert(not G.ApplyBoostProfile(s, id))
    assert(
        s.boosts.automation == original
            and s.boosts.automation.abilities.battleOrders.healthBelow == 65
    )
    s.boosts.automation.owned.conditional = true
    s.boosts.owned.battleOrders = nil
    assert(not G.ApplyBoostProfile(s, id))
end)

case("Profiles load preserves stale references but rejects malformed schemas", function()
    local s = party()
    local _, id = G.SaveBoostProfile(s, nil, "Stale")
    local profile = s.boostProfiles.entries[id]
    profile.automation.abilities.removedBoost =
        { enabled = false, mode = "manual", healthBelow = 50 }
    assert(G.ValidateProfiles(s))
    assert(not G.ApplyBoostProfile(s, id))
    assert(G.Load(G.Copy(s), 10))
    profile.automation.abilities.removedBoost.healthBelow = 0 / 0
    assert(not G.ValidateProfiles(s))
    profile.automation.abilities.removedBoost.healthBelow = 50
    s.boostProfiles.nextID = id
    assert(not G.ValidateProfiles(s))
end)

case("Profiles supply disabled defaults for newly added catalog boosts", function()
    local s = party()
    local _, id = G.SaveBoostProfile(s, nil, "Before catalog growth")
    local boost = { id = "profileTestBoost", name = "Future boost" }
    C.boosts[#C.boosts + 1], C.boostByID[boost.id] = boost, boost
    local ok, result = pcall(function()
        assert(G.ApplyBoostProfile(s, id))
        local config = s.boosts.automation.abilities[boost.id]
        assert(not config.enabled and config.mode == "manual" and config.healthBelow == 50)
    end)
    C.boosts[#C.boosts], C.boostByID[boost.id] = nil, nil
    if not ok then
        error(result)
    end
end)

case("Profiles survive ordinary prestige without restoring active effects", function()
    local s = party()
    local _, id = G.SaveBoostProfile(s, nil, "Permanent")
    assert(G.ActivateBoost(s, "battleOrders"))
    s.prestigeUnlocked, s.runBest = true, 8
    assert(G.Prestige(s))
    assert(s.boostProfiles.entries[id].name == "Permanent")
    assert(G.ApplyBoostProfile(s, id))
    assert(next(s.boosts.activeUntil) == nil and s.boosts.readyAt.battleOrders == 600)
    assert(G.Load(G.Copy(s), 10))
end)

case(
    "Profiles retain route preferences, reject deleted routes, and reset only a changed plan cursor",
    function()
        local s = party()
        assert(G.BuyRoutes(s))
        -- Route commands own step validation; profile snapshots refer only to stable template IDs.
        s.routes.templates =
            { { id = 1, name = "First", steps = {} }, { id = 2, name = "Second", steps = {} } }
        s.routes.selected, s.routes.enabled = 1, true
        local _, id = G.SaveBoostProfile(s, nil, "With route")
        s.routes.run.cursor = 3
        local originalRun = s.routes.run
        assert(G.ApplyBoostProfile(s, id) and s.routes.run == originalRun)
        s.routes.selected, s.routes.enabled = 2, false
        assert(G.ApplyBoostProfile(s, id))
        assert(s.routes.selected == 1 and s.routes.enabled and s.routes.run.cursor == 1)
        s.routes.templates = { s.routes.templates[2] }
        local originalAbilities = s.boosts.automation.abilities
        s.boosts.equipped = "ironResolve"
        assert(not G.ApplyBoostProfile(s, id))
        assert(
            s.boosts.equipped == "ironResolve"
                and s.boosts.automation.abilities == originalAbilities
        )
        s.routes.templates = { { id = 1, name = "First", steps = {} } }
        s.routes.owned = false
        assert(not G.ApplyBoostProfile(s, id))
    end
)

case("Profiles capture one collection effect and reject unavailable effects atomically", function()
    local s = party()
    local set = C.collections[1]
    for _, itemID in ipairs(set.pieces) do
        s.outdoorCollections.pieces[itemID] = true
    end
    assert(G.SetCollectionEffect(s, set.id))
    local ok, id = G.SaveBoostProfile(s, nil, "Outdoor")
    assert(ok and s.boostProfiles.entries[id].collection.effect == set.id)
    assert(G.SetCollectionEffect(s, nil))
    assert(G.ApplyBoostProfile(s, id))
    assert(s.outdoorCollections.effect == set.id)
    assert(G.SetCollectionEffect(s, nil))
    s.outdoorCollections.pieces[set.pieces[1]] = nil
    local equipped = s.boosts.equipped
    assert(not G.ApplyBoostProfile(s, id))
    assert(s.outdoorCollections.effect == nil and s.boosts.equipped == equipped)
    s.boostProfiles.entries[id].collection = nil
    assert(G.ApplyBoostProfile(s, id))
end)

case("Profiles restore offline route opt-in only after entitlement validation", function()
    local s = party()
    assert(G.BuyRoutes(s))
    assert(G.SetOfflineRoutesEnabled(s, true))
    local ok, id = G.SaveBoostProfile(s, nil, "Offline supplies")
    assert(ok)
    assert(G.SetOfflineRoutesEnabled(s, false))
    assert(G.ApplyBoostProfile(s, id) and s.routes.offlineEnabled)
    s.routes.owned, s.routes.offlineEnabled = false, false
    assert(not G.ApplyBoostProfile(s, id) and not s.routes.offlineEnabled)
end)

return cases
