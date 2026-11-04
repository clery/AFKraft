local _, W = ...
local G, C = W.Game, W.Content
local floor, min = math.floor, math.min
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

local function profileID(id)
    return type(id) == "string" and #id > 0 and #id <= 80 and not id:find("%c")
end

local function killNPC(receipt)
    if type(receipt) ~= "string" or #receipt > 160 then
        return nil
    end
    local id = tonumber(receipt:match("^kill:Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
    return integer(id) and id > 0 and id or nil
end

local function sourceProfile(id)
    local sources = W.CollectionSources
    if not sources then
        return nil
    end
    if sources.Profile then
        return sources.Profile(id)
    end
    return sources.profiles and sources.profiles[id]
end

local function validProfile(profile, id)
    return type(profile) == "table"
        and profile.id == id
        and type(profile.chance) == "number"
        and profile.chance >= 0
        and profile.chance <= 100
end

local function validLegacy(state)
    local book = state.collectionBook
    if
        type(book) ~= "table"
        or type(book.pieces) ~= "table"
        or type(book.counters) ~= "table"
        or type(book.receipts) ~= "table"
        or type(book.receiptOrder) ~= "table"
        or (book.target ~= nil and not C.legacyCollectionByID[book.target])
        or (book.lastEncounter ~= nil and not integer(book.lastEncounter))
    then
        return false
    end
    for itemID, tier in pairs(book.pieces) do
        if not C.legacyCollectionByItem[itemID] or not integer(tier) then
            return false
        end
    end
    for setID, tiers in pairs(book.counters) do
        local collection = C.legacyCollectionByID[setID]
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

function G.LegacyCollectionProgress(state, setID, tier)
    local collection = C.legacyCollectionByID[setID]
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

function G.CollectionRankScale(rank)
    return 1 + 0.2 * rank / (rank + 1)
end

function G.LegacyCollectionBonuses(state, enemyFamily)
    local result = { basicAttack = 1, materials = 1, damageTaken = 1 }
    for _, collection in ipairs(C.legacyCollections) do
        local progress = assert(G.LegacyCollectionProgress(state, collection.id))
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

local function emptyOutdoor()
    return {
        version = 1,
        pieces = {},
        counters = {},
        receipts = {},
        stats = { kills = 0, discoveries = 0 },
    }
end

local function belongs(itemID, kind)
    local id = C.collectionByItem[itemID]
    return id and (C.collectionByID[id].kind or "outdoor") == kind
end

local function validBook(book, kind)
    if
        type(book) ~= "table"
        or book.version ~= 1
        or type(book.pieces) ~= "table"
        or type(book.counters) ~= "table"
        or type(book.receipts) ~= "table"
        or type(book.stats) ~= "table"
        or not integer(book.stats.kills)
        or book.stats.kills > 1000000000
        or not integer(book.stats.discoveries)
        or book.stats.discoveries > 1000000000
        or (
            book.effect ~= nil
            and (
                not C.collectionByID[book.effect]
                or (C.collectionByID[book.effect].kind or "outdoor") ~= kind
            )
        )
    then
        return false
    end
    local found = 0
    for itemID, discovered in pairs(book.pieces) do
        if not belongs(itemID, kind) or discovered ~= true then
            return false
        end
        found = found + 1
    end
    if book.stats.discoveries > found then
        return false
    end
    for id, receipts in pairs(book.receipts) do
        local profile = profileID(id) and sourceProfile(id)
        if
            type(profile) ~= "table"
            or not validProfile(profile, id)
            or (profile.kind or "outdoor") ~= kind
            or type(receipts) ~= "table"
        then
            return false
        end
        for itemID, pending in pairs(receipts) do
            if not belongs(itemID, kind) or type(pending) ~= "table" then
                return false
            end
            local count = 0
            for receipt, value in pairs(pending) do
                if not killNPC(receipt) or value ~= true then
                    return false
                end
                count = count + 1
            end
            if count > receiptLimit then
                return false
            end
        end
    end
    book.target = nil
    book.counters = {}
    if book.effect then
        for _, itemID in ipairs(C.collectionByID[book.effect].pieces) do
            if not book.pieces[itemID] then
                return false
            end
        end
    end
    return true
end

function G.ValidateCollections(state)
    if not validLegacy(state) then
        return false
    end
    if state.outdoorCollections == nil then
        local book = emptyOutdoor()
        for itemID in pairs(state.collectionBook.pieces) do
            if belongs(itemID, "outdoor") then
                book.pieces[itemID] = true
            end
        end
        state.outdoorCollections = book
    end
    if state.dungeonCollections == nil then
        state.dungeonCollections = emptyOutdoor()
    end
    return validBook(state.outdoorCollections, "outdoor")
        and validBook(state.dungeonCollections, "dungeon")
        and not (state.outdoorCollections.effect and state.dungeonCollections.effect)
end

function G.CollectionBook(state, setID)
    local collection = C.collectionByID[setID]
    return collection and collection.kind == "dungeon" and state.dungeonCollections
        or state.outdoorCollections
end

function G.CollectionItem(itemID)
    return C.itemByID[itemID] or C.collectionItemByID[itemID]
end

function G.ActiveCollectionEffect(state)
    return state.outdoorCollections.effect or state.dungeonCollections.effect
end

function G.CollectionProgress(state, setID)
    local collection = C.collectionByID[setID]
    if not collection then
        return nil
    end
    local found, missing = 0, {}
    local book = G.CollectionBook(state, setID)
    for _, itemID in ipairs(collection.pieces) do
        if book.pieces[itemID] then
            found = found + 1
        else
            missing[#missing + 1] = itemID
        end
    end
    return {
        found = found,
        count = #collection.pieces,
        complete = found == #collection.pieces,
        missing = missing,
    }
end

function G.CollectionEffectStatus(state, setID)
    if setID == nil then
        return true, "No collection effect selected."
    end
    local collection = setID and C.collectionByID[setID]
    if not collection then
        return false, "No collection effect selected."
    end
    local progress = G.CollectionProgress(state, setID)
    if not progress or not progress.complete then
        return false, "Complete " .. collection.name .. " to use its effect."
    end
    return true,
        G.ActiveCollectionEffect(state) == setID and "Active collection effect."
            or "Ready to select."
end

function G.SetCollectionEffect(state, setID)
    if setID ~= nil then
        local eligible, reason = G.CollectionEffectStatus(state, setID)
        if not eligible then
            return false, reason
        end
    end
    state.outdoorCollections.effect, state.dungeonCollections.effect = nil, nil
    if setID then
        G.CollectionBook(state, setID).effect = setID
    end
    return true
end

function G.CollectionBonuses(state, enemyFamily)
    local legacy = G.LegacyCollectionBonuses(state, enemyFamily)
    local partial = { basicAttack = 0, materials = 0 }
    for _, collection in ipairs(C.collections) do
        local progress = assert(G.CollectionProgress(state, collection.id))
        for stat, milestone in pairs(collection.milestones) do
            if partial[stat] and progress.found >= milestone.pieces then
                partial[stat] = math.min(0.05, partial[stat] + milestone.bonus)
            end
        end
    end
    local effect = G.ActiveCollectionEffect(state)
    local selected = effect and C.collectionByID[effect]
    local selectedProgress = selected and G.CollectionProgress(state, effect)
    local bonuses = selectedProgress and selectedProgress.complete and selected.effect or {}
    return {
        basicAttack = math.max(
            legacy.basicAttack,
            1 + partial.basicAttack + (bonuses.basicAttack or 0)
        ),
        materials = math.max(legacy.materials, 1 + partial.materials + (bonuses.materials or 0)),
        damageTaken = math.min(
            legacy.damageTaken,
            bonuses.family == enemyFamily and (bonuses.damageTaken or 1) or 1
        ),
    }
end

-- Idle victories and physical item acquisition no longer roll outdoor discoveries.
function G.CollectionVictory()
    return nil
end
function G.RegisterCollectionDrop()
    return false
end

function G.CollectionKill(state, context)
    local kind = type(context) == "table"
        and (context.kind or (context.outdoor == true and "outdoor"))
    if
        type(context) ~= "table"
        or (kind ~= "outdoor" and kind ~= "dungeon")
        or (kind == "dungeon" and (context.dungeon ~= true or (context.outdoor ~= nil and context.outdoor ~= false)))
        or (kind == "outdoor" and (context.outdoor ~= true or (context.dungeon ~= nil and context.dungeon ~= false)))
        or context.attributed ~= true
        or not profileID(context.profile)
        or not integer(context.npcID)
        or context.npcID < 1
        or killNPC(context.receipt) ~= context.npcID
        or state.offline
    then
        return false, "This is not an attributed collection creature kill."
    end
    local sources = W.CollectionSources
    if not sources or type(sources.Eligible) ~= "function" then
        return false, "Collection sources are unavailable."
    end
    local eligible, profile = sources.Eligible(context.profile, context.npcID, kind)
    if
        type(profile) ~= "table"
        or not validProfile(profile, context.profile)
        or (profile.kind or "outdoor") ~= kind
        or profile.enabled ~= true
        or profile.verified ~= true
        or type(eligible) ~= "table"
    then
        return false, "This collection source is not enabled and verified."
    end
    local book = kind == "dungeon" and state.dungeonCollections or state.outdoorCollections
    if type(book) ~= "table" then
        return false, "Collections are unavailable."
    end
    local pending, unique = {}, {}
    local receipts = book.receipts[context.profile] or {}
    for _, itemID in ipairs(eligible) do
        if not belongs(itemID, kind) then
            return false, "The source references an unknown collection piece."
        end
        if not unique[itemID] then
            unique[itemID] = true
            if
                not book.pieces[itemID]
                and not (receipts[itemID] and receipts[itemID][context.receipt])
            then
                pending[#pending + 1] = itemID
            end
        end
    end
    if #pending == 0 then
        return false, "No unfinished piece can count this kill."
    end
    book.receipts[context.profile] = receipts
    local discoveries = {}
    for _, itemID in ipairs(pending) do
        receipts[itemID] = receipts[itemID] or {}
        local discovered = G.Random(state, 100) <= profile.chance
        if discovered then
            book.pieces[itemID] = true
            for _, ledger in pairs(book.receipts) do
                ledger[itemID] = nil
            end
            discoveries[#discoveries + 1] = itemID
        else
            local count = 0
            for _ in pairs(receipts[itemID]) do
                count = count + 1
            end
            -- shortcut: retain 128 receipts per piece; expand if delayed duplicate signals exceed this window.
            if count >= receiptLimit then
                receipts[itemID][next(receipts[itemID])] = nil
            end
            receipts[itemID][context.receipt] = true
        end
    end
    book.stats.kills = book.stats.kills + 1
    book.stats.discoveries = book.stats.discoveries + #discoveries
    for _, itemID in ipairs(discoveries) do
        local item = G.CollectionItem(itemID)
        G.Log(
            state,
            (item and item.name or tostring(itemID))
                .. " discovered in the "
                .. kind
                .. " collection.",
            true
        )
        G.Emit(state, "collection", { itemID = itemID, setID = C.collectionByItem[itemID] })
    end
    return true, { discoveries = discoveries, progressed = #pending }
end
