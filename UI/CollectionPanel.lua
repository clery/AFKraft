local _, W = ...
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.CollectionPanel = P

function P.SourceLabel(source)
    return source
            and ((source.familyName or "Eligible creatures") .. " · " .. (source.zone or "Unknown location"))
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
    local details =
        string.format("%.2f%% chance per eligible kill (base %.2f%%).", chance, profile.chance)
    for _, talent in ipairs(C.collectionTalents) do
        local rank = state.collectionTalents[talent.id] or 0
        if rank > 0 then
            local active = talent.kind == (profile.kind or "outdoor")
            details = details
                .. "\n"
                .. talent.name
                .. ": "
                .. (
                    active and string.format("Active (+%.0f%% of base)", bonus * 100)
                    or "Inactive (" .. talent.condition .. " only)"
                )
        end
    end
    return details .. "\nEach kill rolls independently; no guaranteed drop."
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
    U.Text(frame, "SET CATALOG", 0, 0, 24, T.gold, 800)
    U.Help(
        frame,
        "Collections",
        1258,
        0,
        "Hover a piece for its source and chance. Gray pieces are missing.\n\nDiscover pieces through eligible real WoW kills. Idle battles and crafting do not count. Discoveries and passive bonuses survive both resets.\n\nComplete a set to select its effect. Only one set effect can be active."
    )
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
            status.complete and "Complete" or status.found .. "/" .. status.count,
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
        U.Text(card, item.name, 74, 25, 15, found and T.gold or T.muted, 210)
        U.EndBuild(card)
        local details = P.SourceLabel(source)
        if profile and profile.enabled and profile.verified and source and source.verified then
            details = details .. "\n\n" .. P.DropChanceLabel(state, profile)
        else
            details = "Hunting unavailable on this client build. Sources are not verified. "
                .. "Discoveries already earned are kept."
        end
        U.Tooltip(card, item.name, details, 400)
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
                " | %s%s hunt: %d kills | Finds: %d",
                meaningful and "Session" or "Previous",
                kind == "dungeon" and " dungeon" or "",
                report.kills,
                report.discoveries
            )
        or previous and kind == "dungeon" and " | Previous dungeon hunt: Unrecorded"
        or ""
    ui.collectionProgress = U.Text(
        parent,
        progress.found
            .. "/"
            .. progress.count
            .. " pieces · "
            .. book.stats.kills
            .. " eligible "
            .. kind
            .. " kills"
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
        active and "Clear set effect" or "Select set effect",
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
                "%.0f%% less damage from %s",
                (1 - collection.effect.damageTaken) * 100,
                collection.effect.family
            )
        or string.format("+%.0f%% basic-attack damage", (collection.effect.basicAttack or 0) * 100)
    U.Tooltip(
        ui.collectionEffect,
        "One active collection effect",
        "Complete the set to select: "
            .. effectText
            .. ". Replaces your current set effect. Passive discovery bonuses stay active."
    )
    U.Text(parent, "SET BONUSES", 0, 378, 16, T.gold, 930)
    ui.collectionMilestones = U.Text(
        parent,
        string.format(
            "%d pieces: +%.1f%% basic-attack damage\n%d pieces: +%.1f%% materials\nComplete: %s (selectable)",
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
        active and "Active effect: " .. collection.name
            or "Active effect: " .. (effectID and C.collectionByID[effectID].name or "none"),
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
                        and " · legacy completed tier " .. record.completedRank
                    or " · incomplete"
                )
        end
    end
    local bonus = G.LegacyCollectionBonuses(state, "humanoid")
    ui.collectionLegacyStatus = U.Text(
        parent,
        #legacy > 0 and "LEGACY COLLECTIONS · " .. table.concat(legacy, " | ") or "",
        0,
        500,
        13,
        T.gold,
        930
    )
    if #legacy > 0 then
        U.Help(
            parent,
            "Earlier collection bonuses",
            900,
            500,
            string.format(
                "Earlier discoveries are retained; these retired pieces no longer drop.\n\nBasic-attack damage: +%.2f%%\nMaterials: +%.2f%%\nHumanoid damage taken: -%.2f%%",
                (bonus.basicAttack - 1) * 100,
                (bonus.materials - 1) * 100,
                (1 - bonus.damageTaken) * 100
            )
        )
    end
    U.EndBuild(parent)
end
