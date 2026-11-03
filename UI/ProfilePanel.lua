local _, W = ...
local G, C, U, T = W.Game, W.Content, W.Widgets, W.Theme
local P = {}
W.ProfilePanel = P

local function button(parent, label, x, y, width, action, active)
    return U.Button(parent, label, x, y, width, 34, action, active)
end

local function routeName(state, route)
    if not route or not route.selected then
        return "No route selected"
    end
    for _, template in ipairs(state.routes and state.routes.templates or {}) do
        if template.id == route.selected then
            return template.name
        end
    end
    return "Unavailable route"
end

function P.Draw(ui, parent, state)
    if ui.profileState ~= state then
        ui.profileState, ui.selectedProfile, ui.profileNameSelection = state, nil, nil
    end
    if not ui.profileFrame then
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetAllPoints(parent)
        ui.profileFrame = frame
        local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        edit:SetPoint("TOPLEFT", 478, -34)
        edit:SetSize(714, 36)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(40)
        edit:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
        edit:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        edit:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
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
    U.Text(frame, "Saved profiles · " .. #entries .. "/8", 0, 0, 20, T.gold, 420)
    ui.profileControls = { rows = {} }
    for index, entry in ipairs(entries) do
        local row = U.Button(frame, "", 0, 48 + (index - 1) * 66, 416, 56, function()
            ui.selectedProfile = entry.id
            ui:Refresh()
        end, ui.selectedProfile == entry.id)
        U.Begin(row)
        local boost = entry.equipped and C.boostByID[entry.equipped]
        U.Icon(row, boost and boost.icon or "INV_Misc_Book_09", 10, 8, 40)
            :SetParent(row.content or row)
        U.SingleLine(U.Text(row, entry.name, 64, 8, 15, T.gold, 334), 334, 22)
        U.SingleLine(
            U.Text(row, boost and boost.name or "No equipped boost", 64, 31, 12, T.muted, 334),
            334,
            18
        )
        U.EndBuild(row)
        ui.profileControls.rows[entry.id] = row
    end
    ui.profileControls.new = button(frame, "New profile", 0, 594, 200, function()
        ui.selectedProfile, ui.profileNameSelection = nil, nil
        ui:Refresh()
    end)
    U.Text(frame, profile and "Profile name" or "Name your current setup", 470, 0, 17, T.gold, 720)
    local snapshot = profile
        or {
            equipped = state.boosts.equipped,
            automation = state.boosts.automation,
            route = state.routes
                and { selected = state.routes.selected, enabled = state.routes.enabled },
        }
    local equipped = snapshot.equipped and C.boostByID[snapshot.equipped]
    U.Text(
        frame,
        equipped and equipped.name
            or snapshot.equipped and "Unavailable boost"
            or "No boost equipped",
        470,
        102,
        21,
        T.gold,
        730
    )
    U.Text(
        frame,
        snapshot.automation.enabled and "Automation enabled" or "Automation paused",
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
                config.rules and #config.rules > 0 and (#config.rules .. " ordered rules")
                    or config.enabled and (config.mode == "lowHealth" and ("Below " .. config.healthBelow .. "%") or mode and mode.name or "Unavailable")
                    or "Manual",
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
        snapshot.route and snapshot.route.enabled and "Route enabled" or "Route paused",
        470,
        390,
        13,
        T.muted,
        720
    )
    ui.profileControls.save = button(
        frame,
        profile and "Update snapshot" or "Save new profile",
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
        "Save current setup",
        "Snapshot the current equipped boost, automation rules and route preferences. Timers, active effects and currencies are never saved or restored."
    )
    ui.profileControls.apply = button(frame, "Apply profile", 726, 446, 236, function()
        W.Action(G.ApplyBoostProfile, ui.selectedProfile)
    end)
    ui.profileControls.rename = button(frame, "Rename", 470, 496, 236, function()
        ui.profileName:ClearFocus()
        W.Action(G.RenameBoostProfile, ui.selectedProfile, ui.profileName:GetText())
    end)
    ui.profileControls.delete = button(frame, "Delete profile", 726, 496, 236, function()
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
