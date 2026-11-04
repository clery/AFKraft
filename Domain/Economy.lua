local _, W = ...
local G = W.Game
local LIMIT = 9007199254740991
local historicalEnchants = { offense = true, defense = true, utility = true }

local function whole(value, high)
    return type(value) == "number" and value >= 0 and value <= high and value == math.floor(value)
end

-- Current-cycle training and retained enhancement ranks prove these purchases.
-- Crafts, earlier enchant replacements, discarded gear and earlier cycles do not
-- retain a complete spending history. Their conservative fallback credit is zero.
function G.MigrateEconomy(state, previousVersion)
    if previousVersion == 1 then
        if not whole(state.essence, LIMIT) then
            return false
        end
        local report = state.economyMigration
        if report == nil then
            return true
        end
        if type(report) ~= "table" or report.fallbackCredit ~= 0 then
            return false
        end
        for _, key in ipairs({
            "trainingEssence",
            "trainingGold",
            "equipmentEssence",
            "ambiguousItems",
            "ambiguousTraining",
        }) do
            if not whole(report[key], LIMIT) then
                return false
            end
        end
        return true
    end
    if previousVersion ~= nil or not whole(state.essence, LIMIT) then
        return false
    end
    local report = {
        trainingEssence = 0,
        trainingGold = 0,
        equipmentEssence = 0,
        ambiguousItems = 0,
        ambiguousTraining = 0,
        fallbackCredit = 0,
    }
    local seen = {}
    local function itemCredit(item)
        if
            type(item) ~= "table"
            or not whole(item.upgrade or 0, 1000000)
            or not whole(item.count or 1, 1000001)
            or (item.count or 1) < 1
        then
            return false
        end
        -- Duplicate saved references cannot multiply a migration credit.
        if not whole(item.uid, LIMIT) or item.uid == 0 then
            report.ambiguousItems = report.ambiguousItems + (item.count or 1)
            return true
        end
        local identity = item.uid
        if seen[identity] then
            return true
        end
        seen[identity] = true
        local rank, count = item.upgrade or 0, item.count or 1
        local enhancement = 8 * rank + 5 * rank * (rank - 1) / 2
        -- The retained enchant proves one paid application at the historical
        -- fixed 15 Essence price, not any replacements that came before it.
        local enchant = type(item.enchant) == "table" and historicalEnchants[item.enchant.id] and 15
            or 0
        report.equipmentEssence = report.equipmentEssence + (enhancement + enchant) * count
        if item.crafted or (item.forge or 0) > 0 then
            report.ambiguousItems = report.ambiguousItems + count
        end
        return true
    end
    for _, hero in ipairs(state.heroes) do
        local rank = hero.rank or 0
        if whole(rank, 14) then
            report.trainingEssence = report.trainingEssence + 60 * rank * (rank + 1)
            report.trainingGold = report.trainingGold + 80 * rank
        else
            report.ambiguousTraining = report.ambiguousTraining + 1
        end
        for _, item in pairs(hero.gear) do
            if not itemCredit(item) then
                return false
            end
        end
    end
    for _, item in ipairs(state.inventory) do
        if not itemCredit(item) then
            return false
        end
    end
    local credit = report.trainingEssence + report.equipmentEssence
    if
        not whole(state.essence + credit, LIMIT - state.development.invested)
        or not whole(state.gold + report.trainingGold, LIMIT)
    then
        return false
    end
    state.essence = state.essence + credit
    state.gold = state.gold + report.trainingGold
    state.economyVersion, state.economyMigration = 1, report
    G.Log(
        state,
        "Natural hero growth unlocked. Credited "
            .. credit
            .. " Essence and "
            .. report.trainingGold
            .. " gold from recorded retired purchases. Unrecorded spending receives no guessed credit.",
        nil,
        "rewards"
    )
    return true
end
