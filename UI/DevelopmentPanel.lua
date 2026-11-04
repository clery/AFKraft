local _, W = ...
local L = W.L
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.DevelopmentPanel = P

local rows = {
    might = { { L.DAMAGE, "damage" }, { L.HEALING, "healing" } },
    resolve = {
        { L.HEALTH_3, "health" },
        { L.DAMAGE_TAKEN, "damageTaken" },
        { L.VICTORY_RECOVERY, "recovery" },
    },
    provisioning = {
        { L.ZONE_MATERIALS, "materials" },
        { L.EQUIPMENT_COSTS, "costMultiplier" },
        { L.HERO_XP, "heroXP" },
    },
}

local function bonus(value, key)
    local amount = (key == "recovery" and value or value - 1) * 100
    if math.abs(amount) < 0.00001 then
        amount = 0
    end
    return string.format("%+.1f%%", amount)
end

function P.Draw(ui, parent, state)
    local board = state.development
    U.Text(parent, L.INVESTED_PREFIX .. board.invested .. L.ESSENCE_SUFFIX, 0, 4, 20, T.gold, 850)
    ui.developmentControls = { branches = {} }
    local reset = U.Button(parent, L.REDISTRIBUTE_ALL_FREE, 940, 0, 330, 34, function()
        W.Action(G.ResetDevelopment)
    end)
    ui.developmentControls.reset = reset
    U.Enabled(reset, board.invested > 0)
    U.Tooltip(
        reset,
        L.REFUND_EVERY_DEVELOPMENT_RANK,
        L.RECOVER_EXACTLY_PREFIX
            .. board.invested
            .. L.INVESTED_ESSENCE_MILESTONE_CHOICES_STAY_SAVED_AND_REACTIVATE_AT_SUFFIX,
        380
    )
    for index, branch in ipairs(C.development) do
        local x = (index - 1) * 428
        local quote = G.DevelopmentQuote(state, branch.id)
        U.Rect(parent, x, 64, 410, 578, T.panel, 0.7)
        U.Icon(parent, branch.icon, x + 16, 84, 52)
        U.Text(parent, branch.name, x + 84, 86, 24, T.gold, 306)
        U.Text(
            parent,
            L.RANK_PREFIX .. quote.rank .. "/" .. C.developmentRankCap,
            x + 84,
            122,
            15,
            T.muted,
            300
        )
        U.Text(parent, L.CURRENT, x + 192, 180, 13, T.muted, 90)
        U.Text(parent, L.NEXT_RANK, x + 294, 180, 13, T.gold, 100)
        for rowIndex, row in ipairs(rows[branch.id]) do
            local y = 220 + (rowIndex - 1) * 36
            U.Text(parent, row[1], x + 16, y, 14, T.text, 174)
            U.Text(parent, bonus(quote.current[row[2]], row[2]), x + 192, y, 15, T.text, 96)
            U.Text(
                parent,
                quote.maximum and L.COMPLETE or bonus(quote.next[row[2]], row[2]),
                x + 294,
                y,
                15,
                T.gold,
                100
            )
        end
        local buy = U.Button(
            parent,
            quote.maximum and L.RANK_CAP_REACHED
                or (L.INVEST_PREFIX .. quote.cost .. L.ESSENCE_SUFFIX),
            x + 16,
            350,
            378,
            36,
            function()
                W.Action(G.BuyDevelopment, branch.id)
            end,
            false,
            "primary"
        )
        U.Enabled(buy, not quote.maximum and state.essence >= quote.cost)
        U.Tooltip(
            buy,
            branch.name .. L.DEVELOPMENT_SUFFIX,
            branch.description
                .. L.PERMANENT_THROUGH_BOTH_RESETS_REFUND_RANKS_FREELY_FOR_THEIR_SUFFIX,
            350
        )
        local refund = U.Button(
            parent,
            L.REFUND_RANK_PREFIX .. quote.refund .. L.ESSENCE_SUFFIX,
            x + 16,
            402,
            378,
            34,
            function()
                W.Action(G.RefundDevelopment, branch.id)
            end
        )
        U.Enabled(refund, quote.rank > 0)
        U.Text(parent, L.RANK_3_MILESTONE, x + 16, 474, 17, T.gold, 378)
        local controls = { buy = buy, refund = refund, choices = {} }
        for choiceIndex, choice in ipairs(branch.choices) do
            local chosen = quote.choice == choice.id
            local control = U.SelectButton(
                parent,
                "",
                x + 16 + (choiceIndex - 1) * 194,
                514,
                184,
                58,
                function()
                    W.Action(G.SetDevelopmentChoice, branch.id, choice.id)
                end,
                chosen
            )
            U.Begin(control)
            local icon = U.Icon(control, choice.icon, 10, 10, 36)
            icon:SetParent(control.content or control)
            icon:SetDesaturated(quote.rank < 3)
            icon:SetAlpha(quote.rank >= 3 and 1 or 0.5)
            U.SingleLine(
                U.Text(
                    control,
                    choice.name,
                    56,
                    10,
                    13,
                    quote.rank < 3 and T.muted or chosen and T.gold or T.text,
                    118
                ),
                118,
                20
            )
            U.Text(
                control,
                quote.rank < 3 and (chosen and L.SAVED_INACTIVE or L.RANK_3_REQUIRED)
                    or chosen and L.SELECTED
                    or L.CHOOSE_FREE,
                56,
                33,
                11,
                T.muted,
                118
            )
            U.EndBuild(control)
            U.Enabled(control, quote.rank >= 3)
            U.Tooltip(
                control,
                choice.name,
                choice.description .. L.SWITCH_FOR_FREE_YOUR_CHOICE_STAYS_SAVED_BELOW_RANK_SUFFIX,
                350
            )
            controls.choices[choice.id] = control
        end

        ui.developmentControls.branches[branch.id] = controls
    end
    local migration = state.economyMigration
    if migration then
        U.Help(
            parent,
            L.PREVIOUS_INVESTMENTS,
            1258,
            660,
            L.RECORDED_PURCHASES_FROM_THE_OLD_ECONOMY_WERE_REFUNDED_ONCE_PREFIX
                .. (migration.trainingEssence + migration.equipmentEssence)
                .. L.FRAGMENT_GOLD_3
                .. migration.trainingGold
                .. L.UNRECORDED_SPENDING_WAS_NOT_ESTIMATED_SUFFIX
        )
    end
end
