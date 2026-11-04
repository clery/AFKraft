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
            "Use fullscreen for expanded views. Saved for the next login.",
        },
        { "compact", "Compact view", "Use the small adventure window. Saved for the next login." },
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
            "Play while the adventure is visible, using WoW sound-effects volume. Offline progress stays silent.",
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
        name = "New adventure",
        order = 90,
        args = {
            description = {
                type = "description",
                name = "Start over with one hero and the starter guide. This erases the shared adventure for every character on your account. Display and audio preferences are kept.",
                order = 1,
            },
            reset = {
                type = "execute",
                name = "Reset all adventure progress…",
                desc = "Permanently erase heroes, equipment, currencies, Adventure XP, Heritage, recipes, discoveries and destination progress. This is a full reset, not a new chapter.",
                order = 2,
                width = "full",
                confirm = true,
                confirmText = "Erase ALL account-wide WoWIdle progress? Heroes, equipment, gold, materials, Essence, Adventure XP, Heritage, heirlooms, recipes and discoveries will be lost. This cannot be undone. Display and audio preferences are kept.",
                func = function()
                    W.ResetAdventure()
                end,
            },
        },
    }
    W.settingsOptions = options
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WoWIdle", options)
    W.settingsFrame, W.settingsCategory =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WoWIdle", "WoWIdle")
end
