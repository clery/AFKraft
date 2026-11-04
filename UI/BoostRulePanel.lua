local _, W = ...
local G, U, T = W.Game, W.Widgets, W.Theme
local P = {}
W.BoostRulePanel = P
local conditions = {
    { id = "always", name = "Always in combat" },
    { id = "boss", name = "Boss encounter" },
    { id = "lowHealth", name = "Living ally below health" },
    { id = "farming", name = "Safe farming" },
    { id = "pushing", name = "Frontier pushing" },
    { id = "tier", name = "Current tier at least" },
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
    U.Text(parent, "ORDERED RULES", x, y + 5, 14, T.gold, 860)
    controls.add = U.Button(parent, "Add rule", x + 946, y, 140, 28, function()
        if #draft.rules < 4 then
            draft.rules[#draft.rules + 1] = { condition = "boss", action = "activate" }
            ui:Refresh()
        end
    end)
    U.Enabled(controls.add, editable and #draft.rules < 4)
    controls.save = U.Button(parent, "Save rules", x + 1104, y, 140, 28, function()
        W.Action(G.SetBoostRules, id, draft.rules)
    end, false, "primary")
    U.Enabled(controls.save, editable)
    U.Tooltip(
        controls.save,
        "Ordered activation rules",
        "Preview edits, then save. Rules run top to bottom; the first match requests the ordinary activation command. Readiness, capacity, Auto-cast and the global Automation switch still apply. Empty rules use the existing preset.",
        380
    )
    if #draft.rules == 0 then
        U.Text(
            parent,
            editable and "No ordered rules. The selected preset remains in use."
                or "Learn this boost and conditional automation to create up to four rules.",
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
            label or "Choose condition",
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
            "Activation condition",
            "Rules are alternatives, evaluated in saved order. Low health checks living allies only and requires health strictly below the threshold. Tier uses the current run's difficulty.",
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
                    name = rule.condition == "lowHealth" and (value .. "% health")
                        or ("Tier " .. value),
                }
            end
            -- Preserve exact thresholds entered through commands or saved profiles.
            if rule.condition == "lowHealth" and rule.threshold % 5 ~= 0 then
                options[#options + 1] = { id = rule.threshold, name = rule.threshold .. "% health" }
                table.sort(options, function(a, b)
                    return a.id < b.id
                end)
            end
            threshold = U.Choice(
                parent,
                rule.condition == "lowHealth" and (rule.threshold .. "% health")
                    or ("Tier " .. rule.threshold),
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
        local up = U.Button(parent, "Up", x + 800, rowY, 66, 28, function()
            if index > 1 then
                draft.rules[index], draft.rules[index - 1] =
                    draft.rules[index - 1], draft.rules[index]
                ui:Refresh()
            end
        end)
        U.Enabled(up, editable and index > 1)
        local down = U.Button(parent, "Down", x + 878, rowY, 82, 28, function()
            if index < #draft.rules then
                draft.rules[index], draft.rules[index + 1] =
                    draft.rules[index + 1], draft.rules[index]
                ui:Refresh()
            end
        end)
        U.Enabled(down, editable and index < #draft.rules)
        local remove = U.Button(parent, "Remove", x + 978, rowY, 118, 28, function()
            table.remove(draft.rules, index)
            ui:Refresh()
        end)
        U.Enabled(remove, editable)
        controls.rows[index] =
            { condition = condition, threshold = threshold, up = up, down = down, remove = remove }
    end
end
