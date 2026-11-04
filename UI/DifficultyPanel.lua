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
    U.Text(parent, L.DIFFICULTY_HEADING, 0, 0, 22, T.gold, 1296)
    U.Help(parent, L.TRANSCENDENCE, 1258, 0, L.DIFFICULTY_PANEL_DESCRIPTION)
    U.Text(
        parent,
        L.CURRENT_TIER_PREFIX
            .. state.tier
            .. " · "
            .. difficulty.ascensions
            .. L.FRAGMENT_ASCENSIONS
            .. difficulty.currency
            .. L.INHERITANCE_SUFFIX,
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
            tier == 0 and L.BASE or L.TIER_PREFIX .. tier,
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
            L.TIER_PREFIX .. tier,
            #recipes > 0
                    and (L.ONLINE_IDLE_BOSSES_AT_ENCOUNTER_LEVEL_20_CAN_TEACH_PREFIX .. table.concat(
                        recipes,
                        ", "
                    ) .. L.ELIGIBLE_BOSSES_AWARD_ONE_RUNIC_FRAGMENT_RECIPES_STAY_LEARNED)
                or L.RUNIC_BOSS_REWARDS_BEGIN_AT_TIER_2_BASE_ENCHANTMENTS
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
            L.REVIEW_TRANSCENDENCE_TIER_HEADING
                .. selected
                .. " · +"
                .. preview.inheritance
                .. L.INHERITANCE_SUFFIX,
            20,
            236,
            20,
            T.gold,
            1240
        )
        U.Text(
            parent,
            L.TIER_AFFIXES_PREFIX .. (#names > 0 and table.concat(names, ", ") or L.NONE),
            20,
            266,
            12,
            T.muted,
            1240
        )
        U.Text(parent, L.KEEP_HEADING, 20, 282, 16, T.green, 610)
        U.Text(parent, table.concat(preview.retained, "\n"), 20, 320, 15, T.text, 610)
        U.Text(parent, L.RESET_HEADING, 670, 282, 16, T.gold, 590)
        U.Text(parent, table.concat(preview.rebuilt, "\n"), 670, 320, 15, T.text, 590)
        ui.difficultyExecute = button(
            parent,
            L.BEGIN_TRANSCENDENCE_PREFIX .. selected,
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
        ui.difficultyCancel = button(parent, L.KEEP_THIS_ADVENTURE, 20, 576, 380, function()
            ui.difficultyConfirm = false
            ui:Refresh()
        end)
        return
    end
    ui.difficultyExecute, ui.difficultyCancel = nil, nil
    local modifiers = G.DifficultyModifiers({ tier = selected, difficulty = difficulty })
    U.Text(
        parent,
        L.SELECTED_PREFIX
            .. (selected == 0 and L.BASE_ADVENTURE or L.TRANSCENDENCE_PREFIX .. selected),
        0,
        236,
        20,
        T.gold,
        1296
    )
    U.Text(
        parent,
        string.format(
            L.ENEMIES_HEALTH_DAMAGE_HERO_XP_MASTERY,
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
        string.format(L.GOLD_MATERIALS_LOOT, modifiers.gold, modifiers.loot),
        0,
        306,
        15,
        T.muted,
        1296
    )
    U.Help(
        parent,
        L.GUARDED_FORMATIONS,
        1258,
        330,
        string.format(
            L.ENEMIES_TAKE_LESS_BASIC_ATTACK_DAMAGE_SPELLS_RETAIN_FULL,
            (1 - modifiers.basicDamageTaken) * 100
        )
    )
    ui.difficultyAffixes = {}
    if #affixes == 0 then
        U.Text(parent, L.NO_TIER_AFFIXES, 0, 380, 14, T.muted, 1296)
    end
    for index, affix in ipairs(affixes) do
        local card = U.Card(parent, (index - 1) * 430, 370, 410, 34)
        U.Begin(card)
        U.Icon(card, affix.icon, 4, 1, 32):SetParent(card.content or card)
        U.Text(card, affix.name, 46, 8, 14, T.gold, 350)
        U.EndBuild(card)
        U.Tooltip(card, affix.name .. L.FRAGMENT_TIER .. affix.tier .. "+", affix.description)
        ui.difficultyAffixes[affix.id] = card
    end
    U.Text(parent, L.PERMANENT_BONUSES_HEADING, 0, 430, 16, T.gold, 1296)
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
            rank == purchase.max and L.COMPLETE
                or L.IMPROVE_PREFIX .. rank + 1 .. L.INHERITANCE_SUFFIX,
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
        L.REVIEW_RESET .. preview.inheritance .. L.INHERITANCE_SUFFIX,
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
