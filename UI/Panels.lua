local _, W = ...
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local P = {}
W.Panels = P

local function text(p, value, x, y, size, color, width)
    return U.Text(p, value, x, y, size or 14, color or T.text, width)
end

local function button(p, label, x, y, w, fn, active, variant)
    return U.Button(p, label, x, y, w, 32, fn, active, variant)
end

local function selected(ui, s)
    return s.heroes[ui.selected or 1], ui.selected or 1
end

function P.adventure(ui, p, s)
    text(p, "THE NEXT CHAPTER", 0, 0, 12, T.gold)
    text(
        p,
        s.farming and "Regroup. Refine. Return stronger." or "Every adventure leaves a mark.",
        0,
        27,
        23,
        T.text,
        640
    )
    text(
        p,
        s.lastDefeat
            or "Choose where to adventure, shape your party, and let their legend grow while you play.",
        0,
        67,
        14,
        T.muted,
        610
    )
    local z = C.zoneByID[s.zone]
    text(p, "CURRENT HAUL", 710, 0, 12, T.gold)
    text(
        p,
        C.materials[z.material] .. "  ·  Equipment  ·  Idle experience",
        710,
        29,
        16,
        T.text,
        580
    )
    text(
        p,
        "WoW activities fill your Adventure XP bar. Each rank awards Essence for training and upgrades.\nYour party earns idle rewards while you are away, up to 24 hours.",
        710,
        65,
        14,
        T.muted,
        580
    )
    button(
        p,
        #s.heroes < 5 and "Recruit companions" or "Choose destination",
        0,
        128,
        190,
        function()
            if #s.heroes < 5 then
                ui.recruiting = true
                ui:SetTab("party")
            else
                ui:SetTab("atlas")
            end
        end
    )
    button(p, "Shape your build", 206, 128, 185, function()
        ui:SetTab("talents")
    end)
    text(p, "ADVENTURE JOURNAL", 0, 187, 11, T.gold)
    U.SingleLine(text(p, s.log[#s.log] or "", 0, 210, 13, T.muted, 1290), 1290, 24)
end

function P.party(ui, p, s)
    W.PartyPanel.Draw(ui, p, s)
end

function P.talents(ui, p, s)
    local h, index = selected(ui, s)
    text(p, h.name .. "  /  " .. G.Points(h) .. " unspent talent points", 0, 0, 21, T.gold)
    text(p, "Change talents at any time. Earn a point every two idle levels.", 0, 35, 13, T.muted)
    W.TalentPanel.Draw(ui, p, h, index)
    text(p, "COMBAT PRIORITIES", 0, 372, 12, T.gold)
    local priorities, thresholds = {}, {}
    for _, id in ipairs(C.priorityModes) do
        priorities[#priorities + 1] = { id = id, name = C.priorityNames[id] }
    end
    for n = 35, 85, 10 do
        thresholds[#thresholds + 1] = { id = n, name = "Recover below " .. n .. "%" }
    end
    local priority = U.Choice(
        p,
        C.priorityNames[h.priority],
        208,
        362,
        280,
        priorities,
        h.priority,
        function(id)
            W.Action(G.Configure, index, "priority", id)
        end
    )
    local threshold = U.Choice(
        p,
        "Recover below " .. h.healBelow .. "%",
        508,
        362,
        300,
        thresholds,
        h.healBelow,
        function(n)
            W.Action(G.Configure, index, "healBelow", n)
        end
    )
    local special = U.Choice(
        p,
        "Special at " .. h.specialCount .. "+ enemies",
        828,
        362,
        300,
        {
            { id = 1, name = "Special at 1+ enemies" },
            { id = 2, name = "Special at 2+ enemies" },
            { id = 3, name = "Special at 3+ enemies" },
        },
        h.specialCount,
        function(n)
            W.Action(G.Configure, index, "specialCount", n)
        end
    )
    for _, dropdown in ipairs({ priority, threshold, special }) do
        dropdown:SetEnabled(true)
    end
    text(
        p,
        "Priorities guide this companion automatically. Recovery uses their healing or defensive ability.",
        208,
        406,
        12,
        T.muted,
        1088
    )
end

function P.crafting(ui, p, s)
    local h, index = selected(ui, s)
    local slot = ui.craftSlot or 1
    local material = ui.craftMaterial or "timber"
    local heirloom = ui.craftHeirloom or false
    local cost = G.Cost(s, h, heirloom)
    text(p, "Craft for " .. h.name, 0, 0, 23, T.gold)
    text(p, "Choose an equipment slot", 0, 39, 13, T.muted)
    for i, name in ipairs(C.slots) do
        local id = i
        U.Button(p, name, (i - 1) % 2 * 220, 79 + math.floor((i - 1) / 2) * 72, 205, 56, function()
            ui.craftSlot = id
            ui:Refresh()
        end, slot == i)
    end
    text(p, "MATERIAL", 480, 0, 11, T.gold)
    for i, id in ipairs(C.materialOrder) do
        button(
            p,
            C.materials[id] .. " · " .. s.materials[id],
            480,
            48 + (i - 1) * 64,
            310,
            function()
                ui.craftMaterial = id
                ui:Refresh()
            end,
            material == id
        )
    end
    text(
        p,
        heirloom and "Legacy " .. C.slots[slot] or "Runeworn " .. C.slots[slot],
        850,
        0,
        23,
        T.text,
        450
    )
    text(
        p,
        (
            heirloom and "Scales with your hero. Survives prestige."
            or "Rare · Idle level " .. h.level .. " · Power " .. (2 + h.level * 2 + 6)
        ) .. "\nRenewal: +6% ability healing",
        850,
        58,
        14,
        T.muted,
        450
    )
    text(
        p,
        cost.essence
            .. " Essence  /  "
            .. cost.gold
            .. " gold\n"
            .. cost.material
            .. " "
            .. C.materials[material],
        850,
        141,
        16,
        T.gold
    )
    local craft = button(p, "Craft for " .. h.name, 850, 233, 446, function()
        W.Action(G.Craft, index, slot, material, heirloom)
    end, false, "primary")
    U.Enabled(
        craft,
        s.essence >= cost.essence
            and s.gold >= cost.gold
            and s.materials[material] >= cost.material
            and (not heirloom or s.recipes[slot])
    )
    U.Tooltip(
        craft,
        "Craft targeted equipment",
        "The full cost is shown above. Earn Essence by playing WoW and materials by adventuring in the matching zone. Heirloom recipes must first be unlocked in Legacy."
    )
    text(
        p,
        heirloom and not s.recipes[slot] and "Unlock this recipe in Legacy first."
            or "Created in your shared inventory.",
        850,
        285,
        13,
        T.muted,
        446
    )
    button(p, heirloom and "Heirloom recipe" or "Ordinary recipe", 0, 309, 425, function()
        ui.craftHeirloom = not heirloom
        ui:Refresh()
    end, heirloom)
    text(
        p,
        "Crafted items go to the shared inventory. Equip them in Party.",
        480,
        392,
        12,
        T.muted,
        830
    )
end

function P.atlas(ui)
    W.Atlas.Draw(ui)
end

function P.legacy(ui, p, s)
    text(p, "WHAT WILL YOUR PARTY LEAVE BEHIND?", 0, 0, 19, T.gold)
    text(
        p,
        "Legacy " .. s.legacy .. "  /  " .. s.prestiges .. " rewarded chapters",
        0,
        37,
        17,
        T.text
    )
    text(
        p,
        "Keep identities, discoveries, heirlooms, recipes, and unspent Essence.\nReset levels, ordinary gear, gold, materials, and world progress.",
        0,
        77,
        14,
        T.muted,
        650
    )
    local reward = G.PrestigeReward(s)
    button(
        p,
        ui.confirmPrestige and "Confirm reset · +" .. reward .. " Legacy"
            or "Begin a new chapter · +" .. reward .. " Legacy",
        0,
        151,
        600,
        function()
            if not s.prestigeUnlocked then
                W.Notify("Defeat a level 8 milestone boss to unlock prestige.")
                return
            end
            if not ui.confirmPrestige then
                ui.confirmPrestige = true
                ui:Refresh()
                return
            end
            W.Action(G.Prestige)
            ui.confirmPrestige = false
            ui:Refresh()
        end
    )
    if ui.confirmPrestige then
        button(p, "Keep adventuring", 0, 198, 210, function()
            ui.confirmPrestige = false
            ui:Refresh()
        end)
    end
    text(p, "HEIRLOOM RECIPES  /  1 LEGACY EACH", 710, 0, 12, T.gold)
    for i, name in ipairs(C.slots) do
        local slot = i
        button(
            p,
            (s.recipes[i] and "Known · " or "Unlock · ") .. name,
            710 + (i - 1) % 2 * 302,
            38 + math.floor((i - 1) / 2) * 48,
            285,
            function()
                W.Action(G.UnlockRecipe, slot)
            end,
            s.recipes[i]
        )
    end
    text(
        p,
        "Unlock a recipe here, then craft your heirloom with zone materials and Essence.",
        710,
        204,
        13,
        T.muted,
        600
    )
end

function P.loot(ui, p, s)
    text(p, "KEEP THE TREASURES. SALVAGE THE REST.", 0, 0, 19, T.gold)
    text(
        p,
        "Automatically salvage items below the chosen quality, except protected items and enabled keep rules.",
        0,
        33,
        14,
        T.muted,
        1290
    )
    button(p, "Keep " .. C.qualityNames[s.salvage.minQuality] .. "+", 0, 79, 310, function()
        s.salvage.minQuality = s.salvage.minQuality % 4 + 1
        ui:Refresh()
    end)
    button(
        p,
        (s.salvage.keepUpgrades and "[x] " or "") .. "Keep potential upgrades",
        340,
        79,
        310,
        function()
            s.salvage.keepUpgrades = not s.salvage.keepUpgrades
            ui:Refresh()
        end
    )
    button(
        p,
        (s.salvage.keepEffects and "[x] " or "") .. "Keep undiscovered effects",
        680,
        79,
        310,
        function()
            s.salvage.keepEffects = not s.salvage.keepEffects
            ui:Refresh()
        end
    )
    text(
        p,
        "Salvaged "
            .. s.stats.salvaged
            .. " items. Heirlooms are always protected. Rules apply to future drops.",
        0,
        132,
        14,
        T.muted
    )
    local entries = G.InventoryEntries(s, s.heroes[ui.selected])
    local start = (ui.lootPage or 0) * 3 + 1
    for row = 1, 3 do
        local index = start + row - 1
        local item = entries[index] and entries[index].item
        if item then
            button(
                p,
                (item.protected and "Protected · " or "Protect · ") .. item.name,
                (row - 1) * 440,
                178,
                415,
                function()
                    item.protected = not item.protected
                    ui:Refresh()
                end,
                item.protected
            )
        end
    end
    button(p, "Next items", 0, 227, 180, function()
        ui.lootPage = start + 3 <= #s.inventory and (ui.lootPage or 0) + 1 or 0
        ui:Refresh()
    end)
end

function P.Draw(ui)
    local s = W.state
    local p = ui.panel
    if ui.atlas then
        ui.atlas.frame:SetShown(s.ui.tab == "atlas")
    end
    if ui.talentTrees then
        ui.talentTrees:SetShown(s.ui.tab == "talents" and not W.catchup)
    end
    U.Begin(p)
    if W.catchup then
        text(p, "YOUR PARTY IS RETURNING", 0, 0, 22, T.gold)
        text(p, "Resolving your offline adventure…", 0, 43, 16, T.muted)
    else
        local tab = s.ui.tab or "adventure"
        (P[tab] or P.adventure)(ui, p, s)
    end
    U.EndBuild(p)
end
