local _, W = ...
local G, C, L, U, T = W.Game, W.Content, W.L, W.Widgets, W.Theme
local P = {}
W.ChestPanel = P

local function storedItem(state, uid)
    for index, item in ipairs(state.inventory) do
        if item.uid == uid then
            return item, index
        end
    end
end

local function mergeReport(previous, report)
    if not previous then
        return report
    end
    for _, key in ipairs({
        "count",
        "salvaged",
        "duplicates",
        "gold",
        "ore",
        "equipped",
        "disenchanted",
        "relic",
        "powerGain",
    }) do
        if previous[key] or report[key] then
            previous[key] = (previous[key] or 0) + (report[key] or 0)
        end
    end
    previous.quality = math.max(previous.quality, report.quality)
    for _, entry in ipairs(report.entries) do
        local matched
        for _, old in ipairs(previous.entries) do
            if
                old.uid == entry.uid
                and old.zone == entry.zone
                and old.kept == entry.kept
                and (old.equipped ~= nil) == (entry.equipped ~= nil)
                and (old.disenchanted ~= nil) == (entry.disenchanted ~= nil)
                and old.item.slot == entry.item.slot
                and old.item.level == entry.item.level
                and old.item.quality == entry.item.quality
                and G.SameItem(old.item, entry.item)
            then
                old.count = old.count + entry.count
                if entry.equipped then
                    old.equipped = old.equipped + entry.equipped
                end
                if entry.disenchanted then
                    old.disenchanted = old.disenchanted + entry.disenchanted
                end
                matched = true
                break
            end
        end
        if not matched then
            previous.entries[#previous.entries + 1] = entry
        end
    end
    return previous
end

local function reveal(ui, silent)
    local report = ui.chestOpening
    if not report then
        return
    end
    ui.chestOpening = nil
    ui.chestResultElapsed = silent and 1 or 0
    ui.chestReport = mergeReport(ui.chestReport, report)
    if not silent and ui.chestState == W.state then
        if not ui.chestImpact then
            W.Audio.ChestReveal(W.state, report.quality)
        end
        for _, entry in ipairs(report.entries) do
            local item = entry.uid and storedItem(W.state, entry.uid)
            if item then
                G.Emit(W.state, "item", { item = item })
            end
        end
    end
end

local function finish(ui)
    reveal(ui)
    ui.chestResultElapsed = 1
    ui:Refresh()
end

local function scene(ui, parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 0, -128)
    frame:SetSize(1296, 170)
    frame.glow = frame:CreateTexture(nil, "BACKGROUND")
    frame.glow:SetTexture("Interface\\Cooldown\\star4")
    frame.glow:SetBlendMode("ADD")
    frame.glow:SetPoint("CENTER", 0, 8)
    frame.glow:SetSize(310, 200)
    frame.chests, frame.models = {}, {}
    for i = 1, 3 do
        local icon = U.Icon(frame, "INV_Misc_TreasureChest01a", 0, 0, i == 1 and 100 or 64)
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", (i == 1 and 0 or i == 2 and -130 or 130), 8)
        frame.chests[i] = icon
        local model = W.Client.CreateChestModel(frame, icon)
        model:SetSize(i == 1 and 260 or 180, 150)
        model:SetPoint("CENTER", i == 1 and 0 or i == 2 and -180 or 180, 18)
        frame.models[i] = model
    end
    local effects = CreateFrame("Frame", nil, frame)
    effects:SetAllPoints()
    effects:SetFrameLevel(frame.models[1]:GetFrameLevel() + 1)
    frame.flash = effects:CreateTexture(nil, "OVERLAY")
    frame.flash:SetTexture("Interface\\Cooldown\\star4")
    frame.flash:SetBlendMode("ADD")
    frame.flash:SetPoint("CENTER", 0, 8)
    frame.flash:SetSize(260, 150)
    frame.flash:SetAlpha(0)
    frame.sparks = {}
    for i = 1, 12 do
        local spark = effects:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetSize(18, 50)
        frame.sparks[i] = spark
    end
    frame.label = U.SingleLine(U.Text(frame, "", 340, 143, 18, T.gold), 616, 26, "CENTER")
    frame:SetScript("OnUpdate", function(self, dt)
        if ui.chestResultElapsed and ui.chestResultElapsed < 1 then
            ui.chestResultElapsed = math.min(1, ui.chestResultElapsed + dt)
            for index, highlight in ipairs(ui.chestHighlights or {}) do
                local age = ui.chestResultElapsed - (index - 1) * 0.07
                highlight:SetAlpha(age > 0 and math.max(0, 1 - age / 0.45) * 0.65 or 0)
            end
        end
        local report = ui.chestOpening
        if not report then
            return
        end
        if ui.chestState ~= W.state or ui.chestStorage ~= W.state.chests or W.catchup then
            ui.chestOpening, ui.chestReport = nil, nil
            ui:Refresh()
            return
        end
        ui.chestElapsed = ui.chestElapsed + dt
        local quality = report.quality
        local charge = ui.chestCharge
        local release = math.max(0, ui.chestElapsed - charge)
        local burst = math.max(0, release - 0.95)
        local progress = math.min(1, ui.chestElapsed / ui.chestDuration)
        local color = C.qualityColors[quality]
        local pose = release == 0 and "closed" or burst == 0 and "opening" or "opened"
        local energy = release == 0 and ui.chestElapsed / charge * 0.45
            or burst == 0 and 0.45 + release / 0.95 * 0.55
            or math.max(0, 1 - burst / (ui.chestDuration - charge - 0.95))
        if burst > 0 and not ui.chestImpact then
            ui.chestImpact = true
            W.Audio.ChestReveal(W.state, quality)
        end
        for index, model in ipairs(self.models) do
            W.Client.ChestPose(model, pose)
            W.Client.ChestLight(model, color, energy * quality * 0.6)
            model:ClearAllPoints()
            model:SetPoint(
                "CENTER",
                (index == 1 and 0 or index == 2 and -180 or 180)
                    + (release == 0 and math.sin(ui.chestElapsed * 70) * energy * 3 or 0),
                18
            )
        end
        self.flash:SetVertexColor(unpack(color))
        self.flash:SetAlpha(burst > 0 and math.max(0, 1 - burst / 0.25) or 0)
        self.glow:SetVertexColor(unpack(color))
        self.glow:SetRotation(ui.chestElapsed * 0.7)
        self.glow:SetSize(180 + energy * quality * 90, 100 + energy * quality * 45)
        self.glow:SetAlpha(math.min(1, energy * (0.35 + quality * 0.16)))
        self.chests[1]:SetSize(100 + energy * 12, 100 + energy * 12)
        for i, spark in ipairs(self.sparks) do
            local angle = i * math.pi / 6
            local distance = burst > 0 and 45 + burst * (220 + quality * 45) or 35 + energy * 30
            spark:ClearAllPoints()
            spark:SetPoint(
                "CENTER",
                math.cos(angle) * distance,
                8 + math.sin(angle) * distance * 0.45
            )
            spark:SetRotation(angle - math.pi / 2)
            spark:SetVertexColor(unpack(color))
            spark:SetAlpha(burst > 0 and energy * (0.4 + quality * 0.15) or energy * 0.15)
        end
        if progress >= 1 then
            reveal(ui)
            ui:Refresh()
        end
    end)
    return frame
end

local function open(ui, quantity)
    W.Action(function(state)
        local ok, message, report = G.OpenChests(state, quantity, ui.chestZone)
        if ok then
            ui.chestState, ui.chestStorage = state, state.chests
            if not ui.chestOpening then
                ui.chestElapsed, ui.chestPage, ui.chestImpact = 0, 0, false
                ui.chestCharge = 0.35 + report.quality * 0.08
                ui.chestDuration = ui.chestCharge + 0.95 + 0.22 + report.quality * 0.06
            end
            ui.chestOpening = mergeReport(ui.chestOpening, report)
            if state.settings.instantChestReveal then
                -- Rewards are already committed; skipping only changes presentation.
                reveal(ui)
                ui.chestResultElapsed = 1
            end
        end
        return ok, message
    end)
end

function P.Draw(ui, parent, state)
    if not ui.chestFrame then
        local frame = CreateFrame("Frame", nil, ui.workspace)
        frame:SetAllPoints(parent)
        frame:SetScript("OnHide", function()
            reveal(ui, true)
        end)
        ui.chestFrame = frame
        ui.chestScene = scene(ui, frame)
    end
    local frame = ui.chestFrame
    frame:Show()
    if ui.chestState ~= state or (ui.chestStorage and ui.chestStorage ~= state.chests) then
        ui.chestOpening, ui.chestReport = nil, nil
        ui.chestState, ui.chestStorage = state, state.chests
    end
    if ui.chestZone and not C.zoneByID[ui.chestZone] then
        ui.chestZone = nil
    end
    U.Begin(frame)
    local total = G.ChestCount(state, ui.chestZone)
    U.Text(frame, string.format(L.CHESTS_WAITING, total), 0, 0, 23, T.gold, 1100)
    U.Help(frame, L.CHESTS, 1258, 0, L.CHESTS_DESCRIPTION)
    local sources = { { id = "any", name = L.ALL_CHEST_SOURCES } }
    local counts = {}
    for _, chest in ipairs(state.chests) do
        counts[chest.zone] = (counts[chest.zone] or 0) + chest.count
    end
    for _, zone in ipairs(C.zones) do
        if counts[zone.id] then
            sources[#sources + 1] = { id = zone.id, name = zone.name .. " · " .. counts[zone.id] }
        end
    end
    ui.chestSource = U.Choice(
        frame,
        ui.chestZone and C.zoneByID[ui.chestZone].name or L.ALL_CHEST_SOURCES,
        0,
        48,
        330,
        sources,
        ui.chestZone or "any",
        function(value)
            ui.chestZone = value ~= "any" and value or nil
            ui:Refresh()
        end
    )
    ui.chestControls = {}
    for index, entry in ipairs({
        { 1, L.OPEN_ONE_CHEST },
        { 10, L.OPEN_TEN_CHESTS },
        { "all", L.OPEN_ALL_CHESTS },
    }) do
        local quantity = entry[1]
        local control = U.Button(frame, entry[2], 350 + (index - 1) * 180, 48, 164, 32, function()
            open(ui, quantity)
        end, false, index == 3 and "primary" or nil)
        U.Enabled(control, total > 0)
        ui.chestControls[quantity] = control
    end
    ui.chestInstant = U.Checkbox(
        frame,
        L.INSTANT_CHEST_REVEAL,
        920,
        48,
        370,
        state.settings.instantChestReveal,
        function(value)
            state.settings.instantChestReveal = value
            if value and ui.chestOpening then
                finish(ui)
            else
                ui:Refresh()
            end
        end
    )
    ui.chestAutoEquip = U.Checkbox(
        frame,
        L.CHEST_AUTO_EQUIP,
        0,
        88,
        1250,
        state.settings.chestAutoEquip,
        function(value)
            state.settings.chestAutoEquip = value
            ui:Refresh()
        end
    )
    U.Tooltip(ui.chestAutoEquip, L.CHEST_AUTO_EQUIP, L.CHEST_AUTO_EQUIP_DESCRIPTION, 420)
    local report, opening = ui.chestReport, ui.chestOpening
    local display = ui.chestScene
    display.chests[1]:SetSize(100, 100)
    for index, icon in ipairs(display.chests) do
        local shown = index == 1 or (opening and opening.count > 1)
        local model = display.models[index]
        model:SetShown(shown == true)
        icon:SetShown(shown == true and not model.chestReady)
        W.Client.ChestPose(
            model,
            opening
                    and (ui.chestElapsed < ui.chestCharge and "closed" or ui.chestElapsed < ui.chestCharge + 0.95 and "opening" or "opened")
                or report and "opened"
                or "closed"
        )
    end
    if not opening then
        display.flash:SetAlpha(0)
        display.glow:SetAlpha(report and 0.18 or 0)
        for _, spark in ipairs(display.sparks) do
            spark:SetAlpha(0)
        end
    end
    display.label:SetText(
        opening and string.format(L.OPENING_CHESTS, opening.count)
            or report and string.format(L.CHESTS_OPENED, report.count)
            or L.YOUR_NEXT_TREASURE
    )
    display.label:SetTextColor(
        unpack((opening or report) and C.qualityColors[(opening or report).quality] or T.gold)
    )
    ui.chestResultButtons, ui.chestHighlights = {}, {}
    ui.chestSkip = nil
    if opening then
        ui.chestSkip = U.Button(frame, L.REVEAL_NOW, 1030, 0, 200, 32, function()
            finish(ui)
        end, false, "primary")
    end
    if report then
        U.SingleLine(
            U.Text(
                frame,
                report.disenchanted
                        and string.format(
                            L.CHEST_AUTO_SUMMARY,
                            report.equipped,
                            report.powerGain,
                            report.disenchanted,
                            report.gold,
                            report.relic
                        )
                    or string.format(
                        L.CHEST_RESULTS_SUMMARY,
                        report.duplicates,
                        report.salvaged,
                        report.gold,
                        report.ore
                    ),
                0,
                300,
                15,
                T.muted
            ),
            1296,
            24
        )
        local pages = math.max(1, math.ceil(#report.entries / 6))
        ui.chestPage = math.max(0, math.min(ui.chestPage or 0, pages - 1))
        for position = 1, 6 do
            local entry = report.entries[ui.chestPage * 6 + position]
            if entry then
                local x, y = (position - 1) % 3 * 440, 347 + math.floor((position - 1) / 3) * 140
                local item = entry.item
                local stored = entry.uid and storedItem(state, entry.uid)
                local recipient, gain
                if stored then
                    recipient, gain = G.UpgradeRecipient(state, stored)
                end
                local card = U.Card(frame, x, y, 416, 128)
                U.Begin(card)
                local color = C.qualityColors[item.quality]
                U.Rect(card, 0, 0, 3, 128, color)
                local highlight = U.Rect(card, 3, 0, 413, 128, color, 0.2)
                highlight:SetAlpha(0)
                ui.chestHighlights[#ui.chestHighlights + 1] = highlight
                U.Icon(card, item.icon, 14, 14, 40):SetParent(card.content or card)
                U.SingleLine(
                    U.Text(
                        card,
                        G.ItemName(item) .. " ×" .. entry.count,
                        68,
                        12,
                        14,
                        C.qualityColors[item.quality]
                    ),
                    332,
                    24
                )
                U.SingleLine(
                    U.Text(
                        card,
                        C.zoneByID[entry.zone].name .. " · " .. C.qualityNames[item.quality],
                        68,
                        40,
                        12,
                        T.muted
                    ),
                    332,
                    22
                )
                U.SingleLine(
                    U.Text(
                        card,
                        recipient
                                and string.format(
                                    L.UPGRADE_SPOTLIGHT_GAIN,
                                    state.heroes[recipient].name,
                                    gain
                                )
                            or entry.equipped and string.format(
                                L.CHEST_AUTO_ITEM,
                                entry.equipped,
                                entry.disenchanted or 0
                            )
                            or entry.disenchanted and L.CHEST_ITEM_DISENCHANTED
                            or not entry.kept and L.CHEST_ITEM_SALVAGED
                            or stored and L.CHEST_ITEM_STORED
                            or L.CHEST_ITEM_COLLECTED,
                        14,
                        83,
                        12,
                        recipient and T.green or T.muted
                    ),
                    recipient and 254 or 386,
                    28
                )
                if recipient then
                    local equip = U.Button(card, L.EQUIP, 282, 83, 118, 28, function()
                        local current, inventoryIndex = storedItem(state, entry.uid)
                        local hero = state.heroes[recipient]
                        if
                            current
                            and G.CanEquip(hero, current)
                            and G.ItemPower(current, hero)
                                > G.ItemPower(hero.gear[current.slot], hero)
                        then
                            W.Action(G.Equip, recipient, inventoryIndex)
                        end
                    end)
                    ui.chestResultButtons[#ui.chestResultButtons + 1] = equip
                end
                U.EndBuild(card)
                U.Tooltip(
                    card,
                    G.ItemName(item),
                    G.ItemDescription(
                        item,
                        recipient and state.heroes[recipient] or nil,
                        recipient ~= nil
                    ),
                    370
                )
            end
        end
        if pages > 1 then
            local previous = U.Button(frame, L.PREVIOUS, 0, 644, 170, 30, function()
                ui.chestPage = ui.chestPage - 1
                ui:Refresh()
            end)
            local nextPage = U.Button(frame, L.NEXT, 1126, 644, 170, 30, function()
                ui.chestPage = ui.chestPage + 1
                ui:Refresh()
            end)
            U.Enabled(previous, ui.chestPage > 0)
            U.Enabled(nextPage, ui.chestPage < pages - 1)
        end
    else
        U.Text(frame, L.CHESTS_DESCRIPTION, 280, 340, 17, T.muted, 736)
    end
    U.EndBuild(frame)
end
