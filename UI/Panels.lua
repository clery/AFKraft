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

-- Opportunities are derived from the current run, never persisted as notifications.
function P.Opportunities(s)
    local points, talentHero, cappedHero, routes = 0, nil, nil, 0
    for i, hero in ipairs(s.heroes) do
        local unspent = G.Points(hero)
        points = points + unspent
        if unspent > 0 and not talentHero then
            talentHero = i
        end
        if
            hero.level >= G.LevelCap(hero)
            and G.LevelCap(hero) < C.heroLevelCap
            and not cappedHero
        then
            cappedHero = i
        end
    end
    for _, zone in ipairs(C.zones) do
        if zone.level > C.zoneByID[s.zone].level and G.IsUnlocked(s, zone) then
            routes = routes + 1
        end
    end
    return points, talentHero, cappedHero, routes
end

-- Return only lessons that can be acted on now; unavailable lessons never block others.
function P.GuideStep(s, selectedHero)
    local craftHero = s.guide.craftHero
    local recipient = craftHero and s.heroes[craftHero]
    if recipient then
        for index, item in ipairs(s.inventory) do
            if
                item.uid == s.guide.craftItem
                and G.CanEquip(recipient, item)
                and G.ItemPower(item, recipient)
                    > G.ItemPower(recipient.gear[item.slot], recipient)
            then
                return 6, craftHero, nil, { item = item, inventoryIndex = index }
            end
        end
    end
    if not s.guide.equipped then
        for index, hero in ipairs(s.heroes) do
            for _, item in ipairs(s.inventory) do
                if G.CanEquip(hero, item) then
                    return 2, index
                end
            end
        end
    end
    if not s.guide.talent then
        for index, hero in ipairs(s.heroes) do
            if G.Points(hero) > 0 then
                for _, talent in ipairs(G.TalentList(hero)) do
                    if not hero.talents[talent.id] and G.CanTalent(hero, talent) then
                        return 3, index
                    end
                end
            end
        end
    end
    if not s.guide.traveled then
        for _, zone in ipairs(C.zones) do
            if zone.level > C.zoneByID[s.zone].level and G.IsUnlocked(s, zone) then
                return 4, nil, zone
            end
        end
    end
    if not s.guide.crafted then
        local index = selectedHero or 1
        local craft = G.CraftingOpportunity(s, index)
        if craft then
            return 5, index, nil, craft
        end
    end
end

