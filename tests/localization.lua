local _, W = ...
if not W then
    return
end
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end

local function signature(text)
    if not text:find("%%[sdfgicuoxXeE]", 1) and not text:find("%%[-+0#]*[%d.]+[sdfgicuoxXeE]") then
        return ""
    end
    local formats = {}
    for format in text:gmatch("%%[-+ #0]*%d*%.?%d*[cdeEfgGiouXxs%%]") do
        formats[#formats + 1] = format
    end
    return table.concat(formats, "|")
end

case("Localized catalogs have matching keys, placeholders and line breaks", function()
    local reference = W.Locales.enUS
    assert(next(reference))
    assert(reference.MATERIAL_HIDE == "Animal hide" and reference.ACTION_HIDE == "Hide")
    for locale, catalog in pairs(W.Locales) do
        for key, english in pairs(reference) do
            assert(key:match("^[A-Z][A-Z0-9_]*$"), key)
            assert(type(catalog[key]) == "string" and catalog[key] ~= "", locale .. ": " .. key)
            assert(signature(catalog[key]) == signature(english), locale .. " format: " .. key)
            local _, sourceLines = english:gsub("\n", "")
            local _, translatedLines = catalog[key]:gsub("\n", "")
            assert(sourceLines == translatedLines, locale .. " lines: " .. key)
            assert(not catalog[key]:find("ZXQ", 1, true))
        end
        for key in pairs(catalog) do
            assert(reference[key], locale .. " extra: " .. key)
        end
    end
end)

case("Client language, supported locales and explicit overrides resolve safely", function()
    for _, example in ipairs({
        { "frFR", "auto", "frFR" },
        { "deDE", "auto", "deDE" },
        { "esMX", "auto", "esES" },
        { "esES", "auto", "esES" },
        { "ruRU", "auto", "ruRU" },
        { "zhCN", "auto", "zhCN" },
        { "enUS", "ruRU", "ruRU" },
        { "enUS", "zhCN", "zhCN" },
        { "koKR", "auto", "enUS" },
        { "frFR", "enUS", "enUS" },
        { "enUS", "deDE", "deDE" },
        { "enUS", {}, "enUS" },
    }) do
        local namespace = {}
        local environment = setmetatable({
            WoWIdlePreferencesDB = { global = { locale = example[2] } },
            GetLocale = function()
                return example[1]
            end,
        }, { __index = _G })
        local chunk = assert(loadfile("Localization.lua"))
        setfenv(chunk, environment)("WoWIdle", namespace)
        namespace.Locales = W.Locales
        assert(namespace.locale == example[3])
        local fonts = { ruRU = "Fonts\\ARIALN.TTF", zhCN = "Fonts\\ARKai_T.ttf" }
        assert(namespace.font == (fonts[example[3]] or "Fonts\\FRIZQT__.TTF"))
        assert(namespace.L.HERITAGE == W.Locales[example[3]].HERITAGE)
        assert(namespace.L.HERITAGE ~= namespace.L.INHERITANCE)
    end
end)

case("Named keys fall back to the explicit English catalog", function()
    local namespace = {}
    assert(loadfile("Localization.lua"))("WoWIdle", namespace)
    namespace.Locales = { enUS = W.Locales.enUS, frFR = { CLOSE = "Fermer" } }
    namespace.locale = "frFR"
    assert(namespace.L.CLOSE == "Fermer")
    assert(namespace.L.RESET_ADVENTURE_DESCRIPTION == W.Locales.enUS.RESET_ADVENTURE_DESCRIPTION)
    namespace.locale = "enUS"
    assert(namespace.L.CLOSE == "Close")
end)

case("Runtime lookups use defined named keys instead of English prose", function()
    for line in io.lines("WoWIdle.toc") do
        local file = line:gsub("\\", "/")
        if file:match("%.lua$") and not file:match("^Libs/") then
            local handle = assert(io.open(file))
            local source = handle:read("*a")
            handle:close()
            assert(not source:find('L%[%s*"'), file .. " uses an English-text key")
            for key in source:gmatch("%f[%w]L%.([A-Z][A-Z0-9_]*)") do
                assert(W.Locales.enUS[key], file .. " references undefined key " .. key)
            end
        end
    end
end)

case("Every language loads content with stable IDs and translated talent sentences", function()
    for _, locale in ipairs({ "enUS", "frFR", "deDE", "esES", "ruRU", "zhCN" }) do
        local namespace = { locale = locale, Locales = W.Locales }
        namespace.L = setmetatable({}, {
            __index = function(_, key)
                local translated = namespace.Locales[locale][key]
                assert(translated, locale .. " missing: " .. key)
                return translated
            end,
        })
        for _, file in ipairs({
            "Content.lua",
            "Content/Encounters.lua",
            "Content/TalentTraits.lua",
            "Content/TalentExpansion.lua",
            "Content/Items.lua",
            "Content/Boosts.lua",
            "Content/Resources.lua",
            "Content/Collections.lua",
            "Content/Professions.lua",
            "Content/Development.lua",
        }) do
            assert(loadfile(file))("WoWIdle", namespace)
        end
        assert(namespace.Content.classByID.WARRIOR.id == "WARRIOR")
        assert(namespace.Content.zoneByID.elwynn.id == "elwynn")
        assert(namespace.Content.itemByID[25].name == "Worn Shortsword")
        for _, talents in pairs(namespace.Content.talentsByClass) do
            for _, talent in ipairs(talents) do
                assert(not talent.text:find("%%d"))
                assert(type(talent.value) == "number" or type(talent.value) == "boolean")
            end
        end
    end
    WoWIdle = W
end)

case("Item display names follow the locale without changing saved names", function()
    local G, C = W.Game, W.Content
    local item = { itemID = 25, name = "Worn Shortsword", uid = 7 }
    local original = C.itemNames[25]
    local ok, message = pcall(function()
        for _, locale in ipairs({ "enUS", "frFR", "deDE", "esES", "ruRU", "zhCN" }) do
            C.itemNames[25] = W.Locales[locale].ITEM_WORN_SHORTSWORD
            assert(G.ItemName(item) == C.itemNames[25])
            assert(item.name == "Worn Shortsword" and item.uid == 7)
        end
        assert(G.ItemName({ name = "Custom name" }) == "Custom name")
    end)
    C.itemNames[25] = original
    assert(ok, message)
end)

return cases
