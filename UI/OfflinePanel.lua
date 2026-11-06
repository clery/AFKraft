local _, W = ...
local L = W.L
local U, T, C = W.Widgets, W.Theme, W.Content
local P = {}
W.OfflinePanel = P

local function number(value)
    if type(value) ~= "number" or value < 0 or value >= math.huge or value ~= value then
        return "—"
    end
    return tostring(math.floor(value))
end

local function duration(seconds)
    if type(seconds) ~= "number" or seconds < 0 or seconds >= math.huge or seconds ~= seconds then
        return L.TIME_NOT_RECORDED
    end
    local minutes = math.floor(seconds / 60)
    return minutes >= 60 and string.format(L.H_M, math.floor(minutes / 60), minutes % 60)
        or minutes > 0 and (minutes .. "m")
        or (math.floor(seconds) .. "s")
end

local function count(value, singular, plural)
    return number(value) .. " " .. (value == 1 and singular or plural)
end

local function go(ui, tab, hero)
    ui.selected = hero or ui.selected
    ui:SetTab(tab)
end

local function highlights(ui, state, report)
    local entries, best = {}, nil
    for _, item in ipairs(state.inventory) do
        local hero, gain = W.Game.UpgradeRecipient(state, item)
        if hero and (not best or gain > best.gain) then
            best = { item = item, hero = hero, gain = gain }
        end
    end
    if best then
        local item, index = best.item, best.hero
        entries[#entries + 1] = {
            title = string.format(L.RETURN_EQUIP, state.heroes[index].name, W.Game.ItemName(item)),
            detail = string.format(L.UPGRADE_SPOTLIGHT_GAIN, state.heroes[index].name, best.gain),
            icon = item.icon,
            color = C.qualityColors[item.quality],
            label = L.EQUIP,
            action = function()
                for inventoryIndex, stored in ipairs(state.inventory) do
                    local recipient = state.heroes[index]
                    if
                        stored.uid == item.uid
                        and recipient
                        and W.Game.CanEquip(recipient, stored)
                        and W.Game.ItemPower(stored, recipient)
                            > W.Game.ItemPower(recipient.gear[stored.slot], recipient)
                    then
                        W.Action(W.Game.Equip, index, inventoryIndex)
                        return
                    end
                end
                ui:Refresh()
            end,
        }
    end
    local enhancement = report.enhancement
    if type(enhancement) == "table" then
        local hero = state.heroes[enhancement.hero]
        local item = hero and hero.gear[enhancement.slot]
        if
            hero
            and item
            and item.uid == enhancement.uid
            and (item.upgrade or 0) == enhancement.upgrade
            and not (best and best.hero == enhancement.hero and best.item.slot == enhancement.slot)
        then
            local cost = W.Game.UpgradeCost(item, state)
            if state.gold >= cost.gold and state.materials.ore >= cost.materials.ore then
                entries[#entries + 1] = {
                    title = string.format(L.RETURN_ENHANCE, hero.name, W.Game.ItemName(item)),
                    detail = cost.gold .. L.FRAGMENT_GOLD_AND .. cost.materials.ore .. L.ORE_SUFFIX,
                    icon = item.icon,
                    color = T.gold,
                    label = L.UPGRADE_10_STATS,
                    action = function()
                        local current = state.heroes[enhancement.hero].gear[enhancement.slot]
                        if
                            current
                            and current.uid == enhancement.uid
                            and (current.upgrade or 0) == enhancement.upgrade
                        then
                            W.Action(W.Game.Upgrade, enhancement.hero, enhancement.slot)
                        else
                            ui:Refresh()
                        end
                    end,
                }
            end
        end
    end
    local points, talentHero = W.Panels.Opportunities(state)
    local gains = type(report.heroGains) == "table" and report.heroGains or {}
    local strongest
    for _, gained in ipairs(gains) do
        if
            type(gained) == "table"
            and state.heroes[gained.hero]
            and type(gained.levels) == "number"
            and type(gained.level) == "number"
            and type(gained.masteryRanks) == "number"
            and (gained.levels > 0 or gained.masteryRanks > 0)
            and (
                not strongest
                or gained.levels * 10 + gained.masteryRanks
                    > strongest.levels * 10 + strongest.masteryRanks
            )
        then
            strongest = gained
        end
    end
    if strongest then
        local index = strongest.hero
        local companion = state.heroes[index]
        entries[#entries + 1] = {
            title = strongest.levels > 0
                    and string.format(L.RETURN_LEVEL, companion.name, strongest.level)
                or string.format(L.RETURN_MASTERY, companion.name, strongest.masteryRanks),
            detail = points > 0 and string.format(L.RETURN_TALENTS, points) or L.HERO_PROGRESS,
            icon = C.classByID[companion.class].icon,
            color = T.green,
            label = points > 0 and L.SPEND_TALENT_POINTS or L.PARTY_EQUIPMENT,
            action = function()
                go(ui, points > 0 and "talents" or "party", talentHero or index)
            end,
        }
    end
    local chests = W.Game.ChestCount(state)
    if chests > 0 then
        entries[#entries + 1] = {
            title = type(report.chests) == "number"
                    and report.chests > 0
                    and report.chests < math.huge
                    and string.format(L.CHESTS_EARNED, report.chests)
                or string.format(L.CHESTS_WAITING, chests),
            detail = string.format(L.CHESTS_WAITING, chests),
            icon = "INV_Misc_TreasureChest01a",
            color = T.gold,
            label = L.OPEN_CHESTS,
            chest = true,
            action = function()
                go(ui, "chests")
            end,
        }
    end
    if points > 0 and not strongest then
        entries[#entries + 1] = {
            title = string.format(L.RETURN_TALENTS, points),
            detail = L.TALENTS_PRIORITIES,
            icon = "Ability_Marksmanship",
            color = T.green,
            label = L.SPEND_TALENT_POINTS,
            action = function()
                go(ui, "talents", talentHero)
            end,
        }
    end
    if #entries == 0 then
        entries[1] = {
            title = L.RETURN_READY,
            detail = L.RETURN_CREDITED,
            icon = "INV_Misc_Map_01",
            color = T.gold,
            label = L.BACK_TO_ADVENTURE,
            action = function()
                go(ui, "adventure")
            end,
        }
    end
    return entries
