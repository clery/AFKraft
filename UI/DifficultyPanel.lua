local _, W = ...
local L = W.L
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local D = {}
W.DifficultyPanel = D

local function button(parent, label, x, y, width, action)
    return U.Button(parent, label, x, y, width, 34, action)
end

function D.Draw(ui, parent, state)
    local difficulty = state.difficulty
    if ui.difficultyTier == nil or ui.difficultyTier > difficulty.maxTier then
        ui.difficultyTier = state.tier
    end
    U.Text(parent, L["DIFFICULTY"], 0, 0, 22, T.gold, 1296)
    U.Help(
        parent,
        L["Transcendence"],
        1258,
        0,
        L["Choose a tier, then review reset rewards and losses. Each completed tier pays Inheritance once.\n\nDifficulty changes idle battles and rewards, not real WoW Adventure XP or Essence."]
    )
    U.Text(
        parent,
        L["Current tier "]
            .. state.tier
            .. " · "
            .. difficulty.ascensions
            .. L[" ascensions · "]
            .. difficulty.currency
            .. L[" Inheritance"],
        0,
        80,
        16,
        T.gold,
        1296
    )
    ui.difficultyTiers = {}
    for tier = 0, difficulty.maxTier do
        local value = tier
        local x = tier * 108
        ui.difficultyTiers[tier] = U.SelectButton(
            parent,
            tier == 0 and L["Base"] or L["Tier "] .. tier,
            x,
            130,
            98,
            34,
            function()
                ui.difficultyTier, ui.difficultyConfirm = value, false
                ui:Refresh()
            end,
            tier == ui.difficultyTier
        )
        local recipes = {}
        for _, enchant in ipairs(C.enchants) do
            if enchant.tier and tier >= enchant.tier then
                recipes[#recipes + 1] = enchant.name
            end
        end
        U.Tooltip(
            ui.difficultyTiers[tier],
            L["Tier "] .. tier,
            #recipes > 0
                    and (L["Online idle bosses at encounter level 20+ can teach: "] .. table.concat(
                        recipes,
                        ", "
                    ) .. L[". Eligible bosses award one Runic fragment; recipes stay learned through both resets."])
                or L["Runic boss rewards begin at tier 2. Base enchantments need no fragments."]
        )
        U.Icon(parent, "Ability_Warrior_InnerRage", x + 32, 178, 32)
    end
    local selected = ui.difficultyTier
    local preview = G.PrestigePlusPreview(state, selected)
    local affixes, names = G.DifficultyAffixes(selected), {}
    for _, affix in ipairs(affixes) do
        names[#names + 1] = affix.name
    end
    if ui.difficultyConfirm then
        ui.difficultyReview, ui.inheritancePurchases = nil, {}
        U.Text(
            parent,
            L["REVIEW TRANSCENDENCE · TIER "]
                .. selected
                .. " · +"
                .. preview.inheritance
                .. L[" Inheritance"],
            20,
            236,
            20,
            T.gold,
            1240
        )
        U.Text(
            parent,
            L["Tier affixes: "] .. (#names > 0 and table.concat(names, ", ") or L["None"]),
            20,
            266,
            12,
            T.muted,
            1240
        )
        U.Text(parent, L["KEEP"], 20, 282, 16, T.green, 610)
        U.Text(parent, table.concat(preview.retained, "\n"), 20, 320, 15, T.text, 610)
        U.Text(parent, L["RESET"], 670, 282, 16, T.gold, 590)
        U.Text(parent, table.concat(preview.rebuilt, "\n"), 670, 320, 15, T.text, 590)
        ui.difficultyExecute = button(
            parent,
            L["Begin Transcendence "] .. selected,
            670,
            576,
            380,
            function()
                local ok = W.Action(G.PrestigePlus, selected)
                if ok then
                    ui.difficultyConfirm = false
                end
                ui:Refresh()
            end
        )
        U.Enabled(ui.difficultyExecute, preview.eligible)
        ui.difficultyCancel = button(parent, L["Keep this adventure"], 20, 576, 380, function()
            ui.difficultyConfirm = false
            ui:Refresh()
        end)
        return
    end
    ui.difficultyExecute, ui.difficultyCancel = nil, nil
    local modifiers = G.DifficultyModifiers({ tier = selected, difficulty = difficulty })
    U.Text(
        parent,
        L["Selected: "]
            .. (selected == 0 and L["Base adventure"] or L["Transcendence "] .. selected),
        0,
        236,
        20,
        T.gold,
        1296
    )
    U.Text(
        parent,
        string.format(
            L["Enemies: %.2f× health / %.2f× damage · Hero XP %.2f× · Mastery %.2f×"],
            modifiers.enemyHealth,
            modifiers.enemyDamage,
            modifiers.heroXP,
            modifiers.masteryXP
        ),
        0,
        276,
        15,
        T.text,
        1296
    )
    U.Text(
        parent,
        string.format(L["Gold / materials %.2f× · Loot %.2f×"], modifiers.gold, modifiers.loot),
        0,
        306,
        15,
        T.muted,
        1296
    )
    U.Help(
        parent,
        L["Guarded formations"],
        1258,
        330,
        string.format(
            L["Enemies take %.1f%% less basic-attack damage.\n\nSpells retain full damage."],
            (1 - modifiers.basicDamageTaken) * 100
        )
    )
    ui.difficultyAffixes = {}
    if #affixes == 0 then
        U.Text(parent, L["No tier affixes"], 0, 380, 14, T.muted, 1296)
    end
    for index, affix in ipairs(affixes) do
        local card = U.Card(parent, (index - 1) * 430, 370, 410, 34)
        U.Begin(card)
        U.Icon(card, affix.icon, 4, 1, 32):SetParent(card.content or card)
        U.Text(card, affix.name, 46, 8, 14, T.gold, 350)
        U.EndBuild(card)
        U.Tooltip(card, affix.name .. L[" | Tier "] .. affix.tier .. "+", affix.description)
        ui.difficultyAffixes[affix.id] = card
    end
    U.Text(parent, L["PERMANENT BONUSES"], 0, 430, 16, T.gold, 1296)
    ui.inheritancePurchases = {}
    for index, id in ipairs({ "rebuilding", "supplies" }) do
        local purchase = G.InheritancePurchases[id]
        local rank, x = difficulty.purchases[id] or 0, (index - 1) * 650
        U.Text(
            parent,
            purchase.name .. " · " .. rank .. "/" .. purchase.max,
            x,
            472,
            17,
            T.text,
            610
        )
        U.Text(parent, purchase.description, x, 508, 14, T.muted, 610)
        ui.inheritancePurchases[id] = button(
            parent,
            rank == purchase.max and L["Complete"]
                or L["Improve · "] .. rank + 1 .. L[" Inheritance"],
            x,
            546,
            360,
            function()
                W.Action(G.BuyInheritance, id)
            end
        )
        U.Enabled(
            ui.inheritancePurchases[id],
            difficulty.unlocked and rank < purchase.max and difficulty.currency >= rank + 1
        )
    end
    ui.difficultyReview = button(
        parent,
        L["Review reset · +"] .. preview.inheritance .. L[" Inheritance"],
        0,
        610,
        430,
        function()
            ui.difficultyConfirm = true
            ui:Refresh()
        end
    )
    U.Enabled(ui.difficultyReview, preview.eligible)
    U.Text(parent, preview.reason, 0, 658, 15, T.muted, 1296)
end
