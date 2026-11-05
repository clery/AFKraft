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
    local state = G.New(0)
    G.AddHero(state, "WARRIOR")
    state.essence = 100000
    return state
end
local function near(a, b)
    return math.abs(a - b) < 0.000001
end

case(
    "Development purchases use quadratic prices and exact reversible investment receipts",
    function()
        local s = party()
        local initial = s.essence
        for rank = 1, 10 do
            local quote = assert(G.DevelopmentQuote(s, "might"))
            assert(
                quote.rank == rank - 1 and quote.nextRank == rank and quote.cost == 60 * rank * rank
            )
            assert(G.BuyDevelopment(s, "might"))
            assert(G.ValidateDevelopment(s))
        end
        assert(s.development.invested == 23100 and s.essence == initial - 23100)
        local quote = G.DevelopmentQuote(s, "might")
        assert(quote.maximum and quote.cost == nil)
        assert(not G.BuyDevelopment(s, "might"))
        for rank = 10, 1, -1 do
            local before = s.essence
            assert(G.RefundDevelopment(s, "might"))
            assert(s.essence == before + 60 * rank * rank)
        end
        assert(s.essence == initial and s.development.invested == 0)
        assert(not G.RefundDevelopment(s, "might"))
    end
)

case(
    "Development quotes are pure and expose current and prospective diminishing bonuses",
    function()
        local s = party()
        local quote = G.DevelopmentQuote(s, "resolve")
        assert(
            quote.current.health == 1
                and quote.current.recovery == 0
                and quote.current.damageTaken == 1
        )
        assert(
            near(quote.next.health, 1.08)
                and near(quote.next.recovery, 0.006)
                and near(quote.next.damageTaken, 0.97)
        )
        assert(
            s.development.ranks.resolve == 0 and s.development.invested == 0 and s.essence == 100000
        )
        quote.next.health = 10
        assert(G.DevelopmentModifiers(s).health == 1)
        assert(G.DevelopmentQuote(s, "missing") == nil)
    end
)

case("Development invalid requests and insufficient funds are atomic", function()
    local s = party()
    s.essence = 59
    assert(not G.BuyDevelopment(s, "might"))
    assert(not G.BuyDevelopment(s, "missing"))
    assert(not G.RefundDevelopment(s, "missing"))
    assert(not G.SetDevelopmentChoice(s, "might", "assault"))
    assert(s.essence == 59 and s.development.invested == 0 and s.development.ranks.might == 0)
    s.development.invested = 1
    assert(
        not G.BuyDevelopment(s, "might")
            and not G.RefundDevelopment(s, "might")
            and not G.ResetDevelopment(s)
    )
    assert(s.essence == 59 and s.development.invested == 1)
end)

case(
    "Development milestones switch freely and saved choices deactivate below rank three",
    function()
        local s = party()
        for _ = 1, 3 do
            assert(G.BuyDevelopment(s, "might"))
        end
        local base, essence = G.DevelopmentModifiers(s), s.essence
        assert(G.SetDevelopmentChoice(s, "might", "assault"))
        local assault = G.DevelopmentModifiers(s)
        assert(
            near(assault.damage, base.damage * 1.05)
                and assault.healing == base.healing
                and s.essence == essence
        )
        assert(G.SetDevelopmentChoice(s, "might", "restoration"))
        local restoration = G.DevelopmentModifiers(s)
        assert(restoration.damage == base.damage and near(restoration.healing, base.healing * 1.05))
        assert(not G.SetDevelopmentChoice(s, "might", "bulwark"))
        assert(G.RefundDevelopment(s, "might"))
        assert(s.development.choices.might == "restoration")
        assert(G.DevelopmentModifiers(s).healing == G.DevelopmentModifiers(s).damage)
        assert(not G.SetDevelopmentChoice(s, "might", "assault"))
        assert(G.BuyDevelopment(s, "might"))
        assert(G.DevelopmentModifiers(s).healing > G.DevelopmentModifiers(s).damage)
    end
)

case(
    "Development redistribution refunds only board spending and retains other permanent capabilities",
    function()
        local s = party()
        s.professions.bestLevel = math.max(s.professions.bestLevel, 22)
        assert(G.BuyBoost(s, "battleOrders"))
        s.legacy = 5
        s.professions.bestLevel = 60
        assert(G.BuyBoostAutomation(s, "onCooldown"))
        s.difficulty.unlocked, s.difficulty.maxTier = true, 3
        assert(G.BuyRoutes(s))
        local baseline = s.essence
        for _, id in ipairs({ "might", "resolve", "provisioning" }) do
            for _ = 1, 3 do
                assert(G.BuyDevelopment(s, id))
            end
        end
        assert(G.SetDevelopmentChoice(s, "resolve", "renewal"))
        assert(G.SetDevelopmentChoice(s, "provisioning", "harvest"))
        assert(G.ResetDevelopment(s))
        assert(s.essence == baseline and s.development.invested == 0)
        assert(
            s.boosts.owned.battleOrders and s.boosts.automation.owned.onCooldown and s.routes.owned
        )
        assert(
            s.development.choices.resolve == "renewal"
                and s.development.choices.provisioning == "harvest"
        )
        assert(G.ResetDevelopment(s) and s.essence == baseline)
    end
)

