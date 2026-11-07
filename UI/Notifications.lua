local _, W = ...
local G, C, L, U, T = W.Game, W.Content, W.L, W.Widgets, W.Theme
local N = { queue = {} }
W.Notifications = N

function N.Clear()
    N.queue = {}
    N.current, N.state, N.chestCheckTime = nil, nil, nil
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
        if count < 10 or not W.Client.ChestNotificationsAllowed() then
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
        if entry.completed then
            W.UI.collectionSelected = entry.setID
            W.CollectionPanel.Celebrate(W.state, entry.setID, entry.itemID)
        end
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
    frame:SetPoint(
        "BOTTOM",
        AlertFrame or UIParent,
        AlertFrame and "TOP" or "BOTTOM",
        0,
        AlertFrame and 10 or 148
    )
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
    frame.fill = U.Rect(frame, 4, 4, 372, 124, T.bg)
    frame.pieces, frame.pieceGlows = {}, {}
    frame.icon = U.Icon(frame, "INV_Misc_Bag_10", 18, 41, 44)
    frame.heading = U.SingleLine(U.Text(frame, "", 18, 13, 12, T.gold), 310, 20)
    frame.title = U.SingleLine(U.Text(frame, "", 74, 39, 14), 286, 24)
    frame.detail = U.SingleLine(U.Text(frame, "", 74, 65, 12, T.green), 286, 22)
    frame.action = U.Button(frame, L.EQUIP, 246, 96, 114, 24, activate)
    local function onMouseUp(_, button)
        if button == "RightButton" then
            dismiss()
        end
    end
    frame:SetScript("OnMouseUp", onMouseUp)
    frame.action:SetScript("OnMouseUp", onMouseUp)
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
        if N.current and N.current.completed then
            local collection = C.collectionByID[N.current.setID]
            for index, icon in ipairs(self.pieces) do
                local itemID = collection.pieces[index]
                local settle = itemID == N.current.itemID and math.min(1, N.age / 0.4) or 1
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", 24 + (index - 1) * 66 - (1 - settle) * 20, -98)
                icon:SetSize(40 + (1 - settle) * 24, 40 + (1 - settle) * 24)
                icon:SetAlpha(settle)
                self.pieceGlows[index]:SetAlpha(
                    math.max(0, 1 - math.abs(N.age - 0.65) / 0.65) * 0.85
                )
            end
        end
        self:SetAlpha(math.min(1, N.age / 0.2, math.max(0, (8 - N.age) / 0.4)))
        if N.age >= 8 then
            dismiss()
        end
    end)
    frame:Hide()
end

local function chestReminder(state)
    local now = W.Client.Now()
    if N.chestCheckTime == now then
        return
    end
    N.chestCheckTime = now
    local count = G.ChestCount(state)
    local reviewing = W.UI
        and W.UI.frame:IsShown()
        and not state.ui.compact
        and (state.ui.tab == "chests" or state.ui.tab == "offline")
    local allowed = count >= 10 and not reviewing and W.Client.ChestNotificationsAllowed()
    if N.current and N.current.kind == "chest" then
        if not allowed then
            dismiss()
        else
            N.current.title = string.format(L.CHESTS_WAITING, count)
            N.frame.title:SetText(N.current.title)
        end
    end
    if not allowed or N.current or #N.queue > 0 then
        return
    end
    local last = state.ui.lastChestToastTime
    if type(last) == "number" and last <= now and now - last < 1800 then
        return
    end
    N.queue[#N.queue + 1] = {
        kind = "chest",
        key = "chest",
        heading = L.CHEST_FOUND,
        title = string.format(L.CHESTS_WAITING, count),
        detail = L.CHEST_READY_DETAIL,
        icon = "INV_Misc_TreasureChest01a",
        tab = "chests",
    }
end

