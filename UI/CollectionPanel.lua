local _, W = ...
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.CollectionPanel = P

function P.SourceLabel(source)
    return source
            and ((source.familyName or "Eligible creatures") .. " · " .. (source.zone or "Unknown location"))
        or "Sources unverified"
end

function P.SourceProfile(kind)
    kind = kind or "outdoor"
    local sources = W.CollectionSources
    if not sources then
        return nil
    end
    local active = sources.ActiveProfile and sources.ActiveProfile(kind)
    if active then
        return active
    end
    local ids = {}
    for id, profile in pairs(sources.profiles or {}) do
        if profile.flavor == W.Client.flavor and (profile.kind or "outdoor") == kind then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return ids[1] and sources.profiles[ids[1]] or nil
end

function P.TrackedPiece(state)
    local id = G.CollectionTarget(state)
    local item = id and G.CollectionItem(id)
    if not item then
        return nil
    end
    local collection = C.collectionByID[C.collectionByItem[id]]
    local book = G.CollectionBook(state, collection.id)
    local profile = P.SourceProfile(collection.kind)
    local source = profile and profile.sources[id]
    local counters = profile and book.counters[profile.id]
    return {
        item = item,
        source = source,
        found = book.pieces[id] == true,
        kind = collection.kind,
        available = profile and profile.enabled and profile.verified and source and source.verified
            or false,
        count = counters and counters[id] or 0,
        guarantee = profile and profile.guarantee,
    }
end

