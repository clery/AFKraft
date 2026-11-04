local _, W = ...
local L = W.L
local G, C = W.Game, W.Content

function G.HeroResource(hero, unit)
    local kind = hero and C.heroResourceByClass[hero.class]
    local profile = kind and C.heroResources[kind]
    if not profile then
        return nil
    end
    local value = unit and unit.resource
    if type(value) ~= "number" or value ~= value or value < 0 or value > profile.maximum then
        value = profile.initial
    end
    return profile, value, kind
end

function G.EnsureHeroResource(hero, unit)
    local profile, value, kind = G.HeroResource(hero, unit)
    if not profile then
        return false
    end
    unit.resource, unit.resourceMax, unit.resourceKind = value, profile.maximum, kind
    return true
end

function G.GainHeroResource(hero, unit, amount)
    if type(amount) ~= "number" or amount ~= amount or amount < 0 or amount >= math.huge then
        return false
    end
    local profile, value = G.HeroResource(hero, unit)
    if not profile then
        return false
    end
    unit.resource = math.min(profile.maximum, value + amount)
    return true
end

function G.CanHeroAbility(hero, unit, action)
    local profile, value = G.HeroResource(hero, unit)
    if not profile or not profile.costs[action] then
        return false, L["Ability unavailable."]
    end
    local threshold = hero.resourceThreshold or 0
    if value / profile.maximum * 100 < threshold then
        return false,
            L["Waiting for "] .. threshold .. "% " .. profile.name .. L[". Basic attacks continue."]
    end
    if value < profile.costs[action] then
        return false,
            L["Need "]
                .. profile.costs[action]
                .. " "
                .. profile.name
                .. L[". Basic attacks continue."]
    end
    return true, L["Resource ready."]
end

function G.SpendHeroResource(hero, unit, action)
    local ready, reason = G.CanHeroAbility(hero, unit, action)
    if not ready then
        return false, reason
    end
    local profile, value = G.HeroResource(hero, unit)
    if not profile then
        return false, L["Resource unavailable."]
    end
    unit.resource = value - profile.costs[action]
    return true
end
