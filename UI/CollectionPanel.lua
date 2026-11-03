local _, W = ...
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.CollectionPanel = P

function P.Draw(ui, parent, state)
    local setID = ui.collectionSelected or state.collectionBook.target or C.collections[1].id
    local collection = C.collectionByID[setID] or C.collections[1]
    local progress = G.CollectionProgress(state, collection.id)
    U.Text(parent, "COLLECTION BOOK", 0, 0, 24, T.gold, 1000)
    U.Text(
        parent,
        "Permanent discoveries. Equipment can be used, sold, or salvaged freely.",
        0,
        44,
        15,
        T.text,
        1250
    )
    U.Text(parent, collection.name, 0, 100, 22, T.gold, 900)
    U.Text(parent, collection.description, 0, 135, 14, T.text, 1200)
    local targeted = state.collectionBook.target == collection.id
    local target = U.Button(
        parent,
        targeted and "Clear collection target" or "Target this collection",
        948,
        92,
        330,
        34,
        function()
            local nextTarget
            if not targeted then
                nextTarget = collection.id
            end
            W.Action(G.SetCollectionTarget, nextTarget)
        end
    )
    U.Tooltip(
        target,
        "Collection target",
        "A planning preference. Targeting never changes eligibility, drop chances, or the guarantee."
    )
    for index, itemID in ipairs(collection.pieces) do
        local item = C.itemByID[itemID]
        local tier = state.collectionBook.pieces[itemID]
        local x = (index - 1) * 258
        local card = U.Button(parent, "", x, 190, 244, 190, function() end)
        U.Begin(card)
        local icon = U.Icon(card, item.icon, 12, 14, 48)
        icon:SetParent(card.content or card)
        icon:SetDesaturated(tier == nil)
        icon:SetAlpha(tier == nil and 0.45 or 1)
        U.Text(card, item.name, 72, 15, 14, tier ~= nil and T.gold or T.muted, 162)
        U.Text(
            card,
            tier ~= nil and "Discovered · tier " .. tier or "Undiscovered",
            12,
            83,
            13,
            tier ~= nil and T.green or T.muted,
            220
        )
        U.Text(
            card,
            "Outdoor Westfall\nHumanoid encounters\nIdle level 3+ · tier 0+",
            12,
            115,
            12,
            T.text,
            220
        )
        U.EndBuild(card)
        U.Tooltip(
            card,
            item.name,
            table.concat({
                collection.source,
                "5% chance per eligible victory, then an equal roll among five pieces. Prototype tuning.",
                "Every 30 eligible victories without a new piece at that tier guarantees a random missing piece.",
                "Highest tier: "
                    .. (tier ~= nil and tostring(tier) or "not discovered")
                    .. ". Crafted copies do not count.",
            }, "\n"),
            380
        )
    end
    local rank = progress.completedRank
    local headline = progress.found
        .. "/"
        .. progress.count
        .. " discovered"
        .. (rank ~= nil and " · completed tier " .. rank or " · set incomplete")
    U.Text(parent, headline, 0, 407, 18, T.gold, 1250)
    U.Text(
        parent,
        "Tier "
            .. progress.tier
            .. " upgrade: "
            .. progress.tierFound
            .. "/"
            .. progress.count
            .. " pieces · Missing-piece guarantee: "
            .. progress.counter
            .. "/"
            .. progress.guarantee
            .. " eligible victories",
        0,
        442,
        15,
        T.text,
        1250
    )
    local scale = rank and G.CollectionRankScale(rank) or 1
    U.Text(
        parent,
        string.format(
            "2 pieces: +%.1f%% basic-attack damage    4 pieces: +%.1f%% materials",
            2 * scale,
            3 * scale
        ),
        0,
        486,
        15,
        T.text,
        1250
    )
    U.Text(
        parent,
        string.format(
            "Complete: %.1f%% less damage from humanoids. Higher completed tiers improve these bonuses gently.",
            3 * scale
        ),
        0,
        520,
        15,
        T.text,
        1250
    )
    U.Text(
        parent,
        string.format(
            "Next completed-tier reward: +%.2f%% basic attacks, +%.2f%% materials, %.2f%% humanoid defense.",
            2 * G.CollectionRankScale(progress.tier),
            3 * G.CollectionRankScale(progress.tier),
            3 * G.CollectionRankScale(progress.tier)
        ),
        0,
        553,
        13,
        T.muted,
        1250
    )
    U.Text(
        parent,
        "Minigame sources and prototype chances. Discoveries, bonuses, ranks, and guarantee progress survive resets.",
        0,
        598,
        13,
        T.muted,
        1260
    )
end
