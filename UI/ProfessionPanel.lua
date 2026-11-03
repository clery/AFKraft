local _, W = ...
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.ProfessionPanel = P

local function button(parent, label, x, y, width, fn, active)
    return U.Button(parent, label, x, y, width, 34, fn, active)
end

local function text(parent, value, x, y, width, color, size)
    return U.Text(parent, value, x, y, size or 15, color or T.text, width)
end

local function affordable(state, cost)
    if not cost or state.gold < cost.gold or state.essence < cost.essence then
        return false
    end
    for material, count in pairs(cost.materials) do
        if state.materials[material] < count then
            return false
        end
    end
    return true
end

local function costText(cost)
    local parts = { cost.gold .. " gold", cost.essence .. " Essence" }
    for _, material in ipairs(C.materialOrder) do
        local count = cost.materials[material] or 0
        if count > 0 then
            parts[#parts + 1] = count .. " " .. C.materials[material]
        end
    end
    return table.concat(parts, " · ")
end

local function research(ui, frame, state)
    local kind = ui.professionResearch or "crafting"
    local profession = C.professionByID[kind]
    local options = {}
    for _, spec in ipairs(C.professions) do
        options[#options + 1] = { id = spec.id, name = spec.name }
    end
    ui.professionControls.profession = U.Choice(
        frame,
        profession.name,
        0,
        66,
        330,
        options,
        kind,
        function(value)
            ui.professionResearch = value
            ui:Refresh()
        end
    )
    local p = state.professions
    local available, total = G.ProfessionPoints(state, kind)
    text(frame, available .. " / " .. total .. " profession points", 360, 74, 500, T.gold, 19)
    text(
        frame,
        "Work rank "
            .. p.ranks[kind]
            .. "/30 · "
            .. p.xp[kind]
            .. "/"
            .. (20 + p.ranks[kind] * 10)
            .. " work XP",
        880,
        74,
        390,
        T.muted
    )
    local unlocked = G.ProfessionUnlocks(state).research
    if not unlocked then
        text(
            frame,
            "Reach lifetime idle level 50 to specialize. Paid work already earns profession ranks.",
            0,
            116,
            1260,
            T.gold
        )
    end
    local active = G.ProfessionActiveAllocations(state, kind)
    local desired = 0
    for _, rank in pairs(p.allocations[kind]) do
        desired = desired + rank
    end
    ui.professionControls.branches = {}
    for index, branch in ipairs(profession.branches) do
        local x, chosen = (index - 1) * 428, p.allocations[kind][branch.id] or 0
        U.Icon(frame, profession.icon, x, 166, 38)
        text(frame, branch.name, x + 50, 172, 354, T.gold, 20)
        text(frame, branch.description, x, 224, 400, T.muted)
        ui.professionControls.branches[branch.id] = {}
        for rank = 1, 3 do
            local requirement = 1 + (rank - 1) * 3
            local label = rank <= (active[branch.id] or 0) and "Active"
                or rank <= chosen and "Saved plan"
                or "Learn · 1 point"
            local control = button(
                frame,
                "Rank " .. rank .. " · " .. label,
                x,
                292 + (rank - 1) * 80,
                400,
                function()
                    W.Action(G.AllocateProfession, kind, branch.id)
                end,
                rank <= (active[branch.id] or 0)
            )
            text(
                frame,
                "Requires work rank " .. requirement,
                x + 12,
                332 + (rank - 1) * 80,
                380,
                T.muted,
                12
            )
            U.Enabled(
                control,
                unlocked
                    and rank == chosen + 1
                    and available > 0
                    and desired < p.ranks[kind]
                    and p.ranks[kind] >= requirement
            )
            ui.professionControls.branches[branch.id][rank] = control
        end
    end
    ui.professionControls.respec = button(frame, "Reset allocation", 0, 580, 240, function()
        W.Action(G.ResetProfessionAllocations, kind)
    end)
    U.Tooltip(
        ui.professionControls.respec,
        "Reallocate profession points",
        "Free allocation reset. Profession ranks and combat talents are unchanged. Saved allocations survive deeper resets; inactive ranks return as paid work earns points again."
    )
end

function P.Draw(ui, parent, state)
    if not ui.professionFrame then
        ui.professionFrame = CreateFrame("Frame", nil, parent)
        ui.professionFrame:SetAllPoints(parent)
    end
    local frame = ui.professionFrame
    frame:Show()
    U.Begin(frame)
    G.ProfessionUnlocks(state)
    local tab = ui.professionTab or "enchanting"
    ui.professionControls = { tabs = {} }
    for index, entry in ipairs({
        { "enchanting", "Enchant" },
        { "titanforging", "Titanforge" },
        { "research", "Specializations" },
    }) do
        ui.professionControls.tabs[entry[1]] = button(
            frame,
            entry[2],
            (index - 1) * 220,
            0,
            200,
            function()
                ui.professionTab = entry[1]
                ui:Refresh()
            end,
            tab == entry[1]
        )
    end
    if tab == "research" then
        research(ui, frame, state)
        U.EndBuild(frame)
        return
    end
    local heroIndex, slot = ui.professionHero or 1, ui.professionSlot or 1
    if not state.heroes[heroIndex] then
        heroIndex = 1
    end
    local hero = state.heroes[heroIndex] or state.heroes[1]
    if not hero then
        text(frame, "Recruit a companion to work on their equipment.", 0, 74, 1200)
        U.EndBuild(frame)
        return
    end
    local heroes, slots = {}, {}
    for index, companion in ipairs(state.heroes) do
        heroes[#heroes + 1] = { id = index, name = companion.name }
    end
    for _, id in ipairs(C.equipmentSlots) do
        slots[#slots + 1] = { id = id, name = C.slots[id] }
    end
    ui.professionControls.hero = U.Choice(
        frame,
        hero.name,
        0,
        66,
        410,
        heroes,
        heroIndex,
        function(value)
            ui.professionHero = value
            ui:Refresh()
        end
    )
    ui.professionControls.slot = U.Choice(
        frame,
        C.slots[slot],
        440,
        66,
        400,
        slots,
        slot,
        function(value)
            ui.professionSlot = value
            ui:Refresh()
        end
    )
    local p = state.professions
    text(frame, "Work rank " .. p.ranks[tab] .. "/30", 890, 76, 380, T.gold, 18)
    local enchantID = ui.professionEnchant or "offense"
    ui.professionControls.enchants = {}
    if tab == "enchanting" then
        for index, enchant in ipairs(C.enchants) do
            local control = U.Button(frame, "", (index - 1) * 428, 128, 406, 76, function()
                ui.professionEnchant = enchant.id
                ui:Refresh()
            end, enchantID == enchant.id)
            U.Begin(control)
            U.Icon(control, enchant.icon, 12, 12, 48):SetParent(control.content or control)
            text(control, enchant.name, 76, 14, 300, T.gold, 19)
            text(control, enchant.id, 76, 44, 300, T.muted, 12)
            U.EndBuild(control)
            ui.professionControls.enchants[enchant.id] = control
        end
    else
        U.Icon(frame, C.professionByID.titanforging.icon, 0, 132, 56)
        text(
            frame,
            "Raise this item's potential · Five permanent item tiers",
            80,
            146,
            1100,
            T.gold,
            21
        )
    end
    local item = hero.gear[slot]
    local preview, cost, reason
    if tab == "enchanting" then
        preview, cost, reason = G.EnchantQuote(state, heroIndex, slot, enchantID)
    else
        preview, cost, reason = G.ForgeQuote(state, heroIndex, slot)
    end
    text(frame, item and item.name or "Empty equipment slot", 0, 252, 1200, T.gold, 23)
    if item then
        U.Icon(frame, item.icon or "INV_Misc_Book_09", 0, 298, 64)
        text(frame, "Current power " .. G.ItemPower(item, hero), 90, 306, 500, T.muted, 18)
        if preview then
            text(
                frame,
                "New power " .. G.ItemPower(preview, hero),
                660,
                306,
                530,
                G.ItemPower(preview, hero) >= G.ItemPower(item, hero) and T.green or { 1, 0.4, 0.4 },
                21
            )
        end
    end
    if preview then
        if tab == "enchanting" then
            local lines = {}
            for _, key in ipairs(C.itemStatOrder) do
                local value = preview.enchant.stats[key]
                if value then
                    lines[#lines + 1] = "+" .. value .. " " .. C.itemStatNames[key]
                end
            end
            text(frame, table.concat(lines, " · "), 0, 392, 1250, T.green, 19)
            local previous = item.enchant and C.enchantByID[item.enchant.id]
            text(
                frame,
                previous and ("Replaces " .. previous.name .. ". The old enchantment is lost.")
                    or "Adds one targeted enchantment. Basic enhancement and forging are unchanged.",
                0,
                430,
                1250,
                T.muted
            )
        else
            text(
                frame,
                "Titanforge "
                    .. (item.forge or 0)
                    .. " to "
                    .. preview.forge
                    .. " · Item potential +"
                    .. string.format("%.1f", (G.ForgeMultiplier(preview) - 1) * 100)
                    .. "%",
                0,
                392,
                1250,
                T.green,
                20
            )
            text(
                frame,
                item.heirloom and "Heirloom forging survives ordinary and deeper resets."
                    or "This ordinary item is lost on reset. Heirloom investments are retained.",
                0,
                430,
                1250,
                T.muted
            )
        end
        text(frame, costText(cost), 0, 488, 1250, T.gold, 17)
    else
        text(frame, reason or "Choose an equipped item.", 0, 392, 1250, T.gold, 18)
    end
    ui.professionControls.commit = button(
        frame,
        tab == "enchanting" and "Apply enchantment" or "Titanforge item",
        0,
        548,
        340,
        function()
            if tab == "enchanting" then
                W.Action(G.Enchant, heroIndex, slot, enchantID)
            else
                W.Action(G.Titanforge, heroIndex, slot)
            end
        end
    )
    U.Enabled(ui.professionControls.commit, preview ~= nil and affordable(state, cost))
    U.EndBuild(frame)
end
