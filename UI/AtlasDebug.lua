-- Opt-in map calibration. Drafts persist, but editing is disabled every login/reload.
local _, W = ...
local D = { enabled = false }
W.AtlasPinDebug = D
local basePosition, baseDraw = W.Client.ZonePosition, W.Atlas.Draw
local exportWindow

local function drafts()
    if type(W.state.ui.pinCalibration) ~= "table" then
        W.state.ui.pinCalibration = {}
    end
    return W.state.ui.pinCalibration
end

local function valid(point, continent)
    return type(point) == "table"
        and point.continent == continent
        and type(point.x) == "number"
        and type(point.y) == "number"
        and point.x >= 0
        and point.x <= 1
        and point.y >= 0
        and point.y <= 1
end

function W.Client.ZonePosition(zone, continent)
    if D.enabled and W.state then
        local point = drafts()[zone]
        if valid(point, continent) then
            return point.x, point.y
        end
    end
    return basePosition(zone, continent)
end

function D.ExportText()
    local lines = { "-- WoWIdle pin calibration (" .. W.Client.flavor .. ")", "{" }
    for _, zone in ipairs(W.Content.zones) do
        for _, continent in ipairs({ "kalimdor", "eastern" }) do
            local x, y = basePosition(zone.id, continent)
            local point = drafts()[zone.id]
            if valid(point, continent) then
                x, y = point.x, point.y
            end
            if x and y then
                lines[#lines + 1] =
                    string.format('    %s = { "%s", %.6f, %.6f },', zone.id, continent, x, y)
            end
        end
    end
    lines[#lines + 1] = "}"
    return table.concat(lines, "\n")
end

function D.Export()
    if not exportWindow then
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        exportWindow = frame
        frame:SetSize(660, 420)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:EnableMouse(true)
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 1)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 18, -16)
        title:SetText("Pin positions: press Ctrl+C to copy")
        local edit = CreateFrame("EditBox", nil, frame)
        frame.edit = edit
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject("ChatFontNormal")
        edit:SetJustifyH("LEFT")
        edit:SetJustifyV("TOP")
        edit:SetPoint("TOPLEFT", 18, -48)
        edit:SetSize(624, 320)
        edit:SetMaxLetters(0)
        edit:SetScript("OnEscapePressed", function()
            frame:Hide()
        end)
        local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        close:SetSize(100, 26)
        close:SetPoint("BOTTOMRIGHT", -16, 12)
        close:SetText("Close")
        close:SetScript("OnClick", function()
            frame:Hide()
        end)
    end
    exportWindow:Show()
    exportWindow.edit:SetText(D.ExportText())
    exportWindow.edit:SetFocus()
    exportWindow.edit:HighlightText()
end

local function cursor(map)
    local x, y = GetCursorPosition()
    local scale = map:GetEffectiveScale()
    return (x / scale - map:GetLeft()) / map:GetWidth(),
        (map:GetTop() - y / scale) / map:GetHeight()
end

local function attach(map, zoneID, pin)
    if pin.calibrationAttached then
        return
    end
    pin.calibrationAttached = true
    local click, enter = pin:GetScript("OnClick"), pin:GetScript("OnEnter")
    pin:SetScript("OnClick", function(...)
        if not D.enabled then
            click(...)
        end
    end)
    pin:SetScript("OnEnter", function(...)
        if not D.enabled then
            enter(...)
            return
        end
        local x, y = W.Client.ZonePosition(zoneID, map.id)
        GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
        GameTooltip:SetText(W.Content.zoneByID[zoneID].name)
        GameTooltip:AddLine(string.format("Drag to position · x %.6f · y %.6f", x, y))
        GameTooltip:Show()
    end)
    local function dragUpdate()
        local drag = pin.calibrationDrag
        if not D.enabled or not drag then
            return
        end
        local x, y = cursor(map)
        x, y = math.max(0, math.min(1, x + drag.dx)), math.max(0, math.min(1, y + drag.dy))
        drafts()[zoneID] = { continent = map.id, x = x, y = y }
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", map, "TOPLEFT", x * map:GetWidth(), -y * map:GetHeight())
    end
    pin:SetScript("OnMouseDown", function(_, button)
        if not D.enabled or button ~= "LeftButton" then
            return
        end
        local x, y = cursor(map)
        local px, py = W.Client.ZonePosition(zoneID, map.id)
        pin.calibrationDrag = { dx = px - x, dy = py - y }
        pin:SetScript("OnUpdate", dragUpdate)
        GameTooltip:Hide()
    end)
    local function stop()
        pin.calibrationDrag = nil
        pin:SetScript("OnUpdate", nil)
    end
    pin:SetScript("OnMouseUp", stop)
    pin:HookScript("OnHide", stop)
end

function W.Atlas.Draw(ui)
    baseDraw(ui)
    local atlas = ui.atlas
    if not D.enabled and not atlas.calibrationNote then
        return
    end
    if not atlas.calibrationNote then
        local note = atlas.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        atlas.calibrationNote = note
        local actionClick = atlas.action:GetScript("OnClick")
        atlas.action:SetScript("OnClick", function(...)
            if not D.enabled then
                actionClick(...)
            end
        end)
        note:SetPoint("TOPRIGHT", -20, -4)
        note:SetText("PIN DEBUG: drag pins · /wipins export · /wipins off")
    end
    atlas.calibrationNote:SetShown(D.enabled)
    if D.enabled then
        atlas.action:SetEnabled(false)
        atlas.action.text:SetText("Drag pins to calibrate")
    end
    for _, map in ipairs(atlas.maps) do
        if not map.calibrationAttached then
            map.calibrationAttached = true
            local mouseUp = map:GetScript("OnMouseUp")
            local update = map:GetScript("OnUpdate")
            map:SetScript("OnUpdate", function(...)
                if not D.enabled then
                    update(...)
                else
                    map.highlight:Hide()
                end
            end)
            map:SetScript("OnMouseUp", function(...)
                if not D.enabled then
                    mouseUp(...)
                end
            end)
        end
        for zoneID, pin in pairs(map.pins) do
            attach(map, zoneID, pin)
            if D.enabled then
                pin.icon:SetDesaturated(false)
                pin:SetAlpha(1)
            end
        end
    end
end

function D.SetEnabled(enabled)
    D.enabled = enabled == true
    if not W.state then
        return
    end
    if not W.UI then
        W.CreateUI()
    end
    if D.enabled then
        W.UI.frame:Show()
        W.UI:SetTab("atlas")
    else
        if exportWindow then
            exportWindow:Hide()
        end
        if W.UI.atlas then
            for _, map in ipairs(W.UI.atlas.maps) do
                for _, pin in pairs(map.pins) do
                    pin.calibrationDrag = nil
                    pin:SetScript("OnUpdate", nil)
                end
            end
        end
        W.UI:Refresh()
    end
end

function D.Reset()
    if not W.state then
        return
    end
    W.state.ui.pinCalibration = nil
    if W.UI then
        W.UI:Refresh()
    end
end

function D.Command(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if not W.state then
        return
    end
    if message == "export" then
        if D.enabled then
            D.Export()
        end
    elseif message == "reset" then
        if D.enabled then
            D.Reset()
        end
    elseif message == "off" then
        D.SetEnabled(false)
    else
        D.SetEnabled(true)
    end
end
