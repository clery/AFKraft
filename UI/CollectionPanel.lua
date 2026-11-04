local _, W = ...
local L = W.L
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.CollectionPanel = P

function P.SourceLabel(source)
    return source
            and ((source.familyName or L.ELIGIBLE_CREATURES) .. " · " .. (source.zone or L.UNKNOWN_LOCATION))
        or ""
end

function P.SourceProfile(kind)
    local sources = W.CollectionSources
    return sources and sources.ActiveProfile and sources.ActiveProfile(kind or "outdoor") or nil
end

local function createBrowser(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.scroll = CreateFrame("ScrollFrame", nil, frame)
    frame.scroll:SetPoint("TOPLEFT", 0, -48)
    frame.scroll:SetSize(316, 520)
    frame.scroll:SetClipsChildren(true)
    frame.catalog = CreateFrame("Frame", nil, frame.scroll)
    frame.catalog:SetSize(316, math.max(520, #C.collections * 70))
    frame.scroll:SetScrollChild(frame.catalog)
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPLEFT", 330, -48)
    frame.scrollBar:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", 14, 0)
    frame.scrollBar:RegisterCallback("OnScroll", function(_, percentage)
        frame.scroll:SetVerticalScroll(
            percentage * math.max(0, frame.catalog:GetHeight() - frame.scroll:GetHeight())
        )
        GameTooltip:Hide()
    end, frame)
    frame.scroll:EnableMouseWheel(true)
    frame.scroll:SetScript("OnMouseWheel", function(_, delta)
        local maximum = math.max(0, frame.catalog:GetHeight() - frame.scroll:GetHeight())
        if maximum > 0 then
            frame.scrollBar:SetScrollPercentage(
                math.max(0, math.min(1, (frame.scroll:GetVerticalScroll() - delta * 70) / maximum))
            )
        end
    end)
    frame.detail = CreateFrame("Frame", nil, frame)
    frame.detail:SetPoint("TOPLEFT", 366, -48)
    frame.detail:SetSize(930, 540)
    return frame
end

function P.DropChanceLabel(state, profile)
    local chance, bonus = G.CollectionDropChance(state, profile)
    local details = string.format(L.CHANCE_PER_ELIGIBLE_KILL_BASE, chance, profile.chance)
    for _, talent in ipairs(C.collectionTalents) do
        local rank = state.collectionTalents[talent.id] or 0
        if rank > 0 then
            local active = talent.kind == (profile.kind or "outdoor")
            details = details
                .. "\n"
                .. talent.name
                .. ": "
                .. (
                    active and string.format(L.ACTIVE_OF_BASE, bonus * 100)
                    or L.INACTIVE .. talent.condition .. L.ONLY_SUFFIX
                )
        end
    end
    return details .. L.EACH_KILL_ROLLS_INDEPENDENTLY_NO_GUARANTEED_DROP_SUFFIX
end

function P.Draw(ui, parent, state)
    local collection = C.collectionByID[ui.collectionSelected] or C.collections[1]
    local progress = G.CollectionProgress(state, collection.id)
    local book = G.CollectionBook(state, collection.id)
    ui.collectionSelected = collection.id
    local kind = collection.kind or "outdoor"
    local profile = P.SourceProfile(kind)
    ui.collectionFrame = ui.collectionFrame or createBrowser(parent)
    local frame = ui.collectionFrame
    frame:Show()
    U.Begin(frame)
    U.Text(frame, L.SET_CATALOG_HEADING, 0, 0, 24, T.gold, 800)
    U.Help(frame, L.COLLECTIONS, 1258, 0, L.HOVER_A_PIECE_FOR_ITS_SOURCE_AND_CHANCE_GRAY)
    U.EndBuild(frame)
    U.Begin(frame.catalog)
    ui.collectionRows = {}
    for index, entry in ipairs(C.collections) do
        local status = G.CollectionProgress(state, entry.id)
        local row = U.SelectButton(frame.catalog, "", 0, (index - 1) * 70, 310, 64, function()
            ui.collectionSelected = entry.id
            ui:Refresh()
        end, collection.id == entry.id)
        ui.collectionRows[entry.id] = row
        U.Begin(row)
        local icon = U.Icon(row, G.CollectionItem(entry.pieces[1]).icon, 10, 12, 38)
        icon:SetParent(row.content or row)
        icon:SetDesaturated(not status.complete)
        U.SingleLine(U.Text(row, entry.name, 58, 9, 14, T.gold), 240, 22)
        row.statusText = U.Text(
            row,
            status.complete and L.COMPLETE or status.found .. "/" .. status.count,
            58,
            35,
            13,
            status.complete and T.green or T.muted,
            240
        )
        U.EndBuild(row)
    end
    U.EndBuild(frame.catalog)
    parent = frame.detail
    U.Begin(parent)
    U.Text(parent, collection.name, 0, 0, 22, T.gold, 880)
    U.Help(parent, collection.name, 900, 0, collection.description)
    ui.collectionCards = {}
    for index, itemID in ipairs(collection.pieces) do
        local item = G.CollectionItem(itemID)
        local found = book.pieces[itemID] == true
        local source = profile and profile.sources[itemID]
        local card =
            U.Card(parent, ((index - 1) % 3) * 312, 54 + math.floor((index - 1) / 3) * 104, 296, 92)
        ui.collectionCards[itemID] = card
        U.Begin(card)
        card.icon = U.Icon(card, item.icon, 12, 22, 48)
        card.icon:SetParent(card.content or card)
        card.icon:SetDesaturated(not found)
        card.icon:SetAlpha(found and 1 or 0.45)
        U.Text(card, G.ItemName(item), 74, 25, 15, found and T.gold or T.muted, 210)
        U.EndBuild(card)
        local details = P.SourceLabel(source)
        if profile and profile.enabled and profile.verified and source and source.verified then
            details = details .. "\n\n" .. P.DropChanceLabel(state, profile)
        else
            details = L.HUNTING_UNAVAILABLE_ON_THIS_CLIENT_BUILD_SOURCES_ARE_NOT_PREFIX
                .. L.DISCOVERIES_ALREADY_EARNED_ARE_KEPT
        end
        U.Tooltip(card, G.ItemName(item), details, 400)
    end
    local session = G.HuntSessionSummary(state, W.Client.Now())
    local current = kind == "dungeon" and session and session.dungeon
        or kind == "outdoor" and session
    local meaningful = current and (current.kills > 0 or current.discoveries > 0)
    local previous = state.lastHuntSummary
    local report = meaningful and current
        or previous
            and (kind == "dungeon" and previous.dungeon or kind == "outdoor" and previous)
    local sessionText = report
            and string.format(
                L.HUNT_KILLS_FINDS_SUFFIX,
                meaningful and L.SESSION or L.PREVIOUS,
                kind == "dungeon" and L.DUNGEON_SUFFIX or "",
                report.kills,
                report.discoveries
            )
        or previous and kind == "dungeon" and L.PREVIOUS_DUNGEON_HUNT_UNRECORDED_SUFFIX
        or ""
    ui.collectionProgress = U.Text(
        parent,
        progress.found
            .. "/"
            .. progress.count
            .. L.FRAGMENT_PIECES
            .. book.stats.kills
            .. L.FRAGMENT_ELIGIBLE
            .. kind
            .. L.KILLS_SUFFIX
            .. sessionText,
        0,
        330,
        14,
        T.gold,
        930
    )
    local effectID = G.ActiveCollectionEffect(state)
    local active = effectID == collection.id
    ui.collectionEffect = U.Button(
        parent,
        active and L.CLEAR_SET_EFFECT or L.SELECT_SET_EFFECT,
        0,
        272,
        440,
        34,
        function()
            local effect = not active and collection.id or nil
            W.Action(G.SetCollectionEffect, effect)
        end
    )
    U.Enabled(ui.collectionEffect, progress.complete)
    local effectText = collection.effect.damageTaken
            and string.format(
                L.LESS_DAMAGE_FROM,
                (1 - collection.effect.damageTaken) * 100,
                collection.effect.family
            )
        or string.format(L.BASIC_ATTACK_DAMAGE, (collection.effect.basicAttack or 0) * 100)
    U.Tooltip(
        ui.collectionEffect,
        L.ONE_ACTIVE_COLLECTION_EFFECT,
        L.COMPLETE_THE_SET_TO_SELECT_PREFIX
            .. effectText
            .. L.REPLACES_YOUR_CURRENT_SET_EFFECT_PASSIVE_DISCOVERY_BONUSES_STAY
    )
    U.Text(parent, L.SET_BONUSES_HEADING, 0, 378, 16, T.gold, 930)
    ui.collectionMilestones = U.Text(
        parent,
        string.format(
            L.PIECES_BASIC_ATTACK_DAMAGE_PIECES_MATERIALS_COMPLETE_SELECTABLE,
            collection.milestones.basicAttack.pieces,
            collection.milestones.basicAttack.bonus * 100,
            collection.milestones.materials.pieces,
            collection.milestones.materials.bonus * 100,
            effectText
        ),
        0,
        400,
        14,
        T.text,
        930
    )
    ui.collectionEffectStatus = U.Text(
        parent,
        active and L.ACTIVE_EFFECT_PREFIX .. collection.name
            or L.ACTIVE_EFFECT_PREFIX
                .. (effectID and C.collectionByID[effectID].name or L.NONE),
        0,
        466,
        14,
        active and T.green or T.muted,
        930
    )
    local legacy = {}
    for _, old in ipairs(C.legacyCollections) do
        local record = G.LegacyCollectionProgress(state, old.id)
        if record.found > 0 then
            legacy[#legacy + 1] = old.name
                .. ": "
                .. record.found
                .. "/"
                .. record.count
                .. (
                    record.completedRank
                        and L.FRAGMENT_LEGACY_COMPLETED_TIER .. record.completedRank
                    or L.INCOMPLETE_SUFFIX
                )
        end
    end
    local bonus = G.LegacyCollectionBonuses(state, "humanoid")
    ui.collectionLegacyStatus = U.Text(
        parent,
        #legacy > 0 and L.LEGACY_COLLECTIONS_HEADING .. table.concat(legacy, " | ") or "",
        0,
        500,
        13,
        T.gold,
        930
    )
    if #legacy > 0 then
        U.Help(
            parent,
            L.EARLIER_COLLECTION_BONUSES,
            900,
            500,
            string.format(
                L.EARLIER_DISCOVERIES_ARE_RETAINED_THESE_RETIRED_PIECES_NO_LONGER,
                (bonus.basicAttack - 1) * 100,
                (bonus.materials - 1) * 100,
                (1 - bonus.damageTaken) * 100
            )
        )
    end
    U.EndBuild(parent)
end
