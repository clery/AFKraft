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

local function reveal(ui)
    local report = ui.chestOpening
    if not report then
        return
    end
    ui.chestOpening = nil
    if ui.chestState == W.state then
        W.Audio.ChestReveal(W.state, report.quality)
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
    frame.sparks = {}
    for i = 1, 8 do
        local spark = frame:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetSize(12, 24)
        frame.sparks[i] = spark
    end
    frame.label = U.SingleLine(U.Text(frame, "", 340, 143, 18, T.gold), 616, 26, "CENTER")
    frame:SetScript("OnUpdate", function(self, dt)
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
        local duration = 1.2 + quality * 0.35
        local progress = math.min(1, ui.chestElapsed / duration)
        local color = C.qualityColors[quality]
        for _, model in ipairs(self.models) do
            W.Client.ChestLight(model, color, progress * quality * 0.4)
        end
        self.glow:SetVertexColor(unpack(color))
        self.glow:SetRotation(progress * (0.4 + quality * 0.2))
        self.glow:SetSize(120 + progress * quality * 55, 90 + progress * quality * 30)
        self.glow:SetAlpha(
            (0.12 + progress * 0.18 * quality) * (0.8 + 0.2 * math.sin(progress * 20))
        )
        self.chests[1]:SetSize(100 + progress * quality * 5, 100 + progress * quality * 5)
        for i, spark in ipairs(self.sparks) do
            local angle = i * math.pi / 4
            local distance = 35 + progress * (40 + quality * 13)
            spark:ClearAllPoints()
            spark:SetPoint(
                "CENTER",
                math.cos(angle) * distance,
                8 + math.sin(angle) * distance * 0.5
            )
            spark:SetVertexColor(unpack(color))
            spark:SetAlpha(quality >= 2 and progress * (0.3 + quality * 0.15) or 0)
        end
        if progress >= 1 then
            finish(ui)
        end
    end)
    return frame
end

local function open(ui, quantity)
    W.Action(function(state)
        local ok, message, report = G.OpenChests(state, quantity, ui.chestZone)
        if ok then
            ui.chestState, ui.chestReport, ui.chestOpening = state, report, report
            ui.chestStorage = state.chests
            ui.chestElapsed, ui.chestPage = 0, 0
            if state.settings.instantChestReveal then
                -- Rewards are already committed; skipping only changes presentation.
                reveal(ui)
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
            ui.chestOpening = nil
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
        W.Client.ChestPose(model, opening and "opening" or report and "opened" or "closed")
    end
    display.glow:SetAlpha(0)
    for _, spark in ipairs(display.sparks) do
        spark:SetAlpha(0)
    end
    display.label:SetText(
        opening and string.format(L.OPENING_CHESTS, opening.count)
            or report and string.format(L.CHESTS_OPENED, report.count)
            or L.YOUR_NEXT_TREASURE
    )
    display.label:SetTextColor(unpack(report and C.qualityColors[report.quality] or T.gold))
    ui.chestResultButtons = {}
    ui.chestSkip = nil
    if opening then
        ui.chestSkip = U.Button(frame, L.REVEAL_NOW, 548, 306, 200, 32, function()
            finish(ui)
        end, false, "primary")
    elseif report then
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
