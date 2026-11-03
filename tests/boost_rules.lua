local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end
local function rule(condition, threshold)
    return { condition = condition, threshold = threshold, action = "activate" }
end
local function party()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy = 30, 3
    assert(G.BuyBoost(s, "battleOrders"))
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(G.BuyBoostAutomation(s, "conditional"))
    G.StartBattle(s)
    return s
end

case("Ordered boost rules validate bounded typed dense activation lists", function()
    assert(G.ValidateBoostRules(nil) and G.ValidateBoostRules({}))
    assert(G.ValidateBoostRules({
        rule("always"),
        rule("boss"),
        rule("lowHealth", 10),
        rule("tier", 10),
    }))
    for _, invalid in ipairs({
        false,
        { rule("unknown") },
        { { condition = "boss", action = "reset" } },
        { rule("lowHealth", 9) },
        { rule("lowHealth", 90.1) },
        { rule("lowHealth", 0 / 0) },
        { rule("tier", -1) },
        { rule("tier", 11) },
        { rule("boss", 10) },
        { { condition = "boss", action = "activate", minTier = 1 } },
        { rule("boss"), rule("boss"), rule("boss"), rule("boss"), rule("boss") },
        { [2] = rule("boss") },
        { extra = rule("boss") },
    }) do
        assert(not G.ValidateBoostRules(invalid))
    end
end)

case("Rule edits require ownership are atomic copied and never activate", function()
    local s = party()
    local rules = { rule("always") }
    assert(G.SetBoostRules(s, "battleOrders", rules))
    local saved = s.boosts.automation.abilities.battleOrders.rules
    rules[1].condition = "boss"
    assert(saved[1].condition == "always")
    assert(not next(s.boosts.activeUntil) and not next(s.boosts.readyAt))
    assert(not G.SetBoostRules(s, "battleOrders", { rule("lowHealth", 1) }))
    assert(s.boosts.automation.abilities.battleOrders.rules == saved)
    assert(not G.SetBoostRules(s, "ironResolve", {}))
    s.boosts.automation.owned.conditional = nil
    assert(not G.SetBoostRules(s, "battleOrders", {}))
    assert(s.boosts.automation.abilities.battleOrders.rules == saved)
end)

case("Ordered rules choose the first match deterministically", function()
    local s = party()
    assert(
        G.SetBoostRules(
            s,
            "battleOrders",
            { rule("boss"), rule("farming"), rule("pushing"), rule("always") }
        )
    )
    local matched, _, index = G.EvaluateBoostRules(s, "battleOrders")
    assert(matched and index == 3)
    s.farming = true
    matched, _, index = G.EvaluateBoostRules(s, "battleOrders")
    assert(matched and index == 2)
    s.battle.boss = true
    matched, _, index = G.EvaluateBoostRules(s, "battleOrders")
    assert(matched and index == 1)
    assert(G.SetBoostRules(s, "battleOrders", { rule("always"), rule("boss") }))
    matched, _, index = G.EvaluateBoostRules(s, "battleOrders")
    assert(matched and index == 1)
end)

case("Low health rules exclude dead allies and use a strict percentage boundary", function()
    local s = party()
    assert(G.SetBoostRules(s, "battleOrders", { rule("lowHealth", 50) }))
    local ally = s.battle.heroes[1]
    ally.maxHP, ally.hp = 100, 50
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    ally.hp = 49
    assert(G.EvaluateBoostRules(s, "battleOrders"))
    ally.hp = 0
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    G.AddHero(s, "PRIEST")
    s.battle.heroes[2] = { hp = 100, maxHP = 100 }
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    s.battle.heroes[2].hp = 1
    assert(G.EvaluateBoostRules(s, "battleOrders"))
end)

case("Tier rules use the current tier and require living combat", function()
    local s = party()
    assert(G.SetBoostRules(s, "battleOrders", { rule("tier", 2) }))
    s.tier, s.bestTier = 1, 10
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    s.tier = 2
    assert(G.EvaluateBoostRules(s, "battleOrders"))
    for _, enemy in ipairs(s.battle.enemies) do
        enemy.hp = 0
    end
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    s.battle = nil
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
end)

case("Empty ordered rules preserve presets without requesting activation", function()
    local s = party()
    local config = s.boosts.automation.abilities.battleOrders
    config.mode = "boss"
    assert(G.SetBoostRules(s, "battleOrders", { rule("always") }))
    assert(G.SetBoostRules(s, "battleOrders", nil))
    assert(config.mode == "boss" and #config.rules == 0)
    assert(not G.EvaluateBoostRules(s, "battleOrders"))
    assert(not next(s.boosts.readyAt))
end)

case("Ordered rules honor global controls and manual activation owns the cooldown", function()
    local s = party()
    local config = s.boosts.automation.abilities.battleOrders
    assert(G.SetBoostRules(s, "battleOrders", { rule("always") }))
    config.mode, config.enabled = "manual", true
    assert(not G.BoostAutomationStatus(s, "battleOrders"))
    s.boosts.automation.enabled = true
    assert(G.BoostAutomationStatus(s, "battleOrders"))
    config.enabled = false
    assert(not G.BoostAutomationStatus(s, "battleOrders"))
    config.enabled = true
    assert(G.ActivateBoost(s, "battleOrders"))
    local readyAt, activeUntil = s.boosts.readyAt.battleOrders, s.boosts.activeUntil.battleOrders
    assert(not G.AutomateBoost(s))
    assert(
        s.boosts.readyAt.battleOrders == readyAt
            and s.boosts.activeUntil.battleOrders == activeUntil
    )
end)

return cases
