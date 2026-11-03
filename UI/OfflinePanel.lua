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
    local frame = U.Button(parent, "", x, y, 416, 190, function() end)
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
    U.Text(parent, "RETURN REPORT", 0, 0, 24, T.gold, 1250)
    ui.offlineCards = {}
    local report = state.lastOfflineSummary
    if type(report) ~= "table" then
        U.Text(parent, "No offline adventure to report yet.", 0, 56, 17, T.text, 1250)
    else
        U.Text(
            parent,
            "Safe farming · " .. duration(report.seconds) .. " · Rewards already applied",
            0,
            44,
            16,
            T.text,
            1250
        )
        local status = report.interrupted
                and (duration(report.remainingSeconds) .. " remains to resolve on your next load.")
            or "The latest resolved absence. Your adventure continues."
        U.Text(parent, status, 0, 78, 14, T.muted, 1250)
        local cards = ui.offlineCards
        cards.earnings = card(
            parent,
            "Earnings",
            "INV_Misc_Map_01",
            0,
            132,
            number(report.gold) .. " gold",
            count(report.victories, "victory", "victories"),
            "Gold and victories from resolved offline encounters. Offline combat never awards real-activity Adventure XP or Essence."
        )
        cards.progress = card(
            parent,
            "Hero progress",
            "INV_Misc_Book_09",
            440,
            132,
            number(report.heroXP) .. " hero XP",
            count(report.heroLevels, "level gained", "levels gained")
                .. "\n"
                .. number(report.masteryXP)
                .. " Mastery XP · "
                .. count(report.masteryRanks, "rank", "ranks"),
            "Actual retained XP across the party, including level and Mastery rank advances. XP beyond a progression cap is not counted."
        )
        cards.equipment = card(
            parent,
            "Equipment",
            "INV_Misc_Bag_10",
            880,
            132,
            count(report.itemsKept, "item kept", "items kept"),
            number(report.salvaged) .. " automatically salvaged",
            "Kept items include stacked units added to your shared inventory. Your loot rules and inventory capacity decide what is retained or salvaged."
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
            346,
            report.fragments
                    and report.fragments > 0
                    and ("Runic fragments +" .. number(report.fragments))
                or "Zone supplies",
            table.concat(materials, "\n"),
            "Whole materials gained, including salvage returns. Runic fragments come only from eligible tier bosses after a recipe is learned. Fractional combat bonuses are retained for later encounters."
        )
        cards.collections = card(
            parent,
            "Collections",
            "INV_Misc_Bag_10",
            440,
            346,
            report.collectionMode == "outdoor" and "Outdoor hunting stays online"
                or count(report.discoveries, "new discovery", "new discoveries"),
            report.collectionMode == "outdoor" and "No offline discoveries or hunt progress"
                or count(report.upgrades, "higher-tier piece", "higher-tier pieces"),
            "Outdoor discoveries and per-piece guarantees require attributed real-world kills. Offline battles award ordinary equipment and materials. Historical reports may include retired simulated collection rewards."
        )
        cards.automation = card(
            parent,
            "Automation",
            "INV_Misc_Book_09",
            880,
            346,
            count(report.boostUses, "boost use", "boost uses"),
            number(report.routeTransitions)
                .. " route transitions\n"
                .. (
                    report.routeStatus
                    or report.routesWaiting and "Routes waited during offline farming"
                    or report.routesWaiting == false and "Routes were disabled"
                    or "Route state not recorded"
                ),
            "Owned, enabled boost rules use the same clock and cooldowns as online combat. Offline routes require a separate opt-in and visit only checkpoints cleared before departure, at most 12 transitions. New destinations, tiers and resets wait for online play."
        )
    end
    U.Text(
        parent,
        "— means an older report did not record that total.",
        0,
        574,
        13,
        T.muted,
        1250
    )
    ui.offlineBack = U.Button(parent, "Back to adventure", 0, 622, 280, 34, function()
        ui:SetTab("adventure")
    end)
end
