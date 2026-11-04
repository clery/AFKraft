local _, W = ...
local L = W.L
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.ProfilePanel = P

local function button(parent, label, x, y, width, action, active)
    return U.Button(parent, label, x, y, width, 34, action, active)
end

local function routeName(state, route)
    if not route or not route.selected then
        return L["No route selected"]
    end
    for _, template in ipairs(state.routes and state.routes.templates or {}) do
        if template.id == route.selected then
            return template.name
        end
    end
    return L["Unavailable route"]
end

function P.Draw(ui, parent, state)
    if ui.profileState ~= state then
        ui.profileState, ui.selectedProfile, ui.profileNameSelection = state, nil, nil
    end
    if not ui.profileFrame then
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetAllPoints(parent)
        ui.profileFrame = frame
        local edit = U.Input(frame, 478, 34, 714, 36)
        ui.profileName = edit
    end
    local frame, profiles = ui.profileFrame, state.boostProfiles
    frame:Show()
    U.Begin(frame)
    local entries = {}
    for _, entry in pairs(profiles.entries) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(a, b)
        return a.id < b.id
    end)
    local profile = profiles.entries[ui.selectedProfile]
    if not profile then
        ui.selectedProfile = nil
    end
    if ui.profileNameSelection ~= (ui.selectedProfile or false) then
        ui.profileName:SetText(profile and profile.name or "")
        ui.profileNameSelection = ui.selectedProfile or false
    end
    U.Text(frame, L["Saved profiles · "] .. #entries .. "/8", 0, 0, 20, T.gold, 420)
    ui.profileControls = { rows = {} }
    for index, entry in ipairs(entries) do
        local row = U.SelectButton(frame, "", 0, 48 + (index - 1) * 66, 416, 56, function()
            ui.selectedProfile = entry.id
            ui:Refresh()
        end, ui.selectedProfile == entry.id)
        U.Begin(row)
        local boost = entry.equipped and C.boostByID[entry.equipped]
        U.Icon(row, boost and boost.icon or "INV_Misc_Book_09", 10, 8, 40)
            :SetParent(row.content or row)
        U.SingleLine(U.Text(row, entry.name, 64, 8, 15, T.gold, 334), 334, 22)
        U.SingleLine(
            U.Text(row, boost and boost.name or L["No equipped boost"], 64, 31, 12, T.muted, 334),
            334,
            18
        )
        U.EndBuild(row)
        ui.profileControls.rows[entry.id] = row
    end
    ui.profileControls.new = button(frame, L["New profile"], 0, 594, 200, function()
        ui.selectedProfile, ui.profileNameSelection = nil, nil
        ui:Refresh()
    end)
    U.Text(
        frame,
        profile and L["Profile name"] or L["Name your current setup"],
        470,
        0,
        17,
        T.gold,
        720
    )
    local snapshot = profile
        or {
            equipped = state.boosts.equipped,
            automation = state.boosts.automation,
            collection = { effect = state.outdoorCollections.effect },
            route = state.routes and {
                selected = state.routes.selected,
                enabled = state.routes.enabled,
                offlineEnabled = state.routes.offlineEnabled,
            },
        }
    local equipped = snapshot.equipped and C.boostByID[snapshot.equipped]
    U.Text(
        frame,
        equipped and equipped.name
            or snapshot.equipped and L["Unavailable boost"]
            or L["No boost equipped"],
        470,
        102,
        21,
        T.gold,
        730
    )
    U.Text(
        frame,
        snapshot.automation.enabled and L["Automation enabled"] or L["Automation paused"],
        470,
        140,
        14,
        T.muted,
        720
    )
    local index = 0
    for _, boost in ipairs(C.boosts) do
        local config = snapshot.automation.abilities[boost.id]
        if config and (config.enabled or snapshot.equipped == boost.id) then
            local x, y = 470 + (index % 5) * 156, 184 + math.floor(index / 5) * 78
            U.Icon(frame, boost.icon or "INV_Misc_Book_09", x, y, 42)
            local mode = C.boostAutomationModeByID[config.mode]
            U.Text(
                frame,
                config.rules and #config.rules > 0 and (#config.rules .. L[" ordered rules"])
                    or config.enabled and (config.mode == "lowHealth" and (L["Below "] .. config.healthBelow .. "%") or mode and mode.name or L["Unavailable"])
                    or L["Manual"],
                x,
                y + 48,
                12,
                T.text,
                150
            )
            index = index + 1
        end
    end
    U.Text(frame, routeName(state, snapshot.route), 470, 360, 16, T.gold, 720)
    U.Text(
        frame,
        (snapshot.route and snapshot.route.enabled and L["Route enabled"] or L["Route paused"])
            .. (
                snapshot.route
                    and snapshot.route.offlineEnabled
                    and L[" | Offline cleared routes on"]
                or L[" | Offline routes off"]
            ),
        470,
        390,
        13,
        T.muted,
        720
    )
    local effect = snapshot.collection and C.collectionByID[snapshot.collection.effect]
    U.Text(
        frame,
        effect and (L["Collection effect: "] .. effect.name)
            or snapshot.collection and L["No collection effect"]
            or L["Collection effect unchanged"],
        470,
        418,
        13,
        T.muted,
        720
    )
    ui.profileControls.save = button(
        frame,
        profile and L["Update snapshot"] or L["Save new profile"],
        470,
        446,
        236,
        function()
            local name = ui.profileName:GetText()
            ui.profileName:ClearFocus()
            W.Action(function(s)
                local ok, result = G.SaveBoostProfile(s, ui.selectedProfile, name)
                if not ok then
                    return false, result
                end
                ui.selectedProfile, ui.profileNameSelection = result, nil
                return true
            end)
        end
    )
    U.Tooltip(
        ui.profileControls.save,
        L["Save current setup"],
        L["Save your boost, automation, route preferences and collection effect. Applying a profile does not restore currency, cooldowns or active effects."]
    )
    ui.profileControls.apply = button(frame, L["Apply profile"], 726, 446, 236, function()
        W.Action(G.ApplyBoostProfile, ui.selectedProfile)
    end)
    ui.profileControls.rename = button(frame, L["Rename"], 470, 496, 236, function()
        ui.profileName:ClearFocus()
        W.Action(G.RenameBoostProfile, ui.selectedProfile, ui.profileName:GetText())
    end)
    ui.profileControls.delete = button(frame, L["Delete profile"], 726, 496, 236, function()
        W.Action(G.DeleteBoostProfile, ui.selectedProfile)
    end)
    for _, control in ipairs({
        ui.profileControls.apply,
        ui.profileControls.rename,
        ui.profileControls.delete,
    }) do
        U.Enabled(control, profile ~= nil)
    end
    U.Enabled(ui.profileControls.save, profile ~= nil or #entries < 8)
    U.EndBuild(frame)
end
