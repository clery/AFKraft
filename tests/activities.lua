local _, W = ...
if not W then
    return
end
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

local function fixture()
    local namespace = { L = W.L, Content = W.Content, Game = W.Game }
    local secret = {}
    local host = { dead = false, trivial = false, denied = false, threat = 0, level = 90 }
    local names = { [2575] = "Mining", [2366] = "Herb Gathering", [8613] = "Skinning" }
    local environment = setmetatable({
        GetBuildInfo = function()
            return "12.1.5"
        end,
        GetServerTime = function()
            return 1000
        end,
        UnitClass = function()
            return "Warrior", "WARRIOR"
        end,
        UnitName = function()
            return "Adventurer"
        end,
        UnitGUID = function(unit)
            return unit == "player" and "player-guid" or "creature-guid"
        end,
        UnitLevel = function()
            return host.level
        end,
        GetMaxPlayerLevel = function()
            return 90
        end,
        UnitIsDead = function()
            return host.dead
        end,
        UnitIsTrivial = function()
            return host.trivial
        end,
        UnitIsTapDenied = function()
            return host.denied
        end,
        UnitPlayerControlled = function()
            return false
        end,
        UnitCanAttack = function()
            return true
        end,
        UnitThreatSituation = function()
            return host.threat
        end,
        CanLootUnit = function()
            return host.canLoot, host.canLoot
        end,
        issecretvalue = function(value)
            return value == secret
        end,
        C_Spell = {
            GetSpellName = function(id)
                return names[id]
            end,
        },
        C_TooltipInfo = {
            GetWorldCursor = function()
                return host.tooltip
            end,
        },
    }, { __index = _G })
    for _, file in ipairs({
        "Compatibility/Client.lua",
        "Compatibility/Kills.lua",
        "Compatibility/Gathering.lua",
    }) do
        local chunk = assert(loadfile(file))
        setfenv(chunk, environment)
        chunk("WoWIdle", namespace)
    end
    local state = W.Game.New(1000)
    W.Game.AddHero(state, "WARRIOR")
    return namespace, state, host, secret
end

local function tooltip(host, profession, color)
    host.tooltip = {
        lines = {
            { leftText = "Gathering node" },
            { leftText = profession, leftColor = color },
        },
    }
end

local function gather(namespace, state, guid, spell)
    namespace.Client.Event(state, "UNIT_SPELLCAST_SENT", "player", "Gathering node", guid, spell)
    namespace.Client.Event(state, "UNIT_SPELLCAST_SUCCEEDED", "player", guid, spell)
end

case("Credited non-gray kills award Adventure XP at the real character level cap", function()
    local n, s, host = fixture()
    n.Client.Event(s, "UNIT_THREAT_LIST_UPDATE", "target")
    host.dead = true
    n.Client.Event(s, "UNIT_FLAGS", "target")
    n.Client.Event(s, "UNIT_HEALTH", "target")
    n.Client.Event(s, "CHAT_MSG_COMBAT_XP_GAIN", "Experience")
    assert(s.essence == 0 and s.adventure.totalXP == 1 and s.heroes[1].xp == 0)
end)

case("Gray, uncredited, foreign-tapped, and already dead targets do not award XP", function()
    for _, mode in ipairs({ "gray", "uncredited", "foreign", "corpse" }) do
        local n, s, host = fixture()
        host.trivial, host.denied, host.dead = mode == "gray", mode == "foreign", mode == "corpse"
        if mode == "uncredited" then
            host.threat = nil
        end
        n.Client.Event(s, "UNIT_FLAGS", "target")
        host.dead = true
        n.Client.Event(s, "UNIT_FLAGS", "target")
        assert(s.essence == 0 and s.heroes[1].xp == 0, mode)
    end
end)

case("Secret unit data cannot cause errors or unearned kill rewards", function()
    local n, s, host, secret = fixture()
    host.trivial, host.threat = secret, secret
    n.Client.Event(s, "UNIT_HEALTH", "target")
    host.dead = true
    n.Client.Event(s, "UNIT_FLAGS", "target")
    assert(s.essence == 0)
end)

