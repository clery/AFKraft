local _, W = ...
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local Party = {}
W.PartyPanel = Party
local slotIcons = {
    "INV_Sword_04",
    "INV_Chest_Chain_05",
    "INV_Helmet_03",
    "INV_Jewelry_Ring_01",
    "INV_Jewelry_Talisman_07",
    "INV_Jewelry_Talisman_08",
}

local function line(parent, value, x, y, width, size, color)
    return U.SingleLine(
        U.Text(parent, value, x, y, size or 13, color or T.text),
        width,
        (size or 13) + 8
    )
end

local function costText(state, cost)
    local function amount(value, available, label)
        return (available >= value and "|cffdfbc79" or "|cffff8e82")
            .. value
            .. " "
            .. label
            .. "|r"
    end
    return amount(cost.essence, state.essence, "Essence")
        .. "  ·  "
        .. amount(cost.gold, state.gold, "gold")
end

local function affordable(state, cost)
    return state.essence >= cost.essence and state.gold >= cost.gold
end

local function recruit(ui, p, s)
    line(p, "Gather your company", 0, 0, 950, 23, T.gold)
    U.Text(
        p,
        "Choose a class for companion "
            .. (#s.heroes + 1)
            .. " of 5. Names and appearances are generated.",
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
        local b = U.Button(p, "", x, y, 416, 76, function()
            if W.Action(G.AddHero, id) then
                ui.selected = #s.heroes
                ui.recruiting = #s.heroes < 5
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
    U.Text(
        p,
        "Your company shares an inventory. Select a hero above to manage their equipment at any time.",
        0,
        392,
        13,
        T.muted,
        1296
    )
end

local function equipment(ui, p, s, hero, index)
    local class, stats = C.classByID[hero.class], G.Stats(s, hero)
    line(p, hero.name, 0, 0, 310, 23, class.color)
    line(
        p,
        "Level " .. hero.level .. " " .. class.name .. "  ·  " .. U.Number(stats.hp) .. " health",
        0,
        33,
        315,
        13,
        T.muted
    )
    line(
        p,
        hero.level >= G.LevelCap(hero) and "Level cap reached · train to keep growing"
            or "Select a slot to compare and upgrade",
        0,
        59,
        572,
        12,
        hero.level >= G.LevelCap(hero) and T.gold or T.muted
    )
    local training = G.TrainingCost(hero)
    local train = U.Button(p, "Raise cap to " .. (G.LevelCap(hero) + 4), 332, 0, 240, 34, function()
        if W.Action(G.Train, index) then
            W.Notify(hero.name .. " can now reach level " .. G.LevelCap(hero) .. ".")
        end
    end, false, "primary")
    U.Enabled(train, affordable(s, training))
    line(p, costText(s, training), 332, 37, 240, 11)
    U.Tooltip(
        train,
        "Raise the level cap",
        "Current cap: "
            .. G.LevelCap(hero)
            .. ". Training raises the cap by four. Heroes gain experience in idle battles; Adventure XP ranks award the Essence for training."
    )

    local selectedSlot = ui.gearSlot or 1
    for slot, name in ipairs(C.slots) do
        local id, item = slot, hero.gear[slot]
        local x, y = (slot - 1) % 2 * 292, 94 + math.floor((slot - 1) / 2) * 80
        local b = U.Button(p, "", x, y, 280, 68, function()
            ui.gearSlot, ui.bagFilter, ui.bagPage = id, id, 0
            ui:Refresh()
        end, slot == selectedSlot)
        b.text:Hide()
        U.Begin(b)
        U.Icon(b, slotIcons[slot], 12, 15, 36)
        line(b, name, 62, 9, 204, 14, slot == selectedSlot and T.gold or T.text)
        line(
            b,
            item
                    and (G.ItemPower(item, hero) .. " power" .. ((item.upgrade or 0) > 0 and "  ·  +" .. item.upgrade or ""))
                or "Empty slot",
            62,
            36,
            204,
            12,
            item and T.text or T.muted
        )
        U.EndBuild(b)
        U.Tooltip(
            b,
            item and item.name or name,
            item
                    and (C.qualityNames[item.quality] .. " · " .. G.ItemPower(item, hero) .. " power\nSelect to view upgrades and matching inventory.")
                or "Select this slot to find matching equipment in the shared inventory."
        )
    end

    local item = hero.gear[selectedSlot]
    if item then
        local cost = G.UpgradeCost(item)
        line(p, "Upgrade " .. C.slots[selectedSlot], 0, 351, 320, 16, T.gold)
        line(
            p,
            G.ItemPower(item, hero)
                .. " to "
                .. (G.ItemPower(item, hero) + 2)
                .. " power  ·  "
                .. costText(s, cost),
            0,
            381,
            572,
            12
        )
        local upgrade = U.Button(p, "Upgrade +2 power", 332, 346, 240, 34, function()
            if W.Action(G.Upgrade, index, selectedSlot) then
                W.Notify(hero.name .. "’s " .. C.slots[selectedSlot] .. " gained 2 power.")
            end
        end, false, "primary")
        U.Enabled(upgrade, affordable(s, cost))
        U.Tooltip(
            upgrade,
            "Improve this item",
            "Gain 2 power. The cost is shown before purchase. Changes take effect immediately."
        )
    else
        line(
            p,
            "An empty " .. string.lower(C.slots[selectedSlot]) .. " slot",
            0,
            351,
            320,
            16,
            T.gold
        )
        line(p, "Equip a matching item or craft one for this hero.", 0, 381, 572, 12, T.muted)
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
    local filter = ui.bagFilter or 0
    local options, entries = { { id = 0, name = "All equipment" } }, {}
    for slot, name in ipairs(C.slots) do
        options[#options + 1] = { id = slot, name = name }
    end
    entries = G.InventoryEntries(s, hero, filter)
    line(p, "Shared inventory", 608, 0, 420, 21, T.gold)
    line(p, #entries .. " stacks", 1116, 7, 180, 12, T.muted):SetJustifyH("RIGHT")
    U.Choice(
        p,
        filter == 0 and "All equipment" or C.slots[filter],
        608,
        40,
        240,
        options,
        filter,
        function(id)
            ui.bagFilter, ui.bagPage = id, 0
            ui:Refresh()
        end
    )
    local equipBest = U.Button(p, "Equip best power", 1056, 40, 240, 34, function()
        W.Action(G.EquipBest, index)
    end, false, "primary")
    U.Tooltip(
        equipBest,
        "Equip best power",
        "Equip the highest-power usable item in every slot for "
            .. hero.name
            .. ". Uses the shared inventory, keeps current items on equal power, and returns replaced gear to the inventory."
    )

    local pages = math.max(1, math.ceil(#entries / 5))
    local page = math.max(0, math.min(ui.bagPage or 0, pages - 1))
    ui.bagPage = page
    for row = 1, 5 do
        local entry = entries[page * 5 + row]
        if entry then
            local n, item = entry.index, entry.item
            local y = 88 + (row - 1) * 56
            local power = G.ItemPower(item, hero)
            local previous = hero.gear[item.slot]
            local delta = power - G.ItemPower(previous, hero)
            local levelOK = item.heirloom or item.level <= hero.level
            local b = U.Button(p, "", 608, y, 688, 50, function()
                ui.gearSlot = item.slot
                if W.Action(G.Equip, index, n) then
                    W.Notify("Equipped " .. item.name .. " on " .. hero.name .. ".")
                end
            end)
            b.text:Hide()
            U.Begin(b)
            U.Enabled(b, levelOK)
            U.Icon(b, slotIcons[item.slot], 12, 9, 32)
            line(
                b,
                item.name .. ((item.count or 1) > 1 and "  ×" .. item.count or ""),
                58,
                5,
                406,
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
                406,
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
                delta > 0 and T.green or T.muted
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
                C.qualityNames[item.quality]
                    .. " · "
                    .. power
                    .. " power\nCurrently equipped: "
                    .. (previous and previous.name or "Empty")
                    .. " ("
                    .. G.ItemPower(previous, hero)
                    .. " power).\n"
                    .. (
                        not levelOK and "Requires idle level " .. item.level .. "."
                        or "Click to equip. Your previous item returns to inventory."
                    )
            )
        end
    end
    if #entries == 0 then
        line(
            p,
            #s.inventory == 0 and "Your first treasures await" or "No matching equipment",
            632,
            157,
            640,
            21,
            T.text
        )
        U.Text(
            p,
            "Win encounters or craft a targeted item. Equipment is shared by your company.",
            632,
            201,
            14,
            T.muted,
            610
        )
        U.Button(p, "Visit the forge", 632, 258, 216, 34, function()
            ui:SetTab("crafting")
        end)
    end
    local previous = U.Button(p, "Previous", 608, 389, 116, 32, function()
        ui.bagPage = page - 1
        ui:Refresh()
    end)
    local nextPage = U.Button(p, "Next", 1180, 389, 116, 32, function()
        ui.bagPage = page + 1
        ui:Refresh()
    end)
    U.Enabled(previous, page > 0)
    U.Enabled(nextPage, page < pages - 1)
    previous.text:SetJustifyH("CENTER")
    nextPage.text:SetJustifyH("CENTER")
    line(
        p,
        "Page " .. (page + 1) .. " of " .. pages .. "  ·  Power compared with " .. hero.name,
        742,
        394,
        420,
        12,
        T.muted
    ):SetJustifyH("CENTER")
end

function Party.Draw(ui, p, s)
    if ui.recruiting and #s.heroes < 5 then
        recruit(ui, p, s)
        return
    end
    local hero, index = s.heroes[ui.selected], ui.selected
    U.Rect(p, 592, 0, 1, 421, T.line)
    equipment(ui, p, s, hero, index)
    inventory(ui, p, s, hero, index)
end
