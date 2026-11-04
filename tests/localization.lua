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
    local reference = W.Locales.frFR
    assert(next(reference))
    for locale, catalog in pairs(W.Locales) do
        for source in pairs(reference) do
            assert(
                type(catalog[source]) == "string" and catalog[source] ~= "",
                locale .. ": " .. source
            )
            assert(signature(catalog[source]) == signature(source), locale .. " format: " .. source)
            local _, sourceLines = source:gsub("\n", "")
            local _, translatedLines = catalog[source]:gsub("\n", "")
            assert(sourceLines == translatedLines, locale .. " lines: " .. source)
            assert(not catalog[source]:find("ZXQ", 1, true))
        end
        for source in pairs(catalog) do
            assert(reference[source], locale .. " extra: " .. source)
        end
    end
end)

case("Client language, Spanish variants and explicit overrides resolve safely", function()
    for _, example in ipairs({
        { "frFR", "auto", "frFR" },
        { "deDE", "auto", "deDE" },
        { "esMX", "auto", "esES" },
        { "esES", "auto", "esES" },
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
        assert(namespace.L["Player-created name"] == "Player-created name")
        assert(namespace.L["Heritage"] ~= namespace.L["Inheritance"])
    end
end)

case("Every language loads content with stable IDs and translated talent sentences", function()
    for _, locale in ipairs({ "enUS", "frFR", "deDE", "esES" }) do
        local namespace = { locale = locale, Locales = W.Locales }
        namespace.L = setmetatable({}, {
            __index = function(_, source)
                if locale == "enUS" then
                    return source
                end
                local translated = namespace.Locales[locale][source]
                assert(translated, locale .. " missing: " .. source)
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

return cases
