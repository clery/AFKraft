local _, W = ...

W.Locales = {}
local supported = { enUS = true, frFR = true, deDE = true, esES = true, ruRU = true, zhCN = true }
local preferences = type(AFKraftPreferencesDB) == "table" and AFKraftPreferencesDB.global
local selected = type(preferences) == "table" and preferences.locale or "auto"
local client = GetLocale and GetLocale() or "enUS"
if client == "esMX" then
    client = "esES"
end
W.locale = supported[selected] and selected or supported[client] and client or "enUS"

-- Arial Narrow includes Cyrillic and the separators used by the UI.
local fonts = { ruRU = "Fonts\\ARIALN.TTF", zhCN = "Fonts\\ARKai_T.ttf" }
W.font = fonts[W.locale] or "Fonts\\FRIZQT__.TTF"

-- Stable keys share an explicit English fallback; saved IDs and player names are untouched.
W.L = setmetatable({}, {
    __index = function(_, key)
        local catalog = W.Locales[W.locale]
        return catalog and catalog[key] or W.Locales.enUS[key]
    end,
})