end

local function create(ui, parent)
    local frame = CreateFrame("Frame", nil, ui.workspace)
    frame:SetAllPoints(parent)
    frame.art = frame:CreateTexture(nil, "BACKGROUND")
    frame.art:SetPoint("TOPLEFT")
    frame.art:SetSize(1296, 100)
    frame.art:SetTexCoord(0, 1, 0.25, 0.65)
    frame.shade = frame:CreateTexture(nil, "BORDER")
    frame.shade:SetAllPoints(frame.art)
    frame.shade:SetColorTexture(0.03, 0.02, 0.01, 0.65)
    frame.glow = frame:CreateTexture(nil, "ARTWORK")
    frame.glow:SetTexture("Interface\\Cooldown\\star4")
    frame.glow:SetBlendMode("ADD")
    frame.glow:SetPoint("TOPLEFT", -10, 0)
    frame.glow:SetSize(170, 100)
    frame.glow:SetVertexColor(unpack(T.gold))
    frame:SetScript("OnUpdate", function(self, dt)
        if (ui.offlineAge or 1.2) >= 1.2 then
            return
        end
        ui.offlineAge = math.min(1.2, ui.offlineAge + dt)
        local progress = math.min(1, ui.offlineAge / 0.85)
        local eased = 1 - (1 - progress) ^ 3
        self.glow:SetAlpha((1 - ui.offlineAge / 1.2) * 0.5)
        for _, counter in ipairs(ui.offlineNumbers or {}) do
            counter.text:SetText("+" .. number(counter.value * eased) .. counter.suffix)
        end
        for index, card in ipairs(ui.offlineHighlights or {}) do
            card:SetAlpha(math.min(1, 0.55 + math.max(0, ui.offlineAge - (index - 1) * 0.09) * 2))
        end
    end)
    return frame
