local _, W = ...
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
        return "Time not recorded"
    end
    local minutes = math.floor(seconds / 60)
    return minutes >= 60 and string.format("%dh %02dm", math.floor(minutes / 60), minutes % 60)
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
    U.Text(parent, "EARNINGS SUMMARY", 0, 0, 24, T.gold, 1250)
    ui.offlineCards = {}
    local report = state.lastOfflineSummary
    if type(report) ~= "table" then
        U.Text(parent, "No offline adventure to report yet.", 0, 56, 17, T.text, 1250)
    else
        U.Text(parent, "Safe farming · " .. duration(report.seconds), 0, 44, 16, T.text, 1250)
        if report.interrupted then
            U.Text(
                parent,
                duration(report.remainingSeconds) .. " left to resolve",
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
            "Earnings",
            "INV_Misc_Map_01",
            0,
            100,
            number(report.gold) .. " gold",
            count(report.victories, "victory", "victories"),
            "Earned from offline battles. No Adventure XP or Essence is awarded offline."
        )
        cards.progress = card(
            parent,
            "Hero progress",
            "INV_Misc_Book_09",
            440,
            100,
            number(report.heroXP) .. " hero XP",
            count(report.heroLevels, "level gained", "levels gained")
                .. "\n"
                .. number(report.masteryXP)
                .. " Mastery XP · "
                .. count(report.masteryRanks, "rank", "ranks"),
            "XP retained across the party. Includes level and Mastery gains; excludes XP lost at a cap."
        )
        cards.equipment = card(
            parent,
            "Equipment",
            "INV_Misc_Bag_10",
            880,
            100,
            count(report.itemsKept, "item kept", "items kept"),
            number(report.salvaged) .. " automatically salvaged",
            "Items added to your shared inventory, including stacked copies. Loot rules and inventory space determine what is kept."
        )
        local materials = {}
        for _, id in ipairs(C.materialOrder) do
            local amount = type(report.materials) == "table" and report.materials[id] or nil
            materials[#materials + 1] = C.materials[id]
                .. "  "
                .. (amount ~= nil and "+" .. number(amount) or "—")
        end
        cards.materials = card(
            parent,
            "Materials",
            "Trade_BlackSmithing",
            0,
            314,
            report.fragments
                    and report.fragments > 0
                    and ("Runic fragments +" .. number(report.fragments))
                or "Zone supplies",
            table.concat(materials, "\n"),
            "Materials gained, including salvage. Fractional bonuses carry forward. Runic fragments require eligible tier bosses and a learned recipe."
        )
        cards.automation = card(
            parent,
            "Automation",
            "INV_Misc_Book_09",
            440,
            314,
            count(report.boostUses, "boost use", "boost uses"),
            number(report.routeTransitions)
                .. " route transitions\n"
                .. (
                    report.routeStatus
                    or report.routesWaiting and "Routes waited during offline farming"
                    or report.routesWaiting == false and "Routes were disabled"
                    or "Route state not recorded"
                ),
            "Enabled boosts use normal cooldowns. Optional offline routes visit departure-cleared checkpoints, up to 12 transitions. New progression and resets wait for you."
        )
    end
    U.Help(
        parent,
        "Offline progress",
        1258,
        0,
        "Rewards are already applied. Offline farming is capped at 24 hours.\n\nA dash means the older report did not record that total."
    )
    ui.offlineBack = U.Button(parent, "Back to adventure", 0, 552, 280, 34, function()
        ui:SetTab("adventure")
    end)
end