case("Development branches use distinct bounded multipliers and milestone bonuses", function()
    local s = party()
    for _, branch in ipairs(C.development) do
        for _ = 1, 10 do
            assert(G.BuyDevelopment(s, branch.id))
        end
    end
    assert(G.SetDevelopmentChoice(s, "resolve", "renewal"))
    assert(G.SetDevelopmentChoice(s, "provisioning", "harvest"))
    local mods = G.DevelopmentModifiers(s)
    assert(near(mods.damage, 1 + 0.4 * 10 / 14) and near(mods.healing, mods.damage))
    assert(near(mods.health, 1 + 0.4 * 10 / 14) and near(mods.recovery, 0.03 * 10 / 14 + 0.005))
    assert(near(mods.damageTaken, 1 - 0.15 * 10 / 14))
    assert(
        near(mods.materials, (1 + 0.6 * 10 / 14) * 1.1)
            and near(mods.costMultiplier, 1 - 0.25 * 10 / 14)
    )
    assert(near(mods.heroXP, 1 + 0.5 * 10 / 14))
    assert(G.SetDevelopmentChoice(s, "resolve", "bulwark"))
    assert(G.SetDevelopmentChoice(s, "provisioning", "rebuild"))
    local alternate = G.DevelopmentModifiers(s)
    assert(near(alternate.health, mods.health * 1.05) and alternate.recovery < mods.recovery)
    assert(alternate.materials < mods.materials and near(alternate.heroXP, mods.heroXP * 1.1))
end)

case("Development edits preserve battle health proportion, cooldowns and active effects", function()
    local s = party()
    s.professions.bestLevel = math.max(s.professions.bestLevel, 22)
    assert(G.BuyBoost(s, "battleOrders"))
    assert(G.ActivateBoost(s, "battleOrders"))
    G.StartBattle(s)
    local unit = s.battle.heroes[1]
    unit.hp, unit.cd, unit.specialCD, unit.healCD = unit.maxHP * 0.4, 1.7, 5, 8
    local active, ready = s.boosts.activeUntil.battleOrders, s.boosts.readyAt.battleOrders
    local beforeHP = unit.maxHP
    assert(G.BuyDevelopment(s, "resolve"))
    assert(unit.maxHP > beforeHP and near(unit.hp / unit.maxHP, 0.4))
    assert(unit.cd == 1.7 and unit.specialCD == 5 and unit.healCD == 8)
    assert(G.RefundDevelopment(s, "resolve") and near(unit.hp / unit.maxHP, 0.4))
    assert(near(unit.maxHP, beforeHP))
    assert(s.boosts.activeUntil.battleOrders == active and s.boosts.readyAt.battleOrders == ready)
end)

case("Development saves validate exact ledgers and survive ordinary and deeper resets", function()
    local s = party()
    for _ = 1, 3 do
        assert(G.BuyDevelopment(s, "might"))
    end
    assert(G.SetDevelopmentChoice(s, "might", "assault"))
    s.prestigeUnlocked, s.runBest = true, 8
    assert(G.Prestige(s))
    assert(s.development.ranks.might == 3 and s.development.invested == 840)
    local h = s.heroes[1]
    h.level = 60
    assert(G.TalentProgress(h))
    s.encounter = s.encounter + 1
    assert(
        G.DifficultyVictory(
            s,
            { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }
        )
    )
    assert(G.PrestigePlus(s, 1))
    assert(s.development.ranks.might == 3 and s.development.choices.might == "assault")
    assert(G.Load(G.Copy(s), 100))
    for _, mutate in ipairs({
        function(d)
            d.invested = 839
        end,
        function(d)
            d.ranks.might = 11
        end,
        function(d)
            d.ranks.resolve = 0 / 0
        end,
        function(d)
            d.ranks.unknown = 1
        end,
        function(d)
            d.choices.might = "harvest"
        end,
        function(d)
            d.choices.unknown = "assault"
        end,
    }) do
        local malformed = G.Copy(s)
        mutate(malformed.development)
        assert(not G.ValidateDevelopment(malformed))
        assert(not G.Load(malformed, 100))
    end
    local old = G.Copy(s)
    old.development = nil
    assert(G.Load(old, 100) and old.development.invested == 0)
end)

case("Development funds remain exact and refundable at the saved currency limit", function()
    local state = party()
    assert(G.BuyDevelopment(state, "might"))
    state.essence = 9007199254740991 - 60
    assert(G.ValidateDevelopment(state))
    assert(G.ResetDevelopment(state))
    assert(state.essence == 9007199254740991 and state.development.invested == 0)
    for _, funds in ipairs({ -1, 0.5, 0 / 0, math.huge }) do
        state.essence = funds
        assert(not G.ValidateDevelopment(state))
        assert(not G.BuyDevelopment(state, "might") and not G.ResetDevelopment(state))
    end
end)

return cases
