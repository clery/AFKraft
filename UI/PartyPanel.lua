local _, W = ...
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
    return "|cffffffffPrimary stat: "
        .. C.itemStatNames[C.primaryStats[hero.class]]
        .. "|r\n"
        .. "Strength / Agility / Intellect: your class’s primary stat increases attack damage. Other primary stats do not increase attack damage. Intellect also increases healing for every class.\n\n"
        .. "Stamina: increases maximum health.\nSpirit: increases healing.\nHaste: speeds up attacks and special ability cooldowns.\nArmor: reduces incoming damage, with diminishing returns.\nWeapon DPS / Attack Power: increase attack damage.\nSpell Power: increases damage and healing.\nHealing Power: increases healing.\nHealth / 5 sec: restores health during combat.\nResistances: currently informational; do not reduce damage.\n\n"
        .. "Power estimates an item’s value for this class; it is not a combat stat. Talents and prestige can further modify combat stats."
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
        available and "A companion is ready to join" or "Find your next companion",
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
            milestone and ("Defeat a level " .. milestone .. " milestone boss.")
                or "All five companions have joined your company.",
            0,
            54,
            18,
            T.text,
            1000
        )
        U.Button(p, "Back to equipment", 0, 135, 240, 34, function()
            ui.recruiting = false
            ui:Refresh()
        end)
        return
    end
    U.Text(
        p,
        "Choose a class for companion " .. (#s.heroes + 1) .. " of 5.",
        0,
        39,
        14,
        T.muted,
        1030
    )
    local back = U.Button(p, "Back to equipment", 1090, 0, 206, 34, function()
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
            "Recruit a new "
                .. class.name
                .. ". Repeated classes are allowed. A recruit joins the next encounter if your company is fighting."
        )
    end
    U.Help(
        p,
        "Recruitment",
        1030,
        0,
        "Choose a class for the new companion. Names and appearances are generated; repeated classes are allowed.\n\nA recruit joins the next encounter if your party is fighting. Every hero uses the shared inventory. Select a hero to manage their equipment."
    )
end

local function equipment(ui, p, s, hero, index)
    local class, stats = C.classByID[hero.class], G.Stats(s, hero)
    local outfit = W.ModelAssets.starterOutfits[hero.class] or W.ModelAssets.starterOutfits.MAGE
    line(p, hero.name .. "’s equipment", 0, 0, 280, 20, class.color)
    U.Help(p, "Equipment stat guide", 288, 0, statGuide(hero))
    line(
        p,
        "Level " .. hero.level .. " " .. class.name .. "  ·  " .. U.Number(stats.hp) .. " health",
        0,
        33,
        315,
        13,
        T.muted
    )

    local attributeLines = {}
    for _, key in ipairs(C.itemStatOrder) do
        attributeLines[#attributeLines + 1] =
            string.format("%s: %.1f", C.itemStatNames[key], stats.attributes[key] or 0)
    end
    local development = U.Button(p, "Party development", 332, 0, 240, 34, function()
        ui:SetTab("development")
    end)

    U.Tooltip(
        development,
        "Permanent party development · Equipment stats",
        "Heroes earn levels naturally in idle combat without paid gates. Essence invests in permanent Might, Resolve and Provisioning ranks; redistribute ranks freely in Growth.\n\n"
            .. table.concat(attributeLines, "\n")
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
        line(b, name, 48, 2, 220, 12, slot == selectedSlot and T.gold or T.text)
        line(
            b,
            item and item.name or (outfit[slot] and "Basic clothing" or "Empty slot"),
            48,
            rowStep - 22,
            220,
            11,
            item and T.text or T.muted
        )
        U.EndBuild(b)
        U.Tooltip(
            b,
            item and item.name or name,
            item
                    and (qualityText(item) .. " · " .. G.ItemPower(item, hero) .. " power\n" .. G.ItemDescription(
                        item,
                        hero
                    ) .. "\nSelect to view upgrades and matching inventory.")
                or (outfit[slot] and "Basic clothing is cosmetic and adds no stats. " or "")
                    .. "Select this slot to find matching equipment in the shared inventory."
        )
    end

    local item = hero.gear[selectedSlot]
    if item then
        local cost = G.UpgradeCost(item, s)
        line(p, "Upgrade " .. C.slots[selectedSlot], 0, 351, 320, 16, T.gold)
        line(
            p,
            G.ItemPower(item, hero)
                .. " to "
                .. G.ItemPower(item, hero, 1)
                .. " power  ·  "
                .. costText(s, cost),
            0,
            381,
            572,
            12
        )
        local upgrade = U.Button(p, "Upgrade +10% stats", 332, 346, 240, 34, function()
            if W.Action(G.Upgrade, index, selectedSlot) then
                W.Notify(hero.name .. "’s " .. C.slots[selectedSlot] .. " gained 10% base stats.")
            end
        end, false, "primary")
        U.Enabled(upgrade, affordable(s, cost))
        U.Tooltip(
            upgrade,
            "Improve this item",
            "Adds 10% of the base item stats. The power preview uses this hero’s class. Changes take effect immediately."
        )
    else
        line(
            p,
            outfit[selectedSlot] and "Basic clothing · " .. C.slots[selectedSlot]
                or "An empty " .. string.lower(C.slots[selectedSlot]) .. " slot",
            0,
            351,
            320,
            16,
            T.gold
        )
        U.Button(p, "Craft equipment", 332, 346, 240, 34, function()
            ui.craftSlot = selectedSlot
            ui:SetTab("crafting")
        end)
    end
    local identity = W.Client.Identity()
    if hero.generated and hero.class == identity.class then
        local replace = U.Button(
            p,
            "Use " .. identity.name .. " as this companion",
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
    local options, entries = { { id = 0, name = "All equipment" } }, {}
    for _, slot in ipairs(C.equipmentSlots) do
        options[#options + 1] = { id = slot, name = C.slots[slot] }
    end
    local view = ui.bagView or {}
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
        all = "Any availability",
        usable = "Equippable now",
        locked = "Cannot equip",
        upgrades = "Usable upgrades",
    }
    local traitNames = {
        all = "Any trait",
        heirloom = "Heirlooms",
        protected = "Protected",
        effect = "With effect",
        upgraded = "Upgraded",
    }
    describe(view.availability or "all", "all", availabilityNames[view.availability])
    describe(view.quality or 0, 0, C.qualityNames[view.quality])
    describe(view.trait or "all", "all", traitNames[view.trait])
    local function reset()
        ui.bagView, ui.bagFilter, ui.bagPage = nil, 0, 0
        ui:Refresh()
    end
    line(p, "Shared inventory · " .. #s.inventory .. " stacks", 608, 0, 320, 21, T.gold)
    U.Button(p, "Disenchant…", 944, 0, 152, 32, function()
        ui.disenchantOpen, ui.disenchantItem, ui.disenchantPage = true, nil, 0
        ui:Refresh()
    end)
    local equipBest = U.Button(p, "Equip best power", 1112, 0, 184, 32, function()
        W.Action(G.EquipBest, index)
    end, false, "primary")
    U.Rect(p, 608, 38, 688, 36, T.panel, 0.65)
    U.Button(
        p,
        (ui.bagFiltersOpen and "- Filters" or "+ Filters")
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
        { "power", "Power", "High to low", "Low to high" },
        { "level", "Level", "High to low", "Low to high" },
        { "quality", "Quality", "High to low", "Low to high" },
        { "slot", "Equipment slot", "Last to first", "First to last" },
        { "name", "Name", "Z to A", "A to Z" },
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
    line(p, "Sort", 772, 49, 44, 12, T.muted)
    U.Choice(p, sortLabel, 816, 40, 320, sorts, sortValue, function(id)
        view.sort, view.ascending = id:match("^(.-):"), id:match(":asc$") ~= nil
        ui.bagPage = 0
        ui:Refresh()
    end)
    local clear = U.Button(p, "Clear filters", 1152, 40, 144, 32, reset)
    U.Enabled(clear, active > 0)
    ui.guideInventoryTarget = active > 0 and clear or nil
    ui.guideInventoryLabel = "Clear filters"
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
        choice("slot", "Equipment", options, 0, 608)
        choice("availability", "Availability", {
            { id = "all", name = "Any availability" },
            { id = "usable", name = "Equippable now" },
            { id = "locked", name = "Cannot equip" },
            { id = "upgrades", name = "Usable upgrades" },
        }, "all", 784)
        local qualities = { { id = 0, name = "Any quality" } }
        for quality, name in ipairs(C.qualityNames) do
            qualities[#qualities + 1] = { id = quality, name = name }
        end
        choice("quality", "Quality", qualities, 0, 960)
        choice("trait", "Item trait", {
            { id = "all", name = "Any trait" },
            { id = "heirloom", name = "Heirlooms" },
            { id = "protected", name = "Protected" },
            { id = "effect", name = "With effect" },
            { id = "upgraded", name = "Upgraded" },
        }, "all", 1136)
    else
        line(
            p,
            active > 0 and table.concat(summary, "  ·  ") or "All equipment",
            612,
            80,
            680,
            12,
            T.muted
        )
    end
    U.Tooltip(
        equipBest,
        "Equip best power",
        "Equip the highest-power usable item in every slot for "
            .. hero.name
            .. ". Uses the shared inventory, keeps current items on equal power, and returns replaced gear to the inventory."
    )

    local bottom = p:GetHeight() - 34
    local top = ui.bagFiltersOpen and 160 or 104
    local pageSize = math.max(1, math.floor((bottom - top) / 50))
    local pages = math.max(1, math.ceil(#entries / pageSize))
    local page = math.max(0, math.min(ui.bagPage or 0, pages - 1))
    ui.bagPage = page
    for row = 1, pageSize do
        local entry = entries[page * pageSize + row]
        if entry then
            local n, item = entry.index, entry.item
            local y = top + (row - 1) * 50
            local power = G.ItemPower(item, hero)
            local previous = hero.gear[item.slot]
            local delta = power - G.ItemPower(previous, hero)
            local levelOK, restriction = G.CanEquip(hero, item)
            local b = U.SelectButton(p, "", 608, y, 688, 46, function()
                if not levelOK then
                    return
                end
                ui.gearSlot = item.slot
                if W.Action(G.Equip, index, n) then
                    W.Notify("Equipped " .. item.name .. " on " .. hero.name .. ".")
                end
            end)
            if levelOK and item.uid == s.guide.craftItem then
                ui.guideCraftEquipTarget = b
            end
            if levelOK and not ui.guideEquipTarget then
                ui.guideEquipTarget = b
            end
            b.text:Hide()
            U.Begin(b)
            U.Enabled(b, levelOK)
            b:SetMotionScriptsWhileDisabled(true)
            U.Icon(b, item.icon or slotIcons[item.slot], 12, 7, 32):SetParent(b.content or b)
            line(
                b,
                item.name .. ((item.count or 1) > 1 and "  ×" .. item.count or ""),
                58,
                5,
                360,
                13,
                C.qualityColors[item.quality]
            )
            line(
                b,
                C.slots[item.slot]
                    .. "  ·  "
                    .. (item.heirloom and "Heirloom" or "Level " .. item.level)
                    .. "  ·  "
                    .. power
                    .. " power",
                58,
                27,
                360,
                11,
                levelOK and T.muted or { 1, 0.55, 0.51 }
            )
            line(
                b,
                (delta > 0 and "+" or "") .. delta,
                476,
                14,
                90,
                15,
                levelOK and delta > 0 and T.green or T.muted
            ):SetJustifyH("RIGHT")
            line(
                b,
                not levelOK and "Locked" or "Equip",
                584,
                15,
                90,
                12,
                levelOK and T.gold or T.muted
            ):SetJustifyH("CENTER")
            U.EndBuild(b)
            U.Tooltip(
                b,
                item.name,
                qualityText(item)
                    .. " · "
                    .. power
                    .. " power\n"
                    .. G.ItemDescription(item, hero, true)
                    .. "\n\n"
                    .. (
                        not levelOK and ("|cffff6060" .. restriction .. "|r")
                        or "Click to equip on " .. hero.name .. "."
                    ),
                320
            )
        end
    end
    if #entries == 0 then
        line(
            p,
            #s.inventory == 0 and "Your first treasures await" or "No matching equipment",
            632,
            179,
            640,
            21,
            T.text
        )
        U.Text(
            p,
            #s.inventory == 0
                    and "Win encounters or craft a targeted item. Equipment is shared by your company."
                or "Try another filter, or reset the inventory view to show all equipment.",
            632,
            221,
            14,
            T.muted,
            610
        )
        U.Button(
            p,
            #s.inventory == 0 and "Visit the forge" or "Reset filters",
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
    local previous = U.Button(p, "Previous", 608, bottom, 116, 32, function()
        ui.bagPage = page - 1
        ui:Refresh()
    end)
    local nextPage = U.Button(p, "Next", 1180, bottom, 116, 32, function()
        ui.bagPage = page + 1
        ui:Refresh()
    end)
    U.Enabled(previous, page > 0)
    U.Enabled(nextPage, page < pages - 1)
    if not ui.guideInventoryTarget then
        ui.guideInventoryTarget = page < pages - 1 and nextPage or page > 0 and previous or nil
        ui.guideInventoryLabel = page < pages - 1 and "Next" or "Previous"
    end
    previous.text:SetJustifyH("CENTER")
    nextPage.text:SetJustifyH("CENTER")
    line(
        p,
        "Page " .. (page + 1) .. " of " .. pages .. "  ·  Power compared with " .. hero.name,
        742,
        bottom + 5,
        420,
        12,
        T.muted
    ):SetJustifyH("CENTER")
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
    line(p, "Disenchant equipment", 0, 0, 900, 22, T.gold)
    U.Button(p, "Back to equipment", 1096, 0, 200, 32, function()
        ui.disenchantOpen, ui.disenchantItem = false, nil
        ui:Refresh()
    end)
    line(
        p,
        "Turn spare equipment into gold and Relic dust. Equipped gear, heirlooms and protected items are kept.",
        0,
        36,
        1296,
        14,
        T.muted
    )
    line(p, "STORED EQUIPMENT", 0, 76, 792, 12, T.gold)
    for row = 1, 5 do
        local entry = entries[page * 5 + row]
        if entry then
            local item = entry.item
            local b = U.SelectButton(p, "", 0, 102 + (row - 1) * 50, 792, 46, function()
                ui.disenchantItem = item
                ui:Refresh()
            end, item == selected)
            b.text:Hide()
            U.Begin(b)
            U.Icon(b, item.icon or slotIcons[item.slot], 12, 7, 32):SetParent(b.content or b)
            line(
                b,
                item.name .. " ×" .. (item.count or 1),
                62,
                4,
                580,
                14,
                C.qualityColors[item.quality]
            )
            line(
                b,
                C.slots[item.slot]
                    .. " · "
                    .. (item.heirloom and "Heirloom" or "Level " .. item.level)
                    .. " · "
                    .. C.qualityNames[item.quality],
                62,
                23,
                580,
                11,
                T.muted
            )
            line(
                b,
                item.heirloom and "Heirloom"
                    or item.protected and "Protected"
                    or item == selected and "Selected"
                    or "Select",
                656,
                14,
                120,
                12,
                (item.protected or item.heirloom) and T.gold or T.muted
            ):SetJustifyH("RIGHT")
            U.EndBuild(b)
            U.Tooltip(b, item.name, G.ItemDescription(item, s.heroes[ui.selected], true), 360)
        end
    end
    if #entries == 0 then
        line(p, "No stored equipment", 12, 133, 760, 20)
        U.Text(
            p,
            "Win encounters or craft equipment, then return here to disenchant spare items.",
            12,
            174,
            14,
            T.muted,
            740
        )
    end
    local previous = U.Button(p, "Previous", 0, 376, 116, 32, function()
        ui.disenchantPage = page - 1
        ui:Refresh()
    end)
    local nextPage = U.Button(p, "Next", 676, 376, 116, 32, function()
        ui.disenchantPage = page + 1
        ui:Refresh()
    end)
    U.Enabled(previous, page > 0)
    U.Enabled(nextPage, page < pages - 1)
    line(
        p,
        "Page " .. (page + 1) .. " of " .. pages .. " · " .. #entries .. " stacks",
        136,
        383,
        520,
        13,
        T.muted
    ):SetJustifyH("CENTER")

    line(p, "SELECTED STACK", 848, 76, 448, 12, T.gold)
    line(
        p,
        selected and selected.name or "Choose equipment",
        848,
        105,
        448,
        19,
        selected and C.qualityColors[selected.quality] or T.text
    )
    line(
        p,
        selected and ((selected.count or 1) .. " copies in inventory")
            or "Select a stack from the list to preview its rewards.",
        848,
        136,
        448,
        13,
        T.muted
    )
    line(p, "Copies to disenchant", 848, 178, 448, 13, T.muted)
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
            "Disenchant quantity",
            "Consume up to "
                .. amount
                .. " copies of the selected item. Smaller stacks yield only their remaining copies.",
            320
        )
    end
    local reward = G.DisenchantReward(selected, quantity)
    line(p, "You receive", 848, 252, 448, 13, T.muted)
    line(
        p,
        reward and (reward.gold .. " gold + " .. reward.relic .. " Relic dust")
            or selected and "This stack is protected"
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
        "Disenchant " .. count .. (count == 1 and " copy" or " copies"),
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
        "Disenchant selected equipment",
        "Permanently destroys the selected copies for the displayed rewards. This cannot be undone.",
        320
    )
    local protect = U.Checkbox(
        p,
        "Protected",
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
        "Protect equipment",
        "Protected items cannot be disenchanted or automatically salvaged.\n\nHeirlooms are always protected.",
        350
    )
    local total = G.DisenchantAllReward(s)
    local all = U.Button(p, "Disenchant all unprotected", 848, 376, 448, 32, function()
        W.Action(G.DisenchantAll)
    end)
    U.Enabled(all, total.count > 0)
    U.Tooltip(
        all,
        "Disenchant all unprotected equipment",
        "Permanently destroys "
            .. total.count
            .. " items across every page for "
            .. total.gold
            .. " gold and "
            .. total.relic
            .. " Relic dust. Includes upgrades. Equipped gear, heirlooms and protected stacks are kept. The quantity selector does not limit this action.",
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
