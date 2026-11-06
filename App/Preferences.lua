local _, W = ...
local L = W.L

-- Account-wide preferences use AceDB; keep gameplay saves and migrations independent.
function W.BindPreferences(state)
    if AFKraftPreferencesDB == nil then
        AFKraftPreferencesDB =
            { global = { ui = W.Game.Copy(state.ui), settings = W.Game.Copy(state.settings) } }
    end
    local saved = AFKraftPreferencesDB
    if type(saved) ~= "table" or (saved.global ~= nil and type(saved.global) ~= "table") then
        return nil, L.THE_SAVED_PREFERENCES_ARE_INVALID_THEY_HAVE_NOT_BEEN
    end
    for _, key in ipairs({ "ui", "settings" }) do
        if saved.global and saved.global[key] ~= nil and type(saved.global[key]) ~= "table" then
            return nil, L.THE_SAVED_PREFERENCES_ARE_INVALID_THEY_HAVE_NOT_BEEN
        end
    end
    W.preferences = LibStub("AceDB-3.0"):New("AFKraftPreferencesDB", {
        global = {
            ui = { compact = false, locked = false, fullscreen = true, tab = "adventure" },
            settings = W.Game.New(0).settings,
        },
    })
    -- Preserve the state-facing interface and legacy save fields for existing consumers.
    state.ui, state.settings = W.preferences.global.ui, W.preferences.global.settings
    return true
end
