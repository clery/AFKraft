local _, W = ...

-- Account-wide preferences use AceDB; keep gameplay saves and migrations independent.
function W.BindPreferences(state)
    if WoWIdlePreferencesDB == nil then
        WoWIdlePreferencesDB =
            { global = { ui = W.Game.Copy(state.ui), settings = W.Game.Copy(state.settings) } }
    end
    local saved = WoWIdlePreferencesDB
    if type(saved) ~= "table" or (saved.global ~= nil and type(saved.global) ~= "table") then
        return nil, "The saved preferences are invalid. They have not been reset."
    end
    for _, key in ipairs({ "ui", "settings" }) do
        if saved.global and saved.global[key] ~= nil and type(saved.global[key]) ~= "table" then
            return nil, "The saved preferences are invalid. They have not been reset."
        end
    end
    W.preferences = LibStub("AceDB-3.0"):New("WoWIdlePreferencesDB", {
        global = {
            ui = { compact = false, locked = false, fullscreen = true, tab = "adventure" },
            settings = W.Game.New(0).settings,
        },
    })
    -- Preserve the state-facing interface and legacy save fields for existing consumers.
    state.ui, state.settings = W.preferences.global.ui, W.preferences.global.settings
    return true
end
