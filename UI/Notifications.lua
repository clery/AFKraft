local _, W = ...
local G, C, L, U, T = W.Game, W.Content, W.L, W.Widgets, W.Theme
local N = { queue = {} }
W.Notifications = N

function N.Clear()
    N.queue = {}
    N.current, N.state = nil, nil
    if N.frame then
        N.frame:Hide()
    end
end

local function available(state, item)
    for index, stored in ipairs(state.inventory) do
        if stored == item then
            return index
        end
    end
end

local function prepare(entry)
    local state = W.state
    if entry.kind == "chest" then
        local count = G.ChestCount(state)
        if count == 0 then
            return false
        end
        entry.title = string.format(L.CHESTS_WAITING, count)
    end
    if entry.item and entry.kind == "upgrade" then
        if not available(state, entry.item) then
            return false
        end
        local recipient, gain = G.UpgradeRecipient(state, entry.item)
        if not recipient then
            return false
        end
        entry.target = recipient
        entry.detail = string.format(L.UPGRADE_SPOTLIGHT_GAIN, state.heroes[recipient].name, gain)
    end
    return true
end

local function dismiss()
    N.current = nil
    N.frame:Hide()
end

local function activate()
    local entry, state = N.current, W.state
    if not entry or state ~= N.state or W.catchup then
        return
    end
    if entry.kind == "upgrade" then
        local index = available(state, entry.item)
        local hero = state.heroes[entry.target]
        if
            index
            and hero
            and G.CanEquip(hero, entry.item)
            and G.ItemPower(entry.item, hero) > G.ItemPower(hero.gear[entry.item.slot], hero)
        then
            W.Action(G.Equip, entry.target, index)
        end
    else
        W.UI.selected = entry.target or W.UI.selected
        W.UI.frame:Show()
        W.UI:SetTab(entry.tab)
    end
    dismiss()
end

local function create()
    local frame = CreateFrame("Frame", "AFKraftRewardToast", UIParent, "BackdropTemplate")
    N.frame = frame
    frame:SetSize(380, 132)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -32, 180)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    U.Rect(frame, 4, 4, 372, 124, T.bg)
    frame.icon = U.Icon(frame, "INV_Misc_Bag_10", 18, 41, 44)
    frame.heading = U.SingleLine(U.Text(frame, "", 18, 13, 12, T.gold), 310, 20)
    frame.title = U.SingleLine(U.Text(frame, "", 74, 39, 14), 286, 24)
    frame.detail = U.SingleLine(U.Text(frame, "", 74, 65, 12, T.green), 286, 22)
    frame.action = U.Button(frame, L.EQUIP, 246, 96, 114, 24, activate)
    frame.close = U.Button(frame, "×", 342, 10, 24, 24, dismiss)
    U.Tooltip(frame.close, L.CLOSE, "")
    frame:SetScript("OnUpdate", function(self, dt)
        if N.state ~= W.state or W.catchup or not W.state.settings.rewardToasts then
            N.Clear()
            return
        end
        if N.age < 0.2 or not self:IsMouseOver() then
            N.age = N.age + dt
        else
            N.age = math.min(N.age, 7.2)
        end
        self:SetAlpha(math.min(1, N.age / 0.2, math.max(0, (8 - N.age) / 0.4)))
        if N.age >= 8 then
            dismiss()
        end
    end)
    frame:Hide()
end

function N.Flush()
    if N.state and (N.state ~= W.state or W.catchup or not W.state.settings.rewardToasts) then
        N.Clear()
    end
    if N.current then
        return
    end
    while #N.queue > 0 do
        local entry = table.remove(N.queue, 1)
        if prepare(entry) then
            if not N.frame then
                create()
            end
            local frame = N.frame
            N.current, N.age = entry, 0
            frame.heading:SetText("AFKraft · " .. entry.heading)
            frame.title:SetText(entry.title)
            frame.title:SetTextColor(unpack(entry.color or T.text))
            frame.detail:SetText(entry.detail)
            frame.icon:SetTexture("Interface\\Icons\\" .. entry.icon)
            frame:SetBackdropBorderColor(unpack(entry.color or T.gold))
            frame.action.text:SetText(entry.kind == "upgrade" and L.EQUIP or L.VIEW_REWARD)
            U.Tooltip(
                frame,
                entry.title,
                entry.item and G.ItemDescription(entry.item, W.state.heroes[entry.target], true)
                    or entry.detail
            )
            frame:SetAlpha(0)
            frame:Show()
            return
        end
    end
end

local function enqueue(entry)
    for index, pending in ipairs(N.queue) do
        if pending.key == entry.key then
            N.queue[index] = entry
            return
        end
    end
    if #N.queue >= 5 then
        table.remove(N.queue, 1)
    end
    N.queue[#N.queue + 1] = entry
end

local previousEvent = W.OnGameEvent
function W.OnGameEvent(state, event)
    if previousEvent then
        previousEvent(state, event)
    end
    if state ~= W.state or W.catchup or not state.settings.rewardToasts then
        return
    end
    if event.kind == "prestige" then
        N.Clear()
        return
    end
    if N.state ~= state then
        N.Clear()
        N.state = state
    end
    local hero = state.heroes[event.target]
    local class = hero and C.classByID[hero.class]
    if (event.kind == "item" or event.kind == "craft") and event.item then
        local recipient = G.UpgradeRecipient(state, event.item)
        if recipient then
            enqueue({
                kind = "upgrade",
                key = "upgrade:" .. recipient .. ":" .. event.item.slot,
                heading = L.NEW_UPGRADE,
                title = G.ItemName(event.item),
                item = event.item,
                icon = event.item.icon or "INV_Misc_Bag_10",
                color = C.qualityColors[event.item.quality],
            })
        end
    elseif event.kind == "chestOpened" and N.current and N.current.kind == "chest" then
        local count = G.ChestCount(state)
        if count == 0 then
            dismiss()
        else
            N.current.title = string.format(L.CHESTS_WAITING, count)
            N.frame.title:SetText(N.current.title)
        end
    elseif event.kind == "chest" then
        local count = G.ChestCount(state)
        if N.current and N.current.kind == "chest" then
            N.current.title = string.format(L.CHESTS_WAITING, count)
            N.frame.title:SetText(N.current.title)
        elseif count == 1 then
            enqueue({
                kind = "chest",
                key = "chest",
                heading = L.CHEST_FOUND,
                title = string.format(L.CHESTS_WAITING, count),
                detail = L.CHEST_READY_DETAIL,
                icon = "INV_Misc_TreasureChest01a",
                tab = "chests",
            })
        end
    elseif hero and (event.kind == "levelup" or event.kind == "recruit") then
        enqueue({
            kind = event.kind,
            key = event.kind .. ":" .. event.target,
            heading = event.kind == "levelup" and L.LEVEL_UP_TOAST or L.COMPANION_RECRUITED,
            title = hero.name,
            target = event.target,
            detail = L.LEVEL_PREFIX .. hero.level .. " · " .. class.name,
            icon = class.icon,
            tab = event.kind == "levelup" and "talents" or "party",
        })
    elseif event.kind == "collection" then
        local item = G.CollectionItem(event.itemID)
        if item then
            enqueue({
                kind = "collection",
                key = "collection:" .. event.itemID,
                heading = L.COLLECTION_DISCOVERED,
                title = G.ItemName(item),
                detail = L.COLLECTIONS,
                icon = item.icon or "INV_Misc_TreasureChest01a",
                tab = "collections",
                color = C.qualityColors[item.quality],
            })
        end
    end
end
