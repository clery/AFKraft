local _, W = ...
local L = W.L
local G, U, T = W.Game, W.Widgets, W.Theme
local P = {}
W.BoostRulePanel = P
local conditions = {
    { id = "always", name = L.ALWAYS_IN_COMBAT },
    { id = "boss", name = L.BOSS_ENCOUNTER },
    { id = "lowHealth", name = L.LIVING_ALLY_BELOW_HEALTH },
    { id = "farming", name = L.SAFE_FARMING },
    { id = "pushing", name = L.FRONTIER_PUSHING },
    { id = "tier", name = L.CURRENT_TIER_AT_LEAST },
}

function P.Draw(ui, parent, state, id, x, y)
    local config = state.boosts.automation.abilities[id]
    ui.boostRuleDrafts = ui.boostRuleDrafts or {}
    local draft = ui.boostRuleDrafts[id]
    if not draft or draft.state ~= state or draft.saved ~= config.rules then
        draft = { state = state, saved = config.rules, rules = G.Copy(config.rules or {}) }
        ui.boostRuleDrafts[id] = draft
    end
    local editable = state.boosts.owned[id] and state.boosts.automation.owned.conditional == true
    local controls = { rows = {} }
    ui.boostRuleControls = controls
    U.Text(parent, L.ORDERED_RULES_HEADING, x, y + 5, 14, T.gold, 860)
    controls.add = U.Button(parent, L.ADD_RULE, x + 946, y, 140, 28, function()
        if #draft.rules < 4 then
            draft.rules[#draft.rules + 1] = { condition = "boss", action = "activate" }
            ui:Refresh()
        end
    end)
    U.Enabled(controls.add, editable and #draft.rules < 4)
    controls.save = U.Button(parent, L.SAVE_RULES, x + 1104, y, 140, 28, function()
        W.Action(G.SetBoostRules, id, draft.rules)
    end, false, "primary")
    U.Enabled(controls.save, editable)
    U.Tooltip(
        controls.save,
        L.ORDERED_ACTIVATION_RULES,
        L.SAVE_TO_APPLY_YOUR_EDITS_THE_FIRST_MATCHING_RULE,
        380
    )
    if #draft.rules == 0 then
        U.Text(
            parent,
            editable and L.NO_ORDERED_RULES_THE_SELECTED_PRESET_REMAINS_IN_USE
                or L.LEARN_THIS_BOOST_AND_CONDITIONAL_AUTOMATION_TO_CREATE_UP,
            x,
            y + 42,
            13,
            T.muted,
            1200
        )
    end
    for index, rule in ipairs(draft.rules) do
        local rowY = y + 32 + (index - 1) * 32
        U.Text(parent, tostring(index), x, rowY + 7, 13, T.gold, 28)
        local label
        for _, condition in ipairs(conditions) do
            if condition.id == rule.condition then
                label = condition.name
            end
        end
        local condition = U.Choice(
            parent,
            label or L.CHOOSE_CONDITION,
            x + 34,
            rowY,
            430,
            conditions,
            rule.condition,
            function(value)
                rule.condition = value
                rule.threshold = nil
                if value == "lowHealth" then
                    rule.threshold = 50
                elseif value == "tier" then
                    rule.threshold = 0
                end
                ui:Refresh()
            end
        )
        condition:SetEnabled(editable)
        U.Tooltip(
            condition,
            L.ACTIVATION_CONDITION,
            L.THE_FIRST_MATCHING_RULE_WINS_HEALTH_CHECKS_LIVING_ALLIES,
            360
        )
        local threshold
        if rule.condition == "lowHealth" or rule.condition == "tier" then
            local options = {}
            local low, high, step = 0, 10, 1
            if rule.condition == "lowHealth" then
                low, high, step = 10, 90, 5
            end
            for value = low, high, step do
                options[#options + 1] = {
                    id = value,
                    name = rule.condition == "lowHealth" and (value .. L.HEALTH_2)
                        or (L.TIER_PREFIX .. value),
                }
            end
            -- Preserve exact thresholds entered through commands or saved profiles.
            if rule.condition == "lowHealth" and rule.threshold % 5 ~= 0 then
                options[#options + 1] = { id = rule.threshold, name = rule.threshold .. L.HEALTH_2 }
                table.sort(options, function(a, b)
                    return a.id < b.id
                end)
            end
            threshold = U.Choice(
                parent,
                rule.condition == "lowHealth" and (rule.threshold .. L.HEALTH_2)
                    or (L.TIER_PREFIX .. rule.threshold),
                x + 482,
                rowY,
                300,
                options,
                rule.threshold,
                function(value)
                    rule.threshold = value
                    ui:Refresh()
                end
            )
            threshold:SetEnabled(editable)
        end
        local up = U.Button(parent, L.UP, x + 800, rowY, 66, 28, function()
            if index > 1 then
                draft.rules[index], draft.rules[index - 1] =
                    draft.rules[index - 1], draft.rules[index]
                ui:Refresh()
            end
        end)
        U.Enabled(up, editable and index > 1)
        local down = U.Button(parent, L.DOWN, x + 878, rowY, 82, 28, function()
            if index < #draft.rules then
                draft.rules[index], draft.rules[index + 1] =
                    draft.rules[index + 1], draft.rules[index]
                ui:Refresh()
            end
        end)
        U.Enabled(down, editable and index < #draft.rules)
        local remove = U.Button(parent, L.REMOVE, x + 978, rowY, 118, 28, function()
            table.remove(draft.rules, index)
            ui:Refresh()
        end)
        U.Enabled(remove, editable)
        controls.rows[index] =
            { condition = condition, threshold = threshold, up = up, down = down, remove = remove }
    end
end