function P.adventure(ui, p, s)
    local title, detail, label, tab
    if #s.heroes < G.CompanionSlots(s) then
        title, detail, label, tab =
            "You found a companion!",
            "A new companion is ready to join. Choose their class in Party; they join the next encounter.",
            "Recruit companions",
            "party"
    else
        title, detail, label, tab =
            "Your company is advancing",
            "Idle battles earn hero experience, gold, equipment and local materials. WoW activities earn Adventure XP and Essence.",
            "Manage party",
            "party"
    end
    text(p, "YOUR ADVENTURE", 0, 0, 12, T.gold)
    text(p, title, 0, 27, 23, T.text, 640)
    if s.farming then
        detail = (s.lastDefeat or "Your party is farming a safe encounter.")
            .. " Improve your heroes, then use Retry."
    end
    text(p, detail, 0, 65, 14, T.muted, 630)
    button(p, label, 0, 128, 240, function()
        ui.recruiting = label == "Recruit companions"
        ui:SetTab(tab)
    end, false, "primary")
    do
        text(p, "YOUR LEGACY", 710, 0, 12, T.gold)
        local reward = G.PrestigeReward(s)
        text(
            p,
            s.prestigeUnlocked and "A new chapter is available" or "Build a lasting inheritance",
            710,
            27,
            21,
            T.gold,
            580
        )
        text(
            p,
            s.prestigeUnlocked
                    and ("Reset this run for " .. reward .. " Legacy. Review what carries forward before deciding.")
                or "Defeat a level 8 milestone boss to unlock new chapters and earn Legacy for heirloom recipes.",
            710,
            65,
            14,
            T.muted,
            580
        )
        button(
            p,
            s.prestigeUnlocked and "Review Legacy · +" .. reward or "Explore Legacy",
            710,
            128,
            300,
            function()
                ui:SetTab("legacy")
            end
        )
        if s.guide.dismissed and P.GuideStep(s, ui.selected) then
            button(p, "Show starter guide", 1030, 128, 266, function()
                s.guide.dismissed = false
                ui:Refresh()
            end)
        end
    end
    text(p, "ADVENTURE JOURNAL", 0, 187, 11, T.gold)
    U.SingleLine(text(p, s.log[#s.log] or "", 0, 210, 13, T.muted, 1290), 1290, 24)
end

function P.party(ui, p, s)
    W.PartyPanel.Draw(ui, p, s)
end

function P.talents(ui, p, s)
    local h, index = selected(ui, s)
    U.SingleLine(
        text(p, h.name .. "  /  " .. G.Points(h) .. " unspent talent points", 0, 0, 21, T.gold),
        720,
        28
    )
    local progress = G.TalentProgress(h)
    local nextLevel = G.NextTalentLevel(h)
    local mastery = G.MasteryProgress(h)
    local hint = nextLevel and ("Next level point: " .. nextLevel .. ". ") or ""
    if progress.earned >= #G.TalentList(h) then
        hint = "All permanent talent points earned."
    elseif G.MasteryUnlocked(h) then
        hint = hint .. "Mastery XP: encounter level " .. math.max(1, mastery.frontier) .. "+."
    else
        hint = hint .. "Mastery unlocks at hero level " .. C.mastery.unlockLevel .. "."
    end
    text(p, "Permanent talents. Free respecs. " .. hint, 0, 35, 13, T.muted)
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
    local preview, unavailable = G.CraftItem(h, slot, heirloom)
    ui.craftControls = { slots = {}, materials = {} }
    text(p, "Craft for " .. h.name, 0, 0, 23, T.gold)
    text(p, "Choose an equipment slot", 0, 39, 13, T.muted)
    for position, i in ipairs(C.equipmentSlots) do
        local name, id = C.slots[i], i
        ui.craftControls.slots[i] = U.Button(
            p,
            name,
            (position - 1) % 2 * 220,
            79 + math.floor((position - 1) / 2) * 44,
            205,
            38,
            function()
                ui.craftSlot = id
                ui:Refresh()
            end,
            slot == i
        )
    end
    text(p, "MATERIAL", 480, 0, 11, T.gold)
    for i, id in ipairs(C.materialOrder) do
        ui.craftControls.materials[id] = button(
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
    text(p, preview and preview.name or "Recipe unavailable", 850, 0, 23, T.text, 450)
    local description = unavailable
    if preview then
        local quality = heirloom and "Heirloom" or C.qualityNames[preview.quality]
        local requirement = heirloom and "Scales with your hero. Survives chapter resets."
            or "Idle level " .. preview.level
        description = quality .. " · " .. G.ItemPower(preview, h) .. " power\n" .. requirement
    end
    text(p, description, 850, 58, 14, T.muted, 450)
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
    ui.craftControls.craft = craft
    U.Enabled(
        craft,
        preview ~= nil
            and s.essence >= cost.essence
            and s.gold >= cost.gold
            and s.materials[material] >= cost.material
            and (not heirloom or s.recipes[slot])
    )
    U.Tooltip(
        craft,
        "Craft targeted equipment",
        (preview and G.ItemDescription(preview, h) .. "\n\n" or "")
            .. "The full cost is shown above. Earn Essence by playing WoW and materials by adventuring in the matching zone. Heirloom recipes must first be unlocked in Legacy."
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
    ui.craftControls.ordinary = button(p, "Ordinary", 0, 309, 205, function()
        ui.craftHeirloom = false
        ui:Refresh()
    end, not heirloom)
    ui.craftControls.heirloom = button(p, "Heirloom", 220, 309, 205, function()
        ui.craftHeirloom = true
        ui:Refresh()
    end, heirloom)
    if heirloom and not s.recipes[slot] then
        button(p, "View recipe in Legacy", 850, 325, 446, function()
            ui.legacySlot = slot
            ui:SetTab("legacy")
        end)
    end
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
    local reward = G.PrestigeReward(s)
    local currentBonus = s.prestiges * 4
    local nextBonus = currentBonus + (reward > 0 and 4 or 0)
    text(
        p,
        ui.confirmPrestige and "REVIEW YOUR NEW CHAPTER" or "A LASTING INHERITANCE",
        0,
        0,
        24,
        T.gold
    )
    text(
        p,
        s.legacy .. " Legacy available  ·  " .. s.prestiges .. " rewarded chapters",
        0,
        44,
        16,
        T.text,
        1296
    )
    text(
        p,
        "Permanent party bonus: +" .. currentBonus .. "% health, damage and healing.",
        0,
        77,
        16,
        T.green,
        1296
    )
    if ui.confirmPrestige then
        text(p, "GAIN", 0, 138, 14, T.gold)
        text(
            p,
            "+"
                .. reward
                .. " Legacy  ·  Balance after reset: "
                .. (s.legacy + reward)
                .. "\nPermanent party bonus: +"
                .. currentBonus
                .. "% to +"
                .. nextBonus
                .. "%",
            0,
            171,
            20,
            T.green,
            1296
        )
        text(p, "KEEP", 0, 254, 14, T.gold)
        text(
            p,
            "Hero identities and classes; talents, permanent talent points and Mastery; heirlooms; recipes and discoveries; Legacy; Adventure rank and partial XP; unspent Essence.",
            0,
            287,
            17,
            T.text,
            1220
        )
        text(p, "RESET", 0, 365, 14, T.gold)
        text(
            p,
            "Hero levels and training; ordinary equipped and stored gear; gold and zone materials; destination and encounter progress.",
            0,
            398,
            17,
            T.text,
            1220
        )
        text(
            p,
            "Spent Essence is not refunded. This reset cannot be undone.",
            0,
            470,
            16,
            T.gold,
            1220
        )
        button(p, "Keep adventuring", 0, 540, 260, function()
            ui.confirmPrestige = false
            ui:Refresh()
        end)
        -- Keep the final action away from the review button's position.
        local confirm = button(p, "Reset adventure and begin chapter", 760, 540, 536, function()
            if not ui.confirmPrestige or not s.prestigeUnlocked then
                return
            end
            ui.confirmPrestige = false
            if W.Action(G.Prestige) then
                ui:SetTab("adventure")
            else
                ui:Refresh()
            end
        end, false, "primary")
        U.Enabled(confirm, s.prestigeUnlocked == true)
        return
    end
    text(p, "NEW CHAPTER", 0, 142, 14, T.gold)
    text(p, "Start fresh. Carry your legacy forward.", 0, 177, 22, T.text, 630)
    text(
        p,
        "New chapters reset your run. Rewarded chapters add 4 percentage points to your permanent party bonus, and award Legacy for heirloom recipes.",
        0,
        220,
        16,
        T.text,
        620
    )
    text(
        p,
        s.prestigeUnlocked
                and ("Available now: +" .. reward .. " Legacy  ·  Party bonus +" .. currentBonus .. "% to +" .. nextBonus .. "%")
            or "Unlock: defeat a level 8 milestone boss.",
        0,
        310,
        16,
        T.gold,
        620
    )
    if s.prestigeUnlocked and reward == 0 then
        text(
            p,
            "No Legacy or bonus increase this run. Defeat harder milestone bosses to earn a reward.",
            0,
            358,
            15,
            T.muted,
            620
        )
    end
    local review = button(p, "Review new chapter…", 0, 420, 360, function()
        if s.prestigeUnlocked then
            ui.confirmPrestige = true
            ui:Refresh()
        end
    end, false, "primary")
    U.Enabled(review, s.prestigeUnlocked == true)
    text(
        p,
        "Review the full gains, kept progress and reset details before confirming.",
        0,
        478,
        14,
        T.muted,
        620
    )
    text(p, "HEIRLOOMS THAT GROW WITH YOU", 710, 142, 14, T.gold)
    text(p, "Earn Legacy / Unlock recipes / Craft lasting equipment", 710, 180, 16, T.text, 580)
    text(
        p,
        "Heirlooms scale with hero level and survive chapter resets. Each recipe costs 1 Legacy; crafting also costs Essence, gold and materials.",
        710,
        223,
        15,
        T.muted,
        580
    )
    for position, i in ipairs(C.equipmentSlots) do
        local name, slot = C.slots[i], i
        local known = s.recipes[i]
        local recipe = button(
            p,
            (known and "Craft · " or "Unlock · ") .. name .. (known and "" or " · 1 Legacy"),
            710 + (position - 1) % 2 * 302,
            292 + math.floor((position - 1) / 2) * 40,
            285,
            function()
                if s.recipes[slot] or W.Action(G.UnlockRecipe, slot) then
                    ui.craftSlot, ui.craftHeirloom = slot, true
                    ui:SetTab("crafting")
                end
            end,
            known or ui.legacySlot == slot
        )
        U.Tooltip(
            recipe,
            name .. " heirloom recipe",
            known and "Open Crafting to make this heirloom for the selected hero."
                or "Spend 1 Legacy to permanently unlock this recipe, then open Crafting."
        )
    end
    text(
        p,
        "Unlocking a recipe spends Legacy immediately. It does not reset your adventure.",
        710,
        510,
        14,
        T.muted,
        580
    )
end

function P.loot(ui, p, s)
    text(p, "KEEP THE TREASURES. SALVAGE THE REST.", 0, 0, 19, T.gold)
    text(
        p,
        "Automatically salvage future drops below the chosen quality. Manage stored equipment in Party.",
        0,
        33,
        14,
        T.muted,
        1290
    )
    local qualities = {}
    for quality = 1, 4 do
        qualities[#qualities + 1] =
            { id = quality, name = "Keep " .. C.qualityNames[quality] .. "+" }
    end
    U.Choice(
        p,
        "Keep " .. C.qualityNames[s.salvage.minQuality] .. "+",
        0,
        79,
        310,
        qualities,
        s.salvage.minQuality,
        function(quality)
            s.salvage.minQuality = quality
            ui:Refresh()
        end
    )
    U.Checkbox(p, "Keep potential upgrades", 340, 79, 310, s.salvage.keepUpgrades, function(checked)
        s.salvage.keepUpgrades = checked
        ui:Refresh()
    end)
    U.Checkbox(
        p,
        "Keep undiscovered effects",
        680,
        79,
        350,
        s.salvage.keepEffects,
        function(checked)
            s.salvage.keepEffects = checked
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
    ui.guideEquipTarget, ui.guideInventoryTarget, ui.guideCraftEquipTarget = nil, nil, nil
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
