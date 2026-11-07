local _, W = ...
local G, C, L = W.Game, W.Content, W.L

local function whole(value, minimum)
    return type(value) == "number"
        and value >= minimum
        and value <= 1000000000
        and value == math.floor(value)
end

function G.ChestCount(state, zone)
    local count = 0
    for _, chest in ipairs(state.chests) do
        if not zone or chest.zone == zone then
            count = count + chest.count
        end
    end
    return count
end

function G.ValidateChests(state)
    if type(state.chests) ~= "table" or not whole(state.nextItem, 1) then
        return false
    end
    if next(state.chests) == nil then
        return true
    end
    local seen, size = {}, 0
    for _, item in ipairs(state.inventory) do
        if type(item) == "table" and whole(item.uid, 1) then
            seen[item.uid] = true
        end
    end
    for _, hero in ipairs(state.heroes) do
        if type(hero) ~= "table" or type(hero.gear) ~= "table" then
            return false
        end
        for _, item in pairs(hero.gear) do
            if type(item) == "table" and whole(item.uid, 1) then
                seen[item.uid] = true
            end
        end
    end
    for index, chest in pairs(state.chests) do
        if not whole(index, 1) or type(chest) ~= "table" then
            return false
        end
        size = size + 1
        local item = chest.item
        local template = type(item) == "table" and C.itemByID[item.itemID]
        if
            not C.zoneByID[chest.zone]
            or not whole(chest.tier, 0)
            or not whole(chest.count, 1)
            or not template
            or item.slot ~= template.slot
            or not whole(item.uid, 1)
            or not whole(item.level, 1)
            or not G.ValidDisenchantValue(item)
            or not C.qualityNames[item.quality]
            or type(item.name) ~= "string"
            or type(item.icon) ~= "string"
            or type(item.stats) ~= "table"
            or item.count ~= nil
            or item.heirloom
            or item.protected
            or seen[item.uid]
            or not whole(item.upgrade or 0, 0)
            or item.uid >= state.nextItem
        then
            return false
        end
        for stat, value in pairs(item.stats) do
            if
                not C.itemStatNames[stat]
                or type(value) ~= "number"
                or value ~= value
                or value < 0
                or value > 1000000
            then
                return false
            end
        end
        if item.effect ~= nil and type(item.effect) ~= "string" then
            return false
        end
        seen[item.uid] = true
    end
    for index = 1, size do
        if not state.chests[index] then
            return false
        end
    end
    return true
end

local function sameDrop(a, b)
    return a.level == b.level
        and a.slot == b.slot
        and a.quality == b.quality
        and a.effect == b.effect
        and (a.upgrade or 0) == (b.upgrade or 0)
        and G.SameItem(a, b)
end

function G.StoreChest(state, item)
    for _, chest in ipairs(state.chests) do
        local stored = chest.item
        if chest.zone == state.zone and chest.tier == state.tier and sameDrop(stored, item) then
            chest.count = chest.count + 1
            G.Emit(state, "chest")
            return
        end
    end
    state.chests[#state.chests + 1] = {
        zone = state.zone,
        tier = state.tier,
        item = item,
        count = 1,
    }
    G.Emit(state, "chest")
end

