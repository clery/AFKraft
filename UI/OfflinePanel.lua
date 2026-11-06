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

local function card(parent, title, icon, x, y, headline, detail, tooltip)
    local frame = U.Card(parent, x, y, 416, 190)
    U.Begin(frame)
    local art = U.Icon(frame, icon, 16, 16, 36)
    art:SetParent(frame.content or frame)
    U.Text(frame, title, 66, 22, 17, T.gold, 330)
    U.Text(frame, headline, 16, 74, 22, T.text, 384)
    U.Text(frame, detail, 16, 116, 14, T.muted, 384)
    U.EndBuild(frame)
    U.Tooltip(frame, title, tooltip, 350)
    return frame
end

function P.Draw(ui, parent, state)
    U.Text(parent, L.EARNINGS_SUMMARY_HEADING, 0, 0, 24, T.gold, 1250)
    ui.offlineCards = {}
    local report = state.lastOfflineSummary
    if type(report) ~= "table" then
        U.Text(parent, L.NO_OFFLINE_ADVENTURE_TO_REPORT_YET, 0, 56, 17, T.text, 1250)
    else
        U.Text(parent, L.SAFE_FARMING_PREFIX .. duration(report.seconds), 0, 44, 16, T.text, 1250)
        if report.interrupted then
            U.Text(
                parent,
                duration(report.remainingSeconds) .. L.LEFT_TO_RESOLVE_SUFFIX,
                0,
                78,
                14,
                T.gold,
                1250
            )
        end
        local cards = ui.offlineCards
        cards.earnings = card(
            parent,
            L.EARNINGS,
            "INV_Misc_Map_01",
            0,
            100,
            number(report.gold) .. L.GOLD_SUFFIX_3,
            count(report.victories, "victory", "victories"),
            L.EARNED_FROM_OFFLINE_BATTLES_NO_ADVENTURE_XP_OR_ESSENCE
        )
        cards.progress = card(
            parent,
            L.HERO_PROGRESS,
            "INV_Misc_Book_09",
            440,
            100,
            number(report.heroXP) .. L.HERO_XP_SUFFIX,
            count(report.heroLevels, L.LEVEL_GAINED, L.LEVELS_GAINED)
                .. "\n"
                .. number(report.masteryXP)
                .. L.FRAGMENT_MASTERY_XP
                .. count(report.masteryRanks, "rank", "ranks"),
            L.XP_RETAINED_ACROSS_THE_PARTY_INCLUDES_LEVEL_AND_MASTERY
        )
        local chestReport = type(report.chests) == "number"
            and report.chests >= 0
            and report.chests < math.huge
            and report.chests == math.floor(report.chests)
        cards.equipment = card(
            parent,
            chestReport and L.CHESTS or L.EQUIPMENT,
            chestReport and "INV_Misc_TreasureChest01a" or "INV_Misc_Bag_10",
            880,
            100,
            chestReport and string.format(L.CHESTS_EARNED, report.chests)
                or count(report.itemsKept, L.ITEM_KEPT, L.ITEMS_KEPT),
            chestReport and L.CHEST_READY_DETAIL
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
        local trophies, trophyDetails = 0, {}
        local components = type(report.components) == "table" and report.components or {}
        for _, zone in ipairs(C.forgeComponentZones) do
            local amount = components[zone] or 0
            if type(amount) == "number" and amount > 0 and amount < math.huge then
                trophies = trophies + amount
                trophyDetails[#trophyDetails + 1] = C.zoneComponents[zone].name
                    .. " +"
                    .. number(amount)
            end
        end
        cards.materials = card(
            parent,
            L.MATERIALS,
            "Trade_BlackSmithing",
            0,
            314,
            trophies > 0 and (L.BOSS_TROPHIES .. number(trophies))
                or report.fragments and report.fragments > 0 and (L.RUNIC_FRAGMENTS .. number(
                    report.fragments
                ))
                or L.ZONE_SUPPLIES,
            table.concat(materials, "\n"),
            L.MATERIALS_GAINED_INCLUDING_SALVAGE_FRACTIONAL_BONUSES_CARRY_FORWARD
                .. "\n\n"
                .. table.concat(trophyDetails, "\n")
        )
        cards.automation = card(
            parent,
            L.AUTOMATION,
            "INV_Misc_Book_09",
            440,
            314,
            count(report.boostUses, L.BOOST_USE, L.BOOST_USES),
            number(report.routeTransitions)
                .. L.FRAGMENT_ROUTE_TRANSITIONS
                .. (
                    report.routeStatus
                    or report.routesWaiting and L.ROUTES_WAITED_DURING_OFFLINE_FARMING
                    or report.routesWaiting == false and L.ROUTES_WERE_DISABLED
                    or L.ROUTE_STATE_NOT_RECORDED
                ),
            L.ENABLED_BOOSTS_USE_NORMAL_COOLDOWNS_OPTIONAL_OFFLINE_ROUTES_VISIT
        )
    end
    if W.Game.ChestCount(state) > 0 then
        ui.offlineChests = U.Button(parent, L.OPEN_CHESTS, 880, 552, 416, 34, function()
            ui:SetTab("chests")
        end, false, "primary")
    end
    U.Help(parent, L.OFFLINE_PROGRESS, 1258, 0, L.OFFLINE_PROGRESS_DESCRIPTION)
    ui.offlineBack = U.Button(parent, L.BACK_TO_ADVENTURE, 0, 552, 280, 34, function()
        ui:SetTab("adventure")
    end)
end
