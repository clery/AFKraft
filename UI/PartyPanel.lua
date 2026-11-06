local _, W = ...
local L = W.L
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local Party = {}
W.PartyPanel = Party
local slotIcons = {
    "INV_Sword_04",
    "INV_Chest_Chain_05",
    "INV_Helmet_03",
    "INV_Misc_Cape_11",
    false,
    false,
    "INV_Shoulder_05",
    "INV_Gauntlets_05",
    "INV_Belt_03",
    "INV_Pants_02",
    "INV_Boots_05",
    "INV_Bracer_07",
}

local function line(parent, value, x, y, width, size, color)
    return U.SingleLine(
        U.Text(parent, value, x, y, size or 13, color or T.text),
        width,
        (size or 13) + 8
    )
end

local function qualityText(item)
    local colors = { "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee" }
    return "|c" .. (colors[item.quality] or colors[1]) .. C.qualityNames[item.quality] .. "|r"
end

local function statGuide(hero)
    return L.PRIMARY_STAT_PREFIX
        .. C.itemStatNames[C.primaryStats[hero.class]]
        .. "|r\n"
        .. L.YOUR_PRIMARY_STAT_INCREASES_DAMAGE_INTELLECT_ALSO_IMPROVES_HEALING_PREFIX
        .. L.STAMINA_MAXIMUM_HEALTH_SPIRIT_HEALING_POWER_HEALING_HASTE_ATTACK_PREFIX
        .. L.POWER_ESTIMATES_ITEM_VALUE_FOR_THIS_CLASS_IT_IS
end