end

local function card(ui, parent, title, icon, x, headline, detail, tooltip, value, suffix)
    local frame = U.Card(parent, x, 404, 248, 168)
    U.Begin(frame)
    U.Icon(frame, icon, 14, 14, 26):SetParent(frame.content or frame)
    U.SingleLine(U.Text(frame, title, 50, 18, 14, T.gold), 182, 22)
    local counter = U.SingleLine(U.Text(frame, headline, 14, 53, 20, T.text), 220, 30)
    frame.counterText = counter
    if type(value) == "number" and value >= 0 and value < math.huge then
        ui.offlineNumbers[#ui.offlineNumbers + 1] =
            { text = counter, value = value, suffix = suffix or "" }
    end
    U.Text(frame, detail, 14, 94, 12, T.muted, 220):SetHeight(66)
    U.EndBuild(frame)
    U.Tooltip(frame, title, tooltip, 350)
    return frame
end

function P.Draw(ui, parent, state)
    if not ui.offlineFrame then
        ui.offlineFrame = create(ui, parent)
    end
    local frame = ui.offlineFrame
    frame:Show()
    frame.art:SetTexture(C.backdrops[state.zone])
    local report = state.lastOfflineSummary
    if ui.offlineSummary ~= report then
        ui.offlineSummary, ui.offlineAge = report, 0
    end
    ui.offlineCards, ui.offlineHighlights, ui.offlineNumbers = {}, {}, {}
    ui.offlineChests = nil
    U.Begin(frame)
    U.Icon(frame, "INV_Misc_Map_01", 24, 22, 56):SetParent(frame)
    U.SingleLine(U.Text(frame, L.RETURN_WELCOME, 102, 15, 30, T.gold), 1100, 40)
    U.Text(
        frame,
        type(report) == "table" and string.format(L.RETURN_AWAY, duration(report.seconds))
            or L.NO_OFFLINE_ADVENTURE_TO_REPORT_YET,
        104,
        62,
        15,
        T.text,
        1100
    )
    if type(report) == "table" then
        local stories = highlights(ui, state, report)
        for index = 1, math.min(3, #stories) do
            local entry = stories[index]
            local story = U.Card(frame, 0, 116 + (index - 1) * 88, 1296, 76)
            U.Begin(story)
            U.Rect(story, 0, 0, 3, 76, entry.color)
            U.Icon(story, entry.icon, 16, 16, 44):SetParent(story.content or story)
            story.titleText =
                U.SingleLine(U.Text(story, entry.title, 78, 12, 18, entry.color), 890, 28)
            U.SingleLine(U.Text(story, entry.detail, 78, 43, 13, T.text), 890, 22)
            story.action = U.Button(
                story,
                entry.label,
                992,
                20,
                284,
                34,
                entry.action,
                false,
                index == 1 and "primary" or nil
            )
            if entry.chest then
                ui.offlineChests = story.action
            end
            U.EndBuild(story)
            U.Tooltip(story, entry.title, entry.detail, 430)
            story:SetAlpha(1)
            ui.offlineHighlights[#ui.offlineHighlights + 1] = story
        end
        local cards = ui.offlineCards
        cards.earnings = card(
            ui,
            frame,
            L.EARNINGS,
            "INV_Misc_Coin_01",
            0,
            "+" .. number(report.gold) .. L.GOLD_SUFFIX_3,
            count(report.victories, "victory", "victories"),
            L.EARNED_FROM_OFFLINE_BATTLES_NO_ADVENTURE_XP_OR_ESSENCE,
            report.gold,
            L.GOLD_SUFFIX_3
        )
        cards.progress = card(
            ui,
            frame,
            L.HERO_PROGRESS,
            "INV_Misc_Book_09",
            262,
            "+" .. number(report.heroXP) .. L.HERO_XP_SUFFIX,
            count(report.heroLevels, L.LEVEL_GAINED, L.LEVELS_GAINED)
                .. "\n"
                .. number(report.masteryXP)
                .. L.FRAGMENT_MASTERY_XP
                .. count(report.masteryRanks, "rank", "ranks"),
            L.XP_RETAINED_ACROSS_THE_PARTY_INCLUDES_LEVEL_AND_MASTERY,
            report.heroXP,
            L.HERO_XP_SUFFIX
        )
        local chestReport = type(report.chests) == "number"
            and report.chests >= 0
            and report.chests < math.huge
            and report.chests == math.floor(report.chests)
        cards.equipment = card(
            ui,
            frame,
            chestReport and L.CHESTS or L.EQUIPMENT,
            chestReport and "INV_Misc_TreasureChest01a" or "INV_Misc_Bag_10",
            524,
            chestReport and string.format(L.CHESTS_EARNED, report.chests)
                or count(report.itemsKept, L.ITEM_KEPT, L.ITEMS_KEPT),
            chestReport and string.format(L.CHESTS_WAITING, W.Game.ChestCount(state))
                or number(report.salvaged) .. L.AUTOMATICALLY_SALVAGED_SUFFIX,
            chestReport and L.CHESTS_DESCRIPTION
                or L.ITEMS_ADDED_TO_YOUR_SHARED_INVENTORY_INCLUDING_STACKED_COPIES
        )
        local materials = {}
        for _, id in ipairs(C.materialOrder) do
            local amount = type(report.materials) == "table" and report.materials[id] or nil
            materials[#materials + 1] = C.materials[id]
                .. "  "
                .. (amount ~= nil and "+" .. number(amount) or "—")
        end
        local trophyDetails = {}
        local components = type(report.components) == "table" and report.components or {}
        for _, zone in ipairs(C.forgeComponentZones) do
            local amount = components[zone]
            if type(amount) == "number" and amount > 0 and amount < math.huge then
                trophyDetails[#trophyDetails + 1] = C.zoneComponents[zone].name
                    .. " +"
                    .. number(amount)
            end
        end
        cards.materials = card(
            ui,
            frame,
            L.MATERIALS,
            "Trade_BlackSmithing",
            786,
            L.ZONE_SUPPLIES,
            table.concat(materials, "\n"),
            L.MATERIALS_GAINED_INCLUDING_SALVAGE_FRACTIONAL_BONUSES_CARRY_FORWARD
                .. "\n\n"
                .. table.concat(trophyDetails, "\n")
                .. "\n"
                .. L.RUNIC_FRAGMENTS
                .. number(report.fragments)
        )
        cards.automation = card(
            ui,
            frame,
            L.AUTOMATION,
            "INV_Misc_Book_09",
            1048,
            count(report.boostUses, L.BOOST_USE, L.BOOST_USES),
            number(report.routeTransitions) .. L.FRAGMENT_ROUTE_TRANSITIONS,
            report.routeStatus
                or L.ENABLED_BOOSTS_USE_NORMAL_COOLDOWNS_OPTIONAL_OFFLINE_ROUTES_VISIT
        )
        U.Text(
            frame,
            report.interrupted and duration(report.remainingSeconds) .. L.LEFT_TO_RESOLVE_SUFFIX
                or L.RETURN_CREDITED,
            0,
            588,
            13,
            T.muted,
            1296
        )
    end
    ui.offlineBack = U.Button(frame, L.BACK_TO_ADVENTURE, 0, 628, 300, 36, function()
        go(ui, "adventure")
    end)
    ui.offlineParty = U.Button(frame, L.PARTY_EQUIPMENT, 318, 628, 300, 36, function()
        go(ui, "party")
    end)
    if W.Game.ChestCount(state) > 0 and not ui.offlineChests then
        ui.offlineChests = U.Button(frame, L.OPEN_CHESTS, 996, 628, 300, 36, function()
            go(ui, "chests")
        end, false, "primary")
    end
    U.EndBuild(frame)
end