-- At most five heroes: mask assignment finds the best party total without greedy hero ordering.
local function openingAssignment(state, candidates, slot)
    local limit = 2 ^ #state.heroes - 1
    local plans = { [0] = { power = 0, changes = 0, choices = {} } }
    candidates[#candidates + 1] = { count = #state.heroes }
    for _, candidate in ipairs(candidates) do
        for _ = 1, math.min(candidate.count, #state.heroes) do
            local nextPlans = {}
            for mask = 0, limit do
                nextPlans[mask] = plans[mask]
            end
            for mask = 0, limit do
                local plan = plans[mask]
                if plan then
                    for index, hero in ipairs(state.heroes) do
                        local bit = 2 ^ (index - 1)
                        if
                            math.floor(mask / bit) % 2 == 0
                            and (not candidate.item or G.CanEquip(hero, candidate.item))
                        then
                            local power = plan.power + G.ItemPower(candidate.item, hero)
                            local unchanged = candidate.item == hero.gear[slot]
                            local changes = plan.changes + (unchanged and 0 or 1)
                            local previous = nextPlans[mask + bit]
                            if
                                not previous
                                or power > previous.power + 0.0000001
                                or (
                                    math.abs(power - previous.power) < 0.0000001
                                    and changes < previous.changes
                                )
                            then
                                local choices = {}
                                for key, value in pairs(plan.choices) do
                                    choices[key] = value
                                end
                                choices[index] = candidate
                                nextPlans[mask + bit] =
                                    { power = power, changes = changes, choices = choices }
                            end
                        end
                    end
                end
            end
            plans = nextPlans
        end
    end
    return plans[limit].choices
end

local function equipOpening(state, report)
    local changed, before = {}, 0
    report.equipped, report.disenchanted, report.relic = 0, 0, 0
    local gold, relic = state.gold, state.materials.relic
    for _, slot in ipairs(C.equipmentSlots) do
        local candidates, originals = {}, {}
        for _, hero in ipairs(state.heroes) do
            local item = hero.gear[slot]
            before = before + G.ItemPower(item, hero)
            if item then
                candidates[#candidates + 1] = { item = item, count = 1 }
                originals[#originals + 1] = item
            end
        end
        for _, entry in ipairs(report.entries) do
            if entry.item.slot == slot then
                candidates[#candidates + 1] =
                    { item = entry.item, count = entry.count, entry = entry }
            end
        end
        local choices, used = openingAssignment(state, candidates, slot), {}
        for index, hero in ipairs(state.heroes) do
            local candidate = choices[index]
            local item = candidate.item
            if item then
                used[item] = true
            end
            if candidate.entry then
                item = G.Copy(item)
                item.count, item.uid = nil, state.nextItem
                state.nextItem = state.nextItem + 1
                candidate.entry.equipped = (candidate.entry.equipped or 0) + 1
            end
            if hero.gear[slot] ~= item then
                hero.gear[slot] = item
                changed[index] = true
                report.equipped = report.equipped + 1
                state.guide.equipped = true
            end
        end
        for _, item in ipairs(originals) do
            if not used[item] then
                state.inventory[#state.inventory + 1] = item
            end
        end
    end
    local after = 0
    for index, hero in ipairs(state.heroes) do
        for _, slot in ipairs(C.equipmentSlots) do
            after = after + G.ItemPower(hero.gear[slot], hero)
        end
        if changed[index] then
            G.RefreshHero(state, index)
        end
    end
    for _, entry in ipairs(report.entries) do
        local remaining = entry.count - (entry.equipped or 0)
        entry.kept = (entry.equipped or 0) > 0
        entry.uid = nil
        if remaining > 0 then
            local item = G.Copy(entry.item)
            item.count = remaining > 1 and remaining or nil
            state.inventory[#state.inventory + 1] = item
            if G.DisenchantReward(item) then
                G.Disenchant(state, item, nil, true)
                entry.disenchanted = remaining
                report.disenchanted = report.disenchanted + remaining
            else
                entry.kept, entry.uid = true, item.uid
            end
        end
    end
    report.disenchantGold = state.gold - gold
    report.powerGain, report.relic = math.max(0, after - before), state.materials.relic - relic
    if report.equipped > 0 then
        G.Emit(state, "equip")
    end
end

function G.OpenChests(state, quantity, zone)
    if
        (quantity ~= 1 and quantity ~= 10 and quantity ~= "all")
        or (zone ~= nil and not C.zoneByID[zone])
    then
        return false, L.CHOOSE_CHEST_BATCH
    end
    if not G.ValidateChests(state) then
        return false, L.INVALID_CHEST_SAVE
    end
    local remaining =
        math.min(quantity == "all" and math.huge or quantity, G.ChestCount(state, zone))
    if remaining == 0 then
        return false, L.NO_CHESTS_TO_OPEN
    end
    local report = {
        count = remaining,
        quality = 1,
        entries = {},
        salvaged = 0,
        duplicates = 0,
        gold = 0,
        ore = 0,
    }
    local autoEquip = state.settings.chestAutoEquip == true
    local gold, ore, relic = state.gold, state.materials.ore, state.materials.relic
    local retained = {}
    for _, chest in ipairs(state.chests) do
        local amount = (not zone or chest.zone == zone) and math.min(chest.count, remaining) or 0
        if amount > 0 then
            local item = G.Copy(chest.item)
            if amount < chest.count then
                item.uid = state.nextItem
                state.nextItem = state.nextItem + 1
            end
            item.count = amount > 1 and amount or nil
            local stored = autoEquip and item or G.Loot(state, item, true)
            if autoEquip and item.effect then
                state.discoveries["effect:" .. item.effect] = true
            end
            local duplicate = stored and stored ~= item
            for _, previous in ipairs(report.entries) do
                duplicate = duplicate or sameDrop(previous.item, item)
            end
            if not stored then
                for _, existing in ipairs(state.inventory) do
                    duplicate = duplicate or sameDrop(existing, item)
                end
            end
            local duplicates = duplicate and amount or math.max(0, amount - 1)
            report.duplicates = report.duplicates + duplicates
            report.quality = math.max(report.quality, item.quality)
            report.salvaged = report.salvaged + (stored and 0 or amount)
            report.entries[#report.entries + 1] = {
                item = G.Copy(item),
                count = amount,
                kept = stored ~= nil,
                uid = stored and stored.uid,
                zone = chest.zone,
            }
            chest.count = chest.count - amount
            remaining = remaining - amount
        end
        if chest.count > 0 then
            retained[#retained + 1] = chest
        end
    end
    state.chests = retained
    if autoEquip then
        equipOpening(state, report)
    end
    report.gold, report.ore = state.gold - gold, state.materials.ore - ore
    report.relic = state.materials.relic - relic
    table.sort(report.entries, function(a, b)
        if a.item.quality ~= b.item.quality then
            return a.item.quality > b.item.quality
        end
        return a.item.uid < b.item.uid
    end)
    G.Emit(state, "chestOpened")
    return true, nil, report
end
