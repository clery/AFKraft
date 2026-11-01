local _, W = ...

function W.RegisterSettings()
    if W.settingsCategory then
        return
    end
    local uiKeys = { fullscreen = true, compact = true, locked = true }
    local options = {
        type = "group",
        name = "WoWIdle",
        args = {},
        get = function(info)
            local key = info[#info]
            local scope = uiKeys[key] and W.state.ui or W.state.settings
            if scope[key] == nil then
                return key == "fullscreen"
            end
            return scope[key]
        end,
        set = function(info, value)
            local key = info[#info]
            local scope = uiKeys[key] and W.state.ui or W.state.settings
            if uiKeys[key] then
                W.UI:SaveGeometry()
            end
            scope[key] = value
            if uiKeys[key] then
                W.UI.fullscreen = W.state.ui.fullscreen ~= false
                W.UI:ApplyMode()
            elseif key == "combatText" and not value then
                for _, unit in ipairs(W.UI.scene.units) do
                    unit.floatAnimation:Stop()
                    unit.floating:SetAlpha(0)
                end
            elseif key:find("^sound") and not value then
                W.Audio.Stop()
            end
        end,
    }
    local entries = {
        {
            "fullscreen",
            "Fullscreen",
            "Use fullscreen for the expanded view. Also used after login.",
        },
        { "compact", "Compact view", "Use the small adventure window. Also used after login." },
        {
            "locked",
            "Lock window",
            "Prevent moving or resizing the window. Compact mode keeps an Unlock button.",
        },
        {
            "chatAnnouncements",
            "Chat announcements",
            "Print adventure events in your chat window.",
        },
        {
            "combatText",
            "Floating combat text",
            "Show damage and healing numbers above companions and enemies.",
        },
        {
            "soundEnabled",
            "Minigame sounds",
            "Play sounds while the adventure window is visible. Uses WoW sound-effects volume; offline progress stays silent.",
        },
    }
    for _, entry in ipairs(W.Audio.categories) do
        entries[#entries + 1] = { entry.key, entry.name, entry.tip }
    end
    for order, entry in ipairs(entries) do
        options.args[entry[1]] = {
            type = "toggle",
            order = order,
            name = entry[2],
            desc = entry[3],
            width = "full",
        }
    end
    options.args.debug = {
        type = "group",
        name = "Debug",
        order = 100,
        args = {
            description = {
                type = "description",
                name = "Development tools. Pin calibration replaces map travel with dragging until disabled. Editing always starts disabled after login or reload.",
                order = 1,
            },
            pinCalibration = {
                type = "toggle",
                name = "Enable pin calibration for this session",
                desc = "Open the world map and drag any pin, including locked destinations. Draft positions are saved separately and only used while calibration is enabled. Close Settings to edit the map.",
                width = "full",
                order = 2,
                get = function()
                    return W.AtlasPinDebug.enabled
                end,
                set = function(_, value)
                    W.AtlasPinDebug.SetEnabled(value)
                end,
            },
            exportPins = {
                type = "execute",
                name = "Copy pin positions",
                desc = "Open a text box containing all pin coordinates. Press Ctrl+C to copy.",
                order = 3,
                disabled = function()
                    return not W.AtlasPinDebug.enabled
                end,
                func = function()
                    W.AtlasPinDebug.Export()
                end,
            },
            resetPins = {
                type = "execute",
                name = "Reset draft positions",
                desc = "Discard saved calibration drafts and return to the built-in pin positions.",
                order = 4,
                disabled = function()
                    return not W.AtlasPinDebug.enabled
                end,
                func = function()
                    W.AtlasPinDebug.Reset()
                end,
            },
        },
    }
    W.Controller:RegisterChatCommand("wipins", W.AtlasPinDebug.Command, false)
    W.settingsOptions = options
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WoWIdle", options)
    W.settingsFrame, W.settingsCategory =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WoWIdle", "WoWIdle")
end
