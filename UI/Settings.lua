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
            L["Fullscreen"],
            L["Use fullscreen for expanded views. Saved for the next login."],
        },
        {
            "compact",
            L["Compact view"],
            L["Use the small adventure window. Saved for the next login."],
        },
        {
            "locked",
            L["Lock window"],
            L["Prevent moving or resizing the window. Compact mode keeps an Unlock button."],
        },
        {
            "chatAnnouncements",
            L["Chat announcements"],
            L["Print adventure events in your chat window."],
        },
        {
            "combatText",
            L["Floating combat text"],
            L["Show damage and healing numbers above companions and enemies."],
        },
        {
            "soundEnabled",
            L["Minigame sounds"],
            L["Play while the adventure is visible, using WoW sound-effects volume. Offline progress stays silent."],
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
        name = L["New adventure"],
        order = 90,
        args = {
            description = {
                type = "description",
                name = L["Start over with one hero and the starter guide. This erases the shared adventure for every character on your account. Display and audio preferences are kept."],
                order = 1,
            },
            reset = {
                type = "execute",
                name = L["Reset all adventure progress…"],
                desc = L["Permanently erase heroes, equipment, currencies, Adventure XP, Heritage, recipes, discoveries and destination progress. This is a full reset, not a new chapter."],
                order = 2,
                width = "full",
                confirm = true,
                confirmText = L["Erase ALL account-wide AFKcraft progress? Heroes, equipment, gold, materials, Essence, Adventure XP, Heritage, heirlooms, recipes and discoveries will be lost. This cannot be undone. Display and audio preferences are kept."],
                func = function()
                    W.ResetAdventure()
                end,
            },
        },
    }
    options.args.locale = {
        type = "select",
        name = L["Language"],
        desc = L["Choose the addon language. Reload the UI to apply this change."],
        order = 80,
        values = {
            auto = L["Game language"],
            enUS = "English",
            frFR = "Français",
            deDE = "Deutsch",
            esES = "Español",
        },
        get = function()
            local locale = W.preferences.global.locale
            return options.args.locale.values[locale] and locale or "auto"
        end,
        set = function(_, value)
            if options.args.locale.values[value] then
                W.preferences.global.locale = value
                W.Notify(L["Language saved. Use /reload to apply it."])
            end
        end,
        width = "full",
    }
    W.settingsOptions = options
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WoWIdle", options)
    W.settingsFrame, W.settingsCategory =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WoWIdle", "AFKraft : WoW Idle Game")
end
