local _, W = ...
local G, C = W.Game, W.Content
local floor, min = math.floor, math.min
local registration = {}
local receiptLimit = 128

local function integer(value)
    return type(value) == "number" and value >= 0 and value < math.huge and value == floor(value)
end

local function encounterID(receipt)
    if type(receipt) ~= "string" then
        return nil
    end
    local value = tonumber(receipt:match("^encounter:(%d+)$"))
    return integer(value) and value or nil
end

function G.ValidateCollections(state)
    local book = state.collectionBook
    if
        type(book) ~= "table"
        or type(book.pieces) ~= "table"
        or type(book.counters) ~= "table"
        or type(book.receipts) ~= "table"
        or type(book.receiptOrder) ~= "table"
        or (book.target ~= nil and not C.collectionByID[book.target])
        or (book.lastEncounter ~= nil and not integer(book.lastEncounter))
    then
        return false
    end
    for itemID, tier in pairs(book.pieces) do
        if not C.collectionByItem[itemID] or not integer(tier) then
            return false
        end
    end
    for setID, tiers in pairs(book.counters) do
        local collection = C.collectionByID[setID]
        if not collection or type(tiers) ~= "table" then
            return false
        end
        for tier, count in pairs(tiers) do
            if not integer(tier) or not integer(count) or count >= collection.guarantee then
                return false
            end
        end
    end
    local seen, count = {}, 0
    for index, receipt in pairs(book.receiptOrder) do
        if
            not integer(index)
            or index < 1
            or index > receiptLimit
            or seen[receipt]
            or not encounterID(receipt)
            or book.receipts[receipt] ~= true
        then
            return false
        end
        seen[receipt], count = true, count + 1
    end
    if count ~= #book.receiptOrder then
        return false
    end
    for receipt, value in pairs(book.receipts) do
        local serial = encounterID(receipt)
        if
            not serial
            or value ~= true
            or not seen[receipt]
            or serial > (book.lastEncounter or 0)
        then
            return false
        end
    end
    return true
end

function G.CollectionProgress(state, setID, tier)
    local collection = C.collectionByID[setID]
    if not collection or (tier ~= nil and not integer(tier)) then
        return nil
    end
    local book = state.collectionBook
    local found, completedRank = 0, math.huge
    for _, itemID in ipairs(collection.pieces) do
        local rank = book.pieces[itemID]
        if rank ~= nil then
            found = found + 1
            completedRank = min(completedRank, rank)
        end
    end
    local completed = found == #collection.pieces and completedRank or nil
    tier = tier or (completed and completed + 1 or 0)
    local tierFound, missing = 0, {}
    for _, itemID in ipairs(collection.pieces) do
        if (book.pieces[itemID] or -1) >= tier then
            tierFound = tierFound + 1
        else
            missing[#missing + 1] = itemID
        end
    end
    local counters = book.counters[setID] or {}
    return {
        found = found,
        count = #collection.pieces,
        completedRank = completed,
        tier = tier,
        tierFound = tierFound,
        missing = missing,
        counter = tierFound == #collection.pieces and 0 or (counters[tier] or 0),
        guarantee = collection.guarantee,
    }
end

function G.SetCollectionTarget(state, setID)
    if setID ~= nil and not C.collectionByID[setID] then
        return false, "Unknown collection."
    end
    state.collectionBook.target = setID
    return true
end

-- Completed upgrades replace the previous bonus with a bounded, diminishing gain.
function G.CollectionRankScale(rank)
    return 1 + 0.2 * rank / (rank + 1)
end

function G.CollectionBonuses(state, enemyFamily)
    local result = { basicAttack = 1, materials = 1, damageTaken = 1 }
    for _, collection in ipairs(C.collections) do
        local progress = assert(G.CollectionProgress(state, collection.id))
        local scale = progress.completedRank and G.CollectionRankScale(progress.completedRank) or 1
        for stat, milestone in pairs(collection.milestones) do
            if progress.found >= milestone.pieces then
                result[stat] = result[stat] * (1 + milestone.bonus * scale)
            end
        end
        if progress.completedRank and enemyFamily == collection.family then
            result.damageTaken = result.damageTaken * (1 - collection.defense * scale)
        end
    end
    return result
end

local function eligible(collection, context)
    return not context.crafted
        and collection.zones[context.zone] == true
        and collection.families[context.family] == true
        and type(context.level) == "number"
        and context.level >= collection.minLevel
        and integer(context.tier or 0)
end

-- Only CollectionVictory can supply a qualifying, unconsumed acquisition token.
-- Ordinary loot, crafted copies, and inventory reconstruction never register pieces.
function G.RegisterCollectionDrop(state, item, context)
    if
        type(context) ~= "table"
        or context.registration ~= registration
        or context.consumed
        or item.heirloom
        or item.crafted
    then
        return false
    end
    local setID = C.collectionByItem[item.itemID]
    local collection = setID and C.collectionByID[setID]
    if not collection or not eligible(collection, context) then
        return false
    end
    context.consumed = true
    local tier = context.tier or 0
    local previous = state.collectionBook.pieces[item.itemID]
    if previous ~= nil and previous >= tier then
        return false
    end
    state.collectionBook.pieces[item.itemID] = tier
    -- A higher-tier piece also fills lower-tier gaps without conversion rewards.
    local counters = state.collectionBook.counters[setID] or {}
    for rank in pairs(counters) do
        if rank <= tier and (previous == nil or previous < rank) then
            counters[rank] = 0
        end
    end
    G.Log(
        state,
        collection.name
            .. ": "
            .. item.name
            .. (previous == nil and " discovered." or " upgraded to tier " .. tier .. "."),
        true
    )
    G.Emit(
        state,
        "collection",
        { setID = setID, itemID = item.itemID, tier = tier, upgrade = previous ~= nil }
    )
    return true, previous == nil and "discovered" or "upgraded"
end

function G.CollectionVictory(state, context)
    if type(context) ~= "table" then
        return nil
    end
    local serial = encounterID(context.receipt)
    local book = state.collectionBook
    if not serial or serial <= (book.lastEncounter or 0) or book.receipts[context.receipt] then
        return nil
    end
    -- Receipt and acquisition are committed in this synchronous command before disposal.
    book.lastEncounter = serial
    book.receipts[context.receipt] = true
    book.receiptOrder[#book.receiptOrder + 1] = context.receipt
    if #book.receiptOrder > receiptLimit then
        book.receipts[table.remove(book.receiptOrder, 1)] = nil
    end
    for _, collection in ipairs(C.collections) do
        if eligible(collection, context) then
            local tier = context.tier or 0
            local progress = assert(G.CollectionProgress(state, collection.id, tier))
            local counters = book.counters[collection.id] or {}
            book.counters[collection.id] = counters
            if #progress.missing > 0 then
                counters[tier] = (counters[tier] or 0) + 1
            end
            local guaranteed = #progress.missing > 0 and counters[tier] >= collection.guarantee
            local itemID
            if guaranteed then
                itemID = progress.missing[G.Random(state, #progress.missing)]
            elseif G.Random(state, 100) <= collection.chance then
                itemID = collection.pieces[G.Random(state, #collection.pieces)]
            end
            if itemID then
                local template = C.itemByID[itemID]
                local item =
                    G.Item(state, template.slot, template.level, template.quality, false, template)
                local acquisition = G.Copy(context)
                acquisition.registration = registration
                G.RegisterCollectionDrop(state, item, acquisition)
                if guaranteed then
                    counters[tier] = 0
                end
                return item
            end
        end
    end
    return nil
end
