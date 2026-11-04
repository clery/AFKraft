local _, W = ...
local M = {}
W.Minimap = M

local notices = {
    { "combat", "Party regrouped after combat." },
    { "party", "New companion available." },
    { "progress", "Adventure progress unlocked." },
}

local function pending()
    local saved = W.state.ui.minimapNotices
    return type(saved) == "table" and saved or {}
end

function M.Refresh()
    if M.bubble then
        M.bubble:SetShown(type(W.state.ui.minimapNotice) == "string")
    end
end

function M.Record(message, noticeType)
    if W.UI and W.UI.frame:IsShown() and not W.state.ui.compact then
        return
    end
    local saved, known = pending(), false
    for _, notice in ipairs(notices) do
        if notice[1] == noticeType then
            known = true
            break
        end
    end
    if not known then
        return
    end
    saved[noticeType] = true
    W.state.ui.minimapNotices = saved
    W.state.ui.minimapNotice = message
    M.Refresh()
end

function M.Open()
    if not W.state then
        return
    end
    if not W.UI then
        W.CreateUI()
    end
    local notice = W.state.ui.minimapNotice
    W.UI:SaveGeometry()
    W.state.ui.compact = false
    W.state.ui.tab = "adventure"
    W.UI:ApplyMode()
    W.UI.frame:Show()
    if type(notice) == "string" then
        W.Notify(notice)
    end
    W.state.ui.minimapNotice = nil
    W.state.ui.minimapNotices = nil
    M.Refresh()
end

function M.Create()
    if M.button or not Minimap or not W.state then
        return
    end
    local icons = LibStub("LibDBIcon-1.0")
    local saved = W.state.ui.minimap
    if type(saved) ~= "table" then
        saved = {}
        W.state.ui.minimap = saved
    end
    local position = saved.minimapPos
    if type(position) ~= "number" or position ~= position or math.abs(position) == math.huge then
        position = 225
    end
    saved.minimapPos = position % 360
    saved.hide = saved.hide == true
    saved.lock = saved.lock == true
    saved.showInCompartment = saved.showInCompartment == true

    M.launcher = LibStub("LibDataBroker-1.1"):NewDataObject("WoWIdle", {
        type = "launcher",
        label = "WoWIdle",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        OnClick = function(_, mouseButton)
            if mouseButton == "LeftButton" then
                M.Open()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("WoWIdle", 1, 0.82, 0)
            tooltip:AddLine("Click to open the expanded adventure.", 1, 1, 1)
            if not W.state.ui.minimap or not W.state.ui.minimap.lock then
                tooltip:AddLine("Drag to move the minimap button.", 0.7, 0.7, 0.7)
            end
            local notice = W.state.ui.minimapNotice
            if type(notice) == "string" then
                local unread, shown = pending(), false
                for _, summary in ipairs(notices) do
                    if unread[summary[1]] == true then
                        tooltip:AddLine(summary[2], 1, 0.7, 0.3, true)
                        shown = true
                    end
                end
                if not shown then
                    tooltip:AddLine("New adventure updates.", 1, 0.7, 0.3, true)
                end
            end
        end,
    })
    icons:Register("WoWIdle", M.launcher, saved)
    local button = icons:GetMinimapButton("WoWIdle")
    M.button = button
    -- The library owns the launcher; this overlay represents addon-specific unread notices.
    local bubble = CreateFrame("Frame", nil, button)
    M.bubble = bubble
    bubble:SetSize(12, 12)
    bubble:SetPoint("CENTER", button, "TOPRIGHT", -6, -6)
    -- A dark edge, antique-gold rim and highlighted red inset echo the launcher frame.
    local layers = {
        { size = 12, x = 0, y = 0, color = { 0.12, 0.07, 0.03 } },
        { size = 10, x = 0, y = 0, color = { 0.72, 0.53, 0.22 } },
        { size = 8, x = 0, y = 0, color = { 0.72, 0.06, 0.04 } },
        { size = 3, x = -1, y = 2, color = { 1, 0.52, 0.34 } },
    }
    for i, layer in ipairs(layers) do
        local texture = bubble:CreateTexture(nil, "OVERLAY", nil, i)
        texture:SetSize(layer.size, layer.size)
        texture:SetPoint("CENTER", layer.x, layer.y)
        texture:SetColorTexture(layer.color[1], layer.color[2], layer.color[3], 1)
        local mask = bubble:CreateMaskTexture()
        mask:SetAllPoints(texture)
        mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        texture:AddMaskTexture(mask)
    end
    M.Refresh()
end