function N.Flush()
    if N.state and (N.state ~= W.state or W.catchup or not W.state.settings.rewardToasts) then
        N.Clear()
    end
    local state = W.state
    if not state or W.catchup or not state.settings.rewardToasts then
        return
    end
    N.state = state
    chestReminder(state)
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
            if entry.kind == "chest" then
                state.ui.lastChestToastTime = W.Client.Now()
            end
            local height = entry.completed and 200 or 132
            frame:SetHeight(height)
            frame.fill:SetHeight(height - 8)
            frame.action:ClearAllPoints()
            frame.action:SetPoint("TOPLEFT", 246, -(height - 36))
            for _, icon in ipairs(frame.pieces) do
                icon:Hide()
            end
            for _, glow in ipairs(frame.pieceGlows) do
                glow:Hide()
            end
            if entry.completed then
                for index, itemID in ipairs(C.collectionByID[entry.setID].pieces) do
                    if not frame.pieces[index] then
                        frame.pieces[index] = U.Icon(frame, "INV_Misc_Bag_10", 0, 0, 40)
                        local glow = frame:CreateTexture(nil, "ARTWORK")
                        glow:SetTexture("Interface\\Cooldown\\star4")
                        glow:SetBlendMode("ADD")
                        glow:SetVertexColor(unpack(T.gold))
                        glow:SetPoint("CENTER", frame.pieces[index], "CENTER")
                        glow:SetSize(70, 70)
                        frame.pieceGlows[index] = glow
                    end
                    frame.pieces[index]:SetTexture(
                        "Interface\\Icons\\" .. G.CollectionItem(itemID).icon
                    )
                    frame.pieces[index]:Show()
                    frame.pieceGlows[index]:Show()
                    frame.pieceGlows[index]:SetAlpha(0)
                end
            end
            frame.heading:SetText("AFKraft · " .. entry.heading)
            frame.title:SetText(entry.title)
            frame.title:SetTextColor(unpack(entry.color or T.text))
            frame.detail.fitSize = entry.completed and 14 or 12
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
            if entry.completed then
                W.Audio.CollectionComplete(state)
            end
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
        local index = 1
        while N.queue[index] and N.queue[index].completed do
            index = index + 1
        end
        if index > #N.queue then
            if not entry.completed then
                return
            end
            index = #N.queue
        end
        table.remove(N.queue, index)
    end
    if entry.completed then
        table.insert(N.queue, 1, entry)
    else
        N.queue[#N.queue + 1] = entry
    end
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
    elseif event.kind == "chestOpened" or event.kind == "chest" then
        N.chestCheckTime = nil
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
    elseif event.kind == "journal" or event.kind == "journalReward" then
        enqueue({
            kind = event.kind,
            key = event.kind .. ":" .. event.title,
            heading = event.heading,
            title = event.title,
            detail = L.JOURNAL_NAME,
            icon = "INV_Misc_Book_09",
            tab = "journal",
            color = T.gold,
        })
    elseif event.kind == "collection" then
        local item = G.CollectionItem(event.itemID)
        local collection = C.collectionByID[event.setID]
        local completed = event.completed
            and collection
            and G.CollectionProgress(state, collection.id).complete
        if item then
            if completed then
                for index = #N.queue, 1, -1 do
                    if N.queue[index].setID == collection.id then
                        table.remove(N.queue, index)
                    end
                end
                if
                    N.current
                    and N.current.kind == "collection"
                    and N.current.setID == collection.id
                then
                    dismiss()
                end
            end
            enqueue({
                kind = "collection",
                completed = completed,
                setID = event.setID,
                itemID = event.itemID,
                key = completed and "collectionComplete:" .. collection.id
                    or "collection:" .. event.itemID,
                heading = completed and L.COLLECTION_COMPLETE or L.COLLECTION_DISCOVERED,
                title = completed and collection.name or G.ItemName(item),
                detail = completed and string.format(
                    L.COLLECTION_EFFECT_UNLOCKED,
                    W.CollectionPanel.EffectText(collection)
                ) or L.COLLECTIONS,
                icon = item.icon or "INV_Misc_TreasureChest01a",
                tab = "collections",
                color = completed and T.gold or C.qualityColors[item.quality],
            })
        end
    end
end
