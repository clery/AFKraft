local _, W = ...

W.Locales = {}
local supported = { enUS = true, frFR = true, deDE = true, esES = true }
local preferences = type(WoWIdlePreferencesDB) == "table" and WoWIdlePreferencesDB.global
local selected = type(preferences) == "table" and preferences.locale or "auto"
local client = GetLocale and GetLocale() or "enUS"
if client == "esMX" then
    client = "esES"
end
W.locale = supported[selected] and selected or supported[client] and client or "enUS"

-- Stable keys share an explicit English fallback; saved IDs and player names are untouched.
W.L = setmetatable({}, {
    __index = function(_, key)
        local catalog = W.Locales[W.locale]
        return catalog and catalog[key] or W.Locales.enUS[key]
    end,
})