local function costText(state, cost)
    local function amount(value, available, label)
        return (available >= value and "|cffdfbc79" or "|cffff8e82")
            .. value
            .. " "
            .. label
            .. "|r"
    end
    local parts = { amount(cost.gold, state.gold, "gold") }
    for _, id in ipairs(C.materialOrder) do
        local count = cost.materials and cost.materials[id]
        if count and count > 0 then
            parts[#parts + 1] = amount(count, state.materials[id], C.materials[id])
        end
    end
    return table.concat(parts, "  ·  ")
end

local function affordable(state, cost)
    if state.gold < cost.gold then
        return false
    end
    for id, count in pairs(cost.materials or {}) do
        if state.materials[id] < count then
            return false
        end
    end
    return true
end

local function recruit(ui, p, s)
    local available = #s.heroes < G.CompanionSlots(s)
    line(
        p,
        available and L.A_COMPANION_IS_READY_TO_JOIN or L.FIND_YOUR_NEXT_COMPANION,
        0,
        0,
        950,
        23,
        T.gold
    )
    if not available then
        local milestone = G.NextCompanionMilestone(s)
        U.Text(
            p,
            milestone and (L.DEFEAT_A_LEVEL_PREFIX .. milestone .. L.MILESTONE_BOSS_SUFFIX)
                or L.ALL_FIVE_COMPANIONS_HAVE_JOINED_YOUR_COMPANY,
            0,
            54,
            18,
            T.text,
            1000
        )
        U.Button(p, L.BACK_TO_EQUIPMENT, 0, 135, 240, 34, function()
            ui.recruiting = false
            ui:Refresh()
        end)
        return
    end
    U.Text(
        p,
        L.CHOOSE_A_CLASS_FOR_COMPANION_PREFIX .. (#s.heroes + 1) .. L.OF_5_SUFFIX,
        0,
        39,
        14,
        T.muted,
        1030
    )
    local back = U.Button(p, L.BACK_TO_EQUIPMENT, 1090, 0, 206, 34, function()
        ui.recruiting = false
        ui:Refresh()
    end)
    back.text:SetJustifyH("CENTER")
    for i, class in ipairs(C.classes) do
        local id = class.id
        local x, y = (i - 1) % 3 * 440, 90 + math.floor((i - 1) / 3) * 94
        local b = U.SelectButton(p, "", x, y, 416, 76, function()
            if W.Action(G.Recruit, id) then
                ui.selected = #s.heroes
                ui.recruiting = false
                ui:Refresh()
            end
        end)
        b.text:Hide()
        U.Begin(b)
        U.Icon(b, class.icon, 14, 16, 44)
        line(b, class.name, 76, 12, 320, 18, class.color)
        line(b, table.concat(class.paths, "  ·  "), 76, 42, 320, 11, T.muted)
        U.EndBuild(b)
        U.Tooltip(
            b,
            class.name,
            L.RECRUIT_A_NEW_PREFIX
                .. class.name
                .. L.REPEATED_CLASSES_ARE_ALLOWED_A_RECRUIT_JOINS_THE_NEXT
        )
    end
    U.Help(
        p,
        L.RECRUITMENT,
        1030,
        0,
        L.CHOOSE_ANY_CLASS_INCLUDING_DUPLICATES_NAMES_AND_APPEARANCES_ARE
    )
end

local function equipment(ui, p, s, hero, index)
    local class, stats = C.classByID[hero.class], G.Stats(s, hero)
    local outfit = W.ModelAssets.starterOutfits[hero.class] or W.ModelAssets.starterOutfits.MAGE
    line(p, string.format(L.HERO_EQUIPMENT_TITLE, hero.name), 0, 0, 280, 20, class.color)
    U.Help(p, L.EQUIPMENT_STAT_GUIDE, 288, 0, statGuide(hero))
    line(
        p,
        L.LEVEL_PREFIX
            .. hero.level
            .. " "
            .. class.name
            .. "  ·  "
            .. U.Number(stats.hp)
            .. L.HEALTH_SUFFIX,
        0,
        33,
        315,
        13,
        T.muted
    )

    local attributeLines = {}
    for _, key in ipairs(C.itemStatOrder) do
        if (stats.attributes[key] or 0) > 0 then
            attributeLines[#attributeLines + 1] =
                string.format("%s: %.1f", C.itemStatNames[key], stats.attributes[key])
        end
    end
    local development = U.Button(p, L.PARTY_DEVELOPMENT, 332, 0, 240, 34, function()
        ui:SetTab("development")
    end)

    U.Tooltip(
        development,
        L.PERMANENT_PARTY_DEVELOPMENT_EQUIPMENT_STATS,
        L.INVEST_ESSENCE_IN_PARTY_WIDE_BONUSES_IN_GROWTH_RANKS_PREFIX
            .. (
                #attributeLines > 0 and table.concat(attributeLines, "\n")
                or L.NO_EQUIPMENT_BONUSES
            )
    )

    local selectedSlot = C.slots[ui.gearSlot or 1] and (ui.gearSlot or 1) or 1
    local rowStep = 48
    for position, slot in ipairs(C.equipmentSlots) do
        local name = C.slots[slot]
        local id, item = slot, hero.gear[slot]
        local x, y = (position - 1) % 2 * 292, 94 + math.floor((position - 1) / 2) * rowStep
        local b = U.SelectButton(p, "", x, y, 280, rowStep - 4, function()
            ui.gearSlot, ui.bagFilter, ui.bagPage = id, id, 0
            ui:Refresh()
        end, slot == selectedSlot)
        b.text:Hide()
        U.Begin(b)
        U.Icon(b, item and item.icon or slotIcons[slot], 10, 6, rowStep - 20)
            :SetParent(b.content or b)
        line(b, name, 48, 2, item and 184 or 220, 12, slot == selectedSlot and T.gold or T.text)
        line(
            b,
            item and G.ItemName(item) or (outfit[slot] and L.BASIC_CLOTHING or L.EMPTY_SLOT),
            48,
            rowStep - 22,
            item and 184 or 220,
            11,
            item and T.text or T.muted
        )
        if item then
            local cost = G.UpgradeCost(item, s)
            local upgrade = U.Button(b, "+", 242, 7, 30, 30, function()
                if W.Action(G.Upgrade, index, id) then
                    W.Notify(hero.name .. "’s " .. name .. L.GAINED_10_BASE_STATS_SUFFIX)
                end
            end, false, "selection")
            U.Enabled(upgrade, affordable(s, cost))
            upgrade:SetMotionScriptsWhileDisabled(true)
            U.Tooltip(
                upgrade,
                L.IMPROVE_THIS_ITEM,
                L.ADDS_10_OF_THE_BASE_ITEM_STATS_THE_POWER
                    .. "\n\n"
                    .. G.ItemPower(item, hero)
                    .. L.FRAGMENT_TO
                    .. G.ItemPower(item, hero, 1)
                    .. L.FRAGMENT_POWER_2
                    .. costText(s, cost),
                360
            )
        end
        U.EndBuild(b)
        U.Tooltip(
            b,
            item and G.ItemName(item) or name,
            item
                    and (qualityText(item) .. " · " .. G.ItemPower(item, hero) .. L.FRAGMENT_POWER .. G.ItemDescription(
                        item,
                        hero
                    ) .. L.SELECT_TO_VIEW_UPGRADES_AND_MATCHING_INVENTORY_SUFFIX)
                or (outfit[slot] and L.BASIC_CLOTHING_IS_COSMETIC_AND_ADDS_NO_STATS_PREFIX or "")
                    .. L.SELECT_THIS_SLOT_TO_FIND_MATCHING_EQUIPMENT_IN_THE
        )
    end

    local item = hero.gear[selectedSlot]
    if not item then
        line(
            p,
            outfit[selectedSlot] and L.BASIC_CLOTHING_PREFIX .. C.slots[selectedSlot]
                or L.AN_EMPTY_PREFIX .. string.lower(C.slots[selectedSlot]) .. L.SLOT_SUFFIX,
            0,
            351,
            320,
            16,
            T.gold
        )
        U.Button(p, L.CRAFT_EQUIPMENT, 332, 346, 240, 34, function()
            ui.craftSlot = selectedSlot
            ui:SetTab("crafting")
        end)
    end
    local identity = W.Client.Identity()
    if hero.generated and hero.class == identity.class then
        local replace = U.Button(
            p,
            L.USE_PREFIX .. identity.name .. L.AS_THIS_COMPANION_SUFFIX,
            0,
            413,
            572,
            30,
            function()
                W.Action(G.Replace, index, identity)
            end
        )
        U.Enabled(replace, true)
    end
end

local function inventory(ui, p, s, hero, index)
    local filter = C.slots[ui.bagFilter or 0] and ui.bagFilter or 0
    local options, entries = { { id = 0, name = L.ALL_EQUIPMENT } }, {}
    for _, slot in ipairs(C.equipmentSlots) do
        options[#options + 1] = { id = slot, name = C.slots[slot] }
    end
    local view = ui.bagView or {}
    view.availability = view.availability or "usable"
    ui.bagView = view
    entries = G.InventoryEntries(s, hero, filter, view)
    local active, summary = 0, {}
    local function describe(value, default, label)
        if value ~= default then
            active = active + 1
            summary[#summary + 1] = label
        end
    end
    describe(filter, 0, C.slots[filter])
    local availabilityNames = {
        all = L.ANY_AVAILABILITY,
        locked = L.CANNOT_EQUIP,
        usable = L.EQUIPPABLE_NOW,
        upgrades = L.USABLE_UPGRADES,
    }
    local traitNames = {
        all = L.ANY_TRAIT,
        heirloom = L.HEIRLOOMS,
        protected = L.PROTECTED,
        effect = L.WITH_EFFECT,
        upgraded = L.UPGRADED,
    }
    describe(view.availability, "usable", availabilityNames[view.availability])
    describe(view.quality or 0, 0, C.qualityNames[view.quality])
    describe(view.trait or "all", "all", traitNames[view.trait])
    local function reset()
        ui.bagView, ui.bagFilter, ui.bagPage = nil, 0, 0
        ui:Refresh()
    end
    line(p, L.SHARED_INVENTORY_PREFIX .. #s.inventory .. L.STACKS_SUFFIX, 608, 0, 320, 21, T.gold)
    U.Button(p, L.DISENCHANT, 944, 0, 152, 32, function()
        ui.disenchantOpen, ui.disenchantItem, ui.disenchantPage = true, nil, 0
        ui:Refresh()
    end)
    local equipBest = U.Button(p, L.EQUIP_BEST_POWER, 1112, 0, 184, 32, function()
        W.Action(G.EquipBest, index)
    end, false, "primary")
    U.Rect(p, 608, 38, 688, 36, T.panel, 0.65)
    U.Button(
        p,
        (ui.bagFiltersOpen and L.FILTERS or L.FILTERS_2)
            .. (active > 0 and " (" .. active .. ")" or ""),
        608,
        40,
        144,
        32,
        function()
            ui.bagFiltersOpen = not ui.bagFiltersOpen
            ui.bagPage = 0
            ui:Refresh()
        end,
        ui.bagFiltersOpen
    )
    local sorts, sortValue = {}, (view.sort or "power") .. (view.ascending and ":asc" or ":desc")
    for _, option in ipairs({
        { "power", L.POWER, L.HIGH_TO_LOW, L.LOW_TO_HIGH },
        { "level", L.LEVEL, L.HIGH_TO_LOW, L.LOW_TO_HIGH },
        { "quality", L.QUALITY, L.HIGH_TO_LOW, L.LOW_TO_HIGH },
        { "slot", L.EQUIPMENT_SLOT, L.LAST_TO_FIRST, L.FIRST_TO_LAST },
        { "name", L.NAME, L.Z_TO_A, L.A_TO_Z },
    }) do
        sorts[#sorts + 1] = { id = option[1] .. ":desc", name = option[2] .. ": " .. option[3] }
        sorts[#sorts + 1] = { id = option[1] .. ":asc", name = option[2] .. ": " .. option[4] }
    end
    local sortLabel = sorts[1].name
    for _, option in ipairs(sorts) do
        if option.id == sortValue then
            sortLabel = option.name
        end
    end
    line(p, L.SORT, 772, 49, 44, 12, T.muted)
    U.Choice(p, sortLabel, 816, 40, 320, sorts, sortValue, function(id)
        view.sort, view.ascending = id:match("^(.-):"), id:match(":asc$") ~= nil
        ui.bagPage = 0
        ui:Refresh()
    end)
    local clear = U.Button(p, L.CLEAR_FILTERS, 1152, 40, 144, 32, reset)
    U.Enabled(clear, active > 0)
    ui.guideInventoryTarget = active > 0 and clear or nil
    ui.guideInventoryLabel = L.CLEAR_FILTERS
    if ui.bagFiltersOpen then
        U.Rect(p, 608, 78, 688, 70, T.panel, 0.65)
        local function choice(key, title, choices, default, x)
            local value = key == "slot" and filter or view[key] or default
            local label = choices[1].name
            for _, option in ipairs(choices) do
                if option.id == value then
                    label = option.name
                end
            end
            line(p, title, x + 4, 84, 152, 11, T.muted)
            U.Choice(p, label, x, 104, 160, choices, value, function(id)
                if key == "slot" then
                    ui.bagFilter = id
                else
                    view[key] = id
                end
                ui.bagPage = 0
                ui:Refresh()
            end)
        end
        choice("slot", L.EQUIPMENT, options, 0, 608)
        choice("availability", L.AVAILABILITY, {
            { id = "all", name = L.ANY_AVAILABILITY },
            { id = "locked", name = L.CANNOT_EQUIP },
            { id = "usable", name = L.EQUIPPABLE_NOW },
            { id = "upgrades", name = L.USABLE_UPGRADES },
        }, "usable", 784)
        local qualities = { { id = 0, name = L.ANY_QUALITY } }
        for quality, name in ipairs(C.qualityNames) do
            qualities[#qualities + 1] = { id = quality, name = name }
        end
        choice("quality", L.QUALITY, qualities, 0, 960)
        choice("trait", L.ITEM_TRAIT, {
            { id = "all", name = L.ANY_TRAIT },
            { id = "heirloom", name = L.HEIRLOOMS },
            { id = "protected", name = L.PROTECTED },
            { id = "effect", name = L.WITH_EFFECT },
            { id = "upgraded", name = L.UPGRADED },
        }, "all", 1136)
    else
        line(
            p,
            active > 0 and table.concat(summary, "  ·  ") or L.ALL_EQUIPMENT,
            612,
            80,
            680,
            12,
            T.muted
        )
    end
    U.Tooltip(
        equipBest,
        L.EQUIP_BEST_POWER,
        L.EQUIP_THE_HIGHEST_POWER_USABLE_ITEM_IN_EVERY_SLOT_PREFIX
            .. hero.name
            .. L.USES_THE_SHARED_INVENTORY_KEEPS_CURRENT_ITEMS_ON_EQUAL
    )

    local bottom = p:GetHeight() - 34
    local top = ui.bagFiltersOpen and 160 or 104
    local pageSize = math.max(1, math.floor((bottom - top) / 68) * 2)
    local pages = math.max(1, math.ceil(#entries / pageSize))
    local page = math.max(0, math.min(ui.bagPage or 0, pages - 1))
    ui.bagPage = page
    ui.bagCarousel = U.Carousel(
        p,
        608,
        top,
        688,
        bottom - top + 28,
        page,
        pages,
        function(pane, pageIndex, current, carousel)
            for row = 1, pageSize do
                local entry = entries[pageIndex * pageSize + row]
                if entry then
                    local n, item = entry.index, entry.item
                    local x, y = (row - 1) % 2 * 328, math.floor((row - 1) / 2) * 68
                    local power = G.ItemPower(item, hero)
                    local previous = hero.gear[item.slot]
                    local delta = power - G.ItemPower(previous, hero)
                    local usable, restriction = G.CanEquip(hero, item)
                    local b = U.SelectButton(pane, "", x, y, 312, 62, function()
                        if not G.CanEquip(hero, item) then
                            return
                        end
                        ui.gearSlot = item.slot
                        if W.Action(G.Equip, index, n) then
                            W.Notify(
                                L.EQUIPPED_PREFIX
                                    .. G.ItemName(item)
                                    .. L.FRAGMENT_ON
                                    .. hero.name
                                    .. "."
                            )
                        end
                    end)
                    U.CarouselItem(b, carousel)
                    b:EnableMouse(current)
                    if current and usable and item.uid == s.guide.craftItem then
                        ui.guideCraftEquipTarget = b
                    end
                    if current and usable and not ui.guideEquipTarget then
                        ui.guideEquipTarget = b
                    end
                    b.text:Hide()
                    U.Begin(b)
                    U.Enabled(b, usable)
                    b:SetMotionScriptsWhileDisabled(true)
                    U.Icon(b, item.icon or slotIcons[item.slot], 10, 10, 32)
                        :SetParent(b.content or b)
                    line(
                        b,
                        G.ItemName(item) .. ((item.count or 1) > 1 and "  ×" .. item.count or ""),
                        52,
                        4,
                        250,
                        13,
                        C.qualityColors[item.quality]
                    )
                    line(
                        b,
                        C.slots[item.slot]
                            .. "  ·  "
                            .. (item.heirloom and L.HEIRLOOM or L.LEVEL_PREFIX .. item.level)
                            .. "  ·  "
                            .. power
                            .. L.POWER_SUFFIX,
                        52,
                        25,
                        250,
                        11,
                        T.muted
                    )
                    line(
                        b,
                        (delta > 0 and "+" or "") .. delta,
                        212,
                        43,
                        90,
                        12,
                        delta > 0 and T.green or T.muted
                    ):SetJustifyH("RIGHT")
                    U.EndBuild(b)
                    U.Tooltip(
                        b,
                        G.ItemName(item),
                        qualityText(item)
                            .. " · "
                            .. power
                            .. L.FRAGMENT_POWER
                            .. G.ItemDescription(item, hero, true)
                            .. "\n\n"
                            .. (
                                usable and L.CLICK_TO_EQUIP_ON_PREFIX .. hero.name .. "."
                                or "|cffff6060" .. restriction .. "|r"
                            ),
                        320
                    )
                end
            end
        end,
        function(value)
            ui.bagPage = value
            ui:Refresh()
        end
    )
    if #entries == 0 then
        line(
            p,
            #s.inventory == 0 and L.YOUR_FIRST_TREASURES_AWAIT or L.NO_MATCHING_EQUIPMENT,
            632,
            179,
            640,
            21,
            T.text
        )
        U.Text(
            p,
            #s.inventory == 0 and L.WIN_ENCOUNTERS_OR_CRAFT_A_TARGETED_ITEM_EQUIPMENT_IS
                or L.TRY_ANOTHER_FILTER_OR_RESET_THE_INVENTORY_VIEW_TO,
            632,
            221,
            14,
            T.muted,
            610
        )
        U.Button(
            p,
            #s.inventory == 0 and L.VISIT_THE_FORGE or L.RESET_FILTERS,
            632,
            258,
            216,
            34,
            function()
                if #s.inventory == 0 then
                    ui:SetTab("crafting")
                else
                    ui.bagView, ui.bagFilter, ui.bagPage = nil, 0, 0
                    ui:Refresh()
                end
            end
        )
    end
    if not ui.guideInventoryTarget and pages > 1 then
        ui.guideInventoryTarget, ui.guideInventoryLabel = ui.bagCarousel, L.SCROLL_HORIZONTAL_HINT
    end
end

local function disenchant(ui, p, s)
    local entries = G.InventoryEntries(s, s.heroes[ui.selected])
    local pages = math.max(1, math.ceil(#entries / 5))
    local page = math.max(0, math.min(ui.disenchantPage or 0, pages - 1))
    ui.disenchantPage = page
    local selected
    for _, entry in ipairs(entries) do
        if entry.item == ui.disenchantItem then
            selected = entry.item
            break
        end
    end
    -- Never select a neighboring stack automatically after destroying the current one.
    ui.disenchantItem = selected
    line(p, L.DISENCHANT_EQUIPMENT, 0, 0, 900, 22, T.gold)
    U.Button(p, L.BACK_TO_EQUIPMENT, 1096, 0, 200, 32, function()
        ui.disenchantOpen, ui.disenchantItem = false, nil
        ui:Refresh()
    end)
    line(p, L.TURN_SPARE_EQUIPMENT_INTO_GOLD_AND_RELIC_DUST_EQUIPPED, 0, 36, 1296, 14, T.muted)
    line(p, L.STORED_EQUIPMENT_HEADING, 0, 76, 792, 12, T.gold)
    ui.disenchantCarousel = U.Carousel(
        p,
        0,
        102,
        792,
        278,
        page,
        pages,
        function(pane, pageIndex, current, carousel)
            for row = 1, 5 do
                local entry = entries[pageIndex * 5 + row]
                if entry then
                    local item = entry.item
                    local b = U.SelectButton(pane, "", 0, (row - 1) * 50, 752, 46, function()
                        ui.disenchantItem = item
                        ui:Refresh()
                    end, item == selected)
                    U.CarouselItem(b, carousel)
                    b:EnableMouse(current)
                    b.text:Hide()
                    U.Begin(b)
                    U.Enabled(b, true)
                    U.Icon(b, item.icon or slotIcons[item.slot], 12, 7, 32)
                        :SetParent(b.content or b)
                    line(
                        b,
                        G.ItemName(item) .. " ×" .. (item.count or 1),
                        62,
                        4,
                        540,
                        14,
                        C.qualityColors[item.quality]
                    )
                    line(
                        b,
                        C.slots[item.slot]
                            .. " · "
                            .. (item.heirloom and L.HEIRLOOM or L.LEVEL_PREFIX .. item.level)
                            .. " · "
                            .. C.qualityNames[item.quality],
                        62,
                        23,
                        540,
                        11,
                        T.muted
                    )
                    line(
                        b,
                        item.heirloom and L.HEIRLOOM
                            or item.protected and L.PROTECTED
                            or item == selected and L.SELECTED
                            or L.SELECT,
                        616,
                        14,
                        120,
                        12,
                        (item.protected or item.heirloom) and T.gold or T.muted
                    ):SetJustifyH("RIGHT")
                    U.EndBuild(b)
                    U.Tooltip(
                        b,
                        G.ItemName(item),
                        G.ItemDescription(item, s.heroes[ui.selected], true),
                        360
                    )
                end
            end
        end,
        function(value)
            ui.disenchantPage = value
            ui:Refresh()
        end
    )
    if #entries == 0 then
        line(p, L.NO_STORED_EQUIPMENT, 12, 133, 760, 20)
        U.Text(
            p,
            L.WIN_ENCOUNTERS_OR_CRAFT_EQUIPMENT_THEN_RETURN_HERE_TO,
            12,
            174,
            14,
            T.muted,
            740
        )
    end

    line(p, L.SELECTED_STACK_HEADING, 848, 76, 448, 12, T.gold)
    line(
        p,
        selected and selected.name or L.CHOOSE_EQUIPMENT,
        848,
        105,
        448,
        19,
        selected and C.qualityColors[selected.quality] or T.text
    )
    line(
        p,
        selected and ((selected.count or 1) .. L.COPIES_IN_INVENTORY_SUFFIX)
            or L.SELECT_A_STACK_FROM_THE_LIST_TO_PREVIEW_ITS,
        848,
        136,
        448,
        13,
        T.muted
    )
    line(p, L.COPIES_TO_DISENCHANT, 848, 178, 448, 13, T.muted)
    local quantity = ui.disenchantQuantity or 1
    for position, amount in ipairs({ 1, 10, 100 }) do
        local choice = U.SelectButton(
            p,
            tostring(amount),
            848 + (position - 1) * 78,
            204,
            70,
            32,
            function()
                ui.disenchantQuantity = amount
                ui:Refresh()
            end,
            quantity == amount
        )
        choice.text:SetJustifyH("CENTER")
        U.Tooltip(
            choice,
            L.DISENCHANT_QUANTITY,
            L.DESTROY_UP_TO_PREFIX
                .. amount
                .. L.COPIES_OF_THE_SELECTED_STACK_FOR_GOLD_AND_RELIC_SUFFIX,
            320
        )
    end
    local reward = G.DisenchantReward(selected, quantity)
    line(p, L.YOU_RECEIVE, 848, 252, 448, 13, T.muted)
    line(
        p,
        reward and (reward.gold .. L.FRAGMENT_GOLD_2 .. reward.relic .. L.RELIC_DUST_SUFFIX_2)
            or selected and L.THIS_STACK_IS_PROTECTED
            or "—",
        848,
        279,
        448,
        18,
        reward and T.gold or T.muted
    )
    local count = reward and reward.count or quantity
    local destroy = U.Button(
        p,
        L.DISENCHANT_PREFIX .. count .. (count == 1 and L.COPY_SUFFIX or L.COPIES_SUFFIX),
        848,
        318,
        300,
        32,
        function()
            W.Action(G.Disenchant, selected, quantity)
        end,
        false,
        "primary"
    )
    U.Enabled(destroy, reward ~= nil)
    U.Tooltip(
        destroy,
        L.DISENCHANT_SELECTED_EQUIPMENT,
        L.PERMANENTLY_DESTROYS_THE_SELECTED_COPIES_FOR_THE_DISPLAYED_REWARDS,
        320
    )
    local protect = U.Checkbox(
        p,
        L.PROTECTED,
        1160,
        318,
        136,
        selected and selected.protected,
        function(checked)
            if selected and not selected.heirloom then
                selected.protected = checked
                ui:Refresh()
            end
        end
    )
    protect:SetEnabled(selected ~= nil and not selected.heirloom)
    ui.disenchantProtect = protect
    U.Tooltip(
        protect,
        L.PROTECT_EQUIPMENT,
        L.PROTECTED_ITEMS_CANNOT_BE_DISENCHANTED_OR_AUTOMATICALLY_SALVAGED,
        350
    )
    local total = G.DisenchantAllReward(s)
    local all = U.Button(p, L.DISENCHANT_ALL_UNPROTECTED, 848, 376, 448, 32, function()
        W.Action(G.DisenchantAll)
    end)
    U.Enabled(all, total.count > 0)
    U.Tooltip(
        all,
        L.DISENCHANT_ALL_UNPROTECTED_EQUIPMENT,
        L.PERMANENTLY_DESTROYS_PREFIX
            .. total.count
            .. L.FRAGMENT_ITEMS_ACROSS_EVERY_PAGE_FOR
            .. total.gold
            .. L.FRAGMENT_GOLD_AND
            .. total.relic
            .. L.RELIC_DUST_INCLUDES_UPGRADES_EQUIPPED_GEAR_HEIRLOOMS_AND_PROTECTED_SUFFIX,
        360
    )
end

function Party.Draw(ui, p, s)
    if ui.recruiting and #s.heroes < 5 then
        recruit(ui, p, s)
        return
    end
    if ui.disenchantOpen then
        disenchant(ui, p, s)
        return
    end
    local hero, index = s.heroes[ui.selected], ui.selected
    equipment(ui, p, s, hero, index)
    inventory(ui, p, s, hero, index)
end