case("Loot rights cover max-level one-shot kills without a surviving threat entry", function()
    local n, s, host = fixture()
    host.threat, host.dead, host.canLoot = nil, true, true
    n.Client.Event(s, "UNIT_FLAGS", "target")
    n.Client.Event(s, "UPDATE_MOUSEOVER_UNIT")
    assert(s.essence == 0 and s.adventure.totalXP == 1 and s.heroes[1].xp == 0)
end)

case(
    "Below-cap combat experience grants Adventure XP without double-counting unit deaths",
    function()
        local n, s, host = fixture()
        host.level = 40
        n.Client.Event(s, "UNIT_FLAGS", "target")
        host.dead = true
        n.Client.Event(s, "UNIT_FLAGS", "target")
        n.Client.Event(s, "CHAT_MSG_COMBAT_XP_GAIN", "A creature dies; you gain experience.")
        assert(s.essence == 0 and s.adventure.totalXP == 1 and s.heroes[1].xp == 0)
    end
)

case("Eligible mining, herbalism, and skinning reward XP without an actual skill point", function()
    for _, profession in ipairs({ { "Mining", 2575 }, { "Herbalism", 2366 }, { "Skinning", 8613 } }) do
        local n, s, host = fixture()
        tooltip(host, profession[1], { r = 0.25, g = 0.75, b = 0.25 })
        gather(n, s, "gather-green", profession[2])
        assert(
            s.essence == 0
                and s.adventure.totalXP == (profession[2] == 8613 and 0.25 or 4)
                and s.heroes[1].xp == 0,
            profession[1]
        )
    end
end)

case("Orange and yellow nodes reward once across success and skill-up events", function()
    for _, color in ipairs({ { r = 1, g = 0.5, b = 0.25 }, { r = 1, g = 1, b = 0 } }) do
        local n, s, host = fixture()
        tooltip(host, "Mining", color)
        gather(n, s, "gather-once", 2575)
        n.Client.Event(s, "CHAT_MSG_SKILL", "Your skill in Mining has increased.")
        n.Client.Event(s, "UNIT_SPELLCAST_SUCCEEDED", "player", "gather-once", 2575)
        assert(s.essence == 0 and s.adventure.totalXP == 4 and s.heroes[1].xp == 0)
    end
end)

case("Gray, red, and plain white gathering tooltips do not award XP", function()
    for _, color in ipairs({
        { r = 0.5, g = 0.5, b = 0.5 },
        { r = 1, g = 0.1, b = 0.1 },
        { r = 1, g = 1, b = 1 },
    }) do
        local n, s, host = fixture()
        tooltip(host, "Mining", color)
        gather(n, s, "gather-gray", 2575)
        assert(s.essence == 0 and s.adventure.totalXP == 0 and s.heroes[1].xp == 0)
    end
end)

case("Failed and interrupted gathering casts never reward XP", function()
    for _, event in ipairs({ "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
        local n, s, host = fixture()
        tooltip(host, "Mining", { r = 1, g = 1, b = 0 })
        n.Client.Event(s, "UNIT_SPELLCAST_SENT", "player", "Gathering node", "failed", 2575)
        n.Client.Event(s, event, "player", "failed", 2575)
        n.Client.Event(s, "UNIT_SPELLCAST_SUCCEEDED", "player", "failed", 2575)
        n.Client.Event(s, "CHAT_MSG_SKILL", "Your skill in Mining has increased.")
        assert(s.essence == 0)
    end
end)

case("A confirmed gathering skill-up covers unavailable tooltip difficulty", function()
    local n, s = fixture()
    gather(n, s, "gather-fallback", 2575)
    assert(s.essence == 0)
    n.Client.Event(s, "CHAT_MSG_SKILL", "Your skill in Mining has increased.")
    assert(s.essence == 0 and s.adventure.totalXP == 4 and s.heroes[1].xp == 0)
end)

return cases
