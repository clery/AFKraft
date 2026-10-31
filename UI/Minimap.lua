local _, W = ...
local M = {}
W.Minimap = M

function M.Refresh()
    if M.bubble then
        M.bubble:SetShown(type(W.state.ui.minimapNotice) == "string")
    end
end

function M.Record(message)
    if W.UI and W.UI.frame:IsShown() and not W.state.ui.compact then
        return
    end
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
            tooltip:AddLine("Drag to move the minimap button.", 0.7, 0.7, 0.7)
            local notice = W.state.ui.minimapNotice
            if type(notice) == "string" then
                tooltip:AddLine(notice, 1, 0.35, 0.35, true)
            end
        end,
    })
    icons:Register("WoWIdle", M.launcher, saved)
    local button = icons:GetMinimapButton("WoWIdle")
    M.button = button
    -- The library owns the launcher; this overlay represents addon-specific unread notices.
    local bubble = button:CreateTexture(nil, "OVERLAY", nil, 7)
    M.bubble = bubble
    bubble:SetSize(10, 10)
    bubble:SetPoint("TOPRIGHT", -1, -1)
    bubble:SetColorTexture(0.95, 0.08, 0.08, 1)
    local bubbleMask = button:CreateMaskTexture()
    bubbleMask:SetAllPoints(bubble)
    bubbleMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    bubble:AddMaskTexture(bubbleMask)
    M.Refresh()
end
