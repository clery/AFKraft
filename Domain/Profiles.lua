local _, W = ...
local L = W.L
local G, C = W.Game, W.Content
local limit = 8

local function integer(value)
    return type(value) == "number"
        and value >= 1
        and value <= 1000000000
        and value == math.floor(value)
end

local function nameOf(value)
    if type(value) ~= "string" then
        return nil
    end
    local name = value:match("^%s*(.-)%s*$")
    local _, length = name:gsub("[^\128-\191]", "")
    if name == "" or #name > 160 or length > 40 or name:find("%c") then
        return nil
    end
    return name
end

local function validEntry(profile)
    if
        type(profile) ~= "table"
        or not integer(profile.id)
        or not nameOf(profile.name)
        or (profile.equipped ~= nil and type(profile.equipped) ~= "string")
        or type(profile.automation) ~= "table"
        or type(profile.automation.enabled) ~= "boolean"
        or type(profile.automation.abilities) ~= "table"
    then
        return false
    end
    local count = 0
    for id, config in pairs(profile.automation.abilities) do
        count = count + 1
        if
            count > 100
            or type(id) ~= "string"
            or #id > 100
            or type(config) ~= "table"
            or type(config.enabled) ~= "boolean"
            or type(config.mode) ~= "string"
            or #config.mode > 100
            or type(config.healthBelow) ~= "number"
            or config.healthBelow < 10
            or config.healthBelow > 90
            or config.healthBelow ~= math.floor(config.healthBelow)
            or not G.ValidateBoostRules(config.rules)
        then
            return false
        end
    end
    if profile.collection ~= nil then
        local selection = profile.collection
        if
            type(selection) ~= "table"
            or (
                selection.effect ~= nil
                and (type(selection.effect) ~= "string" or #selection.effect > 100)
            )
        then
            return false
        end
    end
    local route = profile.route
    return route == nil
        or (
            type(route) == "table"
            and type(route.enabled) == "boolean"
            and (route.offlineEnabled == nil or type(route.offlineEnabled) == "boolean")
            and (route.selected == nil or integer(route.selected))
        )
end

function G.ValidateProfiles(state)
    local profiles = state.boostProfiles
    if
        type(profiles) ~= "table"
        or not integer(profiles.nextID)
        or type(profiles.entries) ~= "table"
    then
        return false
    end
    local count = 0
    for id, profile in pairs(profiles.entries) do
        count = count + 1
        if
            count > limit
            or not integer(id)
            or id >= profiles.nextID
            or not validEntry(profile)
            or profile.id ~= id
        then
            return false
        end
    end
    return true
end

local function configuration(state, profile)
    if not validEntry(profile) then
        return nil, L.THIS_PROFILE_IS_INVALID
    end
    if
        profile.equipped
        and (not C.boostByID[profile.equipped] or not state.boosts.owned[profile.equipped])
    then
        return nil, L.THIS_PROFILE_NEEDS_A_BOOST_THAT_IS_UNAVAILABLE_OR
    end
    local automation = {
        owned = state.boosts.automation.owned,
        enabled = profile.automation.enabled,
        abilities = {},
    }
    for id, config in pairs(profile.automation.abilities) do
        if not C.boostByID[id] then
            return nil, L.THIS_PROFILE_REFERENCES_AN_UNAVAILABLE_BOOST
        end
        automation.abilities[id] = {
            enabled = config.enabled,
            mode = config.mode,
            healthBelow = config.healthBelow,
            rules = G.Copy(config.rules),
        }
    end
    for _, boost in ipairs(C.boosts) do
        automation.abilities[boost.id] = automation.abilities[boost.id]
            or { enabled = false, mode = "manual", healthBelow = 50 }
    end
    local candidate = { boosts = { owned = state.boosts.owned, automation = automation } }
    if not G.ValidateBoostAutomation(candidate) then
        return nil, L.THIS_PROFILE_REQUIRES_BOOST_OR_AUTOMATION_UNLOCKS_YOU_DO
    end
    if profile.route then
        if not state.routes then
            return nil, L.ROUTE_PLANNING_IS_UNAVAILABLE_FOR_THIS_PROFILE
        end
        if
            (profile.route.selected or profile.route.enabled or profile.route.offlineEnabled)
            and not state.routes.owned
        then
            return nil, L.THIS_PROFILE_REQUIRES_ROUTE_PLANNING
        end
        local found = profile.route.selected == nil
        for _, template in ipairs(state.routes.templates) do
            if template.id == profile.route.selected then
                found = true
                break
            end
        end
        if not found then
            return nil, L.THIS_PROFILE_REFERENCES_A_ROUTE_THAT_NO_LONGER_EXISTS
        end
    end
    if profile.collection then
        local valid, reason = G.CollectionEffectStatus(state, profile.collection.effect)
        if not valid then
            return nil, reason
        end
    end
    return automation
end

function G.SaveBoostProfile(state, id, name)
    local profiles, normalized = state.boostProfiles, nameOf(name)
    if not normalized then
        return false, L.CHOOSE_A_PROFILE_NAME_OF_1_TO_40_CHARACTERS
    end
    if id ~= nil and (not integer(id) or not profiles.entries[id]) then
        return false, L.UNKNOWN_COMMANDER_PROFILE
    end
    local count = 0
    for _ in pairs(profiles.entries) do
        count = count + 1
    end
    if id == nil and (count >= limit or profiles.nextID >= 1000000000) then
        return false, L.KEEP_AT_MOST_EIGHT_COMMANDER_PROFILES
    end
    local savedID = id or profiles.nextID
    if not G.ValidateBoostAutomation(state) then
        return false, L.THE_CURRENT_AUTOMATION_SETUP_IS_INVALID
    end
    local entry = {
        id = savedID,
        name = normalized,
        equipped = state.boosts.equipped,
        automation = { enabled = state.boosts.automation.enabled, abilities = {} },
    }
    for boostID, config in pairs(state.boosts.automation.abilities) do
        entry.automation.abilities[boostID] = {
            enabled = config.enabled,
            mode = config.mode,
            healthBelow = config.healthBelow,
            rules = G.Copy(config.rules),
        }
    end
    if state.routes then
        entry.route = {
            selected = state.routes.selected,
            enabled = state.routes.enabled,
            offlineEnabled = state.routes.offlineEnabled,
        }
    end
    if state.outdoorCollections then
        entry.collection = { effect = G.ActiveCollectionEffect(state) }
    end
    local ready, reason = configuration(state, entry)
    if not ready then
        return false, reason
    end
    profiles.entries[savedID] = entry
    if id == nil then
        profiles.nextID = savedID + 1
    end
    return true, savedID
end

function G.ApplyBoostProfile(state, id)
    local profile = state.boostProfiles.entries[id]
    if not profile then
        return false, L.UNKNOWN_COMMANDER_PROFILE
    end
    local automation, reason = configuration(state, profile)
    if not automation then
        return false, reason
    end
    if profile.collection then
        G.SetCollectionEffect(state, profile.collection.effect)
    end
    state.boosts.equipped = profile.equipped
    state.boosts.automation.enabled = automation.enabled
    state.boosts.automation.abilities = automation.abilities
    if profile.route then
        if state.routes.selected ~= profile.route.selected then
            state.routes.selected = profile.route.selected
            G.ResetRouteRun(state)
        end
        state.routes.enabled = profile.route.enabled
        if profile.route.offlineEnabled ~= nil then
            state.routes.offlineEnabled = profile.route.offlineEnabled
        end
    end
    return true
end

function G.DeleteBoostProfile(state, id)
    if not state.boostProfiles.entries[id] then
        return false, L.UNKNOWN_COMMANDER_PROFILE
    end
    state.boostProfiles.entries[id] = nil
    return true
end

function G.RenameBoostProfile(state, id, name)
    local normalized = nameOf(name)
    if not normalized then
        return false, L.CHOOSE_A_PROFILE_NAME_OF_1_TO_40_CHARACTERS
    end
    if not state.boostProfiles.entries[id] then
        return false, L.UNKNOWN_COMMANDER_PROFILE
    end
    state.boostProfiles.entries[id].name = normalized
    return true
end
