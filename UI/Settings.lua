local _, W = ...
local L = W.L

function W.RegisterSettings()
    if W.settingsCategory then
        return
    end
    local uiKeys = { fullscreen = true, compact = true, locked = true }
    local options = {
        type = "group",
        name = "AFKraft : WoW Idle Game",
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
            L.FULLSCREEN,
            L.FULLSCREEN_DESCRIPTION,
        },
        {
            "compact",
            L.COMPACT_VIEW,
            L.COMPACT_VIEW_DESCRIPTION,
        },
        {
            "locked",
            L.LOCK_WINDOW,
            L.LOCK_WINDOW_DESCRIPTION,
        },
        {
            "chatAnnouncements",
            L.CHAT_ANNOUNCEMENTS,
            L.CHAT_ANNOUNCEMENTS_DESCRIPTION,
        },
        {
            "combatText",
            L.FLOATING_COMBAT_TEXT,
            L.FLOATING_COMBAT_TEXT_DESCRIPTION,
        },
        {
            "soundEnabled",
            L.MINIGAME_SOUNDS,
            L.MINIGAME_SOUNDS_DESCRIPTION,
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
    options.args.adventure = {
        type = "group",
        name = L.NEW_ADVENTURE,
        order = 90,
        args = {
            description = {
                type = "description",
                name = L.NEW_ADVENTURE_DESCRIPTION,
                order = 1,
            },
            reset = {
                type = "execute",
                name = L.RESET_ADVENTURE,
                desc = L.RESET_ADVENTURE_DESCRIPTION,
                order = 2,
                width = "full",
                confirm = true,
                confirmText = L.RESET_ADVENTURE_CONFIRMATION,
                func = function()
                    W.ResetAdventure()
                end,
            },
        },
    }
    options.args.locale = {
        type = "select",
        name = L.LANGUAGE,
        desc = L.LANGUAGE_DESCRIPTION,
        order = 80,
        values = {
            auto = L.GAME_LANGUAGE,
            enUS = "English",
            frFR = "Français",
            deDE = "Deutsch",
            esES = "Español",
            ruRU = "Русский",
            zhCN = "简体中文",
        },
        get = function()
            local locale = W.preferences.global.locale
            return options.args.locale.values[locale] and locale or "auto"
        end,
        set = function(_, value)
            if options.args.locale.values[value] then
                W.preferences.global.locale = value
                W.Notify(L.LANGUAGE_RELOAD_NOTICE)
            end
        end,
        width = "full",
    }
    W.settingsOptions = options
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WoWIdle", options)
    W.settingsFrame, W.settingsCategory =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WoWIdle", "AFKraft : WoW Idle Game")
end
