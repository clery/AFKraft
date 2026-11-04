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
        return L["Time not recorded"]
    end
    local minutes = math.floor(seconds / 60)
    return minutes >= 60 and string.format(L["%dh %02dm"], math.floor(minutes / 60), minutes % 60)
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
    U.Text(parent, L["EARNINGS SUMMARY"], 0, 0, 24, T.gold, 1250)
    ui.offlineCards = {}
    local report = state.lastOfflineSummary
    if type(report) ~= "table" then
        U.Text(parent, L["No offline adventure to report yet."], 0, 56, 17, T.text, 1250)
    else
        U.Text(parent, L["Safe farming · "] .. duration(report.seconds), 0, 44, 16, T.text, 1250)
        if report.interrupted then
            U.Text(
                parent,
                duration(report.remainingSeconds) .. L[" left to resolve"],
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
            L["Earnings"],
            "INV_Misc_Map_01",
            0,
            100,
            number(report.gold) .. L[" gold"],
            count(report.victories, "victory", "victories"),
            L["Earned from offline battles. No Adventure XP or Essence is awarded offline."]
        )
        cards.progress = card(
            parent,
            L["Hero progress"],
            "INV_Misc_Book_09",
            440,
            100,
            number(report.heroXP) .. L[" hero XP"],
            count(report.heroLevels, L["level gained"], L["levels gained"])
                .. "\n"
                .. number(report.masteryXP)
                .. L[" Mastery XP · "]
                .. count(report.masteryRanks, "rank", "ranks"),
            L["XP retained across the party. Includes level and Mastery gains; excludes XP lost at a cap."]
        )
        cards.equipment = card(
            parent,
            L["Equipment"],
            "INV_Misc_Bag_10",
            880,
            100,
            count(report.itemsKept, L["item kept"], L["items kept"]),
            number(report.salvaged) .. L[" automatically salvaged"],
            L["Items added to your shared inventory, including stacked copies. Loot rules and inventory space determine what is kept."]
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
            L["Materials"],
            "Trade_BlackSmithing",
            0,
            314,
            trophies > 0 and (L["Boss trophies +"] .. number(trophies))
                or report.fragments and report.fragments > 0 and (L["Runic fragments +"] .. number(
                    report.fragments
                ))
                or L["Zone supplies"],
            table.concat(materials, "\n"),
            L["Materials gained, including salvage. Fractional bonuses carry forward. Runic fragments require eligible tier bosses and a learned recipe."]
                .. "\n\n"
                .. table.concat(trophyDetails, "\n")
        )
        cards.automation = card(
            parent,
            L["Automation"],
            "INV_Misc_Book_09",
            440,
            314,
            count(report.boostUses, L["boost use"], L["boost uses"]),
            number(report.routeTransitions)
                .. L[" route transitions\n"]
                .. (
                    report.routeStatus
                    or report.routesWaiting and L["Routes waited during offline farming"]
                    or report.routesWaiting == false and L["Routes were disabled"]
                    or L["Route state not recorded"]
                ),
            L["Enabled boosts use normal cooldowns. Optional offline routes visit departure-cleared checkpoints, up to 12 transitions. New progression and resets wait for you."]
        )
    end
    U.Help(
        parent,
        L["Offline progress"],
        1258,
        0,
        L["Rewards are already applied. Offline farming is capped at 24 hours.\n\nA dash means the older report did not record that total."]
    )
    ui.offlineBack = U.Button(parent, L["Back to adventure"], 0, 552, 280, 34, function()
        ui:SetTab("adventure")
    end)
end