function P.Draw(ui, parent, state)
    local collection = C.collectionByID[ui.collectionSelected] or C.collections[1]
    local progress = G.CollectionProgress(state, collection.id)
    local book = G.CollectionBook(state, collection.id)
    local selected = C.collectionByItem[ui.collectionPiece] == collection.id and ui.collectionPiece
        or C.collectionByItem[book.target] == collection.id and book.target
        or progress.missing[1]
        or collection.pieces[1]
    ui.collectionSelected, ui.collectionPiece = collection.id, selected
    local kind = collection.kind or "outdoor"
    local profile = P.SourceProfile(kind)
    local enabled = profile and profile.enabled and profile.verified
    local counters = profile and book.counters[profile.id] or {}
    counters = counters or {}
    U.Text(parent, "COLLECTIONS", 0, 0, 24, T.gold, 1000)
    U.Text(
        parent,
        "Track pieces from attributed creature kills. Discoveries survive resets.",
        0,
        44,
        15,
        T.text,
        1280
    )
    ui.collectionChoices = {}
    for index, entry in ipairs(C.collections) do
        ui.collectionChoices[entry.id] = U.Button(
            parent,
            entry.name,
            700 + (index - 1) * 290,
            0,
            280,
            34,
            function()
                ui.collectionSelected, ui.collectionPiece = entry.id, nil
                ui:Refresh()
            end,
            collection.id == entry.id
        )
    end
    U.Text(parent, collection.name, 0, 94, 22, T.gold, 1280)
    U.Text(parent, collection.description, 0, 130, 14, T.text, 1280)
    ui.collectionSourceStatus = U.Text(
        parent,
        enabled and profile and "Verified " .. kind .. " sources"
            or kind .. " acquisition disabled: this client's sources are unverified.",
        0,
        166,
        14,
        enabled and T.green or T.muted,
        1280
    )
    ui.collectionCards = {}
    for index, itemID in ipairs(collection.pieces) do
        local item = G.CollectionItem(itemID)
        local found = book.pieces[itemID] == true
        local source = profile and profile.sources[itemID]
        local verified = enabled and source and source.verified
        local count, guarantee = counters[itemID] or 0, profile and profile.guarantee or 0
        local card = U.Button(parent, "", (index - 1) * 258, 204, 244, 190, function()
            ui.collectionPiece = itemID
            ui:Refresh()
        end, selected == itemID)
        ui.collectionCards[itemID] = card
        U.Begin(card)
        local icon = U.Icon(card, item.icon, 12, 14, 48)
        icon:SetParent(card.content or card)
        icon:SetDesaturated(not found)
        icon:SetAlpha(found and 1 or 0.45)
        U.Text(card, item.name, 72, 15, 14, found and T.gold or T.muted, 162)
        U.Text(
            card,
            (found and "Discovered" or "Undiscovered")
                .. (book.target == itemID and " · Targeted" or ""),
            12,
            82,
            13,
            found and T.green or T.muted,
            220
        )
        U.Text(
            card,
            found and "Recorded permanently"
                or profile and "Saved progress " .. count .. "/" .. guarantee
                or "No acquisition profile",
            12,
            108,
            12,
            T.text,
            220
        )
        U.Text(
            card,
            verified and P.SourceLabel(source) or "Source unverified",
            12,
            136,
            12,
            T.muted,
            220
        )
        U.EndBuild(card)
        local evidence = source and P.SourceLabel(source) or "No source evidence for this client."
        local tuning = profile
                and string.format(
                    "Prototype: %.1f%% per eligible kill for this piece; guaranteed by %d eligible kills.",
                    profile.chance,
                    guarantee
                )
            or "No acquisition profile available."
        U.Tooltip(
            card,
            item.name,
            table.concat({
                evidence,
                verified and "Verified " .. kind .. " source."
                    or "Candidate source only. Acquisition remains disabled until verified for this client.",
                tuning,
                "Saved eligible-kill progress: "
                    .. count
                    .. ". The same creature cannot count twice.",
                "Tracking changes the selected target only; it never changes drop chances. Only attributed real kills in the correct location discover pieces; idle combat and crafted items do not.",
            }, "\n"),
            400
        )
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
            .. " pieces discovered · "
            .. book.stats.kills
            .. " eligible "
            .. kind
            .. " kills"
            .. sessionText,
        0,
        420,
        18,
        T.gold,
        1296
    )
    ui.collectionTarget = U.Button(
        parent,
        book.target == selected and "Clear piece target" or "Track selected piece",
        0,
        460,
        380,
        34,
        function()
            local target = book.target ~= selected and selected or nil
            W.Action(G.SetCollectionTarget, target)
        end
    )
    local effectID = G.ActiveCollectionEffect(state)
    local active = effectID == collection.id
    ui.collectionEffect = U.Button(
        parent,
        active and "Clear active collection effect" or "Select completed-set effect",
        420,
        460,
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
                "%.0f%% reduced %s damage",
                (1 - collection.effect.damageTaken) * 100,
                collection.effect.family
            )
        or string.format("+%.0f%% basic attacks", (collection.effect.basicAttack or 0) * 100)
    U.Tooltip(
        ui.collectionEffect,
        "One active collection effect",
        "Complete every piece to select this set's "
            .. effectText
            .. " effect. Selecting it replaces the previously selected collection effect. Partial-set bonuses remain permanent."
    )
    U.Text(
        parent,
        "2 pieces: +0.5% basic attacks · 4 pieces: +0.5% materials · Complete: selectable "
            .. effectText,
        0,
        512,
        14,
        T.text,
        1280
    )
    ui.collectionEffectStatus = U.Text(
        parent,
        active and "Active effect: " .. collection.name
            or "Active effect: " .. (effectID and C.collectionByID[effectID].name or "none"),
        0,
        544,
        14,
        active and T.green or T.muted,
        1280
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
        #legacy > 0 and "PROTECTED LEGACY HISTORY · " .. table.concat(legacy, " | ")
            or "LEGACY HISTORY · Previous idle discoveries are retained separately.",
        0,
        592,
        13,
        T.gold,
        1280
    )
    U.Text(
        parent,
        string.format(
            "Protected legacy value: +%.2f%% basic attacks · +%.2f%% materials · %.2f%% humanoid defense. No new legacy drops.",
            (bonus.basicAttack - 1) * 100,
            (bonus.materials - 1) * 100,
            (1 - bonus.damageTaken) * 100
        ),
        0,
        624,
        13,
        T.muted,
        1280
    )
end
