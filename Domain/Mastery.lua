local _, W = ...
local L = W.L
local C, G = W.Content, W.Game
local min, max, floor = math.min, math.max, math.floor

local function whole(value)
    return type(value) == "number" and value >= 0 and value < math.huge and value == floor(value)
end

function G.MasteryCost(rank)
    local late = max(0, rank - C.mastery.softCap)
    return C.mastery.baseXP + rank * C.mastery.xpPerRank + late * late * C.mastery.xpPerLateRank
end

function G.MasteryProgress(hero)
    local mastery = hero.mastery
    if mastery == nil then
        mastery = { rank = 0, xp = 0, frontier = 0 }
    elseif
        type(mastery) ~= "table"
        or not whole(mastery.rank)
        or not whole(mastery.xp)
        or not whole(mastery.frontier)
        or G.MasteryCost(mastery.rank) >= math.huge
        or mastery.xp >= G.MasteryCost(mastery.rank)
    then
        return nil, L.THE_SAVED_MASTERY_PROGRESSION_IS_INVALID_YOUR_ADVENTURE_HAS
    end
    hero.mastery = mastery
    if mastery.frontiers == nil then
        mastery.frontiers = { [0] = mastery.frontier }
    elseif type(mastery.frontiers) ~= "table" then
        return nil, L.THE_SAVED_TIER_MASTERY_FRONTIERS_ARE_INVALID_YOUR_ADVENTURE
    end
    for tier, frontier in pairs(mastery.frontiers) do
        if not whole(tier) or tier > 10 or not whole(frontier) then
            return nil, L.THE_SAVED_TIER_MASTERY_FRONTIERS_ARE_INVALID_YOUR_ADVENTURE
        end
    end
    mastery.frontiers[0] = max(mastery.frontiers[0] or 0, mastery.frontier)
    return mastery
end

function G.MasteryFrontier(hero, tier)
    local mastery = G.MasteryProgress(hero)
    return mastery and (mastery.frontiers[tier or 0] or 0) or 0
end

function G.MasteryUnlocked(hero)
    local progress = G.TalentProgress(hero)
    return progress and progress.bestLevel >= C.mastery.unlockLevel or false
end

-- Victory XP feeds a separate, persistent track even at the character level cap.
-- Its encounter frontier survives prestige so easier runs cannot farm Mastery.
function G.RewardMastery(hero, encounterLevel, experience, boss, tier)
    tier = tier or 0
    if
        not whole(encounterLevel)
        or encounterLevel < 1
        or not whole(experience)
        or not whole(tier)
        or tier > 10
    then
        return 0, 0
    end
    local mastery = G.MasteryProgress(hero)
    local progress = G.TalentProgress(hero)
    if not mastery or not progress then
        return 0, 0
    end
    local frontier = mastery.frontiers[tier] or 0
    local eligible = encounterLevel >= frontier
    mastery.frontiers[tier] = max(frontier, encounterLevel)
    if tier == 0 then
        mastery.frontier = mastery.frontiers[0]
    end
    if not eligible or not G.MasteryUnlocked(hero) or progress.earned >= G.TalentLimit(hero) then
        return 0, 0
    end
    local gained = experience * (boss and C.mastery.bossMultiplier or 1)
    if gained >= math.huge then
        return 0, 0
    end
    local xp, ranks = mastery.xp + gained, 0
    local limit = G.TalentLimit(hero)
    while progress.earned < limit and xp >= G.MasteryCost(mastery.rank) do
        xp = xp - G.MasteryCost(mastery.rank)
        mastery.rank = mastery.rank + 1
        if mastery.rank % C.mastery.ranksPerPoint == 0 then
            progress.earned = progress.earned + 1
        end
        ranks = ranks + 1
    end
    mastery.xp = min(xp, G.MasteryCost(mastery.rank) - 1)
    return gained, ranks
end
